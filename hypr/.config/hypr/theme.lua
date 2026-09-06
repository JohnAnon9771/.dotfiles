-- ═══════════════════════════════════════════════════════════════
--  A PALETA DO TORREÃO — espelho de Theme.qml.
--  O compositor e o shell precisam concordar sobre o que é ouro.
--
--  GERADO por tools/theme-sync.py a partir do Theme.qml. NAO EDITE.
--  Para mudar uma cor, mude no Theme.qml e rode:
--      tools/theme-sync.py --write
-- ═══════════════════════════════════════════════════════════════

local M = {}

-- Os nove do spec
M.coal      = "0a0908"
M.stone     = "1c1a17"
M.timber    = "241a12"
M.rim       = "3a3630"
M.cinza     = "6d6a63"
M.blood     = "6e1420"
M.gold      = "c9a24a"
M.parchment = "e8dcc0"
M.spectral  = "8b6bd9"

-- Derivadas
M.hall      = "201a14"
M.iron      = "56544e"
M.dim       = "44423d"
M.ash       = "b1a996"
M.ivory     = "f1ead9"
M.torch     = "e3c37a"
M.scar      = "9f6460"
M.ember     = "a06237"
M.vespers   = "261f36"
M.wraith    = "ac93d0"

--- "c9a24a" + 0.9 → "rgba(c9a24ae6)"
function M.rgba(hex, alpha)
    local a = math.floor((alpha or 1) * 255 + 0.5)
    return string.format("rgba(%s%02x)", hex, a)
end

function M.rgb(hex)
    return "rgb(" .. hex .. ")"
end

return M
