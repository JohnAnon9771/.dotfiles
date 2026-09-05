#!/usr/bin/env bash
# Valida o shell QML sem precisar de um compositor Wayland.
#
# O Quickshell sintetiza o qmldir de cada pasta em tempo de execução,
# e escrever um à mão DESLIGA essa síntese. Então montamos uma árvore
# espelho em /tmp — só links e qmldir gerado — e apontamos o qmllint
# para lá. O repositório continua sem qmldir nenhum.
#
#   ./tools/lint-qml.sh          # só o que importa
#   ./tools/lint-qml.sh -v       # sem filtro

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/quickshell/.config/quickshell/keep"
SHADOW="${TMPDIR:-/tmp}/keep-lint-$$"

QMLLINT="$(command -v qmllint || echo /usr/lib/qt6/bin/qmllint)"
[ -x "$QMLLINT" ] || { echo "qmllint não encontrado. Instale qt6-declarative." >&2; exit 127; }

QT_QML="/usr/lib/qt6/qml"
[ -d "$QT_QML" ] || QT_QML="$(dirname "$QMLLINT")/../qml"

verbose=0
[ "${1:-}" = "-v" ] && verbose=1

# Limitações conhecidas do qmltypes do Quickshell, não erros nossos:
#   · PanelWindow/PopupWindow são QML_UNCREATABLE em C++ e registrados
#     por um proxy que o qmllint não enxerga;
#   · Edges (edges/gravity/adjustment do PopupAnchor), FileViewAdapter
#     e BluetoothAdapter não são exportados declarativamente.
# Rode com -v para ver tudo.
IGNORE='declared as singleton in qmldir'
IGNORE="$IGNORE|Type PanelWindow is not creatable"
IGNORE="$IGNORE|Type PopupWindow is not creatable"
IGNORE="$IGNORE|No type found for property \"(edges|gravity|adjustment)\""
IGNORE="$IGNORE|incomplete type \"FileViewAdapter\""
# Tipos que existem mas nao sao exportados declarativamente
# (BluetoothAdapter, AuthFlow, ...). O runtime resolve; o qmltypes nao.
IGNORE="$IGNORE|not being exposed declaratively"
# GlobalShortcut herda de PostReloadHook, que nao e exportado.
IGNORE="$IGNORE|PostReloadHook was not found"
IGNORE="$IGNORE|Type GlobalShortcut is used but it is not resolved"
IGNORE="$IGNORE|unknown grouped property scope margins"
IGNORE="$IGNORE|Type margins is used but it is not resolved"

trap 'rm -rf "$SHADOW"' EXIT

# ── Monta a árvore espelho com os qmldir que o Quickshell faria ──
build_shadow() {
    local rel dir module dest
    while IFS= read -r dir; do
        rel="${dir#$SRC}"
        rel="${rel#/}"
        dest="$SHADOW/qs${rel:+/$rel}"
        mkdir -p "$dest"

        module="qs"
        [ -n "$rel" ] && module="qs.${rel//\//.}"
        echo "module $module" > "$dest/qmldir"

        for f in "$dir"/*.qml; do
            [ -e "$f" ] || continue
            local base type
            base="$(basename "$f")"
            type="${base%.qml}"
            # O Quickshell só registra arquivos que comecem com maiúscula.
            case "$type" in [A-Z]*) ;; *) continue ;; esac

            ln -sf "$f" "$dest/$base"
            if head -3 "$f" | grep -q '^pragma Singleton'; then
                echo "singleton $type 1.0 $base" >> "$dest/qmldir"
            else
                echo "$type 1.0 $base" >> "$dest/qmldir"
            fi
        done

        # Bibliotecas .js e o resto acompanham para os imports relativos.
        for f in "$dir"/*.js "$dir"/*.sh; do
            [ -e "$f" ] && ln -sf "$f" "$dest/$(basename "$f")"
        done
    done < <(find "$SRC" -type d | sort)
}

build_shadow

fail=0
while IFS= read -r f; do
    rel="${f#$SRC/}"
    shadow_file="$SHADOW/qs/$rel"

    if [ "$verbose" = 1 ]; then
        out="$("$QMLLINT" -I "$QT_QML" -I "$SHADOW" "$shadow_file" 2>&1)"
    else
        out="$("$QMLLINT" -I "$QT_QML" -I "$SHADOW" "$shadow_file" 2>&1 \
            | grep -E '^(Error|Warning): .*\.qml:[0-9]+:[0-9]+:' \
            | grep -viE "$IGNORE")"
    fi

    if [ -n "$out" ]; then
        printf '\033[33m=== %s\033[0m\n%s\n' "$rel" "${out//$SHADOW\/qs\//}"
        fail=1
    fi
done < <(find "$SRC" -name '*.qml' | sort)

if [ "$fail" = 0 ]; then
    printf '\033[32mAs pedras estão assentadas.\033[0m\n'
fi
exit $fail
