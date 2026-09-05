pragma ComponentBehavior: Bound

//  A CRIPTA — o que já passou.
//  Antes não havia notificação nenhuma; agora há também memória delas.

import QtQuick
import Quickshell.Services.Notifications
import qs
import qs.ui
import qs.hall
import qs.services

Column {
    id: root

    spacing: Theme.pad.base

    Row {
        width: parent.width
        spacing: Theme.pad.base

        Illuminated {
            anchors.verticalCenter: parent.verticalCenter
            text: "Cripta"
            initialSize: Theme.size.display
            restSize: Theme.size.base
            gap: 3
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: root.width - 150
            height: 1
        }

        StoneButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: Notifs.history.length > 0
            text: "esvaziar"
            onChosen: Notifs.clearHistory()
        }
    }

    Divider { width: parent.width }

    RuneField {
        id: search

        width: parent.width
        placeholder: "procurar na cripta"
        // A busca espera a digitação parar: `needle` alimenta o model do
        // Repeater abaixo, e cada mudança destrói e recria até 120
        // delegates. Mesmo respiro que o Grimório usa para os arquivos.
        onTextChanged: sift.restart()
    }

    property string needle: ""

    Timer {
        id: sift
        interval: 220
        onTriggered: root.needle = search.text
    }

    Repeater {
        model: Notifs.searchHistory(root.needle)

        Item {
            id: bone

            required property var modelData

            width: parent.width
            implicitHeight: stack.implicitHeight + Theme.pad.base

            readonly property bool critical:
                modelData.urgency === NotificationUrgency.Critical

            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                anchors.bottomMargin: Theme.pad.snug
                width: 2
                color: bone.critical ? Theme.blood
                     : bone.modelData.urgency === NotificationUrgency.Low
                        ? Theme.dust : Theme.gold
            }

            Column {
                id: stack

                anchors {
                    left: parent.left; leftMargin: Theme.pad.roomy
                    right: parent.right; top: parent.top
                }
                spacing: 1

                Row {
                    width: parent.width
                    spacing: Theme.pad.snug

                    Rune {
                        width: Math.min(implicitWidth, parent.width - 110)
                        text: bone.modelData.summary
                        size: Theme.size.small
                        color: Theme.fgStrong
                    }

                    Text {
                        text: bone.modelData.appName
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.size.tiny
                        color: Theme.fgDim
                        renderType: Text.NativeRendering
                    }
                }

                Text {
                    width: parent.width
                    visible: text.length > 0
                    text: bone.modelData.body
                    textFormat: Text.StyledText
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.size.tiny
                    color: Theme.fgMuted
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }

                Text {
                    text: {
                        const d = new Date(bone.modelData.at);
                        const now = new Date();
                        const sameDay = d.toDateString() === now.toDateString();
                        const hm = Fmt.pad2(d.getHours()) + ":" + Fmt.pad2(d.getMinutes());
                        return sameDay ? hm
                            : d.getDate() + " " + Lore.months[d.getMonth()].substring(0, 3).toLowerCase() + "  " + hm;
                    }
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.size.tiny
                    color: Theme.alpha(Theme.fgDim, 0.75)
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    Rune {
        visible: Notifs.history.length === 0
        text: Lore.empty("crypt")
        size: Theme.size.small
        color: Theme.fgDim
    }
}
