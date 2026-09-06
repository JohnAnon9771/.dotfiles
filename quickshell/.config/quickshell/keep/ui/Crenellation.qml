//  AMEIAS — a assinatura do torreão.
//
//  Um perfil só, traçado de ponta a ponta: a silhueta é o que lê. A
//  primeira versão eram retângulos soltos com um fio no topo de cada
//  um, e contra a parede escura só o fio aparecia — a barra ganhava
//  uma borda pontilhada em vez de uma muralha.
//
//  Serve em qualquer borda. O Grande Salão usa a de baixo e a da
//  esquerda, para ler como uma torre pendurada na muralha.

import QtQuick
import qs

Canvas {
    id: root

    /// De que lado os dentes apontam.
    property int edge: Qt.BottomEdge   // Bottom, Top, Left, Right

    property color stone: Theme.bg
    property color rim: Theme.iron
    /// 0..1 — brasa subindo pela muralha sob carga.
    property real heat: Theme.heat
    property bool ruined: true

    /// Se este perfil desenha a própria silhueta.
    ///
    /// Um perfil que só PREENCHE o vão de outro não é uma segunda fiada:
    /// é a pedra que faltava. Se ele traçar o próprio fio, as duas linhas
    /// ficam lado a lado e o encaixe vira zíper. Quem carrega a silhueta
    /// é sempre o perfil que dá para fora — a Muralha, no caso do
    /// encontro dela com o Grande Salão.
    property bool rimmed: true

    /// Este perfil é o NEGATIVO de outro, não um perfil próprio.
    ///
    /// `merlon` e `gap` continuam sendo os DA OUTRA superfície: o que
    /// muda é o que se preenche. Onde ela tem dente, aqui fica só o que
    /// faltou ao dente — nada, se ele estiver inteiro; onde ela tem vão,
    /// aqui é cheio.
    ///
    /// Encaixe periódico não dá conta disto. Trocar merlão por vão fecha
    /// os vãos, mas não fecha a RUÍNA: um merlão desabado abre um buraco
    /// de 15 px que nenhum dente de 11 alcança, e o que aparecia lá era
    /// o papel de parede — uma janelinha no meio da parede. O negativo
    /// fecha os dois, porque não supõe padrão nenhum: ele lê o perfil
    /// da outra dente a dente.
    property bool complement: false

    /// Quanto o negativo POUPA junto à linha da parede, em px.
    /// Só faz sentido com `complement`.
    ///
    /// A outra superfície traça o fio dela por toda a silhueta, teto
    /// incluído — e o teto é justamente onde o negativo é mais cheio.
    /// Preenchendo até lá em cima, o negativo apaga o trecho do fio que
    /// corre pelos vãos e deixa só o que sobra: o fundo e os flancos de
    /// cada merlão, soltos. É o U.
    ///
    /// Poupando um pixel, o fio sobrevive inteiro. As duas ameias ficam
    /// na MESMA pedra, e o que mostra a costura é ele — um só, contínuo,
    /// desenhando a silhueta da Muralha dentro da faixa cheia.
    property real spare: 0

    /// Deslocamento em pixels do padrão. Serve para casar as ameias
    /// de duas superfícies diferentes: a muralha começa na borda da
    /// tela, e o Salão, que fica no meio dela, precisa saber disso
    /// para os dentes se alinharem.
    property int phase: 0

    readonly property bool vertical: edge === Qt.LeftEdge || edge === Qt.RightEdge
    property int merlon: Theme.metric.crenelWidth
    property int gap: Theme.metric.crenelGap
    property int depth: Theme.metric.crenelHeight

    implicitHeight: vertical ? 0 : depth
    implicitWidth: vertical ? depth : 0

    // onHeatChanged repinta, e isso é aceitável — mas só depois que
    // Sys.pressure e Gpu.pressure passaram a sair em degraus de 1/20
    // (ver Fmt.step). Antes, o ruído de leitura fazia Theme.heat mudar
    // a cada amostra de 2 s, e o Behavior de 1400 ms transformava isso
    // numa repintura por frame de uma tela inteira de merlões, 70% do
    // tempo. Com o degrau, em repouso heat não muda e este Canvas não
    // é tocado.
    //
    // Tentei uma vez separar a brasa e o fio em Canvas próprios, para
    // trocar repintura por opacidade. Ficou pior: três texturas
    // empilhadas somam as bordas antialiased de cada uma, e o fio de
    // luz de 1 px perde o corte. Um passo só de fill+stroke no mesmo
    // contexto é o que deixa a silhueta limpa.
    onStoneChanged: requestPaint()
    onRimChanged: requestPaint()
    onHeatChanged: requestPaint()
    onPhaseChanged: requestPaint()
    onDepthChanged: requestPaint()
    onMerlonChanged: requestPaint()
    onGapChanged: requestPaint()
    onRuinedChanged: requestPaint()
    onRimmedChanged: requestPaint()
    onComplementChanged: requestPaint()
    onSpareChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    /// Quanto o dente n avança. Zero = merlão desabado.
    ///
    /// `n` é o índice do dente NO PADRÃO, contado da origem da fase — e
    /// não a contagem interna deste item. É o que faz duas superfícies
    /// com a mesma fase concordarem sobre qual merlão desabou: sem isso
    /// o negativo tapava o buraco errado.
    function reach(n, d) {
        if (!ruined) return d;
        if (n % 23 === 14) return 0;          // um desabou
        if (n % 7 === 3) return d * 0.62;     // e um está gasto
        return d;
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        const step = merlon + gap;
        // Trabalhamos sempre em "ao longo da borda" × "para dentro",
        // e deixamos a transformação decidir de que lado isso cai.
        const span = vertical ? height : width;
        const d = vertical ? width : height;
        const start = -(((phase % step) + step) % step);
        const count = Math.ceil((span - start) / step) + 1;
        // O índice, no padrão, do primeiro dente que cai neste item.
        // `phase` é onde o zero local do item cai na régua do padrão, e
        // `start` recua até o dente anterior: a soma é sempre múltipla
        // do passo. Para a Muralha, que começa na borda da tela, dá 0.
        const first = Math.round((phase + start) / step);

        ctx.save();

        // Cada caso leva o ponto (aoLongo, paraDentro) ao seu lugar.
        // Conferir a matriz importa: rotate(θ) é [[cos,-sin],[sin,cos]],
        // então rotate(90°) manda (a,b) para (-b,a) — e não para (b,a),
        // que foi o engano que deixou a ameia lateral invisível.
        switch (edge) {
            case Qt.TopEdge:                       // (a,b) → (a, d-b)
                ctx.translate(0, d);
                ctx.scale(1, -1);
                break;
            case Qt.LeftEdge:                      // (a,b) → (d-b, a)
                ctx.translate(d, 0);
                ctx.rotate(Math.PI / 2);
                break;
            case Qt.RightEdge:                     // (a,b) → (b, a)
                ctx.rotate(Math.PI / 2);
                ctx.scale(1, -1);
                break;
            default:                               // BottomEdge: já é assim
                break;
        }

        // Um degrau do perfil: corre pelo teto até x0, mergulha `drop`,
        // atravessa até x1 e volta.
        function dip(x0, x1, drop, inset) {
            ctx.lineTo(x0, inset);
            if (drop > 0) {
                ctx.lineTo(x0, drop - inset);
                ctx.lineTo(x1, drop - inset);
                ctx.lineTo(x1, inset);
            }
        }

        function trace(inset) {
            ctx.beginPath();
            ctx.moveTo(start, inset);

            for (let i = 0; i < count; i++) {
                const a = start + i * step;
                const b = a + merlon;
                const n = first + i;

                if (complement) {
                    // Sob o merlão, o que faltou a ele; sob o vão, tudo —
                    // menos o que `spare` reserva para o fio da outra.
                    // O teto do merlão desabado também respeita o teto,
                    // senão o fio se interrompe justo na ruína.
                    const cap = d - spare;
                    dip(a, b, Math.min(d - reach(n, d), cap), inset);
                    dip(b, a + step, cap, inset);
                } else {
                    dip(a, b, reach(n, d), inset);
                }
            }

            ctx.lineTo(span, inset);
        }

        // Preenchimento: fecha por trás, onde a parede já é sólida.
        trace(0);
        ctx.lineTo(span, -1);
        ctx.lineTo(start, -1);
        ctx.closePath();
        ctx.fillStyle = stone;
        ctx.fill();

        if (heat > 0.02) {
            const g = ctx.createLinearGradient(0, 0, 0, d);
            g.addColorStop(0, Qt.rgba(Theme.ember.r, Theme.ember.g, Theme.ember.b, heat * 0.30));
            g.addColorStop(1, Qt.rgba(Theme.ember.r, Theme.ember.g, Theme.ember.b, 0));
            ctx.fillStyle = g;
            ctx.fill();
        }

        // O fio de luz, correndo pela silhueta.
        if (rimmed) {
            trace(0.5);
            ctx.strokeStyle = rim;
            ctx.lineWidth = 1;
            ctx.stroke();
        }

        ctx.restore();
    }
}
