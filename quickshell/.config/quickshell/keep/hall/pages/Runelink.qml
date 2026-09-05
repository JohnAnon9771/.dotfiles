pragma ComponentBehavior: Bound

//  O ELO RÚNICO — bluetooth.

import QtQuick
import qs
import qs.ui
import qs.hall
import qs.services

Column {
    id: root

    spacing: Theme.pad.wide

    Section {
        title: "Elo"

        Toggle {
            width: parent.width
            label: "runas acesas"
            detail: Bt.blocked ? "travado no hardware" : (Bt.busy ? "…" : "")
            on: Bt.enabled
            enabled: Bt.available && !Bt.blocked
            onFlipped: Bt.toggle()
        }

        Toggle {
            width: parent.width
            visible: Bt.enabled
            label: "procurar"
            on: Bt.discovering
            tint: Theme.wraith
            onFlipped: Bt.toggleScan()
        }

        Rune {
            visible: !Bt.available
            text: "Nenhum adaptador respondeu."
            size: Theme.size.small
            color: Theme.fgDim
        }
    }

    Section {
        title: "Aparelhos"
        visible: Bt.enabled

        Repeater {
            model: Bt.sorted

            Choice {
                required property var modelData

                width: parent.width
                text: Bt.label(modelData)
                chosen: modelData.connected
                busy: modelData.pairing
                glyph: modelData.connected ? Theme.glyph.btOn : Theme.glyph.bt
                tint: Theme.royal
                detail: {
                    const b = Bt.battery(modelData);
                    const s = Bt.status(modelData);
                    return b >= 0 ? s + " · " + Fmt.pct(b) : s;
                }
                onPicked: Bt.engage(modelData)
            }
        }

        Rune {
            visible: Bt.sorted.length === 0
            text: Lore.empty("bluetooth")
            size: Theme.size.small
            color: Theme.fgDim
        }
    }
}
