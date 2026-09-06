-- ═══════════════════════════════════════════════════════════════
--  APARÊNCIA
--  Pedra não tem canto arredondado: raio 0, como sempre foi aqui.
--  O que muda é a borda, que passa a ser luz de tocha em vez de
--  marfim liso, e o blur, que agora existe — mas só para as camadas
--  do torreão.
-- ═══════════════════════════════════════════════════════════════

local c = require("theme")

hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 8,

        border_size = 2,

        col = {
            -- A moldura da janela em foco pega a luz da tocha:
            -- ouro envelhecido virando ouro aceso na diagonal.
            active_border = {
                colors = { c.rgba(c.gold, 0.93), c.rgba(c.torch, 0.93) },
                angle = 45,
            },
            inactive_border = c.rgba(c.wood, 0.72),
        },

        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 0,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = false,
        },

        -- Ligado, mas de graça: o Hyprland só borra o que está atrás
        -- de superfície translúcida, e as janelas aqui são opacas.
        -- Quem se inscreve no blur são as camadas do shell, em
        -- rules.lua — é o que dá profundidade de vidro fosco aos
        -- painéis sem custar nada no resto da tela.
        --
        -- "Sem custar nada" só vale para janela opaca. Para as camadas
        -- inscritas, size 6 com passes 3 é kawase de 3 idas e 3 voltas
        -- sobre um framebuffer 3840x2160 — e a wiki é explícita em que
        -- passes é o que mais pesa. Daí o xray.
        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            noise = 0.02,
            contrast = 0.9,
            brightness = 0.72,
            vibrancy = 0.10,

            -- Borra o papel de parede, não a pilha de janelas que
            -- estiver sob a camada. Como a Névoa é estática, o vidro
            -- sai igual — e o Hyprland para de reborrar o que mudou
            -- atrás do painel a cada frame.
            xray = true,

            -- Era true; o default do Hyprland é false. Borrar menu e
            -- tooltip é custo por superfície efêmera, e elas aparecem
            -- justamente durante interação, quando há menos folga.
            popups = false,

            new_optimizations = true,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        -- pseudotile deixou de ser opção de config: virou estado de
        -- janela. O SUPER+P não fica órfão — hl.dsp.window.pseudo()
        -- não depende de nada declarado aqui.
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    -- Com o monitor em scale 2 (ver monitors.lua), toda janela
    -- XWayland era renderizada em 1x e ampliada pela GPU: borrada, e
    -- pagando sampling a cada frame. Com isto ela desenha na
    -- resolução real, e o GDK_SCALE/QT_SCALE_FACTOR do env.lua faz
    -- os toolkits compensarem o tamanho.
    xwayland = {
        force_zero_scaling = true,
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = true,
        -- misc.vfr saiu do config: o compositor já reduz o quadro
        -- sozinho quando a tela está parada. Quem existe hoje é
        -- misc.vrr, que é outra coisa (sincronia adaptativa) e fica
        -- desligada de propósito.
        focus_on_activate = true,
    },
})

-- ── Curvas ─────────────────────────────────────────────────────
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1} } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1} } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })
