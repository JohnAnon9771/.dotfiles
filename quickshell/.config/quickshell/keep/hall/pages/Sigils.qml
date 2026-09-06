pragma ComponentBehavior: Bound

//  SIGILOS — os alternadores rápidos.

import QtQuick
import Quickshell
import qs
import qs.ui
import qs.hall
import qs.services

Column {
    id: root

    spacing: Theme.pad.wide

    signal action(string what)

    //  Os scripts do torreão moram em ~/.local/bin, e o torreão sobe
    //  como unit do systemd: herda o PATH do gerenciador de usuário,
    //  não o do seu shell. O uwsm/env põe a pasta lá, mas o
    //  caminho inteiro dispensa a aposta — um execDetached que não
    //  acha o binário não devolve erro nenhum, o botão só não faz nada.
    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/"

    Section {
        title: "Sigilos"

        Toggle {
            width: parent.width
            label: "não perturbe"
            detail: Notifs.unread > 0 ? Notifs.unread + " por ler" : ""
            hint: "Cala os pergaminhos que sobem no canto da tela. Nada "
                + "se perde: tudo continua chegando e fica guardado na "
                + "Cripta. O aviso crítico atravessa o silêncio assim "
                + "mesmo — é para isso que ele existe."
            on: Notifs.dnd
            tint: Theme.gold
            onFlipped: Notifs.toggleDnd()
        }

        Toggle {
            width: parent.width
            label: "vigília eterna"
            detail: Idle.inhibited ? "o castelo não dorme" : ""
            hint: "Prende o sono: a tela não apaga e o Portão não cai, "
                + "por mais tempo que o teclado fique quieto. Os "
                + "sensores também ficam de pé — eles dormem junto com "
                + "a sessão para não medir uma máquina que ninguém olha."
            on: Idle.inhibited
            tint: Theme.wraith
            onFlipped: Idle.toggleInhibit()
        }

        Toggle {
            width: parent.width
            label: "véu de âmbar"
            detail: "modo noturno"
            hint: "Estende uma camada de tinta quente sobre a tela "
                + "inteira, acima até da Muralha. Não é filtro de gama "
                + "de verdade — não mexe na curva do monitor —, mas "
                + "dispensa hyprsunset e gammastep e descansa a vista."
            on: Settings.data.nightLight
            tint: Theme.ember
            onFlipped: Settings.toggleNightLight()
        }

        Toggle {
            width: parent.width
            label: "corvos"
            hint: Net.wifiBlocked
                ? "O rádio está travado por hardware — a tecla de avião "
                + "ou o interruptor do aparelho. Daqui não se destrava."
                : "Liga e desliga o rádio sem fio. As redes conhecidas e "
                + "a força do sinal ficam na aba Corvos."
            on: Net.wifiEnabled
            enabled: Net.available && !Net.wifiBlocked
            tint: Theme.moat
            onFlipped: Net.toggleWifi()
        }

        Toggle {
            width: parent.width
            label: "elo rúnico"
            hint: Bt.available
                ? "Liga e desliga o bluetooth. Os aparelhos emparelhados "
                + "e a bateria de cada um ficam na aba Elo."
                : "Nenhum adaptador bluetooth respondeu ao chamado."
            on: Bt.enabled
            enabled: Bt.available
            tint: Theme.royal
            onFlipped: Bt.toggle()
        }

        // Era o toggle de "névoa à deriva", que gravava Settings.data.fog
        // — propriedade que nenhum arquivo de desenho jamais leu. Um
        // botão que não fazia nada. No lugar entra o que estava
        // faltando: os presságios não tinham controle nenhum na UI.
        Toggle {
            width: parent.width
            label: "presságios"
            detail: "assombrações"
            hint: "As nove assombrações do torreão. Entre 3h e 4h a "
                + "paleta esfria para o espectral e um fantasma pousa "
                + "ao lado do brasão; na sexta-feira 13 a cruz vira "
                + "caveira; à noite a Névoa ganha um véu violeta; um "
                + "morcego atravessa o Ossuário de vez em quando; o "
                + "epitáfio muda depois de trinta dias de pé; o Grimório "
                + "responde a certas palavras; e o Portão é assombrado "
                + "depois da terceira senha errada."
            on: Settings.data.easterEggs
            tint: Theme.wraith
            onFlipped: Settings.toggleEasterEggs()
        }
    }

    Section {
        title: "Atos"

        Choice {
            width: parent.width
            text: "Capturar uma região"
            glyph: Theme.glyph.fleuron
            hint: "Arrastar um retângulo. Vai para a área de "
                + "transferência e, se houver onde, também para "
                + "Imagens/capturas."
            onPicked: Quickshell.execDetached([root.bin + "keep-shot", "region"])
        }

        Choice {
            width: parent.width
            text: "Modo jogo"
            glyph: Theme.glyph.gamepad
            hint: "Troca para o TTY 3, onde o modo jogo mora. A sessão "
                + "do desktop NÃO cai: ela fica de pé no TTY dela, e "
                + "voltar é só trocar de TTY."
            onPicked: Quickshell.execDetached([root.bin + "gamer-vt"])
        }

        Choice {
            width: parent.width
            text: "Reerguer o torreão"
            glyph: Theme.glyph.fleuron
            hint: "Recarrega o shell inteiro do disco. É o que aplica "
                + "uma mudança de configuração sem derrubar a sessão."
            onPicked: Quickshell.reload(true)
        }

        Choice {
            width: parent.width
            text: "Refazer a sondagem dos sensores"
            glyph: Theme.glyph.cpu
            detail: Probe.error.length > 0 ? Probe.error : ""
            hint: Probe.error.length > 0
                ? Probe.error
                : "Varre o /sys de novo atrás de temperaturas, ventoinhas "
                + "e placas de vídeo. Serve quando um sensor trocou de "
                + "caminho — o que acontece ao trocar de hardware ou "
                + "depois de uma atualização de kernel."
            onPicked: Probe.rescan()
        }

        Choice {
            width: parent.width
            text: "Ossuário"
            glyph: Theme.glyph.power
            tint: Theme.blood
            hint: "Onde se desliga, reinicia, suspende e encerra a "
                + "sessão. Cada osso exige segurar para confirmar."
            onPicked: root.action("ossuary")
        }
    }
}
