// ═══════════════════════════════════════════════════════════════
//  BUSCA DIFUSA
//  Pontua o quanto um texto responde ao que foi digitado.
//  Funções puras — testadas em tools/test-parsers.qml.
//
//  A ideia é a de sempre (fzf, Sublime): a consulta precisa ser uma
//  subsequência do alvo, e o que separa um bom acerto de um ruim é
//  ONDE as letras caem. "ff" deve achar "Firefox" antes de
//  "Diff Tool", porque acertou o início de duas palavras.
// ═══════════════════════════════════════════════════════════════

.pragma library

var BONUS_START     = 18;   // primeira letra do alvo
var BONUS_WORD      = 12;   // início de palavra: após espaço, - _ . /
var BONUS_CAMEL     = 8;    // fronteira camelCase
var BONUS_RUN       = 7;    // letra colada na anterior
var PENALTY_GAP     = -2;   // por letra pulada
var PENALTY_GAP_MAX = -20;  // teto do castigo por buraco

function isBoundary(ch) {
    return ch === " " || ch === "-" || ch === "_" || ch === "."
        || ch === "/" || ch === ":" || ch === "(";
}

function isUpper(ch) { return ch >= "A" && ch <= "Z"; }
function isLower(ch) { return ch >= "a" && ch <= "z"; }

/// Pontua `query` contra `text`. Devolve -1 quando não casa.
/// Quanto maior, melhor.
function score(query, text) {
    if (!query || query.length === 0) return 0;
    if (!text || text.length === 0) return -1;

    var q = query.toLowerCase();
    var t = text.toLowerCase();

    // Atalhos que valem muito e custam pouco.
    if (t === q) return 1000;
    if (t.indexOf(q) === 0) return 800 - (t.length - q.length);

    var total = 0;
    var ti = 0;
    var prevMatch = -2;
    var gapRun = 0;

    for (var qi = 0; qi < q.length; qi++) {
        var want = q.charAt(qi);
        var found = -1;

        while (ti < t.length) {
            if (t.charAt(ti) === want) { found = ti; break; }
            ti++;
        }

        if (found === -1) return -1;   // não é subsequência

        var bonus = 0;
        if (found === 0) {
            bonus += BONUS_START;
        } else {
            var before = text.charAt(found - 1);
            if (isBoundary(before)) bonus += BONUS_WORD;
            else if (isLower(before) && isUpper(text.charAt(found))) bonus += BONUS_CAMEL;
        }

        if (found === prevMatch + 1) bonus += BONUS_RUN;
        else if (prevMatch >= 0) {
            gapRun = found - prevMatch - 1;
            bonus += Math.max(PENALTY_GAP_MAX, gapRun * PENALTY_GAP);
        }

        total += bonus + 1;
        prevMatch = found;
        ti++;
    }

    // Entre dois alvos igualmente bem casados, o mais curto ganha:
    // "Files" antes de "Files (Recuperação de arquivos antigos)".
    return total - Math.floor(text.length / 12);
}

/// Melhor pontuação entre vários campos, com peso por campo.
/// `fields` = [[texto, peso], ...]
function scoreFields(query, fields) {
    var best = -1;
    for (var i = 0; i < fields.length; i++) {
        var s = score(query, fields[i][0]);
        if (s < 0) continue;
        s = s * fields[i][1];
        if (s > best) best = s;
    }
    return best;
}

/// Quais letras do alvo casaram — para destacar na lista.
/// Devolve os índices, ou [] se não casa.
function positions(query, text) {
    if (!query || query.length === 0) return [];

    var q = query.toLowerCase();
    var t = text.toLowerCase();
    var out = [];
    var ti = 0;

    for (var qi = 0; qi < q.length; qi++) {
        var found = -1;
        while (ti < t.length) {
            if (t.charAt(ti) === q.charAt(qi)) { found = ti; break; }
            ti++;
        }
        if (found === -1) return [];
        out.push(found);
        ti++;
    }
    return out;
}

/// Peso do hábito: quantas vezes foi usado, decaindo com o tempo.
/// Meia-vida de duas semanas — o que você usou ontem pesa mais que
/// o que você usou muito no ano passado.
function frecency(count, lastUsedMs, nowMs) {
    if (!count || count <= 0) return 0;
    var days = (nowMs - lastUsedMs) / 86400000;
    if (days < 0) days = 0;
    return count * Math.pow(0.5, days / 14);
}
