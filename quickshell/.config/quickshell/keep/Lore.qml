pragma Singleton

//  ╔═══════════════════════════════════════════════════════════════╗
//  ║  O LIVRO DAS HORAS                                            ║
//  ║  Fase da lua, hora das bruxas, e a voz do castelo.            ║
//  ║  Estados vazios não dizem "vazio". Dizem alguma coisa.        ║
//  ╚═══════════════════════════════════════════════════════════════╝

import QtQuick
import Quickshell

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
        "apps":      "Nenhum feitiço com esse nome.",
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
    // Ⅰ..Ⅹ como caracteres únicos (U+2160+). O X faltava na waybar.

    readonly property var numerals: [
        "Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ", "Ⅴ",
        "Ⅵ", "Ⅶ", "Ⅷ", "Ⅸ", "Ⅹ"
    ]

    function numeral(n) {
        if (n >= 1 && n <= 10) return numerals[n - 1];
        // Acima de X, compõe à moda antiga.
        const vals = [100, 90, 50, 40, 10, 9, 5, 4, 1];
        const syms = ["C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];
        let out = "", v = n;
        for (let i = 0; i < vals.length; i++)
            while (v >= vals[i]) { out += syms[i]; v -= vals[i]; }
        return out;
    }

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
