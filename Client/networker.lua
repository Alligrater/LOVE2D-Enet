--- Copyright (C) 2020 Alligrater
--- This piece of software follows the MIT license. See LICENSE for detail.

local enet = require "enet"
local host, peer_host
local connection = false
local server
local Networker = {}
local chatHistory =
[[
JNK CHAT
Copyright (C) Alligrater 2020
Please Enter Your Server Address:]]
-- Populate the text field so the user knows what to do next...?


function Networker.establishConnection(addr)
    Networker.writeChatHistory("Connecting to " .. addr .. "...")
    host = enet.host_create()
    peer_host = host:connect(addr)

    connection = false
    -- Gonna wait for a maximum of 5 seconds before failing and disconnecting.
    -- This piece of code is generally the same as the code found on the love2d enet tutorial and enet-lua tutorial
    local timeWaited = 0
    while not connection and timeWaited < 5000 do
        local event = host:service(5000)
        if event then
            if event.type == "connect" then
                Networker.writeChatHistory("Connected to " .. addr)
                server = event.peer
                connection = true
            end
        else
            timeWaited = timeWaited + 5000
        end
    end

    if(not connection) then
        Networker.writeChatHistory("Failed to Connect: Time Out")
        peer_host:disconnect()
        host:flush()
    else
        Networker.writeChatHistory("Please Enter Your Nickname:")
        setQueryMode("nick")
    end
end

function Networker.update(dt)
    --Update is called whenever love.update is called.
    if not connection then return end

    -- For each event in the event queue, service it, until there are no more events to be found.
    -- Service is responsible for handling both in and out, which tricked me a bit in the first place.
    -- You can think of this as reading files using fgetc() in c, where you will continue to read, until there's nothing to read.

    local event = host:service()
    while event do
        if(event.type == "receive") then
            --print(event.peer, "-> Host:", event.data)
            Networker.onMessage(event)
        elseif(event.type == "disconnect") then
            Networker.disconnect("Disconnected: Server Closed")
        end
        event = host:service()
    end
end

--- For sending things out ---
--- Consider the message made with 2 parts: a type, and the message body.
--- The parts are separated by a carriage return. There's probably better ways like json to do it? I don't know.
function Networker.sendMessage(...)
    if(not connection) then return end
    -- Just concatenating the message with the carriage returns
    local arg = {...}
    local message = ""
    for i,v in ipairs(arg) do
        message = message .. tostring(v)
        if(i ~= #arg) then
            message = message .. "\r\n"
        end
    end

    print("Host ->", server, ":" .. message )
    server:send(message)  --Queue a message
end

--- For getting things back in ---
--- The message sent from the server has 3 parts:
--- message type (it will always be msg, maybe i can add something to it?)
--- the sender's nickname
--- the message body
--- Basically just concatenate everything in the format you wish.
function Networker.onMessage(event)
    if(event.type == "receive") then
        local data = Networker.parseEventData(event.data)
        if(#data >= 3) then
            Networker.writeChatHistory(data[2] .. ":" .. data[3])
        end
    end
end

--- parse all \r\n symbols. This code is found online.
function Networker.parseEventData(data)
    result = {};
    for match in (data.."\r\n"):gmatch("(.-)".."\r\n") do
        table.insert(result, match);
    end
    return result;
end

function Networker.disconnect(reason)
    Networker.writeChatHistory(reason)
    if(peer_host) then peer_host:disconnect() end --These can be nil, if your connection failes on the first step
    if(host) then host:flush() end
    setQueryMode("server")
    Networker.writeChatHistory("Please Enter Your Server Address:")
end

function Networker.getChatHistory()
    return chatHistory
end

function Networker.writeChatHistory(msg)
    --local arg = {...}
    chatHistory = chatHistory .. "\r\n" .. msg
end

return Networker