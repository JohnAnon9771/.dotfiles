pragma Singleton

//  ╔═══════════════════════════════════════════════════════════════╗
//  ║  A RONDA                                                      ║
//  ║  Um relógio só, e o interruptor que o desliga.                 ║
//  ╚═══════════════════════════════════════════════════════════════╝
//
//  O QUE ISTO CONSERTA
//
//  O torreão parado gastava 0,58% de um core e ~70 wakeups/s. Medindo
//  thread a thread, 0,45% e ~66 wakeups estavam nas doze threads do
//  QThreadPool — o pool por onde todo FileView assíncrono passa.
//  Dezenove arquivos de /proc e /sys, relidos a cada dois segundos.
//
//  Afrouxar só o intervalo para 60 s levou a 0,03% e 3,7 wakeups/s. O
//  custo é por LEITURA, não por timer: cada reload() é um despacho para
//  o pool e uma volta pelo event loop, e sai por umas sete trocas de
//  contexto. (O `blockAllReads` não resolve — ver services/ProcFile.qml.)
//
//  Então há duas alavancas, e esta ronda serve as duas:
//
//    · CADÊNCIA — cada arquivo lê no ritmo que o dado tem, não no
//      ritmo do mais apressado. Um timer só, com divisores, em vez de
//      quatro cronômetros em fase incerta.
//    · CONTAGEM — o que só o popup mostra só é lido enquanto o popup
//      existe. Ver `Gpu.watchers`.
//
//  A base é 2 s e não 1 s de propósito: o §1.6 propõe 1 s supondo
//  timers desencontrados (2, 3, 5, 30, 60), e aqui eles já batem no
//  mesmo 2 s. Um relógio de 1 s DOBRARIA os despertares para arrumar um
//  desencontro que não existe.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services

Singleton {
    id: root

    // ═══ O INTERRUPTOR ═════════════════════════════════════════
    // Empurrados de fora pelo shell.qml, para não inverter camadas:
    // o Idle é dono do protocolo Wayland e não pode passar a conhecer
    // o Portão nem o Hyprland sem fechar um ciclo no grafo.

    /// A grade está baixada? (gate/Portcullis.qml)
    property bool locked: false

    /// A tela está apagada? O Hyprland não conta o DPMS por IPC, então
    /// quem sabe é quem mandou apagar — o shell.qml, no mesmo lugar em
    /// que chama Wm.dpms().
    property bool screenOff: false

    /// A muralha existe e está visível?
    property bool barVisible: true

    /// Há janela em tela cheia por cima da muralha? Isto o Hyprland
    /// responde sozinho, por evento — sem poll, sem rawEvent.
    readonly property bool fullscreen:
        Hyprland.focusedWorkspace !== null
        && Hyprland.focusedWorkspace.hasFullscreen

    /// Vale a pena o castelo medir alguma coisa agora?
    ///
    /// O `Idle.awake` sozinho só sabia de tempo sem input — e o tempo
    /// é de doze minutos. Trancar com Super+L não parava nada: a
    /// telemetria seguia lendo /proc para uma tela preta.
    readonly property bool active:
           barVisible
        && !locked
        && !screenOff
        && !(fullscreen && Settings.data.hideOnFullscreen)
        && Idle.awake

    // ═══ O SINO DA RONDA ═══════════════════════════════════════

    /// Base do compasso, em ms. Todo divisor abaixo conta daqui.
    readonly property int compasso: 2000

    /// Toca a cada compasso. `n` cresce sem parar; quem escuta usa o
    /// resto da divisão para escolher o próprio ritmo.
    ///
    ///     function onBeat(n) { if (n % 2 === 0) reler(); }   // 4 s
    signal beat(int n)

    /// Disparado quando a ronda acorda. Contador acumulado (ticks de
    /// CPU, bytes de rede) fica velho enquanto o castelo dorme: o
    /// primeiro delta depois de acordar seria a média do sono inteiro.
    /// Quem guarda amostra anterior zera aqui.
    signal woke()

    property int tick: 0

    Timer {
        interval: root.compasso
        repeat: true
        running: root.active
        triggeredOnStart: true

        onRunningChanged: if (running) root.woke()
        onTriggered: {
            root.tick++;
            root.beat(root.tick);
        }
    }
}
