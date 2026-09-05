//  BRILHO DE TOCHA — o halo por trás do que está aceso.
//  Coloque atrás do alvo (z negativo). Só o elemento ativo brilha.

import QtQuick
import QtQuick.Effects
import qs

MultiEffect {
    id: root

    /// O item que emite luz. O efeito se ancora nele.
    property Item target
    property color glow: Theme.accentLit
    property real strength: 0.7 * Theme.glowStrength
    property real spread: 1.0

    source: target
    anchors.fill: target
    z: -1

    autoPaddingEnabled: true
    shadowEnabled: true
    shadowColor: root.glow
    shadowBlur: root.spread
    shadowOpacity: root.strength
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 0

    Behavior on shadowOpacity {
        NumberAnimation { duration: Theme.anim.slow; easing.type: Easing.OutCubic }
    }
}
