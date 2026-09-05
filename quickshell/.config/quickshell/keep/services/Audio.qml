pragma Singleton

//  O ÓRGÃO — os tubos do salão.
//  Hoje não existe interface de áudio nenhuma: o volume só se muda
//  por F11/F12 chamando wpctl, sem retorno visual.
//
//  Nó do Pipewire só entrega volume e mudo depois de "bound": sem o
//  PwObjectTracker abaixo, tudo aqui leria lixo.

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

Singleton {
    id: root

    property real step: 0.05
    /// Sem passar de 100%. Amplificar além disso distorce e é o
    /// que o bind antigo já evitava com `wpctl -l 1`.
    property real maxVolume: 1.0

    readonly property bool ready: Pipewire.ready

    // ── Saída e entrada padrão ─────────────────────────────────
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : true

    readonly property real micVolume: source && source.audio ? source.audio.volume : 0
    readonly property bool micMuted: source && source.audio ? source.audio.muted : true

    readonly property string sinkName: nodeLabel(sink)
    readonly property string sourceName: nodeLabel(source)

    // ── Classificação dos nós ──────────────────────────────────
    // Um stream de reprodução carrega a flag Sink (ele *recebe* o
    // áudio do aplicativo), então filtrar só por isSink juntaria
    // aplicativos com placas de som. É preciso olhar Stream também.

    function isAudio(n)  { return n && (n.type & PwNodeType.Audio) !== 0; }
    function isStream(n) { return n && (n.type & PwNodeType.Stream) !== 0; }
    function isSink(n)   { return n && (n.type & PwNodeType.Sink) !== 0; }

    readonly property var nodes: Pipewire.nodes.values

    /// Placas e saídas de verdade.
    readonly property var sinks: {
        const out = [];
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i];
            if (isAudio(n) && isSink(n) && !isStream(n)) out.push(n);
        }
        return out;
    }

    /// Microfones e entradas.
    readonly property var sources: {
        const out = [];
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i];
            if (isAudio(n) && !isSink(n) && !isStream(n)) out.push(n);
        }
        return out;
    }

    /// Aplicativos tocando agora — o volume por app.
    readonly property var streams: {
        const out = [];
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i];
            if (isAudio(n) && isStream(n) && isSink(n)) out.push(n);
        }
        return out;
    }

    /// Aplicativos gravando agora. Vale saber quem está ouvindo.
    readonly property var captures: {
        const out = [];
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i];
            if (isAudio(n) && isStream(n) && !isSink(n)) out.push(n);
        }
        return out;
    }

    // Sem isto, `volume`, `muted` e `properties` devolvem lixo.
    PwObjectTracker {
        objects: [root.sink, root.source]
            .concat(root.sinks)
            .concat(root.sources)
            .concat(root.streams)
            .concat(root.captures)
    }

    // ═══ NOMES ═════════════════════════════════════════════════

    /// O nome que uma pessoa reconhece, não o identificador do nó.
    function nodeLabel(n) {
        if (!n) return "—";
        if (n.nickname && n.nickname.length > 0) return n.nickname;
        if (n.description && n.description.length > 0) return n.description;
        return n.name || "—";
    }

    /// Para streams: o aplicativo, não o nome do fluxo.
    function streamLabel(n) {
        if (!n) return "—";
        const p = n.properties;
        if (p) {
            if (p["application.name"]) return p["application.name"];
            if (p["media.name"]) return p["media.name"];
        }
        return nodeLabel(n);
    }

    function streamIcon(n) {
        if (!n || !n.properties) return "";
        const p = n.properties;
        return p["application.icon-name"] || p["application.process.binary"] || "";
    }

    // ═══ CONTROLE ══════════════════════════════════════════════

    function setVolume(v) {
        if (!sink || !sink.audio) return;
        sink.audio.volume = Math.max(0, Math.min(root.maxVolume, v));
    }

    function nudge(delta) {
        if (!sink || !sink.audio) return;
        // Desliga o mudo ao subir o volume: é o que a pessoa quis dizer.
        if (delta > 0 && sink.audio.muted) sink.audio.muted = false;
        setVolume(sink.audio.volume + delta);
    }

    function volumeUp()   { nudge(root.step); }
    function volumeDown() { nudge(-root.step); }

    function toggleMute() {
        if (sink && sink.audio) sink.audio.muted = !sink.audio.muted;
    }

    function toggleMicMute() {
        if (source && source.audio) source.audio.muted = !source.audio.muted;
    }

    function setMicVolume(v) {
        if (!source || !source.audio) return;
        source.audio.volume = Math.max(0, Math.min(1, v));
    }

    function makeDefaultSink(node)   { Pipewire.preferredDefaultAudioSink = node; }
    function makeDefaultSource(node) { Pipewire.preferredDefaultAudioSource = node; }

    function setNodeVolume(node, v) {
        if (node && node.audio) node.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleNodeMute(node) {
        if (node && node.audio) node.audio.muted = !node.audio.muted;
    }

    /// Glifo do volume, para a muralha e a lápide.
    function glyph(v, isMuted) {
        if (isMuted) return Theme.glyph.volMute;
        if (v < 0.34) return Theme.glyph.volLow;
        if (v < 0.67) return Theme.glyph.volMid;
        return Theme.glyph.volHigh;
    }
}
