
local Networker

function love.load()
    io.stdout:setvbuf("no")
    --love.window.setTitle("Networker: Server")
    Networker = require("networker")
    Networker.startServer(19198)
end

function love.update(dt)
    Networker.update(dt)
end