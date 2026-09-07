pragma ComponentBehavior: Bound

//  O ÓRGÃO — volume na muralha.
//  Roda muda o volume, clique do meio silencia, clique abre o salão.
//  Antes não havia interface alguma: só F11 e F12 chamando wpctl.

import QtQuick
import qs
import qs.ui
import qs.rampart
import qs.services

Segment {
    id: root

    signal openHall()

    spacing: Theme.pad.tight
    hoverTint: Theme.gold

    onActivated: root.openHall()
    onMiddle: Audio.toggleMute()
    onScrolled: steps => steps > 0 ? Audio.volumeUp() : Audio.volumeDown()

    popup: Component {
        DetailCard {
            title: "Órgão"

            DetailRow {
                label: "saída"
                labelWidth: 60
                value: Audio.sinkName
            }
            DetailRow {
                label: "volume"
                labelWidth: 60
                value: Audio.muted ? "silenciado" : Fmt.pct(Audio.volume)
                tint: Audio.muted ? Theme.scar : Theme.fg
            }
            DetailRow {
                visible: Audio.source !== null
                label: "entrada"
                labelWidth: 60
                value: Audio.micMuted ? "silenciado" : Audio.sourceName
                tint: Audio.micMuted ? Theme.dim : Theme.fg
            }

            Item { height: Theme.pad.snug; width: 1; visible: Audio.streams.length > 0 }

            Repeater {
                model: Audio.streams

                DetailRow {
                    required property var modelData

                    label: Audio.streamLabel(modelData)
                    labelWidth: 110
                    value: modelData.audio
                        ? (modelData.audio.muted ? "silenciado" : Fmt.pct(modelData.audio.volume))
                        : "—"
                    tint: Theme.fgMuted
                }
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Audio.glyph(Audio.volume, Audio.muted)
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.base
        color: Audio.muted ? Theme.scar : Theme.fg
        renderType: Text.NativeRendering

        Behavior on color { ColorAnimation { duration: Theme.anim.quick } }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Audio.muted ? "──" : Fmt.pct(Audio.volume)
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.base
        color: Audio.muted ? Theme.fgDim : Theme.fg
        renderType: Text.NativeRendering
    }
}
