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

    /// O papel de parede como URL absoluta, com o "~" resolvido.
    /// Um lugar só, de propósito: a Névoa e o Portão precisam da MESMA
    /// string. URLs diferentes para o mesmo arquivo são duas chaves no
    /// cache de pixmap do Qt, e a imagem é decodificada duas vezes.
    readonly property string wallpaperUrl: {
        const p = root.data.wallpaper;
        if (!p || p.length === 0) return "";
        if (p.charAt(0) !== "~") return "file://" + p;
        const home = Quickshell.env("HOME");
        return home ? "file://" + home + p.substring(1) : "";
    }

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
            /// O protocolo diz que crítico não expira sozinho. Aqui
            /// expira, mas devagar: pergaminho que nunca sai da tela é
            /// pergaminho que nunca sai da memória, e a cripta guarda o
            /// registro de qualquer jeito.
            property int criticalTimeoutMs: 300000
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
            /// O pci.ids nem sempre distingue a variante ("RX 9070/
            /// 9070 XT/9070 GRE"). Escreva aqui o nome exato da placa.
            property string gpuName: ""
            property string cpuHwmon: ""      // ex.: "k10temp"
            property string netInterface: ""  // ex.: "enp5s0"
        }
    }

    // Conveniências de escrita — evitam Settings.data.x = y espalhado.
    function toggleDnd()        { root.data.dnd = !root.data.dnd; }
    function toggleNightLight() { root.data.nightLight = !root.data.nightLight; }
    function toggleFog()        { root.data.fog = !root.data.fog; }
}
