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

    readonly property color liveTint: value < 0.6
        ? tint
        : Theme.mix(tint, Theme.gauge(value), (value - 0.6) / 0.4)

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
            width: parent.width * Math.max(0, Math.min(1, root.value))
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
