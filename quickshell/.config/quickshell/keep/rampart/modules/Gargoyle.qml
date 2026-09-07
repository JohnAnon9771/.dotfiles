//  A GÁRGULA — a ponta da muralha, e a bica dos pergaminhos.
//
//  As duas extremidades da barra eram corte seco contra a borda da
//  tela: a Row da esquerda encostava em parent.left e a da direita em
//  parent.right, e a muralha simplesmente acabava. Agora ela termina
//  em alguma coisa, e essa alguma coisa é a única criatura de pixel
//  art do castelo.
//
//  A DA DIREITA É UMA BICA, e isso não é licença poética: é o que uma
//  gárgula É. O ofício dela numa catedral é cuspir a água para longe
//  da parede, e aqui o que desce por ela são os Pergaminhos. Ela olha
//  quando há o que ler, fecha a cara quando você pediu silêncio, e
//  sangra quando o que chegou é crítico.
//
//  A DA ESQUERDA GUARDA O BRASÃO, espelhada, olhando para fora pelo
//  outro lado. É a mesma célula do atlas com um Scale de -1 — espelho
//  não gasta célula.
//
//  ZERO FRAMES EM REPOUSO. Não há animação nenhuma aqui: todo estado é
//  uma troca de `cell`, que é uma propriedade. Ver ui/Sprite.qml.

import QtQuick
import qs
import qs.ui
import qs.art
import qs.services

Item {
    id: root

    /// A da esquerda olha para o outro lado.
    property bool mirrored: false

    /// A da direita responde aos Pergaminhos; a da esquerda, não.
    property bool spout: false

    readonly property bool eggs: Settings.data.easterEggs

    implicitWidth: sprite.side + Theme.pad.snug
    implicitHeight: parent ? parent.height : Theme.metric.barHeight

    /// Qual cara ela está fazendo.
    ///
    /// A ordem é de precedência, e é a mesma escala de estado do
    /// castelo: risco real primeiro, sobrenatural depois, e o resto
    /// por último. Uma gárgula sangrando não deve virar espectral às
    /// três da manhã só porque deu a hora.
    readonly property int face: {
        if (spout && Notifs.anyCritical) return Atlas.gargoyleAlarm;
        if (spout && Notifs.dnd) return Atlas.gargoyleShut;
        if (eggs && Lore.cursedDay) return Atlas.gargoyleCrack;
        if (eggs && Lore.witching) return Atlas.gargoyleWatch;
        return Atlas.gargoyleOpen;
    }

    Sprite {
        id: sprite

        // Empoleirada, não flutuando: as garras encostam na linha em
        // que a parede vira ameia. O sprite já traz 1 px de margem
        // embaixo por causa da §2.2, então a 2x sobram 2 px de folga e
        // ela não fica espremida contra o corte.
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }

        cell: root.face
        mirrored: root.mirrored
        zoom: 2
    }
}
