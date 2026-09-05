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
    match = { namespace = "^keep-(grimoire|ossuary|seal|hall|tablet)$" },

    blur = true,
    ignore_alpha = 0.08,
})

-- A muralha e os pergaminhos: sem blur (são quase opacos) mas com
-- animação de camada, que é o que os faz deslizar.
hl.layer_rule({
    name  = "keep-rampart",
    match = { namespace = "^keep-(rampart|scrolls)$" },

    blur = true,
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
    match = { class = "^steam$", title = "^(?!Steam$).*" },
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
