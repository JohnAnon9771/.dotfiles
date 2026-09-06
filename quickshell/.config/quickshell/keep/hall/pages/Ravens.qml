pragma ComponentBehavior: Bound

//  OS CORVOS — rede.
//  Módulo nativo do Quickshell falando com o NetworkManager por DBus.
//
//  Detalhe do protocolo: WifiNetwork.signalStrength vai de 0,0 a 1,0
//  (não 0-100), e o caminho certo para conectar é chamar connect()
//  primeiro; se ele falhar com NoSecrets, aí sim pedir a senha.

import QtQuick
import Quickshell.Networking
import qs
import qs.ui
import qs.hall
import qs.services

Column {
    id: root

    spacing: Theme.pad.wide

    property var pending: null
    property string trouble: ""

    function engage(net) {
        root.trouble = "";
        if (net.connected) { net.disconnect(); return; }
        root.pending = null;
        net.connect();
    }

    Section {
        title: "Corvos"

        Toggle {
            width: parent.width
            label: "asas abertas"
            detail: Net.wifiBlocked ? "travado no hardware" : ""
            on: Net.wifiEnabled
            enabled: !Net.wifiBlocked
            onFlipped: Net.toggleWifi()
        }

        Fact {
            label: "elo"
            value: Net.label
            tint: Net.online ? Theme.moss : Theme.ember
        }
        Fact {
            visible: Net.onWifi
            label: "sinal"
            value: Fmt.pct(Net.strength)
        }
        Fact { label: "descendo"; value: Fmt.rate(Net.rxRate); tint: Theme.moat }
        Fact { label: "subindo";  value: Fmt.rate(Net.txRate); tint: Theme.gold }
        Fact {
            visible: Probe.netIface.length > 0
            label: "via"
            value: Probe.netIface
            tint: Theme.fgDim
        }
    }

    Section {
        title: "Torres"
        visible: Net.wifiEnabled && Net.wifiDevice !== null

        Repeater {
            model: Net.visibleNetworks

            Column {
                id: perch

                required property var modelData

                width: parent.width
                spacing: 0

                Choice {
                    width: parent.width
                    text: perch.modelData.name
                    chosen: perch.modelData.connected
                    busy: perch.modelData.stateChanging
                    glyph: {
                        const bars = Theme.glyph.wifi;
                        const s = perch.modelData.signalStrength || 0;
                        return bars[Math.min(bars.length - 1, Math.floor(s * bars.length))];
                    }
                    detail: {
                        const bits = [];
                        if (perch.modelData.known) bits.push("conhecida");
                        if (perch.modelData.security !== WifiSecurityType.Open) bits.push("selada");
                        return bits.join(" · ");
                    }
                    tint: Theme.wraith
                    onPicked: {
                        if (perch.modelData.connected) { perch.modelData.disconnect(); return; }
                        root.pending = null;
                        root.trouble = "";
                        perch.modelData.connect();
                    }
                }

                // A senha só aparece quando o compositor de fato pediu.
                Item {
                    width: parent.width
                    height: visible ? key.implicitHeight + Theme.pad.base : 0
                    visible: root.pending === perch.modelData

                    RuneField {
                        id: key

                        anchors {
                            left: parent.left; right: parent.right
                            leftMargin: Theme.pad.wide
                            top: parent.top; topMargin: Theme.pad.tight
                        }
                        echoMode: TextInput.Password
                        placeholder: "a palavra desta torre"
                        accent: Theme.wraith

                        onAccepted: {
                            perch.modelData.connectWithPsk(text);
                            text = "";
                            root.pending = null;
                        }
                        onCancelled: root.pending = null
                    }
                }

                Connections {
                    target: perch.modelData
                    function onConnectionFailed(reason) {
                        if (reason === ConnectionFailReason.NoSecrets) {
                            root.pending = perch.modelData;
                            root.trouble = "";
                        } else {
                            root.trouble = "A torre recusou o corvo.";
                        }
                    }
                }
            }
        }

        Rune {
            visible: Net.visibleNetworks.length === 0
            text: Lore.empty("wifi")
            size: Theme.size.small
            color: Theme.fgDim
        }

        Text {
            visible: root.trouble.length > 0
            text: root.trouble
            font.family: Theme.font.carved
            font.italic: true
            font.pixelSize: Theme.size.small
            color: Theme.scar
            renderType: Text.NativeRendering
        }
    }
}
