pragma Singleton

//  OS FEITIÇOS — o que se pode invocar.
//  Índice de .desktop com busca difusa e memória de hábito: o que
//  você abre todo dia sobe sozinho. O wofi ordenava por nada.

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import "fuzzy.js" as F

Singleton {
    id: root

    /// O terminal em que apps de console abrem. O execute() do
    /// Quickshell ignora Terminal=true, então tratamos aqui.
    property string terminal: "kitty"

    readonly property var entries: DesktopEntries.applications.values

    /// id → { n: vezes usado, t: última vez (ms) }
    property alias uses: habit.uses

    // ═══ BUSCA ═════════════════════════════════════════════════

    /// Devolve [{ entry, score, positions }] ordenado do melhor
    /// para o pior. Consulta vazia lista por hábito.
    function search(query, limit) {
        const cap = limit || 40;
        const now = Date.now();
        const list = root.entries;
        const out = [];

        if (!query || query.length === 0) {
            for (let i = 0; i < list.length; i++) {
                out.push({
                    entry: list[i],
                    score: root.habitOf(list[i].id, now) * 100,
                    positions: []
                });
            }
            out.sort((a, b) => b.score - a.score
                            || a.entry.name.localeCompare(b.entry.name));
            return out.slice(0, cap);
        }

        for (let i = 0; i < list.length; i++) {
            const e = list[i];

            // O nome é o que a pessoa lembra; o resto ajuda, mas
            // não deve passar na frente.
            const fields = [[e.name, 1.0]];
            if (e.genericName && e.genericName.length > 0) fields.push([e.genericName, 0.55]);
            if (e.id && e.id.length > 0) fields.push([e.id, 0.45]);

            const kw = e.keywords;
            if (kw) for (let k = 0; k < kw.length; k++) fields.push([kw[k], 0.4]);

            let s = F.scoreFields(query, fields);
            if (s < 0) continue;

            s += root.habitOf(e.id, now) * 8;
            out.push({ entry: e, score: s, positions: F.positions(query, e.name) });
        }

        out.sort((a, b) => b.score - a.score);
        return out.slice(0, cap);
    }

    function habitOf(id, now) {
        const u = root.uses[id];
        return u ? F.frecency(u.n, u.t, now) : 0;
    }

    // ═══ INVOCAÇÃO ═════════════════════════════════════════════

    function launch(entry) {
        if (!entry) return;
        root.remember(entry.id);

        if (entry.runInTerminal) {
            // O execute() do Quickshell ignora Terminal=true.
            Quickshell.execDetached({
                command: [root.terminal, "-e"].concat(entry.command),
                workingDirectory: entry.workingDirectory
            });
        } else {
            entry.execute();
        }
    }

    function launchAction(entry, action) {
        if (!action) return;
        if (entry) root.remember(entry.id);
        action.execute();
    }

    /// Comando solto, do modo ">".
    function run(command, inTerminal) {
        if (!command || command.length === 0) return;
        Quickshell.execDetached(
            inTerminal ? [root.terminal, "-e", "sh", "-c", command]
                       : ["sh", "-c", command]
        );
    }

    // ═══ HÁBITO ════════════════════════════════════════════════

    function remember(id) {
        if (!id) return;
        const u = root.uses;
        const prev = u[id];
        // Reatribui o objeto inteiro: mutar em lugar não notifica.
        const next = Object.assign({}, u);
        next[id] = { n: (prev ? prev.n : 0) + 1, t: Date.now() };
        root.uses = next;
        saveSoon.restart();
    }

    function forget(id) {
        const next = Object.assign({}, root.uses);
        delete next[id];
        root.uses = next;
        saveSoon.restart();
    }

    /// Escrever a cada invocação castigaria o disco à toa.
    Timer {
        id: saveSoon
        interval: 4000
        onTriggered: habitFile.writeAdapter()
    }

    FileView {
        id: habitFile
        path: Quickshell.statePath("habit.json")
        printErrors: false

        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) writeAdapter();
        }

        JsonAdapter {
            id: habit
            property var uses: ({})
        }
    }
}
