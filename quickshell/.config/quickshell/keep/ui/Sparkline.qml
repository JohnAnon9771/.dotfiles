//  TRAÇO — o histórico recente, pequeno.
//  Vive na muralha ao lado de cada número.

import QtQuick
import qs

Canvas {
    id: root

    /// Amostras 0..1, da mais antiga para a mais nova.
    property var samples: []
    property color line: Theme.accent
    property color under: Theme.alpha(Theme.accent, 0.18)
    property real thickness: 1

    implicitWidth: 28
    implicitHeight: Theme.size.base

    onSamplesChanged: requestPaint()
    onLineChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        const n = samples.length;
        if (n < 2) return;

        const dx = width / (n - 1);
        const y = i => height - 1 - Math.max(0, Math.min(1, samples[i])) * (height - 2);

        ctx.beginPath();
        ctx.moveTo(0, y(0));
        for (let i = 1; i < n; i++) ctx.lineTo(i * dx, y(i));

        // Área sob a curva, bem discreta.
        ctx.save();
        ctx.lineTo(width, height);
        ctx.lineTo(0, height);
        ctx.closePath();
        ctx.fillStyle = under;
        ctx.fill();
        ctx.restore();

        ctx.beginPath();
        ctx.moveTo(0, y(0));
        for (let i = 1; i < n; i++) ctx.lineTo(i * dx, y(i));
        ctx.strokeStyle = line;
        ctx.lineWidth = thickness;
        ctx.stroke();
    }
}
