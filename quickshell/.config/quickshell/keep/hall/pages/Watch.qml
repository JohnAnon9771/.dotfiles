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

    // A página funda: aqui se vê tudo que o Sys e o Gpu sabem, então
    // os dois passam a colher o conjunto completo enquanto ela existe.
    Attention { service: Sys }
    Attention { service: Gpu }

    spacing: Theme.pad.wide

    // ═══ AS FORJAS ═════════════════════════════════════════════

    Section {
        title: "Forjas"

        Row {
            spacing: Theme.pad.wide

            // A cor sai do `level` do próprio escudo, não da leitura
            // crua: `charge` também dispara repintura do Canvas, e passá-la
            // por fora do degrau anularia metade do conserto. O `reading`
            // continua fino — o número não anima, então não custa nada.
            ShieldGauge {
                id: cpuShield
                implicitWidth: 62
                implicitHeight: 92
                value: Sys.cpuUsage
                charge: Theme.mix(Theme.gold, Theme.gauge(cpuShield.level),
                                  cpuShield.level < 0.6 ? 0 : (cpuShield.level - 0.6) / 0.4)
                label: "cpu"
                reading: Fmt.pct(Sys.cpuUsage)
            }

            ShieldGauge {
                id: gpuShield
                visible: Gpu.present
                implicitWidth: 62
                implicitHeight: 92
                value: Gpu.usage
                charge: Theme.mix(Theme.moat, Theme.gauge(gpuShield.level),
                                  gpuShield.level < 0.6 ? 0 : (gpuShield.level - 0.6) / 0.4)
                label: "gpu"
                reading: Fmt.pct(Gpu.usage)
            }

            ShieldGauge {
                id: ramShield
                implicitWidth: 62
                implicitHeight: 92
                value: Sys.memUsage
                charge: Theme.mix(Theme.royal, Theme.gauge(ramShield.level),
                                  ramShield.level < 0.6 ? 0 : (ramShield.level - 0.6) / 0.4)
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

                            // Em degraus, como os escudos. A carga por
                            // núcleo é a leitura mais nervosa da casa, e
                            // são doze a vinte e quatro destas com Behavior
                            // de 220 ms: sem o degrau, o ruído de uma
                            // amostra bastava para o Salão inteiro
                            // renderizar a 60 fps. Dez degraus num quadrado
                            // de 15 px é 1,5 px por passo — o degrau não
                            // aparece, o tremor some.
                            Rectangle {
                                readonly property real level: Fmt.step(thread.modelData, 10)

                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                height: Math.max(1, parent.height * level)
                                color: Theme.gauge(level)
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
