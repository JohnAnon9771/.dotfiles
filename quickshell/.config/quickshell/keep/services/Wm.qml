pragma Singleton

//  O SENESCAL — quem fala com o compositor.
//  O Hyprland 0.55 trocou o hyprlang por Lua, e com isso a sintaxe
//  dos dispatchers mudou: `workspace 3` virou
//  `hl.dsp.focus({ workspace = 3 })`.
//
//  O Quickshell expõe Hyprland.usingLua justamente para isto. Toda
//  a tradução mora aqui: se a sintaxe mudar de novo, muda um arquivo.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

Singleton {
    id: root

    readonly property bool lua: Hyprland.usingLua

    function send(request) { Hyprland.dispatch(request); }

    // ── Workspaces ─────────────────────────────────────────────

    function workspace(n) {
        send(lua ? "hl.dsp.focus({ workspace = " + n + " })"
                 : "workspace " + n);
    }

    /// `dir` = +1 próximo, -1 anterior.
    function workspaceStep(dir) {
        const rel = dir > 0 ? "e+1" : "e-1";
        send(lua ? "hl.dsp.focus({ workspace = \"" + rel + "\" })"
                 : "workspace " + rel);
    }

    function moveToWorkspace(n) {
        send(lua ? "hl.dsp.window.move({ workspace = " + n + " })"
                 : "movetoworkspace " + n);
    }

    function toggleSpecial(name) {
        send(lua ? "hl.dsp.workspace.toggle_special(\"" + name + "\")"
                 : "togglespecialworkspace " + name);
    }

    // ── Janelas ────────────────────────────────────────────────

    function focusWindow(address) {
        send(lua ? "hl.dsp.focus({ window = \"address:" + address + "\" })"
                 : "focuswindow address:" + address);
    }

    function closeActive() {
        send(lua ? "hl.dsp.window.close()" : "killactive");
    }

    function toggleFloating() {
        send(lua ? "hl.dsp.window.float({ action = \"toggle\" })"
                 : "togglefloating");
    }

    function fullscreen() {
        send(lua ? "hl.dsp.window.fullscreen()" : "fullscreen");
    }

    function exitSession() {
        send(lua ? "hl.dsp.exit()" : "exit");
    }
}
