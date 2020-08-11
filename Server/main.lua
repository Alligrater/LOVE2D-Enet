--- Copyright (C) 2020 Alligrater
--- This piece of software follows the MIT license. See LICENSE for detail.

local Networker

--- Existing bugs:
--- Try run the packed binary file and send in some unicode characters.
--- The encoding is messed up somehow.
    --- Though, you can workaround this by running the file in wsl... weird.

function love.load()
    io.stdout:setvbuf("no")
    --love.window.setTitle("Networker: Server")
    Networker = require("networker")
    Networker.startServer(19198)
end

function love.update(dt)
    Networker.update(dt)
end