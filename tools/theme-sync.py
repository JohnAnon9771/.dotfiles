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


def starship(c):
    # O PROMPT ERA O ÓRFÃO DO SISTEMA DE TEMA.
    #
    # O docstring aqui em cima já prometia o starship desde que este
    # arquivo existe, e o dict ALVOS só tinha o hypr e o kitty. Nesse
    # meio-tempo o commit c0fb725 trocou a paleta pelos Nove, e o
    # starship.toml ficou com seis hexes que saíram do castelo:
    # #4f6b4a, #3a8f8f, #1e6a88, #c2a35a, #b04b4b, #8b6f9b.
    #
    # O resultado era visível: o prompt pintava node de VERDE num
    # terminal em que o color2 é bege — porque o paleta.conf, este sim
    # gerado, já traduzia verde e azul para neutro, e o starship passava
    # por cima com hex cru.
    #
    # AS TRÊS LEIS VALEM AQUI TAMBÉM, e o mapa abaixo é o que elas
    # deixam:
    #
    #   · OURO fica com o `character` de sucesso, e com mais nada. Ele é
    #     o ponto ATIVO do prompt — é onde você digita. Pintar o cwd de
    #     ouro em toda linha seria a mesma violação que a rampa antiga
    #     do gauge(): a cor do foco vestida por algo que está sempre lá.
    #   · VERMELHO fica com o prompt de erro, que é risco real.
    #   · VIOLETA não aparece. Não há nada sobrenatural num prompt.
    #
    # O PESO NÃO MUDA. O arquivo antigo era bold em tudo menos o
    # [time], e isso é escolha de quem usa o prompt — aqui só a COR
    # entra no espelho. Um gerador que aproveita a passagem para
    # redesenhar o que não lhe pediram é um gerador em que não se
    # confia.
    #
    # E as versões de linguagem perdem a cor própria, todas. Rust
    # laranja, Go ciano e Node verde eram a definição de dashboard: seis
    # matizes competindo para dizer a coisa menos interessante da linha.
    # Em `dim` elas continuam legíveis e param de gritar.
    # OS GLIFOS SAEM POR ESCAPE, e não literais.
    #
    # Eles vivem na área de uso privado da Nerd Font, e caractere de PUA
    # atravessa pipe, editor e clipboard sem garantia nenhuma: na
    # primeira escrita deste gerador três deles chegaram ao arquivo como
    # ESPAÇO, e um TOML com um espaço a mais não reclama de nada.
    #
    # E um deles nunca existiu: o `read_only` era U+F83D, que NÃO ESTÁ
    # no cmap da JetBrainsMono Nerd Font — conferido. O prompt caía em
    # reserva do fontconfig naquele cadeado desde sempre, exatamente
    # como o rótulo do Ceifador na muralha. Vai para md-lock, que é o
    # mesmo cadeado que a Theme.glyph já usa no Ossuário.
    ARCH   = "\uf303"       # linux-archlinux
    CADEADO = "\U000f033e"  # md-lock  (era U+F83D, ausente)
    RAMO   = "\uf418"       # oct-git_branch
    PACOTE = "\U000f03d6"   # md-package_variant  (era um emoji colorido)

    L = [AVISO_HASH, "",
         "format = \"\"\"",
         f'[{ARCH} archlinux](bold {c["cinza"]}) $directory$git_branch$git_status'
         "$rust$ruby$nodejs$golang$package$docker_context$time",
         "$character\"\"\"", "",
         "add_newline = false", "",
         "# Tetos de tempo por prompt. Sem eles o starship usa 500 ms por",
         "# comando e 30 ms de varredura: um repositório grande, ou um `node -v`",
         "# lento, seguram o prompt inteiro. 100 ms é mais do que suficiente",
         "# para todo detector daqui, e o que estourar simplesmente não aparece.",
         "command_timeout = 100",
         "scan_timeout = 10", "",
         "[directory]",
         f'style = "bold {c["ash"]}"',
         f'read_only = "{CADEADO} "',
         "truncation_length = 3",
         'truncation_symbol = "../"',
         'format = "[$path]($style) "', "",
         "[git_branch]",
         f'symbol = "{RAMO} "',
         f'style = "bold {c["cinza"]}"',
         'format = "[$symbol$branch]($style) "', "",
         "# Sujo é atenção, e brasa é a cor da atenção na escala de estado.",
         "[git_status]",
         f'style = "bold {c["ember"]}"',
         "format = '([$all_status$ahead_behind]($style) )'",
         "# $all_status obriga um `git status` completo a cada prompt. Pular os",
         "# submódulos é o corte que a própria doc do starship recomenda.",
         "ignore_submodules = true", ""]

    # As linguagens, todas na mesma voz apagada.
    # dev-rust, dev-ruby, dev-nodejs_small, seti-go — os mesmos do
    # arquivo antigo, menos o ruby: lá ele era U+E791, que é o
    # `dev-ruby_rough`, um rubi lascado. O inteiro é o U+E739.
    for secao, simbolo in (("rust", "\ue7a8"), ("ruby", "\ue739"),
                           ("nodejs", "\ue718"), ("golang", "\ue627")):
        L += [f"[{secao}]",
              f'symbol = "{simbolo} "',
              f'style = "bold {c["dim"]}"',
              'format = "[$symbol($version )]($style)"', ""]

    L += ["# Era um emoji colorido de caixa de papelão, que quebra a voz",
          "# única e não tem cor nenhuma da paleta.",
          "[package]",
          f'symbol = "{PACOTE} "',
          f'style = "bold {c["dim"]}"',
          'format = "[$symbol$version]($style) "', "",
          "[time]",
          "disabled = false",
          'time_format = "%R"',
          f'style = "{c["cinza"]}"',
          "format = '[$time]($style) '", "",
          "# O ÚNICO OURO DA LINHA. Onde você digita é o que está ativo.",
          "[character]",
          f'success_symbol = "[❯](bold {c["gold"]})"',
          f'error_symbol = "[❯](bold {c["scar"]})"',
          f'vicmd_symbol = "[❮](bold {c["cinza"]})"', ""]
    return "\n".join(L)


def btop(c):
    # Os gradientes seguem o Theme.gauge(): MONOCROMÁTICO até importar.
    # A rampa antiga corria musgo → teal → ouro, então um btop aberto
    # numa máquina ociosa ficava verde e azul — e era o mesmo erro que o
    # c0fb725 tirou da muralha, só que numa janela ao lado dela.
    #
    # Agora: cinza enquanto está tudo bem, ouro quando começa a pesar,
    # brasa quando esquenta, sangue quando é risco. É a mesma leitura da
    # barra, na mesma máquina, na mesma hora.
    def g(*nomes):
        return [c[n] for n in nomes]

    L = [AVISO_HASH,
         "# Tema do btop. A paleta canônica vive no Theme.qml.", "",
         f'theme[main_bg]="{c["stone"]}"',
         f'theme[main_fg]="{c["parchment"]}"',
         f'theme[title]="{c["gold"]}"',
         f'theme[hi_fg]="{c["torch"]}"',
         f'theme[selected_bg]="{c["timber"]}"',
         f'theme[selected_fg]="{c["ivory"]}"',
         f'theme[inactive_fg]="{c["dim"]}"',
         f'theme[graph_text]="{c["ash"]}"',
         f'theme[proc_misc]="{c["cinza"]}"', "",
         "# Molduras: madeira.",
         f'theme[cpu_box]="{c["timber"]}"',
         f'theme[mem_box]="{c["timber"]}"',
         f'theme[net_box]="{c["timber"]}"',
         f'theme[proc_box]="{c["timber"]}"',
         f'theme[div_line]="{c["rim"]}"', "",
         "# ── Gradientes: a escala de estado do castelo ──"]

    rampas = [
        ("temp",      g("cinza", "ember", "scar")),
        ("cpu",       g("cinza", "gold", "scar")),
        ("free",      g("dim", "cinza", "ash")),
        ("cached",    g("dim", "cinza", "parchment")),
        ("available", g("dim", "cinza", "ash")),
        ("used",      g("cinza", "gold", "scar")),
        ("download",  g("dim", "cinza", "ash")),
        ("upload",    g("dim", "cinza", "ash")),
        ("process",   g("cinza", "gold", "scar")),
    ]
    for nome, (a, b, d) in rampas:
        L += [f'theme[{nome}_start]="{a}"',
              f'theme[{nome}_mid]="{b}"',
              f'theme[{nome}_end]="{d}"']
    return "\n".join(L) + "\n"


def opencode(c):
    # O tema do agente de código. Mesmo problema, mesma correção.
    #
    # Aqui a lei do violeta é a que mais dói: `syntaxKeyword` e
    # `syntaxOperator` estavam em roxo, que num arquivo de código é a
    # coisa MAIS comum da tela. Violeta é do sobrenatural, e nada num
    # buffer é sobrenatural — keyword vai para ouro, que é o realce
    # legítimo, e operador para a voz apagada.
    #
    # Verde e ciano somem do mesmo jeito que sumiram da muralha. O que
    # sobrevive de cor é: ouro para o que se destaca, brasa para aviso,
    # sangue para erro, e três neutros para o resto.
    import json
    defs = {
        "bg":          c["stone"],
        "bg-light":    c["hall"],
        "bg-lighter":  c["timber"],
        "fg":          c["parchment"],
        "fg-strong":   c["ivory"],
        "fg-muted":    c["ash"],
        "fg-dim":      c["cinza"],
        "rim":         c["rim"],
        "gold":        c["gold"],
        "torch":       c["torch"],
        "ember":       c["ember"],
        "scar":        c["scar"],
        "dim":         c["dim"],
    }
    tema = {
        "primary": "gold", "secondary": "fg-muted", "accent": "torch",
        "error": "scar", "warning": "ember", "success": "fg-muted",
        "info": "fg-dim",
        "text": "fg", "textMuted": "fg-muted",
        "background": "bg", "backgroundPanel": "bg-light",
        "backgroundElement": "bg-lighter",
        "border": "rim", "borderActive": "gold", "borderSubtle": "bg-light",
        "diffAdded": "fg-muted", "diffRemoved": "scar", "diffContext": "dim",
        "markdownText": "fg", "markdownHeading": "gold",
        "markdownLink": "torch", "markdownCode": "fg-muted",
        "markdownBlockQuote": "dim", "markdownEmph": "fg-muted",
        "markdownStrong": "fg-strong",
        "syntaxComment": "dim", "syntaxKeyword": "gold",
        "syntaxFunction": "fg-strong", "syntaxVariable": "fg",
        "syntaxString": "fg-muted", "syntaxNumber": "torch",
        "syntaxType": "fg-muted", "syntaxOperator": "fg-dim",
    }
    doc = {
        "$schema": "https://opencode.ai/theme.json",
        "//": AVISO_HASH.removeprefix("# "),
        "name": "Dark Medieval",
        "defs": defs,
        "theme": tema,
    }
    return json.dumps(doc, indent=2, ensure_ascii=False) + "\n"


ALVOS = {
    "hypr/.config/hypr/theme.lua": lua,
    "kitty/.config/kitty/paleta.conf": kitty,
    "starship/.config/starship.toml": starship,
    "btop/.config/btop/themes/dark-medieval.theme": btop,
    "opencode/.config/opencode/themes/dark-medieval.json": opencode,
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
