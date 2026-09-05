-- Executa a config Lua do Hyprland contra um `hl` simulado.
--
-- O luac só diz se a sintaxe está de pé. Isto roda de verdade: pega
-- concatenação com nil, laço que não fecha, chave escrita errado, e
-- imprime exatamente o que a config manda para o compositor — dá para
-- conferir cada bind com o olho.
--
--   lua tools/test-hypr.lua           # resumo
--   lua tools/test-hypr.lua --full    # tudo

local full = arg[1] == "--full"
local log, errors = {}, {}
local counts = setmetatable({}, { __index = function() return 0 end })

local function note(kind, text, key)
    counts[kind] = counts[kind] + 1
    log[#log + 1] = { kind = kind, text = text, key = key }
end

local function show(v, depth)
    depth = depth or 0
    if type(v) == "table" then
        if v.__dsp then return v.__dsp end
        if depth > 2 then return "{...}" end
        local parts = {}
        for k, x in pairs(v) do
            parts[#parts + 1] = tostring(k) .. "=" .. show(x, depth + 1)
        end
        table.sort(parts)
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    if type(v) == "string" then return '"' .. v .. '"' end
    return tostring(v)
end

-- Os dispatchers devolvem um objeto que descreve a si mesmo.
local function dispatcher(path)
    return setmetatable({}, {
        __call = function(_, ...)
            local args = {}
            for i = 1, select("#", ...) do args[#args + 1] = show((select(i, ...))) end
            return { __dsp = path .. "(" .. table.concat(args, ", ") .. ")" }
        end,
        __index = function(_, key) return dispatcher(path .. "." .. key) end,
    })
end

hl = {
    dsp = dispatcher("dsp"),

    monitor       = function(t) note("monitor", show(t)) end,
    env           = function(k, v) note("env", k .. "=" .. tostring(v)) end,
    config        = function(t) note("config", show(t)) end,
    curve         = function(n, t) note("curve", n .. " " .. show(t)) end,
    animation     = function(t) note("animation", show(t)) end,
    gesture       = function(t) note("gesture", show(t)) end,
    device        = function(t) note("device", show(t)) end,
    window_rule   = function(t) note("window_rule", (t.name or "?") .. " " .. show(t)) end,
    layer_rule    = function(t) note("layer_rule", (t.name or "?") .. " " .. show(t)) end,
    workspace_rule= function(t) note("workspace_rule", show(t)) end,
    permission    = function(a, b, c) note("permission", a .. " " .. b .. " " .. c) end,
    exec_cmd      = function(c) note("exec", tostring(c)) end,
    on            = function(ev, fn)
        note("on", ev)
        if ev == "hyprland.start" then
            local ok, err = pcall(fn)
            if not ok then errors[#errors + 1] = "hyprland.start: " .. tostring(err) end
        end
    end,

    bind = function(keys, action, opts)
        if type(keys) ~= "string" then
            errors[#errors + 1] = "bind com tecla que nao e string: " .. show(keys)
            return
        end
        if action == nil then
            errors[#errors + 1] = "bind sem acao: " .. keys
            return
        end
        note("bind", string.format("%-26s %s%s", keys, show(action),
            opts and ("  " .. show(opts)) or ""), keys)
    end,
}

-- O require tem de achar os módulos ao lado do hyprland.lua.
local dir = "hypr/.config/hypr"
package.path = dir .. "/?.lua;" .. package.path

local ok, err = pcall(dofile, dir .. "/hyprland.lua")
if not ok then
    io.write("\27[31mA config nao rodou:\27[0m\n  ", tostring(err), "\n")
    os.exit(1)
end

-- ── Relatório ──────────────────────────────────────────────────
local order = { "monitor", "env", "config", "curve", "animation", "gesture",
                "bind", "window_rule", "layer_rule", "permission", "on", "exec" }

for _, kind in ipairs(order) do
    if counts[kind] > 0 then
        io.write(string.format("\27[33m%-16s %d\27[0m\n", kind, counts[kind]))
        if full or kind == "bind" or kind == "layer_rule" then
            for _, e in ipairs(log) do
                if e.kind == kind then io.write("    ", e.text, "\n") end
            end
        end
    end
end

-- Bind repetido é erro silencioso: o último ganha e o primeiro some.
-- Normaliza para "super+shift+n": a ordem dos modificadores nao
-- importa para o compositor, e "SUPER + A" e "SUPER+A" sao a mesma
-- tecla.
local function normalize(keys)
    local parts = {}
    for part in keys:lower():gmatch("[^%s+]+") do parts[#parts + 1] = part end
    local main = table.remove(parts)
    table.sort(parts)
    parts[#parts + 1] = main
    return table.concat(parts, "+")
end

local seen, dup = {}, {}
for _, e in ipairs(log) do
    if e.kind == "bind" and e.key then
        local k = normalize(e.key)
        if seen[k] then dup[#dup + 1] = e.key .. " (ja ligada como " .. seen[k] .. ")"
        else seen[k] = e.key end
    end
end
for _, k in ipairs(dup) do errors[#errors + 1] = "tecla ligada duas vezes: " .. k end

io.write("\n")
if #errors > 0 then
    for _, e in ipairs(errors) do io.write("\27[31m  ✗ ", e, "\27[0m\n") end
    os.exit(1)
end
io.write("\27[32mAs pedras estao assentadas.\27[0m\n")
