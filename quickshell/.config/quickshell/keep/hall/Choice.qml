//  Uma opção numa lista: dispositivo de som, rede, aparelho.

import QtQuick
import qs
import qs.ui

Item {
    id: root

    property string text: ""
    property string detail: ""
    property string glyph: ""
    property bool chosen: false
    property bool busy: false
    property color tint: Theme.moss

    signal picked()

    implicitHeight: 30

    Rectangle {
        anchors.fill: parent
        color: root.chosen ? Theme.alpha(root.tint, 0.22)
             : area.containsMouse ? Theme.alpha(Theme.gold, 0.10)
                                  : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.anim.instant } }
    }

    Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 2
        color: root.tint
        visible: root.chosen
    }

    Text {
        id: mark
        anchors {
            left: parent.left; leftMargin: Theme.pad.base
            verticalCenter: parent.verticalCenter
        }
        text: root.glyph.length > 0 ? root.glyph
            : (root.chosen ? Theme.glyph.fleuron : "◇")
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.small
        color: root.chosen ? root.tint : Theme.fgDim
        renderType: Text.NativeRendering
    }

    Text {
        anchors {
            left: mark.right; leftMargin: Theme.pad.base
            right: side.left; rightMargin: Theme.pad.snug
            verticalCenter: parent.verticalCenter
        }
        text: root.text
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.small
        color: root.chosen ? Theme.fgStrong : Theme.ash
        elide: Text.ElideRight
        renderType: Text.NativeRendering
    }

    Rune {
        id: side
        anchors {
            right: parent.right; rightMargin: Theme.pad.base
            verticalCenter: parent.verticalCenter
        }
        text: root.busy ? "…" : root.detail
        size: Theme.size.tiny
        color: Theme.fgDim
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
    }
}
