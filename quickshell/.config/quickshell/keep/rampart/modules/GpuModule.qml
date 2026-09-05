pragma ComponentBehavior: Bound

//  A FORJA MAIOR — a placa de vídeo.
//  O buraco que motivou esta reconstrução: a barra antiga não
//  mostrava GPU nenhuma.

import QtQuick
import qs
import qs.ui
import qs.rampart
import qs.services

Readout {
    id: root

    visible: Gpu.present

    glyph: "◈"
    value: Fmt.pct(Gpu.usage)
    tint: Theme.moat
    level: Math.max(Gpu.usage, Gpu.thermalPressure)
    samples: Gpu.history

    popup: Component {
        DetailCard {
            title: Gpu.name

            DetailRow {
                label: "núcleo"
                value: Fmt.pct(Gpu.usage, 1)
                level: Gpu.usage
            }
            DetailRow {
                visible: Gpu.has.memBusy === true
                label: "memória"
                value: Fmt.pct(Gpu.memBusy, 1)
                level: Gpu.memBusy
            }
            DetailRow {
                label: "vram"
                value: Fmt.bytes(Gpu.vramUsed) + " / " + Fmt.bytes(Gpu.vramTotal)
                level: Gpu.vramUsage
            }

            Item { height: Theme.pad.tight; width: 1 }

            // Na Radeon quem manda no throttle é a junction, não a
            // edge. As três juntas contam a história inteira.
            DetailRow {
                label: "borda"
                value: Fmt.temp(Gpu.tempEdge)
                level: Gpu.tempEdge / Gpu.critEdge
            }
            DetailRow {
                visible: Gpu.has.tempJunc === true
                label: "junção"
                value: Fmt.temp(Gpu.tempJunction)
                level: Gpu.tempJunction / Gpu.critJunction
            }
            DetailRow {
                visible: Gpu.has.tempMem === true
                label: "vram °"
                value: Fmt.temp(Gpu.tempMemory)
                level: Gpu.tempMemory / Gpu.critMemory
            }

            Item { height: Theme.pad.tight; width: 1 }

            DetailRow {
                visible: Gpu.has.power === true
                label: "potência"
                value: Gpu.powerCapW > 0
                    ? Fmt.watts(Gpu.powerUw) + " / " + Math.round(Gpu.powerCapW) + " W"
                    : Fmt.watts(Gpu.powerUw)
                level: Gpu.powerUsage
            }
            DetailRow {
                visible: Gpu.has.fan === true
                label: "ventoinha"
                value: Gpu.fanIdle ? "em repouso" : Gpu.fanRpm + " rpm"
                tint: Gpu.fanIdle ? Theme.verdigris : Theme.fg
            }
            DetailRow {
                visible: Gpu.has.sclk === true
                label: "relógio"
                value: Fmt.hertz(Gpu.sclk) + "Hz"
                       + (Gpu.has.mclk === true ? "  ·  vram " + Fmt.hertz(Gpu.mclk) + "Hz" : "")
            }
            DetailRow {
                visible: Gpu.link.length > 0
                label: "barramento"
                value: Gpu.link
            }
        }
    }
}
