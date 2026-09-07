pragma ComponentBehavior: Bound

//  ╔═══════════════════════════════════════════════════════════════╗
//  ║  O OSSUÁRIO — o fim da vigília.                               ║
//  ║                                                               ║
//  ║  Antes: a roda do mouse sobre um rótulo na barra. Girar para   ║
//  ║  o lado errado desligava a máquina, sem pergunta nenhuma.      ║
//  ║                                                               ║
//  ║  Agora: cinco arcos de pedra. Trancar e repousar disparam na   ║
//  ║  hora; reiniciar, desligar e sair exigem SEGURAR até o selo    ║
//  ║  de cera se encher e lacrar. Soltar antes cancela.             ║
//  ╚═══════════════════════════════════════════════════════════════╝

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.ui
import qs.services

Scope {
    id: root

    property bool open: false

    signal lockRequested()

    function show()   { root.open = true; }
    function hide()   { root.open = false; }
    function toggle() { root.open = !root.open; }

    LazyLoader {
        activeAsync: root.open

        PanelWindow {
            id: win

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "keep-ossuary"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            anchors { left: true; right: true; top: true; bottom: true }

            property int chosen: 0

            readonly property var doors: [
                { key: "L", title: "Trancar o portão",  glyph: Theme.glyph.lock,
                  hint: "baixar a grade",       hold: false, act: "lock" },
                { key: "S", title: "Repousar",           glyph: Theme.glyph.sleep,
                  hint: "suspender a máquina",  hold: false, act: "suspend" },
                { key: "R", title: "Renascer",           glyph: Theme.glyph.reboot,
                  hint: "reiniciar",            hold: true,  act: "reboot" },
                { key: "D", title: "Descansar em paz",   glyph: Theme.glyph.power,
                  hint: "desligar",             hold: true,  act: "poweroff" },
                { key: "Q", title: "Deixar o castelo",   glyph: Theme.glyph.logout,
                  hint: "encerrar a sessão",    hold: true,  act: "logout" }
            ]

            function commit(act) {
                root.hide();
                switch (act) {
                    case "lock":     root.lockRequested(); break;
                    case "suspend":  Quickshell.execDetached(["systemctl", "suspend"]); break;
                    case "reboot":   Quickshell.execDetached(["systemctl", "reboot"]); break;
                    case "poweroff": Quickshell.execDetached(["systemctl", "poweroff"]); break;
                    case "logout":   Wm.exitSession(); break;
                }
            }

            // ═══ O VÉU ═════════════════════════════════════════

            // O véu, em duas camadas. Uma só, mesmo a 97%, ainda
            // deixava ler o terminal atrás: contra texto branco em
            // fundo preto, 3% de passagem é muito. Empilhadas, a
            // transmissão cai para menos de 2% — e a segunda dá a
            // temperatura violeta, que preto puro não tem.
            Rectangle {
                id: veil
                anchors.fill: parent
                color: Theme.crypt
                opacity: 0
                Component.onCompleted: opacity = 0.94
                Behavior on opacity { Motion.Panel { opening: true } }
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.vespers
                opacity: veil.opacity * 0.45
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }

            // ═══ OS ARCOS ══════════════════════════════════════

            Column {
                anchors.centerIn: parent
                spacing: Theme.pad.vast

                Illuminated {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Ossuario"
                    gap: 7
                    initialSize: 46
                    restSize: 26
                    initialColor: Theme.scar
                    restColor: Theme.fgMuted
                }

                Row {
                    id: gallery
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.pad.wide

                    Repeater {
                        model: win.doors

                        Item {
                            id: door

                            required property var modelData
                            required property int index

                            readonly property bool lit: win.chosen === door.index

                            width: 158
                            height: 232

                            // A tocha acende POR DENTRO do arco: um
                            // retângulo de realce por cima vazava dos
                            // ombros da ogiva.
                            Arch {
                                anchors.fill: parent
                                lit: door.lit
                                fill: door.lit ? Theme.alpha(Theme.timber, 0.95)
                                               : Theme.alpha(Theme.crypt, 0.55)
                                glow: Theme.alpha(Theme.gold, 0.22)
                                stroke: door.lit ? Theme.accentLit : Theme.borderInner
                                strokeWidth: door.lit ? 2 : 1

                                Behavior on strokeWidth { NumberAnimation { duration: Theme.anim.quick } }
                            }

                            Column {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: Theme.pad.roomy
                                spacing: Theme.pad.roomy

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: door.modelData.glyph
                                    font.family: Theme.font.mono
                                    font.pixelSize: 38
                                    color: door.lit
                                        ? (door.modelData.hold ? Theme.scar : Theme.accentLit)
                                        : Theme.fgDim
                                    renderType: Text.NativeRendering

                                    Behavior on color { ColorAnimation { duration: Theme.anim.quick } }
                                }

                                Rune {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 138
                                    horizontalAlignment: Text.AlignHCenter
                                    // Quebra em duas linhas: elidir comia
                                    // "…o portão" e "…em paz", que é
                                    // justamente onde está o sentido.
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideNone
                                    text: door.modelData.title
                                    size: Theme.size.small
                                    color: door.lit ? Theme.fgStrong : Theme.fgDim
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: door.modelData.hint
                                    font.family: Theme.font.mono
                                    font.pixelSize: Theme.size.tiny
                                    color: Theme.fgDim
                                    opacity: door.lit ? 1 : 0.4
                                    renderType: Text.NativeRendering
                                }
                            }

                            // ── O selo ─────────────────────────
                            // Só nas portas que pedem que você segure.
                            WaxSeal {
                                anchors {
                                    horizontalCenter: parent.horizontalCenter
                                    bottom: parent.bottom
                                    bottomMargin: Theme.pad.roomy
                                }
                                visible: door.modelData.hold
                                implicitWidth: 22
                                implicitHeight: 22
                                wax: Theme.blood
                                filled: door.lit ? hold.progress : 0
                                glyph: hold.progress > 0.98 ? "✓" : ""
                            }

                            // A tecla de atalho, gravada no arco.
                            Text {
                                anchors {
                                    horizontalCenter: parent.horizontalCenter
                                    top: parent.top; topMargin: Theme.pad.roomy
                                }
                                text: door.modelData.key
                                font.family: Theme.font.quill
                                font.pixelSize: Theme.size.tiny
                                font.letterSpacing: Theme.runic(Theme.size.tiny)
                                color: door.lit ? Theme.accent : Theme.alpha(Theme.fgDim, 0.6)
                                renderType: Text.NativeRendering
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onEntered: win.chosen = door.index
                                onPressed: {
                                    win.chosen = door.index;
                                    hold.instant = !door.modelData.hold;
                                    hold.begin();
                                }
                                onReleased: hold.release()
                                onCanceled: hold.release()
                            }
                        }
                    }
                }

                // ── O rodapé ───────────────────────────────────
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.pad.tight

                    Rune {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Lore.vigil(Sys.uptime)
                        size: Theme.size.small
                        color: Theme.fgDim
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: win.doors[win.chosen].hold
                            ? "segure " + Theme.glyph.enter
                                + " ou o clique até o selo lacrar   ·   esc cancela"
                            : Theme.glyph.enter + " para "
                                + win.doors[win.chosen].hint + "   ·   esc cancela"
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.size.tiny
                        color: Theme.alpha(Theme.fgDim, 0.8)
                        renderType: Text.NativeRendering
                    }
                }
            }

            // ═══ O LACRE ═══════════════════════════════════════

            HoldToConfirm {
                id: hold
                onConfirmed: win.commit(win.doors[win.chosen].act)
            }

            // ═══ TECLADO ═══════════════════════════════════════

            Item {
                anchors.fill: parent
                focus: true

                Keys.onEscapePressed: root.hide()
                Keys.onLeftPressed:  win.chosen = (win.chosen + win.doors.length - 1) % win.doors.length
                Keys.onRightPressed: win.chosen = (win.chosen + 1) % win.doors.length

                Keys.onPressed: e => {
                    if (e.isAutoRepeat) { e.accepted = true; return; }

                    if (e.key === Qt.Key_H) { win.chosen = (win.chosen + win.doors.length - 1) % win.doors.length; e.accepted = true; return; }
                    if (e.key === Qt.Key_L && !(e.modifiers & Qt.ShiftModifier)) {
                        // "l" navega; mas se for a inicial de uma porta, escolhe.
                        win.chosen = (win.chosen + 1) % win.doors.length; e.accepted = true; return;
                    }

                    // Iniciais: cada arco tem a sua.
                    for (let i = 0; i < win.doors.length; i++) {
                        if (e.text.toUpperCase() === win.doors[i].key) {
                            win.chosen = i;
                            hold.instant = !win.doors[i].hold;
                            hold.begin();
                            e.accepted = true;
                            return;
                        }
                    }

                    if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
                        hold.instant = !win.doors[win.chosen].hold;
                        hold.begin();
                        e.accepted = true;
                    }
                }

                Keys.onReleased: e => {
                    if (e.isAutoRepeat) { e.accepted = true; return; }
                    hold.release();
                }

                Component.onCompleted: forceActiveFocus()
            }

            // ═══ O MORCEGO ═════════════════════════════════════
            // Raro, e só aqui. Atravessa o véu e some.

            Item {
                id: bat

                visible: Settings.data.easterEggs
                width: 26
                height: 14
                y: win.height * 0.18
                x: -60

                Text {
                    anchors.centerIn: parent
                    // Era "\u{fe3f}", um colchete angular de apresentação
                    // vertical que NENHUMA fonte do sistema tem — saía
                    // como tofu. Não se notava porque a cor também
                    // estava errada e o morcego era invisível.
                    text: Theme.glyph.bat
                    font.family: Theme.font.mono
                    font.pixelSize: 18
                    // E a cor era Theme.crypt (#11100d), a mais escura da
                    // paleta, sobre um véu que compõe em ~#231D25:
                    // contraste 1.16:1.
                    color: Theme.alpha(Theme.iron, 0.85)
                    rotation: -8
                    renderType: Text.NativeRendering
                }

                SequentialAnimation {
                    id: flight
                    NumberAnimation {
                        target: bat; property: "x"
                        from: -60; to: win.width + 60
                        duration: 2600; easing.type: Easing.InOutSine
                    }
                }

                SequentialAnimation on y {
                    running: flight.running
                    loops: Animation.Infinite
                    NumberAnimation { to: win.height * 0.14; duration: 320; easing.type: Easing.InOutSine }
                    NumberAnimation { to: win.height * 0.22; duration: 320; easing.type: Easing.InOutSine }
                }

                Component.onCompleted: {
                    // Uma vez a cada seis aberturas, mais ou menos.
                    if (Settings.data.easterEggs && Math.random() < 0.17) flight.start();
                }
            }
        }
    }
}
