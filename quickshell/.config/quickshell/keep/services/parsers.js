// ═══════════════════════════════════════════════════════════════
//  LEITURA DOS ARQUIVOS DO REINO
//  Funções puras: entra texto de /proc, sai objeto. Sem estado,
//  sem QML, sem efeito colateral — por isso dá para testar de
//  verdade em tools/test-parsers.qml, contra o /proc real.
// ═══════════════════════════════════════════════════════════════

.pragma library

function clamp01(v) {
    return v < 0 ? 0 : (v > 1 ? 1 : v);
}

/// /proc/stat → { usage, cores: [0..1], ticks }
/// `prevTicks` é o retorno `ticks` da chamada anterior (ou null na
/// primeira, que sempre devolve zero: uso de CPU é uma diferença,
/// não um valor instantâneo).
function stat(txt, prevTicks) {
    var lines = txt.split("\n");
    var cores = [];
    var ticks = {};
    var usage = 0;

    for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        if (line.substring(0, 3) !== "cpu") break;   // as linhas de cpu vêm primeiro

        var f = line.trim().split(/\s+/);
        var name = f[0];

        // user nice system idle iowait irq softirq steal guest guest_nice
        var total = 0;
        for (var k = 1; k < f.length; k++) {
            var n = parseInt(f[k], 10);
            if (isFinite(n)) total += n;
        }
        var idle = (parseInt(f[4], 10) || 0) + (parseInt(f[5], 10) || 0);

        var use = 0;
        if (prevTicks && prevTicks[name]) {
            var dTotal = total - prevTicks[name].total;
            var dIdle = idle - prevTicks[name].idle;
            if (dTotal > 0) use = clamp01(1 - dIdle / dTotal);
        }
        ticks[name] = { total: total, idle: idle };

        if (name === "cpu") usage = use;
        else cores.push(use);
    }

    return { usage: usage, cores: cores, ticks: ticks };
}

/// /proc/meminfo → bytes
function meminfo(txt) {
    var out = { total: 0, available: 0, free: 0, cached: 0, buffers: 0,
                swapTotal: 0, swapFree: 0 };
    var lines = txt.split("\n");

    for (var i = 0; i < lines.length; i++) {
        var c = lines[i].indexOf(":");
        if (c < 0) continue;

        var kb = parseInt(lines[i].substring(c + 1), 10);
        if (!isFinite(kb)) continue;
        var b = kb * 1024;

        switch (lines[i].substring(0, c)) {
            case "MemTotal":     out.total = b; break;
            case "MemFree":      out.free = b; break;
            case "MemAvailable": out.available = b; break;
            case "Buffers":      out.buffers = b; break;
            case "Cached":       out.cached = b; break;
            case "SwapTotal":    out.swapTotal = b; break;
            case "SwapFree":     out.swapFree = b; return out;  // último que interessa
        }
    }
    return out;
}

/// /proc/loadavg
function loadavg(txt) {
    var f = txt.trim().split(/\s+/);
    var out = { l1: parseFloat(f[0]) || 0,
                l5: parseFloat(f[1]) || 0,
                l15: parseFloat(f[2]) || 0,
                running: 0, procs: 0 };
    if (f[3]) {
        var s = f[3].split("/");
        out.running = parseInt(s[0], 10) || 0;
        out.procs = parseInt(s[1], 10) || 0;
    }
    return out;
}

/// /proc/net/dev → { iface: {rx, tx} } em bytes acumulados.
/// Ignora loopback e interfaces virtuais de container, que só
/// inflariam o gráfico com tráfego que não sai da máquina.
function netdev(txt) {
    var out = {};
    var lines = txt.split("\n");

    for (var i = 2; i < lines.length; i++) {
        var colon = lines[i].indexOf(":");
        if (colon < 0) continue;

        var name = lines[i].substring(0, colon).trim();
        if (name === "lo") continue;
        if (name.indexOf("veth") === 0 || name.indexOf("docker") === 0
            || name.indexOf("br-") === 0 || name.indexOf("virbr") === 0) continue;

        var f = lines[i].substring(colon + 1).trim().split(/\s+/);
        out[name] = {
            rx: parseInt(f[0], 10) || 0,   // bytes recebidos
            tx: parseInt(f[8], 10) || 0    // bytes enviados
        };
    }
    return out;
}

/// Taxa em bytes/s entre duas amostras de netdev().
function netRate(now, prev, seconds) {
    var out = { rx: 0, tx: 0 };
    if (!prev || seconds <= 0) return out;

    for (var name in now) {
        if (!prev[name]) continue;
        var drx = now[name].rx - prev[name].rx;
        var dtx = now[name].tx - prev[name].tx;
        if (drx > 0) out.rx += drx / seconds;
        if (dtx > 0) out.tx += dtx / seconds;
    }
    return out;
}

/// Saída de `df -P -B1` → lista de sistemas de arquivos.
function df(txt) {
    var out = [];
    var lines = txt.split("\n");

    for (var i = 1; i < lines.length; i++) {
        var f = lines[i].trim().split(/\s+/);
        if (f.length < 6) continue;

        var size = parseInt(f[1], 10);
        var used = parseInt(f[2], 10);
        if (!isFinite(size) || size <= 0) continue;

        out.push({
            source: f[0],
            size: size,
            used: used,
            avail: parseInt(f[3], 10) || 0,
            mount: f.slice(5).join(" "),
            usage: clamp01(used / size)
        });
    }
    return out;
}

/// pp_dpm_sclk / pp_dpm_mclk → MHz da linha marcada com "*".
/// Reserva para placas cujo hwmon não expõe freq*_input.
function ppDpm(txt) {
    var lines = txt.split("\n");
    for (var i = 0; i < lines.length; i++) {
        if (lines[i].indexOf("*") < 0) continue;
        var m = lines[i].match(/(\d+)\s*Mhz/i);
        if (m) return parseInt(m[1], 10);
    }
    return 0;
}
