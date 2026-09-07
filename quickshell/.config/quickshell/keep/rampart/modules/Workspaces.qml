pragma ComponentBehavior: Bound

//  AS FLÂMULAS — os workspaces em algarismos romanos.
//  Herdado do rice antigo, com o Ⅹ que faltava (a waybar só tinha
//  nove ícones) e com a tocha que treme de verdade no ativo.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.ui
import qs.rampart
import qs.services

Item {
    id: root

    /// Sempre visíveis, mesmo vazios.
    property var persistent: [1, 2, 3]
    property int maxWorkspace: 10

    implicitWidth: row.implicitWidth + Theme.pad.snug * 2
    implicitHeight: parent ? parent.height : Theme.metric.barHeight

    readonly property var live: Hyprland.workspaces.values
    readonly property int focusedId:
        Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1

    /// Quais salas aparecem: as que existem, mais as fixas, mais a
    /// que está em foco.
    ///
    /// ISTO NÃO É O MODELO DO REPEATER, e essa é a correção inteira.
    ///
    /// Era. E como modelo, custava a fila de flâmulas ser DESTRUÍDA e
    /// reconstruída sempre que a lista mudasse de conteúdo — porque o
    /// Repeater troca o modelo por identidade, e um array novo é um
    /// modelo novo. Não é só o pano que morre e nasce: é o algarismo,
    /// é o TorchGlow com o framebuffer dele, é o MouseArea.
    ///
    /// Medido com uma sonda no onPaint do Banner, indo para uma sala
    /// que ainda não existia:
    ///
    ///     I → VII    4 repaints — e dois deles, o do II e o do III,
    ///                com a cor EXATAMENTE igual à que já tinham
    ///
    /// Agora o modelo é uma CONTAGEM, e contagem não muda quando você
    /// troca de sala. Os delegates nascem uma vez e ficam; quem some é
    /// a largura e a visibilidade de cada um. E `slots` vira só a
    /// resposta para "esta aparece?", com a guarda de conteúdo abaixo
    /// para nem isso ser reavaliado à toa.
    property var slots: []

    /// O tamanho da fila. Constante na vida real: o Hyprland só tem
    /// atalho até o X, e o teto não se mexe. O max() é o caso raro de
    /// alguém despachar à mão para uma sala acima do teto — aí a fila
    /// cresce, e só aí ela é reconstruída.
    readonly property int slotCount: Math.max(maxWorkspace, focusedId)


    function computeSlots() {
        const seen = ({});
        const out = [];

        for (let i = 0; i < root.persistent.length; i++) {
            seen[root.persistent[i]] = true;
            out.push(root.persistent[i]);
        }

        const l = root.live;
        for (let i = 0; i < l.length; i++) {
            const w = l[i];
            if (w.id < 1 || w.id > root.maxWorkspace) continue;   // especiais têm id negativo
            if (seen[w.id]) continue;
            seen[w.id] = true;
            out.push(w.id);
        }

        if (root.focusedId >= 1 && !seen[root.focusedId]) out.push(root.focusedId);

        out.sort((a, b) => a - b);

        // A guarda. Mesmo conteúdo, mesmo array: o Repeater não vê
        // nada acontecer, e nada é reconstruído.
        const atual = root.slots;
        if (atual.length === out.length) {
            let igual = true;
            for (let i = 0; i < out.length; i++)
                if (atual[i] !== out[i]) { igual = false; break; }
            if (igual) return;
        }

        root.slots = out;
    }

    onLiveChanged: root.computeSlots()
    onFocusedIdChanged: root.computeSlots()
    onPersistentChanged: root.computeSlots()
    Component.onCompleted: root.computeSlots()

    function workspaceOf(id) {
        const l = root.live;
        for (let i = 0; i < l.length; i++) if (l[i].id === id) return l[i];
        return null;
    }

    // Declarada antes da Row para ficar por baixo: as flamulas
    // tratam o clique, e a roda escorre ate aqui.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: e => Wm.workspaceStep(e.angleDelta.y > 0 ? -1 : 1)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            // Contagem, não lista. Ver a doutrina em `slots`.
            model: root.slotCount

            Item {
                id: flag

                required property int index

                /// `wsId` e não `id`: `id` é palavra do QML.
                readonly property int wsId: index + 1

                /// Esta sala está na fila agora?
                readonly property bool shown: root.slots.indexOf(wsId) >= 0

                readonly property var ws: root.workspaceOf(wsId)
                readonly property bool focused: wsId === root.focusedId
                readonly property bool occupied:
                    ws !== null && ws.toplevels.values.length > 0
                readonly property bool urgent: ws !== null && ws.urgent

                // Quem sai da fila encolhe a zero em vez de morrer. A
                // Row reflui igual; o que não acontece é o delegate ser
                // reconstruído.
                width: shown ? numeral.implicitWidth + Theme.pad.base : 0
                visible: shown
                height: root.height

                Text {
                    id: numeral

                    anchors.centerIn: parent
                    text: Theme.roman(flag.wsId)

                    // Silkscreen, na grade dela: 8 px lógicos = 16 de
                    // dispositivo em scale 2, inteiro e sem meio-tom.
                    font.family: Theme.font.pixel
                    font.pixelSize: Theme.size.pixelLarge
                    font.letterSpacing: Theme.graven(Theme.size.pixelLarge)
                    font.weight: flag.focused ? Font.Bold : Font.Normal

                    color: flag.urgent   ? Theme.scar
                         : flag.focused  ? Theme.accentLit
                         : flag.occupied ? Theme.ash
                                         : Theme.fgDim

                    renderType: Text.NativeRendering

                    Behavior on color { ColorAnimation { duration: Theme.anim.base } }
                }

                // O brilho da tocha, só no que está aceso.
                //
                // Nada de animar strength: o TorchGlow é um MultiEffect
                // com shadowEnabled, e a doc do Qt é direta — blur e
                // sombra são os efeitos mais caros e não se aplicam a
                // uma fonte que anima.
                TorchGlow {
                    target: numeral
                    visible: flag.focused
                    glow: Theme.accentLit
                    strength: flag.focused ? 0.55 * Theme.glowStrength : 0
                }

                // A flâmula: fio embaixo de quem tem janelas.
                Rectangle {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: Theme.pad.tight
                    }
                    width: numeral.implicitWidth
                    height: 1
                    color: flag.focused ? Theme.accentLit : Theme.alpha(Theme.ash, 0.5)
                    opacity: flag.occupied || flag.focused ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.anim.base } }
                }

                // Pulsação de urgência: cinco vezes, e para.
                //
                // A urgência do Hyprland dura até você VISITAR o
                // workspace — pode ser meia hora. Infinito aqui era
                // meia hora de scale a 60 fps, na mesma muralha de
                // onde a chama foi embora (ver o rodapé deste arquivo).
                // Cinco pulsos chamam o olho; depois a cor de sangue
                // do numeral segura o recado sozinha.
                SequentialAnimation on scale {
                    running: flag.urgent
                    loops: 5
                    alwaysRunToEnd: true
                    NumberAnimation { to: 1.12; duration: 420; easing.type: Easing.OutQuad }
                    NumberAnimation { to: 1.0;  duration: 420; easing.type: Easing.InQuad }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Wm.workspace(flag.wsId)
                }
            }
        }

        // O scratchpad, quando está aberto.
        Item {
            width: visible ? scratch.implicitWidth + Theme.pad.base : 0
            height: root.height
            visible: {
                const l = root.live;
                for (let i = 0; i < l.length; i++)
                    if (l[i].id < 0 && l[i].toplevels.values.length > 0) return true;
                return false;
            }

            // O SCRATCHPAD NÃO É SOBRENATURAL, é só especial.
            //
            // Ele vestia Theme.royal, que hoje aponta para o spectral —
            // e a terceira lei do Theme.qml não abre exceção: violeta é
            // do sobrenatural, e nunca decorativo. Com o brasão
            // recebendo o fantasma às 03:00 em wraith, a barra tinha
            // dois violetas ao mesmo tempo querendo dizer coisas
            // diferentes, e um deles era decoração.
            //
            // Ash é a cor de item do castelo, e é o que ele é: uma
            // janela guardada que existe.
            Text {
                id: scratch
                anchors.centerIn: parent
                text: Theme.glyph.scratch
                font.family: Theme.font.mono
                font.pixelSize: Theme.size.base
                color: Theme.ash
                renderType: Text.NativeRendering
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Wm.toggleSpecial("magic")
            }
        }
    }

    // A CHAMA FOI EMBORA. Ela sorteava flame ∈ [0.87, 1.00) a cada
    // ~470 ms e animava por 260 ms, o que mantinha a barra desenhando
    // ~55% do tempo — a última fonte de dano contínuo do torreão.
    //
    // E não se via: o efeito entrava em UM lugar só, a opacidade do
    // algarismo romano de 14 px do workspace em foco, com diferença
    // média de 4,3% entre dois sorteios. Abaixo do limiar. Uma tocha
    // que ninguém vê tremular não é uma tocha, é um timer.
}
