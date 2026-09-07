pragma Singleton

//  ╔═══════════════════════════════════════════════════════════════╗
//  ║  O LIVRO DAS HORAS                                            ║
//  ║  Fase da lua, hora das bruxas, e a voz do castelo.            ║
//  ║  Estados vazios não dizem "vazio". Dizem alguma coisa.        ║
//  ╚═══════════════════════════════════════════════════════════════╝

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ═══ O RELÓGIO DAS SOMBRAS ═════════════════════════════════════

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property date now: clock.date

    /// 03:00–03:59 — quando as coisas que dormem acordam.
    readonly property bool witching: clock.date.getHours() === 3

    /// Sexta-feira 13. O brasão troca a cruz por uma caveira.
    readonly property bool cursedDay: clock.date.getDay() === 5
                                   && clock.date.getDate() === 13

    /// Noite de verdade (para escurecer levemente a névoa).
    readonly property bool nocturnal: clock.date.getHours() >= 22
                                   || clock.date.getHours() < 6

    // ═══ A VIGÍLIA ═════════════════════════════════════════════════
    //
    // Há quanto tempo o castelo está de pé, em segundos, sem poll.
    //
    // O caminho óbvio seria Sys.uptime, e ele NÃO SERVE: o /proc/uptime
    // só é relido quando `Sys.detailed` é verdadeiro, isto é, enquanto
    // algum popup está aberto. Fora disso o valor fica congelado no que
    // era da última vez que alguém olhou, e vale zero até o primeiro
    // popup da sessão. É a decisão certa lá — uptime nunca aparece na
    // muralha, só no Epitáfio e no Salão — e a errada aqui.
    //
    // Então: o instante do boot é lido UMA VEZ, e o resto é subtração.
    // Quem conta o tempo passar é o SystemClock que este arquivo já
    // paga para saber a hora, e ele bate de minuto em minuto. Custo
    // marginal de saber a idade do castelo: zero leitura, zero timer.

    /// Milissegundos desde a época no instante do boot. 0 até ler.
    property real bootAt: 0

    FileView {
        path: "/proc/uptime"
        printErrors: false
        onLoaded: {
            const s = parseFloat(text().split(" ")[0]);
            if (isFinite(s)) root.bootAt = Date.now() - s * 1000;
        }
    }

    /// Segundos de vigília. Anda sozinho, na batida do relógio.
    readonly property real vigilSeconds:
        bootAt > 0 ? Math.max(0, (clock.date.getTime() - bootAt) / 1000) : 0

    /// Dias INTEIROS de vigília — muda uma vez por dia, e é de propósito.
    /// Quem se pendura aqui repinta uma vez por dia, não uma por minuto.
    readonly property int vigilDays: Math.floor(vigilSeconds / 86400)

    // ═══ A LUA ═════════════════════════════════════════════════════
    // Lua nova de referência: 2000-01-06 18:14 UTC.
    // Mês sinódico: 29,530588853 dias.

    readonly property real moonAge: {
        const epoch = Date.UTC(2000, 0, 6, 18, 14, 0);
        const days = (clock.date.getTime() - epoch) / 86400000;
        const syn = 29.530588853;
        return ((days % syn) + syn) % syn;
    }

    /// 0.0 = lua nova · 0.5 = cheia · 1.0 = nova de novo
    readonly property real moonPhase: moonAge / 29.530588853

    /// Fração iluminada do disco, 0..1. É isto que o widget desenha.
    readonly property real moonLit: (1 - Math.cos(2 * Math.PI * moonPhase)) / 2

    /// Crescente (à direita) ou minguante (à esquerda)?
    readonly property bool moonWaxing: moonPhase < 0.5

    readonly property string moonName: {
        const p = moonPhase;
        if (p < 0.0335 || p >= 0.9665) return "Lua Nova";
        if (p < 0.2165) return "Crescente Côncava";
        if (p < 0.2835) return "Quarto Crescente";
        if (p < 0.4665) return "Crescente Gibosa";
        if (p < 0.5335) return "Lua Cheia";
        if (p < 0.7165) return "Minguante Gibosa";
        if (p < 0.7835) return "Quarto Minguante";
        return "Minguante Côncava";
    }

    // ═══ A VOZ DO CASTELO ══════════════════════════════════════════

    readonly property var aphorisms: [
        "As pedras lembram de todos que passaram.",
        "Ninguém guarda o torreão para sempre.",
        "O que dorme sob a capela não foi enterrado.",
        "As tochas queimam por hábito, não por esperança.",
        "Conte as horas. Elas contam você.",
        "O fosso ficou seco. O que vivia nele, não.",
        "Nenhum sino toca aqui desde o cerco.",
        "A hera segura as paredes que a argamassa largou.",
        "Há mais nomes na cripta do que no salão.",
        "O vento conhece cada corredor pelo nome.",
        "As armaduras estão vazias. Algumas sempre estiveram.",
        "Quem ergueu estas muralhas não confiava no campo aberto.",
        "O último escriba não terminou a frase.",
        "A ponte levadiça baixa sozinha, às vezes.",
        "Guarde bem o portão. O de dentro também."
    ]

    readonly property var latin: [
        "Non licet transire.",        // Não é permitido passar.
        "Memento mori.",              // Lembra-te da morte.
        "Vigilate et orate.",         // Vigiai e orai.
        "Nemo intrat.",               // Ninguém entra.
        "Umbrae ambulant.",           // As sombras caminham.
        "Porta clausa est."           // O portão está fechado.
    ]

    /// Aforismo estável dentro da mesma hora — não fica trocando
    /// enquanto você olha, mas muda ao longo do dia.
    function aphorism() {
        const seed = clock.date.getFullYear() * 10000
                   + clock.date.getMonth() * 100
                   + clock.date.getDate()
                   + clock.date.getHours();
        return aphorisms[seed % aphorisms.length];
    }

    function anyLatin() {
        return latin[Math.floor(Math.random() * latin.length)];
    }

    // ═══ ESTADOS VAZIOS ════════════════════════════════════════════
    // É onde a maioria dos rices morre. Aqui cada vazio tem voz.

    readonly property var emptiness: ({
        "crypt":     "Nada assombra esta noite.",
        "grimoire":  "O grimório não conhece esse feitiço.",
        "bluetooth": "Nenhum elo foi forjado.",
        "wifi":      "Nenhum corvo pousou na torre.",
        "tray":      "O mensageiro não trouxe nada.",
        "media":     "Silêncio no salão.",
        "windows":   "Nenhuma aparição por aqui.",
        "files":     "O arquivo não guarda esse nome.",
        "apps":      "O grimório aguarda.",
        "process":   "As forjas estão frias."
    })

    function empty(key) {
        return emptiness[key] !== undefined ? emptiness[key] : "Vazio.";
    }

    // ═══ EPITÁFIO ══════════════════════════════════════════════════

    /// "A vigília durou 3 dias, 4 horas."
    function vigil(seconds) {
        const d = Math.floor(seconds / 86400);
        const h = Math.floor((seconds % 86400) / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        let parts = [];
        if (d > 0) parts.push(d + (d === 1 ? " dia" : " dias"));
        if (h > 0) parts.push(h + (h === 1 ? " hora" : " horas"));
        if (parts.length === 0) parts.push(m + (m === 1 ? " minuto" : " minutos"));
        return "A vigília durou " + parts.join(", ") + ".";
    }

    /// Marco raro: mais de 30 dias de pé merece uma linha própria.
    function isLongVigil(seconds) { return seconds > 2592000; }

    // ═══ ALGARISMOS ROMANOS ════════════════════════════════════════
    //
    // MORAM NO THEME.ROMAN, e este arquivo não tem mais opinião.
    //
    // Aqui viviam um `numerals[]` com os Ⅰ..Ⅹ do Unicode (U+2160) e um
    // `numeral()` que os servia. Ninguém chamava nenhum dos dois: os
    // dois pontos de uso do castelo — a flâmula da Muralha e a linha de
    // janela do Grimório — chamam Theme.roman(), que compõe com o I, o
    // V e o X do ALFABETO, para os romanos existirem em toda voz.
    //
    // Era código morto, e código morto que contradiz a doutrina é pior
    // que código morto: os dez caracteres estavam ausentes das quatro
    // fontes do repositório, então quem os reusasse ganhava reserva do
    // fontconfig sem aviso. O glyph-audit.py agora varre string de
    // módulo e acusava os dez — e o certo era apagar, não silenciar.

    // ═══ MESES DO ALMANAQUE ════════════════════════════════════════

    readonly property var months: [
        "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
        "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ]

    readonly property var weekdays: ["D", "S", "T", "Q", "Q", "S", "S"]

    readonly property var weekdaysLong: [
        "Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"
    ]
}
