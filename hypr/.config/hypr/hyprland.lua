-- ╔═══════════════════════════════════════════════════════════════╗
-- ║                                                               ║
-- ║   O   T O R R E Ã O                                           ║
-- ║   Hyprland 0.56, em Lua.                                      ║
-- ║                                                               ║
-- ║   O hyprlang foi depreciado no 0.55 e a config antiga estava   ║
-- ║   num arquivo só, com a indentação achatada. Aqui vai em       ║
-- ║   pedaços, cada um com um assunto.                            ║
-- ║                                                               ║
-- ║   A barra, o papel de parede, o lançador, as notificações, o   ║
-- ║   agente polkit e o bloqueio de tela são um shell só:          ║
-- ║   ~/.config/quickshell/keep                                   ║
-- ║                                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

require("monitors")
require("env")
require("looknfeel")
require("input")
require("binds")
require("rules")
require("autostart")
