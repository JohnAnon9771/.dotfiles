pragma ComponentBehavior: Bound

//  O PERGAMINHO DO MENSAGEIRO — o menu da bandeja, desenhado por nós.
//  O menu nativo do Qt viria cinza e quebraria o tema. Aqui os itens
//  saem do QsMenuOpener e são pintados como o resto do castelo.
//
//  Submenu não abre em cascata: expande no lugar, recuado. Numa
//  lista curta isso é mais fácil de acertar com o mouse.

import QtQuick
import Quickshell
import qs
import qs.ui

PopupWindow {
    id: root

    property var barWindow: null
    property var item: null
    property Item origin: null
    property var expanded: null

    color: "transparent"
    visible: false
    grabFocus: true

    implicitWidth: Math.max(150, frame.implicitWidth)
    implicitHeight: frame.implicitHeight

    anchor {
        item: root.origin
        edges: Edges.Bottom
        gravity: Edges.Bottom
        adjustment: PopupAdjustment.Slide
        margins.top: Theme.pad.tight
    }

    function open(trayItem, anchorItem) {
        root.expanded = null;
        root.item = trayItem;
        root.origin = anchorItem;
        root.visible = true;
    }

    function close() {
        root.visible = false;
        root.item = null;
        root.expanded = null;
    }

    onVisibleChanged: if (!visible) root.item = null

    QsMenuOpener {
        id: opener
        menu: root.item ? root.item.menu : null
    }

    Panel {
        id: frame

        padding: Theme.pad.tight
        implicitWidth: list.implicitWidth + padding * 2
        implicitHeight: list.implicitHeight + padding * 2
        fleurons: false

        Column {
            id: list
            spacing: 0

            Repeater {
                model: opener.children

                Column {
                    id: branch

                    required property var modelData

                    spacing: 0

                    MenuEntry {
                        entry: branch.modelData
                        opened: root.expanded === branch.modelData
                        onChosen: {
                            if (branch.modelData.hasChildren) {
                                root.expanded = root.expanded === branch.modelData
                                    ? null : branch.modelData;
                            } else {
                                branch.modelData.triggered();
                                root.close();
                            }
                        }
                    }

                    QsMenuOpener {
                        id: sub
                        menu: branch.modelData.hasChildren ? branch.modelData : null
                    }

                    Column {
                        spacing: 0
                        visible: root.expanded === branch.modelData

                        Repeater {
                            model: sub.children

                            MenuEntry {
                                required property var modelData

                                indent: Theme.pad.roomy
                                entry: modelData
                                onChosen: {
                                    modelData.triggered();
                                    root.close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
