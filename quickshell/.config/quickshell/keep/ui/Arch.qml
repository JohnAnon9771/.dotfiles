//  ARCO OGIVAL — a porta gótica.
//
//  Duas armadilhas já pegas aqui:
//
//  1. Curva quadrática com os controles no topo dá arco ROMANO: as
//     duas metades se encontram com tangente horizontal e o topo sai
//     redondo. Gótico é ponta — dois arcos de círculo com centro nos
//     pés opostos, que se cruzam em ângulo a 0,866 da largura.
//
//  2. O Shape do Qt não redesenha quando só a COR de uma parada do
//     gradiente muda por vinculação: o arco continuava aceso depois
//     de o mouse sair, e só apagava na segunda passagem. Por isso
//     isto é Canvas, como o escudo, o selo e as ameias — repinta
//     quando mandamos.

import QtQuick
import qs

Canvas {
    id: root

    property color fill: Theme.bgPanel
    property color stroke: Theme.borderOuter
    property real strokeWidth: Theme.border.outer
    /// A luz que entra por cima quando a porta está acesa.
    property color glow: "transparent"
    property bool lit: false

    /// Altura da ogiva acima da linha de imposta.
    readonly property real rise: width * 0.8660254
    readonly property real springY: Math.min(rise, height * 0.9)

    onFillChanged: requestPaint()
    onStrokeChanged: requestPaint()
    onStrokeWidthChanged: requestPaint()
    onGlowChanged: requestPaint()
    onLitChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        const w = width;
        const h = height;
        const sy = springY;
        const inset = strokeWidth / 2;

        function trace() {
            ctx.beginPath();
            ctx.moveTo(inset, h - inset);
            ctx.lineTo(inset, sy);
            // Metade esquerda: centro no pé direito.
            ctx.arc(w, sy, w - inset, Math.PI, Math.PI * 4 / 3, false);
            // Metade direita: centro no pé esquerdo.
            ctx.arc(0, sy, w - inset, -Math.PI / 3, 0, false);
            ctx.lineTo(w - inset, h - inset);
            ctx.closePath();
        }

        trace();

        if (lit && Qt.colorEqual(glow, "transparent") === false) {
            const g = ctx.createLinearGradient(0, 0, 0, h);
            g.addColorStop(0.0, glow);
            g.addColorStop(0.7, fill);
            g.addColorStop(1.0, fill);
            ctx.fillStyle = g;
        } else {
            ctx.fillStyle = fill;
        }
        ctx.fill();

        if (strokeWidth > 0) {
            trace();
            ctx.strokeStyle = stroke;
            ctx.lineWidth = strokeWidth;
            ctx.lineJoin = "miter";
            ctx.stroke();
        }
    }
}
