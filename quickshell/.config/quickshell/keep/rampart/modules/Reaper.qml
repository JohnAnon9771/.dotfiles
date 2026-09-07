pragma ComponentBehavior: Bound

//  O CEIFADOR — a porta do Ossuário.
//  O rótulo é o easter egg do rice antigo e fica. O que muda é o
//  comportamento: antes a roda do mouse desligava a máquina sem
//  perguntar nada. Agora o clique abre o Ossuário, e lá dentro
//  desligar exige segurar até o selo lacrar.
//
//  O RÓTULO PARA DE SER DESENHADO POR OITO FONTES.
//
//  Ele era "𝙳Ǝ⊲⊢𝙷 𝙽𝟎⊢𝙴": um D de Mathematical Monospace, um E virado
//  do alfabeto pan-nigeriano, dois sinais de lógica e um zero de
//  novo da faixa matemática. Sete dos oito codepoints NÃO EXISTEM na
//  JetBrainsMono Nerd Font — só o ⊢ — então cada letra caía numa
//  fonte de reserva diferente do fontconfig, com peso e largura
//  próprios. É a "barra remendada" que o Theme.qml documenta, escrita
//  no lugar onde ninguém foi procurar: string literal de módulo, e
//  não a tabela de glifos que o glyph-audit.py conferia.
//
//  As palavras ficam, porque o easter egg são elas. O que sai é o
//  truque de sósia: a mesma estilização vem da TIPOGRAFIA — versalete
//  da voz do escriba com o espaçamento rúnico das inscrições, igual
//  ao brasão do outro lado da muralha. Dez letras, uma fonte só.

import QtQuick
import qs
import qs.ui
import qs.rampart

Segment {
    id: root

    signal openOssuary()

    padding: Theme.pad.roomy
    hoverTint: Theme.scar

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
        text: "Death Note"
        font.family: Theme.font.quill
        font.pixelSize: Theme.size.large
        font.letterSpacing: Theme.runic(Theme.size.large)
        font.capitalization: Font.AllUppercase
        font.weight: Font.DemiBold
        color: root.hovered ? Theme.ivory : Theme.scar
        renderType: Text.NativeRendering

        Behavior on color { ColorAnimation { duration: Theme.anim.quick } }
    }
}
