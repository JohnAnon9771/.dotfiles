//  OS TOQUES DE CORNETA — atalhos globais.
//
//  O compositor chama estes direto pelo protocolo de atalho global do
//  Hyprland. A alternativa seria `exec-once qs ipc call ...` em cada
//  bind, o que nasce um processo a cada tecla — uns 30 ms de espera
//  para abrir um lançador que deveria ser instantâneo.
//
//  Do lado do Hyprland:  hl.bind("SUPER + SPACE", hl.dsp.global("quickshell:grimoire"))

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services

Scope {
    id: root

    signal triggered(string what)

    GlobalShortcut {
        name: "grimoire"
        description: "Abrir o grimório"
        onPressed: root.triggered("grimoire")
    }

    GlobalShortcut {
        name: "hall"
        description: "Abrir o grande salão"
        onPressed: root.triggered("hall")
    }

    GlobalShortcut {
        name: "crypt"
        description: "Abrir a cripta"
        onPressed: root.triggered("crypt")
    }

    GlobalShortcut {
        name: "ossuary"
        description: "Abrir o ossuário"
        onPressed: root.triggered("ossuary")
    }

    GlobalShortcut {
        name: "lock"
        description: "Trancar o portão"
        onPressed: root.triggered("lock")
    }

    GlobalShortcut {
        name: "almanac"
        description: "Abrir o almanaque"
        onPressed: root.triggered("almanac")
    }

    // ── Som ────────────────────────────────────────────────────
    // Passam por aqui e não pelo wpctl para a Lápide aparecer.

    GlobalShortcut {
        name: "volumeUp"
        description: "Volume acima"
        onPressed: { Audio.volumeUp(); root.triggered("osd:volume"); }
    }

    GlobalShortcut {
        name: "volumeDown"
        description: "Volume abaixo"
        onPressed: { Audio.volumeDown(); root.triggered("osd:volume"); }
    }

    GlobalShortcut {
        name: "volumeMute"
        description: "Silenciar"
        onPressed: { Audio.toggleMute(); root.triggered("osd:volume"); }
    }

    GlobalShortcut {
        name: "micMute"
        description: "Silenciar o microfone"
        onPressed: { Audio.toggleMicMute(); root.triggered("osd:mic"); }
    }

    // ── Alternadores ───────────────────────────────────────────

    GlobalShortcut {
        name: "dnd"
        description: "Não perturbe"
        onPressed: { Notifs.toggleDnd(); root.triggered("osd:dnd"); }
    }

    GlobalShortcut {
        name: "inhibit"
        description: "Vigília eterna"
        onPressed: { Idle.toggleInhibit(); root.triggered("osd:inhibit"); }
    }

    GlobalShortcut {
        name: "nightLight"
        description: "Modo noturno"
        onPressed: Settings.toggleNightLight()
    }
}
