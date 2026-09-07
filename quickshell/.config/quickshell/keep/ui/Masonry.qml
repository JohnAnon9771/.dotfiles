//  A CANTARIA — a parede que faltava.
//
//  A Muralha era um Rectangle de cor chapada com um fio de ferro no
//  topo. Todo o ornamento do castelo vivia nas BORDAS — os nove pixels
//  de ameia — ou dentro de glifo; entre os dois havia 34 px de tinta
//  lisa onde três Row flutuavam sem chão. Isto dá chão a elas.
//
//  A GRADE AMARRA NA AMEIA, e é o ponto inteiro.
//
//  A pedra tem a largura de um passo de merlão (Theme.metric.stone =
//  crenelWidth + crenelGap) e começa na mesma origem, então a fiada de
//  baixo abre junta exatamente onde cada dente nasce: o merlão vira o
//  topo de uma pedra em vez de um retângulo pousado sobre um borrão.
//  Casar as duas grades foi o que separou "parede" de "textura".
//
//  A JUNTA NÃO PODE SER HIERARQUIA.
//
//  Ela é o `rim` a 35% sobre a parede, e isso é escolha medida: dá por
//  volta de 1,1:1, na mesma faixa que o commit d6f9aa9 mediu para o
//  que NÃO separa nada (fundo timber × parede, 1,02:1) e bem abaixo do
//  borderInner, que é quem separa de verdade (1,45:1). Se a cantaria
//  competir com um único glifo da barra ela falhou, por mais bonita
//  que esteja — a muralha é onde se lê a máquina, não um papel de
//  parede.
//
//  NADA DE SORTEIO. Toda variação sai de resto de divisão, como a
//  ruína da Crenellation. Determinismo importa por dois motivos: a
//  parede é a mesma entre reinícios, e é a mesma em dois monitores da
//  mesma largura — com Math.random() os dois lados de uma mesa
//  ficariam com paredes diferentes, e isso se vê.
//
//  E NÃO REAGE À CARGA, de propósito. A Crenellation já repinta com o
//  `heat` e se defende: ela tem 9 px de altura. Uma faixa de 34 px na
//  largura da tela é quase quatro vezes os pixels, e a carga JÁ TEM
//  VOZ — o gradiente de brasa da ameia. Uma informação, uma voz.
//
//  O que ela conta é outra coisa: o tempo. Ver `wear`.

import QtQuick
import qs

Canvas {
    id: root

    /// A cor da parede. Todo o resto é derivado dela.
    property color stone: Theme.bg

    /// A junta entre as pedras.
    property color joint: Theme.alpha(Theme.rim, 0.35)

    /// 0..1 — quanto tempo o castelo está de pé.
    ///
    /// Ornamento que carrega informação real, na linha das Velas do
    /// Guardião do §3.8: escorridos descem do topo e líquen entra nas
    /// juntas das pontas conforme a vigília avança, e o boot devolve a
    /// parede limpa. Duas semanas de pé é o teto.
    ///
    /// Vem de Lore.vigilDays, que é INTEIRO: este Canvas repinta uma
    /// vez por dia, e não uma vez por minuto.
    property real wear: Math.min(1, Lore.vigilDays / 14)

    property int course: Theme.metric.course
    property int stoneWidth: Theme.metric.stone

    /// Quanto o líquen avança a partir de cada ponta, em px.
    property int lichenSpan: 180

    onStoneChanged: requestPaint()
    onJointChanged: requestPaint()
    onWearChanged: requestPaint()
    onCourseChanged: requestPaint()
    onStoneWidthChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    /// -1 escura · 0 comum · +1 clara. Estável por pedra.
    ///
    /// Dois primos diferentes para as duas direções: com o mesmo em
    /// ambas a variação sai em diagonal, e o olho acha o padrão na
    /// primeira olhada. Com estes ela lê como pedra escolhida a
    /// esmo por um pedreiro que não estava pensando nisso.
    function tone(c, k) {
        const n = k * 31 + c * 17;
        if (n % 23 === 9) return 1;
        if (n % 13 === 5) return -1;
        return 0;
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        const w = width, h = height;
        if (w <= 0 || h <= 0) return;

        // Fiadas contadas DE BAIXO: é a de baixo que precisa casar com
        // a ameia, e contar de cima faria o encaixe escorregar toda vez
        // que a barHeight mudasse.
        //
        // O resto vai para a fiada DE CIMA, e não vira fiada própria.
        // Com 34 px e curso 11 sobra um pixel: uma quarta fiada de 1 px
        // punha uma junta horizontal encostada no fio de ferro do topo,
        // e as duas juntas lidas como uma linha grossa. Três fiadas,
        // a de cima com 12.
        const rows = Math.max(1, Math.floor(h / course));
        const half = Math.floor(stoneWidth / 2);

        function topo(c) { return c === rows - 1 ? 0 : h - (c + 1) * course; }

        // ── A parede ────────────────────────────────────────────
        ctx.fillStyle = stone;
        ctx.fillRect(0, 0, w, h);

        // ── As pedras que destoam ───────────────────────────────
        // Uns poucos por cento para cada lado — 1,04:1 e 1,05:1 contra
        // a parede, que é a faixa que o d6f9aa9 mediu como "não separa
        // nada". É exatamente o que se quer: matéria, não hierarquia.
        const clara  = Theme.mix(stone, Theme.rim, 0.14);
        const escura = Theme.mix(stone, Theme.coal, 0.30);

        for (let c = 0; c < rows; c++) {
            const y0 = topo(c), y1 = h - c * course;
            const off = (c % 2) * half;
            const first = Math.floor(-off / stoneWidth) - 1;
            const last = Math.ceil((w - off) / stoneWidth) + 1;

            for (let k = first; k <= last; k++) {
                const t = root.tone(c, k);
                if (t === 0) continue;
                ctx.fillStyle = t > 0 ? clara : escura;
                ctx.fillRect(off + k * stoneWidth, y0, stoneWidth, y1 - y0);
            }
        }

        // ── As juntas ───────────────────────────────────────────
        // Um traçado só, um stroke só. A Crenellation já pagou para
        // aprender que empilhar superfícies soma bordas antialiased e
        // o fio de 1 px perde o corte.
        ctx.beginPath();

        for (let c = 1; c < rows; c++) {
            const y = h - c * course + 0.5;
            ctx.moveTo(0, y);
            ctx.lineTo(w, y);
        }

        for (let c = 0; c < rows; c++) {
            const y0 = topo(c), y1 = h - c * course;
            const off = (c % 2) * half;
            for (let x = off; x <= w; x += stoneWidth) {
                if (x <= 0) continue;
                ctx.moveTo(x + 0.5, y0);
                ctx.lineTo(x + 0.5, y1);
            }
        }

        ctx.strokeStyle = joint;
        ctx.lineWidth = 1;
        ctx.stroke();

        if (wear <= 0.01) return;

        // ── O líquen ────────────────────────────────────────────
        // Só nas juntas, e só nas pontas — é onde a parede encontra o
        // que não é parede. Redesenha o mesmo traçado por cima, seis
        // vezes, cada uma alcançando menos: o empilhamento faz o alfa
        // crescer para a borda sem precisar de gradiente.
        //
        // Neutro, porque a paleta não tem verde. Líquen de pedra fria
        // é cinza de qualquer jeito.
        const passos = 6;
        for (let i = 0; i < passos; i++) {
            const span = lichenSpan * (1 - i / passos);
            if (span < 2) break;

            ctx.beginPath();
            for (let c = 1; c < rows; c++) {
                const y = h - c * course + 0.5;
                ctx.moveTo(0, y);
                ctx.lineTo(span, y);
                ctx.moveTo(w - span, y);
                ctx.lineTo(w, y);
            }
            ctx.strokeStyle = Theme.alpha(Theme.dim, wear * 0.09);
            ctx.lineWidth = 1;
            ctx.stroke();
        }

        // ── Os escorridos ───────────────────────────────────────
        // A primeira versão era um gradiente horizontal no topo, e
        // estava errada por baixo do bonito: uma faixa escura correndo
        // a largura da tela, logo abaixo de um fio de ferro que também
        // corre a largura da tela, não lê como fuligem — lê como se o
        // fio tivesse engrossado.
        //
        // Sujeira de parede é VERTICAL. Escorre do topo, coluna a
        // coluna, cada uma com a sua força e o seu alcance, e uma em
        // cada cinco fica limpa. O que era gradiente vira mancha, e
        // mancha é o que o olho lê como tempo.
        for (let k = -1; k <= w / stoneWidth + 1; k++) {
            const n = k * 37;
            if (n % 5 === 0) continue;

            const forca = (n % 23 === 9 ? 0.42
                         : n % 7 === 3  ? 0.26
                                        : 0.34) * wear;
            const alto = course * (n % 11 === 4 ? 1.2
                                 : n % 13 === 6 ? 2.4
                                                : 1.8);
            const x0 = k * stoneWidth + (n % 3 !== 0 ? 2 : 0);
            const larg = stoneWidth - (n % 3 !== 0 ? 6 : 2);

            const g = ctx.createLinearGradient(0, 0, 0, alto);
            g.addColorStop(0, Theme.alpha(Theme.coal, forca));
            g.addColorStop(1, Theme.alpha(Theme.coal, 0));
            ctx.fillStyle = g;
            ctx.fillRect(x0, 0, larg, alto);
        }
    }
}
