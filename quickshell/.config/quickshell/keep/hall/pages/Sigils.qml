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

    //  Os scripts do torreão moram em ~/.local/bin, e o torreão sobe
    //  como unit do systemd: herda o PATH do gerenciador de usuário,
    //  não o do seu shell. O environment.d põe a pasta lá, mas o
    //  caminho inteiro dispensa a aposta — um execDetached que não
    //  acha o binário não devolve erro nenhum, o botão só não faz nada.
    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/"

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
            onPicked: Quickshell.execDetached([root.bin + "keep-shot", "region"])
        }

        Choice {
            width: parent.width
            text: "Modo jogo"
            glyph: Theme.glyph.keep
            onPicked: Quickshell.execDetached([root.bin + "gamer-vt"])
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
