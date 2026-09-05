pragma ComponentBehavior: Bound

//  O ÓRGÃO — som.
//  O desktop não tinha interface de áudio nenhuma: nem seletor de
//  saída, nem volume por aplicativo, nem microfone.

import QtQuick
import qs
import qs.ui
import qs.hall
import qs.services

Column {
    id: root

    spacing: Theme.pad.wide

    Section {
        title: "Saida"

        Slider {
            width: parent.width
            value: Audio.volume
            muted: Audio.muted
            tint: Theme.moss
            glyph: Audio.glyph(Audio.volume, Audio.muted)
            onMoved: v => Audio.setVolume(v)
            onToggled: Audio.toggleMute()
        }

        Fact { label: "tubo"; value: Audio.sinkName }

        Item { height: Theme.pad.tight; width: 1 }

        Repeater {
            model: Audio.sinks

            Choice {
                required property var modelData

                width: parent.width
                text: Audio.nodeLabel(modelData)
                chosen: modelData === Audio.sink
                onPicked: Audio.makeDefaultSink(modelData)
            }
        }
    }

    Section {
        title: "Escuta"
        visible: Audio.source !== null

        Slider {
            width: parent.width
            value: Audio.micVolume
            muted: Audio.micMuted
            tint: Theme.teal
            glyph: Audio.micMuted ? Theme.glyph.micOff : Theme.glyph.mic
            onMoved: v => Audio.setMicVolume(v)
            onToggled: Audio.toggleMicMute()
        }

        Fact { label: "boca"; value: Audio.sourceName }

        Repeater {
            model: Audio.sources

            Choice {
                required property var modelData

                width: parent.width
                text: Audio.nodeLabel(modelData)
                chosen: modelData === Audio.source
                onPicked: Audio.makeDefaultSource(modelData)
            }
        }
    }

    // ═══ QUEM ESTÁ TOCANDO ═════════════════════════════════════

    Section {
        title: "Vozes"

        Repeater {
            model: Audio.streams

            Slider {
                required property var modelData

                width: parent.width
                label: Audio.streamLabel(modelData)
                value: modelData.audio ? modelData.audio.volume : 0
                muted: modelData.audio ? modelData.audio.muted : false
                tint: Theme.royal
                glyph: Theme.glyph.music
                onMoved: v => Audio.setNodeVolume(modelData, v)
                onToggled: Audio.toggleNodeMute(modelData)
            }
        }

        Rune {
            visible: Audio.streams.length === 0
            text: Lore.empty("media")
            size: Theme.size.small
            color: Theme.fgDim
        }
    }

    Section {
        title: "Ouvidos"
        visible: Audio.captures.length > 0

        // Vale saber quem está gravando.
        Repeater {
            model: Audio.captures

            Fact {
                required property var modelData
                label: Audio.streamLabel(modelData)
                value: modelData.audio && modelData.audio.muted ? "mudo" : "escutando"
                tint: modelData.audio && modelData.audio.muted
                    ? Theme.verdigris : Theme.ember
            }
        }
    }
}
