//  ARCO OGIVAL — a porta gótica.
//  Base reta, laterais retas, e duas curvas que se encontram num
//  ponto. Usado no Ossuário e nos cabeçalhos de seção.

import QtQuick
import QtQuick.Shapes
import qs

Shape {
    id: root

    property color fill: Theme.bgPanel
    property color stroke: Theme.borderOuter
    property real strokeWidth: Theme.border.outer
    /// Onde as laterais retas terminam e a ogiva começa (0..1 da altura).
    property real spring: 0.42

    readonly property real springY: height * spring

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        id: path

        fillColor: root.fill
        strokeColor: root.stroke
        strokeWidth: root.strokeWidth
        joinStyle: ShapePath.MiterJoin

        startX: 0
        startY: root.height

        PathLine { x: 0;                  y: root.springY }
        PathQuad { controlX: 0;           controlY: 0; x: root.width / 2; y: 0 }
        PathQuad { controlX: root.width;  controlY: 0; x: root.width;     y: root.springY }
        PathLine { x: root.width;         y: root.height }
        PathLine { x: 0;                  y: root.height }
    }
}
