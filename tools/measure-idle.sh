#!/usr/bin/env bash
# A RONDA DA MEDIÇÃO — a linha de base, e o que mudou desde ela.
#
# O número que manda é o `frames/s`: com a barra parada ele tem que ir a
# zero. Se não for, alguma coisa está animando em repouso, e o resto da
# lista é decoração.
#
# O §1.8 do spec pede smem, pidstat e amdgpu_top. Nenhum dos três está
# instalado aqui, e nenhum dos três é necessário: tudo o que importa sai
# do /proc por diferença entre duas leituras.
#
#   tools/measure-idle.sh                 # 120 s e imprime
#   tools/measure-idle.sh --secs 600      # o teste de aceitação do §1.8
#   tools/measure-idle.sh --save          # guarda a linha, com o commit
#   tools/measure-idle.sh --diff          # compara com a última guardada
#   tools/measure-idle.sh --gpu           # inclui a placa

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/keep-measure"
TSV="$STATE/baseline.tsv"
TCK="$(getconf CLK_TCK)"
mkdir -p "$STATE"

SECS=120
save=0; diff=0; gpu=0
while [ $# -gt 0 ]; do
    case "$1" in
        --secs)  SECS="$2"; shift 2 ;;
        --save)  save=1; shift ;;
        --diff)  diff=1; shift ;;
        --gpu)   gpu=1; shift ;;
        -h|--help) sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 0 ;;
        *) echo "opção desconhecida: $1" >&2; exit 2 ;;
    esac
done

# ── Quem é o torreão ───────────────────────────────────────────
# `pgrep -x quickshell` não acha nada: o binário se chama `qs`. O -x do
# spec falharia calado e o script mediria o vazio.
PID="$(pgrep -f 'qs -c keep' | head -1)"
[ -n "$PID" ] || { echo "o torreão não está de pé (pgrep -f 'qs -c keep')" >&2; exit 1; }
HYPR="$(pgrep -x Hyprland | head -1)"

# ── Leitores ───────────────────────────────────────────────────

# Jiffies de usuário + sistema de um /proc/<x>/stat.
# O comm da thread pode ter espaço e parêntese ("Thread (pooled)"), então
# corta-se tudo até o último ')' antes de contar campos.
jiffies() {
    local f="$1" rest
    [ -r "$f" ] || { echo 0; return; }
    rest="$(cat "$f" 2>/dev/null)" || { echo 0; return; }
    rest="${rest#*) }"
    awk '{print $12 + $13}' <<< "$rest"      # utime e stime, já sem os 2 primeiros
}

ctxt() {
    awk '/_ctxt_switches/ {s += $2} END {print s + 0}' "$1" 2>/dev/null || echo 0
}

# O /proc/<pid>/status traz os contadores da thread LÍDER, não a soma do
# processo — medido: 20/s ali contra 66/s somando as 31 threads. Quem
# quer saber quantas vezes o torreão acordou tem que somar task/*.
#
# E as threads do pool NASCEM E MORREM durante a janela: somar o conjunto
# do início contra o do fim dá delta negativo quando um tid some. Então
# guardamos "tid valor" e o delta é calculado por tid, tratando quem não
# existia no início como zero. Quem morreu no meio leva os ticks embora —
# é subcontagem, e é o erro honesto a cometer aqui.
snap_ctxt() {
    local p tid
    for p in /proc/$PID/task/*/status; do
        tid="${p#/proc/$PID/task/}"; tid="${tid%/status}"
        echo "$tid $(ctxt "$p")"
    done
}

snap_pool() {
    local p tid
    for p in /proc/$PID/task/*; do
        [ "$(cat "$p/comm" 2>/dev/null)" = "Thread (pooled)" ] || continue
        tid="${p##*/}"
        echo "$tid $(jiffies "$p/stat")"
    done
}

# delta <arquivo-inicio> <arquivo-fim> — soma (fim - inicio) por tid.
delta() {
    awk 'NR == FNR { a[$1] = $2; next } { s += $2 - (($1 in a) ? a[$1] : 0) } END { print s + 0 }' "$1" "$2"
}

# O tid da thread cujo comm bate com o padrão.
tid_de() {
    local p
    for p in /proc/$PID/task/*; do
        [ "$(cat "$p/comm" 2>/dev/null)" = "$1" ] && { echo "${p##*/}"; return; }
    done
}

gpu_card() {
    local best="" bestv=0 c v
    for c in /sys/class/drm/card[0-9]*; do
        [ -r "$c/device/mem_info_vram_total" ] || continue
        v="$(cat "$c/device/mem_info_vram_total" 2>/dev/null || echo 0)"
        [ "$v" -gt "$bestv" ] && { bestv="$v"; best="$c"; }
    done
    echo "$best"
}

# ── Amostra ────────────────────────────────────────────────────

RENDER_TID="$(tid_de QSGRenderThread)"
WL_TIDS="$(for p in /proc/$PID/task/*; do
    [ "$(cat "$p/comm" 2>/dev/null)" = "WaylandEventThr" ] && echo "${p##*/}"
done)"

echo "o torreão é o pid $PID · amostrando ${SECS}s"
[ -n "$RENDER_TID" ] || echo "  (sem QSGRenderThread visível — frames/s sai como n/d)"

c0="$(jiffies /proc/$PID/stat)"
snap_ctxt > "$STATE/.w0.$$"
r0=0; rw0=0
[ -n "$RENDER_TID" ] && { r0="$(jiffies /proc/$PID/task/$RENDER_TID/stat)"; rw0="$(ctxt /proc/$PID/task/$RENDER_TID/status)"; }
m0="$(jiffies /proc/$PID/task/$PID/stat)"
snap_pool > "$STATE/.p0.$$"
h0=0; [ -n "$HYPR" ] && h0="$(jiffies /proc/$HYPR/stat)"
snap_wl() { local t; for t in $WL_TIDS; do echo "$t $(ctxt /proc/$PID/task/$t/status)"; done; }
snap_wl > "$STATE/.wl0.$$"

CARD=""; gsum=0; gmax=0; gn=0
if [ "$gpu" = 1 ]; then
    CARD="$(gpu_card)"
    if [ -n "$CARD" ] && [ -r "$CARD/device/gpu_busy_percent" ]; then
        ( end=$((SECS)); i=0
          while [ "$i" -lt "$end" ]; do
              cat "$CARD/device/gpu_busy_percent" 2>/dev/null
              sleep 1; i=$((i + 1))
          done ) > "$STATE/.gpu.$$" 2>/dev/null &
        GPUJOB=$!
    fi
fi

sleep "$SECS"

c1="$(jiffies /proc/$PID/stat)"
snap_ctxt > "$STATE/.w1.$$"
r1=0; rw1=0
[ -n "$RENDER_TID" ] && { r1="$(jiffies /proc/$PID/task/$RENDER_TID/stat)"; rw1="$(ctxt /proc/$PID/task/$RENDER_TID/status)"; }
m1="$(jiffies /proc/$PID/task/$PID/stat)"
snap_pool > "$STATE/.p1.$$"
h1=0; [ -n "$HYPR" ] && h1="$(jiffies /proc/$HYPR/stat)"
snap_wl > "$STATE/.wl1.$$"

if [ -n "${GPUJOB:-}" ]; then
    wait "$GPUJOB" 2>/dev/null
    if [ -s "$STATE/.gpu.$$" ]; then
        read -r gsum gmax gn <<< "$(awk '{s+=$1; if($1>m)m=$1; n++} END{printf "%d %d %d", s, m, n}' "$STATE/.gpu.$$")"
    fi
    rm -f "$STATE/.gpu.$$"
fi

# ── Memória: PSS quando dá, VmRSS quando não ───────────────────
# O PSS é o número honesto: desconta a fatia de biblioteca Qt que o
# torreão divide com qualquer outro cliente Qt. Só que o smaps_rollup
# exige ser o mesmo usuário — de dentro de um container, não é.
mem_label="PSS   "; mem_nota=""
mem_kb="$(awk '/^Pss:/ {print $2; exit}' /proc/$PID/smaps_rollup 2>/dev/null)"
if [ -z "$mem_kb" ]; then
    mem_label="VmRSS"
    mem_nota="  (sem acesso ao smaps_rollup; o VmRSS conta biblioteca compartilhada e infla)"
    mem_kb="$(awk '/^VmRSS:/ {print $2}' /proc/$PID/status)"
fi

pct() { awk -v a="$1" -v b="$2" -v s="$SECS" -v t="$TCK" 'BEGIN{printf "%.2f", (b-a)*100/t/s}'; }
per() { awk -v a="$1" -v b="$2" -v s="$SECS" 'BEGIN{printf "%.1f", (b-a)/s}'; }

CPU="$(pct "$c0" "$c1")"
MAIN="$(pct "$m0" "$m1")"
POOL="$(pct 0 "$(delta "$STATE/.p0.$$" "$STATE/.p1.$$")")"
RCPU="n/d"; FRAMES="n/d"
[ -n "$RENDER_TID" ] && { RCPU="$(pct "$r0" "$r1")"; FRAMES="$(per "$rw0" "$rw1")"; }
WAKE="$(per 0 "$(delta "$STATE/.w0.$$" "$STATE/.w1.$$")")"
WLEV="$(per 0 "$(delta "$STATE/.wl0.$$" "$STATE/.wl1.$$")")"
HCPU="n/d"; [ -n "$HYPR" ] && HCPU="$(pct "$h0" "$h1")"
THREADS="$(awk '/^Threads:/ {print $2}' /proc/$PID/status)"
MEM="$(awk -v k="$mem_kb" 'BEGIN{printf "%.0f", k/1024}')"

# ── Saída ──────────────────────────────────────────────────────
alvo() { awk -v v="$1" -v a="$2" 'BEGIN{print (v+0 <= a+0) ? "✔" : "✘"}'; }

cat <<TAB

  ────────────────────────────────────────────────────────────
   CPU do torreão      ${CPU}%          alvo < 0.20     $(alvo "$CPU" 0.20)
   └─ thread principal ${MAIN}%
   └─ render           ${RCPU}%
   └─ pool de I/O      ${POOL}%   ($(wc -l < "$STATE/.p1.$$") threads: todo FileView assíncrono passa por aqui)
   wakeups             ${WAKE}/s        alvo ≤ 2        $(alvo "$WAKE" 2)
   └─ wayland          ${WLEV}/s
   frames/s            ${FRAMES}        alvo ~ 0        $(alvo "$FRAMES" 0.5)
   ${mem_label}               ${MEM} MB       alvo < 150      $(alvo "$MEM" 150)${mem_nota}
   threads             ${THREADS}
   Hyprland, ao lado   ${HCPU}%
TAB
if [ "$gn" -gt 0 ]; then
    awk -v s="$gsum" -v m="$gmax" -v n="$gn" \
        'BEGIN{printf "   GPU ocupada         %.1f%% média · %d%% pico\n", s/n, m}'
    [ -r "$CARD/device/power_dpm_force_performance_level" ] &&
        echo "   dpm                 $(cat "$CARD/device/power_dpm_force_performance_level")"
fi
echo "  ────────────────────────────────────────────────────────────"

# frames/s é proxy, e o leitor tem que saber disso.
cat <<'NOTA'

  frames/s é o voluntary_ctxt_switches da QSGRenderThread: cada frame
  bloqueia aquela thread ao menos uma vez. É proxy, não contagem — mas
  não exige reiniciar a shell, que é o que o QSG_RENDER_TIMING exigiria.
  60 fps contínuos dariam ~60/s.
NOTA

# ── Persistência ───────────────────────────────────────────────
rm -f "$STATE"/.w[01].$$ "$STATE"/.p[01].$$ "$STATE"/.wl[01].$$

REF="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo '-')"
LINHA="$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    "$(date -Is)" "$REF" "$SECS" "$CPU" "$MAIN" "$WAKE" "$FRAMES" "$MEM" "$THREADS")"

if [ "$diff" = 1 ] && [ -r "$TSV" ]; then
    ANT="$(tail -1 "$TSV")"
    echo
    echo "  contra $(cut -f1,2 <<< "$ANT" | tr '\t' ' '):"
    awk -F'\t' -v novo="$LINHA" 'BEGIN{
        split(novo, n, "\t")
        nome[4]="CPU %"; nome[5]="principal %"; nome[6]="wakeups/s"
        nome[7]="frames/s"; nome[8]="MB"; nome[9]="threads"
    } {
        for (i = 4; i <= 9; i++) {
            d = n[i] - $i
            printf "    %-14s %8s → %-8s %+.2f\n", nome[i], $i, n[i], d
        }
    }' <<< "$ANT"
fi

if [ "$save" = 1 ]; then
    [ -s "$TSV" ] || printf 'quando\tcommit\tsegundos\tcpu\tprincipal\twakeups\tframes\tmb\tthreads\n' > "$TSV"
    printf '%s\n' "$LINHA" >> "$TSV"
    echo
    echo "  → guardado em $TSV"
fi
