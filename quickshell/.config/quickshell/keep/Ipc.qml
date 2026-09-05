//  O CORNETEIRO — o que o compositor pode pedir ao shell.
//
//  Os binds do Hyprland chamam isto em vez de nascer um processo:
//      qs -c keep ipc call keep grimoire
//
//  O Quickshell só registra a função se o tipo estiver anotado.

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services

Scope {
    id: root

    /// shell.qml escuta e decide o que abrir.
    signal requested(string what)

    IpcHandler {
        target: "keep"

        // ── Superfícies ────────────────────────────────────────
        function grimoire(): void { root.requested("grimoire"); }
        function hall(): void     { root.requested("hall"); }
        function crypt(): void    { root.requested("crypt"); }
        function ossuary(): void  { root.requested("ossuary"); }
        function almanac(): void  { root.requested("almanac"); }
        function lock(): void     { root.requested("lock"); }

        // ── Som ────────────────────────────────────────────────
        // Passam por aqui, e não direto pelo wpctl, para a Lápide
        // aparecer. Antes o volume mudava sem nenhum retorno visual.
        function volumeUp(): void   { Audio.volumeUp(); root.requested("osd:volume"); }
        function volumeDown(): void { Audio.volumeDown(); root.requested("osd:volume"); }
        function volumeMute(): void { Audio.toggleMute(); root.requested("osd:volume"); }
        function micMute(): void    { Audio.toggleMicMute(); root.requested("osd:mic"); }

        function volumeSet(pct: int): void {
            Audio.setVolume(pct / 100);
            root.requested("osd:volume");
        }

        // ── Alternadores ───────────────────────────────────────
        function dnd(): void        { Notifs.toggleDnd(); root.requested("osd:dnd"); }
        function nightLight(): void { Settings.toggleNightLight(); }
        function inhibit(): void    { Idle.toggleInhibit(); root.requested("osd:inhibit"); }
        function dismissAll(): void { Notifs.dismissAll(); }

        // ── Manutenção ─────────────────────────────────────────
        function reload(): void { Quickshell.reload(true); }
        function rescan(): void { Probe.rescan(); }

        // ── Consultas, para scripts ────────────────────────────
        function volume(): int  { return Math.round(Audio.volume * 100); }
        function muted(): bool  { return Audio.muted; }
        function unread(): int  { return Notifs.unread; }
    }
}
