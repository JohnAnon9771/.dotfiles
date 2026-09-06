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

    // O df é o único spawn recorrente do torreão. Rodava 3x por minuto
    // — 180 vezes por hora para ver um número que muda em dia, não em
    // segundo. Agora é a cada 5 minutos (150 compassos), e quem abre o
    // painel recebe leitura fresca na hora, pelo refresh().
    //
    // Não há de onde tirar isto sem processo: o QStorageInfo não é
    // registrado no QML, o /proc/self/mountinfo sabe o que está montado
    // mas não o que está ocupado, e o UDisks2 só conta o tamanho do
    // bloco. Ocupação é chamada de sistema, não arquivo.
    Connections {
        target: Vigil
        function onBeat(n) { if (n % 150 === 0) root.refresh(); }
        function onWoke() {
            root.lastIo = null;
            root.lastIoAt = 0;
        }
    }

    /// Colhe a ocupação agora, se não houver uma em voo.
    function refresh() {
        if (!dfProc.running) dfProc.running = true;
    }

    // ═══ VAZÃO ═════════════════════════════════════════════════

    property var lastIo: null
    property real lastIoAt: 0

    ProcFile {
        id: stats
        path: "/proc/diskstats"

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

    /// Quantas superfícies estão olhando a vazão. Ver Attention.qml.
    property int watchers: 0
    readonly property bool detailed: watchers > 0

    // A muralha mostra o ESPAÇO LIVRE, que vem do df. A vazão de leitura
    // e escrita só aparece no cartão de detalhe — então o /proc/diskstats
    // só é lido enquanto o cartão existe. Eram 0,5 leituras por segundo
    // para alimentar duas linhas que ninguém estava lendo.
    Connections {
        target: Vigil
        function onBeat(n) { if (root.detailed) stats.reload(); }
        function onWoke() {
            root.lastIo = null;
            root.lastIoAt = 0;
        }
    }

    // Sem amostra anterior não há taxa: a primeira leitura ao abrir o
    // cartão só serve de marco zero, e a taxa aparece no compasso
    // seguinte. É o preço de não medir o que ninguém olha.
    onDetailedChanged: {
        if (!root.detailed) return;
        root.lastIo = null;
        root.lastIoAt = 0;
        stats.reload();
    }
}
