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

    /// O texto MAIS LARGO que este medidor pode vir a mostrar.
    ///
    /// Sem isto o número reservava só a largura do valor do momento, e
    /// "8%" virando "12%" mudava o implicitWidth do Segment. A Row do
    /// centro da muralha então relayoutava e TODO módulo à direita
    /// escorregava alguns pixels — seis medidores fazendo isso a cada
    /// dois segundos, o dia inteiro.
    ///
    /// Era trabalho de layout recorrente e era feio: a §3.3 da doutrina
    /// pede que nenhum estado mude posição ou tamanho dos módulos, e a
    /// barra desobedecia sozinha, sem estado nenhum mudar.
    ///
    /// Reserve o pior caso, não o caso comum. "100%" e não "8%".
    property string reserve: "100%"

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

    TextMetrics {
        id: reserva
        font: numero.font
        text: root.reserve
    }

    Text {
        id: numero

        anchors.verticalCenter: parent.verticalCenter
        text: root.value

        // O Math.max é a rede de segurança: se algum dia um valor
        // passar da reserva, ele volta a alargar em vez de ser cortado.
        // Reserva bem escolhida nunca chega lá.
        width: Math.max(reserva.width, implicitWidth)
        horizontalAlignment: Text.AlignRight

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
