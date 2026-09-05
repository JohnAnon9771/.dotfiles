//  A AMPULHETA — as horas.
//  Cinzel com espaçamento largo, um fio de segundos por baixo, e a
//  lua de verdade ao lado. Na hora das bruxas, blackletter.

import QtQuick
import Quickshell
import qs
import qs.ui
import qs.rampart

Segment {
    id: root

    signal openAlmanac()

    padding: Theme.pad.roomy
    spacing: Theme.pad.snug
    hoverTint: Theme.gold

    onActivated: root.openAlmanac()

    readonly property bool bewitched: Settings.data.easterEggs && Lore.witching

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    MoonDisc {
        anchors.verticalCenter: parent.verticalCenter
        visible: Settings.data.easterEggs
        implicitWidth: 12
        implicitHeight: 12
        lit: root.bewitched ? Theme.wraith : Theme.parchment
    }

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: face.implicitWidth
        height: parent.height

        Text {
            id: face

            anchors.centerIn: parent
            text: Settings.data.clock24h
                ? Fmt.pad2(clock.hours) + ":" + Fmt.pad2(clock.minutes)
                : Fmt.pad2(((clock.hours + 11) % 12) + 1) + ":" + Fmt.pad2(clock.minutes)

            font.family: root.bewitched ? Theme.font.scribe : Theme.font.carved
            font.pixelSize: root.bewitched ? Theme.size.title : Theme.size.base
            font.letterSpacing: root.bewitched ? 0 : Theme.runic(Theme.size.base)
            color: root.bewitched ? Theme.wraith : Theme.fg
            renderType: Text.NativeRendering
        }

        // O fio dos segundos: a hora escoando.
        Rectangle {
            anchors { left: parent.left; bottom: parent.bottom; bottomMargin: Theme.pad.tight }
            width: face.implicitWidth * (clock.seconds / 60)
            height: 1
            color: Theme.alpha(Theme.accent, 0.6)
        }
    }
}
