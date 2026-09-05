#!/usr/bin/env bash
# Valida a sintaxe do shell QML sem precisar de um compositor Wayland.
#
# O qmllint do Qt não conhece os tipos do Quickshell, então os avisos
# de "module not found" e "unqualified access" a singletons nossos são
# esperados e ficam filtrados. O que sobra é bug de verdade.
#
#   ./tools/lint-qml.sh          # só o que importa
#   ./tools/lint-qml.sh -v       # tudo, sem filtro

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHELL_DIR="$ROOT/quickshell/.config/quickshell/keep"

QMLLINT="$(command -v qmllint || echo /usr/lib/qt6/bin/qmllint)"
if [ ! -x "$QMLLINT" ]; then
    echo "qmllint não encontrado. Instale qt6-declarative." >&2
    exit 127
fi

verbose=0
[ "${1:-}" = "-v" ] && verbose=1

cd "$SHELL_DIR" || exit 1

fail=0
while IFS= read -r f; do
    if [ "$verbose" = 1 ]; then
        out="$("$QMLLINT" "$f" 2>&1)"
    else
        out="$("$QMLLINT" "$f" 2>&1 \
            | grep -E '\.qml:[0-9]+:[0-9]+: (Error|Warning)' \
            | grep -viE 'was not found|Unqualified access|Warnings occurred while importing')"
    fi
    if [ -n "$out" ]; then
        printf '\033[33m=== %s\033[0m\n%s\n' "$f" "$out"
        fail=1
    fi
done < <(find . -name '*.qml' | sort)

if [ "$fail" = 0 ]; then
    printf '\033[32mAs pedras estão assentadas.\033[0m\n'
fi
exit $fail
