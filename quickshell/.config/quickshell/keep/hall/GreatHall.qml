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
            color: "transparent"

            // Zona zero, mas em modo Normal: não reserva espaço para
            // si e ainda assim respeita o de quem já reservou. É o
            // que faz o Salão nascer exatamente sob a Muralha, sem
            // precisar somar alturas à mão — e continua certo com a
            // waybar antiga no ar durante a transição.
            exclusiveZone: 0

            anchors { left: true; right: true; top: true; bottom: true }

            // Clicar fora fecha.
            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }

            Item {
                id: slab

                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                width: Theme.metric.hallWidth + rail.width + tower.width

                // Desliza da direita.
                x: parent.width
                Component.onCompleted: x = parent.width - width

                Behavior on x {
                    NumberAnimation { duration: Theme.anim.slow; easing.type: Easing.OutCubic }
                }

                MouseArea { anchors.fill: parent }

                // ── As ameias do Salão ─────────────────────────
                // A mesma ideia de degraus da Muralha, na lateral, no
                // topo e no pé: o Salão é uma torre pendurada na
                // parede, não uma gaveta que abriu.
                //
                // O corpo abaixo RECUA a profundidade dos dentes em
                // cada borda ameiada. Sem isso a pedra do fundo
                // cobria os vãos e só a linha de contorno aparecia —
                // as ameias ficavam invisíveis.

                readonly property int cren: Theme.metric.crenelHeight
                readonly property int quoin: 6

                Crenellation {
                    id: tower

                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    edge: Qt.LeftEdge
                    // A cor do corrimão, que é quem ela encosta.
                    stone: Theme.bgDeep
                    rim: Theme.borderOuter
                    heat: Settings.data.weather ? Theme.heat : 0

                    // Numa borda vertical o motivo lê como cantaria —
                    // as pedras de canto de uma torre. Cantaria é
                    // regular, então nada de merlão faltando; e mais
                    // rasa, senão vira zíper ao longo de mil pixels.
                    ruined: false
                    depth: slab.quoin
                    merlon: 18
                    gap: 14
                    z: 3
                }

                // O encaixe com a Muralha: dentes apontando para CIMA,
                // defasados meio compasso, para cada um nascer sob um
                // vão dela. Os dois perfis se fecham como fiada de
                // pedra, em vez de deixar uma tira de papel de parede
                // entre a barra e o painel.
                Crenellation {
                    anchors { left: tower.right; right: parent.right; top: parent.top }
                    edge: Qt.TopEdge
                    stone: Theme.bg
                    rim: Theme.borderOuter
                    heat: Settings.data.weather ? Theme.heat : 0
                    ruined: false
                    phase: slab.x + tower.width
                         + (Theme.metric.crenelWidth + Theme.metric.crenelGap) / 2
                    z: 3
                }

                Crenellation {
                    anchors { left: tower.right; right: parent.right; bottom: parent.bottom }
                    edge: Qt.BottomEdge
                    stone: Theme.bg
                    rim: Theme.borderOuter
                    heat: Settings.data.weather ? Theme.heat : 0
                    // Em compasso com os dentes da Muralha, que
                    // começam na borda da tela.
                    phase: slab.x + tower.width
                    z: 3
                }

                // ── As flâmulas laterais ───────────────────────
                Rectangle {
                    id: rail

                    anchors {
                        left: tower.right
                        top: parent.top; topMargin: slab.cren
                        bottom: parent.bottom; bottomMargin: slab.cren
                    }
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
                                    color: banner.here ? Theme.bg
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
                    anchors {
                        left: rail.right; right: parent.right
                        top: parent.top; topMargin: slab.cren
                        bottom: parent.bottom; bottomMargin: slab.cren
                    }
                    // A mesma pedra da Muralha, não um painel mais
                    // claro: as duas superfícies são a mesma parede.
                    color: Theme.bg

                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: 1
                        color: Theme.borderInner
                    }

                    Fleuron { anchors { right: parent.right; top: parent.top; rightMargin: 4; topMargin: 3 } }
                    Fleuron { anchors { right: parent.right; bottom: parent.bottom; rightMargin: 4; bottomMargin: 3 } }

                    Flickable {
                        id: scroll

                        anchors.fill: parent
                        anchors.margins: Theme.pad.wide
                        contentHeight: pages.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        // Sem arrasto: clicar e puxar o conteúdo num
                        // painel de controle é fácil de fazer sem
                        // querer, e atrapalha mais do que serve. A
                        // roda faz o trabalho.
                        interactive: false

                        readonly property real limit:
                            Math.max(0, contentHeight - height)

                        Behavior on contentY {
                            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                        }

                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: e => {
                                const step = e.angleDelta.y !== 0 ? e.angleDelta.y : e.angleDelta.x;
                                scroll.contentY = Math.max(0,
                                    Math.min(scroll.limit, scroll.contentY - step));
                            }
                        }

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
