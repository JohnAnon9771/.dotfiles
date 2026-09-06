pragma Singleton

//  A VIGÍLIA ETERNA — ociosidade da sessão.
//  A máquina nunca trancava: não havia lock nem hypridle. Isto usa
//  o ext-idle-notify do compositor direto, sem daemon extra.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

Singleton {
    id: root

    /// Ligado pelo usuário nos Sigilos — impede o castelo de dormir.
    property bool inhibited: false

    /// A janela a que o inibidor se prende. O shell.qml aponta para
    /// a muralha; sem janela o protocolo não aceita o inibidor.
    property var anchorWindow: null

    readonly property bool enabled: Settings.data.idleEnabled
    readonly property int lockAfter: Settings.data.idleLockMinutes * 60
    readonly property int dpmsAfter: Settings.data.idleDpmsMinutes * 60

    signal shouldLock()
    signal shouldSleep()
    signal awoke()

    IdleInhibitor {
        window: root.anchorWindow
        enabled: root.inhibited && root.anchorWindow !== null
    }

    IdleMonitor {
        id: lockWatch
        enabled: root.enabled && !root.inhibited
        timeout: root.lockAfter
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle) root.shouldLock();
            else root.awoke();
        }
    }

    IdleMonitor {
        id: sleepWatch
        // Apagar a tela só faz sentido depois de trancar.
        enabled: root.enabled && !root.inhibited && root.dpmsAfter > root.lockAfter
        timeout: root.dpmsAfter
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.shouldSleep()
    }

    readonly property bool idle: lockWatch.isIdle

    /// Vale a pena medir a máquina agora?
    ///
    /// Os serviços de telemetria (Sys, Gpu, Net, Disks) penduram o
    /// `running:` dos seus Timers aqui. Enquanto o castelo dorme não
    /// há quem leia um número: o Portão não mostra telemetria, e a
    /// tela está apagada. Eram ~9,5 leituras de arquivo por segundo e
    /// um `df` a cada 20 s rodando para ninguém.
    ///
    /// Com a vigília desligada nos Sigilos, `idle` nunca vira true —
    /// então isto fica preso em `true` e nada muda, que é o correto.
    readonly property bool awake: !root.idle

    function toggleInhibit() { root.inhibited = !root.inhibited; }
}
