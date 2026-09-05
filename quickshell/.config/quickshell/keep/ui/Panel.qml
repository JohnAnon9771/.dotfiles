//  PAINEL — a moldura de pedra padrão.
//  Borda externa de ferro, fundo de salão, e fleurões nos quatro
//  cantos. Nenhum canto fica nu.

import QtQuick
import qs

Rectangle {
    id: root

    default property alias content: inner.data
    property int padding: Theme.pad.roomy
    property bool fleurons: true

    color: Theme.bgPanel
    radius: Theme.radius
    border.width: Theme.border.outer
    border.color: Theme.borderOuter

    // Fio interno de madeira — dá espessura à parede.
    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.border.outer
        color: "transparent"
        border.width: Theme.border.inner
        border.color: Theme.alpha(Theme.borderInner, 0.7)
        radius: Theme.radius
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.padding
    }

    Fleuron { visible: root.fleurons; anchors { left: parent.left; top: parent.top; leftMargin: 3; topMargin: 2 } }
    Fleuron { visible: root.fleurons; anchors { right: parent.right; top: parent.top; rightMargin: 3; topMargin: 2 } }
    Fleuron { visible: root.fleurons; anchors { left: parent.left; bottom: parent.bottom; leftMargin: 3; bottomMargin: 2 } }
    Fleuron { visible: root.fleurons; anchors { right: parent.right; bottom: parent.bottom; rightMargin: 3; bottomMargin: 2 } }
}
