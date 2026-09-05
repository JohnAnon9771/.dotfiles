pragma ComponentBehavior: Bound

//  Uma linha do grimório.
//  O item escolhido usa o gradiente de musgo que o rice já tinha no
//  wofi — continuidade deliberada com o que já funcionava.

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs
import qs.ui

Item {
    id: root

    required property var result
    property bool chosen: false

    signal invoked()

    // Duas linhas de texto não cabem em 30: título e subtítulo
    // encostavam um no outro.
    implicitHeight: 38

    Rectangle {
        anchors.fill: parent
        visible: root.chosen
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0;  color: Theme.alpha(Theme.moss, 0.70) }
            GradientStop { position: 0.35; color: Theme.alpha(Theme.moss, 0.30) }
            GradientStop { position: 0.75; color: "transparent" }
        }
    }

    Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 2
        color: Theme.moss
        visible: root.chosen
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.gold, 0.08)
        visible: hover.containsMouse && !root.chosen
    }

    Row {
        anchors {
            left: parent.left; right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: Theme.pad.roomy
            rightMargin: Theme.pad.roomy
        }
        spacing: Theme.pad.roomy

        // Ícone do aplicativo, ou o glifo do modo.
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18

            IconImage {
                anchors.fill: parent
                implicitSize: 18
                source: root.result.icon || ""
                visible: String(source).length > 0 && status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: !root.result.icon || root.result.icon.length === 0
                text: root.result.glyph || ""
                font.family: Theme.font.mono
                font.pixelSize: Theme.size.base
                color: root.chosen ? Theme.accentLit : Theme.fgDim
                renderType: Text.NativeRendering
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: root.result.title || ""
                font.family: root.result.mono ? Theme.font.mono : Theme.font.carved
                font.pixelSize: Theme.size.base
                font.letterSpacing: root.result.mono ? 0 : Theme.graven(Theme.size.base)
                color: root.chosen ? Theme.ivory : Theme.ash
                renderType: Text.NativeRendering
            }

            Text {
                visible: text.length > 0
                text: root.result.subtitle || ""
                font.family: Theme.font.mono
                font.pixelSize: Theme.size.tiny
                color: root.chosen ? Theme.alpha(Theme.ivory, 0.65) : Theme.fgDim
                renderType: Text.NativeRendering
            }
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.invoked()
    }
}
