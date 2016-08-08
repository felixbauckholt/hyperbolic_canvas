function love.conf(t)
    local x = 256*3
    t.window.width = x
    t.window.height = x
    t.window.minwidth = 30
    t.window.minheight = 30
    t.window.resizable = true


    t.version = "0.10.1"

    t.modules.joystick = false
    t.modules.physics = false
end
