pragma Singleton

//  PERGAMINHOS — as notificações.
//  Antes: nada. Nenhum daemon instalado, nenhuma notificação jamais
//  aparecia. O Quickshell fala o protocolo direto.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs
import "fuzzy.js" as F

Singleton {
    id: root

    /// Pergaminhos abertos na tela agora.
    property var popups: []

    /// A cripta: o registro do que já passou, entre reinícios.
    property alias history: crypt.log
    property alias lastSeen: crypt.lastSeen

    readonly property bool dnd: Settings.data.dnd
    readonly property bool silent: dnd

    readonly property int unread: {
        const h = root.history;
        let n = 0;
        for (let i = 0; i < h.length; i++)
            if (h[i].at > root.lastSeen) n++;
        return n;
    }

    readonly property bool anyCritical: {
        const p = root.popups;
        for (let i = 0; i < p.length; i++)
            if (p[i].urgency === NotificationUrgency.Critical) return true;
        return false;
    }

    // ═══ SERVIDOR ══════════════════════════════════════════════
    // Todos os "supported" nascem em false. Sem ligá-los, os
    // aplicativos deixam de mandar ações, ícones e resposta inline.

    NotificationServer {
        id: server

        keepOnReload: true

        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true
        inlineReplySupported: true
        persistenceSupported: true      // temos cripta, então é verdade

        onNotification: n => root.receive(n)
    }

    // ═══ CHEGADA ═══════════════════════════════════════════════

    function receive(n) {
        // Sem isto o Quickshell descarta a notificação na hora.
        n.tracked = true;

        root.archive(n);

        // O crítico atravessa o silêncio. É para isso que ele existe.
        const critical = n.urgency === NotificationUrgency.Critical;
        if (root.dnd && !critical) return;

        n.closed.connect(() => root.drop(n));
        root.popups = root.popups.concat([n]);
    }

    function drop(n) {
        const out = [];
        for (let i = 0; i < root.popups.length; i++)
            if (root.popups[i] !== n) out.push(root.popups[i]);
        root.popups = out;
    }

    /// Quanto tempo o pergaminho fica aberto. O aplicativo pode
    /// pedir um tempo; crítico não expira sozinho, por definição.
    function lifetime(n) {
        if (!n) return Settings.data.scrollTimeoutMs;
        if (n.urgency === NotificationUrgency.Critical) return 0;
        if (n.expireTimeout > 0) return n.expireTimeout * 1000;
        return Settings.data.scrollTimeoutMs;
    }

    // ═══ CRIPTA ════════════════════════════════════════════════

    function archive(n) {
        const entry = {
            at: Date.now(),
            appName: n.appName || "",
            appIcon: n.appIcon || "",
            summary: n.summary || "",
            body: n.body || "",
            image: n.image || "",
            urgency: n.urgency,
            desktopEntry: n.desktopEntry || ""
        };

        const log = root.history.slice();
        log.unshift(entry);
        while (log.length > Settings.data.cryptLimit) log.pop();
        root.history = log;

        saveSoon.restart();
    }

    function markSeen() {
        root.lastSeen = Date.now();
        saveSoon.restart();
    }

    function clearHistory() {
        root.history = [];
        root.lastSeen = Date.now();
        cryptFile.writeAdapter();
    }

    /// Busca na cripta, para o Grande Salão.
    function searchHistory(query) {
        if (!query || query.length === 0) return root.history;

        const out = [];
        const log = root.history;
        for (let i = 0; i < log.length; i++) {
            const s = F.scoreFields(query, [
                [log[i].summary, 1.0],
                [log[i].appName, 0.6],
                [log[i].body, 0.4]
            ]);
            if (s >= 0) out.push(log[i]);
        }
        return out;
    }

    // ═══ AÇÕES ═════════════════════════════════════════════════

    function dismiss(n)  { if (n) n.dismiss(); }
    function expire(n)   { if (n) n.expire(); }

    function dismissAll() {
        const p = root.popups.slice();
        for (let i = 0; i < p.length; i++) p[i].dismiss();
        root.popups = [];
    }

    function invoke(action) { if (action) action.invoke(); }

    function reply(n, text) {
        if (n && n.hasInlineReply && text.length > 0) n.sendInlineReply(text);
    }

    function toggleDnd() {
        Settings.toggleDnd();
        // Sair do silêncio não faz chover o que ficou represado:
        // o que passou está na cripta e é lá que se lê.
    }

    // ═══ PERSISTÊNCIA ══════════════════════════════════════════

    Timer {
        id: saveSoon
        interval: 3000
        onTriggered: cryptFile.writeAdapter()
    }

    FileView {
        id: cryptFile
        path: Quickshell.statePath("crypt.json")
        printErrors: false

        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) writeAdapter();
        }

        JsonAdapter {
            id: crypt
            property var log: []
            property real lastSeen: 0
        }
    }
}
