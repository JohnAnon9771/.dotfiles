-- ═══════════════════════════════════════════════════════════════
--  OS TOQUES
--
--  O que fala com o torreão usa hl.dsp.global(): o Quickshell
--  registra atalhos globais no compositor, então a tecla chega
--  direto no shell. A alternativa — `qs ipc call` em cada bind —
--  nasce um processo por tecla, e o lançador demoraria a abrir.
-- ═══════════════════════════════════════════════════════════════

local mod = "SUPER"
local terminal = "kitty"
local browser = "firefox"

local function keep(name)
    return hl.dsp.global("quickshell:" .. name)
end

-- ── Programas ──────────────────────────────────────────────────
hl.bind(mod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mod .. " + M", hl.dsp.exec_cmd(terminal .. " -e btop"))
hl.bind(mod .. " + G", hl.dsp.exec_cmd((os.getenv("HOME") or "~") .. "/.local/bin/gamer-vt"))

-- ── O torreão ──────────────────────────────────────────────────
hl.bind(mod .. " + SPACE",       keep("grimoire"))   -- era wofi
hl.bind(mod .. " + A",           keep("hall"))
hl.bind(mod .. " + N",           keep("crypt"))
hl.bind(mod .. " + ESCAPE",      keep("ossuary"))
hl.bind(mod .. " + CTRL + L",    keep("lock"))
hl.bind(mod .. " + C",           keep("almanac"))
hl.bind(mod .. " + SHIFT + N",   keep("dnd"))
hl.bind(mod .. " + SHIFT + I",   keep("inhibit"))
hl.bind(mod .. " + SHIFT + B",   keep("nightLight"))
hl.bind(mod .. " + SHIFT + R",   hl.dsp.exec_cmd("qs -c keep ipc call keep reload"))

-- ── Janelas ────────────────────────────────────────────────────
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"))   -- perdido no diff antigo

-- Foco
hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Mover a janela — faltava
hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Redimensionar — faltava.
-- `relative` nasce false, e sem ele o x e o y viram TAMANHO ABSOLUTO:
-- a janela ficaria com -40 pixels de largura.
local function grow(dx, dy)
    return hl.dsp.window.resize({ x = dx, y = dy, relative = true })
end

hl.bind(mod .. " + CTRL + left",  grow(-40, 0), { repeating = true })
hl.bind(mod .. " + CTRL + right", grow( 40, 0), { repeating = true })
hl.bind(mod .. " + CTRL + up",    grow(0, -40), { repeating = true })
hl.bind(mod .. " + CTRL + down",  grow(0,  40), { repeating = true })

-- Arrastar e redimensionar com o mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ── Salões (workspaces) ────────────────────────────────────────
for i = 1, 10 do
    local key = i % 10   -- o décimo é o zero
    hl.bind(mod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Scratchpad
hl.bind(mod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- ── Capturas ───────────────────────────────────────────────────
-- Região, tela inteira e janela. Antes só havia a de região.
-- A lógica vive em scripts/.local/bin/keep-shot: escrever isso dentro
-- de uma string Lua dentro de uma string de shell era um ninho de
-- aspas esperando para quebrar.
hl.bind("F8",         hl.dsp.exec_cmd("keep-shot region"))
hl.bind("SHIFT + F8", hl.dsp.exec_cmd("keep-shot full"))
hl.bind("CTRL + F8",  hl.dsp.exec_cmd("keep-shot window"))

-- ── Som e mídia ────────────────────────────────────────────────
-- Passam pelo torreão para a Lápide aparecer: antes o volume mudava
-- sem retorno visual nenhum.
hl.bind("XF86AudioRaiseVolume", keep("volumeUp"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", keep("volumeDown"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        keep("volumeMute"), { locked = true })
hl.bind("XF86AudioMicMute",     keep("micMute"),    { locked = true })

-- As teclas que ele já usava, mantidas.
hl.bind("F12", keep("volumeDown"), { locked = true, repeating = true })
hl.bind("F11", keep("volumeMute"), { locked = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
