//  SEGURAR PARA LACRAR.
//  Ações destrutivas exigem que você mantenha pressionado enquanto
//  o selo de cera se enche. Soltar cedo cancela. É o conserto do
//  "scroll do mouse desliga a máquina".

import QtQuick
import qs

Item {
    id: root

    property int duration: Theme.metric.holdMs
    /// Ações inofensivas (trancar, repousar) disparam na hora.
    property bool instant: false
    property real progress: 0
    property bool holding: false

    signal confirmed()
    signal aborted()

    function begin() {
        if (instant) { confirmed(); return; }
        holding = true;
    }

    function release() {
        if (instant) return;
        if (holding && progress < 1) aborted();
        holding = false;
    }

    onHoldingChanged: {
        if (holding) {
            drain.stop();
            fill.duration = Math.max(1, root.duration * (1 - root.progress));
            fill.start();
        } else {
            fill.stop();
            drain.start();
        }
    }

    NumberAnimation {
        id: fill
        target: root; property: "progress"
        to: 1.0
        easing.type: Easing.Linear
        onFinished: if (root.holding) { root.holding = false; root.progress = 0; root.confirmed(); }
    }

    NumberAnimation {
        id: drain
        target: root; property: "progress"
        to: 0.0
        duration: Theme.anim.quick
        easing.type: Easing.OutCubic
    }
}
