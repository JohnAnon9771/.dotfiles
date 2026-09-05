pragma ComponentBehavior: Bound

//  AS ADEGAS — espaço em disco.

import QtQuick
import qs
import qs.ui
import qs.rampart
import qs.services

Readout {
    id: root

    glyph: "⛃"
    value: Fmt.bytes(Disks.rootFree)
    tint: Theme.teal
    level: Disks.rootUsage

    popup: Component {
        DetailCard {
            title: "Adegas"

            Repeater {
                model: Disks.mounts

                DetailRow {
                    required property var modelData

                    label: modelData.mount
                    labelWidth: 96
                    value: Fmt.bytes(modelData.avail) + " livres"
                    level: modelData.usage
                }
            }

            Item { height: Theme.pad.snug; width: 1 }

            DetailRow {
                label: "leitura"
                labelWidth: 96
                value: Fmt.rate(Disks.readRate) + "/s"
                tint: Theme.moat
            }
            DetailRow {
                label: "escrita"
                labelWidth: 96
                value: Fmt.rate(Disks.writeRate) + "/s"
                tint: Theme.gold
            }
        }
    }
}
