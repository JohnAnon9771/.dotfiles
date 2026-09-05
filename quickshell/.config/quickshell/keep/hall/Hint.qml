//  A GLOSA — o que aquele sigilo faz, escrito por extenso.
//
//  Existe porque o `detail` de uma linha é uma etiqueta, não uma
//  explicação: cabe "modo noturno", não cabe a frase que diz o que o
//  modo noturno mexe. E o ToolTipish, o outro balão da casa, é linha
//  única e abre À DIREITA do âncora — serve para as flâmulas do
//  corrimão, que são estreitas, e não para uma linha que já ocupa a
//  largura inteira de um painel de 420 px: o balão nasceria fora da
//  tela.
//
//  Então esta desce POR CIMA das linhas de baixo, com a largura do
//  âncora, e quebra o texto. Não empurra nada: a altura da linha não
//  muda, o painel não salta quando o mouse passeia.

import QtQuick
import QtQuick.Window
import qs

Rectangle {
    id: root

    /// A linha a que a glosa pertence.
    property Item anchor: null
    /// O MouseArea que a linha já tem. A glosa não põe outro por cima:
    /// dois MouseArea empilhados roubariam o clique do alternador.
    property MouseArea area: null
    property alias text: body.text
    property color tint: Theme.accent

    //  Espera antes de aparecer. O mesmo compasso do hover da Muralha
    //  (ver rampart/Segment.qml), para o balão não piscar quando o
    //  mouse só está atravessando a lista.
    property int dwell: 320

    readonly property bool wanted:
        root.area !== null && root.area.containsMouse && body.text.length > 0

    property bool shown: false

    onWantedChanged: {
        if (root.wanted) timer.restart();
        else { timer.stop(); root.shown = false; }
    }

    onShownChanged: root.lift(root.shown)

    //  ── Erguer a corrente ──────────────────────────────────────
    //
    //  `z` ordena um item apenas entre os IRMÃOS dele. A linha mora no
    //  Column de uma Section, e a Section mora no Column da página:
    //  erguer só a linha põe o balão acima das outras linhas DA MESMA
    //  seção, e a seção seguinte continua desenhando por cima — o
    //  cabeçalho "Atos" atravessava o texto do balão dos presságios.
    //
    //  Então sobe-se a corrente inteira até o conteúdo do Flickable,
    //  que é onde o clip corta de qualquer jeito. O caminho é só de
    //  Columns, o Loader e o item das páginas, e nenhum deles usa z —
    //  mas o valor anterior é guardado e devolvido assim mesmo, porque
    //  quebrar o z de um item alheio é o tipo de estrago que só
    //  aparece três telas depois.
    property var raised: []

    function lift(on) {
        for (let i = 0; i < root.raised.length; i++)
            root.raised[i].item.z = root.raised[i].z;
        root.raised = [];

        if (!on || !root.anchor) return;

        const chain = [];
        let it = root.anchor;

        //  A parada: o item cujo pai o declara como `contentItem` é o
        //  conteúdo do Flickable. Item comum não tem essa propriedade,
        //  então a comparação é falsa e a subida continua. O teto de 12
        //  é cinto e suspensório para uma árvore que mude de forma.
        for (let n = 0; n < 12 && it && it.parent; n++) {
            chain.push({ item: it, z: it.z });
            it.z = 10;
            if (it.parent.contentItem === it) break;
            it = it.parent;
        }

        root.raised = chain;
    }

    Timer {
        id: timer
        interval: root.dwell
        onTriggered: {
            //  Vira para cima quando não couber. O conteúdo do Salão
            //  mora dentro de um Flickable com clip, então a glosa da
            //  última linha seria cortada pelo pé do painel em vez de
            //  aparecer. Medido na hora de mostrar, que é a única hora
            //  em que a resposta importa — e depois de rolar a lista a
            //  medição de antes já não valeria.
            if (root.anchor && root.Window.height > 0) {
                const foot = root.anchor.mapToItem(null, 0, root.anchor.height).y;
                root.above = foot + root.implicitHeight + Theme.pad.tight
                           > root.Window.height;
            }
            root.shown = true;
        }
    }

    /// Se a glosa sobe em vez de descer.
    property bool above: false

    width: root.anchor ? root.anchor.width : 0
    y: root.above ? -height - Theme.pad.hair : (root.anchor ? root.anchor.height + Theme.pad.hair : 0)
    z: 10

    implicitHeight: body.implicitHeight + Theme.pad.base * 2

    color: Theme.bgRaised
    border.width: 1
    border.color: Theme.borderInner

    visible: opacity > 0.01
    opacity: root.shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.anim.quick } }

    //  O fio da cor do sigilo, do mesmo lado em que a linha acende
    //  quando está ligada: a glosa pertence àquela linha, e não é um
    //  cartão solto que apareceu no meio da lista.
    Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 2
        color: root.tint
    }

    //  Prosa é mono, não Rune: o Rune força versalete e espaçamento
    //  rúnico, que são para rótulo entalhado, e elide em vez de quebrar.
    Text {
        id: body

        anchors {
            fill: parent
            margins: Theme.pad.base
            leftMargin: Theme.pad.roomy
        }
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.tiny
        color: Theme.fgMuted
        wrapMode: Text.WordWrap
        lineHeight: 1.25
        renderType: Text.NativeRendering
    }
}
