#!/usr/bin/env python3
"""Confere a GlyphSet do Theme.qml contra os nomes reais dos glifos na fonte.

Existe porque a tabela já errou duas vezes em silêncio: `ghost` apontava para
md-surround_sound_2_0 (o espectro do Portão desenhava um "2.0") e `keep` para
md-airbag. Um codepoint errado NÃO vira tofu — a Nerd Font tem quase todo o
plano privado ocupado, então o glifo errado simplesmente aparece, e só se
descobre olhando.

Lê as tabelas `cmap` (formatos 4 e 12) e `post` (versão 2.0) direto do TTF,
sem dependência externa. Sai != 0 se algum codepoint não existir na fonte.

Audita TODAS as famílias que o castelo usa, e não só a Nerd Font. Desde
que a Cinzel saiu e entraram a Cormorant Garamond e a Silkscreen, são
quatro vozes carregando texto — e a segunda coisa que este programa pega
é a fonte que NÃO TEM o caractere e deixa o fontconfig escolher outra por
baixo. Um "IX" desenhado por uma fonte de reserva com outro peso é
exatamente o tipo de remendo que ninguém vê e todo mundo sente.

    tools/glyph-audit.py [--quiet]
"""
import re
import struct
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
THEME = REPO / "quickshell/.config/quickshell/keep/Theme.qml"

# A família dos ícones: é dela que sai a GlyphSet inteira.
FAMILY = "JetBrainsMono Nerd Font"

# E o que cada voz de texto precisa cobrir sozinha, sem reserva.
#
# Os algarismos romanos moram aqui de propósito: eles são I, V e X do
# alfabeto justamente para existirem em toda voz. Se um dia alguém
# trocar por Ⅰ..Ⅹ do Unicode, este teste avisa antes da barra remendar.
ROMANOS = "IVXLCDM"

# As vozes vêm do PACOTE, não do sistema: o que importa auditar é o TTF
# que o repositório entrega, e não o que o fontconfig desta máquina por
# acaso resolveu hoje. Um container com o cache velho não é motivo para
# o teste falhar, e um host com a fonte instalada por fora não é motivo
# para ele passar.
VENDOR = REPO / "fonts/.local/share/fonts/keep"
VOZES = {
    "Cormorant Garamond": ("CormorantGaramond[wght].ttf",
                           ROMANOS + "0123456789:·—\u2019\""),
    "Silkscreen":         ("Silkscreen-Regular.ttf",
                           ROMANOS + "0123456789·"),
    "UnifrakturMaguntia": ("UnifrakturMaguntia-Book.ttf",
                           "Torreão" + ROMANOS),
}


def font_path(family):
    out = subprocess.run(["fc-match", "-f", "%{file}", family],
                         capture_output=True, text=True, check=True)
    return out.stdout.strip()


def tables(data):
    out = {}
    for i in range(struct.unpack(">H", data[4:6])[0]):
        o = 12 + i * 16
        out[data[o:o + 4].decode("latin1")] = struct.unpack(">II", data[o + 8:o + 16])
    return out


def cmap4(data, sub):
    """Formato 4 — o que fontes de texto costumam trazer."""
    segx2 = struct.unpack(">H", data[sub + 6:sub + 8])[0]
    seg = segx2 // 2
    ends = struct.unpack(f">{seg}H", data[sub + 14:sub + 14 + segx2])
    sb = sub + 16 + segx2
    starts = struct.unpack(f">{seg}H", data[sb:sb + segx2])
    cobre = set()
    for s, e in zip(starts, ends):
        if s == 0xFFFF:
            continue
        cobre.update(range(s, min(e, 0xFFFE) + 1))
    return cobre


def cobertura(caminho):
    """Todos os codepoints que a fonte tem, por qualquer subtable."""
    data = Path(caminho).read_bytes()
    off, _ = tables(data)["cmap"]
    cobre = set()
    for i in range(struct.unpack(">H", data[off + 2:off + 4])[0]):
        _, _, sub_off = struct.unpack(">HHI", data[off + 4 + i * 8:off + 12 + i * 8])
        sub = off + sub_off
        fmt = struct.unpack(">H", data[sub:sub + 2])[0]
        if fmt == 4:
            cobre |= cmap4(data, sub)
        elif fmt == 12:
            for g in range(struct.unpack(">I", data[sub + 12:sub + 16])[0]):
                s, e, _gid = struct.unpack(">III", data[sub + 16 + g * 12:sub + 28 + g * 12])
                cobre.update(range(s, e + 1))
    return cobre


def instalada(familia):
    """O fontconfig desta máquina resolve a família, ou entrega reserva?

    O fc-match SEMPRE devolve alguma coisa: sem a família ele entrega a
    reserva, calado. É o mesmo silêncio que este programa existe para
    quebrar — mas aqui vale só como AVISO, porque a máquina que roda o
    teste nem sempre é a que roda o torreão.
    """
    try:
        achou = subprocess.run(["fc-match", "-f", "%{family}", familia],
                               capture_output=True, text=True, check=True).stdout
    except subprocess.CalledProcessError:
        return False
    return familia.split()[0].lower() in achou.lower()


def auditar_vozes(quiet):
    """Cada voz de texto cobre o que se pede dela, sem cair em reserva?"""
    faltou = 0
    for familia, (arquivo, precisa) in VOZES.items():
        caminho = VENDOR / arquivo
        if not caminho.exists():
            print(f"  \033[31m{familia:<22} NÃO VERSIONADA em "
                  f"fonts/.local/share/fonts/keep/{arquivo}\033[0m")
            faltou += 1
            continue
        cobre = cobertura(caminho)
        ausentes = [c for c in dict.fromkeys(precisa) if ord(c) not in cobre]
        if ausentes:
            print(f"  \033[31m{familia:<22} não tem: {' '.join(ausentes)}\033[0m")
            faltou += 1
        elif not quiet:
            nota = "" if instalada(familia) else "  (não instalada NESTA máquina)"
            print(f"  {familia:<22} cobre os {len(set(precisa))} pedidos{nota}")
    return faltou


def cmap12(data, tabs):
    """codepoint -> glyph id, só o subtable formato 12 (o que cobre o plano 15)."""
    off, _ = tabs["cmap"]
    mapping = {}
    for i in range(struct.unpack(">H", data[off + 2:off + 4])[0]):
        _, _, sub_off = struct.unpack(">HHI", data[off + 4 + i * 8:off + 12 + i * 8])
        sub = off + sub_off
        if struct.unpack(">H", data[sub:sub + 2])[0] != 12:
            continue
        for g in range(struct.unpack(">I", data[sub + 12:sub + 16])[0]):
            s, e, gid = struct.unpack(">III", data[sub + 16 + g * 12:sub + 28 + g * 12])
            for cp in range(s, e + 1):
                mapping.setdefault(cp, gid + (cp - s))
    return mapping


def post_names(data, tabs):
    off, length = tabs["post"]
    if struct.unpack(">I", data[off:off + 4])[0] != 0x20000:
        return None, None
    n = struct.unpack(">H", data[off + 32:off + 34])[0]
    idx = struct.unpack(f">{n}H", data[off + 34:off + 34 + n * 2])
    p, end, names = off + 34 + n * 2, off + length, []
    while p < end:
        ln = data[p]
        names.append(data[p + 1:p + 1 + ln].decode("latin1"))
        p += 1 + ln
    return idx, names


def main():
    quiet = "--quiet" in sys.argv

    print("── As vozes ──────────────────────────────────────────")
    faltou = auditar_vozes(quiet)
    print()
    print("── Os ícones ─────────────────────────────────────────")

    data = Path(font_path(FAMILY)).read_bytes()
    tabs = tables(data)
    c2g = cmap12(data, tabs)
    idx, names = post_names(data, tabs)

    def glyph_name(cp):
        gid = c2g.get(cp)
        if gid is None:
            return None
        if idx is None or gid >= len(idx):
            return "<sem post>"
        i = idx[gid]
        return names[i - 258] if 258 <= i < 258 + len(names) else f"<mac {i}>"

    src = THEME.read_text()
    rows = re.findall(r'property string (\w+):\s*"\\u\{([0-9a-fA-F]+)\}"', src)
    if not rows:
        print("nenhum glifo encontrado em", THEME, file=sys.stderr)
        return 2

    missing = []
    for prop, hexcp in rows:
        cp = int(hexcp, 16)
        name = glyph_name(cp)
        if name is None:
            missing.append((prop, cp))
            print(f"  \033[31m{prop:<12} U+{cp:05X}  AUSENTE NA FONTE\033[0m")
        elif not quiet:
            print(f"  {prop:<12} U+{cp:05X}  {name}")

    print()
    if missing or faltou:
        if missing:
            print(f"\033[31m{len(missing)} glifo(s) ausente(s) na {FAMILY}.\033[0m")
        if faltou:
            print(f"\033[31m{faltou} voz(es) de texto com buraco.\033[0m")
        return 1
    print(f"\033[32m{len(rows)} glifos, todos presentes na {FAMILY}.\033[0m")
    print("Confira os NOMES acima: um codepoint errado existe na fonte e "
          "desenha o ícone errado, sem virar tofu.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
