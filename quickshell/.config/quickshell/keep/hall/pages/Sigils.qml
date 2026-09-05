pragma ComponentBehavior: Bound

//  SIGILOS — os alternadores rápidos.

import QtQuick
import Quickshell
import qs
import qs.ui
import qs.hall
import qs.services

Column {
    id: root

    spacing: Theme.pad.wide

    signal action(string what)

    Section {
        title: "Sigilos"

        Toggle {
            width: parent.width
            label: "não perturbe"
            detail: Notifs.unread > 0 ? Notifs.unread + " por ler" : ""
            on: Notifs.dnd
            tint: Theme.gold
            onFlipped: Notifs.toggleDnd()
        }

        Toggle {
            width: parent.width
            label: "vigília eterna"
            detail: Idle.inhibited ? "o castelo não dorme" : ""
            on: Idle.inhibited
            tint: Theme.wraith
            onFlipped: Idle.toggleInhibit()
        }

        Toggle {
            width: parent.width
            label: "véu de âmbar"
            detail: "modo noturno"
            on: Settings.data.nightLight
            tint: Theme.ember
            onFlipped: Settings.toggleNightLight()
        }

        Toggle {
            width: parent.width
            label: "corvos"
            on: Net.wifiEnabled
            enabled: Net.available && !Net.wifiBlocked
            tint: Theme.moat
            onFlipped: Net.toggleWifi()
        }

        Toggle {
            width: parent.width
            label: "elo rúnico"
            on: Bt.enabled
            enabled: Bt.available
            tint: Theme.royal
            onFlipped: Bt.toggle()
        }

        Toggle {
            width: parent.width
            label: "névoa à deriva"
            detail: "custa GPU"
            on: Settings.data.fog
            tint: Theme.teal
            onFlipped: Settings.toggleFog()
        }
    }

    Section {
        title: "Atos"

        Choice {
            width: parent.width
            text: "Capturar uma região"
            glyph: Theme.glyph.fleuron
            onPicked: Quickshell.execDetached(["keep-shot", "region"])
        }

        Choice {
            width: parent.width
            text: "Modo jogo"
            glyph: Theme.glyph.keep
            onPicked: Quickshell.execDetached(["gamer-vt"])
        }

        Choice {
            width: parent.width
            text: "Reerguer o torreão"
            glyph: Theme.glyph.fleuron
            onPicked: Quickshell.reload(true)
        }

        Choice {
            width: parent.width
            text: "Refazer a sondagem dos sensores"
            glyph: Theme.glyph.cpu
            detail: Probe.error.length > 0 ? Probe.error : ""
            onPicked: Probe.rescan()
        }

        Choice {
            width: parent.width
            text: "Ossuário"
            glyph: Theme.glyph.power
            tint: Theme.blood
            onPicked: root.action("ossuary")
        }
    }
}
