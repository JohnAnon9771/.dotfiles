-- O que sobe junto com a sessão.
--
-- Antes não subia nada: todos os exec-once estavam comentados, e o
-- hyprpaper vinha por um serviço systemd à parte. Agora o torreão
-- cobre barra, papel de parede, notificações, polkit e bloqueio —
-- então é um processo só.

hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c keep -d -n")
end)
