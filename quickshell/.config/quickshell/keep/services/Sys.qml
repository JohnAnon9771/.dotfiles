pragma Singleton

//  A VIGÍLIA — o que a máquina está fazendo agora.
//  Tudo sai de /proc e /sys: nenhum processo auxiliar, nenhum parse
//  de saída de comando. O sensor de temperatura vem do Probe, então
//  não há hwmon chumbado que quebre no próximo boot.

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import "parsers.js" as P

Singleton {
    id: root

    /// Quantas amostras o traço da muralha guarda.
    property int historyLength: 40

    // ── CPU ────────────────────────────────────────────────────
    property real cpuUsage: 0          // 0..1, agregado
    property var coreUsage: []         // 0..1 por thread
    property real cpuTemp: 0           // °C
    property var cpuHistory: []

    // ── Memória (bytes) ────────────────────────────────────────
    property real memTotal: 0
    property real memAvailable: 0
    property real memCached: 0
    property real swapTotal: 0
    property real swapFree: 0

    readonly property real memUsed: Math.max(0, memTotal - memAvailable)
    readonly property real memUsage: memTotal > 0 ? memUsed / memTotal : 0
    readonly property real swapUsed: Math.max(0, swapTotal - swapFree)
    readonly property real swapUsage: swapTotal > 0 ? swapUsed / swapTotal : 0

    // ── Tempo e carga ──────────────────────────────────────────
    property real uptime: 0            // segundos
    property real load1: 0
    property real load5: 0
    property real load15: 0
    property int procRunning: 0
    property int procTotal: 0

    readonly property int cores: Probe.cores

    // ── Pressão ────────────────────────────────────────────────
    // O quanto o torreão está sob esforço, 0..1. É isto que faz as
    // tochas queimarem mais forte. Temperatura pesa mais que uso:
    // 100% de CPU a 50 °C é trabalho; 70% a 88 °C é aflição.
    readonly property real thermalPressure:
        cpuTemp > 0 ? Fmt.clamp01((cpuTemp - 55) / 35) : 0

    /// Em degraus e com piso: o ruído de leitura não pode virar
    /// animação. Ver Fmt.step() e Fmt.clima().
    readonly property real pressure:
        Fmt.clima(Math.max(cpuUsage * 0.85, thermalPressure, memUsage * 0.5))

    readonly property bool feverish: cpuTemp >= 85

    // ═══ LEITURA ═══════════════════════════════════════════════

    /// Quantas superfícies estão olhando o detalhe. Ver Attention.qml.
    property int watchers: 0
    readonly property bool detailed: watchers > 0

    // Um relógio só, com divisores. Ver services/Vigil.qml — inclusive
    // para o porquê de a cadência ser a alavanca, e não o modo de
    // leitura.
    Connections {
        target: Vigil

        function onBeat(n) {
            // 2 s. O traço da CPU na muralha se desenha com isto, e é
            // a única leitura desta casa que a barra mostra ao vivo.
            stat.reload();

            // 6 s. Memória não muda em degrau de dois segundos, e o
            // /proc/meminfo é o arquivo mais gordo do conjunto — são
            // ~55 linhas para colher cinco números.
            if (n % 3 === 0) mem.reload();

            // 6 s. Silício não esfria mais rápido que isso, e o §1.6
            // do spec já pedia 5 s para temperatura.
            if (n % 3 === 0 && temp.path.length > 0) temp.reload();

            // Daqui para baixo, só com alguém olhando: carga, processos
            // e uptime aparecem no popup do módulo, no Epitáfio e na
            // página do Salão — nunca na muralha.
            if (!root.detailed) return;
            load.reload();
            up.reload();
        }

        // A contagem de ticks fica velha enquanto o castelo dorme; o
        // primeiro delta depois de acordar seria a média dos 12
        // minutos parados. Zerar faz a primeira amostra ser um
        // recomeço limpo, e o triggeredOnStart da ronda repõe o valor.
        function onWoke() { root.lastTicks = null; }
    }

    // Abrir o popup não pode mostrar carga de dois minutos atrás.
    onDetailedChanged: {
        if (!root.detailed) return;
        load.reload();
        up.reload();
    }

    ProcFile {
        id: stat
        path: "/proc/stat"
        onLoaded: root.readStat(text())
    }

    ProcFile {
        id: mem
        path: "/proc/meminfo"
        onLoaded: root.readMeminfo(text())
    }

    ProcFile {
        id: up
        path: "/proc/uptime"
        onLoaded: {
            const v = parseFloat(text().split(" ")[0]);
            if (isFinite(v)) root.uptime = v;
        }
    }

    ProcFile {
        id: load
        path: "/proc/loadavg"
        onLoaded: root.readLoadavg(text())
    }

    ProcFile {
        id: temp
        // "" enquanto a sondagem não terminou; FileView trata como descarregado.
        path: Probe.cpu.temp || ""
        onLoaded: {
            const v = parseInt(text(), 10);
            if (isFinite(v)) root.cpuTemp = v / 1000;
        }
    }

    // ═══ INTERPRETAÇÃO ═════════════════════════════════════════
    // A lógica vive em parsers.js, pura e sem QML, para que
    // tools/test-parsers.qml possa exercitá-la contra o /proc real.

    /// Contadores acumulados da leitura anterior.
    property var lastTicks: null

    function readStat(txt) {
        const r = P.stat(txt, root.lastTicks);
        root.lastTicks = r.ticks;
        root.cpuUsage = r.usage;
        root.coreUsage = r.cores;
        root.pushHistory(r.usage);
    }

    function pushHistory(v) {
        const h = root.cpuHistory.slice();
        h.push(v);
        while (h.length > root.historyLength) h.shift();
        root.cpuHistory = h;
    }

    function readMeminfo(txt) {
        const m = P.meminfo(txt);
        root.memTotal = m.total;
        root.memAvailable = m.available;
        root.memCached = m.cached;
        root.swapTotal = m.swapTotal;
        root.swapFree = m.swapFree;
    }

    function readLoadavg(txt) {
        const l = P.loadavg(txt);
        root.load1 = l.l1;
        root.load5 = l.l5;
        root.load15 = l.l15;
        root.procRunning = l.running;
        root.procTotal = l.procs;
    }
}
