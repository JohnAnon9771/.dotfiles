pragma ComponentBehavior: Bound

//  ╔═══════════════════════════════════════════════════════════════╗
//  ║  O PORTÃO — a tela de bloqueio.                               ║
//  ║  A máquina nunca trancava: não havia lock nem idle instalado.  ║
//  ║  WlSessionLock + PAM, sem hyprlock, sem pacote nenhum.         ║
//  ║                                                               ║
//  ║  ⚠ Se este componente morrer sem pôr locked = false, o         ║
//  ║  compositor deixa a sessão travada de verdade. Por isso o      ║
//  ║  recarregamento do shell é inibido enquanto a grade está       ║
//  ║  baixada.                                                      ║
//  ╚═══════════════════════════════════════════════════════════════╝

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.Mpris
import qs
import qs.ui
import qs.services

Scope {
    id: root

    readonly property bool locked: session.locked
    property int failures: 0

    function lock() {
        if (session.locked) return;
        root.failures = 0;
        session.locked = true;
    }

    function unlock() { session.locked = false; }

    WlSessionLock {
        id: session

        // Identidade estável: sem isto, um recarregamento do shell no
        // meio de uma sessão trancada poderia recriar o objeto e
        // deixar o compositor travado para sempre.
        reloadableId: "keep-gate"

        WlSessionLockSurface {
            id: surface

            color: "transparent"

            property string secret: ""
            property bool checking: pam.active
            property string complaint: ""

            function attempt() {
                if (pam.active || surface.secret.length === 0) return;
                surface.complaint = "";
                pam.start();
            }

            PamContext {
                id: pam

                config: "login"

                onCompleted: result => {
                    if (result === PamResult.Success) {
                        surface.secret = "";
                        root.unlock();
                    } else {
                        root.failures++;
                        surface.secret = "";
                        surface.complaint = Lore.anyLatin();
                        rattle.start();
                    }
                }

                onError: err => {
                    root.failures++;
                    surface.complaint = "O selo não respondeu.";
                    rattle.start();
                }

                onPamMessage: {
                    if (pam.responseRequired) pam.respond(surface.secret);
                }
            }

            // ═══ O FUNDO ═══════════════════════════════════════

            Image {
                id: scene
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                // Mesma URL que a Névoa usa, logo o mesmo decode: o
                // papel de parede entra na tela de bloqueio de graça.
                source: Settings.wallpaperUrl
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.crypt
                opacity: 0.86
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.vespers
                opacity: 0.4
            }

            // ═══ A GRADE ═══════════════════════════════════════
            // Desce sobre a tela ao trancar. É o gesto que dá nome
            // a esta superfície.

            Item {
                id: grid

                anchors.fill: parent
                y: -parent.height
                opacity: 0.5

                Component.onCompleted: descend.start()

                NumberAnimation {
                    id: descend
                    target: grid; property: "y"; from: -surface.height; to: 0
                    duration: 900; easing.type: Easing.OutCubic
                }

                // Barras verticais.
                Repeater {
                    model: Math.ceil(surface.width / 74)
                    Rectangle {
                        required property int index
                        x: index * 74
                        width: 3
                        height: parent.height
                        color: Theme.alpha(Theme.iron, 0.5)
                    }
                }

                // Travessas horizontais.
                Repeater {
                    model: Math.ceil(surface.height / 74)
                    Rectangle {
                        required property int index
                        y: index * 74
                        width: parent.width
                        height: 2
                        color: Theme.alpha(Theme.iron, 0.32)
                    }
                }
            }

            // A grade chacoalha quando a senha erra.
            SequentialAnimation {
                id: rattle
                NumberAnimation { target: grid; property: "x"; to:  7; duration: 45 }
                NumberAnimation { target: grid; property: "x"; to: -7; duration: 45 }
                NumberAnimation { target: grid; property: "x"; to:  5; duration: 45 }
                NumberAnimation { target: grid; property: "x"; to: -5; duration: 45 }
                NumberAnimation { target: grid; property: "x"; to:  0; duration: 60 }
            }

            // ═══ O ESPECTRO ════════════════════════════════════
            // Depois de três erros, alguém aparece por um instante.

            Text {
                id: wraith

                anchors.centerIn: parent
                anchors.verticalCenterOffset: -140
                text: Theme.glyph.ghost
                font.family: Theme.font.mono
                font.pixelSize: 190
                color: Theme.wraith
                opacity: 0
                renderType: Text.NativeRendering

                SequentialAnimation {
                    id: haunting
                    NumberAnimation { target: wraith; property: "opacity"; to: 0.16; duration: 1100; easing.type: Easing.InOutSine }
                    PauseAnimation { duration: 500 }
                    NumberAnimation { target: wraith; property: "opacity"; to: 0; duration: 1600; easing.type: Easing.InOutSine }
                }
            }

            Connections {
                target: root
                function onFailuresChanged() {
                    if (Settings.data.easterEggs && root.failures === 3) haunting.start();
                }
            }

            // ═══ O RELÓGIO ═════════════════════════════════════

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -70
                spacing: Theme.pad.snug

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Fmt.pad2(clock.hours) + ":" + Fmt.pad2(clock.minutes)
                    font.family: Theme.font.carved
                    font.pixelSize: Theme.size.colossal
                    font.letterSpacing: Theme.graven(Theme.size.colossal)
                    color: Theme.parchment
                    renderType: Text.NativeRendering
                }

                Rune {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Lore.weekdaysLong[clock.date.getDay()] + ", "
                        + clock.date.getDate() + " de "
                        + Lore.months[clock.date.getMonth()]
                    size: Theme.size.base
                    color: Theme.fgMuted
                }
            }

            // ═══ A FENDA ═══════════════════════════════════════

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 90
                spacing: Theme.pad.roomy

                RuneField {
                    id: slot

                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 340
                    focus: true
                    echoMode: TextInput.Password
                    placeholder: "diga a palavra"
                    fontSize: Theme.size.large
                    erring: surface.complaint.length > 0
                    accent: surface.checking ? Theme.wraith : Theme.accent
                    enabled: !surface.checking

                    onTextChanged: {
                        surface.secret = text;
                        surface.complaint = "";
                    }
                    onAccepted: surface.attempt()

                    Component.onCompleted: forceActiveFocus()
                }

                // A queixa, em latim.
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: surface.checking ? "…" : surface.complaint
                    font.family: Theme.font.carved
                    font.italic: true
                    font.pixelSize: Theme.size.base
                    color: Theme.scar
                    opacity: text.length > 0 ? 1 : 0
                    renderType: Text.NativeRendering

                    Behavior on opacity { NumberAnimation { duration: Theme.anim.base } }
                }

                // Riscos na parede: um por tentativa falha.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 5
                    visible: root.failures > 0

                    Repeater {
                        model: Math.min(root.failures, 12)
                        Rectangle {
                            width: 2
                            height: 13
                            rotation: 9
                            color: Theme.alpha(Theme.blood, 0.75)
                        }
                    }
                }
            }

            // ═══ O BARDO, MESMO TRANCADO ═══════════════════════

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 64
                spacing: Theme.pad.roomy
                visible: bard.player !== null

                QtObject {
                    id: bard
                    readonly property var player: Mpris.players.values.length > 0
                        ? Mpris.players.values[0] : null
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: bard.player && bard.player.isPlaying
                        ? Theme.glyph.music : Theme.glyph.pause
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.size.base
                    color: Theme.royal
                    renderType: Text.NativeRendering

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (bard.player) bard.player.togglePlaying()
                    }
                }

                Rune {
                    anchors.verticalCenter: parent.verticalCenter
                    text: bard.player
                        ? (bard.player.trackArtist + " — " + bard.player.trackTitle)
                        : ""
                    size: Theme.size.small
                    color: Theme.fgDim
                    width: 420
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
