pragma Singleton

//  AS ADEGAS — o que cabe e o que já foi gasto.
//  Ocupação vem do df (uma vez a cada 20 s, disco não enche
//  depressa); a vazão de leitura e escrita vem de /proc/diskstats,
//  que é arquivo e não custa processo.

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import "parsers.js" as P

Singleton {
    id: root

    property int usageIntervalMs: 20000
    property int ioIntervalMs: 2000

    /// [{ source, mount, size, used, avail, usage }]
    property var mounts: []

    property real readRate: 0      // bytes/s
    property real writeRate: 0

    /// A raiz é a que aparece na muralha. Se não houver "/" na
    /// lista — acontece dentro de container, onde a raiz é overlay
    /// e nós a filtramos — mostra a maior montagem em vez de zero.
    readonly property var rootFs: {
        const m = mounts;
        for (let i = 0; i < m.length; i++)
            if (m[i].mount === "/") return m[i];
        return m.length > 0 ? m[0] : null;
    }

    readonly property real rootUsage: rootFs ? rootFs.usage : 0
    readonly property real rootFree: rootFs ? rootFs.avail : 0

    // ═══ OCUPAÇÃO ══════════════════════════════════════════════

    Process {
        id: dfProc
        // -P: uma linha por sistema de arquivos, sem quebra.
        // -B1: bytes, sem arredondar para "1,4G" e perder precisão.
        command: ["df", "-P", "-B1",
                  "-x", "tmpfs", "-x", "devtmpfs", "-x", "squashfs",
                  "-x", "overlay", "-x", "efivarfs", "-x", "ramfs"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const list = P.df(text);
                // Ordena: raiz primeiro, depois por tamanho.
                list.sort((a, b) => a.mount === "/" ? -1
                                  : b.mount === "/" ? 1
                                  : b.size - a.size);
                root.mounts = list;
            }
        }
    }

    // Dorme com o castelo: é o único spawn recorrente do torreão,
    // e rodava 3x por minuto com a tela apagada. Ver Idle.awake.
    Timer {
        interval: root.usageIntervalMs
        running: Idle.awake
        repeat: true
        triggeredOnStart: true
        onTriggered: dfProc.running = true
    }

    // ═══ VAZÃO ═════════════════════════════════════════════════

    property var lastIo: null
    property real lastIoAt: 0

    FileView {
        id: stats
        path: "/proc/diskstats"
        printErrors: false

        onLoaded: {
            const now = P.diskstats(text());
            const t = Date.now() / 1000;

            if (root.lastIo && root.lastIoAt > 0) {
                const r = P.diskRate(now, root.lastIo, t - root.lastIoAt);
                root.readRate = r.read;
                root.writeRate = r.written;
            }

            root.lastIo = now;
            root.lastIoAt = t;
        }
    }

    // Dorme com o castelo. Ver Idle.awake.
    Timer {
        interval: root.ioIntervalMs
        running: Idle.awake
        repeat: true
        triggeredOnStart: true

        onRunningChanged: if (!running) {
            root.lastIo = null;
            root.lastIoAt = 0;
        }

        onTriggered: stats.reload()
    }
}
