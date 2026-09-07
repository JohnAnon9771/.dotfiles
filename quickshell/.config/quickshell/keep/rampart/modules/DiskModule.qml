pragma ComponentBehavior: Bound

//  AS ADEGAS — espaço em disco.

import QtQuick
import qs
import qs.ui
import qs.rampart
import qs.services

Readout {
    id: root

    glyph: Theme.glyph.disk
    value: Fmt.bytes(Disks.rootFree)
    reserve: "88.8T"
    tint: Theme.ash
    level: Disks.rootUsage

    popup: Component {
        DetailCard {
            title: "Adegas"

            // O df agora só corre de cinco em cinco minutos; abrir o
            // cartão manda colher na hora, para o número que se OLHA
            // nunca ser o velho.
            Attention { service: Disks }
        Component.onCompleted: Disks.refresh()

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
                value: Fmt.rate(Disks.readRate)
                tint: Theme.ash
            }
            DetailRow {
                label: "escrita"
                labelWidth: 96
                value: Fmt.rate(Disks.writeRate)
                tint: Theme.gold
            }
        }
    }
}
