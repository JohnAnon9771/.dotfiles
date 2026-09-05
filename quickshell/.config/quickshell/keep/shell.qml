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
import qs.scrolls
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

    // ═══ AS SUPERFÍCIES ════════════════════════════════════════

    Mist {}

    Rampart {
        id: rampart

        onOpenHall: page => shell.open("hall", page)
        onOpenOssuary: shell.open("ossuary", "")
        onOpenAlmanac: shell.open("almanac", "")
    }

    NightVeil {}

    ScrollLayer {}

    Tablet {
        id: tablet
    }

    Ipc {
        onRequested: what => shell.open(what, "")
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
