pragma Singleton

//  ╔═══════════════════════════════════════════════════════════════╗
//  ║  O ATLAS                                                      ║
//  ║  Onde cada sprite mora dentro do PNG. Uma textura, um draw.   ║
//  ╚═══════════════════════════════════════════════════════════════╝
//
//  GERADO por tools/atlas-gen.py a partir da arte. NAO EDITE.
//  Para mudar a arte, mude o mapa de caracteres lá e rode:
//      tools/atlas-gen.py --write

import QtQuick
import Quickshell

Singleton {
    /// O PNG. Resolvido a partir DESTE arquivo, para o caminho não
    /// depender de quem importa.
    readonly property url source: Qt.resolvedUrl("atlas.png")

    readonly property int cell: 12
    readonly property int sheetWidth: 96
    readonly property int sheetHeight: 12

    /// O retângulo da célula `n`, em pixels do atlas.
    function rect(n) {
        return Qt.rect((n % 8) * cell, Math.floor(n / 8) * cell,
                       cell, cell);
    }

    readonly property int gargoyleShut: 0
    readonly property int gargoyleOpen: 1
    readonly property int gargoyleWatch: 2
    readonly property int gargoyleAlarm: 3
    readonly property int gargoyleCrack: 4
}
