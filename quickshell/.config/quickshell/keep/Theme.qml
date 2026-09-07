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

    // ═══ OS NOVE ══════════════════════════════════════════════════
    // A paleta do spec, literal. Estes são os únicos hexes escritos à
    // mão no castelo inteiro; todo o resto abaixo é derivado deles por
    // mix(), para nada entrar na família por acidente.
    //
    // As três leis, e elas são leis:
    //   · OURO só em foco e estado ativo.
    //   · VERMELHO só em risco real.
    //   · VIOLETA é do sobrenatural, e nunca decorativo.

    readonly property color coal:      "#0a0908"  // carvão — o fundo de tudo
    readonly property color stone:     "#1c1a17"  // pedra — superfícies
    readonly property color timber:    "#241a12"  // madeira — superfície quente
    readonly property color rim:       "#3a3630"  // o fio de luz do sprite escuro
    readonly property color cinza:     "#6d6a63"  // texto secundário
    readonly property color blood:     "#6e1420"  // sangue seco
    readonly property color gold:      "#c9a24a"  // ouro velho
    readonly property color parchment: "#e8dcc0"  // pergaminho — texto primário
    readonly property color spectral:  "#8b6bd9"  // o que não devia estar aqui

    // ═══ DERIVADOS ════════════════════════════════════════════════
    // Cada um é mix() dos nove. O hex ao lado é o resultado, e serve
    // para o tools/theme-sync.py exportar sem ter que avaliar QML.

    /// Fundo de painel: pedra puxada para a madeira.
    readonly property color hall:   mix(stone, timber, 0.5)        // #201a14

    /// Ferro velho — a moldura externa.
    readonly property color iron:   mix(cinza, stone, 0.28)        // #56544e

    /// Adormecido: o que existe e não está acontecendo.
    readonly property color dim:    mix(cinza, stone, 0.5)         // #44423d

    /// Texto de item — entre o secundário e o primário.
    readonly property color ash:    mix(cinza, parchment, 0.55)    // #b1a996

    /// Marfim — o primário forte, para capitular e destaque.
    readonly property color ivory:  mix(parchment, "#ffffff", 0.4) // #f1ead9

    /// Ouro aceso: foco, tocha, o numeral em que você está.
    /// É o `l` da paleta dos sprites — a mesma tinta em pixel e vetor.
    readonly property color torch:  "#e3c37a"

    /// SANGUE SOBRE PEDRA.
    ///
    /// O #6e1420 do spec é cor de PREENCHIMENTO: sobre o carvão ele dá
    /// 1,69:1 de contraste, o que como texto é invisível. Ele está
    /// certo onde o mockup o usa — selo de cera, quadrado de fechar,
    /// rótulo sobre pergaminho claro, borda.
    ///
    /// Para letra e glifo sobre a muralha é preciso subir: este dá
    /// 4,23:1, melhor que o #b04b4b que o castelo usava antes (3,75:1),
    /// e continua na família do sangue seco em vez de virar tijolo.
    readonly property color scar:   mix(blood, parchment, 0.4)     // #9f6460

    /// Brasa — atenção térmica, entre o ouro e o sangue. É a única
    /// matiz que o spec não tem e que a escala de estado exige: sem
    /// ela, "quente mas ainda ok" teria que dividir cor com "risco".
    readonly property color ember:  mix(gold, blood, 0.45)         // #a06237

    /// Véspera — a sombra que a noite deixa. Carvão com um fio de
    /// espectral dentro; nunca cor de objeto, só de ar.
    readonly property color vespers: mix(coal, spectral, 0.22)     // #261f36

    /// O espectral aceso, para quando ele precisa ser lido.
    readonly property color wraith: mix(spectral, parchment, 0.35) // #ac93d0

    // ── Em trânsito ───────────────────────────────────────────────
    // Estes NÃO estão na doutrina e saem na próxima passada. Ficam
    // apontando para o vizinho neutro certo, para o castelo já parar
    // de ter verde e azul sem quebrar os ~44 pontos que os citam.
    //
    // Por que sair: sob "ouro só em foco, vermelho só em risco", uma
    // máquina ociosa pintada de verde e um link pintado de azul dizem
    // "isto aqui é um dashboard", e o castelo deixa de ser um castelo.
    readonly property color moss:      ash        // era #4f6b4a
    readonly property color verdigris: dim        // era #4a6b66
    readonly property color teal:      cinza      // era #3a8f8f
    readonly property color moat:      gold       // era #1e9fb4
    readonly property color royal:     spectral   // era #8b6f9b
    readonly property color crypt:     coal       // o nome antigo do carvão
    readonly property color dust:      cinza
    readonly property color linen:     ash
    readonly property color wood:      rim
    readonly property color storm:     cinza
    readonly property color frost:     hall
    readonly property color clot:      blood

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

    // A escala de estado: adormecido → normal → bom → atenção →
    // alerta → crítico.
    //
    // "Bom" não é verde. Sob "ouro só em foco e ativo", pintar de verde
    // uma máquina que está apenas funcionando gasta uma cor com a
    // informação menos interessante que existe — e o olho aprende a
    // ignorar a barra inteira. O que está bem simplesmente não chama.
    readonly property color stAsleep:    dim
    readonly property color stNormal:    parchment
    readonly property color stGood:      ash
    readonly property color stInfo:      cinza
    readonly property color stWarn:      gold
    readonly property color stAlert:     ember
    readonly property color stCrit:      scar        // legível; o blood é de preenchimento
    readonly property color stSpectral:  wraith

    // ═══ CORES VIVAS ═══════════════════════════════════════════════

    /// A primária do momento: ouro, e espectral na hora das bruxas.
    ///
    /// O ACCENT DESACOPLOU DO CLIMA, e é uma correção de significado,
    /// não de gosto. Ele escorregava para brasa conforme a carga da
    /// máquina — mas ouro é a cor de FOCO e de ATIVO. Com a máquina a
    /// meio gás, um workspace em foco e uma CPU quente passavam a
    /// dividir a mesma cor, e aí o ouro não queria dizer mais nada.
    ///
    /// O clima não perdeu voz: ele fala pelo gradiente de brasa da
    /// ameia e pela escala de gauge(), que são inequivocamente sobre
    /// severidade. Ganhamos de quebra uma classe inteira de repintura:
    /// o accent parou de mudar sozinho a cada degrau de carga, e ele é
    /// citado em dezesseis lugares.
    readonly property color accent: witching ? spectral : gold

    /// O realce aceso (workspace ativo, foco, tocha).
    readonly property color accentLit: witching ? wraith : torch

    /// Intensidade do brilho de tocha: pulsa mais forte sob carga.
    readonly property real glowStrength: 0.55 + heat * 0.45

    // ═══ TIPOGRAFIA ════════════════════════════════════════════
    // Três vozes: pedra esculpida, mão do escriba, livro-razão.
    //
    // Os grupos abaixo são componentes inline, não QtObject solto:
    // assim o qmllint enxerga cada campo e um erro de digitação em
    // Theme.size.smal aparece no lint em vez de virar `undefined`
    // silencioso na tela.

    component FontSet: QtObject {
        /// UnifrakturMaguntia — blackletter. NUNCA abaixo de 18px,
        /// nunca em texto corrido. Só capitulares e brasões.
        readonly property string scribe: "UnifrakturMaguntia"

        /// Cormorant Garamond — a mão do escriba. Relógio, prosa,
        /// epitáfios, o corpo de tudo que é texto escrito e não dado.
        readonly property string quill: "Cormorant Garamond"

        /// JetBrains Mono Nerd Font — todo dado: números, listas,
        /// caminhos, metadados. E os ícones, que são codepoints dela.
        readonly property string mono: "JetBrainsMono Nerd Font"

        /// Silkscreen — os algarismos romanos e os microrrótulos que
        /// encostam em pixel art.
        ///
        /// Desenhada em grade de 8: use SÓ em size.pixel e
        /// size.pixelLarge. Em qualquer outro corpo ela sai com haste
        /// de espessura irregular, que é o oposto do ponto dela.
        readonly property string pixel: "Silkscreen"

        /// ALGARISMO DE CAIXA ALTA, e alinhado em coluna.
        ///
        /// A Cormorant é uma garalda de verdade, então os algarismos
        /// dela são ANTIGOS por padrão: o 1, o 2 e o 0 têm a altura do
        /// x, e o 3, o 4, o 5, o 7 e o 9 descem abaixo da linha. Num
        /// parágrafo isso é bonito; num relógio de 34 px é um número
        /// que parece pequeno e balança de dígito para dígito.
        ///
        /// O `lnum` sobe todos para a altura de capitular — 0,66 em vez
        /// de 0,42 do corpo — e o `tnum` dá a mesma largura a todos,
        /// que é o que impede o "1" de encolher o relógio ao virar a
        /// hora. Use nos ALGARISMOS de qualquer voz de texto; a mono
        /// já nasce assim e não precisa.
        readonly property var figures: ({ "lnum": 1, "tnum": 1 })
    }

    //  POR QUE A CINZEL SAI
    //
    //  Ela e a Cormorant Garamond são as duas serifas de display do
    //  conjunto, e se sobrepõem quase inteiras: capitular romana e
    //  garalda old-style resolvem o mesmo problema. Carregar cinco
    //  famílias para manter as duas não se defende.
    //
    //  Quem herda o quê: a prosa e o relógio vão para a `quill`, e os
    //  ALGARISMOS ROMANOS vão para a `pixel`. Este segundo parece
    //  estranho até você lembrar onde eles ficam — encostados nos
    //  sprites da muralha. Um glifo de hastes inteiras é mais coerente
    //  com a doutrina do pixel que uma capitular de inscrição, e de
    //  quebra resolve a redundância num gesto só.

    component SizeSet: QtObject {
        /// A grade da Silkscreen. Só estes dois corpos para ela: são
        /// múltiplos de 8, e em scale 2 dão 16 e 32 px de dispositivo.
        readonly property int pixel:      8
        readonly property int pixelLarge: 16

        readonly property int tiny:     10
        readonly property int small:    11
        readonly property int base:     12
        readonly property int large:    14
        readonly property int title:    16
        readonly property int display:  22
        readonly property int huge:     44
        readonly property int colossal: 72
    }

    component PadSet: QtObject {
        readonly property int hair:  2
        readonly property int tight: 4
        readonly property int snug:  6
        readonly property int base:  8
        readonly property int roomy: 12
        readonly property int wide:  16
        readonly property int vast:  24
    }

    component BorderSet: QtObject {
        readonly property int inner: 1
        readonly property int outer: 2
    }

    component MetricSet: QtObject {
        readonly property int barHeight:      34
        readonly property int crenelHeight:   9   // altura dos dentes da ameia
        readonly property int crenelWidth:    15  // largura do merlão
        readonly property int crenelGap:      11  // vão entre merlões
        readonly property int hallWidth:      420
        readonly property int grimoireWidth:  760
        readonly property int grimoireHeight: 460
        readonly property int scrollWidth:    380
        readonly property int holdMs:         700 // segurar-para-confirmar
    }

    // ═══ TEMPO ═════════════════════════════════════════════════
    //
    // Duas regras de sensação valem mais que qualquer número, e é por
    // elas que os degraus abaixo foram retunados:
    //
    //   1. SAÍDA MAIS LENTA QUE ENTRADA. Entrada rápida faz a interface
    //      parecer que responde; saída lenta faz ela parecer macia. O
    //      contrário parece que ela está fugindo de você.
    //
    //   2. FECHAR É MAIS RÁPIDO QUE ABRIR. Quem fecha já decidiu. Fazer
    //      essa pessoa esperar pela animação é a coisa mais irritante
    //      que uma shell pode fazer.
    //
    // E uma regra de faixa: movimento útil é rápido (120–200 ms) e
    // movimento atmosférico é lento a ponto de dar dúvida (segundos).
    // Nada no meio — velocidade média parece bug. Era justamente onde
    // o antigo `slow: 380` vivia.

    component AnimSet: QtObject {
        readonly property int instant: 60
        readonly property int quick:   120
        readonly property int base:    180
        readonly property int slow:    220
        readonly property int languid: 900
    }

    /// A tabela canônica do movimento. Os NÚMEROS moram aqui; a FORMA
    /// (curva, assimetria, overshoot) mora em Motion.qml, porque
    /// entrada e saída não cabem num Behavior sem um condicional.
    component MotionSet: QtObject {
        readonly property int hoverIn:    120
        readonly property int hoverOut:   180   // sai mais devagar do que entra
        readonly property int press:       60
        readonly property int release:    220
        readonly property int focus:      100
        readonly property int panelOpen:  180
        readonly property int panelClose: 120   // fecha mais rápido do que abre

        /// Corte seco. O sobrenatural não faz transição: quem não
        /// estava olhando não vê acontecer.
        readonly property int haunt: 0

        /// Vinte minutos de relógio de parede. Dia virando noite não é
        /// animação, é clima.
        readonly property int dayNight: 1200000

        /// O quanto o `release` passa do ponto antes de assentar. O
        /// OutBack do Qt usa 1.70158 como padrão, que é elástico
        /// demais para pedra.
        readonly property real overshoot: 1.1
    }

    readonly property FontSet   font:   FontSet {}
    readonly property SizeSet   size:   SizeSet {}
    readonly property PadSet    pad:    PadSet {}
    readonly property BorderSet border: BorderSet {}
    readonly property MetricSet metric: MetricSet {}
    readonly property AnimSet   anim:   AnimSet {}
    readonly property MotionSet motion: MotionSet {}

    // ═══ GLIFOS ════════════════════════════════════════════════
    // Regra do castelo: nenhum glifo cai em fonte de reserva.
    //
    // A JetBrainsMono Nerd Font NÃO cobre ⚙ ⌬ ☄ ⛃ ✝ ☠ ☾ ⛨ nem os
    // algarismos romanos Ⅰ..Ⅹ. Tudo isso vinha sendo desenhado por
    // alguma fonte de reserva do fontconfig, cada um com um peso
    // diferente — era a causa da barra parecer remendada.
    //
    // Então: ícone é sempre codepoint Nerd Font (conferido presente),
    // e o que é letra fica numa das vozes de texto. Os algarismos
    // romanos são I, V, X do alfabeto e não os Ⅰ..Ⅹ do Unicode: assim
    // eles existem em QUALQUER voz, e hoje moram na Silkscreen, onde a
    // haste inteira encosta na pixel art sem destoar.

    component GlyphSet: QtObject {
        // Vigília
        readonly property string cpu:      "\u{f0ee0}"
        readonly property string gpu:      "\u{f08ae}"
        readonly property string ram:      "\u{f035b}"
        readonly property string temp:     "\u{f050f}"
        readonly property string tempHot:  "\u{f0e01}"
        readonly property string disk:     "\u{f02ca}"
        readonly property string fan:      "\u{f0210}"

        // Corvos
        readonly property string wired:    "\u{f0201}"
        readonly property string wifiOff:  "\u{f092d}"
        readonly property var    wifi:     ["\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"]
        readonly property string down:     "↓"
        readonly property string up:       "↑"

        // Órgão
        readonly property string volMute:  "\u{f075f}"
        readonly property string volLow:   "\u{f057f}"
        readonly property string volMid:   "\u{f0580}"
        readonly property string volHigh:  "\u{f057e}"
        readonly property string mic:      "\u{f036c}"
        readonly property string micOff:   "\u{f036d}"

        // Pergaminhos
        readonly property string bell:     "\u{f009a}"
        readonly property string bellOff:  "\u{f009b}"
        readonly property string bellNone: "\u{f009c}"

        // Ossuário
        readonly property string lock:     "\u{f033e}"
        readonly property string sleep:    "\u{f04b2}"
        readonly property string reboot:   "\u{f0709}"
        readonly property string power:    "\u{f0425}"
        readonly property string logout:   "\u{f0343}"

        // Elo rúnico
        readonly property string bt:       "\u{f00af}"
        readonly property string btOn:     "\u{f00b1}"
        readonly property string btOff:    "\u{f00b2}"

        // Bardo
        readonly property string music:    "\u{f075a}"
        readonly property string play:     "\u{f040a}"
        readonly property string pause:    "\u{f03e4}"

        // Identidade — estes ficam numa voz de texto, não na mono.
        readonly property string cross:    "†"      // o brasão
        readonly property string skull:    "\u{f068c}"
        // U+F07F0 era md-surround_sound_2_0: o espectro do Portão e o
        // fantasma do brasão apareciam como um "2.0" desenhado. A
        // fonte TEM o codepoint, ele só não é um fantasma.
        readonly property string ghost:    "\u{f02a0}"   // md-ghost
        // E U+F0BE9 era md-airbag.
        readonly property string keep:     "\u{f011a}"   // md-castle
        readonly property string gamepad:  "\u{f0296}"   // md-gamepad
        readonly property string bat:      "\u{f0b5f}"   // md-bat
        readonly property string fleuron:  "◈"
        readonly property string scratch:  "\u{f0306}"
        readonly property string moon:     "\u{f0594}"
    }

    readonly property GlyphSet glyph: GlyphSet {}

    /// Algarismo romano em letras de verdade, e não nos Ⅰ..Ⅹ do
    /// Unicode: I, V e X existem em toda voz do castelo.
    function roman(n) {
        const vals = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
        const syms = ["M", "CM", "D", "CD", "C", "XC", "L", "XL",
                      "X", "IX", "V", "IV", "I"];
        let out = "", v = Math.max(0, Math.floor(n));
        for (let i = 0; i < vals.length; i++)
            while (v >= vals[i]) { out += syms[i]; v -= vals[i]; }
        return out;
    }

    /// Espaçamento rúnico — o letter-spacing largo das inscrições.
    /// QML mede em px, não em em; converta a partir do tamanho.
    function runic(px)  { return px * 0.18; }
    function graven(px) { return px * 0.10; }

    // ═══ MÉTRICA ═══════════════════════════════════════════════
    // Pedra não tem canto arredondado. Raio 0 em tudo.

    readonly property int radius: 0

    // ═══ FERRAMENTAS ═══════════════════════════════════════════════

    /// Mistura linear entre duas cores. t = 0 → a, t = 1 → b.
    ///
    /// O Qt.color() na entrada não é zelo: uma STRING não tem `.r`, e em
    /// JavaScript `undefined - undefined` é NaN, que o Qt.rgba() aterra
    /// em zero sem reclamar — inclusive no alfa. Um `mix(parchment,
    /// "#ffffff", 0.4)` devolvia #00000000, e o marfim, que é o texto
    /// forte do castelo inteiro, era transparente. Cor que entra por
    /// argumento passa por aqui antes de ser lida.
    function mix(a, b, t) {
        const x = Qt.color(a), y = Qt.color(b);
        const k = Math.max(0, Math.min(1, t));
        return Qt.rgba(x.r + (y.r - x.r) * k,
                       x.g + (y.g - x.g) * k,
                       x.b + (y.b - x.b) * k,
                       x.a + (y.a - x.a) * k);
    }

    /// Mesma cor, outra opacidade. Substitui todo rgba() hardcoded.
    function alpha(c, a) {
        const x = Qt.color(c);
        return Qt.rgba(x.r, x.g, x.b, a);
    }

    /// Cor de um valor 0..1 na escala de estado. Para medidores,
    /// barras de temperatura e qualquer coisa que possa piorar.
    ///
    /// MONOCROMÁTICA ATÉ IMPORTAR. A rampa antiga corria verde → ouro →
    /// brasa → sangue, então uma máquina ociosa ficava verde e uma a
    /// 50% ficava DOURADA. Sob "ouro só em foco e ativo" isso era
    /// violação direta: metade da barra vestia a cor do foco o tempo
    /// todo, e a cor do foco parava de significar foco.
    ///
    /// Agora nada acontece até 60%. Entre 60 e 85 o ouro entra, e daí
    /// para cima ele apodrece em sangue. Quem olha a muralha de canto
    /// de olho vê cinza enquanto está tudo bem — que é quase sempre — e
    /// só é interrompido quando há motivo.
    function gauge(t) {
        const k = Math.max(0, Math.min(1, t));
        if (k < 0.60) return cinza;
        if (k < 0.85) return mix(cinza, gold, (k - 0.60) / 0.25);
        return mix(gold, scar, (k - 0.85) / 0.15);
    }

    /// Cor de temperatura em °C, com limiares de silício.
    function thermal(celsius) {
        return gauge((celsius - 35) / 55);  // 35 °C frio → 90 °C crítico
    }
}
