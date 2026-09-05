//  O SINO — notificações por ler.
//  O selo de cera conta quantas esperam na cripta.

import QtQuick
import qs
import qs.ui
import qs.rampart
import qs.services

Segment {
    id: root

    signal openCrypt()

    hoverTint: Theme.gold
    spacing: 0

    onActivated: root.openCrypt()
    onSecondary: Notifs.toggleDnd()

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: glyph.implicitWidth + 6
        height: parent.height

        Text {
            id: glyph
            anchors.centerIn: parent
            text: Notifs.dnd ? "󰂛" : Notifs.unread > 0 ? "󰂚" : "󰂜"
            font.family: Theme.font.mono
            font.pixelSize: Theme.size.base
            color: Notifs.dnd ? Theme.verdigris
                 : Notifs.unread > 0 ? Theme.gold
                                     : Theme.fgDim
            renderType: Text.NativeRendering

            Behavior on color { ColorAnimation { duration: Theme.anim.quick } }
        }

        // O selo, no canto do sino.
        WaxSeal {
            anchors { right: parent.right; top: parent.top; topMargin: Theme.pad.tight }
            visible: Notifs.unread > 0 && !Notifs.dnd

            implicitWidth: 13
            implicitHeight: 13
            wax: Notifs.anyCritical ? Theme.blood : Theme.gold
            glyph: Notifs.unread > 9 ? "+" : String(Notifs.unread)
            glyphColor: Theme.crypt
        }
    }
}
