// ═══════════════════════════════════════════════════════════════
//  ARITMANCIA — a calculadora do grimório.
//  Avalia expressão aritmética sem abrir a porta para código
//  arbitrário: o texto passa por uma lista branca antes de virar
//  função, e só nomes de Math sobrevivem.
// ═══════════════════════════════════════════════════════════════

.pragma library

var FUNCS = ["sqrt", "cbrt", "abs", "floor", "ceil", "round", "sign",
             "sin", "cos", "tan", "asin", "acos", "atan",
             "log2", "log10", "log", "exp", "pow", "min", "max", "hypot", "trunc"];

var CONSTS = { pi: Math.PI, e: Math.E, tau: Math.PI * 2, phi: (1 + Math.sqrt(5)) / 2 };

/// Devolve { ok, value, text } — ou { ok: false } se não for conta.
function calc(input) {
    var src = String(input).trim();
    if (src.length === 0) return { ok: false };

    // Precisa ter pelo menos um operador ou função: "42" sozinho não
    // é uma conta, é um número, e não vale abrir a aritmancia por ele.
    if (!/[-+*/^%()]|\b(sqrt|log|sin|cos|tan|abs|min|max|pow)\b/.test(src))
        return { ok: false };

    var expr = src
        .replace(/,/g, ".")          // vírgula decimal
        .replace(/\^/g, "**")
        // O numero inteiro, nao so o ultimo digito: "20%" tem de virar
        // (20/100), senao "200*20%" lia "200*2*(0/100)" e dava zero.
        .replace(/(\d+(?:\.\d+)?)\s*%(?![\d.])/g, "($1/100)");

    // Lista branca: dígitos, operadores, parênteses e nomes conhecidos.
    var allowed = new RegExp(
        "^(?:[0-9.\\s()+\\-*/%,]|\\*\\*|" +
        FUNCS.join("|") + "|" + Object.keys(CONSTS).join("|") + ")+$", "i");

    if (!allowed.test(expr)) return { ok: false };

    // Nomes viram Math.* ou constante. Qualquer outro identificador já
    // foi barrado acima.
    expr = expr.replace(/\b([a-z_][a-z0-9_]*)\b/gi, function (m) {
        var low = m.toLowerCase();
        if (CONSTS[low] !== undefined) return "(" + CONSTS[low] + ")";
        if (FUNCS.indexOf(low) >= 0) return "Math." + low;
        return "__nope__";
    });

    if (expr.indexOf("__nope__") >= 0) return { ok: false };

    try {
        var v = Function('"use strict"; return (' + expr + ');')();
        if (typeof v !== "number" || !isFinite(v)) return { ok: false };
        return { ok: true, value: v, text: format(v) };
    } catch (e) {
        return { ok: false };
    }
}

function format(v) {
    if (Number.isInteger(v)) return String(v);
    var r = v.toFixed(6).replace(/0+$/, "").replace(/\.$/, "");
    return r;
}
