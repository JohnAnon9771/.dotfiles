#!/usr/bin/env python3
"""Gera os espelhos da paleta a partir do Theme.qml.

O Theme.qml e a fonte unica de verdade da cor do torreao — mas ele nao e
o unico que precisa saber o que e ouro. O Hyprland desenha a borda da
janela, o kitty pinta dezesseis cores de terminal, o starship pinta o
prompt, o btop e o opencode tem tema proprio. Eram cinco arquivos
espelhados a mao, com um comentario dizendo "se mudar aqui, mude la" —
que e a forma educada de dizer "isto vai dessincronizar".

Agora dessincronizar da erro:

    tools/theme-sync.py            # confere; sai != 0 se divergiu
    tools/theme-sync.py --write    # regenera os espelhos

Os arquivos gerados ficam COMMITADOS, de proposito: o Hyprland arranca
antes de qualquer ferramenta, e um clone limpo tem que subir sem python.
Mesmo contrato do tools/glyph-audit.py e do atlas.

Le duas formas do Theme.qml:

    readonly property color gold: "#c9a24a"          -- literal
    readonly property color ash:  mix(...)  // #b1a996  -- derivada

A segunda so entra se o hex estiver no comentario ao lado. E de
proposito: derivada sem hex anotado nao atravessa a fronteira, porque
avaliar mix() aqui seria reimplementar o QML em python e mentir na
primeira vez que a expressao mudasse.
"""
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
THEME = REPO / "quickshell/.config/quickshell/keep/Theme.qml"

LITERAL = re.compile(r'readonly\s+property\s+color\s+(\w+):\s*"(#[0-9a-fA-F]{6})"')
# O [^\n]*? tem que engolir aspas: `mix(parchment, "#ffffff", 0.4)` e
# uma derivada legitima, e um `[^"\n]` educado demais a perderia.
DERIVADA = re.compile(r'readonly\s+property\s+color\s+(\w+):\s*[^\n]*?//\s*(#[0-9a-fA-F]{6})')


def paleta():
    txt = THEME.read_text(encoding="utf-8")
    cores = {}
    for m in LITERAL.finditer(txt):
        cores[m.group(1)] = m.group(2).lower()
    for m in DERIVADA.finditer(txt):
        cores.setdefault(m.group(1), m.group(2).lower())
    if "gold" not in cores:
        sys.exit("nao achei a paleta no Theme.qml — o formato mudou?")
    return cores


AVISO_LUA = "-- GERADO por tools/theme-sync.py a partir do Theme.qml. NAO EDITE."
AVISO_HASH = "# GERADO por tools/theme-sync.py a partir do Theme.qml. NAO EDITE."


def lua(c):
    grupos = [
        ("Os nove do spec", ["coal", "stone", "timber", "rim", "cinza",
                             "blood", "gold", "parchment", "spectral"]),
        ("Derivadas", ["hall", "iron", "dim", "ash", "ivory", "torch",
                       "scar", "ember", "vespers", "wraith"]),
    ]
    L = ["-- ═══════════════════════════════════════════════════════════════",
         "--  A PALETA DO TORREÃO — espelho de Theme.qml.",
         "--  O compositor e o shell precisam concordar sobre o que é ouro.",
         "--",
         "--  " + AVISO_LUA.removeprefix("-- "),
         "--  Para mudar uma cor, mude no Theme.qml e rode:",
         "--      tools/theme-sync.py --write",
         "-- ═══════════════════════════════════════════════════════════════",
         "", "local M = {}", ""]
    for titulo, nomes in grupos:
        L.append("-- " + titulo)
        for n in nomes:
            if n in c:
                L.append(f'M.{n:<10}= "{c[n].lstrip("#")}"')
        L.append("")
    L += ['--- "c9a24a" + 0.9 → "rgba(c9a24ae6)"',
          "function M.rgba(hex, alpha)",
          "    local a = math.floor((alpha or 1) * 255 + 0.5)",
          '    return string.format("rgba(%s%02x)", hex, a)',
          "end", "",
          "function M.rgb(hex)",
          '    return "rgb(" .. hex .. ")"',
          "end", "", "return M", ""]
    return "\n".join(L)


def kitty(c):
    # O terminal tem dezesseis cores e a doutrina tem nove. As oito
    # normais sao a familia; as oito "brilhantes" sao a mesma familia um
    # degrau acima. Verde e azul viram neutro pelo mesmo motivo que
    # sairam da muralha — nao ha verde nem azul nesta paleta.
    m = {
        "color0": c["coal"],      "color8":  c["dim"],
        "color1": c["scar"],      "color9":  c["ember"],
        "color2": c["ash"],       "color10": c["parchment"],
        "color3": c["gold"],      "color11": c["torch"],
        "color4": c["cinza"],     "color12": c["ash"],
        "color5": c["spectral"],  "color13": c["wraith"],
        "color6": c["iron"],      "color14": c["cinza"],
        "color7": c["parchment"], "color15": c["ivory"],
    }
    L = [AVISO_HASH, "",
         f'background            {c["stone"]}',
         f'foreground            {c["parchment"]}',
         f'selection_background  {c["timber"]}',
         f'selection_foreground  {c["ivory"]}',
         f'cursor                {c["gold"]}',
         f'cursor_text_color     {c["stone"]}',
         f'url_color             {c["torch"]}', "",
         f'tab_bar_background       {c["coal"]}',
         f'active_tab_foreground    {c["coal"]}',
         f'active_tab_background    {c["gold"]}',
         f'inactive_tab_foreground  {c["cinza"]}',
         f'inactive_tab_background  {c["hall"]}', ""]
    for k in sorted(m, key=lambda s: int(s[5:])):
        L.append(f"{k:<8}{m[k]}")
    return "\n".join(L) + "\n"


ALVOS = {
    "hypr/.config/hypr/theme.lua": lua,
    "kitty/.config/kitty/paleta.conf": kitty,
}


def main():
    escrever = "--write" in sys.argv
    c = paleta()
    sujo = 0
    for rel, gera in ALVOS.items():
        p = REPO / rel
        novo = gera(c)
        velho = p.read_text(encoding="utf-8") if p.exists() else None
        if velho == novo:
            print(f"  ok       {rel}")
            continue
        sujo += 1
        if escrever:
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(novo, encoding="utf-8")
            print(f"  escrito  {rel}")
        else:
            print(f"  DIVERGE  {rel}")
    if sujo and not escrever:
        print("\nO espelho nao bate com o Theme.qml. Rode com --write.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
