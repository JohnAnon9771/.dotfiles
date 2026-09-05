//  Alternador — a runa que acende.

import QtQuick
import qs
import qs.ui

Item {
    id: root

    property string label: ""
    property string detail: ""
    /// A explicação por extenso, no balão. Ver Hint.qml.
    property string hint: ""
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
        id: name

        anchors {
            left: parent.left; leftMargin: Theme.pad.base
            verticalCenter: parent.verticalCenter
        }
        text: root.label
        size: Theme.size.small
        color: root.enabled ? (root.on ? Theme.fgStrong : Theme.ash) : Theme.fgDim
    }

    //  Ancorada nos DOIS lados, alinhada à direita.
    //
    //  Só tinha a âncora da direita e nenhuma largura, então crescia
    //  para a esquerda até onde o texto quisesse — e uma etiqueta longa
    //  escrevia por cima do rótulo. Com o vão fechado ela elide, que é
    //  o certo para uma etiqueta: o que não coube nela não pertencia a
    //  ela, pertence ao balão.
    Rune {
        anchors {
            left: name.right; leftMargin: Theme.pad.base
            right: lamp.left; rightMargin: Theme.pad.base
            verticalCenter: parent.verticalCenter
        }
        horizontalAlignment: Text.AlignRight
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

    //  hoverEnabled fica ligado mesmo com a linha desativada: um sigilo
    //  que não pode ser acionado é justamente o que mais precisa dizer
    //  por quê. Quem para de responder é o clique.
    MouseArea {
        id: area
        anchors.fill: parent
        acceptedButtons: root.enabled ? Qt.LeftButton : Qt.NoButton
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.flipped()
    }

    Hint {
        id: glossary
        anchor: root
        area: area
        text: root.hint
        tint: root.tint
    }
}
