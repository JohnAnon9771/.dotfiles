#!/usr/bin/env python3
"""Confere a GlyphSet do Theme.qml contra os nomes reais dos glifos na fonte.

Existe porque a tabela já errou duas vezes em silêncio: `ghost` apontava para
md-surround_sound_2_0 (o espectro do Portão desenhava um "2.0") e `keep` para
md-airbag. Um codepoint errado NÃO vira tofu — a Nerd Font tem quase todo o
plano privado ocupado, então o glifo errado simplesmente aparece, e só se
descobre olhando.

Lê as tabelas `cmap` (formato 12) e `post` (versão 2.0) direto do TTF, sem
dependência externa. Sai != 0 se algum codepoint não existir na fonte.

    tools/glyph-audit.py [--quiet]
"""
import re
import struct
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
THEME = REPO / "quickshell/.config/quickshell/keep/Theme.qml"
FAMILY = "JetBrainsMono Nerd Font"


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
    if missing:
        print(f"\033[31m{len(missing)} glifo(s) ausente(s) na {FAMILY}.\033[0m")
        return 1
    print(f"\033[32m{len(rows)} glifos, todos presentes na {FAMILY}.\033[0m")
    print("Confira os NOMES acima: um codepoint errado existe na fonte e "
          "desenha o ícone errado, sem virar tofu.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
