--- Copyright (C) 2020 Alligrater
--- This piece of software follows the MIT license. See LICENSE for detail.

local Networker
local text = ""
local font, tnr, ss
local utf8
local canvas
--local isTextEditing = "direct" --editing, committed, direct
--local textInput = ""'
local isIMEOpen = false
local inputStream = 0

local queryMode = "server"

function love.load()
    io.stdout:setvbuf("no")
    love.window.setTitle("Networker: Client")
    Networker = require("networker")
    utf8 = require('utf8')
    tnr = love.graphics.newFont("resource/times.ttf", 12, "mono")
    ss = love.graphics.newFont("resource/simsun.ttc", 12)
    tnr:setFilter("nearest","nearest")
    ss:setFilter("nearest","nearest")
    tnr:setFallbacks(ss)
    love.graphics.setFont(tnr)
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.keyboard.setKeyRepeat(true)
    canvas = love.graphics.newCanvas(400,300)
end

function love.textinput(t)
    --if(isTextEditing == "editing") then
    --end
    isIMEOpen = false
    inputStream = 0
    text = text .. t
end

function love.update(dt)
    Networker.update(dt)
    local _, count = Networker:getChatHistory():gsub('\n', '\n')
    love.keyboard.setTextInput( true, text:len(), (count+2) * 24, 1, 1 )
end

-- Bascailly prints the chat log, a caret and whatever you are typing next to it.
function love.draw()
    --First, concat everything.
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
        love.graphics.print(Networker.getChatHistory() .. "\r\n>" .. text .. tostring(isIMEOpen), 4, 4)
    love.graphics.setColor(1, 1, 1, 1.0)
    love.graphics.setCanvas()
    love.graphics.draw(canvas,0,0, 0,2,2)
    --love.keyboard.setInput
end

function love.keypressed(key)

    if(key == "return") then --If you press enter, its treated as sending the message.
        --First check whether text is empty:
        if(isBlank(text)) then return end -- Just don't do anything
        if(queryMode == "server") then
            local serverAddr = string.gsub(text, "%s+", "") -- No space allowed!
            if(text:match("[%a*%d*%.*]+:%d+") == nil) then --Crude check for whether it is a pattern that looks like an ip address.
                Networker.writeChatHistory("This is not a valid server address. Try again.")
            else
                --Try connect, and if anything goes wrong...
                if(not pcall(function() Networker.establishConnection(text) end))then
                    Networker.disconnect("Failed to Connect: Unknown Error") --Honestly this hsould probably be handled better, but for this case, its fine.
                end
            end
        elseif(queryMode == "nick") then            --Sending a nick command
            local nickname = string.gsub(text, "^%s+", "") --No starting space
            nickname = string.gsub(nickname, "%s+$", "") --No trailing space
            Networker.sendMessage("nick", nickname)
            setQueryMode("msg")
        else
            --Just sending regular messages
            Networker.sendMessage("msg", text) --maybe trysend instead.. we'll talk about that later.
        end
        text = ""


    elseif(key == "backspace") then
        if(not isIMEOpen) then
            if(text == "" or text == nil) then text = "" return
            else text = sub(text,1,-2) end
        end
        inputStream = inputStream - 1
        if(inputStream <= 0) then
            isIMEOpen = false
            inputStream = 0
        end
    end
    if(key:len() == 1) then
        inputStream = inputStream + 1
    end
    print(inputStream)
end

function isBlank(s)
    return s == nil or s:match("%S") == nil
end

-- Query mode: server, nickname, anything else
-- Server: bascially ask for a server address
-- Nickname: after connect to the server, ask for the nickname
-- anything else: for sending message to other people.
function setQueryMode(mode)
    queryMode = mode
end

--UTF8 support
--This code is found online, I have no idea how it works :/
-- But without this, trying to delete any utf-8 characters will cause an error.
function sub(s,i,j)
    i=utf8.offset(s,i)
    j=utf8.offset(s,j+1)-1
    return string.sub(s,i,j)
end

--Somehow textedited is called one more time after thigns end.
function love.textedited(txt,start,length)
    isIMEOpen = ((txt:len() > 0) or inputStream > 0)
end