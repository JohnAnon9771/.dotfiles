pragma ComponentBehavior: Bound

//  A LÁPIDE — o aviso rápido.
//  Uma tábua de pedra que aparece no centro por um instante: volume,
//  mudo, não perturbe, vigília eterna. Antes o volume mudava sem
//  nenhum retorno visual.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.ui
import qs.services

Variants {
    model: Quickshell.screens.slice(0, 1)

    PanelWindow {
        id: win

        required property var modelData

        screen: modelData
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "keep-tablet"
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: slab.opacity > 0.01

        anchors { bottom: true }
        margins.bottom: 120

        implicitWidth: 250
        implicitHeight: 92

        // Atravessável: é aviso, não botão.
        mask: Region {}

        // ── Estado ─────────────────────────────────────────────
        property string glyph: ""
        property string label: ""
        property real level: -1
        property color tint: Theme.accent

        function show(g, l, value, color) {
            win.glyph = g;
            win.label = l;
            win.level = value === undefined ? -1 : value;
            win.tint = color === undefined ? Theme.accent : color;
            slab.opacity = 1;
            linger.restart();
        }

        /// Chamadas prontas, para o IPC não precisar saber de cores.
        function showVolume() {
            win.show(Audio.glyph(Audio.volume, Audio.muted),
                     Audio.muted ? "silenciado" : Fmt.pct(Audio.volume),
                     Audio.muted ? 0 : Audio.volume,
                     Audio.muted ? Theme.blood : Theme.moss);
        }

        function showMic() {
            win.show(Audio.micMuted ? Theme.glyph.micOff : Theme.glyph.mic,
                     Audio.micMuted ? "mudo" : "escutando",
                     -1,
                     Audio.micMuted ? Theme.blood : Theme.moss);
        }

        function showDnd() {
            win.show(Notifs.dnd ? Theme.glyph.bellOff : Theme.glyph.bell,
                     Notifs.dnd ? "silêncio" : "de novo à escuta",
                     -1,
                     Notifs.dnd ? Theme.verdigris : Theme.gold);
        }

        function showInhibit() {
            win.show(Theme.glyph.lock,
                     Idle.inhibited ? "vigília eterna" : "a vigília pode cessar",
                     -1,
                     Idle.inhibited ? Theme.wraith : Theme.fgDim);
        }

        Timer {
            id: linger
            interval: 1400
            onTriggered: slab.opacity = 0
        }

        // ── A tábua ────────────────────────────────────────────
        Panel {
            id: slab

            anchors.fill: parent
            padding: Theme.pad.wide
            opacity: 0

            Behavior on opacity {
                NumberAnimation { duration: Theme.anim.base; easing.type: Easing.OutCubic }
            }

            Column {
                anchors.centerIn: parent
                spacing: Theme.pad.snug
                width: parent.width

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.pad.roomy

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.glyph
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.size.display
                        color: win.tint
                        renderType: Text.NativeRendering
                    }

                    Rune {
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.label
                        size: Theme.size.base
                        color: Theme.fg
                    }
                }

                // A barra entalhada.
                Item {
                    width: parent.width
                    height: 4
                    visible: win.level >= 0

                    Rectangle {
                        anchors.fill: parent
                        color: Theme.alpha(Theme.crypt, 0.7)
                    }

                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: parent.width * Math.max(0, win.level)
                        color: win.tint

                        Behavior on width {
                            NumberAnimation { duration: Theme.anim.quick; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }
}
