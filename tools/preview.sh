#!/usr/bin/env bash
# Renderiza uma folha de prova visual do torreão num PNG, offscreen.
# Não toca na sessão Wayland do usuário.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/quickshell/.config/quickshell/keep"
OUT="${1:-$ROOT/preview.png}"
SHADOW="${TMPDIR:-/tmp}/keep-preview-$$"
trap 'rm -rf "$SHADOW"' EXIT

# Mesma árvore-espelho do lint: qmldir gerado, arquivos por link.
while IFS= read -r dir; do
    rel="${dir#$SRC}"; rel="${rel#/}"
    dest="$SHADOW/qs${rel:+/$rel}"
    mkdir -p "$dest"
    module="qs"; [ -n "$rel" ] && module="qs.${rel//\//.}"
    echo "module $module" > "$dest/qmldir"
    for f in "$dir"/*.qml; do
        [ -e "$f" ] || continue
        base="$(basename "$f")"; type="${base%.qml}"
        case "$type" in [A-Z]*) ;; *) continue ;; esac
        ln -sf "$f" "$dest/$base"
        if head -3 "$f" | grep -q '^pragma Singleton'; then
            echo "singleton $type 1.0 $base" >> "$dest/qmldir"
        else
            echo "$type 1.0 $base" >> "$dest/qmldir"
        fi
    done
    for f in "$dir"/*.js; do [ -e "$f" ] && ln -sf "$f" "$dest/$(basename "$f")"; done
done < <(find "$SRC" -type d | sort)

QML="$(command -v qml || echo /usr/lib/qt6/bin/qml)"
QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 \
    "$QML" -I /usr/lib/qt6/qml -I "$SHADOW" \
    --apptype gui "$ROOT/tools/preview.qml" \
    --  2>&1 | sed 's/^qml: //'

[ -f "$OUT" ] && echo "→ $OUT"
