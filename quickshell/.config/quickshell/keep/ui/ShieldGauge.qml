//  ESCUDO HERÁLDICO — medidor de brasão.
//  Enche de baixo para cima e muda de cor conforme piora:
//  musgo → ouro → brasa → sangue.

import QtQuick
import qs

Item {
    id: root

    /// 0..1
    property real value: 0
    property color charge: Theme.gauge(root.level)
    property color field: Theme.alpha(Theme.crypt, 0.55)
    property color rim: Theme.borderInner
    property alias label: caption.text
    property alias reading: readout.text

    /// Em quantos degraus o escudo enxerga o 0..1. Ver Fmt.step().
    property int steps: 20

    /// O valor em degraus, e o nível que o desenho de fato segue.
    ///
    /// O Behavior morava em `value`, que vem cru do serviço. Como
    /// cpuUsage e gpu_busy_percent balançam alguns por cento entre duas
    /// leituras, cada amostra de 2 s reabria 380 ms de animação, e
    /// `onVChanged` repinta o Canvas A CADA FRAME dela: eram ~23
    /// rasterizações em CPU por escudo, indefinidamente, com a máquina
    /// parada. É o mesmo laço que Fmt.step() já tinha fechado para
    /// Theme.heat, e que aqui tinha ficado aberto.
    ///
    /// Com o degrau antes do Behavior, em repouso nada muda e o escudo
    /// não é tocado; uma subida de verdade continua chegando suave.
    readonly property real level: Fmt.step(root.value, root.steps)
    property real shown: root.level

    implicitWidth: 54
    implicitHeight: 62

    Behavior on shown { NumberAnimation { duration: Theme.anim.slow; easing.type: Easing.OutCubic } }

    Canvas {
        id: shield
        anchors.fill: parent
        anchors.bottomMargin: caption.visible ? caption.height + 2 : 0

        readonly property real v: root.shown
        readonly property color c: root.charge
        readonly property color f: root.field
        readonly property color r: root.rim

        onVChanged: requestPaint()
        onCChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        // Escudo de brasão (heater shield).
        //
        // O bico depende da TANGENTE com que as duas curvas se
        // encontram. Com o controle no canto de baixo — ou no meio —
        // a tangente final fica horizontal, as curvas se juntam lisas
        // e sai um U. Pondo o último controle para dentro e para
        // cima, cada lado chega ao ponto inclinado, e o encontro vira
        // ângulo. É o mesmo raciocínio da ogiva do Ossuário.
        function trace(ctx, w, h) {
            const shoulder = h * 0.34;

            ctx.beginPath();
            ctx.moveTo(1, 1);
            ctx.lineTo(w - 1, 1);
            ctx.lineTo(w - 1, shoulder);
            ctx.bezierCurveTo(w - 1,     h * 0.56,
                              w * 0.86,  h * 0.80,
                              w / 2,     h - 1);
            ctx.bezierCurveTo(w * 0.14,  h * 0.80,
                              1,         h * 0.56,
                              1,         shoulder);
            ctx.closePath();
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            trace(ctx, width, height);
            ctx.fillStyle = f;
            ctx.fill();

            // A carga do brasão sobe pelo escudo.
            ctx.save();
            trace(ctx, width, height);
            ctx.clip();
            ctx.fillStyle = c;
            ctx.fillRect(0, height * (1 - v), width, height * v);
            ctx.restore();

            trace(ctx, width, height);
            ctx.strokeStyle = r;
            ctx.lineWidth = 1;
            ctx.stroke();
        }
    }

    Text {
        id: readout
        anchors.centerIn: shield
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.base
        font.bold: true
        color: Theme.ivory
        style: Text.Outline
        styleColor: Theme.alpha(Theme.crypt, 0.8)
        renderType: Text.NativeRendering
    }

    Rune {
        id: caption
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
        size: Theme.size.tiny
        color: Theme.fgDim
        visible: text.length > 0
    }
}
