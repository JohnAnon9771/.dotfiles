//  A APARIÇÃO — que janela está em foco.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.ui
import qs.rampart

Segment {
    id: root

    property int maxWidth: 420

    // Não chamar de `top`: sombrearia a linha de ancoragem do Item.
    readonly property var focused: Hyprland.activeToplevel
    readonly property string title: focused && focused.title ? focused.title : ""

    interactive: false
    visible: title.length > 0

    /// A largura NÃO segue o título.
    ///
    /// Este é o último módulo da fila esquerda e não recebe clique, então
    /// reservar a faixa inteira não muda coisa nenhuma na tela — e evita
    /// que cada troca de título relayoute a Row.
    ///
    /// Isso importa mais do que parece: um terminal com trabalho correndo
    /// reescreve o próprio título várias vezes por segundo (um spinner,
    /// o nome do alvo do make, o progresso de um download). Medindo o
    /// socket2 do Hyprland numa sessão comum deram 3,2 eventos/s, quase
    /// todos `windowtitle` — e cada um puxava um passo de layout que a
    /// muralha não devia nem sentir.
    implicitWidth: visible ? root.maxWidth : 0

    Text {
        id: label

        anchors.verticalCenter: parent.verticalCenter

        // Fixa também aqui: com o elide ligado, é o Text que decide o
        // corte, e ele não precisa medir o texto inteiro para isso.
        width: root.maxWidth - root.padding * 2

        text: root.title
        font.family: Theme.font.mono
        font.pixelSize: Theme.size.base
        color: Theme.fgMuted
        elide: Text.ElideRight
        renderType: Text.NativeRendering

        opacity: root.title.length > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim.base } }
    }
}
