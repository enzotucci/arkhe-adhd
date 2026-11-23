-- configuracao da janela, lida pelo LÖVE antes do main.lua
function love.conf(t)
    t.identity = "arkhe-adhd"
    t.version = "11.5"

    t.window.title = "arkhe-adhd"
    t.window.width = 480
    t.window.height = 360
    t.window.resizable = false
    t.window.minwidth = 440
    t.window.minheight = 240
    t.window.highdpi = true -- usa a resolucao cheia em telas retina (sem isso fica pixelado)

    -- modulos que o arkhe nao usa
    t.modules.audio = false
    t.modules.sound = false
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
end
