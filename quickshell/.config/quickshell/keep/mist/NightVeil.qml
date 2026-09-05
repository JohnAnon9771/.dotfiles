//  O VÉU DE ÂMBAR — modo noturno.
//  Uma camada de tinta quente sobre a tela inteira, acima até da
//  muralha. Zero pacotes: nada de hyprsunset nem gammastep.
//
//  Não é filtro de gama de verdade (não mexe na curva do monitor),
//  mas para descansar a vista à noite faz o serviço.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData

        screen: modelData
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "keep-nightveil"
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        anchors { left: true; right: true; top: true; bottom: true }

        // Sem isto o véu comeria todo clique da tela.
        mask: Region {}

        visible: Settings.data.nightLight

        Rectangle {
            anchors.fill: parent
            color: Theme.ember
            opacity: Settings.data.nightLight ? Settings.data.nightStrength : 0

            Behavior on opacity {
                NumberAnimation { duration: 1200; easing.type: Easing.InOutQuad }
            }
        }
    }
}
