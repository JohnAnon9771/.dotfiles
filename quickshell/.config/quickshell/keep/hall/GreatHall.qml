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

    // ── O véu ──────────────────────────────────────────────────
    // Pega o clique fora, e é só para isso que existe. Era um MouseArea
    // dentro da janela do Salão, o que obrigava a janela a cobrir a tela
    // inteira — e o Qt danifica a superfície INTEIRA a cada frame que
    // desenha, então qualquer repintura do painel custava ao compositor
    // uma recomposição de 3840x2160. Separado, o véu desenha uma vez e
    // nunca mais: superfície parada não gera dano nenhum.
    //
    // Camada Top, não Overlay: assim ele fica abaixo do Salão sem
    // depender da ordem em que as duas janelas nascem. E a margem
    // superior tira a superfície de cima da Muralha em vez de apenas não
    // tratar o clique lá — o que é mais firme, porque uma camada sem item
    // interativo ainda engole o evento.
    LazyLoader {
        activeAsync: root.open

        PanelWindow {
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "keep-hall-scrim"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            color: "transparent"

            exclusionMode: ExclusionMode.Ignore
            anchors { left: true; right: true; top: true; bottom: true }
            margins.top: Theme.metric.barHeight + Theme.metric.crenelHeight

            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }
        }
    }

    LazyLoader {
        activeAsync: root.open

        PanelWindow {
            id: win

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "keep-hall"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            // O Salão não reserva espaço para si, e TAMBÉM não respeita
            // o de quem reservou. Em modo Normal a janela nascia em
            // y=43, logo abaixo dos dentes da Muralha, e os dois perfis
            // só se encostavam — duas fiadas empilhadas, com costura à
            // vista. Para encaixar de verdade, os dentes do Salão
            // precisam subir PARA DENTRO da faixa dos dentes da
            // Muralha, e para isso a janela precisa alcançar y=34.
            // Só o exclusionMode: atribuir exclusiveZone junto faz o
            // Quickshell voltar o modo para Normal, e a janela nasce
            // de novo abaixo da Muralha.
            exclusionMode: ExclusionMode.Ignore

            // Sem `left`: a janela tem a largura do painel e mais nada.
            // Cobria a tela inteira, e como o Qt danifica a superfície
            // toda a cada frame, um medidor que mexesse obrigava o
            // compositor a recompor 3840x2160. Assim o dano é o painel.
            anchors { right: true; top: true; bottom: true }
            implicitWidth: slab.width

            Item {
                id: slab

                // O topo encosta na PAREDE da Muralha, não nos dentes
                // dela: a faixa de crenelHeight logo abaixo de
                // barHeight passa a ser dividida pelos dois perfis, um
                // apontando para baixo e o outro para cima. O corpo
                // continua recuando slab.cren em cada borda ameiada,
                // então nada de conteúdo sobe junto.
                //
                // Sem `anchors.right`: o anchor e o `x` se atropelavam,
                // um mandando na posição e o outro sobrescrevendo. A
                // janela agora tem a largura do painel, então em repouso
                // o slab mora em x=0 e quem manda é só o deslize.
                anchors {
                    top: parent.top; topMargin: Theme.metric.barHeight
                    bottom: parent.bottom
                }
                width: Theme.metric.hallWidth + rail.width + tower.width

                // Desliza da direita, e ASSENTA EM PIXEL INTEIRO.
                //
                // O que animava era o próprio `x`, em float. Durante os
                // 380 ms a subárvore inteira — as três texturas de Canvas
                // das ameias e todo o texto — ficava sob uma translação
                // de meio pixel: textura amostrada fora da grade sai
                // filtrada, e o fio de luz de 1 px, que só existe porque
                // cai no centro do pixel, se espalhava por duas linhas.
                // Era o borrão da abertura. Ao parar num inteiro tudo
                // voltava ao corte, o que dava a impressão de a nitidez
                // "chegar depois".
                //
                // Animar um número solto e arredondar na saída mantém o
                // deslize e devolve cada quadro à grade. De quebra o
                // valor inicial vem de `slab.width`, que é constante:
                // não depende mais de o compositor já ter dimensionado a
                // janela, e some a chance de o painel nascer em x=-472.
                property real slide: slab.width
                x: Math.round(slab.slide)
                Component.onCompleted: slab.slide = 0

                Behavior on slide {
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

                /// Onde a borda esquerda do Salão cai NA TELA.
                ///
                /// As ameias se penduram aqui, não no `x`: a fase delas se
                /// mede a partir da borda da tela, que é onde o padrão da
                /// Muralha começa, e a janela não alcança mais lá. Além
                /// disso este valor é fixo, e o `x` anima por 380 ms —
                /// cada mudança de `phase` repintaria os Canvas das três
                /// ameias a cada frame do deslize.
                ///
                /// O alinhamento com a Muralha só precisa valer quando o
                /// painel para. Durante o deslize os dentes acompanham a
                /// pedra, que é o que pedra faz.
                readonly property real originX: win.screen ? win.screen.width - win.width : 0

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

                // O encaixe com a Muralha: este perfil é o NEGATIVO do
                // dela, e não uma segunda fiada.
                //
                // Meio compasso nunca encaixou. O merlão dela tem 15 e o
                // vão 11, então um dente de 15 deslocado de 13 caía em
                // [13, 28] enquanto o vão é [15, 26] — invadia 2 px de
                // cada lado, e o que se via era a costura, não o encaixe.
                //
                // Trocar merlão por vão fecharia os vãos, mas não a
                // ruína: um merlão desabado abre 15 px que nenhum dente
                // de 11 alcança. O negativo fecha os dois — ver
                // Crenellation.complement. Por isso merlon e gap ficam
                // nos valores DELA, e a fase é a dela: a Muralha começa
                // na borda da tela, então basta somar onde a nossa borda
                // esquerda cai lá.
                Crenellation {
                    anchors { left: tower.right; right: parent.right; top: parent.top }
                    edge: Qt.TopEdge
                    heat: Settings.data.weather ? Theme.heat : 0

                    complement: true
                    phase: slab.originX + tower.width

                    // A MESMA pedra da Muralha: a faixa é uma parede só,
                    // e quem mostra a costura é o fio.
                    //
                    // Fio nenhum daqui — o único é o dela, e o `spare`
                    // poupa o pixel do teto para ele sobreviver inteiro.
                    // Sem isso o negativo apagava o trecho que corre
                    // pelos vãos e sobrava só o fundo e os flancos de
                    // cada merlão: o U solto.
                    stone: Theme.bg
                    rimmed: false
                    spare: 1
                    z: 3
                }

                Crenellation {
                    anchors { left: tower.right; right: parent.right; bottom: parent.bottom }
                    edge: Qt.BottomEdge
                    stone: Theme.bg
                    rim: Theme.borderOuter
                    heat: Settings.data.weather ? Theme.heat : 0
                    // Em compasso com os dentes da Muralha, que
                    // começam na borda da tela. Esta dá para o papel de
                    // parede, então mantém merlão, vão e fio próprios.
                    phase: slab.originX + tower.width
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
