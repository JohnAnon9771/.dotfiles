//  Uma linha do menu da bandeja.

import QtQuick
import Quickshell
import qs
import qs.ui

Item {
    id: root

    property var entry: null
    property int indent: 0
    property bool opened: false

    signal chosen()

    readonly property bool separator: entry ? entry.isSeparator : false
    readonly property bool usable: entry ? entry.enabled : false

    implicitWidth: root.indent + Theme.pad.snug * 2 + icon.width
                 + label.implicitWidth + Theme.pad.wide
    implicitHeight: separator ? Theme.pad.snug : 24

    // Separador: uma corrente curta, não uma linha.
    Divider {
        anchors.centerIn: parent
        visible: root.separator
        width: parent.width - Theme.pad.base
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.separator
        color: root.opened ? Theme.alpha(Theme.moss, 0.28)
             : area.containsMouse && root.usable ? Theme.alpha(Theme.moss, 0.20)
                                                 : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.anim.instant } }
    }

    Item {
        id: icon

        anchors {
            left: parent.left
            leftMargin: Theme.pad.snug + root.indent
            verticalCenter: parent.verticalCenter
        }
        visible: !root.separator
        width: 15
        height: 15

        Image {
            anchors.fill: parent
            source: root.entry && root.entry.icon ? root.entry.icon : ""
            visible: String(source).length > 0
            sourceSize.width: 30
            sourceSize.height: 30
            smooth: true
            asynchronous: true
        }

        // Caixa de marcação e botão de rádio, no vocabulário do castelo.
        Text {
            anchors.centerIn: parent
            visible: root.entry
                  && root.entry.buttonType !== QsMenuButtonType.None
            text: root.entry && root.entry.checkState === Qt.Checked ? "◈" : "◇"
            font.family: Theme.font.mono
            font.pixelSize: Theme.size.small
            color: root.entry && root.entry.checkState === Qt.Checked
                ? Theme.accent : Theme.fgDim
            renderType: Text.NativeRendering
        }
    }

    Text {
        id: label

        anchors {
            left: icon.right
            leftMargin: Theme.pad.snug
            verticalCenter: parent.verticalCenter
        }
        visible: !root.separator

        text: root.entry ? root.entry.text : ""
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.small
        color: root.usable ? Theme.fg : Theme.fgDim
        renderType: Text.NativeRendering
    }

    Text {
        anchors {
            right: parent.right
            rightMargin: Theme.pad.snug
            verticalCenter: parent.verticalCenter
        }
        visible: root.entry && root.entry.hasChildren
        text: root.opened ? "▾" : "▸"
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.tiny
        color: Theme.fgDim
        renderType: Text.NativeRendering
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: !root.separator && root.usable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.chosen()
    }
}
