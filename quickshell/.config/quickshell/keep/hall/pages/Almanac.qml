pragma ComponentBehavior: Bound

//  O ALMANAQUE — o calendário, com a lua de verdade.

import QtQuick
import Quickshell
import qs
import qs.ui
import qs.hall
import qs.services

Column {
    id: root

    spacing: Theme.pad.wide

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    /// Mês em exibição; 0 = o de hoje.
    property int offset: 0

    readonly property date shown: new Date(clock.date.getFullYear(),
                                           clock.date.getMonth() + offset, 1)

    readonly property int firstWeekday: shown.getDay()
    readonly property int daysInMonth:
        new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate()

    Section {
        title: "Almanaque"

        Row {
            width: parent.width
            spacing: Theme.pad.base

            StoneButton {
                anchors.verticalCenter: parent.verticalCenter
                text: "◂"
                onChosen: root.offset--
            }

            Rune {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 150
                horizontalAlignment: Text.AlignHCenter
                text: Lore.months[root.shown.getMonth()] + "  " + root.shown.getFullYear()
                size: Theme.size.base
                color: Theme.fg
            }

            StoneButton {
                anchors.verticalCenter: parent.verticalCenter
                text: "▸"
                onChosen: root.offset++
            }
        }

        Item { height: Theme.pad.tight; width: 1 }

        Grid {
            columns: 7
            rowSpacing: 2
            columnSpacing: 2

            // Cabeçalho da semana.
            Repeater {
                model: Lore.weekdays

                Item {
                    required property string modelData
                    width: 34
                    height: 20

                    Rune {
                        anchors.centerIn: parent
                        text: parent.modelData
                        size: Theme.size.tiny
                        color: Theme.royal
                    }
                }
            }

            // Os dias que sobram do mês anterior.
            Repeater {
                model: root.firstWeekday
                Item { width: 34; height: 28 }
            }

            Repeater {
                model: root.daysInMonth

                Item {
                    id: day

                    required property int index
                    readonly property int number: index + 1
                    readonly property bool today:
                        root.offset === 0 && number === clock.date.getDate()
                    readonly property bool weekend: {
                        const wd = (root.firstWeekday + index) % 7;
                        return wd === 0 || wd === 6;
                    }

                    width: 34
                    height: 28

                    Rectangle {
                        anchors.fill: parent
                        color: day.today ? Theme.alpha(Theme.gold, 0.18) : "transparent"
                        border.width: day.today ? 1 : 0
                        border.color: Theme.accent
                    }

                    Text {
                        anchors.centerIn: parent
                        text: day.number
                        font.family: Theme.font.carved
                        font.pixelSize: Theme.size.small
                        color: day.today ? Theme.accentLit
                             : day.weekend ? Theme.fgDim
                                           : Theme.ash
                        renderType: Text.NativeRendering
                    }
                }
            }
        }
    }

    Section {
        title: "Lua"

        Row {
            spacing: Theme.pad.wide

            MoonDisc {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 54
                implicitHeight: 54
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Rune {
                    text: Lore.moonName
                    size: Theme.size.base
                    color: Theme.fg
                }
                Text {
                    text: Fmt.pct(Lore.moonLit) + " iluminada"
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.size.small
                    color: Theme.fgMuted
                    renderType: Text.NativeRendering
                }
                Text {
                    text: Lore.moonAge.toFixed(1) + " dias de idade  ·  "
                        + (Lore.moonWaxing ? "crescendo" : "minguando")
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.size.tiny
                    color: Theme.fgDim
                    renderType: Text.NativeRendering
                }
            }
        }

        Item { height: Theme.pad.snug; width: 1 }

        Text {
            width: parent.width
            text: Lore.aphorism()
            font.family: Theme.font.carved
            font.italic: true
            font.pixelSize: Theme.size.small
            color: Theme.fgDim
            wrapMode: Text.WordWrap
            renderType: Text.NativeRendering
        }
    }
}
