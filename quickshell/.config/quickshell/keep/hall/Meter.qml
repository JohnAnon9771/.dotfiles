//  Barra de medida com rótulo e leitura.
//  Como no resto do castelo, a cor guarda a identidade em repouso e
//  só desliza para a escala de estado quando aperta.

import QtQuick
import qs
import qs.ui

Item {
    id: root

    property string label: ""
    property string reading: ""
    /// 0..1
    property real value: 0
    property color tint: Theme.accent
    property int barHeight: 5

    /// Em quantos degraus a barra enxerga o 0..1. Ver Fmt.step().
    ///
    /// A barra tem quase 400 px, então vinte degraus dão saltos de 19 px
    /// — visíveis, mas com os 220 ms de OutCubic em cima eles leem como
    /// movimento, não como pulo. O que não podia continuar era o outro
    /// extremo: `value` vem cru do serviço, e o ruído de leitura reabria
    /// os dois Behaviors a cada amostra de 2 s. São doze Meters só na
    /// Vigília — o Salão renderizava a 60 fps com a máquina parada.
    property int steps: 20

    readonly property real level: Fmt.step(root.value, root.steps)

    readonly property color liveTint: level < 0.6
        ? tint
        : Theme.mix(tint, Theme.gauge(level), (level - 0.6) / 0.4)

    implicitHeight: name.implicitHeight + barHeight + 5
    width: parent ? parent.width : 0

    Rune {
        id: name
        anchors.left: parent.left
        anchors.top: parent.top
        text: root.label
        size: Theme.size.tiny
        color: Theme.fgDim
    }

    Text {
        anchors.right: parent.right
        anchors.baseline: name.baseline
        text: root.reading
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.small
        color: Theme.fg
        renderType: Text.NativeRendering
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: root.barHeight
        color: Theme.alpha(Theme.crypt, 0.75)

        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: parent.width * root.level
            color: root.liveTint

            Behavior on width {
                NumberAnimation { duration: Theme.anim.base; easing.type: Easing.OutCubic }
            }
            Behavior on color { ColorAnimation { duration: Theme.anim.slow } }
        }

        // O fio de imposta, como nos medidores de pedra.
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 1
            color: Theme.alpha(Theme.borderInner, 0.9)
        }
    }
}
