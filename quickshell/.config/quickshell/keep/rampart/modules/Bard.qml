pragma ComponentBehavior: Bound

//  O BARDO — o que está tocando.
//  Só aparece quando há música. Clique toca ou pausa, roda troca de
//  faixa, clique direito para o bardo.

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs
import qs.ui
import qs.rampart
import qs.services

Segment {
    id: root

    property int maxWidth: 220

    /// O primeiro que estiver tocando; se ninguém toca, o primeiro
    /// que existir — assim os controles seguem servindo para
    /// retomar o que ficou pausado.
    readonly property var player: {
        const list = Mpris.players.values;
        for (let i = 0; i < list.length; i++)
            if (list[i].isPlaying) return list[i];
        return list.length > 0 ? list[0] : null;
    }

    readonly property bool playing: player !== null && player.isPlaying

    visible: player !== null
    spacing: Theme.pad.tight
    hoverTint: Theme.royal

    onActivated: if (player && player.canTogglePlaying) player.togglePlaying()
    onSecondary: if (player && player.canQuit) player.quit()
    onScrolled: steps => {
        if (!player) return;
        if (steps > 0 && player.canGoNext) player.next();
        else if (steps < 0 && player.canGoPrevious) player.previous();
    }

    popup: Component {
        DetailCard {
            title: "Bardo"

            DetailRow {
                label: "canção"
                labelWidth: 62
                value: root.player ? root.player.trackTitle : ""
            }
            DetailRow {
                visible: root.player && root.player.trackArtist.length > 0
                label: "de"
                labelWidth: 62
                value: root.player ? root.player.trackArtist : ""
                tint: Theme.fgMuted
            }
            DetailRow {
                visible: root.player && root.player.trackAlbum.length > 0
                label: "em"
                labelWidth: 62
                value: root.player ? root.player.trackAlbum : ""
                tint: Theme.fgDim
            }
            DetailRow {
                label: "tocador"
                labelWidth: 62
                value: root.player ? root.player.identity : ""
                tint: Theme.fgDim
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.playing ? Theme.glyph.music : Theme.glyph.pause
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.base
        color: root.playing ? Theme.royal : Theme.verdigris
        renderType: Text.NativeRendering

        // Pulsa devagar enquanto toca — o bardo respirando.
        SequentialAnimation on opacity {
            running: root.playing
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { to: 0.62; duration: 1400; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0;  duration: 1400; easing.type: Easing.InOutSine }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(root.maxWidth, implicitWidth)

        text: {
            if (!root.player) return "";
            const t = root.player.trackTitle || "";
            const a = root.player.trackArtist || "";
            return a.length > 0 ? a + " — " + t : t;
        }

        font.family: Theme.font.mono
        font.pixelSize: Theme.size.base
        color: root.playing ? Theme.fg : Theme.fgDim
        elide: Text.ElideRight
        renderType: Text.NativeRendering
    }
}
