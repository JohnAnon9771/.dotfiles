-- O que sobe junto com a sessão.
--
-- Antes não subia nada: todos os exec-once estavam comentados, e o
-- hyprpaper vinha por um serviço systemd à parte.
--
-- Este sistema usa uwsm, então componente de sessão não nasce de
-- exec-once: nasce de unit, pendurada em graphical-session.target.
-- O que o compositor faz aqui é apenas dar a partida — quem decide
-- entre `uwsm finalize` e subir o torreão à mão é o keep-session,
-- conforme a sessão tenha ou não um systemd por trás.
--
-- A unit é systemd/.config/systemd/user/quickshell-keep.service.

hl.on("hyprland.start", function()
    hl.exec_cmd("keep-session")
end)
