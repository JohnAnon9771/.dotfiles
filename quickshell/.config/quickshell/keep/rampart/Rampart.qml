pragma ComponentBehavior: Bound

//  ╔═══════════════════════════════════════════════════════════════╗
//  ║  A MURALHA                                                    ║
//  ║  A barra do torreão. Uma por monitor.                         ║
//  ║                                                               ║
//  ║  A borda de baixo é de ameias de verdade: merlões desenhados,  ║
//  ║  alguns gastos, um ou outro desabado. É a assinatura do rice.  ║
//  ╚═══════════════════════════════════════════════════════════════╝

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.ui
import qs.services
import qs.rampart.modules

Scope {
    id: root

    signal openHall(string page)
    signal openOssuary()
    signal openAlmanac()

    /// A primeira muralha erguida. O inibidor de ociosidade precisa
    /// de uma janela a que se prender.
    property var primaryBar: null

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData

            screen: modelData
            WlrLayershell.namespace: "keep-rampart"
            color: "transparent"

            anchors { left: true; right: true; top: true }
            implicitHeight: Theme.metric.barHeight + Theme.metric.crenelHeight

            Component.onCompleted: if (!root.primaryBar) root.primaryBar = bar

            // ═══ A PAREDE ══════════════════════════════════════

            Rectangle {
                id: wall

                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: Theme.metric.barHeight
                color: Theme.bg

                // Moldura de ferro, herdada da barra antiga.
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: 1
                    color: Theme.borderOuter
                }
            }

            // ═══ AS AMEIAS ═════════════════════════════════════

            Crenellation {
                anchors { left: parent.left; right: parent.right; top: wall.bottom }
                stone: Theme.bg
                rim: Theme.borderOuter
                heat: Settings.data.weather ? Theme.heat : 0
            }

            // ═══ ESQUERDA ══════════════════════════════════════

            Row {
                id: leftSide

                anchors { left: parent.left; top: parent.top }
                height: Theme.metric.barHeight
                spacing: 0

                Crest {
                    id: crest
                    host: hoverPopup
                }

                Workspaces {
                    id: flags
                }

                WindowTitle {
                    // Não invade o centro: encolhe conforme sobra
                    // espaço. Depende só de coisas que não dependem
                    // dele, senão vira laço de vinculação.
                    maxWidth: Math.max(0, middle.x - crest.width - flags.width
                                          - Theme.pad.vast)
                }
            }

            // ═══ CENTRO — A VIGÍLIA ════════════════════════════

            Row {
                id: middle

                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
                height: Theme.metric.barHeight
                spacing: 0

                CpuModule {
                    host: hoverPopup
                    onActivated: root.openHall("watch")
                }
                GpuModule {
                    host: hoverPopup
                    onActivated: root.openHall("watch")
                }
                RamModule {
                    host: hoverPopup
                    onActivated: root.openHall("watch")
                }
                TempModule {
                    host: hoverPopup
                    onActivated: root.openHall("watch")
                }
                DiskModule {
                    host: hoverPopup
                    onActivated: root.openHall("watch")
                }
                NetModule {
                    host: hoverPopup
                    onActivated: root.openHall("ravens")
                }
            }

            // ═══ DIREITA ═══════════════════════════════════════

            Row {
                id: rightSide

                anchors { right: parent.right; top: parent.top }
                height: Theme.metric.barHeight
                spacing: 0

                Tray {
                    barWindow: bar
                }

                Bard {
                    host: hoverPopup
                }

                Volume {
                    host: hoverPopup
                    onOpenHall: root.openHall("organ")
                }

                Bell {
                    onOpenCrypt: root.openHall("crypt")
                }

                Reaper {
                    host: hoverPopup
                    onOpenOssuary: root.openOssuary()
                }

                Clock {
                    onOpenAlmanac: root.openAlmanac()
                }
            }

            // ═══ A JANELA DA TORRE ═════════════════════════════
            // Uma só, compartilhada por todos os módulos.

            BarPopup {
                id: hoverPopup
            }
        }
    }
}
