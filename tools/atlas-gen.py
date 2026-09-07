#!/usr/bin/env python3
"""Gera o atlas de sprites do torreão a partir da arte, que é TEXTO.

    tools/atlas-gen.py            # confere; sai != 0 se divergiu
    tools/atlas-gen.py --write    # regenera o PNG e o Atlas.qml
    tools/atlas-gen.py --show     # imprime cada sprite no terminal

O PNG e o Atlas.qml ficam COMMITADOS, pelo mesmo motivo dos outros
espelhos: o Hyprland arranca antes de qualquer ferramenta e um clone
limpo tem que subir sem python. Mesmo contrato do tools/glyph-audit.py
e do tools/theme-sync.py — que, aliás, já prometia este arquivo no
docstring dele muito antes de ele existir.

A ARTE É FONTE, e é a decisão que faz isto valer a pena.

Cada sprite é um mapa de caracteres aqui embaixo: um caractere por
pixel, e cada letra é o NOME de uma cor da paleta dos Nove — não um
hex. Os hexes saem do Theme.qml, lidos do mesmo jeito que o
theme-sync.py lê. Então mudar `iron` no Theme.qml redesenha as
gárgulas, e a pixel art para de ser um binário órfão que envelhece
sozinho enquanto o resto do castelo muda de cor.

Sem PIL: zlib e struct dão conta de escrever e reler um PNG RGBA, e o
glyph-audit.py já abriu o precedente lendo `cmap` de TTF na mão. Uma
dependência a menos é uma dependência a menos.

AS REGRAS DA §2.2 SÃO CONFERIDAS AQUI, e reprovam o sprite:

  · preenchimento no máximo 60% da célula;
  · pelo menos 1 px de margem vazia nos quatro lados;
  · pelo menos um pixel de plano aceso (`iron`).

As duas primeiras vêm do spec, que documenta o fantasma que a 12x12
"lia como um retângulo com dois furos". A terceira é a lição do corvo e
do morcego: sujeito escuro em fundo escuro não se resolve com detalhe
interno. E aqui ela é mais dura do que no spec, de propósito — sobre a
parede da muralha o carvão dá 1,15:1, quase nada. Quem carrega a
silhueta é o plano ACESO, não o contorno.
"""
import re
import struct
import sys
import zlib
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
KEEP = REPO / "quickshell/.config/quickshell/keep"
THEME = KEEP / "Theme.qml"
ART = KEEP / "art"

# A CÉLULA CRESCEU DE 10 PARA 12.
#
# O §2.2 reserva 8x8 e 10x10 para a barra — "silhueta grossa, 2 a 3
# cores" — e manda o detalhe para 12x12 e 16x16, que ele supõe a 4x ou
# 5x nos overlays. Aqui é 12x12 a 2x, que o spec não previu.
#
# A regra existe porque densidade de detalhe não sobrevive à redução, e
# ela continua valendo: o que NÃO se faz é desenhar uma vez e escalar
# para os dois usos. Um sprite de barra desenhado PARA a barra, na
# escala em que vai ser visto, não cai nessa armadilha — e 44% mais
# pixels são a diferença entre um vulto com um ponto aceso e um bicho
# com órbita, presa e pata.
#
# Vinte e quatro pixels lógicos numa parede de 34: cabe, e sobra.
CELL = 12          # a célula nativa dos sprites de barra
COLS = 8           # células por linha no atlas

# ═══ A PALETA DA ARTE ══════════════════════════════════════════════
# Letra -> nome no Theme.qml. Nenhum hex mora aqui.
TINTAS = {
    "k": "coal",       # sombra, boca, vão
    "d": "stone",      # meio-tom (a cor da própria parede)
    "r": "rim",        # meia-luz
    "z": "dim",        # entre a meia-luz e o plano aceso
    "i": "iron",       # o plano ACESO — é ele que desenha a silhueta
    "w": "wraith",     # o espectral, quando ele olha
    "b": "scar",       # o sangue, quando há risco de verdade
    "c": "cinza",      # o olho apenas aberto
}

# O caractere do OLHO é um encaixe, não uma cor: o mesmo desenho sai
# do forno quantas vezes forem precisas, uma por cor de olho. Assim a
# gárgula tem um desenho só, e não cinco que precisam concordar.
OLHO = "o"

# ═══ A ARTE ════════════════════════════════════════════════════════

#  A GÁRGULA — 12x12, virada para a DIREITA.
#
#  A da esquerda da muralha é esta mesma, espelhada em tempo de
#  execução por um Scale de xScale -1: espelho não gasta célula.
#
#  Ela é PEDRA ESCULPIDA, e por isso é mais clara que a parede em vez
#  de mais escura. A primeira versão era um corpo de carvão com fio de
#  luz, seguindo o §2.2 ao pé da letra — e sumia, porque o §2.2 supõe
#  o fundo de carvão do spec, e a muralha é de pedra. Medindo contra a
#  parede: carvão 1,15:1, rim 1,45:1, ferro 2,29:1. Quem lê é o ferro.
#
#  Luz de cima e da esquerda, a mesma dos escorridos da cantaria.
#
#  O QUE A SOMBRA FAZ AQUI é o que a primeira versão não fazia: ela
#  ESCULPE. Mais pixels sozinhos não deram mais detalhe — a passada
#  intermediária, toda em meio-tom com um contorno aceso, leu como
#  massa. O que descreve forma num sprite deste tamanho é o carvão POR
#  DENTRO: a órbita funda, o vão da boca, a presa clara que sobrou no
#  meio dela, o vinco entre as duas patas.
GARGULA = """
............
....i.......
...izi......
..izzzi.....
..irzzzii...
..irzkozzi..
..irzzzkkkk.
..rizzzzkik.
...izzzzi...
...izkzzi...
...ii.ii....
............
"""

#  A MESMA, RACHADA. Sexta-feira 13, e mais nada.
#  A fissura desce do corno pelo dorso. O olho fecha junto: o que
#  rachou não olha.
GARGULA_RACHA = """
............
....i.......
...iki......
..izkzi.....
..irzkzii...
..irzkozzi..
..irzzkkkkk.
..rizzzzkik.
...izkzzi...
...izzzzi...
...ii.ii....
............
"""

SPRITES = {
    #  nome            arte             olho (nome no Theme, ou None)
    "gargoyleShut":  (GARGULA,        None),
    "gargoyleOpen":  (GARGULA,        "cinza"),
    "gargoyleWatch": (GARGULA,        "wraith"),
    "gargoyleAlarm": (GARGULA,        "scar"),
    "gargoyleCrack": (GARGULA_RACHA,  None),
}


# ═══ O THEME COMO FONTE DE COR ═════════════════════════════════════

LITERAL = re.compile(r'readonly\s+property\s+color\s+(\w+):\s*"(#[0-9a-fA-F]{6})"')
DERIVADA = re.compile(r'readonly\s+property\s+color\s+(\w+):\s*[^\n]*?//\s*(#[0-9a-fA-F]{6})')


def paleta():
    txt = THEME.read_text(encoding="utf-8")
    cores = {}
    for m in LITERAL.finditer(txt):
        cores[m.group(1)] = m.group(2).lower()
    for m in DERIVADA.finditer(txt):
        cores.setdefault(m.group(1), m.group(2).lower())
    if "iron" not in cores:
        sys.exit("nao achei a paleta no Theme.qml — o formato mudou?")
    return cores


def rgb(hexa):
    h = hexa.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


# ═══ A ARTE COMO GRADE ═════════════════════════════════════════════

def grade(arte):
    linhas = arte.strip("\n").split("\n")
    largura = max(len(l) for l in linhas)
    return [list(l.ljust(largura, ".")) for l in linhas]


def conferir(nome, g):
    """As regras da §2.2. Devolve a lista de problemas."""
    h, w = len(g), len(g[0])
    cheio = sum(1 for linha in g for c in linha if c != ".")
    p = []
    if (w, h) != (CELL, CELL):
        p.append(f"célula {w}x{h}, e a nativa é {CELL}x{CELL}")
    if cheio > 0.60 * w * h:
        p.append(f"preenchimento {cheio / (w * h):.0%}, o teto é 60%")
    if any(c != "." for c in g[0]):
        p.append("sem margem no topo")
    if any(c != "." for c in g[-1]):
        p.append("sem margem embaixo")
    if any(linha[0] != "." for linha in g):
        p.append("sem margem à esquerda")
    if any(linha[-1] != "." for linha in g):
        p.append("sem margem à direita")
    if not any(c == "i" for linha in g for c in linha):
        p.append("sem plano aceso (iron) — a silhueta não vai ler na parede")
    return p


# ═══ O PNG, na mão ═════════════════════════════════════════════════

def escrever_png(caminho, w, h, px):
    cru = bytearray()
    for y in range(h):
        cru.append(0)                       # filtro None
        for x in range(w):
            cru += bytes(px[y][x])
    def bloco(tag, dados):
        c = tag + dados
        return struct.pack(">I", len(dados)) + c + struct.pack(">I", zlib.crc32(c))
    out = b"\x89PNG\r\n\x1a\n"
    out += bloco(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    out += bloco(b"IDAT", zlib.compress(bytes(cru), 9))
    out += bloco(b"IEND", b"")
    caminho.write_bytes(out)


def ler_png(caminho):
    """Só o que este programa escreve: RGBA 8 bits, sem entrelace, filtro 0.

    Compara-se PIXEL, e não byte de arquivo: a saída do zlib depende da
    versão da biblioteca, e um `--write` numa máquina com outro zlib
    faria o modo de conferência acusar divergência que não existe.
    """
    if not caminho.exists():
        return None
    dados = caminho.read_bytes()
    if dados[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    i, w, h, idat = 8, 0, 0, b""
    while i < len(dados):
        n = struct.unpack(">I", dados[i:i + 4])[0]
        tag = dados[i + 4:i + 8]
        corpo = dados[i + 8:i + 8 + n]
        if tag == b"IHDR":
            w, h, prof, cor, _, _, entre = struct.unpack(">IIBBBBB", corpo)
            if (prof, cor, entre) != (8, 6, 0):
                return None
        elif tag == b"IDAT":
            idat += corpo
        elif tag == b"IEND":
            break
        i += 12 + n
    cru = zlib.decompress(idat)
    px, passo, ant = [], w * 4, bytearray(w * 4)
    for y in range(h):
        base = y * (passo + 1)
        filtro = cru[base]
        linha = bytearray(cru[base + 1:base + 1 + passo])
        if filtro == 1:
            for x in range(4, passo):
                linha[x] = (linha[x] + linha[x - 4]) & 0xFF
        elif filtro == 2:
            for x in range(passo):
                linha[x] = (linha[x] + ant[x]) & 0xFF
        elif filtro != 0:
            return None                     # não é nosso
        px.append([tuple(linha[x:x + 4]) for x in range(0, passo, 4)])
        ant = linha
    return px


# ═══ A FORJA ═══════════════════════════════════════════════════════

def forjar(cores):
    """Devolve (pixels, ordem_das_celulas, problemas)."""
    problemas = []
    celulas = []
    for nome, (arte, olho) in SPRITES.items():
        g = grade(arte)
        for erro in conferir(nome, g):
            problemas.append(f"{nome}: {erro}")
        celulas.append((nome, g, olho))

    linhas = (len(celulas) + COLS - 1) // COLS
    w, h = COLS * CELL, max(1, linhas) * CELL
    px = [[(0, 0, 0, 0)] * w for _ in range(h)]

    for idx, (nome, g, olho) in enumerate(celulas):
        ox, oy = (idx % COLS) * CELL, (idx // COLS) * CELL
        for y, linha in enumerate(g):
            for x, c in enumerate(linha):
                if c == ".":
                    continue
                if c == OLHO:
                    if olho is None:
                        c = "k"             # olho fechado: uma fenda escura
                    else:
                        px[oy + y][ox + x] = rgb(cores[olho]) + (255,)
                        continue
                if c not in TINTAS:
                    problemas.append(f"{nome}: letra {c!r} não está na paleta da arte")
                    continue
                px[oy + y][ox + x] = rgb(cores[TINTAS[c]]) + (255,)

    return px, [n for n, _, _ in celulas], problemas


AVISO = "//  GERADO por tools/atlas-gen.py a partir da arte. NAO EDITE."


def atlas_qml(ordem, w, h):
    L = ["pragma Singleton", "",
         "//  ╔═══════════════════════════════════════════════════════════════╗",
         "//  ║  O ATLAS                                                      ║",
         "//  ║  Onde cada sprite mora dentro do PNG. Uma textura, um draw.   ║",
         "//  ╚═══════════════════════════════════════════════════════════════╝",
         "//",
         AVISO,
         "//  Para mudar a arte, mude o mapa de caracteres lá e rode:",
         "//      tools/atlas-gen.py --write",
         "", "import QtQuick", "import Quickshell", "",
         "Singleton {",
         "    /// O PNG. Resolvido a partir DESTE arquivo, para o caminho não",
         "    /// depender de quem importa.",
         '    readonly property url source: Qt.resolvedUrl("atlas.png")',
         "",
         f"    readonly property int cell: {CELL}",
         f"    readonly property int sheetWidth: {w}",
         f"    readonly property int sheetHeight: {h}",
         "",
         "    /// O retângulo da célula `n`, em pixels do atlas.",
         "    function rect(n) {",
         f"        return Qt.rect((n % {COLS}) * cell, Math.floor(n / {COLS}) * cell,",
         "                       cell, cell);",
         "    }",
         ""]
    for i, nome in enumerate(ordem):
        L.append(f"    readonly property int {nome}: {i}")
    L += ["}", ""]
    return "\n".join(L)


def main():
    escrever = "--write" in sys.argv
    mostrar = "--show" in sys.argv

    cores = paleta()
    px, ordem, problemas = forjar(cores)
    h, w = len(px), len(px[0])

    if mostrar:
        for nome, (arte, _) in SPRITES.items():
            print(f"\n── {nome} ──")
            for linha in grade(arte):
                print("  " + "".join("··" if c == "." else c * 2 for c in linha))

    print("── A arte ────────────────────────────────────────────")
    if problemas:
        for p in problemas:
            print(f"  \033[31m{p}\033[0m")
        print(f"\n\033[31m{len(problemas)} sprite(s) reprovado(s) pela §2.2.\033[0m")
        return 1
    for nome, (arte, _) in SPRITES.items():
        g = grade(arte)
        cheio = sum(1 for l in g for c in l if c != ".")
        print(f"  {nome:<16} {cheio:>2}/{CELL * CELL} px")

    print()
    print("── O atlas ───────────────────────────────────────────")
    ART.mkdir(parents=True, exist_ok=True)
    png = ART / "atlas.png"
    qml = ART / "Atlas.qml"
    novo_qml = atlas_qml(ordem, w, h)

    sujo = []
    if ler_png(png) != px:
        sujo.append(f"{png.relative_to(REPO)}")
    if (qml.read_text(encoding="utf-8") if qml.exists() else None) != novo_qml:
        sujo.append(f"{qml.relative_to(REPO)}")

    if not sujo:
        print(f"  ok       {png.relative_to(REPO)}  ({w}x{h}, {len(ordem)} células)")
        print(f"  ok       {qml.relative_to(REPO)}")
        return 0

    for s in sujo:
        print(f"  {'escrito ' if escrever else 'DIVERGE '} {s}")
    if not escrever:
        print("\nO atlas nao bate com a arte. Rode com --write.")
        return 1

    escrever_png(png, w, h, px)
    qml.write_text(novo_qml, encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
