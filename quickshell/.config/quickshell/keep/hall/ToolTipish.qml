//  O nome da flâmula, quando o mouse pousa nela.

import QtQuick
import qs
import qs.ui

Rectangle {
    id: root

    property Item anchor: null
    property alias text: label.text
    property bool shown: false

    parent: root.anchor ? root.anchor.parent : null
    x: root.anchor ? root.anchor.x + root.anchor.width + Theme.pad.tight : 0
    y: root.anchor ? root.anchor.y + (root.anchor.height - height) / 2 : 0
    z: 10

    width: label.implicitWidth + Theme.pad.roomy
    height: 22

    color: Theme.bgRaised
    border.width: 1
    border.color: Theme.borderInner

    visible: opacity > 0.01
    opacity: root.shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.anim.quick } }

    Rune {
        id: label
        anchors.centerIn: parent
        size: Theme.size.tiny
        color: Theme.fg
    }
}
