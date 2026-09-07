//  ALAVANCA — o controle de volume.
//  Uma corda que se puxa: barra entalhada, sem botão redondo.

import QtQuick
import qs
import qs.ui

Item {
    id: root

    property string label: ""
    property string glyph: ""
    property real value: 0
    property bool muted: false
    property color tint: Theme.moss

    signal moved(real v)
    signal toggled()

    implicitHeight: 30

    readonly property color live: root.muted ? Theme.verdigris : root.tint

    // O glifo também é o botão de mudo.
    Text {
        id: icon

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 20
        text: root.glyph
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.base
        color: root.muted ? Theme.scar : root.tint
        renderType: Text.NativeRendering

        Behavior on color { ColorAnimation { duration: Theme.anim.quick } }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()
        }
    }

    Rune {
        id: name
        anchors.left: icon.right
        anchors.leftMargin: Theme.pad.snug
        anchors.top: parent.top
        visible: root.label.length > 0
        width: parent.width - icon.width - reading.width - Theme.pad.wide
        text: root.label
        size: Theme.size.tiny
        color: Theme.fgDim
    }

    Text {
        id: reading
        anchors.right: parent.right
        anchors.top: parent.top
        text: root.muted ? "silenciado" : Fmt.pct(root.value)
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.small
        color: root.muted ? Theme.fgDim : Theme.fg
        renderType: Text.NativeRendering
    }

    Item {
        id: track

        anchors {
            left: icon.right
            leftMargin: Theme.pad.snug
            right: parent.right
            bottom: parent.bottom
            bottomMargin: 4
        }
        height: 7

        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.crypt, 0.75)
            border.width: 1
            border.color: Theme.alpha(Theme.borderInner, 0.9)
        }

        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            anchors.margins: 1
            width: Math.max(0, (parent.width - 2) * Math.min(1, root.value))
            color: root.live

            Behavior on color { ColorAnimation { duration: Theme.anim.quick } }
        }

        // A ponta da corda: onde se pega.
        Rectangle {
            x: Math.max(0, Math.min(parent.width - 3, parent.width * root.value - 1))
            width: 3
            height: parent.height + 6
            y: -3
            color: drag.pressed ? Theme.ivory : Theme.alpha(Theme.parchment, 0.85)
            visible: !root.muted
        }

        MouseArea {
            id: drag

            anchors.fill: parent
            anchors.margins: -7
            cursorShape: Qt.PointingHandCursor

            function pick(mx) {
                root.moved(Math.max(0, Math.min(1, (mx - 7) / track.width)));
            }

            onPressed: e => pick(e.x)
            onPositionChanged: e => { if (pressed) pick(e.x); }
            onWheel: e => root.moved(Math.max(0, Math.min(1,
                root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }
}
