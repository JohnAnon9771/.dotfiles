-- ═══════════════════════════════════════════════════════════════
--  REGRAS DE JANELA E DE CAMADA
-- ═══════════════════════════════════════════════════════════════

-- ── Camadas do torreão ─────────────────────────────────────────
-- Vidro fosco só onde interessa. O blur está ligado em looknfeel,
-- mas janela opaca não borra nada — então isto não custa no resto
-- da tela, e é o que faz o véu do Ossuário parar de deixar ler o
-- texto que está atrás.
hl.layer_rule({
    name  = "keep-glass",
    match = { namespace = "^keep-(grimoire|ossuary|seal|tablet)$" },

    blur = true,
    ignore_alpha = 0.08,
})

-- O Grande Salão saiu do vidro. Ele é pedra opaca de ponta a ponta —
-- Theme.bg no corpo, bgDeep no corrimão e na cantaria — então o blur
-- ficava atrás de superfície que não deixa ver nada. E como a janela
-- cobria a tela inteira, isso era kawase de 3 passes sobre 3840x2160 a
-- cada frame que o painel repintasse: o mesmo item que tirou a Muralha
-- daqui, pago de novo e sem nada em troca.
hl.layer_rule({
    name  = "keep-hall",
    match = { namespace = "^keep-hall$" },

    blur = false,
    ignore_alpha = 0.4,
})

-- O véu que pega o clique fora do Salão. Alpha 0 puro, e desenhado uma
-- vez só: nem blur, nem animação de camada — animar uma superfície de
-- tela cheia que ninguém vê é custo por nada.
hl.layer_rule({
    name  = "keep-hall-scrim",
    match = { namespace = "^keep-hall-scrim$" },

    blur = false,
    no_anim = true,
})

-- A muralha e os pergaminhos: sem blur (são quase opacos) mas com
-- animação de camada, que é o que os faz deslizar.
--
-- O blur estava ligado aqui, contra o que este comentário sempre
-- disse, e era o item mais caro da sessão: a barra tem fundo
-- transparente, então todo repaint dela obrigava o Hyprland a
-- recomputar kawase de 3 passes (looknfeel: size 6, passes 3) sobre
-- um framebuffer 3840x2160. Como a barra nunca ficava parada, isso
-- rodava a 60 fps o dia inteiro e anulava o misc:vfr.
--
-- Medido com o desktop ocioso: gpu_busy_percent 13-19% e 23 W.
hl.layer_rule({
    name  = "keep-rampart",
    match = { namespace = "^keep-(rampart|scrolls)$" },

    blur = false,
    ignore_alpha = 0.4,
})

-- A névoa é o fundo: nada de animar nem borrar o papel de parede.
hl.layer_rule({
    name  = "keep-mist",
    match = { namespace = "^keep-(mist|nightveil)$" },

    no_anim = true,
})

-- ── Janelas ────────────────────────────────────────────────────

hl.window_rule({
    -- Ignora pedido de maximizar de qualquer aplicativo.
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    -- Conserta o arrasto no XWayland.
    name  = "fix-xwayland-drags",
    match = {
        class = "^$", title = "^$",
        xwayland = true, float = true,
        fullscreen = false, pin = false,
    },
    no_focus = true,
})

-- Diálogos flutuam: seletor de arquivo, autenticação, "sobre".
hl.window_rule({
    name  = "float-dialogs",
    match = { title = "^(Open|Save|Escolher|Abrir|Salvar).*" },
    float = true,
    center = true,
})

hl.window_rule({
    name  = "float-utilities",
    match = { class = "^(pavucontrol|blueman-manager|nm-connection-editor|org.kde.polkit-kde-authentication-agent-1)$" },
    float = true,
    center = true,
    size = "980 640",
})

-- Picture-in-picture: pequeno, flutuante e por cima de tudo.
hl.window_rule({
    name  = "pip",
    match = { title = "^(Picture-in-Picture|Imagem sobre imagem)$" },
    float = true,
    pin = true,
    size = "600 338",
    move = "100%-620 100%-400",
})

-- Steam abre janelinhas que não devem virar tile.
hl.window_rule({
    name  = "steam-bits",
    match = { class = "^steam$" },
    float = true,
})

-- Hyprland-run, do template.
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- ── Permissões ─────────────────────────────────────────────────
-- Só valem com ecosystem.enforce_permissions ligado; deixadas prontas
-- para quando ele for ligado. Exigem reinício do Hyprland.
hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
hl.permission("/usr/(bin|local/bin)/quickshell", "screencopy", "allow")
