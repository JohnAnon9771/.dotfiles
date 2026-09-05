//  Cartão de detalhe: capitular, corrente, e o conteúdo.

import QtQuick
import qs
import qs.ui

Column {
    id: root

    property string title: ""
    default property alias body: holder.data

    spacing: Theme.pad.snug

    Illuminated {
        text: root.title
        initialSize: Theme.size.title + 4
        restSize: Theme.size.base
    }

    Divider { width: Math.max(200, holder.implicitWidth) }

    Column {
        id: holder
        spacing: 2
    }
}
