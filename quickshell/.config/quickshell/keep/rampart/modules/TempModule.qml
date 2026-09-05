//  O CALOR — temperatura da CPU.
//  O sensor vem do Probe, pelo rótulo. A barra antiga tinha
//  /sys/class/hwmon/hwmon0 chumbado; nesta máquina o k10temp está
//  no hwmon2, então aquilo lia a placa de vídeo.

import QtQuick
import qs
import qs.ui
import qs.rampart
import qs.services

Readout {
    id: root

    visible: Sys.cpuTemp > 0

    glyph: Sys.feverish ? "🜂" : "☄"
    value: Fmt.temp(Sys.cpuTemp)
    tint: Theme.ember
    level: Sys.thermalPressure

    // Brasa quando passa dos 85 °C.
    TorchGlow {
        target: parent
        visible: Sys.feverish
        glow: Theme.blood
        strength: Sys.feverish ? 0.6 : 0
        spread: 0.8
    }
}
