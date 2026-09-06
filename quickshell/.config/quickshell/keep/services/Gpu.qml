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

    property int historyLength: 40

    readonly property var card: Probe.gpu
    readonly property bool present: card !== null
    readonly property var has: card ? card.has : ({})

    readonly property string name: {
        const pinned = Settings.data.gpuName;
        if (pinned && pinned.length > 0) return pinned;
        return card ? gpuName(card) : "";
    }
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

    /// Em degraus e com piso, como a da CPU — e aqui importa mais,
    /// porque gpu_busy_percent é a leitura mais ruidosa das duas.
    /// Ver Fmt.clima().
    readonly property real pressure:
        present
            ? Fmt.clima(Math.max(usage * 0.85, thermalPressure, powerUsage * 0.6))
            : 0

    readonly property bool feverish: temp > 0 && temp >= critJunction - 15

    // ═══ LEITURA ═══════════════════════════════════════════════

    readonly property string dev: card ? card.dev : ""
    readonly property string hw: card ? card.hwmon : ""

    function sysPath(base, leaf, enabled) {
        return (enabled === true && base.length > 0) ? base + "/" + leaf : "";
    }

    /// Quantas superfícies estão olhando o detalhe. Ver Attention.qml.
    property int watchers: 0
    readonly property bool detailed: watchers > 0

    // Esta era a casa mais cara do torreão: doze arquivos de /sys a
    // cada dois segundos, para a muralha desenhar UM número. O resto
    // alimentava um popup que passa o dia fechado.
    //
    // Agora são dois arquivos no compasso e mais três a cada seis
    // segundos; os outros seis só respiram enquanto alguém olha.
    Connections {
        target: Vigil

        function onBeat(n) {
            if (!root.present) return;

            // 2 s — `usage`, e é tudo que o GpuModule desenha.
            busy.reload();

            // 12 s — temperatura e potência da placa não entram na
            // muralha como NÚMERO em lugar nenhum: entram como COR,
            // alimentando `pressure`, que vira Theme.heat e sobe a
            // brasa pela ameia. Cor de ambiente que leva 1,4 s para
            // interpolar não precisa de amostra de dois segundos.
            //
            // (A do processador é outra história: o TempModule desenha
            // o número, e por isso o Sys lê a dele a cada 6 s.)
            if (n % 6 === 0) {
                if (t1.path.length > 0) t1.reload();
                if (t2.path.length > 0) t2.reload();
                if (pwr.path.length > 0) pwr.reload();
            }

            // lspeed e lwidth NÃO entram aqui: largura e velocidade do
            // link PCIe não mudam em uso normal, e o FileView já lê uma
            // vez quando o path é atribuído. Relê sozinho se o Probe
            // trocar de placa, que é a única hora em que faz diferença.
            //
            // Em amdgpu a leitura desses dois ainda pode tirar a placa
            // do estado de baixa energia — reamostrá-los a 0,5 Hz para
            // ver o mesmo número era o pior negócio do serviço.

            if (!root.detailed) return;

            // Daqui para baixo é o popup e a página do Salão.
            if (memBusyFile.path.length > 0) memBusyFile.reload();
            if (vram.path.length > 0) vram.reload();
            if (t3.path.length > 0) t3.reload();
            if (fan.path.length > 0) fan.reload();
            if (f1.path.length > 0) f1.reload();
            if (f2.path.length > 0) f2.reload();
        }
    }

    // Abrir o popup não pode mostrar número de dois minutos atrás: ao
    // ganhar o primeiro olhar, colhe tudo na hora.
    onDetailedChanged: {
        if (!root.detailed || !root.present) return;
        if (memBusyFile.path.length > 0) memBusyFile.reload();
        if (vram.path.length > 0) vram.reload();
        if (t3.path.length > 0) t3.reload();
        if (fan.path.length > 0) fan.reload();
        if (f1.path.length > 0) f1.reload();
        if (f2.path.length > 0) f2.reload();
    }

    function num(txt) {
        const v = parseInt(txt, 10);
        return isFinite(v) ? v : 0;
    }

    ProcFile {
        id: busy
        path: root.sysPath(root.dev, "gpu_busy_percent", root.has.busy)
        onLoaded: {
            root.usage = Fmt.clamp01(root.num(text()) / 100);
            const h = root.history.slice();
            h.push(root.usage);
            while (h.length > root.historyLength) h.shift();
            root.history = h;
        }
    }

    ProcFile {
        id: memBusyFile
        path: root.sysPath(root.dev, "mem_busy_percent", root.has.memBusy)
        onLoaded: root.memBusy = Fmt.clamp01(root.num(text()) / 100)
    }

    ProcFile {
        id: vram
        path: root.sysPath(root.dev, "mem_info_vram_used", root.has.vram)
        onLoaded: root.vramUsed = root.num(text())
    }

    ProcFile {
        id: t1
        path: root.sysPath(root.hw, "temp1_input", root.has.tempEdge)
        onLoaded: root.tempEdge = root.num(text()) / 1000
    }

    ProcFile {
        id: t2
        path: root.sysPath(root.hw, "temp2_input", root.has.tempJunc)
        onLoaded: root.tempJunction = root.num(text()) / 1000
    }

    ProcFile {
        id: t3
        path: root.sysPath(root.hw, "temp3_input", root.has.tempMem)
        onLoaded: root.tempMemory = root.num(text()) / 1000
    }

    ProcFile {
        id: pwr
        // O probe já resolveu se é power1_average ou power1_input.
        path: (root.card && root.card.powerPath) ? root.card.powerPath : ""
        onLoaded: root.powerUw = root.num(text())
    }

    ProcFile {
        id: fan
        path: root.sysPath(root.hw, "fan1_input", root.has.fan)
        onLoaded: root.fanRpm = root.num(text())
    }

    ProcFile {
        id: f1
        path: root.sysPath(root.hw, "freq1_input", root.has.sclk)
        onLoaded: root.sclk = root.num(text())
    }

    ProcFile {
        id: f2
        path: root.sysPath(root.hw, "freq2_input", root.has.mclk)
        onLoaded: root.mclk = root.num(text())
    }

    ProcFile {
        id: lspeed
        path: root.sysPath(root.dev, "current_link_speed", root.has.link)
        onLoaded: root.linkSpeed = text().trim()
    }

    ProcFile {
        id: lwidth
        path: root.sysPath(root.dev, "current_link_width", root.has.link)
        onLoaded: root.linkWidth = root.num(text())
    }

    // ═══ NOMES ═════════════════════════════════════════════════
    // O nome vem do pci.ids do sistema, resolvido pelo probe. Uma
    // tabela escrita a mão envelhece e erra: a primeira versão disto
    // chamava esta 9070 XT de 9060 XT.
    //
    // Quando a base só conhece a família — "Radeon RX 9070/9070 XT/
    // 9070 GRE", porque o subsistema desta placa ainda não entrou
    // nela — não há como adivinhar a variante, e chutar seria pior
    // que perguntar. Aí vale o que estiver em Settings.gpuName.

    function gpuName(card) {
        if (!card) return "GPU";
        if (card.name && card.name.length > 0) return card.name;
        return card.pciId ? "GPU " + card.pciId : "GPU";
    }

    /// Verdade quando a base do sistema só soube dizer a família.
    readonly property bool nameIsFamily:
        card !== null && card.name !== undefined && card.name.indexOf("/") >= 0

    /// Todas as placas, para o Grande Salão poder mostrar a iGPU também.
    readonly property var all: Probe.gpus
}
