//  RUNA — texto entalhado em pedra.
//  Cinzel, versalete, espaçamento largo. Para títulos e rótulos.
//
//  O tamanho é `size`, e não `font.pixelSize`: o espaçamento rúnico
//  se calcula a partir dele, e ler font.pixelSize de dentro de uma
//  vinculação para font.letterSpacing fecha um laço — mexer no grupo
//  `font` reinvalida o grupo inteiro.

import QtQuick
import qs

Text {
    id: root

    /// "carved" (pedra, padrão) · "scribe" (blackletter) · "mono" (dados)
    property string voice: "carved"
    property int size: Theme.size.base

    font.family: voice === "scribe" ? Theme.font.scribe
               : voice === "mono"   ? Theme.font.mono
                                    : Theme.font.carved
    font.pixelSize: root.size
    font.letterSpacing: voice === "mono" ? 0 : Theme.runic(root.size)
    font.capitalization: voice === "carved" ? Font.AllUppercase : Font.MixedCase

    color: Theme.fg
    renderType: Text.NativeRendering
    elide: Text.ElideRight
}
