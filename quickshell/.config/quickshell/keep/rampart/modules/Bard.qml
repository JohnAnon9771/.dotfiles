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

        // AQUI RESPIRAVA O BARDO, e era a última animação permanente
        // do torreão.
        //
        // Um SequentialAnimation infinito na opacidade, `running:
        // playing`. Parece inofensivo até você notar o que é o estado
        // "tocando": música no fone é o modo de repouso de quem usa a
        // máquina o dia inteiro. Enquanto houvesse som, a muralha
        // desenhava a 60 fps — a GPU nunca dormia, e a Regra de Ouro
        // valia para tudo menos para o único módulo que fica ligado
        // por horas.
        //
        // A informação já estava dita sem custo nenhum: o glifo troca
        // entre nota e pausa, e a cor entre royal e verdigris. Duas
        // mudanças discretas, zero frame em repouso.
        Behavior on color { ColorAnimation { duration: Theme.anim.slow } }
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
