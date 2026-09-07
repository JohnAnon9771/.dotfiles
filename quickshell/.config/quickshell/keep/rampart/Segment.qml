pragma ComponentBehavior: Bound

//  SEGMENTO — uma pedra da muralha.
//  Base comum de todo módulo da barra: realce ao passar o mouse,
//  clique, roda do mouse e o popup de detalhe.

import QtQuick
import qs
import qs.ui

Item {
    id: root

    default property alias content: row.data

    /// A janela de detalhe compartilhada, injetada pela Rampart.
    property var host: null
    property Component popup: null

    property int spacing: Theme.pad.snug
    property int padding: Theme.pad.base
    property bool interactive: true
    /// Aceso: o módulo está em estado de destaque (painel aberto).
    property bool active: false
    property color hoverTint: Theme.accent

    readonly property bool hovered: mouse.containsMouse

    signal activated()
    signal secondary()
    signal middle()
    signal scrolled(int steps)

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: parent ? parent.height : Theme.metric.barHeight

    // Realce discreto: uma sombra quente, não um botão.
    //
    // Entra em 120 ms e sai em 180: o mouse atravessando a muralha
    // acende rápido e apaga devagar, e é isso que faz a fila de
    // módulos parecer macia em vez de nervosa. Ver Motion.qml.
    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(root.hoverTint, root.active ? 0.16
                                          : root.hovered ? 0.10 : 0)
        Behavior on color { Motion.HoverColor { entering: root.hovered || root.active } }
    }

    // Fio de luz embaixo quando o painel do módulo está aberto.
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: root.hoverTint
        opacity: root.active ? 1 : 0
        Behavior on opacity { Motion.Panel { opening: root.active } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.spacing
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: e => {
            if (e.button === Qt.RightButton) root.secondary();
            else if (e.button === Qt.MiddleButton) root.middle();
            else root.activated();
        }

        onWheel: e => {
            const steps = e.angleDelta.y !== 0
                ? (e.angleDelta.y > 0 ? 1 : -1)
                : (e.angleDelta.x > 0 ? 1 : -1);
            root.scrolled(steps);
        }

        onEntered: if (root.popup && root.host) dwell.restart()
        onExited: {
            dwell.stop();
            if (root.host) root.host.hide(root);
        }
    }

    // Passar o mouse de raspão não deve abrir nada.
    Timer {
        id: dwell
        interval: root.host ? root.host.openDelay : 320
        onTriggered: if (root.host && root.popup) root.host.show(root, root.popup)
    }
}
