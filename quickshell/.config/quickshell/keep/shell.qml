//@ pragma ShellId keep

//  ╔═══════════════════════════════════════════════════════════════╗
//  ║                                                               ║
//  ║   O   T O R R E Ã O                                           ║
//  ║   Um castelo abandonado que ainda acende as tochas.            ║
//  ║                                                               ║
//  ║   Substitui waybar, wofi, hyprpaper e polkit-gnome por uma     ║
//  ║   base só. Aqui é a raiz: monta as superfícies e liga o        ║
//  ║   clima do tema ao que a máquina está sentindo.                ║
//  ║                                                               ║
//  ╚═══════════════════════════════════════════════════════════════╝

import QtQuick
import Quickshell
import qs
import qs.services
import qs.mist
import qs.rampart
import qs.grimoire
import qs.gate
import qs.hall
import qs.ossuary
import qs.scrolls
import qs.seal
import qs.tablet

ShellRoot {
    id: shell

    // ═══ O CLIMA DO CASTELO ════════════════════════════════════
    // As tochas queimam mais forte quando as forjas trabalham, e a
    // paleta esfria na hora das bruxas. Uma transição de segundos:
    // você sente com o canto do olho, sem ler número nenhum.

    Binding {
        target: Theme
        property: "heat"
        value: Settings.data.weather
            ? Math.max(Sys.pressure, Gpu.pressure)
            : 0
    }

    Binding {
        target: Theme
        property: "witching"
        value: Settings.data.easterEggs && Lore.witching
    }

    // A vigília precisa de uma janela a que se prender.
    Binding {
        target: Idle
        property: "anchorWindow"
        value: rampart.primaryBar
    }

    // ═══ O INTERRUPTOR DA RONDA ════════════════════════════════
    // O Vigil decide se vale medir a máquina agora, e não pode
    // perguntar sozinho: se ele passasse a conhecer o Portão, o grafo
    // de serviços fecharia um ciclo. Então a resposta vem de cima,
    // no mesmo gesto do anchorWindow.

    Binding {
        target: Vigil
        property: "locked"
        value: gate.locked
    }

    Binding {
        target: Vigil
        property: "barVisible"
        value: rampart.primaryBar !== null && rampart.primaryBar.visible
    }

    // ═══ AS SUPERFÍCIES ════════════════════════════════════════

    Mist {}

    Rampart {
        id: rampart

        onOpenHall: page => hall.show(page)
        onOpenOssuary: ossuary.show()
        onOpenAlmanac: hall.toggle("almanac")
    }

    NightVeil {}

    Grimoire {
        id: grimoire
        onAction: what => shell.open(what, "")
    }

    GreatHall {
        id: hall
        onAction: what => shell.open(what, "")
    }

    Ossuary {
        id: ossuary
        onLockRequested: shell.open("lock", "")
    }

    Portcullis {
        id: gate
    }

    Seal {}

    ScrollLayer {}

    Tablet {
        id: tablet
    }

    Ipc {
        onRequested: what => shell.open(what, "")
    }

    Shortcuts {
        onTriggered: what => shell.open(what, "")
    }

    // ═══ A VIGÍLIA ═════════════════════════════════════════════
    // Ninguém precisa lembrar de trancar o portão.

    Connections {
        target: Idle

        function onShouldLock() { gate.lock(); }
        function onShouldSleep() {
            // O Hyprland não conta o estado de DPMS por IPC: quem sabe
            // que a tela apagou é quem mandou apagar.
            if (gate.locked) {
                Wm.dpms("off");
                Vigil.screenOff = true;
            }
        }
        function onAwoke() {
            Wm.dpms("on");
            Vigil.screenOff = false;
        }
    }

    // ═══ ROTEAMENTO ════════════════════════════════════════════
    // As superfícies restantes entram nas próximas fases; até lá o
    // pedido é registrado em vez de sumir em silêncio.

    function open(what, arg) {
        switch (what) {
            // A Lápide: aviso rápido, sem painel.
            case "osd:volume":  tablet.instances[0].showVolume(); break;
            case "osd:mic":     tablet.instances[0].showMic(); break;
            case "osd:dnd":     tablet.instances[0].showDnd(); break;
            case "osd:inhibit": tablet.instances[0].showInhibit(); break;

            case "grimoire": grimoire.toggle(); break;
            case "ossuary":  ossuary.toggle(); break;
            case "hall":     hall.toggle(""); break;
            case "crypt":    hall.toggle("crypt"); break;
            case "almanac":  hall.toggle("almanac"); break;
            case "sleep":    Quickshell.execDetached(["systemctl", "suspend"]); break;
            case "lock":     gate.lock(); break;

            default:
                console.log("[keep] ainda não erguido:", what, arg);
        }
    }

    // ═══ REINÍCIO ══════════════════════════════════════════════

    Connections {
        target: Quickshell

        function onReloadFailed(error) {
            console.warn("[keep] as pedras não assentaram:", error);
        }
    }
}
