#!/usr/bin/env bash
# Roda os testes dos parsers de /proc contra a máquina atual.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$(command -v qml || echo /usr/lib/qt6/bin/qml)"
[ -x "$QML" ] || { echo "qml não encontrado. Instale qt6-declarative." >&2; exit 127; }

QML_XHR_ALLOW_FILE_READ=1 \
QT_QPA_PLATFORM=offscreen \
QT_FORCE_STDERR_LOGGING=1 \
"$QML" "$ROOT/tools/test-parsers.qml" 2>&1 | sed 's/^qml: //'
exit "${PIPESTATUS[0]}"
