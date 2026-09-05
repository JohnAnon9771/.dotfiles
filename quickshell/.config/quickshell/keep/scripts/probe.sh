#!/bin/sh
# ═══════════════════════════════════════════════════════════════
#  SONDAGEM DO TORREÃO
#  Descobre uma vez, no início da sessão, onde ficam os sensores.
#  Depois disso o shell só lê arquivos — nenhum processo por ciclo.
#
#  Nada de caminho chumbado: a waybar tinha hwmon0 fixo e quebrava
#  a cada boot em que os módulos carregassem noutra ordem. Pior:
#  numa máquina com iGPU + dedicada, o número do card e o número do
#  hwmon não se correspondem.
#
#  Saída: um objeto JSON em stdout.
# ═══════════════════════════════════════════════════════════════

set -u

j_str() { printf '"%s"' "$(printf '%s' "${1:-}" | sed 's/\\/\\\\/g; s/"/\\"/g')"; }

# ── Nome comercial da placa ─────────────────────────────────────
# Vem da base do sistema (hwdata), nao de tabela escrita a mao: uma
# tabela chumbada envelhece e erra — a primeira versao disto chamava
# uma 9070 XT de 9060 XT.
#
# Procura primeiro pelo subsistema, que identifica a placa exata do
# fabricante; se nao achar, cai no dispositivo, que da a familia.
PCI_IDS=""
for f in /usr/share/hwdata/pci.ids /usr/share/misc/pci.ids /usr/share/pci.ids; do
    [ -r "$f" ] && { PCI_IDS=$f; break; }
done

pci_name() {
    ven=$1; dev=$2; subven=$3; subdev=$4
    [ -n "$PCI_IDS" ] || return 1

    awk -v ven="$ven" -v dev="$dev" -v sv="$subven" -v sd="$subdev" '
        # Bloco do fabricante
        /^[0-9a-f]/ { invendor = ($1 == ven); indev = 0; next }
        !invendor { next }

        # Linha do dispositivo: um tab
        /^\t[0-9a-f]/ {
            if (indev) exit
            id = $1
            if (id == dev) {
                indev = 1
                sub(/^\t[0-9a-f]+  /, "")
                devname = $0
            }
            next
        }

        # Linha do subsistema: dois tabs
        indev && /^\t\t/ {
            if ($1 == sv && $2 == sd) {
                sub(/^\t\t[0-9a-f]+ [0-9a-f]+  /, "")
                print $0
                exit
            }
            next
        }

        END { if (devname != "" ) print devname }
    ' "$PCI_IDS" 2>/dev/null | head -1
}

# "Navi 48 [Radeon RX 9070 XT]" -> "Radeon RX 9070 XT"
# O nome de marketing entre colchetes e o que uma pessoa reconhece.
pretty_name() {
    printf '%s' "$1" | sed -n 's/.*\[\(.*\)\].*/\1/p; t; p' | head -1
}
j_num() { n=$(cat "$1" 2>/dev/null) || n=""; case "$n" in ''|*[!0-9-]*) printf 'null' ;; *) printf '%s' "$n" ;; esac; }
have()  { [ -r "$1" ] && printf true || printf false; }

# ── Núcleos ────────────────────────────────────────────────────
cores=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null) || cores=1
model=$(grep -m1 '^model name' /proc/cpuinfo 2>/dev/null | sed 's/.*: //')

# ── Sensor de temperatura da CPU ────────────────────────────────
# Preferência de chip: k10temp/zenpower (AMD) > coretemp (Intel).
# Dentro do chip, prefere Tctl > Tdie > Package > sem rótulo.
cpu_hwmon=""; cpu_name=""; cpu_temp=""; cpu_label=""; cpu_crit=""; cpu_rank=99

pick_cpu_sensor() {
    dir=$1; name=$2; rank=$3
    best=""; best_label=""; best_score=99

    for t in "$dir"/temp*_input; do
        [ -r "$t" ] || continue
        stem="${t%_input}"
        label=""
        [ -r "${stem}_label" ] && label=$(cat "${stem}_label" 2>/dev/null)

        case "$label" in
            Tctl)            score=0 ;;
            Tdie)            score=1 ;;
            "Package id "*)  score=2 ;;
            Tccd*)           score=8 ;;
            "")              score=5 ;;
            *)               score=6 ;;
        esac

        if [ "$score" -lt "$best_score" ]; then
            best=$t; best_label=$label; best_score=$score
        fi
    done

    [ -n "$best" ] || return 1
    [ "$rank" -lt "$cpu_rank" ] || return 0

    cpu_hwmon=$dir; cpu_name=$name; cpu_temp=$best
    cpu_label=$best_label; cpu_rank=$rank
    cpu_crit=""
    [ -r "${best%_input}_crit" ] && cpu_crit="${best%_input}_crit"
    return 0
}

for d in /sys/class/hwmon/hwmon*; do
    [ -r "$d/name" ] || continue
    n=$(cat "$d/name" 2>/dev/null) || continue
    case "$n" in
        k10temp|zenpower)  pick_cpu_sensor "$d" "$n" 0 ;;
        coretemp)          pick_cpu_sensor "$d" "$n" 1 ;;
        cpu_thermal|soc)   pick_cpu_sensor "$d" "$n" 2 ;;
    esac
done

if [ -z "$cpu_temp" ]; then
    for d in /sys/class/hwmon/hwmon*; do
        [ -r "$d/temp1_input" ] || continue
        n=$(cat "$d/name" 2>/dev/null) || n="?"
        pick_cpu_sensor "$d" "$n" 50 && break
    done
fi

# ── Placas de vídeo ─────────────────────────────────────────────
# Enumera TODAS (uma máquina com Ryzen tem a iGPU do processador
# além da dedicada) e ordena pela VRAM: a de 16 GB vem antes da de
# 512 MB. Quem dirige o monitor é quase sempre a maior.
emit_gpu() {
    dev=$1

    hw=""
    for h in "$dev"/hwmon/hwmon*; do
        [ -d "$h" ] && { hw=$h; break; }
    done

    drv=""
    [ -L "$dev/driver" ] && drv=$(basename "$(readlink -f "$dev/driver")" 2>/dev/null)

    pciid=$(sed -n 's/^PCI_ID=//p' "$dev/uevent" 2>/dev/null)
    subid=$(sed -n 's/^PCI_SUBSYS_ID=//p' "$dev/uevent" 2>/dev/null)
    slot=$(sed -n 's/^PCI_SLOT_NAME=//p' "$dev/uevent" 2>/dev/null)

    name=$(pci_name "$(echo "$pciid" | cut -d: -f1 | tr 'A-Z' 'a-z')" \
                    "$(echo "$pciid" | cut -d: -f2 | tr 'A-Z' 'a-z')" \
                    "$(echo "$subid" | cut -d: -f1 | tr 'A-Z' 'a-z')" \
                    "$(echo "$subid" | cut -d: -f2 | tr 'A-Z' 'a-z')")
    name=$(pretty_name "$name")

    # amdgpu expõe potência ora como power1_average, ora power1_input.
    power=""
    [ -r "$hw/power1_average" ] && power="$hw/power1_average"
    [ -z "$power" ] && [ -r "$hw/power1_input" ] && power="$hw/power1_input"

    printf '    { "dev": %s, "hwmon": %s, "driver": %s, "pciId": %s, "subsysId": %s, "slot": %s,\n' \
        "$(j_str "$dev")" "$(j_str "$hw")" "$(j_str "$drv")" "$(j_str "$pciid")" \
        "$(j_str "$subid")" "$(j_str "$slot")"
    printf '      "name": %s,\n' "$(j_str "$name")"
    printf '      "vramTotal": %s, "powerPath": %s,\n' \
        "$(j_num "$dev/mem_info_vram_total")" "$(j_str "$power")"
    printf '      "powerCap": %s, "fanMax": %s,\n' \
        "$(j_num "$hw/power1_cap")" "$(j_num "$hw/fan1_max")"
    printf '      "critEdge": %s, "critJunc": %s, "critMem": %s,\n' \
        "$(j_num "$hw/temp1_crit")" "$(j_num "$hw/temp2_crit")" "$(j_num "$hw/temp3_crit")"
    printf '      "has": { "busy": %s, "memBusy": %s, "vram": %s, "sclk": %s, "mclk": %s,\n' \
        "$(have "$dev/gpu_busy_percent")" "$(have "$dev/mem_busy_percent")" \
        "$(have "$dev/mem_info_vram_used")" "$(have "$hw/freq1_input")" "$(have "$hw/freq2_input")"
    printf '               "tempEdge": %s, "tempJunc": %s, "tempMem": %s,\n' \
        "$(have "$hw/temp1_input")" "$(have "$hw/temp2_input")" "$(have "$hw/temp3_input")"
    printf '               "power": %s, "fan": %s, "link": %s } }' \
        "$([ -n "$power" ] && printf true || printf false)" \
        "$(have "$hw/fan1_input")" "$(have "$dev/current_link_speed")"
}

# Ordena por VRAM decrescente antes de emitir.
gpu_list=$(
    for c in /sys/class/drm/card*/device; do
        [ -r "$c/gpu_busy_percent" ] || continue
        v=$(cat "$c/mem_info_vram_total" 2>/dev/null) || v=0
        case "$v" in ''|*[!0-9]*) v=0 ;; esac
        printf '%020d %s\n' "$v" "$c"
    done | sort -rn | cut -d' ' -f2-
)

# ── Interface de rede padrão ────────────────────────────────────
# A rota default vive em /proc/net/route: destino 00000000.
net_iface=$(awk '$2 == "00000000" && $1 != "Iface" { print $1; exit }' /proc/net/route 2>/dev/null)

# ── Saída ───────────────────────────────────────────────────────
printf '{\n'
printf '  "cores": %s,\n' "$cores"
printf '  "cpuModel": %s,\n' "$(j_str "$model")"
printf '  "cpu": { "hwmon": %s, "name": %s, "temp": %s, "label": %s, "crit": %s },\n' \
    "$(j_str "$cpu_hwmon")" "$(j_str "$cpu_name")" "$(j_str "$cpu_temp")" \
    "$(j_str "$cpu_label")" "$(j_str "$cpu_crit")"

printf '  "gpus": [\n'
first=1
for c in $gpu_list; do
    [ "$first" = 1 ] || printf ',\n'
    emit_gpu "$c"
    first=0
done
[ "$first" = 1 ] || printf '\n'
printf '  ],\n'

printf '  "net": { "iface": %s }\n' "$(j_str "$net_iface")"
printf '}\n'
