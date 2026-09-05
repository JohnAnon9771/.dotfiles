//  SELO DE CERA — a marca lacrada.
//  Badge de notificação, avatar de app, confirmação de ação.
//  A borda é recortada porque cera derretida não é círculo perfeito.

import QtQuick
import qs

Item {
    id: root

    property color wax: Theme.blood
    property color rim: Theme.alpha(Theme.crypt, 0.55)
    /// 0..1 — quanto do selo já foi carimbado (para segurar-e-confirmar)
    property real filled: 1.0
    property alias glyph: emblem.text
    property color glyphColor: Theme.ivory

    implicitWidth: 18
    implicitHeight: 18

    Canvas {
        id: disc
        anchors.fill: parent

        readonly property color c: root.wax
        readonly property color r: root.rim
        readonly property real f: root.filled

        onCChanged: requestPaint()
        onRChanged: requestPaint()
        onFChanged: requestPaint()
        onWidthChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const cx = width / 2, cy = height / 2;
            const R = Math.min(width, height) / 2 - 1;
            const bumps = 11, amp = R * 0.08;

            // Perímetro recortado da cera.
            ctx.beginPath();
            for (let i = 0; i <= 240; i++) {
                const a = i / 240 * Math.PI * 2;
                const rr = R - amp + amp * Math.cos(a * bumps);
                const x = cx + Math.cos(a) * rr;
                const y = cy + Math.sin(a) * rr;
                if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
            }
            ctx.closePath();

            // Cera ainda não carimbada fica só como sombra.
            ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, 0.18);
            ctx.fill();

            // A parte já lacrada preenche de baixo para cima.
            if (f > 0.001) {
                ctx.save();
                ctx.clip();
                ctx.fillStyle = c;
                ctx.fillRect(0, height * (1 - f), width, height * f);
                ctx.restore();
            }

            ctx.strokeStyle = r;
            ctx.lineWidth = 1;
            ctx.stroke();
        }
    }

    Text {
        id: emblem
        anchors.centerIn: parent
        font.family: Theme.font.mono
        font.pixelSize: Math.round(root.height * 0.52)
        color: root.glyphColor
        visible: text.length > 0
        opacity: root.filled
        renderType: Text.NativeRendering
    }
}
