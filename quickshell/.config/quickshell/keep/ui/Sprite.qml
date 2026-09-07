//  SPRITE — um recorte do atlas, e nada mais.
//
//  O componente que o §1.4 do spec pede e que o castelo nunca teve:
//  uma textura na GPU, um Image por sprite visível, um draw call. A
//  alternativa que o mockup HTML sugeria — box-shadow por pixel —
//  viraria centenas de Rectangle no scenegraph por criatura.
//
//  As três regras que fazem pixel art parecer pixel art, e todas as
//  três são obrigatórias aqui:
//
//    · `smooth: false` e `mipmap: false` — sem antialias, sem
//      meio-tom. É o que separa pixel art de pixel art borrada.
//    · `sourceSize` no tamanho NATIVO da folha, para o Qt não decodar
//      mais pixel do que existe.
//    · ESCALA INTEIRA, sempre. `zoom: 2` num sprite de 10, nunca
//      `width: 25` — meio pixel de sprite é um pixel torto.
//
//  Estático em repouso, por doutrina (§2.2: "Sprite na barra em
//  repouso: 0 frames"). Trocar de estado aqui é trocar `cell`, que é
//  uma propriedade e não uma animação: nenhum frame é agendado, o
//  scenegraph redesenha o quadro em que a troca aconteceu e volta a
//  dormir.

import QtQuick
import qs.art

Image {
    id: root

    /// Qual célula do atlas. Use os nomes do Atlas: `Atlas.gargoyleOpen`.
    property int cell: 0

    /// Multiplicador inteiro. Dois é o da muralha.
    property int zoom: 2

    /// Espelha na horizontal. Espelho não gasta célula do atlas.
    property bool mirrored: false

    source: Atlas.source
    sourceClipRect: Atlas.rect(root.cell)
    sourceSize: Qt.size(Atlas.sheetWidth, Atlas.sheetHeight)

    smooth: false
    mipmap: false
    fillMode: Image.Stretch

    /// O lado do sprite já escalado. Quem posiciona usa isto.
    readonly property int side: Atlas.cell * root.zoom

    // width/height, e NÃO implicitWidth/implicitHeight: no Image as
    // duas implícitas são somente-leitura — o Qt as deriva da fonte —
    // e atribuí-las derruba a configuração inteira em tempo de
    // execução. O qmllint não pega: ele passou verde nesta mesma
    // linha, e quem reclamou foi o log do torreão.
    width: root.side
    height: root.side

    transform: Scale {
        xScale: root.mirrored ? -1 : 1
        origin.x: root.width / 2
    }
}
