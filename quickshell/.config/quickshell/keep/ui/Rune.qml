//  RUNA — o texto do castelo, numa voz só por vez.
//
//  O tamanho é `size`, e não `font.pixelSize`: o espaçamento rúnico se
//  calcula a partir dele, e ler font.pixelSize de dentro de uma
//  vinculação para font.letterSpacing fecha um laço — mexer no grupo
//  `font` reinvalida o grupo inteiro.

import QtQuick
import qs

Text {
    id: root

    /// Qual das quatro vozes do castelo fala aqui.
    ///
    ///   "carved"  pedra entalhada — a quill em versalete, com
    ///             espaçamento largo. É inscrição, não prosa.
    ///   "quill"   a mão do escriba — prosa, epitáfio, relógio.
    ///   "scribe"  blackletter — só capitular e brasão, nunca < 18px.
    ///   "mono"    dados, caminhos, metadados.
    ///   "pixel"   os numerais e os rótulos que encostam em sprite.
    property string voice: "carved"
    property int size: Theme.size.base

    font.family: voice === "scribe" ? Theme.font.scribe
               : voice === "mono"   ? Theme.font.mono
               : voice === "pixel"  ? Theme.font.pixel
                                    : Theme.font.quill

    font.pixelSize: root.size

    // A pixel tem espaçamento próprio na grade dela; alargar quebra o
    // encaixe. A mono já vem monoespaçada. As outras duas respiram.
    font.letterSpacing: voice === "mono" || voice === "pixel"
                        ? 0 : Theme.runic(root.size)

    // Versalete só na pedra: a Cormorant em caixa alta com espaçamento
    // largo É a inscrição. Prosa em caixa alta seria grito.
    font.capitalization: voice === "carved" ? Font.AllUppercase
                                            : Font.MixedCase

    color: Theme.fg
    renderType: Text.NativeRendering
    elide: Text.ElideRight
}
