//  Rótulo e valor, sem barra.

import QtQuick
import qs
import qs.ui

Item {
    id: root

    property string label: ""
    property string value: ""
    property color tint: Theme.fg

    width: parent ? parent.width : 0
    implicitHeight: Math.max(name.implicitHeight, reading.implicitHeight) + 2

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
        color: root.tint
        elide: Text.ElideRight
        renderType: Text.NativeRendering
    }
}
