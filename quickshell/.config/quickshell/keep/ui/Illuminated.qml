//  CAPITULAR — título com a primeira letra iluminada.
//  A inicial em blackletter dourado, o resto entalhado em pedra.
//  É o único lugar onde o Unifraktur é legível: grande e sozinho.
//
//  Nada de Row aqui: as duas vozes têm métricas diferentes e
//  precisam compartilhar a linha de base, não o topo.

import QtQuick
import qs

Item {
    id: root

    property string text: ""
    property color initialColor: Theme.accent
    property color restColor: Theme.fg
    property int initialSize: Theme.size.display
    property int restSize: Theme.size.title
    property int gap: 1

    implicitWidth: cap.implicitWidth + root.gap + rest.implicitWidth
    implicitHeight: Math.max(cap.implicitHeight, rest.implicitHeight)

    Text {
        id: rest

        anchors.left: cap.right
        anchors.leftMargin: root.gap
        anchors.bottom: parent.bottom

        text: root.text.substring(1)
        font.family: Theme.font.carved
        font.pixelSize: root.restSize
        font.letterSpacing: Theme.runic(root.restSize)
        font.capitalization: Font.AllUppercase
        color: root.restColor
        renderType: Text.NativeRendering
    }

    Text {
        id: cap

        anchors.left: parent.left
        anchors.baseline: rest.baseline

        text: root.text.length > 0 ? root.text.charAt(0) : ""
        font.family: Theme.font.scribe
        font.pixelSize: root.initialSize
        color: root.initialColor
    }
}
