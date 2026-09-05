//  ARCO OGIVAL — a porta gótica.
//
//  A primeira versão usava duas curvas quadráticas com os controles
//  no topo: elas se encontravam com tangente horizontal, o que dá um
//  arco ROMANO, arredondado. Gótico é ponta.
//
//  A ogiva de verdade são dois arcos de círculo cujos centros ficam
//  nos pés opostos. Com raio igual à largura, eles se cruzam a
//  0,866·largura acima da linha de imposta — e cruzam em ângulo,
//  formando o bico.

import QtQuick
import QtQuick.Shapes
import qs

Shape {
    id: root

    property color fill: Theme.bgPanel
    property color stroke: Theme.borderOuter
    property real strokeWidth: Theme.border.outer
    /// Segunda cor: quando definida, o arco recebe um degradê de cima
    /// para baixo. É como a tocha acende a porta sem vazar do arco.
    property color glow: "transparent"
    property bool lit: false

    /// 1.0 = ogiva equilátera. Abaixo disso o bico abre.
    property real pointiness: 1.0

    readonly property real rise: width * 0.8660254 * pointiness
    readonly property real springY: Math.min(rise, height * 0.86)

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: root.stroke
        strokeWidth: root.strokeWidth
        joinStyle: ShapePath.MiterJoin
        capStyle: ShapePath.FlatCap

        // Um caminho só: pôr fillGradient de volta em null não limpa
        // o degradê anterior no Shape — o arco ficava aceso depois de
        // apagar. Então o degradê é sempre o mesmo objeto, e quem
        // muda é a cor do topo.
        fillColor: "transparent"
        fillGradient: litFill

        startX: 0
        startY: root.height

        PathLine { x: 0; y: root.springY }
        PathArc {
            x: root.width / 2; y: root.springY - root.rise
            radiusX: root.width; radiusY: root.width
            direction: PathArc.Clockwise
        }
        PathArc {
            x: root.width; y: root.springY
            radiusX: root.width; radiusY: root.width
            direction: PathArc.Clockwise
        }
        PathLine { x: root.width; y: root.height }
        PathLine { x: 0;          y: root.height }
    }

    LinearGradient {
        id: litFill
        x1: 0; y1: 0
        x2: 0; y2: root.height

        GradientStop { position: 0.0; color: root.lit ? root.glow : root.fill }
        GradientStop { position: 0.7; color: root.fill }
        GradientStop { position: 1.0; color: root.fill }
    }
}
