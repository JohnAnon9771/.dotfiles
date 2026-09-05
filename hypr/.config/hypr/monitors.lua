-- Monitores. Ver https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- 4K a 60 Hz com escala 2: o espaço lógico é 1920x1080, que é o que
-- a Muralha usa para calcular altura e tamanho de fonte.

hl.monitor({
    output   = "HDMI-A-1",
    mode     = "3840x2160@60",
    position = "0x0",
    scale    = 2,
})

-- Qualquer outro que apareça: o que der.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
