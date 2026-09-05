//  Alternador — a runa que acende.

import QtQuick
import qs
import qs.ui

Item {
    id: root

    property string label: ""
    property string detail: ""
    property bool on: false
    property color tint: Theme.moss

    signal flipped()

    implicitHeight: 30

    Rectangle {
        anchors.fill: parent
        color: area.containsMouse ? Theme.alpha(Theme.gold, 0.08) : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.anim.instant } }
    }

    Rune {
        anchors {
            left: parent.left; leftMargin: Theme.pad.base
            verticalCenter: parent.verticalCenter
        }
        text: root.label
        size: Theme.size.small
        color: root.enabled ? (root.on ? Theme.fgStrong : Theme.ash) : Theme.fgDim
    }

    Rune {
        anchors {
            right: lamp.left; rightMargin: Theme.pad.base
            verticalCenter: parent.verticalCenter
        }
        text: root.detail
        size: Theme.size.tiny
        color: Theme.fgDim
    }

    // A lâmpada: uma barra que enche, não um interruptor de celular.
    Rectangle {
        id: lamp

        anchors {
            right: parent.right; rightMargin: Theme.pad.base
            verticalCenter: parent.verticalCenter
        }
        width: 30
        height: 12
        color: Theme.alpha(Theme.crypt, 0.8)
        border.width: 1
        border.color: root.on ? root.tint : Theme.borderInner

        Behavior on border.color { ColorAnimation { duration: Theme.anim.quick } }

        Rectangle {
            anchors.margins: 2
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.on ? parent.width - 4 : 0
            color: root.enabled ? root.tint : Theme.fgDim
            opacity: root.on ? 1 : 0

            Behavior on width { NumberAnimation { duration: Theme.anim.base; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: Theme.anim.quick } }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.flipped()
    }
}
