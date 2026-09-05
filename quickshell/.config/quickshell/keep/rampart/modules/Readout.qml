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
    /// 0..1 — pinta o glifo pela escala de estado quando > 0.
    property real level: -1

    spacing: Theme.pad.tight
    hoverTint: root.tint

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.base
        color: root.level >= 0 ? Theme.gauge(root.level) : root.tint
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
