//  ATENÇÃO — enquanto este item existe, alguém está olhando o detalhe.
//
//  A muralha mostra uma fração do que os serviços sabem: o GpuModule
//  desenha `Gpu.usage` e mais nada, mas o Gpu lia doze arquivos de
//  /sys a cada dois segundos para alimentar um popup que fica fechado
//  o dia inteiro. Ler sensor para ninguém foi medido em 0,45% de um
//  core e ~66 wakeups/s — ver services/Vigil.qml.
//
//  Então o popup declara a própria fome. Ponha um destes dentro de
//  qualquer superfície que mostre detalhe:
//
//      DetailCard {
//          Attention { service: Gpu }
//          ...
//      }
//
//  Enquanto o cartão existir, o serviço relê os sensores caros; quando
//  o Loader o destruir, ele volta a ler só o que a muralha desenha.
//
//  Se por acaso o onDestruction não vier, o contador fica preso acima
//  de zero e o serviço passa a ler tudo, sempre — que é exatamente o
//  comportamento antigo. A falha é degradar, não quebrar.

import QtQuick

Item {
    /// O singleton de serviço a acordar. Precisa ter `watchers: int`.
    property var service: null

    visible: false
    width: 0
    height: 0

    Component.onCompleted:   if (service) service.watchers++
    Component.onDestruction: if (service) service.watchers--
}
