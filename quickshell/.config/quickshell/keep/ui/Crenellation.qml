pragma ComponentBehavior: Bound

//  AMEIAS — a assinatura do torreão.
//  Merlões pendurados na borda inferior da muralha. Alguns estão
//  gastos, um ou outro caiu: o castelo está abandonado, afinal.

import QtQuick
import qs

Item {
    id: root

    /// Cor da pedra dos merlões.
    property color stone: Theme.wood
    /// Fio de luz no topo, onde a pedra pega o brilho da tocha.
    property color rim: Theme.iron
    /// 0..1 — quanto o castelo está em brasa (as ameias esquentam).
    property real heat: Theme.heat
    /// Deixa merlões faltando aqui e ali, como muralha desmoronada.
    property bool ruined: true

    implicitHeight: Theme.metric.crenelHeight

    readonly property int step: Theme.metric.crenelWidth + Theme.metric.crenelGap
    readonly property int count: Math.max(1, Math.floor(width / step))

    Repeater {
        model: root.count

        Rectangle {
            id: merlon

            required property int index

            // Pedra gasta: cada quinto merlão é mais baixo, e um a
            // cada dezessete simplesmente não está mais lá.
            readonly property bool missing: root.ruined && (merlon.index % 17 === 11)
            readonly property real wear: root.ruined && (merlon.index % 5 === 3) ? 0.62 : 1.0

            x: merlon.index * root.step
            width: Theme.metric.crenelWidth
            height: root.height * merlon.wear
            visible: !missing

            color: root.stone

            // A brasa sobe pela muralha quando as forjas trabalham.
            Rectangle {
                anchors.fill: parent
                color: Theme.ember
                opacity: root.heat * 0.35 * (0.6 + 0.4 * Math.sin(merlon.index * 1.7))
                visible: root.heat > 0.02
            }

            // Fio de luz no topo do merlão.
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 1
                color: root.rim
                opacity: 0.55
            }
        }
    }
}
