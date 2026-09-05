pragma ComponentBehavior: Bound

//  A VIGÍLIA — o que a máquina está fazendo, a fundo.
//  Aqui mora a GPU inteira, que era o buraco principal do setup antigo.

import QtQuick
import qs
import qs.ui
import qs.hall
import qs.services

Column {
    id: root

    spacing: Theme.pad.wide

    // ═══ AS FORJAS ═════════════════════════════════════════════

    Section {
        title: "Forjas"

        Row {
            spacing: Theme.pad.wide

            ShieldGauge {
                implicitWidth: 62
                implicitHeight: 92
                value: Sys.cpuUsage
                charge: Theme.mix(Theme.gold, Theme.gauge(Sys.cpuUsage),
                                  Sys.cpuUsage < 0.6 ? 0 : (Sys.cpuUsage - 0.6) / 0.4)
                label: "cpu"
                reading: Fmt.pct(Sys.cpuUsage)
            }

            ShieldGauge {
                visible: Gpu.present
                implicitWidth: 62
                implicitHeight: 92
                value: Gpu.usage
                charge: Theme.mix(Theme.moat, Theme.gauge(Gpu.usage),
                                  Gpu.usage < 0.6 ? 0 : (Gpu.usage - 0.6) / 0.4)
                label: "gpu"
                reading: Fmt.pct(Gpu.usage)
            }

            ShieldGauge {
                implicitWidth: 62
                implicitHeight: 92
                value: Sys.memUsage
                charge: Theme.mix(Theme.royal, Theme.gauge(Sys.memUsage),
                                  Sys.memUsage < 0.6 ? 0 : (Sys.memUsage - 0.6) / 0.4)
                label: "ram"
                reading: Fmt.pct(Sys.memUsage)
            }

            // Os fios por thread: doze contam mais que um número.
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Rune {
                    text: Probe.cores + " fios"
                    size: Theme.size.tiny
                    color: Theme.fgDim
                }

                Grid {
                    columns: 6
                    rowSpacing: 3
                    columnSpacing: 3

                    Repeater {
                        model: Sys.coreUsage

                        Rectangle {
                            id: thread
                            required property real modelData

                            width: 15
                            height: 15
                            color: Theme.alpha(Theme.crypt, 0.7)

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

        Item { height: Theme.pad.tight; width: 1 }

        Fact {
            label: "forja"
            value: Probe.cpuModel.replace(/\s*\d+-Core Processor\s*/i, "")
        }
        Fact {
            label: "calor"
            value: Fmt.temp(Sys.cpuTemp) + "   " + (Probe.cpu.label || "")
            tint: Sys.feverish ? Theme.blood : Theme.fg
        }
        Fact {
            label: "média de carga"
            value: Sys.load1.toFixed(2) + "  ·  " + Sys.load5.toFixed(2)
                 + "  ·  " + Sys.load15.toFixed(2)
        }
        Fact {
            label: "almas"
            value: Sys.procRunning + " correndo de " + Sys.procTotal
        }
        Fact {
            label: "vigília"
            value: Fmt.duration(Sys.uptime)
        }
    }

    // ═══ A FORJA MAIOR ═════════════════════════════════════════

    Section {
        title: "Placa"
        visible: Gpu.present

        Fact { label: "nome"; value: Gpu.name }

        Meter {
            label: "núcleo"
            value: Gpu.usage
            reading: Fmt.pct(Gpu.usage)
            tint: Theme.moat
        }

        Meter {
            visible: Gpu.has.memBusy === true
            label: "controlador de memória"
            value: Gpu.memBusy
            reading: Fmt.pct(Gpu.memBusy)
            tint: Theme.teal
        }

        Meter {
            label: "vram"
            value: Gpu.vramUsage
            reading: Fmt.bytes(Gpu.vramUsed) + " / " + Fmt.bytes(Gpu.vramTotal)
            tint: Theme.royal
        }

        Item { height: Theme.pad.tight; width: 1 }

        // Numa Radeon quem dispara o throttle é a junção, não a borda.
        Meter {
            label: "borda"
            value: Gpu.tempEdge / Gpu.critEdge
            reading: Fmt.temp(Gpu.tempEdge)
            tint: Theme.ember
        }
        Meter {
            visible: Gpu.has.tempJunc === true
            label: "junção"
            value: Gpu.tempJunction / Gpu.critJunction
            reading: Fmt.temp(Gpu.tempJunction) + "  de " + Math.round(Gpu.critJunction) + "°"
            tint: Theme.ember
        }
        Meter {
            visible: Gpu.has.tempMem === true
            label: "memória"
            value: Gpu.tempMemory / Gpu.critMemory
            reading: Fmt.temp(Gpu.tempMemory)
            tint: Theme.ember
        }

        Item { height: Theme.pad.tight; width: 1 }

        Meter {
            visible: Gpu.has.power === true && Gpu.powerCapW > 0
            label: "potência"
            value: Gpu.powerUsage
            reading: Fmt.watts(Gpu.powerUw) + " de " + Math.round(Gpu.powerCapW) + " W"
            tint: Theme.gold
        }
        Meter {
            visible: Gpu.has.fan === true && Gpu.fanMax > 0
            label: "ventoinha"
            value: Gpu.fanUsage
            reading: Gpu.fanIdle ? "em repouso" : Gpu.fanRpm + " rpm"
            tint: Gpu.fanIdle ? Theme.verdigris : Theme.wraith
        }

        Fact {
            visible: Gpu.has.sclk === true
            label: "relógio"
            value: Fmt.hertz(Gpu.sclk) + "Hz"
                 + (Gpu.has.mclk === true ? "   vram " + Fmt.hertz(Gpu.mclk) + "Hz" : "")
        }
        Fact {
            visible: Gpu.link.length > 0
            label: "barramento"
            value: Gpu.link
        }

        // A outra placa, quando há duas. Numa máquina Ryzen a iGPU
        // do processador está sempre lá.
        Fact {
            visible: Gpu.all.length > 1
            label: "também há"
            value: {
                const others = [];
                for (let i = 0; i < Gpu.all.length; i++) {
                    if (Gpu.all[i] === Gpu.card) continue;
                    others.push(Gpu.gpuName(Gpu.all[i])
                              + " (" + Fmt.bytes(Gpu.all[i].vramTotal) + ")");
                }
                return others.join(", ");
            }
            tint: Theme.fgDim
        }
    }

    // ═══ A DESPENSA ════════════════════════════════════════════

    Section {
        title: "Despensa"

        Meter {
            label: "em uso"
            value: Sys.memUsage
            reading: Fmt.bytes(Sys.memUsed) + " / " + Fmt.bytes(Sys.memTotal)
            tint: Theme.royal
        }
        Fact { label: "livre"; value: Fmt.bytes(Sys.memAvailable) }
        Fact { label: "cache"; value: Fmt.bytes(Sys.memCached); tint: Theme.verdigris }
        Meter {
            visible: Sys.swapTotal > 0
            label: "troca"
            value: Sys.swapUsage
            reading: Fmt.bytes(Sys.swapUsed) + " / " + Fmt.bytes(Sys.swapTotal)
            tint: Theme.verdigris
        }
    }

    // ═══ AS ADEGAS ═════════════════════════════════════════════

    Section {
        title: "Adegas"

        Repeater {
            model: Disks.mounts

            Meter {
                required property var modelData

                label: modelData.mount
                value: modelData.usage
                reading: Fmt.bytes(modelData.avail) + " livres de "
                       + Fmt.bytes(modelData.size)
                tint: Theme.teal
            }
        }

        Item { height: Theme.pad.tight; width: 1 }

        Fact { label: "leitura"; value: Fmt.rate(Disks.readRate);  tint: Theme.moat }
        Fact { label: "escrita"; value: Fmt.rate(Disks.writeRate); tint: Theme.gold }
    }
}
