pragma ComponentBehavior: Bound

//  A PILHA DE PERGAMINHOS.
//  Encostada no canto superior direito, logo abaixo da muralha.
//  A janela é do tamanho do conteúdo: nada de sobreposição em tela
//  cheia comendo clique.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

Variants {
    // Só na tela onde a muralha está: notificação repetida em cada
    // monitor é ruído, não recurso.
    model: Quickshell.screens.slice(0, 1)

    PanelWindow {
        id: win

        required property var modelData

        screen: modelData
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "keep-scrolls"
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        anchors { top: true; right: true }
        margins.top: Theme.pad.base
        margins.right: Theme.pad.base

        implicitWidth: Theme.metric.scrollWidth
        implicitHeight: Math.max(1, stack.implicitHeight)
        visible: Notifs.popups.length > 0

        Column {
            id: stack

            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: Theme.pad.snug

            add: Transition {
                NumberAnimation { property: "y"; duration: Theme.anim.base; easing.type: Easing.OutCubic }
            }
            move: Transition {
                NumberAnimation { property: "y"; duration: Theme.anim.base; easing.type: Easing.OutCubic }
            }

            Repeater {
                model: Notifs.popups

                ScrollToast {
                    required property var modelData
                    notif: modelData
                }
            }
        }
    }
}
