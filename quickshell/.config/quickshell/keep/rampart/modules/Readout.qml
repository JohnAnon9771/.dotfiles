//  LEITURA — a forma comum dos medidores do centro da muralha.
//  Glifo, número, e um traço do histórico recente.

import QtQuick
import qs
import qs.ui
import qs.rampart

Segment {
    id: root

    property string glyph: ""
    property string value: ""
    property color tint: Theme.accent
    /// Amostras 0..1 para o traço. Vazio esconde o traço.
    property var samples: []
    /// 0..1 — o quanto este medidor está sofrendo.
    property real level: -1

    /// A cor do glifo guarda a identidade do módulo em repouso e só
    /// desliza para a escala de estado quando a coisa aperta. Pintar
    /// direto pela escala deixava a muralha inteira verde no ócio, e
    /// aí ouro, roxo e teal — a paleta do rice — nunca apareciam.
    readonly property color liveTint: {
        if (level < 0) return tint;
        if (level < 0.6) return tint;
        return Theme.mix(tint, Theme.gauge(level), (level - 0.6) / 0.4);
    }

    spacing: Theme.pad.tight
    hoverTint: root.tint

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.base
        color: root.liveTint
        renderType: Text.NativeRendering

        Behavior on color { ColorAnimation { duration: Theme.anim.slow } }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.base
        color: Theme.fg
        renderType: Text.NativeRendering
    }

    Sparkline {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.samples && root.samples.length > 1
        samples: root.samples
        line: root.tint
        under: Theme.alpha(root.tint, 0.16)
        height: Theme.size.base
    }
}
