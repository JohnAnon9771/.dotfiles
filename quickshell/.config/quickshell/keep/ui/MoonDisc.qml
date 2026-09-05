//  A LUA — desenhada, não escrita.
//  Sem emoji colorido para brigar com a paleta: o terminador é uma
//  elipse de verdade, calculada da fase real do dia.

import QtQuick
import qs

Canvas {
    id: root

    /// 0.0 = nova · 0.25 = quarto crescente · 0.5 = cheia · 0.75 = minguante
    property real phase: Lore.moonPhase
    property color lit: Theme.parchment
    property color dark: Theme.alpha(Theme.iron, 0.28)

    implicitWidth: 14
    implicitHeight: 14

    onPhaseChanged: requestPaint()
    onLitChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        const cx = width / 2, cy = height / 2;
        const R = Math.min(width, height) / 2 - 0.5;
        const HALF = Math.PI / 2;

        // O disco em sombra, sempre visível.
        ctx.beginPath();
        ctx.ellipse(cx, cy, R, R, 0, 0, Math.PI * 2, false);
        ctx.fillStyle = dark;
        ctx.fill();

        // Minguante é crescente espelhado.
        const waxing = phase < 0.5;
        ctx.save();
        if (!waxing) { ctx.translate(width, 0); ctx.scale(-1, 1); }

        // Semi-eixo do terminador: +R na lua nova, 0 no quarto, -R na cheia.
        const a = R * Math.cos(2 * Math.PI * phase);

        ctx.beginPath();
        // Limbo iluminado: meio círculo da direita, de cima para baixo.
        ctx.ellipse(cx, cy, R, R, 0, -HALF, HALF, false);
        // Terminador: volta de baixo para cima, curvando conforme a fase.
        if (a > 0) ctx.ellipse(cx, cy,  a, R, 0,  HALF, -HALF, true);
        else       ctx.ellipse(cx, cy, -a, R, 0,  HALF, 3 * HALF, false);
        ctx.closePath();

        ctx.fillStyle = lit;
        ctx.fill();
        ctx.restore();
    }
}
