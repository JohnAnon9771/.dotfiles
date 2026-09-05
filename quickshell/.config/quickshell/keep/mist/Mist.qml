pragma ComponentBehavior: Bound

//  A NÉVOA — o papel de parede.
//  Substitui o hyprpaper e o serviço systemd dele. Ganha travessia
//  suave na troca, vinheta, e um fundo procedural para quando a
//  imagem some: o desktop nunca fica quebrado.

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData

        screen: modelData
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "keep-mist"
        exclusionMode: ExclusionMode.Ignore

        // Opaca de propósito, e não "transparent": a Névoa é o fundo de
        // tudo e sempre pinta o gradiente abaixo. Cor opaca faz o
        // Quickshell pedir uma superfície opaca, que poupa blend na GPU
        // e deixa o compositor descartar por oclusão o que está atrás.
        // A cor é a mesma do primeiro GradientStop: nada muda na tela.
        color: Theme.crypt

        anchors { left: true; right: true; top: true; bottom: true }

        // ── Fundo procedural ───────────────────────────────────
        // Sempre desenhado. Se a imagem carregar, ela cobre; se
        // sumir, isto continua parecendo de propósito.
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0;  color: Theme.crypt }
                GradientStop { position: 0.45; color: Theme.stone }
                GradientStop { position: 1.0;  color: Qt.darker(Theme.timber, 1.6) }
            }
        }

        // ── A imagem, em travessia ─────────────────────────────
        // Dois panos: o novo entra por cima enquanto o velho apaga.
        Image {
            id: below
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            // Sem `cache: false`: os dois panos acabam com a MESMA
            // imagem depois da travessia, e com o cache ligado isso é
            // um decode compartilhado em vez de dois. O Portão também
            // se pendura neste mesmo.
            visible: status === Image.Ready
        }

        Image {
            id: above
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            source: Settings.wallpaperUrl
            visible: status === Image.Ready
            opacity: 0

            onStatusChanged: if (status === Image.Ready) fadeIn.restart()

            NumberAnimation {
                id: fadeIn
                target: above
                property: "opacity"
                from: 0; to: 1
                duration: Theme.anim.languid
                easing.type: Easing.InOutQuad
                onFinished: {
                    below.source = above.source;
                    below.opacity = 1;
                }
            }
        }

        // ── Vinheta ────────────────────────────────────────────
        // Escurece as bordas para a muralha e os painéis terem
        // onde se apoiar. Sombra com temperatura, não preto puro.
        Shape {
            anchors.fill: parent
            visible: Settings.data.vignette
            preferredRendererType: Shape.CurveRenderer
            asynchronous: true

            ShapePath {
                strokeWidth: -1
                fillGradient: RadialGradient {
                    centerX: win.width / 2
                    centerY: win.height / 2
                    centerRadius: Math.max(win.width, win.height) * 0.72
                    focalX: centerX
                    focalY: centerY

                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.62; color: Theme.alpha(Theme.crypt, 0.10) }
                    GradientStop { position: 1.0; color: Theme.alpha(Theme.vespers, 0.62) }
                }

                startX: 0; startY: 0
                PathLine { x: win.width; y: 0 }
                PathLine { x: win.width; y: win.height }
                PathLine { x: 0;         y: win.height }
            }
        }

        // ── Véspera ────────────────────────────────────────────
        // À noite o castelo esfria um tom. Some de dia.
        Rectangle {
            anchors.fill: parent
            color: Theme.vespers
            opacity: Settings.data.easterEggs && Lore.nocturnal ? 0.12 : 0
            Behavior on opacity {
                NumberAnimation { duration: 4000; easing.type: Easing.InOutQuad }
            }
        }
    }
}
