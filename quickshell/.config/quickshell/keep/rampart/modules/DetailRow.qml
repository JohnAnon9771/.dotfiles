//  Uma linha de detalhe: rótulo entalhado à esquerda, valor à direita.

import QtQuick
import qs
import qs.ui

Item {
    id: root

    property string label: ""
    property string value: ""
    property color tint: Theme.fg
    /// >= 0 pinta o valor pela escala de estado.
    property real level: -1
    property int labelWidth: 74

    implicitWidth: labelWidth + Theme.pad.roomy + reading.implicitWidth
    implicitHeight: Math.max(name.implicitHeight, reading.implicitHeight)

    Rune {
        id: name
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: root.labelWidth
        text: root.label
        font.pixelSize: Theme.size.tiny
        color: Theme.fgDim
    }

    Text {
        id: reading
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.small
        color: root.level >= 0 ? Theme.gauge(root.level) : root.tint
        renderType: Text.NativeRendering
    }
}
