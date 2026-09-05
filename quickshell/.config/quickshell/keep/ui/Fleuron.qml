//  FLEURÃO — o losango de filigrana que marca canto de painel.
//  Detalhe de manuscrito iluminado: nenhum canto fica nu.

import QtQuick
import qs

Text {
    property real weight: 0.4

    text: Theme.glyph.fleuron
    font.family: Theme.font.mono
    font.pixelSize: Theme.size.tiny
    color: Theme.alpha(Theme.gold, weight)
    renderType: Text.NativeRendering
}
