//  CORRENTE — separador de seção.
//  Não é uma linha: é um fio com um elo no meio, pendurado.

import QtQuick
import qs

Item {
    id: root

    property bool vertical: false
    property color wire: Theme.borderInner
    property color link: Theme.alpha(Theme.gold, 0.5)

    implicitWidth: vertical ? 1 : 80
    implicitHeight: vertical ? 40 : Theme.size.tiny

    Rectangle {
        anchors.centerIn: parent
        width: root.vertical ? 1 : parent.width
        height: root.vertical ? parent.height : 1
        color: root.wire
    }

    Rectangle {
        anchors.centerIn: parent
        width: 5; height: 5
        rotation: 45
        color: Theme.bgPanel
        border.width: 1
        border.color: root.link
    }
}
