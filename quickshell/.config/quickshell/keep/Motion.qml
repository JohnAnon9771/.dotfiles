//  ╔═══════════════════════════════════════════════════════════════╗
//  ║  A GRAMÁTICA DO MOVIMENTO                                     ║
//  ║  Uma curva por gesto, e o mesmo gesto em todo o castelo.       ║
//  ╚═══════════════════════════════════════════════════════════════╝
//
//  Os NÚMEROS vivem em Theme.motion. Aqui mora a FORMA — e ela precisa
//  de um arquivo próprio por um motivo que não é de gosto:
//
//  As duas regras de sensação do §2.3 são ASSIMÉTRICAS. Entrada é mais
//  rápida que saída; fechar é mais rápido que abrir. Um `Behavior` tem
//  uma animação só para os dois sentidos, então a assimetria não cabe
//  num número — cabe num condicional, e um condicional precisa morar
//  em algum lugar. É aqui.
//
//  E NÃO é `pragma Singleton`, de propósito. Singleton faz o nome
//  resolver para a INSTÂNCIA, e `Motion.Hover {}` precisa que ele
//  resolva para o TIPO. Arquivo comum expõe os `component` inline como
//  tipos; singleton não expõe.
//
//  COMO USAR
//
//      Behavior on opacity { Motion.Hover { entering: root.hovered } }
//      Behavior on color   { Motion.HoverColor { entering: root.hovered } }
//      Behavior on opacity { Motion.Panel { opening: root.open } }
//      Motion.Press   { target: tile; property: "scale"; to: 0.97 }
//      Motion.Release { target: tile; property: "scale"; to: 1.0 }
//
//  Quem inventar duração nova responde a uma pergunta antes: é
//  movimento útil (120–200 ms) ou é clima (segundos)? Se a resposta
//  for "mais ou menos", está errado — o meio parece bug.

import QtQuick
import qs

QtObject {
    /// Passar o mouse. Ligue `entering` ao próprio estado de hover: a
    /// entrada responde, a saída suaviza.
    component Hover: NumberAnimation {
        property bool entering: true
        duration: entering ? Theme.motion.hoverIn : Theme.motion.hoverOut
        easing.type: Easing.OutCubic
    }

    /// A mesma coisa, para cor — e NÃO é um luxo de simetria.
    ///
    /// Um `Behavior on color` com NumberAnimation dentro não avisa e não
    /// falha: o Qt converte a cor para número, não consegue, e assenta a
    /// propriedade em PRETO OPACO. Era o que pintava de preto cada pedra
    /// da muralha sob o mouse. Cor anima com ColorAnimation; a regra vale
    /// para os dois pares daqui.
    component HoverColor: ColorAnimation {
        property bool entering: true
        duration: entering ? Theme.motion.hoverIn : Theme.motion.hoverOut
        easing.type: Easing.OutCubic
    }

    /// Apertar. Curto e seco — é a confirmação de que o clique pegou.
    component Press: NumberAnimation {
        duration: Theme.motion.press
        easing.type: Easing.OutQuad
    }

    /// Soltar. Passa um pouco do ponto e assenta: pedra pesada tem
    /// inércia, mas não é elástico.
    component Release: NumberAnimation {
        duration: Theme.motion.release
        easing.type: Easing.OutBack
        easing.overshoot: Theme.motion.overshoot
    }

    /// Foco de teclado. Mais rápido que hover porque quem navega de
    /// teclado atravessa vários alvos seguidos.
    component Focus: NumberAnimation {
        duration: Theme.motion.focus
        easing.type: Easing.OutCubic
    }

    /// Abrir e fechar painel. Ligue `opening` ao estado de aberto.
    /// A curva também vira: entra desacelerando, sai acelerando.
    component Panel: NumberAnimation {
        property bool opening: true
        duration: opening ? Theme.motion.panelOpen : Theme.motion.panelClose
        easing.type: opening ? Easing.OutCubic : Easing.InCubic
    }

    /// A mesma coisa, para cor.
    component PanelColor: ColorAnimation {
        property bool opening: true
        duration: opening ? Theme.motion.panelOpen : Theme.motion.panelClose
        easing.type: opening ? Easing.OutCubic : Easing.InCubic
    }

    /// Clima. Vinte minutos, linear, imperceptível de propósito: você
    /// nota que mudou, nunca vê mudando.
    component DayNight: ColorAnimation {
        duration: Theme.motion.dayNight
        easing.type: Easing.Linear
    }
}
