pragma ComponentBehavior: Bound

//  O SELO DO SENHOR — o agente polkit.
//  Substitui o polkit-gnome. Quando algo precisa de autorização, é
//  aqui que a senha é pedida — no tema do castelo, e não no diálogo
//  cinza do GTK.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import qs
import qs.ui
import qs.services

Scope {
    id: root

    readonly property bool asking: agent.isActive && agent.flow !== null

    PolkitAgent {
        id: agent
    }

    LazyLoader {
        activeAsync: root.asking

        PanelWindow {
            id: win

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "keep-seal"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            anchors { left: true; right: true; top: true; bottom: true }

            readonly property var flow: agent.flow

            Rectangle {
                anchors.fill: parent
                color: Theme.crypt
                opacity: 0.72
            }

            MouseArea {
                anchors.fill: parent
                onClicked: if (win.flow) win.flow.cancelAuthenticationRequest()
            }

            Panel {
                anchors.centerIn: parent
                width: 460
                implicitHeight: form.implicitHeight + padding * 2
                padding: Theme.pad.vast

                MouseArea { anchors.fill: parent }

                Column {
                    id: form

                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    spacing: Theme.pad.roomy

                    Row {
                        spacing: Theme.pad.roomy

                        WaxSeal {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 34
                            implicitHeight: 34
                            wax: Theme.gold
                            glyph: Theme.glyph.lock
                            glyphColor: Theme.crypt
                        }

                        Illuminated {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Selo"
                            gap: 4
                            initialSize: Theme.size.display + 6
                            restSize: Theme.size.title
                        }
                    }

                    Text {
                        width: parent.width
                        text: "O castelo exige o selo do senhor."
                        font.family: Theme.font.carved
                        font.italic: true
                        font.pixelSize: Theme.size.base
                        color: Theme.fgMuted
                        wrapMode: Text.WordWrap
                        renderType: Text.NativeRendering
                    }

                    Divider { width: parent.width }

                    // O que está sendo pedido.
                    Text {
                        width: parent.width
                        text: win.flow ? win.flow.message : ""
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.size.small
                        color: Theme.fg
                        wrapMode: Text.WordWrap
                        renderType: Text.NativeRendering
                    }

                    Text {
                        width: parent.width
                        visible: text.length > 0
                        text: win.flow ? win.flow.actionId : ""
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.size.tiny
                        color: Theme.fgDim
                        elide: Text.ElideMiddle
                        renderType: Text.NativeRendering
                    }

                    // Quem está sendo autenticado.
                    Fact {
                        width: parent.width
                        visible: win.flow && win.flow.selectedIdentity !== null
                        label: "em nome de"
                        value: win.flow && win.flow.selectedIdentity
                            ? String(win.flow.selectedIdentity) : ""
                    }

                    RuneField {
                        id: pass

                        width: parent.width
                        visible: win.flow && win.flow.isResponseRequired
                        focus: true
                        echoMode: win.flow && win.flow.responseVisible
                            ? TextInput.Normal : TextInput.Password
                        placeholder: win.flow && win.flow.inputPrompt.length > 0
                            ? win.flow.inputPrompt : "a palavra"
                        erring: win.flow ? win.flow.supplementaryIsError : false

                        onAccepted: {
                            if (win.flow) win.flow.submit(text);
                            text = "";
                        }
                        onCancelled: if (win.flow) win.flow.cancelAuthenticationRequest()

                        Component.onCompleted: forceActiveFocus()
                    }

                    Text {
                        width: parent.width
                        visible: text.length > 0
                        text: win.flow ? win.flow.supplementaryMessage : ""
                        font.family: Theme.font.carved
                        font.italic: true
                        font.pixelSize: Theme.size.small
                        color: win.flow && win.flow.supplementaryIsError
                            ? Theme.blood : Theme.fgDim
                        wrapMode: Text.WordWrap
                        renderType: Text.NativeRendering
                    }

                    Row {
                        anchors.right: parent.right
                        spacing: Theme.pad.snug

                        StoneButton {
                            text: "recusar"
                            onChosen: if (win.flow) win.flow.cancelAuthenticationRequest()
                        }

                        StoneButton {
                            text: "lacrar"
                            primary: true
                            onChosen: {
                                if (win.flow) win.flow.submit(pass.text);
                                pass.text = "";
                            }
                        }
                    }
                }
            }

            Connections {
                target: agent
                function onAuthenticationRequestStarted() { pass.forceActiveFocus(); }
            }
        }
    }
}
