//  AMEIAS — a assinatura do torreão.
//
//  Na primeira versão eram retângulos soltos com um fio no topo de
//  cada um: contra a parede escura só o fio aparecia, e a barra
//  ganhava uma borda pontilhada em vez de uma muralha. Agora é um
//  perfil só, traçado de ponta a ponta — a silhueta é o que lê.

import QtQuick
import qs

Canvas {
    id: root

    /// Cor da pedra. A mesma da parede: é a mesma muralha.
    property color stone: Theme.bg
    /// Fio de luz que corre pela silhueta.
    property color rim: Theme.iron
    /// 0..1 — brasa subindo pela muralha sob carga.
    property real heat: Theme.heat
    /// Merlões gastos e um ou outro desabado.
    property bool ruined: true

    readonly property int merlon: Theme.metric.crenelWidth
    readonly property int gap: Theme.metric.crenelGap

    implicitHeight: Theme.metric.crenelHeight

    onStoneChanged: requestPaint()
    onRimChanged: requestPaint()
    onHeatChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        const step = merlon + gap;
        const count = Math.ceil(width / step) + 1;
        const h = height;

        // ── O perfil ───────────────────────────────────────────
        // Sobe e desce entre a base da parede e a ponta do merlão,
        // num traço só. É isto que dá a silhueta de castelo.
        ctx.beginPath();
        ctx.moveTo(0, 0);

        for (let i = 0; i < count; i++) {
            const x0 = i * step;
            const x1 = x0 + merlon;

            // Pedra gasta: um a cada sete é mais baixo, e um a cada
            // vinte e três já não está mais lá.
            const missing = ruined && (i % 23 === 14);
            const drop = missing ? 0 : (ruined && (i % 7 === 3) ? h * 0.62 : h);

            ctx.lineTo(x0, 0);
            if (drop > 0) {
                ctx.lineTo(x0, drop);
                ctx.lineTo(x1, drop);
                ctx.lineTo(x1, 0);
            }
        }

        ctx.lineTo(width, 0);

        // Fecha por cima para poder preencher: a parede acima já é
        // sólida, então o preenchimento só aparece nos dentes.
        ctx.lineTo(width, -1);
        ctx.lineTo(0, -1);
        ctx.closePath();

        ctx.fillStyle = stone;
        ctx.fill();

        // Brasa: as ameias esquentam quando as forjas trabalham.
        if (heat > 0.02) {
            const g = ctx.createLinearGradient(0, 0, 0, h);
            g.addColorStop(0, Qt.rgba(Theme.ember.r, Theme.ember.g, Theme.ember.b, heat * 0.30));
            g.addColorStop(1, Qt.rgba(Theme.ember.r, Theme.ember.g, Theme.ember.b, 0));
            ctx.fillStyle = g;
            ctx.fill();
        }

        // ── O fio de luz ───────────────────────────────────────
        // Traça a silhueta de novo, agora só a linha.
        ctx.beginPath();
        ctx.moveTo(0, 0.5);

        for (let i = 0; i < count; i++) {
            const x0 = i * step;
            const x1 = x0 + merlon;
            const missing = ruined && (i % 23 === 14);
            const drop = missing ? 0 : (ruined && (i % 7 === 3) ? h * 0.62 : h);

            ctx.lineTo(x0 + 0.5, 0.5);
            if (drop > 0) {
                ctx.lineTo(x0 + 0.5, drop - 0.5);
                ctx.lineTo(x1 - 0.5, drop - 0.5);
                ctx.lineTo(x1 - 0.5, 0.5);
            }
        }
        ctx.lineTo(width, 0.5);

        ctx.strokeStyle = rim;
        ctx.lineWidth = 1;
        ctx.stroke();
    }
}
