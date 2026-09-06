-- Variáveis de ambiente.
-- Ver https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- ── Qual placa ─────────────────────────────────────────────────
-- Há duas amdgpu nesta máquina: a Raphael do Ryzen (0000:14:00.0) e
-- a dedicada (0000:03:00.0). Sem isto o Hyprland escolhe por ordem
-- de enumeração, sem garantia.
--
-- O caminho é por PCI de propósito. A numeração dos render nodes NÃO
-- acompanha a dos cards e não é estável entre boots — nesta máquina,
-- hoje:
--     card1 = 0000:03:00.0 (dedicada) -> renderD128
--     card0 = 0000:14:00.0 (iGPU)     -> renderD129
-- ou seja, fixar "renderD129" pegaria a integrada.
--
-- A tela está fisicamente na dedicada, então é ela que faz o scanout
-- de qualquer jeito; deixar o resto na integrada só acrescentaria uma
-- cópia por frame pelo PCIe.
hl.env("AQ_DRM_DEVICES", "/dev/dri/by-path/pci-0000:03:00.0-card")

-- ── Escala ─────────────────────────────────────────────────────
-- Par de looknfeel.xwayland.force_zero_scaling: o XWayland passa a
-- desenhar em 3840x2160 e são os toolkits que dobram o tamanho.
hl.env("GDK_SCALE", "2")
hl.env("QT_SCALE_FACTOR", "2")

-- Sem isto o Firefox cai em XWayland, que com scale 2 é o pior caso.
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- LIBVA_DRIVER_NAME não entra: ele nomeia o *driver*, não a placa, e
-- nas duas o driver é o mesmo radeonsi — que o Mesa já resolve
-- sozinho a partir do driver DRM. Definir não compra nada e vira
-- armadilha no dia em que algum app precisar de outro.
