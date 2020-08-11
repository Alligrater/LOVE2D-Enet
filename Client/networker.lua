
local enet = require "enet"
local host, peer_host
local connection = false
local server
local Networker = {}
local chatHistory = --"JunkChat ver@1.0.1\nCreated by Alligrater\nPlease Enter Your Server Address: "
[[
JNK CHAT
Copyright (C) Alligrater 2020
Please Enter Your Server Address:]]



function Networker.establishConnection(addr)
    --if(connection) then return end -- Do not connect twice
    Networker.writeChatHistory("Connecting to " .. addr .. "...")
    host = enet.host_create()
    peer_host = host:connect(addr)

    connection = false
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
    if not connection then return end
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
---
function Networker.sendMessage(...)
    if(not connection) then return end
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
    --host:service() --Send it.
end

--- For getting things back in ---

function Networker.onMessage(event)
    if(event.type == "receive") then
        local data = Networker.parseEventData(event.data)
        if(#data >= 3) then
            Networker.writeChatHistory(data[2] .. ":" .. data[3])
        end
    end
end



function Networker.parseEventData(data)
    --Parse the data with ",". We only need to know the first two I assume?
    result = {};
    for match in (data.."\r\n"):gmatch("(.-)".."\r\n") do
        table.insert(result, match);
    end
    return result;
end

function Networker.getChatHistory()
    return chatHistory
end

function Networker.writeChatHistory(msg)
    --local arg = {...}
    chatHistory = chatHistory .. "\r\n" .. msg
end

function Networker.disconnect(reason)
    Networker.writeChatHistory(reason)
    if(peer_host) then peer_host:disconnect() end
    if(host) then host:flush() end
    setQueryMode("server")
    Networker.writeChatHistory("Please Enter Your Server Address:")
end

return Networker