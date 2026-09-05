pragma Singleton

//  SONDAGEM — onde ficam os sensores desta máquina.
//  Roda scripts/probe.sh UMA vez e guarda os caminhos. Todo o resto
//  do shell só lê arquivos: nenhum processo por ciclo de atualização.

import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root

    property bool ready: false
    property string error: ""
    property var info: ({ cores: 1, cpu: {}, gpus: [], net: {} })

    readonly property int cores: info.cores || 1
    readonly property string cpuModel: info.cpuModel || ""
    readonly property var cpu: info.cpu || ({})
    readonly property var gpus: info.gpus || []
    readonly property string netIface: (info.net && info.net.iface) || ""

    /// A placa que interessa. Numa máquina Ryzen há a iGPU do
    /// processador além da dedicada; o probe já ordena pela VRAM,
    /// mas o usuário pode fixar outra em Settings.
    readonly property var gpu: {
        if (gpus.length === 0) return null;

        const want = Settings.data.gpuCard;
        if (want && want.length > 0) {
            for (let i = 0; i < gpus.length; i++)
                if (gpus[i].dev.indexOf("/" + want + "/") >= 0) return gpus[i];
        }
        return gpus[0];
    }

    readonly property bool hasGpu: gpu !== null

    function rescan() {
        root.error = "";
        prober.running = true;
    }

    Process {
        id: prober

        command: ["sh", Quickshell.shellPath("scripts/probe.sh")]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length === 0) {
                    root.error = "a sondagem voltou vazia";
                    return;
                }
                try {
                    root.info = JSON.parse(text);
                    root.ready = true;
                    root.error = "";
                } catch (e) {
                    root.error = "sondagem ilegível: " + e;
                    console.warn("[keep] probe.sh devolveu JSON inválido:", e);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.warn("[keep] probe.sh:", text.trim());
            }
        }
    }
}
