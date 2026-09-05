-- ═══════════════════════════════════════════════════════════════
--  A PALETA DO TORREÃO — espelho de Theme.qml.
--  O compositor e o shell precisam concordar sobre o que é ouro.
--  Se mudar aqui, mude lá.
-- ═══════════════════════════════════════════════════════════════

local M = {}

-- Pedra e madeira
M.crypt     = "11100d"
M.stone     = "15120f"
M.hall      = "1b1813"
M.timber    = "2a231d"
M.wood      = "3a3127"
M.iron      = "7a736b"

-- Pergaminho
M.dust      = "6f6559"
M.parchment = "dcd4c4"
M.ivory     = "f4f0e6"

-- Fogo e sangue
M.gold      = "c2a35a"
M.torch     = "e1c97a"
M.ember     = "c9743a"
M.blood     = "b04b4b"

-- Musgo e assombração
M.moss      = "4f6b4a"
M.wraith    = "86b39a"
M.royal     = "8b6f9b"
M.vespers   = "3b2f45"

--- "c2a35a" + 0.9 → "rgba(c2a35ae6)"
function M.rgba(hex, alpha)
    local a = math.floor((alpha or 1) * 255 + 0.5)
    return string.format("rgba(%s%02x)", hex, a)
end

function M.rgb(hex)
    return "rgb(" .. hex .. ")"
end

return M
