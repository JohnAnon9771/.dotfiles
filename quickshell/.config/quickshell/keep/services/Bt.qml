pragma Singleton

//  O ELO RÚNICO — bluetooth.
//  Módulo nativo do Quickshell falando BlueZ por DBus. Sem
//  bluetoothctl, sem parse de saída de terminal.

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null

    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property bool discovering: adapter ? adapter.discovering : false
    readonly property int state: adapter ? adapter.state : BluetoothAdapterState.Disabled
    readonly property bool blocked: state === BluetoothAdapterState.Blocked
    readonly property bool busy: state === BluetoothAdapterState.Enabling
                              || state === BluetoothAdapterState.Disabling

    readonly property var devices: adapter ? adapter.devices.values : []

    /// Ligados agora — é o que a muralha mostra.
    readonly property var connected: {
        const out = [];
        const d = devices;
        for (let i = 0; i < d.length; i++)
            if (d[i].connected) out.push(d[i]);
        return out;
    }

    readonly property bool anyConnected: connected.length > 0

    /// Conhecidos primeiro, depois os avistados na varredura.
    readonly property var sorted: {
        const out = devices.slice();
        out.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.paired !== b.paired) return a.paired ? -1 : 1;
            return label(a).localeCompare(label(b));
        });
        return out;
    }

    function label(d) {
        if (!d) return "—";
        if (d.name && d.name.length > 0) return d.name;
        if (d.deviceName && d.deviceName.length > 0) return d.deviceName;
        return d.address || "—";
    }

    /// Estado em uma palavra, para a lista.
    function status(d) {
        if (!d) return "";
        if (d.pairing) return "forjando elo…";
        if (d.connected) return "ligado";
        if (d.paired) return "conhecido";
        return "avistado";
    }

    function setEnabled(on) { if (adapter) adapter.enabled = on; }
    function toggle()       { if (adapter) adapter.enabled = !adapter.enabled; }

    function scan(on) {
        if (!adapter || !adapter.enabled) return;
        adapter.discovering = on;
    }

    function toggleScan() {
        if (adapter && adapter.enabled) adapter.discovering = !adapter.discovering;
    }

    /// Um clique faz a coisa certa: parear se não conhece, ligar se
    /// conhece, desligar se já está ligado.
    function engage(d) {
        if (!d) return;
        if (d.connected) d.disconnect();
        else if (d.paired) d.connect();
        else d.pair();
    }

    function forget(d) { if (d) d.forget(); }

    /// Alguns periféricos reportam bateria; a maioria não.
    function battery(d) {
        return d && d.batteryAvailable ? d.battery : -1;
    }
}
