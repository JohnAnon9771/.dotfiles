pragma ComponentBehavior: Bound

//  ╔═══════════════════════════════════════════════════════════════╗
//  ║  A MURALHA                                                    ║
//  ║  A barra do torreão. Uma por monitor.                         ║
//  ║                                                               ║
//  ║  A borda de baixo é de ameias de verdade: merlões desenhados,  ║
//  ║  alguns gastos, um ou outro desabado. É a assinatura do rice.  ║
//  ╚═══════════════════════════════════════════════════════════════╝

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.ui
import qs.services
import qs.rampart.modules

Scope {
    id: root

    signal openHall(string page)
    signal openOssuary()
    signal openAlmanac()

    /// A primeira muralha erguida. O inibidor de ociosidade precisa
    /// de uma janela a que se prender.
    property var primaryBar: null

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData

            screen: modelData
            WlrLayershell.namespace: "keep-rampart"
            color: "transparent"

            anchors { left: true; right: true; top: true }

            // ═══ A JANELA CRESCE, A EXCLUSIVA NÃO ══════════════
            //
            // Os estandartes pendem abaixo da ameia, sobre o desktop.
            // Para isso a janela precisa de mais 14 px de altura — mas
            // se a zona exclusiva crescesse junto, toda janela do
            // sistema desceria 14 px para acomodar um pano.
            //
            // Então a exclusiva fica presa no que a muralha realmente
            // OCUPA (parede + ameia) e o resto é sobreposição. Sem o
            // exclusionMode explícito o Quickshell derivaria a zona da
            // altura da janela, que é justamente o que não se quer.
            readonly property int solid: Theme.metric.barHeight
                                       + Theme.metric.crenelHeight

            implicitHeight: solid + Theme.metric.bannerDrop
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: solid

            // ═══ E A MÁSCARA, QUE É O PREÇO ════════════════════
            //
            // Uma janela de layer-shell recebe ponteiro na área
            // inteira. Sem máscara, os 14 px de folga virariam uma
            // faixa invisível atravessando a tela que engole clique de
            // quem está embaixo — o pior tipo de bug, porque não se vê.
            //
            // Então o que aceita ponteiro é declarado: a parede, as
            // ameias, e a tira dos estandartes. O resto é buraco.
            //
            // A tira cobre também os VÃOS entre um pano e outro, e isso
            // é de propósito e não tolerância: ali a roda do mouse
            // troca de sala, igual à faixa dos algarismos lá em cima.
            // O que seria acidente vira função.
            mask: Region {
                Region { item: wall }
                Region { item: crenels }
                Region { item: bannerStrip }
            }

            Component.onCompleted: if (!root.primaryBar) root.primaryBar = bar

            // ═══ A PAREDE ══════════════════════════════════════

            Rectangle {
                id: wall

                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: Theme.metric.barHeight
                color: Theme.bg

                // A cantaria. Pintada uma vez: em repouso este Canvas
                // não é tocado. Ver ui/Masonry.qml para por que ela não
                // reage à carga.
                //
                // Sem z negativo, e isso não é detalhe: no Qt Quick um
                // item com z < 0 vai para trás DO PRÓPRIO PAI, não para
                // trás dos irmãos. Com `z: -1` a cantaria ficava atrás
                // do Rectangle opaco da parede — desenhada, custando o
                // Canvas inteiro, e invisível. Aqui a ordem de
                // declaração já basta: ela vem antes do fio de ferro, e
                // as três Row são irmãs da parede e vêm depois.
                Masonry {
                    anchors.fill: parent
                }

                // ═══ OS CONTRAFORTES ═══════════════════════════
                //
                // As duas pontas eram corte seco: a parede simplesmente
                // acabava contra a borda da tela. Aqui elas ganham
                // cantaria de canto — as pedras alternadas com que se
                // fecha a quina de uma torre.
                //
                // É a MESMA Crenellation da borda de baixo, virada para
                // o lado, que é como o Grande Salão já desenha a quina
                // dele. Numa borda vertical o motivo deixa de ler como
                // ameia e passa a ler como cantaria, e por isso vale a
                // mesma regra de lá: cantaria é REGULAR — nada de
                // merlão desabado — e mais rasa, senão vira zíper.
                //
                // Passo de 22 em 34 px de parede dá pedra sim, pedra
                // não, e é a gárgula que senta em cima.

                Crenellation {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    edge: Qt.LeftEdge
                    stone: Theme.mix(Theme.bg, Theme.rim, 0.30)
                    rim: Theme.borderOuter
                    ruined: false
                    depth: 5
                    merlon: 11
                    gap: 11
                    heat: 0
                }

                Crenellation {
                    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                    edge: Qt.RightEdge
                    stone: Theme.mix(Theme.bg, Theme.rim, 0.30)
                    rim: Theme.borderOuter
                    ruined: false
                    depth: 5
                    merlon: 11
                    gap: 11
                    heat: 0
                }

                // Moldura de ferro, herdada da barra antiga.
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: 1
                    color: Theme.borderOuter
                }
            }

            // ═══ AS AMEIAS ═════════════════════════════════════

            Crenellation {
                id: crenels

                anchors { left: parent.left; right: parent.right; top: wall.bottom }
                stone: Theme.bg
                rim: Theme.borderOuter
                heat: Settings.data.weather ? Theme.heat : 0
            }

            // A área de ponteiro dos estandartes. Invisível: quem
            // desenha pano é cada flâmula, lá dentro do Workspaces,
            // porque só ela sabe onde cada algarismo caiu.
            Item {
                id: bannerStrip

                x: leftSide.x + flags.x
                y: bar.solid
                width: flags.width
                height: Theme.metric.bannerDrop

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: e => Wm.workspaceStep(e.angleDelta.y > 0 ? -1 : 1)
                }
            }

            // ═══ ESQUERDA ══════════════════════════════════════

            Row {
                id: leftSide

                anchors { left: parent.left; top: parent.top }
                height: Theme.metric.barHeight
                spacing: 0

                Crest {
                    id: crest
                    host: hoverPopup
                }

                Workspaces {
                    id: flags
                }

                WindowTitle {
                    // Não invade o centro: encolhe conforme sobra
                    // espaço. Depende só de coisas que não dependem
                    // dele, senão vira laço de vinculação.
                    maxWidth: Math.max(0, middle.x - crest.width - flags.width
                                          - Theme.pad.vast)
                }
            }

            // ═══ CENTRO — A VIGÍLIA ════════════════════════════

            Row {
                id: middle

                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
                height: Theme.metric.barHeight
                spacing: 0

                CpuModule {
                    host: hoverPopup
                    onActivated: root.openHall("watch")
                }
                GpuModule {
                    host: hoverPopup
                    onActivated: root.openHall("watch")
                }
                RamModule {
                    host: hoverPopup
                    onActivated: root.openHall("watch")
                }
                TempModule {
                    host: hoverPopup
                    onActivated: root.openHall("watch")
                }
                DiskModule {
                    host: hoverPopup
                    onActivated: root.openHall("watch")
                }
                NetModule {
                    host: hoverPopup
                    onActivated: root.openHall("ravens")
                }
            }

            // ═══ AS PILASTRAS ══════════════════════════════════
            //
            // A barra tem três grupos — identidade, vigília, serviços —
            // e até aqui não havia nada entre eles: três Row de
            // spacing 0 encostadas, separadas só pelo realce de hover,
            // que só existe quando o mouse está lá.
            //
            // O ui/Divider já resolvia isto e nunca tinha subido na
            // muralha: ele é usado em sete lugares, todos painel ou
            // popup. Aqui ele ancora nas bordas da Row do centro, que é
            // a única com âncora fixa — as outras duas correm com o
            // conteúdo.
            //
            // FERRO FRIO, e é decisão de lei e não de gosto. O elo do
            // Divider é ouro a 50%, o que passa numa lista de popup e
            // não passa repetido na parede: ouro é foco e ativo, e duas
            // pilastras douradas acesas o dia inteiro gastariam a cor
            // do foco com decoração. A única tocha acesa do castelo
            // continua sendo o numeral do workspace em que você está.

            Divider {
                anchors {
                    right: middle.left
                    rightMargin: Theme.pad.roomy
                    verticalCenter: wall.verticalCenter
                }
                vertical: true
                implicitHeight: Theme.metric.barHeight - Theme.pad.snug * 2
                wire: Theme.borderOuter
                link: Theme.iron
            }

            Divider {
                anchors {
                    left: middle.right
                    leftMargin: Theme.pad.roomy
                    verticalCenter: wall.verticalCenter
                }
                vertical: true
                implicitHeight: Theme.metric.barHeight - Theme.pad.snug * 2
                wire: Theme.borderOuter
                link: Theme.iron
            }

            // ═══ DIREITA ═══════════════════════════════════════

            Row {
                id: rightSide

                anchors { right: parent.right; top: parent.top }
                height: Theme.metric.barHeight
                spacing: 0

                Tray {
                    barWindow: bar
                }

                Bard {
                    host: hoverPopup
                }

                Volume {
                    host: hoverPopup
                    onOpenHall: root.openHall("organ")
                }

                Bell {
                    onOpenCrypt: root.openHall("crypt")
                }

                Reaper {
                    host: hoverPopup
                    onOpenOssuary: root.openOssuary()
                }

                Clock {
                    onOpenAlmanac: root.openAlmanac()
                }
            }

            // ═══ A JANELA DA TORRE ═════════════════════════════
            // Uma só, compartilhada por todos os módulos.

            BarPopup {
                id: hoverPopup
            }
        }
    }
}
