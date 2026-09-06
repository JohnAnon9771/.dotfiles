//  EPITÁFIO — o que o brasão conta quando você para em cima dele.

import QtQuick
import qs
import qs.ui
import qs.services

Column {
    id: root

    property string hostName: ""

    spacing: Theme.pad.snug

    // O Epitáfio conta a vigília e a carga: sensores que a muralha não
    // desenha e que, por isso, só são lidos enquanto ele existe.
    Attention { service: Sys }

    Illuminated {
        text: root.hostName
        initialSize: Theme.size.display
        restSize: Theme.size.large
    }

    Divider { width: Math.max(160, parent.width) }

    Grid {
        columns: 2
        rowSpacing: 2
        columnSpacing: Theme.pad.roomy

        Rune { text: "vigília"; size: Theme.size.tiny; color: Theme.fgDim }
        Text {
            text: Fmt.duration(Sys.uptime)
            font.family: Theme.font.mono; font.pixelSize: Theme.size.small
            color: Theme.fg
        }

        Rune { text: "forja"; size: Theme.size.tiny; color: Theme.fgDim }
        Text {
            text: Probe.cpuModel.replace(/\s*\d+-Core Processor\s*/i, "")
            font.family: Theme.font.mono; font.pixelSize: Theme.size.small
            color: Theme.fg
        }

        Rune { text: "carga"; size: Theme.size.tiny; color: Theme.fgDim }
        Text {
            text: Sys.load1.toFixed(2) + "  ·  " + Sys.procTotal + " almas"
            font.family: Theme.font.mono; font.pixelSize: Theme.size.small
            color: Theme.fg
        }

        Rune { text: "lua"; size: Theme.size.tiny; color: Theme.fgDim }
        Row {
            spacing: Theme.pad.tight
            MoonDisc { anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: Lore.moonName
                font.family: Theme.font.mono; font.pixelSize: Theme.size.small
                color: Theme.fg
            }
        }
    }

    Divider { width: Math.max(160, parent.width) }

    Text {
        width: Math.max(180, parent.width)
        text: Lore.aphorism()
        font.family: Theme.font.carved
        font.pixelSize: Theme.size.small
        font.italic: true
        color: Theme.fgDim
        wrapMode: Text.WordWrap
    }

    // Marco raro: mais de trinta dias de pé.
    Text {
        visible: Settings.data.easterEggs && Lore.isLongVigil(Sys.uptime)
        text: "A vigília perdura."
        font.family: Theme.font.scribe
        font.pixelSize: Theme.size.large
        color: Theme.wraith
    }
}
