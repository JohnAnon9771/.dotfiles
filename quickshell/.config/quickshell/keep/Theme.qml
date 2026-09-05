pragma Singleton

//  ╔═══════════════════════════════════════════════════════════════╗
//  ║  O TORREÃO — Dark Medieval Keep                               ║
//  ║  Fonte única de verdade da paleta, tipografia e métrica.      ║
//  ║  Espelhado em hypr/theme.lua para o compositor.               ║
//  ╚═══════════════════════════════════════════════════════════════╝

import QtQuick
import Quickshell

Singleton {
    id: root

    // ═══ ESTADO AMBIENTE ═══════════════════════════════════════════
    // O castelo tem clima: as cores respondem à carga da máquina e
    // à hora. Quem escreve nestas duas propriedades é o shell.qml.

    /// 0.0 = torreão adormecido · 1.0 = forjas a todo vapor
    property real heat: 0.0

    /// 03:00–04:00 — a paleta esfria em direção ao espectral
    property bool witching: false

    // Transições lentas: você sente, não vê piscar.
    Behavior on heat { NumberAnimation { duration: 1400; easing.type: Easing.OutCubic } }

    // ═══ PEDRA E MADEIRA ═══════════════════════════════════════════
    readonly property color crypt:     "#11100d"  // fundo mais profundo
    readonly property color stone:     "#15120f"  // fundo principal
    readonly property color hall:      "#1b1813"  // painel elevado
    readonly property color timber:    "#2a231d"  // superfície 2 / selecionado
    readonly property color wood:      "#3a3127"  // madeira escura / bordas
    readonly property color iron:      "#7a736b"  // ferro velho (era #808080, cinza morto)

    // ═══ PERGAMINHO ════════════════════════════════════════════════
    readonly property color dust:      "#6f6559"  // pedra gasta — texto inativo
    readonly property color ash:       "#b6b0a4"  // texto de item
    readonly property color linen:     "#b0a79b"  // texto abafado
    readonly property color parchment: "#dcd4c4"  // pergaminho gasto — fg padrão
    readonly property color ivory:     "#f4f0e6"  // marfim — fg forte

    // ═══ FOGO E SANGUE ═════════════════════════════════════════════
    readonly property color gold:      "#c2a35a"  // ouro envelhecido — primária
    readonly property color torch:     "#e1c97a"  // ouro aceso
    readonly property color ember:     "#c9743a"  // brasa — atenção térmica
    readonly property color blood:     "#b04b4b"  // sangue seco — destrutivo
    readonly property color clot:      "#5b2222"  // sangue coalhado

    // ═══ MUSGO E FOSSO ═════════════════════════════════════════════
    readonly property color moss:      "#4f6b4a"  // verde musgo — sucesso/seleção
    readonly property color verdigris: "#4a6b66"  // azinhavre — adormecido
    readonly property color teal:      "#3a8f8f"  // teal profundo
    readonly property color storm:     "#1e6a88"  // céu tempestuoso
    readonly property color moat:      "#1e9fb4"  // água do fosso — link
    readonly property color frost:     "#26333a"  // seleção fria

    // ═══ ASSOMBRAÇÃO ═══════════════════════════════════════════════
    readonly property color wraith:    "#86b39a"  // fogo-fátuo — o espectral
    readonly property color royal:     "#8b6f9b"  // roxo realeza — identidade
    readonly property color vespers:   "#3b2f45"  // véspera — sombra violeta

    // ═══ PAPÉIS SEMÂNTICOS ═════════════════════════════════════════
    // Use SEMPRE estes nos widgets. Trocar um token acima repinta
    // o castelo inteiro sem caçar hex espalhado.

    readonly property color bg:          stone
    readonly property color bgDeep:      crypt
    readonly property color bgPanel:     hall
    readonly property color bgRaised:    timber
    readonly property color bgScrim:     alpha(vespers, 0.82)

    readonly property color fg:          parchment
    readonly property color fgStrong:    ivory
    readonly property color fgMuted:     linen
    readonly property color fgDim:       dust

    readonly property color borderInner: wood
    readonly property color borderOuter: iron
    readonly property color borderLit:   accent

    // A escala de estado que faltava:
    // adormecido → normal → bom → info → atenção → alerta → crítico
    readonly property color stAsleep:    verdigris
    readonly property color stNormal:    parchment
    readonly property color stGood:      moss
    readonly property color stInfo:      moat
    readonly property color stWarn:      gold
    readonly property color stAlert:     ember
    readonly property color stCrit:      blood
    readonly property color stSpectral:  wraith

    // ═══ CORES VIVAS ═══════════════════════════════════════════════
    // Derivadas do clima. Quanto mais quente o torreão, mais as
    // tochas puxam para brasa. Na hora das bruxas, tudo esfria.

    /// A primária do momento — ouro em repouso, brasa sob carga.
    readonly property color accent: witching
        ? mix(gold, wraith, 0.55)
        : mix(gold, ember, heat * 0.7)

    /// O realce aceso (workspace ativo, foco, tocha).
    readonly property color accentLit: witching
        ? mix(torch, wraith, 0.6)
        : mix(torch, ember, heat * 0.55)

    /// Intensidade do brilho de tocha: pulsa mais forte sob carga.
    readonly property real glowStrength: 0.55 + heat * 0.45

    // ═══ TIPOGRAFIA ════════════════════════════════════════════════
    // Três vozes: pedra esculpida, mão do escriba, livro-razão.

    readonly property QtObject font: QtObject {
        /// Cinzel — capitulares romanas. Títulos, algarismos, relógio.
        readonly property string carved: "Cinzel"

        /// UnifrakturMaguntia — blackletter. NUNCA abaixo de 20px,
        /// nunca em texto corrido. Só capitulares e brasões.
        readonly property string scribe: "UnifrakturMaguntia"

        /// JetBrains Mono Nerd Font — todo o resto. Dados, corpo, listas.
        readonly property string mono: "JetBrainsMono Nerd Font"
    }

    readonly property QtObject size: QtObject {
        readonly property int tiny:    10
        readonly property int small:   11
        readonly property int base:    12
        readonly property int large:   14
        readonly property int title:   16
        readonly property int display: 22
        readonly property int huge:    44
        readonly property int colossal: 72
    }

    /// Espaçamento rúnico — o letter-spacing largo das inscrições.
    /// QML mede em px, não em em; converta a partir do tamanho.
    function runic(px)  { return px * 0.18 }
    function graven(px) { return px * 0.10 }

    // ═══ MÉTRICA ═══════════════════════════════════════════════════
    // Pedra não tem canto arredondado. Raio 0 em tudo.

    readonly property int radius: 0

    readonly property QtObject pad: QtObject {
        readonly property int hair: 2
        readonly property int tight: 4
        readonly property int snug: 6
        readonly property int base: 8
        readonly property int roomy: 12
        readonly property int wide: 16
        readonly property int vast: 24
    }

    readonly property QtObject border: QtObject {
        readonly property int inner: 1
        readonly property int outer: 2
    }

    readonly property QtObject metric: QtObject {
        readonly property int barHeight:      34
        readonly property int crenelHeight:   6   // altura dos dentes da ameia
        readonly property int crenelWidth:    9   // largura do merlão
        readonly property int crenelGap:      6   // vão entre merlões
        readonly property int hallWidth:      420
        readonly property int grimoireWidth:  760
        readonly property int grimoireHeight: 460
        readonly property int scrollWidth:    380
        readonly property int holdMs:         700 // segurar-para-confirmar
    }

    readonly property QtObject anim: QtObject {
        readonly property int instant: 90
        readonly property int quick:   150
        readonly property int base:    220
        readonly property int slow:    380
        readonly property int languid: 900
    }

    // ═══ FERRAMENTAS ═══════════════════════════════════════════════

    /// Mistura linear entre duas cores. t = 0 → a, t = 1 → b.
    function mix(a, b, t) {
        const k = Math.max(0, Math.min(1, t));
        return Qt.rgba(a.r + (b.r - a.r) * k,
                       a.g + (b.g - a.g) * k,
                       a.b + (b.b - a.b) * k,
                       a.a + (b.a - a.a) * k);
    }

    /// Mesma cor, outra opacidade. Substitui todo rgba() hardcoded.
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    /// Cor de um valor 0..1 na escala de estado. Para medidores,
    /// barras de temperatura e qualquer coisa que possa piorar.
    function gauge(t) {
        const k = Math.max(0, Math.min(1, t));
        if (k < 0.5)  return mix(moss,  gold,  k / 0.5);
        if (k < 0.8)  return mix(gold,  ember, (k - 0.5) / 0.3);
        return mix(ember, blood, (k - 0.8) / 0.2);
    }

    /// Cor de temperatura em °C, com limiares de silício.
    function thermal(celsius) {
        return gauge((celsius - 35) / 55);  // 35 °C frio → 90 °C crítico
    }
}
