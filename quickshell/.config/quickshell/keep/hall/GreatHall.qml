pragma ComponentBehavior: Bound

//  ╔═══════════════════════════════════════════════════════════════╗
//  ║  O GRANDE SALÃO — a central de controle.                      ║
//  ║                                                               ║
//  ║  Tudo que o desktop não tinha: a GPU inteira, som com volume   ║
//  ║  por aplicativo, wifi, bluetooth, o histórico de notificações  ║
//  ║  e os alternadores rápidos. Entra pela direita.                ║
//  ╚═══════════════════════════════════════════════════════════════╝

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.ui
import qs.hall.pages

Scope {
    id: root

    property bool open: false
    property string page: "watch"

    signal action(string what)

    function show(which) {
        if (which && which.length > 0) root.page = which;
        root.open = true;
    }

    function hide() { root.open = false; }

    function toggle(which) {
        // Clicar de novo no mesmo assunto fecha; noutro, troca de aba.
        if (root.open && (!which || which === root.page)) root.hide();
        else root.show(which);
    }

    readonly property var tabs: [
        { id: "watch",    title: "Vigília",  glyph: Theme.glyph.cpu },
        { id: "organ",    title: "Órgão",    glyph: Theme.glyph.volHigh },
        { id: "ravens",   title: "Corvos",   glyph: Theme.glyph.wifi[3] },
        { id: "runelink", title: "Elo",      glyph: Theme.glyph.bt },
        { id: "crypt",    title: "Cripta",   glyph: Theme.glyph.bell },
        { id: "sigils",   title: "Sigilos",  glyph: Theme.glyph.fleuron },
        { id: "almanac",  title: "Almanaque", glyph: Theme.glyph.moon }
    ]

    LazyLoader {
        activeAsync: root.open

        PanelWindow {
            id: win

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "keep-hall"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            anchors { left: true; right: true; top: true; bottom: true }

            // Clicar fora fecha.
            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }

            Item {
                id: slab

                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                anchors.topMargin: Theme.metric.barHeight + Theme.metric.crenelHeight
                width: Theme.metric.hallWidth + rail.width

                // Desliza da direita.
                x: parent.width
                Component.onCompleted: x = parent.width - width

                Behavior on x {
                    NumberAnimation { duration: Theme.anim.slow; easing.type: Easing.OutCubic }
                }

                MouseArea { anchors.fill: parent }

                // ── As flâmulas laterais ───────────────────────
                Rectangle {
                    id: rail

                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: 46
                    color: Theme.bgDeep

                    Rectangle {
                        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                        width: 1
                        color: Theme.borderInner
                    }

                    Column {
                        anchors { left: parent.left; right: parent.right; top: parent.top }
                        anchors.topMargin: Theme.pad.base

                        Repeater {
                            model: root.tabs

                            Item {
                                id: banner

                                required property var modelData
                                readonly property bool here: root.page === banner.modelData.id

                                width: rail.width
                                height: 46

                                Rectangle {
                                    anchors.fill: parent
                                    color: banner.here ? Theme.bgPanel
                                         : tabArea.containsMouse ? Theme.alpha(Theme.gold, 0.08)
                                                                 : "transparent"
                                    Behavior on color { ColorAnimation { duration: Theme.anim.instant } }
                                }

                                // A flâmula acesa: fio dourado na borda.
                                Rectangle {
                                    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                                    width: 2
                                    color: Theme.accentLit
                                    visible: banner.here
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: banner.modelData.glyph
                                    font.family: Theme.font.mono
                                    font.pixelSize: Theme.size.title
                                    color: banner.here ? Theme.accentLit
                                         : tabArea.containsMouse ? Theme.ash
                                                                 : Theme.fgDim
                                    renderType: Text.NativeRendering

                                    Behavior on color { ColorAnimation { duration: Theme.anim.quick } }
                                }

                                MouseArea {
                                    id: tabArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.page = banner.modelData.id
                                }

                                ToolTipish {
                                    anchor: banner
                                    text: banner.modelData.title
                                    shown: tabArea.containsMouse && !banner.here
                                }
                            }
                        }
                    }
                }

                // ── O salão ────────────────────────────────────
                Rectangle {
                    anchors { left: rail.right; right: parent.right; top: parent.top; bottom: parent.bottom }
                    color: Theme.bgPanel

                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: 1
                        color: Theme.borderInner
                    }

                    Fleuron { anchors { right: parent.right; top: parent.top; rightMargin: 4; topMargin: 3 } }
                    Fleuron { anchors { right: parent.right; bottom: parent.bottom; rightMargin: 4; bottomMargin: 3 } }

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: Theme.pad.wide
                        contentHeight: pages.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Item {
                            id: pages

                            width: parent.width
                            implicitHeight: loader.implicitHeight

                            Loader {
                                id: loader

                                width: parent.width
                                asynchronous: true

                                sourceComponent: {
                                    switch (root.page) {
                                        case "organ":    return organPage;
                                        case "ravens":   return ravensPage;
                                        case "runelink": return runelinkPage;
                                        case "crypt":    return cryptPage;
                                        case "sigils":   return sigilsPage;
                                        case "almanac":  return almanacPage;
                                        default:         return watchPage;
                                    }
                                }

                                // Cada troca de aba entra com um respiro.
                                onLoaded: fade.restart()

                                NumberAnimation {
                                    id: fade
                                    target: loader; property: "opacity"
                                    from: 0; to: 1
                                    duration: Theme.anim.base
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }

            Component { id: watchPage;    Watch    { width: pages.width } }
            Component { id: organPage;    Organ    { width: pages.width } }
            Component { id: ravensPage;   Ravens   { width: pages.width } }
            Component { id: runelinkPage; Runelink { width: pages.width } }
            Component { id: cryptPage;    Crypt    { width: pages.width } }
            Component { id: almanacPage;  Almanac  { width: pages.width } }
            Component {
                id: sigilsPage
                Sigils {
                    width: pages.width
                    onAction: what => { root.hide(); root.action(what); }
                }
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.hide()
                Component.onCompleted: forceActiveFocus()
            }
        }
    }
}
