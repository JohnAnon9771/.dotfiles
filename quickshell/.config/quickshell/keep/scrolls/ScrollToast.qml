pragma ComponentBehavior: Bound

//  PERGAMINHO — uma notificação.
//  Corpo de pergaminho, rolos nas pontas, selo de cera segurando o
//  ícone do aplicativo, e um pavio queimando na borda de baixo em
//  vez de barra de progresso.

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs
import qs.ui
import qs.services

Item {
    id: root

    required property var notif

    /// Mantém o objeto vivo enquanto o pergaminho rola para fora.
    property bool leaving: false

    readonly property int urgency: notif ? notif.urgency : NotificationUrgency.Normal
    readonly property bool critical: urgency === NotificationUrgency.Critical

    readonly property color seal: critical ? Theme.blood
                                : urgency === NotificationUrgency.Low ? Theme.dust
                                                                      : Theme.gold

    implicitWidth: Theme.metric.scrollWidth
    implicitHeight: body.implicitHeight + roll * 2

    readonly property int roll: 5

    // Entra rolando da direita.
    x: Theme.metric.scrollWidth
    opacity: 0
    Component.onCompleted: enter.start()

    NumberAnimation {
        id: enter
        target: root; property: "x"; to: 0
        duration: Theme.anim.slow; easing.type: Easing.OutCubic
    }
    NumberAnimation {
        target: root; property: "opacity"; to: 1
        running: true; duration: Theme.anim.base
    }

    function dismiss() {
        if (root.leaving) return;
        root.leaving = true;
        leave.start();
    }

    SequentialAnimation {
        id: leave
        ParallelAnimation {
            NumberAnimation {
                target: root; property: "x"
                to: Theme.metric.scrollWidth + 40
                duration: Theme.anim.base; easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: root; property: "opacity"; to: 0
                duration: Theme.anim.base
            }
        }
        NumberAnimation {
            target: root; property: "implicitHeight"; to: 0
            duration: Theme.anim.quick; easing.type: Easing.InQuad
        }
        ScriptAction {
            script: {
                if (root.notif) root.notif.dismiss();
                Notifs.drop(root.notif);
            }
        }
    }

    // O aplicativo fechou a notificação por conta própria.
    Connections {
        target: root.notif
        ignoreUnknownSignals: true
        function onClosed() { root.dismiss(); }
    }

    // ═══ O ROLO DE CIMA ════════════════════════════════════════

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: root.roll
        color: Theme.timber

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: Theme.alpha(Theme.crypt, 0.6)
        }
    }

    // ═══ O CORPO ═══════════════════════════════════════════════

    Rectangle {
        id: body

        anchors {
            left: parent.left; right: parent.right
            top: parent.top; topMargin: root.roll
        }
        implicitHeight: content.implicitHeight + Theme.pad.roomy * 2
        color: Theme.bgPanel
        clip: true

        // O filete de urgência.
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 2
            color: root.seal
        }

        Row {
            id: content

            anchors {
                left: parent.left; right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: Theme.pad.roomy
                rightMargin: Theme.pad.roomy
            }
            spacing: Theme.pad.roomy

            // ── O selo, segurando o ícone ──────────────────────
            Item {
                width: 30
                height: 30
                anchors.verticalCenter: parent.verticalCenter

                WaxSeal {
                    anchors.fill: parent
                    wax: root.seal
                    glyph: hasIcon ? "" : Theme.glyph.bell
                    glyphColor: root.critical ? Theme.ivory : Theme.crypt

                    readonly property bool hasIcon: icon.status === Image.Ready

                    // Pulsa em sangue quando é crítico — três vezes, e
                    // para. Era infinito, e um pergaminho crítico vive
                    // cinco minutos: eram cinco minutos de scale a 60
                    // fps por uma notificação que você já leu.
                    SequentialAnimation on scale {
                        running: root.critical
                        loops: 3
                        alwaysRunToEnd: true
                        NumberAnimation { to: 1.10; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.00; duration: 900; easing.type: Easing.InOutSine }
                    }
                }

                IconImage {
                    id: icon
                    anchors.centerIn: parent
                    implicitSize: 17
                    source: {
                        if (!root.notif) return "";
                        if (root.notif.image && root.notif.image.length > 0)
                            return root.notif.image;
                        if (root.notif.appIcon && root.notif.appIcon.length > 0)
                            return Quickshell.iconPath(root.notif.appIcon, true);
                        return "";
                    }
                    visible: status === Image.Ready
                }
            }

            // ── O texto ────────────────────────────────────────
            Column {
                width: parent.width - 30 - Theme.pad.roomy
                spacing: 3

                Row {
                    width: parent.width
                    spacing: Theme.pad.snug

                    Rune {
                        width: Math.min(implicitWidth, parent.width - stamp.width - Theme.pad.snug)
                        text: root.notif ? root.notif.summary : ""
                        size: Theme.size.base
                        color: Theme.fgStrong
                    }

                    Text {
                        id: stamp
                        anchors.baseline: parent.children[0].baseline
                        text: root.notif ? root.notif.appName : ""
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.size.tiny
                        color: Theme.fgDim
                        renderType: Text.NativeRendering
                    }
                }

                Text {
                    width: parent.width
                    visible: text.length > 0
                    text: root.notif ? root.notif.body : ""
                    textFormat: Text.StyledText
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.size.small
                    color: Theme.fgMuted
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }

                // ── As ações ───────────────────────────────────
                Row {
                    visible: root.notif && root.notif.actions.length > 0
                    spacing: Theme.pad.snug
                    topPadding: Theme.pad.tight

                    Repeater {
                        model: root.notif ? root.notif.actions : []

                        Rectangle {
                            id: act

                            required property var modelData

                            width: label.implicitWidth + Theme.pad.roomy
                            height: 20
                            color: hover.containsMouse
                                ? Theme.alpha(Theme.moss, 0.35)
                                : Theme.alpha(Theme.timber, 0.9)
                            border.width: 1
                            border.color: hover.containsMouse ? Theme.moss : Theme.borderInner

                            Behavior on color { ColorAnimation { duration: Theme.anim.instant } }

                            Rune {
                                id: label
                                anchors.centerIn: parent
                                text: act.modelData.text
                                size: Theme.size.tiny
                                color: hover.containsMouse ? Theme.fgStrong : Theme.fg
                            }

                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    act.modelData.invoke();
                                    root.dismiss();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ═══ O ROLO DE BAIXO E O PAVIO ═════════════════════════════

    Rectangle {
        id: bottomRoll

        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: root.roll
        color: Theme.timber

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 1
            color: Theme.alpha(Theme.crypt, 0.6)
        }
    }

    // O pavio queimando.
    //
    // O comentário antigo dizia "crítico não expira, então não tem
    // pavio" — e estava desatualizado: o Notifs.lifetime() devolve
    // criticalTimeoutMs, que são cinco minutos. O pavio queimava, e
    // queimava animando `width`: 300 000 ms de relayout, ~18 000
    // frames para encolher um fio de 1 px.
    //
    // Agora encolhe por `scale` ancorado à esquerda. O desenho é o
    // mesmo, a matriz vai para o scenegraph e o layout não é tocado.
    Item {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: root.roll
        visible: fuse.duration > 0

        Rectangle {
            id: wick

            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: parent.width
            height: 1
            color: Theme.alpha(Theme.ember, 0.85)
            transformOrigin: Item.Left

            NumberAnimation {
                id: fuse
                target: wick; property: "scale"
                from: 1; to: 0
                duration: root.notif ? Notifs.lifetime(root.notif) : 0
                running: duration > 0 && !hovering.containsMouse && !root.leaving
                onFinished: root.dismiss()
            }

            // A brasa na ponta do pavio.
            Rectangle {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: 3; height: 3
                color: Theme.ember
                visible: fuse.running
            }
        }
    }

    // ═══ INTERAÇÃO ═════════════════════════════════════════════
    // Passar o mouse pausa o pavio: dá tempo de ler.

    MouseArea {
        id: hovering

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        drag.target: root
        drag.axis: Drag.XAxis
        drag.minimumX: 0
        drag.maximumX: root.width

        onClicked: e => {
            if (e.button === Qt.MiddleButton) { Notifs.dismissAll(); return; }
            root.dismiss();
        }

        // Arrastar para a direita dispensa; soltar no meio volta.
        onReleased: {
            if (root.x > root.width * 0.35) root.dismiss();
            else settle.start();
        }
    }

    NumberAnimation {
        id: settle
        target: root; property: "x"; to: 0
        duration: Theme.anim.quick; easing.type: Easing.OutCubic
    }
}
