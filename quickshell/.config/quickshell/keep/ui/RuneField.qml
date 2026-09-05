pragma ComponentBehavior: Bound

//  FENDA ENTALHADA — campo de entrada.
//  Sem caixa: uma ranhura na pedra com fio dourado embaixo.
//  O fio acende quando você escreve nela.

import QtQuick
import qs

FocusScope {
    id: root

    property alias text: field.text
    property alias placeholder: ghost.text
    property alias echoMode: field.echoMode
    property alias inputField: field
    property color accent: Theme.accent
    property bool erring: false
    property int fontSize: Theme.size.base

    signal accepted()
    signal cancelled()

    implicitHeight: field.implicitHeight + Theme.pad.snug * 2
    implicitWidth: 200

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.crypt, 0.5)
        radius: Theme.radius
        border.width: Theme.border.inner
        border.color: Theme.alpha(Theme.borderInner, 0.8)
    }

    TextInput {
        id: field
        anchors {
            fill: parent
            leftMargin: Theme.pad.base
            rightMargin: Theme.pad.base
        }
        verticalAlignment: TextInput.AlignVCenter
        focus: true

        font.family: Theme.font.mono
        font.pixelSize: root.fontSize
        color: root.erring ? Theme.blood : Theme.fgStrong
        selectionColor: Theme.alpha(Theme.moss, 0.7)
        selectedTextColor: Theme.ivory
        passwordCharacter: "▪"
        clip: true

        onAccepted: root.accepted()
        Keys.onEscapePressed: root.cancelled()

        cursorDelegate: Rectangle {
            width: 1
            color: root.accent
            visible: field.activeFocus
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: field.activeFocus
                NumberAnimation { to: 0.15; duration: 620; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0;  duration: 620; easing.type: Easing.InOutQuad }
            }
        }
    }

    Text {
        id: ghost
        anchors {
            left: parent.left; leftMargin: Theme.pad.base
            verticalCenter: parent.verticalCenter
        }
        visible: field.text.length === 0
        font.family: Theme.font.carved
        font.pixelSize: root.fontSize - 1
        font.letterSpacing: Theme.runic(root.fontSize - 1)
        font.capitalization: Font.AllUppercase
        color: Theme.fgDim
        renderType: Text.NativeRendering
    }

    // O fio dourado: apagado em repouso, aceso em foco, sangrando em erro.
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: root.erring ? Theme.blood
             : field.activeFocus ? root.accent
             : Theme.alpha(Theme.borderInner, 0.9)

        Behavior on color { ColorAnimation { duration: Theme.anim.quick } }
    }
}
