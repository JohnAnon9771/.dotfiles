pragma Singleton

//  A FORJA — a placa de vídeo.
//  O maior buraco do setup antigo: a waybar não mostrava GPU nenhuma.
//
//  Tudo por sysfs, sem nvidia-smi, sem rocm-smi, sem pacote nenhum.
//  Os caminhos vêm do Probe, que já escolheu a placa certa — nesta
//  máquina há duas amdgpu (a iGPU do Ryzen e a dedicada) e o número
//  do hwmon não acompanha o número do card.

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services

Singleton {
    id: root

    property int intervalMs: 2000
    property int historyLength: 40

    readonly property var card: Probe.gpu
    readonly property bool present: card !== null
    readonly property var has: card ? card.has : ({})

    readonly property string name: card ? gpuName(card.pciId) : ""
    readonly property string driver: card ? card.driver : ""

    // ── Ocupação ───────────────────────────────────────────────
    property real usage: 0             // 0..1 — núcleo gráfico
    property real memBusy: 0           // 0..1 — controlador de memória
    property var history: []

    // ── VRAM (bytes) ───────────────────────────────────────────
    property real vramUsed: 0
    readonly property real vramTotal: card && card.vramTotal ? card.vramTotal : 0
    readonly property real vramUsage: vramTotal > 0 ? vramUsed / vramTotal : 0

    // ── Temperaturas (°C) ──────────────────────────────────────
    // A que importa numa Radeon é a junction, não a edge: é ela que
    // dispara o throttle. A waybar não mostrava nenhuma das três.
    property real tempEdge: 0
    property real tempJunction: 0
    property real tempMemory: 0

    readonly property real temp: tempJunction > 0 ? tempJunction : tempEdge

    readonly property real critEdge: card && card.critEdge ? card.critEdge / 1000 : 100
    readonly property real critJunction: card && card.critJunc ? card.critJunc / 1000 : 110
    readonly property real critMemory: card && card.critMem ? card.critMem / 1000 : 105

    // ── Energia ────────────────────────────────────────────────
    property real powerUw: 0                                    // microwatts
    readonly property real powerW: powerUw / 1e6
    readonly property real powerCapW:
        card && card.powerCap ? card.powerCap / 1e6 : 0
    readonly property real powerUsage:
        powerCapW > 0 ? Fmt.clamp01(powerW / powerCapW) : 0

    // ── Ventoinha ──────────────────────────────────────────────
    property int fanRpm: 0
    readonly property int fanMax: card && card.fanMax ? card.fanMax : 0
    readonly property real fanUsage: fanMax > 0 ? Fmt.clamp01(fanRpm / fanMax) : 0
    /// Placa moderna para a ventoinha em repouso. Silêncio não é defeito.
    readonly property bool fanIdle: has.fan === true && fanRpm === 0

    // ── Relógios (Hz) ──────────────────────────────────────────
    property real sclk: 0
    property real mclk: 0

    // ── Barramento ─────────────────────────────────────────────
    property string linkSpeed: ""
    property int linkWidth: 0
    readonly property string link:
        linkWidth > 0 && linkSpeed.length > 0
            ? linkSpeed.replace(" GT/s PCIe", " GT/s") + " ×" + linkWidth
            : ""

    // ── Pressão ────────────────────────────────────────────────
    readonly property real thermalPressure:
        temp > 0 ? Fmt.clamp01((temp - 60) / (critJunction - 60)) : 0

    readonly property real pressure:
        present ? Math.max(usage * 0.85, thermalPressure, powerUsage * 0.6) : 0

    readonly property bool feverish: temp > 0 && temp >= critJunction - 15

    // ═══ LEITURA ═══════════════════════════════════════════════

    readonly property string dev: card ? card.dev : ""
    readonly property string hw: card ? card.hwmon : ""

    function sysPath(base, leaf, enabled) {
        return (enabled === true && base.length > 0) ? base + "/" + leaf : "";
    }

    Timer {
        interval: root.intervalMs
        running: root.present
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            busy.reload();
            if (memBusyFile.path.length > 0) memBusyFile.reload();
            if (vram.path.length > 0) vram.reload();
            if (t1.path.length > 0) t1.reload();
            if (t2.path.length > 0) t2.reload();
            if (t3.path.length > 0) t3.reload();
            if (pwr.path.length > 0) pwr.reload();
            if (fan.path.length > 0) fan.reload();
            if (f1.path.length > 0) f1.reload();
            if (f2.path.length > 0) f2.reload();
            if (lspeed.path.length > 0) lspeed.reload();
            if (lwidth.path.length > 0) lwidth.reload();
        }
    }

    function num(txt) {
        const v = parseInt(txt, 10);
        return isFinite(v) ? v : 0;
    }

    FileView {
        id: busy
        path: root.sysPath(root.dev, "gpu_busy_percent", root.has.busy)
        printErrors: false
        onLoaded: {
            root.usage = Fmt.clamp01(root.num(text()) / 100);
            const h = root.history.slice();
            h.push(root.usage);
            while (h.length > root.historyLength) h.shift();
            root.history = h;
        }
    }

    FileView {
        id: memBusyFile
        path: root.sysPath(root.dev, "mem_busy_percent", root.has.memBusy)
        printErrors: false
        onLoaded: root.memBusy = Fmt.clamp01(root.num(text()) / 100)
    }

    FileView {
        id: vram
        path: root.sysPath(root.dev, "mem_info_vram_used", root.has.vram)
        printErrors: false
        onLoaded: root.vramUsed = root.num(text())
    }

    FileView {
        id: t1
        path: root.sysPath(root.hw, "temp1_input", root.has.tempEdge)
        printErrors: false
        onLoaded: root.tempEdge = root.num(text()) / 1000
    }

    FileView {
        id: t2
        path: root.sysPath(root.hw, "temp2_input", root.has.tempJunc)
        printErrors: false
        onLoaded: root.tempJunction = root.num(text()) / 1000
    }

    FileView {
        id: t3
        path: root.sysPath(root.hw, "temp3_input", root.has.tempMem)
        printErrors: false
        onLoaded: root.tempMemory = root.num(text()) / 1000
    }

    FileView {
        id: pwr
        // O probe já resolveu se é power1_average ou power1_input.
        path: (root.card && root.card.powerPath) ? root.card.powerPath : ""
        printErrors: false
        onLoaded: root.powerUw = root.num(text())
    }

    FileView {
        id: fan
        path: root.sysPath(root.hw, "fan1_input", root.has.fan)
        printErrors: false
        onLoaded: root.fanRpm = root.num(text())
    }

    FileView {
        id: f1
        path: root.sysPath(root.hw, "freq1_input", root.has.sclk)
        printErrors: false
        onLoaded: root.sclk = root.num(text())
    }

    FileView {
        id: f2
        path: root.sysPath(root.hw, "freq2_input", root.has.mclk)
        printErrors: false
        onLoaded: root.mclk = root.num(text())
    }

    FileView {
        id: lspeed
        path: root.sysPath(root.dev, "current_link_speed", root.has.link)
        printErrors: false
        onLoaded: root.linkSpeed = text().trim()
    }

    FileView {
        id: lwidth
        path: root.sysPath(root.dev, "current_link_width", root.has.link)
        printErrors: false
        onLoaded: root.linkWidth = root.num(text())
    }

    // ═══ NOMES ═════════════════════════════════════════════════
    // O sysfs não diz o nome comercial da placa. Uma tabelinha curta
    // cobre o que importa; o resto cai no ID PCI, que é honesto.

    readonly property var pciNames: ({
        "1002:7550": "Radeon RX 9060 XT",
        "1002:7551": "Radeon RX 9060",
        "1002:7590": "Radeon RX 9070 XT",
        "1002:7591": "Radeon RX 9070",
        "1002:744c": "Radeon RX 7900 XTX",
        "1002:747e": "Radeon RX 7800 XT",
        "1002:7480": "Radeon RX 7700 XT",
        "1002:73ff": "Radeon RX 6600",
        "1002:73df": "Radeon RX 6750 XT",
        "1002:164e": "Radeon Graphics (Raphael)",
        "1002:15bf": "Radeon 780M",
        "1002:1586": "Radeon 890M"
    })

    function gpuName(pciId) {
        if (!pciId) return "GPU";
        const key = String(pciId).toLowerCase();
        return pciNames[key] !== undefined ? pciNames[key] : ("GPU " + pciId);
    }

    /// Todas as placas, para o Grande Salão poder mostrar a iGPU também.
    readonly property var all: Probe.gpus
}
