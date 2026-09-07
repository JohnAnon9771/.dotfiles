//  Botão entalhado — usado no Selo e no que mais precisar.

import QtQuick
import qs
import qs.ui

Rectangle {
    id: root

    property alias text: label.text
    property bool primary: false

    signal chosen()

    implicitWidth: label.implicitWidth + Theme.pad.vast
    implicitHeight: 28

    color: area.containsMouse
        ? Theme.alpha(root.primary ? Theme.gold : Theme.scar, 0.30)
        : Theme.alpha(Theme.timber, 0.85)

    border.width: 1
    border.color: area.containsMouse
        ? (root.primary ? Theme.gold : Theme.scar)
        : Theme.borderInner

    Behavior on color { ColorAnimation { duration: Theme.anim.instant } }

    Rune {
        id: label
        anchors.centerIn: parent
        size: Theme.size.small
        color: area.containsMouse ? Theme.fgStrong : Theme.fg
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.chosen()
    }
}
