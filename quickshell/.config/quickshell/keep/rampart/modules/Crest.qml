pragma ComponentBehavior: Bound

//  O BRASÃO — o nome do castelo.
//  Guarda o ✝ do rice antigo. Na sexta-feira 13 a cruz vira caveira;
//  na hora das bruxas, um corvo pousa ao lado.

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.ui
import qs.rampart

Segment {
    id: root

    property string hostName: "castelo"

    readonly property bool cursed: Settings.data.easterEggs && Lore.cursedDay
    readonly property string mark: cursed ? Theme.glyph.skull : Theme.glyph.cross

    hoverTint: Theme.gold
    padding: Theme.pad.roomy
    spacing: Theme.pad.snug

    popup: Component {
        Epitaph { hostName: root.hostName }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.mark
        // A adaga vive na Cinzel, junto do nome; a caveira é Nerd Font.
        font.family: root.cursed ? Theme.font.mono : Theme.font.carved
        font.pixelSize: Theme.size.base
        color: root.cursed ? Theme.scar : Theme.gold
        renderType: Text.NativeRendering

        Behavior on color { ColorAnimation { duration: Theme.anim.slow } }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.hostName
        font.family: Theme.font.carved
        font.pixelSize: Theme.size.base
        font.letterSpacing: Theme.runic(Theme.size.base)
        font.capitalization: Font.AllUppercase
        font.weight: Font.DemiBold
        color: Theme.gold
        renderType: Text.NativeRendering
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.mark
        font.family: root.cursed ? Theme.font.mono : Theme.font.carved
        font.pixelSize: Theme.size.base
        color: root.cursed ? Theme.scar : Theme.gold
        renderType: Text.NativeRendering
    }

    // O espectro da hora das bruxas.
    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: Settings.data.easterEggs && Lore.witching
        text: Theme.glyph.ghost
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.small
        color: Theme.wraith
        renderType: Text.NativeRendering
    }

    // O nome da máquina, lido uma vez.
    FileView {
        path: "/etc/hostname"
        printErrors: false
        onLoaded: {
            const h = text().trim();
            if (h.length > 0) root.hostName = h;
        }
    }
}
