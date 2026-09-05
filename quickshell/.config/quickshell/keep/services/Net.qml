pragma Singleton

//  OS CORVOS — mensageiros do castelo.
//  O estado das redes vem do módulo nativo do Quickshell (NetworkManager
//  por DBus, sem chamar nmcli); as taxas vêm de /proc/net/dev, porque
//  o NM não as expõe.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs
import qs.services
import "parsers.js" as P

Singleton {
    id: root

    property int intervalMs: 2000
    property int historyLength: 40

    // ── Vazão ──────────────────────────────────────────────────
    property real rxRate: 0        // bytes/s
    property real txRate: 0
    property var rxHistory: []
    property var txHistory: []

    // ── Estado ─────────────────────────────────────────────────
    readonly property bool available: Networking.backend !== NetworkBackendType.None
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiBlocked: !Networking.wifiHardwareEnabled
    readonly property int connectivity: Networking.connectivity
    readonly property bool online: connectivity === NetworkConnectivity.Full

    readonly property var devices: Networking.devices.values

    readonly property var wifiDevice: {
        const d = devices;
        for (let i = 0; i < d.length; i++)
            if (d[i].type === DeviceType.Wifi) return d[i];
        return null;
    }

    readonly property var wiredDevice: {
        const d = devices;
        for (let i = 0; i < d.length; i++)
            if (d[i].type === DeviceType.Wired) return d[i];
        return null;
    }

    /// A rede a que estamos ligados agora, se houver.
    readonly property var activeNetwork: {
        const d = devices;
        for (let i = 0; i < d.length; i++) {
            if (!d[i].connected) continue;
            const nets = d[i].networks.values;
            for (let k = 0; k < nets.length; k++)
                if (nets[k].connected) return nets[k];
        }
        return null;
    }

    readonly property bool onWifi:
        activeNetwork !== null && activeNetwork.device
        && activeNetwork.device.type === DeviceType.Wifi

    readonly property string label:
        activeNetwork ? activeNetwork.name
      : wiredDevice && wiredDevice.connected ? "cabo"
      : "sem elo"

    /// 0..1 — força do sinal, ou 1 no cabo (fio não desvanece).
    readonly property real strength:
        onWifi && activeNetwork.signalStrength !== undefined
            ? activeNetwork.signalStrength
            : (activeNetwork ? 1 : 0)

    /// Redes visíveis, mais fortes primeiro, uma entrada por SSID.
    readonly property var visibleNetworks: {
        if (!wifiDevice) return [];

        const seen = ({});
        const out = [];
        const nets = wifiDevice.networks.values;

        for (let i = 0; i < nets.length; i++) {
            const n = nets[i];
            if (!n.name || n.name.length === 0) continue;      // rede oculta
            if (seen[n.name] !== undefined) continue;
            seen[n.name] = true;
            out.push(n);
        }

        out.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.known !== b.known) return a.known ? -1 : 1;
            return (b.signalStrength || 0) - (a.signalStrength || 0);
        });
        return out;
    }

    function setWifi(on)   { Networking.wifiEnabled = on; }
    function toggleWifi()  { Networking.wifiEnabled = !Networking.wifiEnabled; }

    function setScanning(on) {
        if (wifiDevice) wifiDevice.scannerEnabled = on;
    }

    // ═══ VAZÃO ═════════════════════════════════════════════════

    property var lastSample: null
    property real lastSampleAt: 0

    FileView {
        id: dev
        path: "/proc/net/dev"
        printErrors: false

        onLoaded: {
            const now = P.netdev(text());
            const t = Date.now() / 1000;

            if (root.lastSample && root.lastSampleAt > 0) {
                const r = P.netRate(now, root.lastSample, t - root.lastSampleAt);
                root.rxRate = r.rx;
                root.txRate = r.tx;
                root.push(r.rx, r.tx);
            }

            root.lastSample = now;
            root.lastSampleAt = t;
        }
    }

    // Dorme com o castelo. Ver Idle.awake.
    Timer {
        interval: root.intervalMs
        running: Idle.awake
        repeat: true
        triggeredOnStart: true

        onRunningChanged: if (!running) {
            root.lastSample = null;
            root.lastSampleAt = 0;
        }

        onTriggered: dev.reload()
    }

    /// O gráfico é normalizado pelo pico recente, não por um teto
    /// fixo: 100 Mb/s achataria tudo numa rede de 1 Gb/s.
    property real peak: 65536

    function push(rx, tx) {
        const top = Math.max(rx, tx);
        root.peak = Math.max(top, root.peak * 0.97, 65536);

        const a = root.rxHistory.slice();
        const b = root.txHistory.slice();
        a.push(Fmt.clamp01(rx / root.peak));
        b.push(Fmt.clamp01(tx / root.peak));
        while (a.length > root.historyLength) a.shift();
        while (b.length > root.historyLength) b.shift();
        root.rxHistory = a;
        root.txHistory = b;
    }
}
