//  A APARIÇÃO — que janela está em foco.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.ui
import qs.rampart

Segment {
    id: root

    property int maxWidth: 420

    // Não chamar de `top`: sombrearia a linha de ancoragem do Item.
    readonly property var focused: Hyprland.activeToplevel
    readonly property string title: focused && focused.title ? focused.title : ""

    interactive: false
    visible: title.length > 0
    implicitWidth: visible ? Math.min(root.maxWidth, label.implicitWidth + padding * 2) : 0

    Text {
        id: label

        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(root.maxWidth - root.padding * 2, implicitWidth)

        text: root.title
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.base
        color: Theme.fgMuted
        elide: Text.ElideRight
        renderType: Text.NativeRendering

        opacity: root.title.length > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim.base } }
    }
}
