//  A JANELA DA TORRE — o detalhe que aparece ao passar o mouse.
//  Uma só por muralha, com o conteúdo trocado: dez módulos não
//  precisam de dez janelas.
//
//  É informativa e não recebe clique — o `mask` vazio deixa o
//  ponteiro atravessar. Para agir, clique no módulo: ele abre o
//  Grande Salão. Isso evita a dança de manter o popup vivo
//  enquanto o mouse viaja até ele.

import QtQuick
import Quickshell
import qs
import qs.ui

PopupWindow {
    id: root

    property Item origin: null
    property Component content: null
    /// Tempo parado sobre o módulo antes de abrir.
    property int openDelay: 320

    color: "transparent"
    visible: content !== null && origin !== null

    // Atravessável: informação, não alvo.
    mask: Region {}

    anchor {
        item: root.origin
        edges: Edges.Bottom
        gravity: Edges.Bottom
        adjustment: PopupAdjustment.Slide
        margins.top: Theme.pad.tight
    }

    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight

    function show(item, component) {
        root.origin = item;
        root.content = component;
    }

    function hide(item) {
        // Só apaga se ainda for este módulo: o mouse pode já ter
        // pousado no vizinho e trocado o conteúdo.
        if (root.origin === item) {
            root.origin = null;
            root.content = null;
        }
    }

    Panel {
        id: frame

        padding: Theme.pad.roomy
        implicitWidth: loader.implicitWidth + padding * 2
        implicitHeight: loader.implicitHeight + padding * 2

        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim.quick } }

        Loader {
            id: loader
            anchors.fill: parent
            sourceComponent: root.content
        }
    }
}
