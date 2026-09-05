//  Rótulo e valor, sem depender dos módulos da muralha.

import QtQuick
import qs
import qs.ui

Item {
    id: root

    property string label: ""
    property string value: ""

    implicitHeight: Math.max(name.implicitHeight, reading.implicitHeight)

    Rune {
        id: name
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        size: Theme.size.tiny
        color: Theme.fgDim
    }

    Text {
        id: reading
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.small
        color: Theme.fg
        renderType: Text.NativeRendering
    }
}
