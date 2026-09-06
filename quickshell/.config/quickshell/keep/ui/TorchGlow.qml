//  BRILHO DE TOCHA — o halo por trás do que está aceso.
//  Coloque atrás do alvo (z negativo). Só o elemento ativo brilha.
//
//  Isto é um MultiEffect com shadowEnabled: um passe de blur, que a
//  §1.3 da doutrina desaconselha para sombra. Ele fica porque o halo
//  do numeral em foco é a assinatura da muralha — mas com duas rédeas
//  que faltavam:
//
//  1. `visible` desliga o efeito quando não há o que acender. Ele
//     vive dentro do Repeater dos workspaces, então SEM isto havia um
//     framebuffer offscreen por flâmula, permanente, inclusive nos que
//     estavam com strength 0.
//
//  2. O `Behavior on shadowOpacity` foi embora. O Workspaces.qml já
//     comentava que não se anima strength num MultiEffect — mas a
//     dependência tinha entrado por baixo: strength saía de
//     Theme.glowStrength, que sai de `heat`, que muda com a carga da
//     máquina. Cada degrau de carga abria 380 ms de re-blur, em todas
//     as flâmulas ao mesmo tempo.

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

    // Sem luz para dar, o efeito não precisa existir na árvore.
    visible: root.strength > 0.01

    autoPaddingEnabled: true
    shadowEnabled: true
    shadowColor: root.glow
    shadowBlur: root.spread
    shadowOpacity: root.strength
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 0
}
