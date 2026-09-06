pragma ComponentBehavior: Bound

//  OS CORVOS — rede.

import QtQuick
import qs
import qs.ui
import qs.rampart
import qs.services

Segment {
    id: root

    spacing: Theme.pad.tight
    hoverTint: Theme.wraith

    readonly property bool linked: Net.activeNetwork !== null || Net.rxRate > 0

    /// Reserva para as taxas. Mesma razão do Readout.reserve: "↓840k"
    /// virando "↓1.2M" mudava a largura do módulo a cada dois segundos,
    /// e o relógio à direita dançava junto.
    TextMetrics {
        id: reserva
        font: descendo.font
        text: "↓888.8M"
    }

    popup: Component {
        DetailCard {
            title: "Corvos"

            DetailRow {
                label: "elo"
                value: Net.label
                tint: Net.online ? Theme.moss : Theme.ember
            }
            DetailRow {
                visible: Net.onWifi
                label: "sinal"
                value: Fmt.pct(Net.strength)
                level: 1 - Net.strength
            }
            DetailRow {
                label: "descendo"
                value: Fmt.rate(Net.rxRate)
                tint: Theme.moat
            }
            DetailRow {
                label: "subindo"
                value: Fmt.rate(Net.txRate)
                tint: Theme.gold
            }
            DetailRow {
                visible: Probe.netIface.length > 0
                label: "via"
                value: Probe.netIface
                tint: Theme.fgDim
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: {
            if (!Net.available) return Theme.glyph.wifiOff;
            if (Net.onWifi) {
                const bars = Theme.glyph.wifi;
                return bars[Math.min(bars.length - 1,
                                     Math.floor(Net.strength * bars.length))];
            }
            return root.linked ? Theme.glyph.wired : Theme.glyph.wifiOff;
        }
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.base
        color: Net.online ? Theme.wraith
             : root.linked ? Theme.ember
                           : Theme.fgDim
        renderType: Text.NativeRendering

        Behavior on color { ColorAnimation { duration: Theme.anim.slow } }
    }

    Text {
        id: descendo

        anchors.verticalCenter: parent.verticalCenter
        text: Theme.glyph.down + Fmt.rate(Net.rxRate)
        width: Math.max(reserva.width, implicitWidth)
        horizontalAlignment: Text.AlignRight
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.base
        color: Theme.fgMuted
        renderType: Text.NativeRendering
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Theme.glyph.up + Fmt.rate(Net.txRate)
        width: Math.max(reserva.width, implicitWidth)
        horizontalAlignment: Text.AlignRight
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.base
        color: Theme.fgDim
        renderType: Text.NativeRendering
    }
}
