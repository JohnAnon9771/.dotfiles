pragma ComponentBehavior: Bound

//  OS MENSAGEIROS — a bandeja do sistema.
//  A barra antiga não tinha bandeja nenhuma: nada de Discord, Steam,
//  cliente de VPN. Agora tem, e o menu é desenhado no tema em vez de
//  ser o cinza do Qt.

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs
import qs.ui
import qs.rampart

Row {
    id: root

    /// A muralha, para ancorar o menu.
    property var barWindow: null

    spacing: 0
    height: parent ? parent.height : Theme.metric.barHeight

    Repeater {
        model: SystemTray.items

        Item {
            id: slot

            required property var modelData

            width: 24
            height: root.height

            Image {
                anchors.centerIn: parent
                width: 15; height: 15
                source: slot.modelData.icon
                sourceSize.width: 30       // o dobro, para não borrar em 4K
                sourceSize.height: 30
                smooth: true
                asynchronous: true
                opacity: slot.modelData.status === Status.Passive ? 0.55 : 1

                Behavior on opacity { NumberAnimation { duration: Theme.anim.quick } }
            }

            // Atenção pedida: um ponto de sangue.
            Rectangle {
                anchors { right: parent.right; top: parent.top; rightMargin: 4; topMargin: 6 }
                width: 4; height: 4; radius: 2
                color: Theme.blood
                visible: slot.modelData.status === Status.NeedsAttention

                // Seis piscadas e para. Era infinito, e "pedir atenção"
                // é um estado que o app pode nunca retirar: um
                // syncthing esquecido prendia a muralha a 60 fps até o
                // fim da sessão. Seis piscadas você vê; a mancha de
                // sangue continua lá depois, parada, dizendo o mesmo.
                SequentialAnimation on opacity {
                    running: slot.modelData.status === Status.NeedsAttention
                    loops: 6
                    NumberAnimation { to: 0.3; duration: 700 }
                    NumberAnimation { to: 1.0; duration: 700 }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.alpha(Theme.gold, area.containsMouse ? 0.10 : 0)
                z: -1
                Behavior on color { ColorAnimation { duration: Theme.anim.quick } }
            }

            MouseArea {
                id: area

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor

                onClicked: e => {
                    const item = slot.modelData;

                    // Itens só-de-menu ignoram activate(); abrir o
                    // menu é a única coisa útil a fazer com eles.
                    if (e.button === Qt.RightButton || item.onlyMenu) {
                        if (item.hasMenu) menu.open(item, slot);
                        return;
                    }
                    if (e.button === Qt.MiddleButton) { item.secondaryActivate(); return; }
                    item.activate();
                }

                onWheel: e => slot.modelData.scroll(
                    e.angleDelta.y !== 0 ? e.angleDelta.y : e.angleDelta.x,
                    e.angleDelta.y === 0)
            }
        }
    }

    TrayMenu {
        id: menu
        barWindow: root.barWindow
    }
}
