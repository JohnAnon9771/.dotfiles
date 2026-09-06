pragma ComponentBehavior: Bound

//  A AMPULHETA — as horas.
//  Cormorant com espaçamento largo e a lua de verdade ao lado. Na hora
//  das bruxas, blackletter.
//
//  Sem envelope: a primeira versão punha o relógio dentro de um Item
//  com `height: parent.height`, e o pai era a Row do Segmento, cuja
//  altura vem justamente dos filhos. Esse laço era o que deixava a
//  lua e os números desencontrados.
//
//  Também sem o fio de segundos que corria por baixo: a 34 pixels de
//  barra ele não tinha folga e riscava os algarismos.

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
        precision: SystemClock.Minutes
    }

    MoonDisc {
        anchors.verticalCenter: parent.verticalCenter
        visible: Settings.data.easterEggs
        implicitWidth: 13
        implicitHeight: 13
        lit: root.bewitched ? Theme.wraith : Theme.parchment
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter

        text: Settings.data.clock24h
            ? Fmt.pad2(clock.hours) + ":" + Fmt.pad2(clock.minutes)
            : Fmt.pad2(((clock.hours + 11) % 12) + 1) + ":" + Fmt.pad2(clock.minutes)

        font.family: root.bewitched ? Theme.font.scribe : Theme.font.quill
        font.pixelSize: root.bewitched ? Theme.size.title : Theme.size.base
        font.letterSpacing: root.bewitched ? 0 : Theme.runic(Theme.size.base)
        color: root.bewitched ? Theme.wraith : Theme.fg
        renderType: Text.NativeRendering
    }
}
