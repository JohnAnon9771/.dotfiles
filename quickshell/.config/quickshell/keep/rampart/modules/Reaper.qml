pragma ComponentBehavior: Bound

//  O CEIFADOR — a porta do Ossuário.
//  O rótulo é o easter egg do rice antigo e fica. O que muda é o
//  comportamento: antes a roda do mouse desligava a máquina sem
//  perguntar nada. Agora o clique abre o Ossuário, e lá dentro
//  desligar exige segurar até o selo lacrar.

import QtQuick
import qs
import qs.ui
import qs.rampart

Segment {
    id: root

    signal openOssuary()

    padding: Theme.pad.roomy
    hoverTint: Theme.blood

    onActivated: root.openOssuary()

    popup: Component {
        DetailCard {
            title: "Ossuário"
            Text {
                width: 190
                text: "Trancar, repousar, renascer ou descansar em paz.\n"
                    + "As três últimas pedem que você segure."
                font.family: Theme.font.mono
                font.pixelSize: Theme.size.small
                color: Theme.fgMuted
                wrapMode: Text.WordWrap
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "𝙳Ǝ⊲⊢𝙷 𝙽𝟎⊢𝙴"
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.large
        color: root.hovered ? Theme.ivory : Theme.blood
        renderType: Text.NativeRendering

        Behavior on color { ColorAnimation { duration: Theme.anim.quick } }
    }
}
