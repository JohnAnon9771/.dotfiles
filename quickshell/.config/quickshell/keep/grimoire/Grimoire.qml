pragma ComponentBehavior: Bound

//  ╔═══════════════════════════════════════════════════════════════╗
//  ║  O GRIMÓRIO — o livro de feitiços.                            ║
//  ║  Substitui o wofi. O prompt continua sendo "invoke spell..."   ║
//  ║                                                               ║
//  ║  Um sigilo no começo troca o modo:                            ║
//  ║    (nada) feitiços · > comandos · = aritmancia · / arquivos   ║
//  ║    : aparições · ; sigilos · ! castelo · ? ajuda              ║
//  ╚═══════════════════════════════════════════════════════════════╝

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.ui
import qs.services
import "spells.js" as Calc
import "sigils.js" as Sig
import "../services/fuzzy.js" as F

Scope {
    id: root

    property bool open: false

    /// O shell trata o que exige outra superfície (ossuário, lock).
    signal action(string what)

    function show()   { root.open = true; }
    function hide()   { root.open = false; }
    function toggle() { root.open = !root.open; }

    LazyLoader {
        activeAsync: root.open

        PanelWindow {
            id: win

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "keep-grimoire"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            anchors { left: true; right: true; top: true; bottom: true }

            // ═══ ESTADO ════════════════════════════════════════

            property string query: ""
            property int cursor: 0

            readonly property string sigil:
                query.length > 0 && ">=/:;!?".indexOf(query.charAt(0)) >= 0
                    ? query.charAt(0) : ""

            readonly property string term:
                sigil.length > 0 ? query.substring(1).trim() : query.trim()

            readonly property string modeName: ({
                "":  "feitiços",
                ">": "comandos",
                "=": "aritmancia",
                "/": "arquivos",
                ":": "aparições",
                ";": "sigilos",
                "!": "castelo",
                "?": "ajuda"
            })[sigil]

            // ═══ RESULTADOS ════════════════════════════════════

            // Vinculação, não atribuição: a varredura de .desktop é
            // assíncrona, e com um `results = build()` imperativo a
            // lista chegava depois e o livro ficava vazio para sempre.
            readonly property var results: win.build()

            onResultsChanged: win.cursor = 0

            function build() {
                const q = win.term;

                switch (win.sigil) {
                    case "?": return win.helpRows();
                    case "!": return win.castleRows(q);
                    case ";": return win.sigilRows(q);
                    case ":": return win.windowRows(q);
                    case "=": return win.calcRows(q);
                    case ">": return win.commandRows(q);
                    case "/": return win.fileRows();
                    default:  return win.appRows(q);
                }
            }

            // ── Feitiços: os aplicativos ───────────────────────
            function appRows(q) {
                const hits = Apps.search(q, 60);
                const out = [];

                // Uma conta digitada sem sigilo ainda deve responder.
                const sum = Calc.calc(q);
                if (sum.ok) {
                    out.push({
                        kind: "calc", title: sum.text, subtitle: q + "  ·  copia ao escolher",
                        glyph: Theme.glyph.fleuron, mono: true, value: sum.text
                    });
                }

                for (let i = 0; i < hits.length; i++) {
                    const e = hits[i].entry;
                    out.push({
                        kind: "app",
                        title: e.name,
                        subtitle: e.genericName || e.comment || "",
                        icon: e.icon ? Quickshell.iconPath(e.icon, true) : "",
                        entry: e
                    });
                }
                return out;
            }

            // ── Aritmancia ────────────────────────────────────
            function calcRows(q) {
                const sum = Calc.calc(q);
                if (!sum.ok) {
                    return [{ kind: "none", title: "…", mono: true,
                              subtitle: "a aritmancia não reconhece isso",
                              glyph: Theme.glyph.fleuron }];
                }
                return [{ kind: "calc", title: sum.text, mono: true,
                          subtitle: q + "  ·  copia ao escolher",
                          glyph: Theme.glyph.fleuron, value: sum.text }];
            }

            // ── Comandos ──────────────────────────────────────
            function commandRows(q) {
                if (q.length === 0) return [];
                return [
                    { kind: "run", title: q, mono: true,
                      subtitle: "executar", glyph: "$", cmd: q, term: false },
                    { kind: "run", title: q, mono: true,
                      subtitle: "executar no terminal", glyph: ">", cmd: q, term: true }
                ];
            }

            // ── Aparições: as janelas abertas ─────────────────
            function windowRows(q) {
                const tops = Hyprland.toplevels.values;
                const out = [];

                for (let i = 0; i < tops.length; i++) {
                    const t = tops[i];
                    const title = t.title || "(sem título)";
                    const where = t.workspace ? Theme.roman(t.workspace.id) : "";

                    let score = 0;
                    if (q.length > 0) {
                        score = F.scoreFields(q, [[title, 1.0], [where, 0.3]]);
                        if (score < 0) continue;
                    }

                    out.push({
                        kind: "window", title: title, mono: true,
                        subtitle: where.length > 0 ? "no salão " + where : "",
                        glyph: Theme.glyph.keep, address: t.address, score: score
                    });
                }

                // O que está em foco agora vem por último: você quase
                // nunca quer pular para a janela em que já está.
                out.sort((a, b) => b.score - a.score);
                return out;
            }

            // ── Sigilos ───────────────────────────────────────
            function sigilRows(q) {
                const out = [];
                const lower = q.toLowerCase();

                for (let i = 0; i < Sig.sigils.length; i++) {
                    const s = Sig.sigils[i];
                    if (q.length > 0
                        && s[1].indexOf(lower) < 0
                        && s[0] !== q) continue;

                    out.push({
                        kind: "sigil", title: s[0], mono: true,
                        subtitle: s[1] + "  ·  copia ao escolher",
                        glyph: "", value: s[0]
                    });
                    if (out.length >= 80) break;
                }
                return out;
            }

            // ── Castelo ───────────────────────────────────────
            function castleRows(q) {
                const all = [
                    { kind: "act", title: "Trancar o portão", act: "lock",
                      glyph: Theme.glyph.lock,   subtitle: "baixar a grade" },
                    { kind: "act", title: "Repousar", act: "sleep",
                      glyph: Theme.glyph.sleep,  subtitle: "suspender a máquina" },
                    { kind: "act", title: "Renascer", act: "ossuary",
                      glyph: Theme.glyph.reboot, subtitle: "reiniciar — pede confirmação" },
                    { kind: "act", title: "Descansar em paz", act: "ossuary",
                      glyph: Theme.glyph.power,  subtitle: "desligar — pede confirmação" },
                    { kind: "act", title: "Deixar o castelo", act: "ossuary",
                      glyph: Theme.glyph.logout, subtitle: "sair da sessão" },
                    { kind: "act", title: "Reerguer o torreão", act: "reload",
                      glyph: Theme.glyph.fleuron, subtitle: "recarregar o shell" }
                ];
                if (q.length === 0) return all;

                const out = [];
                for (let i = 0; i < all.length; i++)
                    if (all[i].title.toLowerCase().indexOf(q.toLowerCase()) >= 0) out.push(all[i]);
                return out;
            }

            // ── Ajuda ─────────────────────────────────────────
            function helpRows() {
                return [
                    { kind: "none", title: "sem sigilo", subtitle: "feitiços: os aplicativos", glyph: "" },
                    { kind: "none", title: ">", subtitle: "comandos: rodar algo do PATH", glyph: "", mono: true },
                    { kind: "none", title: "=", subtitle: "aritmancia: contas", glyph: "", mono: true },
                    { kind: "none", title: "/", subtitle: "arquivos: buscar sob a casa", glyph: "", mono: true },
                    { kind: "none", title: ":", subtitle: "aparições: pular para uma janela", glyph: "", mono: true },
                    { kind: "none", title: ";", subtitle: "sigilos: copiar um símbolo", glyph: "", mono: true },
                    { kind: "none", title: "!", subtitle: "castelo: trancar, dormir, desligar", glyph: "", mono: true }
                ];
            }

            // ── Arquivos ──────────────────────────────────────
            property var fileHits: []

            function fileRows() { return win.fileHits; }

            Process {
                id: finder
                stdout: StdioCollector {
                    onStreamFinished: {
                        const lines = text.split("\n");
                        const out = [];
                        for (let i = 0; i < lines.length && out.length < 60; i++) {
                            const p = lines[i].trim();
                            if (p.length === 0) continue;
                            const slash = p.lastIndexOf("/");
                            out.push({
                                kind: "file", mono: true,
                                title: slash >= 0 ? p.substring(slash + 1) : p,
                                subtitle: slash >= 0 ? p.substring(0, slash) : "",
                                glyph: Theme.glyph.disk, path: p
                            });
                        }
                        win.fileHits = out;
                    }
                }
            }

            Timer {
                id: seek
                interval: 220
                onTriggered: {
                    const q = win.term;
                    if (q.length < 2) { win.fileHits = []; return; }
                    const home = Quickshell.env("HOME") || ".";
                    // fd quando existir; senão o find, que está sempre lá.
                    finder.command = ["sh", "-c",
                        "command -v fd >/dev/null 2>&1 " +
                        "&& fd --hidden --exclude .git --max-results 60 -- " +
                        "'" + q.replace(/'/g, "") + "' " + home +
                        " || find " + home + " -maxdepth 6 -iname '*" +
                        q.replace(/'/g, "") + "*' -not -path '*/.git/*' 2>/dev/null | head -60"];
                    finder.running = true;
                }
            }

            onQueryChanged: if (win.sigil === "/") seek.restart()

            // ═══ INVOCAÇÃO ═════════════════════════════════════

            function invoke(r) {
                if (!r) return;

                switch (r.kind) {
                    case "app":    Apps.launch(r.entry); break;
                    case "run":    Apps.run(r.cmd, r.term); break;
                    case "window": Wm.focusWindow(r.address); break;
                    case "file":   Quickshell.execDetached(["xdg-open", r.path]); break;
                    case "calc":
                    case "sigil":  Quickshell.clipboardText = r.value; break;
                    case "act":
                        if (r.act === "reload") Quickshell.reload(true);
                        else root.action(r.act);
                        break;
                    default: return;    // ajuda não faz nada
                }
                root.hide();
            }

            // ═══ EASTER EGGS ═══════════════════════════════════

            readonly property string incantation: {
                if (!Settings.data.easterEggs) return "";
                const q = win.query.trim().toLowerCase();
                if (q === "xyzzy") return "Nada acontece.";
                if (q === "ave" || q === "necronomicon") return "keep";
                return "";
            }

            // ═══ O LIVRO ═══════════════════════════════════════

            // Clicar fora fecha.
            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.bgScrim
                opacity: 0.55
            }

            Panel {
                id: book

                anchors.centerIn: parent
                width: Theme.metric.grimoireWidth
                height: Theme.metric.grimoireHeight
                padding: 0

                // Engole o clique para não fechar ao usar o livro.
                MouseArea { anchors.fill: parent }

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.border.outer + Theme.border.inner
                    spacing: 0

                    // ── O prompt ───────────────────────────────
                    Item {
                        width: parent.width
                        height: 46

                        Rune {
                            id: modeLabel
                            anchors {
                                left: parent.left; leftMargin: Theme.pad.wide
                                verticalCenter: parent.verticalCenter
                            }
                            text: win.modeName
                            size: Theme.size.small
                            color: Theme.royal
                        }

                        TextInput {
                            id: input

                            anchors {
                                left: modeLabel.right; leftMargin: Theme.pad.roomy
                                right: counter.left; rightMargin: Theme.pad.roomy
                                verticalCenter: parent.verticalCenter
                            }

                            focus: true
                            font.family: Theme.font.mono
                            font.pixelSize: Theme.size.large
                            color: Theme.fgStrong
                            selectionColor: Theme.alpha(Theme.moss, 0.7)
                            selectedTextColor: Theme.ivory
                            clip: true

                            onTextChanged: win.query = text

                            cursorDelegate: Rectangle {
                                width: 2
                                color: Theme.accent
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    running: true
                                    NumberAnimation { to: 0.15; duration: 620; easing.type: Easing.InOutQuad }
                                    NumberAnimation { to: 1.0;  duration: 620; easing.type: Easing.InOutQuad }
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: input.text.length === 0
                                text: "invoke spell..."
                                font: input.font
                                color: Theme.fgDim
                                renderType: Text.NativeRendering
                            }

                            Keys.onEscapePressed: root.hide()
                            Keys.onUpPressed: win.move(-1)
                            Keys.onDownPressed: win.move(1)
                            Keys.onReturnPressed: e => {
                                if (e.modifiers & Qt.ShiftModifier
                                    && win.results[win.cursor]
                                    && win.results[win.cursor].kind === "run") {
                                    Apps.run(win.results[win.cursor].cmd, true);
                                    root.hide();
                                    return;
                                }
                                win.invoke(win.results[win.cursor]);
                            }
                            Keys.onEnterPressed: win.invoke(win.results[win.cursor])

                            Keys.onPressed: e => {
                                if (e.modifiers & Qt.ControlModifier) {
                                    if (e.key === Qt.Key_J) { win.move(1); e.accepted = true; }
                                    else if (e.key === Qt.Key_K) { win.move(-1); e.accepted = true; }
                                    else if (e.key === Qt.Key_N) { win.move(1); e.accepted = true; }
                                    else if (e.key === Qt.Key_P) { win.move(-1); e.accepted = true; }
                                }
                            }
                        }

                        Text {
                            id: counter
                            anchors {
                                right: parent.right; rightMargin: Theme.pad.wide
                                verticalCenter: parent.verticalCenter
                            }
                            text: win.results.length > 0
                                ? (win.cursor + 1) + "/" + win.results.length : ""
                            font.family: Theme.font.mono
                            font.pixelSize: Theme.size.tiny
                            color: Theme.fgDim
                            renderType: Text.NativeRendering
                        }

                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 1
                            color: Theme.alpha(Theme.gold, 0.45)
                        }
                    }

                    // ── As páginas ─────────────────────────────
                    Item {
                        width: parent.width
                        height: parent.height - 46 - 24

                        ListView {
                            id: list

                            anchors.fill: parent
                            anchors.topMargin: Theme.pad.tight
                            clip: true
                            model: win.results
                            currentIndex: win.cursor
                            highlightMoveDuration: Theme.anim.quick
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: SpellRow {
                                required property var modelData
                                required property int index

                                width: list.width
                                result: modelData
                                chosen: index === win.cursor
                                onInvoked: {
                                    win.cursor = index;
                                    win.invoke(modelData);
                                }
                            }
                        }

                        // Nada encontrado: o castelo fala.
                        Column {
                            anchors.centerIn: parent
                            visible: win.results.length === 0
                            spacing: Theme.pad.snug

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: win.incantation === "Nada acontece."
                                    ? "Nada acontece."
                                    : win.term.length === 0
                                        ? Lore.empty("apps")
                                        : Lore.empty(win.sigil === "/" ? "files"
                                                   : win.sigil === ":" ? "windows"
                                                                       : "grimoire")
                                font.family: Theme.font.quill
                                font.pixelSize: Theme.size.large
                                font.italic: true
                                color: Theme.fgDim
                                renderType: Text.NativeRendering
                            }
                        }

                        // O cartão de "sobre", para quem souber a palavra.
                        Column {
                            anchors.centerIn: parent
                            visible: win.incantation === "keep"
                            spacing: Theme.pad.base

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Torreão"
                                font.family: Theme.font.scribe
                                font.pixelSize: Theme.size.huge
                                color: Theme.accent
                            }
                            Rune {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "erguido sobre Quickshell"
                                size: Theme.size.small
                                color: Theme.fgDim
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Lore.anyLatin()
                                font.family: Theme.font.quill
                                font.italic: true
                                font.pixelSize: Theme.size.base
                                color: Theme.wraith
                            }
                        }
                    }

                    // ── O rodapé ───────────────────────────────
                    Item {
                        width: parent.width
                        height: 24

                        Rectangle {
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            height: 1
                            color: Theme.alpha(Theme.borderInner, 0.8)
                        }

                        Text {
                            anchors {
                                left: parent.left; leftMargin: Theme.pad.wide
                                verticalCenter: parent.verticalCenter
                            }
                            text: Theme.glyph.enter + " invocar   "
                                + Theme.glyph.updown + " escolher   "
                                + "? sigilos   esc fechar"
                            font.family: Theme.font.mono
                            font.pixelSize: Theme.size.tiny
                            color: Theme.fgDim
                            renderType: Text.NativeRendering
                        }
                    }
                }
            }

            function move(delta) {
                const n = win.results.length;
                if (n === 0) return;
                win.cursor = (win.cursor + delta + n) % n;
                list.positionViewAtIndex(win.cursor, ListView.Contain);
            }

            Component.onCompleted: input.forceActiveFocus()
        }
    }
}
