//  Uma seção do salão: capitular, corrente e o conteúdo.

import QtQuick
import qs
import qs.ui

Column {
    id: root

    property string title: ""
    default property alias body: holder.data

    spacing: Theme.pad.base
    width: parent ? parent.width : 0

    Illuminated {
        text: root.title
        initialSize: Theme.size.display
        restSize: Theme.size.base
        gap: 3
    }

    Divider { width: root.width }

    Column {
        id: holder
        width: root.width
        spacing: Theme.pad.snug
    }
}
