// Prova visual: desenha as peças do torreão numa janela offscreen e
// salva um PNG. Não toca na sessão do usuário — usa só o vocabulário
// de ui/ e o Theme, sem os tipos de janela do Wayland.
//
// Rode com tools/preview.sh.

import QtQuick
import qs
import qs.ui

Item {
    id: sheet

    width: 1180
    height: 620

    property string outFile: "preview.png"

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.crypt }
            GradientStop { position: 0.5; color: Theme.stone }
            GradientStop { position: 1.0; color: Qt.darker(Theme.timber, 1.6) }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        // ── A muralha, imitada ─────────────────────────────────
        Item {
            width: parent.width
            height: Theme.metric.barHeight + Theme.metric.crenelHeight

            Rectangle {
                id: wall
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: Theme.metric.barHeight
                color: Theme.bg

                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: 1
                    color: Theme.borderOuter
                }

                Row {
                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 10

                    Text {
                        text: "✝"
                        font.family: Theme.font.mono; font.pixelSize: Theme.size.base
                        color: Theme.royal
                    }
                    Rune { text: "torreao"; color: Theme.royal; font.weight: Font.DemiBold }
                    Text {
                        text: "✝"
                        font.family: Theme.font.mono; font.pixelSize: Theme.size.base
                        color: Theme.royal
                    }

                    Item { width: 14; height: 1 }

                    Repeater {
                        model: [1, 2, 3, 4, 5]
                        Text {
                            required property int modelData
                            text: Lore.numeral(modelData)
                            font.family: Theme.font.carved
                            font.pixelSize: Theme.size.large
                            font.letterSpacing: Theme.graven(Theme.size.large)
                            font.weight: modelData === 2 ? Font.Bold : Font.Normal
                            color: modelData === 2 ? Theme.accentLit
                                 : modelData <= 3  ? Theme.ash
                                                   : Theme.fgDim
                            rightPadding: 8
                        }
                    }

                    Item { width: 10; height: 1 }

                    Text {
                        text: "nvim — Theme.qml"
                        font.family: Theme.font.mono; font.pixelSize: Theme.size.base
                        color: Theme.fgMuted
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 16

                    Repeater {
                        model: [
                            { g: "⚙", v: "42%",  c: Theme.gold,   l: 0.42 },
                            { g: "◈", v: "71%",  c: Theme.moat,   l: 0.71 },
                            { g: "⌬", v: "12G",  c: Theme.royal,  l: 0.38 },
                            { g: "☄", v: "58°",  c: Theme.ember,  l: 0.30 },
                            { g: "⛃", v: "210G", c: Theme.teal,   l: 0.55 }
                        ]
                        Row {
                            required property var modelData
                            spacing: 4
                            Text {
                                text: modelData.g
                                font.family: Theme.font.mono; font.pixelSize: Theme.size.base
                                color: Theme.gauge(modelData.l)
                            }
                            Text {
                                text: modelData.v
                                font.family: Theme.font.mono; font.pixelSize: Theme.size.base
                                color: Theme.fg
                            }
                        }
                    }
                }

                Row {
                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 12

                    Text {
                        text: "󰕾 64%"
                        font.family: Theme.font.mono; font.pixelSize: Theme.size.base
                        color: Theme.moss
                    }
                    WaxSeal {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 14; implicitHeight: 14
                        wax: Theme.gold; glyph: "3"; glyphColor: Theme.crypt
                    }
                    Text {
                        text: "𝙳Ǝ⊲⊢𝙷 𝙽𝟎⊢𝙴"
                        font.family: Theme.font.mono; font.pixelSize: Theme.size.large
                        color: Theme.blood
                    }
                    MoonDisc { anchors.verticalCenter: parent.verticalCenter }
                    Rune { text: "23:47" }
                }
            }

            Crenellation {
                anchors { left: parent.left; right: parent.right; top: wall.bottom }
                stone: Theme.bg
                rim: Theme.borderOuter
            }
        }

        // ── Tipografia e peças ─────────────────────────────────
        Row {
            spacing: 20

            Panel {
                width: 300; height: 210
                Column {
                    spacing: 10
                    Illuminated { text: "Ossuario" }
                    Divider { width: 260 }
                    Text {
                        width: 260
                        text: "As pedras lembram de todos que passaram."
                        font.family: Theme.font.carved
                        font.pixelSize: Theme.size.small
                        font.italic: true
                        color: Theme.fgDim
                        wrapMode: Text.WordWrap
                    }
                    Row {
                        spacing: 8
                        Repeater {
                            model: [
                                { c: Theme.verdigris, t: "adormecido" },
                                { c: Theme.moss,      t: "bom" },
                                { c: Theme.gold,      t: "atencao" },
                                { c: Theme.ember,     t: "alerta" },
                                { c: Theme.blood,     t: "critico" },
                                { c: Theme.wraith,    t: "espectral" }
                            ]
                            Column {
                                required property var modelData
                                spacing: 3
                                Rectangle { width: 34; height: 20; color: modelData.c }
                                Text {
                                    text: modelData.t
                                    font.family: Theme.font.mono; font.pixelSize: 8
                                    color: Theme.fgDim
                                }
                            }
                        }
                    }
                }
            }

            Panel {
                width: 250; height: 210
                Row {
                    spacing: 16
                    ShieldGauge {
                        value: 0.42; label: "cpu"; reading: "42"
                        implicitWidth: 62; implicitHeight: 78
                    }
                    ShieldGauge {
                        value: 0.71; label: "gpu"; reading: "71"
                        implicitWidth: 62; implicitHeight: 78
                    }
                    ShieldGauge {
                        value: 0.93; label: "vram"; reading: "93"
                        implicitWidth: 62; implicitHeight: 78
                    }
                }
            }

            Panel {
                width: 290; height: 210
                Column {
                    spacing: 12
                    Illuminated { text: "Selos"; initialSize: 20; restSize: 13 }
                    Row {
                        spacing: 10
                        WaxSeal { implicitWidth: 34; implicitHeight: 34; wax: Theme.blood; glyph: "☠" }
                        WaxSeal { implicitWidth: 34; implicitHeight: 34; wax: Theme.gold;  glyph: "⚑"; glyphColor: Theme.crypt }
                        WaxSeal { implicitWidth: 34; implicitHeight: 34; wax: Theme.moss;  glyph: "✓" }
                        WaxSeal { implicitWidth: 34; implicitHeight: 34; wax: Theme.blood; filled: 0.45; glyph: "" }
                    }
                    Row {
                        spacing: 10
                        Repeater {
                            model: [0.0, 0.12, 0.25, 0.5, 0.75, 0.88]
                            MoonDisc {
                                required property real modelData
                                phase: modelData
                                implicitWidth: 26; implicitHeight: 26
                            }
                        }
                    }
                    RuneField {
                        width: 250
                        placeholder: "invoke spell..."
                    }
                }
            }
        }

        // ── Arcos do Ossuario ──────────────────────────────────
        Row {
            spacing: 14

            Repeater {
                model: [
                    { g: "⛨", t: "trancar",  on: false },
                    { g: "☾", t: "repousar", on: false },
                    { g: "⟳", t: "renascer", on: true  },
                    { g: "☠", t: "descansar",on: false },
                    { g: "⌂", t: "partir",   on: false }
                ]

                Item {
                    required property var modelData
                    width: 118; height: 150

                    Arch {
                        anchors.fill: parent
                        fill: modelData.on ? Theme.alpha(Theme.gold, 0.10) : Theme.alpha(Theme.crypt, 0.5)
                        stroke: modelData.on ? Theme.accentLit : Theme.borderInner
                        spring: 0.45
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.g
                            font.family: Theme.font.mono
                            font.pixelSize: 30
                            color: modelData.on ? Theme.accentLit : Theme.fgDim
                        }
                        Rune {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.t
                            size: Theme.size.tiny
                            color: modelData.on ? Theme.fg : Theme.fgDim
                        }
                    }
                }
            }
        }
    }

    Timer {
        interval: 900
        running: true
        onTriggered: {
            sheet.grabToImage(function(result) {
                result.saveToFile(sheet.outFile);
                Qt.exit(0);
            }, Qt.size(sheet.width * 2, sheet.height * 2));
        }
    }
}
