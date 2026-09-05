pragma ComponentBehavior: Bound

//  A DESPENSA — memória.

import QtQuick
import qs
import qs.ui
import qs.rampart
import qs.services

Readout {
    id: root

    glyph: Theme.glyph.ram
    value: Fmt.bytes(Sys.memUsed)
    tint: Theme.royal
    level: Sys.memUsage

    popup: Component {
        DetailCard {
            title: "Despensa"

            DetailRow {
                label: "em uso"
                value: Fmt.bytes(Sys.memUsed) + " / " + Fmt.bytes(Sys.memTotal)
                level: Sys.memUsage
            }
            DetailRow {
                label: "livre"
                value: Fmt.bytes(Sys.memAvailable)
            }
            DetailRow {
                label: "cache"
                value: Fmt.bytes(Sys.memCached)
                tint: Theme.verdigris
            }
            DetailRow {
                visible: Sys.swapTotal > 0
                label: "troca"
                value: Fmt.bytes(Sys.swapUsed) + " / " + Fmt.bytes(Sys.swapTotal)
                level: Sys.swapUsage
            }
        }
    }
}
