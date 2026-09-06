pragma ComponentBehavior: Bound

//  A FORJA — a CPU.

import QtQuick
import qs
import qs.ui
import qs.rampart
import qs.services

Readout {
    id: root

    glyph: Theme.glyph.cpu
    value: Fmt.pct(Sys.cpuUsage)
    reserve: "100%"
    tint: Theme.ash
    level: Sys.cpuUsage
    samples: Sys.cpuHistory

    popup: Component {
        DetailCard {
            title: "Forja"

            Attention { service: Sys }

            DetailRow {
                label: "carga"
                value: Fmt.pct(Sys.cpuUsage, 1)
                level: Sys.cpuUsage
            }
            DetailRow {
                label: "calor"
                value: Fmt.temp(Sys.cpuTemp) + "  " + (Probe.cpu.label || "")
                level: Sys.thermalPressure
            }
            DetailRow {
                label: "média"
                value: Sys.load1.toFixed(2) + " · " + Sys.load5.toFixed(2)
                       + " · " + Sys.load15.toFixed(2)
            }
            DetailRow {
                label: "almas"
                value: Sys.procRunning + " de " + Sys.procTotal
            }
            DetailRow {
                label: "vigília"
                value: Fmt.duration(Sys.uptime)
            }

            // Um fio por thread. Doze fios contam mais que um número.
            Item { height: Theme.pad.snug; width: 1 }

            Row {
                spacing: 2

                Repeater {
                    model: Sys.coreUsage

                    Rectangle {
                        id: thread

                        required property real modelData

                        width: 7
                        height: 26
                        color: Theme.alpha(Theme.crypt, 0.6)

                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: Math.max(1, parent.height * thread.modelData)
                            color: Theme.gauge(thread.modelData)
                            Behavior on height { NumberAnimation { duration: Theme.anim.base } }
                        }
                    }
                }
            }
        }
    }
}
