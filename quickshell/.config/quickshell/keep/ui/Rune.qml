//  RUNA — texto entalhado em pedra.
//  Cinzel, versalete, espaçamento largo. Para títulos e rótulos.

import QtQuick
import qs

Text {
    id: root

    /// "carved" (pedra, padrão) · "scribe" (blackletter) · "mono" (dados)
    property string voice: "carved"

    font.family: voice === "scribe" ? Theme.font.scribe
               : voice === "mono"   ? Theme.font.mono
                                    : Theme.font.carved
    font.pixelSize: Theme.size.base
    font.letterSpacing: voice === "mono" ? 0 : Theme.runic(font.pixelSize)
    font.capitalization: voice === "carved" ? Font.AllUppercase : Font.MixedCase

    color: Theme.fg
    renderType: Text.NativeRendering
    elide: Text.ElideRight
}
