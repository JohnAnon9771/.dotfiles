//  AMEIAS — a assinatura do torreão.
//
//  Um perfil só, traçado de ponta a ponta: a silhueta é o que lê. A
//  primeira versão eram retângulos soltos com um fio no topo de cada
//  um, e contra a parede escura só o fio aparecia — a barra ganhava
//  uma borda pontilhada em vez de uma muralha.
//
//  Serve em qualquer borda. O Grande Salão usa a de baixo e a da
//  esquerda, para ler como uma torre pendurada na muralha.

import QtQuick
import qs

Canvas {
    id: root

    /// De que lado os dentes apontam.
    property int edge: Qt.BottomEdge   // Bottom, Top, Left, Right

    property color stone: Theme.bg
    property color rim: Theme.iron
    /// 0..1 — brasa subindo pela muralha sob carga.
    property real heat: Theme.heat
    property bool ruined: true

    /// Deslocamento em pixels do padrão. Serve para casar as ameias
    /// de duas superfícies diferentes: a muralha começa na borda da
    /// tela, e o Salão, que fica no meio dela, precisa saber disso
    /// para os dentes se alinharem.
    property int phase: 0

    readonly property bool vertical: edge === Qt.LeftEdge || edge === Qt.RightEdge
    property int merlon: Theme.metric.crenelWidth
    property int gap: Theme.metric.crenelGap
    property int depth: Theme.metric.crenelHeight

    implicitHeight: vertical ? 0 : depth
    implicitWidth: vertical ? depth : 0

    onStoneChanged: requestPaint()
    onRimChanged: requestPaint()
    onHeatChanged: requestPaint()
    onPhaseChanged: requestPaint()
    onDepthChanged: requestPaint()
    onMerlonChanged: requestPaint()
    onGapChanged: requestPaint()
    onRuinedChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    /// Quanto o dente n avança. Zero = merlão desabado.
    function reach(i, d) {
        if (!ruined) return d;
        if (i % 23 === 14) return 0;          // um desabou
        if (i % 7 === 3) return d * 0.62;     // e um está gasto
        return d;
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        const step = merlon + gap;
        // Trabalhamos sempre em "ao longo da borda" × "para dentro",
        // e deixamos a transformação decidir de que lado isso cai.
        const span = vertical ? height : width;
        const d = vertical ? width : height;
        const start = -(((phase % step) + step) % step);
        const count = Math.ceil((span - start) / step) + 1;

        ctx.save();

        // Cada caso leva o ponto (aoLongo, paraDentro) ao seu lugar.
        // Conferir a matriz importa: rotate(θ) é [[cos,-sin],[sin,cos]],
        // então rotate(90°) manda (a,b) para (-b,a) — e não para (b,a),
        // que foi o engano que deixou a ameia lateral invisível.
        switch (edge) {
            case Qt.TopEdge:                       // (a,b) → (a, d-b)
                ctx.translate(0, d);
                ctx.scale(1, -1);
                break;
            case Qt.LeftEdge:                      // (a,b) → (d-b, a)
                ctx.translate(d, 0);
                ctx.rotate(Math.PI / 2);
                break;
            case Qt.RightEdge:                     // (a,b) → (b, a)
                ctx.rotate(Math.PI / 2);
                ctx.scale(1, -1);
                break;
            default:                               // BottomEdge: já é assim
                break;
        }

        function trace(inset) {
            ctx.beginPath();
            ctx.moveTo(start, inset);

            for (let i = 0; i < count; i++) {
                const a = start + i * step;
                const b = a + merlon;
                const drop = reach(i, d);

                ctx.lineTo(a, inset);
                if (drop > 0) {
                    ctx.lineTo(a, drop - inset);
                    ctx.lineTo(b, drop - inset);
                    ctx.lineTo(b, inset);
                }
            }

            ctx.lineTo(span, inset);
        }

        // Preenchimento: fecha por trás, onde a parede já é sólida.
        trace(0);
        ctx.lineTo(span, -1);
        ctx.lineTo(start, -1);
        ctx.closePath();
        ctx.fillStyle = stone;
        ctx.fill();

        if (heat > 0.02) {
            const g = ctx.createLinearGradient(0, 0, 0, d);
            g.addColorStop(0, Qt.rgba(Theme.ember.r, Theme.ember.g, Theme.ember.b, heat * 0.30));
            g.addColorStop(1, Qt.rgba(Theme.ember.r, Theme.ember.g, Theme.ember.b, 0));
            ctx.fillStyle = g;
            ctx.fill();
        }

        // O fio de luz, correndo pela silhueta.
        trace(0.5);
        ctx.strokeStyle = rim;
        ctx.lineWidth = 1;
        ctx.stroke();

        ctx.restore();
    }
}
