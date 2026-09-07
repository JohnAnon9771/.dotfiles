//  O ESTANDARTE — o pano do workspace.
//
//  A "flâmula" era um Rectangle de 1 px sob o algarismo romano, e o
//  nome já prometia mais do que ela entregava. Agora é pano: pende da
//  vara de ferro, drapeja POR CIMA das ameias — que é o que um
//  estandarte de castelo faz com o parapeito — e termina em cauda de
//  andorinha.
//
//  Canvas, e não Shape: o ui/Arch.qml já registrou que o Shape não
//  redesenha quando só a COR de uma parada de gradiente muda por
//  vinculação, e aqui a cor muda toda vez que o foco troca de sala.
//
//  Repinta na troca de workspace e na de ocupação, e em mais nada. Em
//  repouso é uma textura parada como qualquer outra.

import QtQuick
import qs

Canvas {
    id: root

    /// A cor do pano.
    property color cloth: Theme.alpha(Theme.ash, 0.35)

    /// A vara de onde ele pende.
    property color rod: Theme.iron

    /// Quanto da altura é a cauda de andorinha.
    property int tail: 6

    onClothChanged: requestPaint()
    onRodChanged: requestPaint()
    onTailChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        const w = width, h = height;
        if (w <= 0 || h <= 0) return;

        const corte = h - tail;

        // ── O pano ──────────────────────────────────────────────
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(w, 0);
        ctx.lineTo(w, corte);
        ctx.lineTo(w / 2, h);          // a cauda: sobe no meio
        ctx.lineTo(0, corte);
        ctx.closePath();
        ctx.fillStyle = cloth;
        ctx.fill();

        // ── A dobra ─────────────────────────────────────────────
        // Um pano chapado é um adesivo. A faixa da direita entra na
        // sombra, como se ele torcesse ao pendurar — é o mínimo que
        // separa tecido de retângulo, e custa um fillRect.
        ctx.save();
        ctx.clip();
        ctx.fillStyle = Theme.alpha(Theme.coal, 0.22);
        ctx.fillRect(w - Math.max(2, Math.floor(w / 3)), 0, w, h);
        ctx.restore();

        // ── A vara ──────────────────────────────────────────────
        // Ferro atravessado no topo, passando um pixel de cada lado:
        // é o que faz o pano PENDER de alguma coisa em vez de flutuar.
        ctx.fillStyle = rod;
        ctx.fillRect(-1, 0, w + 2, 1);
    }
}
