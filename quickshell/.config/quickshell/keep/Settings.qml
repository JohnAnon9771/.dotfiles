pragma Singleton

//  Preferências do torreão, persistidas em
//  ~/.local/state/quickshell/by-shell/keep/settings.json
//
//  Os padrões vivem AQUI, não no arquivo — o repo de dotfiles não
//  carrega estado de runtime. O JSON só guarda o que você mudou.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property alias data: adapter

    FileView {
        path: Quickshell.statePath("settings.json")
        watchChanges: true
        printErrors: false          // primeira execução não tem arquivo

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            // Arquivo ainda não existe: grava os padrões.
            if (err === FileViewError.FileNotFound) writeAdapter();
        }

        JsonAdapter {
            id: adapter

            // ── Névoa (wallpaper) ──
            property string wallpaper: "~/Pictures/dark_medieval.jpg"
            property bool vignette: true
            property bool fog: false          // névoa à deriva: bonito, mas custa GPU

            // ── Atmosfera ──
            property bool weather: true       // as cores reagem à carga
            property bool easterEggs: true    // fantasmas, morcegos, hora das bruxas

            // ── Notificações ──
            property bool dnd: false
            property int scrollTimeoutMs: 6000
            property int cryptLimit: 120      // quantos pergaminhos a cripta guarda

            // ── Vigília (idle) ──
            property bool idleEnabled: true
            property int idleLockMinutes: 12
            property int idleDpmsMinutes: 20

            // ── Modo noturno ──
            property bool nightLight: false
            property real nightStrength: 0.28

            // ── Relógio ──
            property bool clock24h: true

            // ── Sensores: "" = detectar sozinho (o padrão correto) ──
            property string gpuCard: ""       // ex.: "card1"
            property string cpuHwmon: ""      // ex.: "k10temp"
            property string netInterface: ""  // ex.: "enp5s0"
        }
    }

    // Conveniências de escrita — evitam Settings.data.x = y espalhado.
    function toggleDnd()        { adapter.dnd = !adapter.dnd }
    function toggleNightLight() { adapter.nightLight = !adapter.nightLight }
    function toggleFog()        { adapter.fog = !adapter.fog }
}
