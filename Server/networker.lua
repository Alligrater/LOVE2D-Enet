--- Copyright (C) 2020 Alligrater
--- This piece of software follows the MIT license. See LICENSE for detail.

local running = true
local enet = require "enet"
local host, connection
local connectedPeers = {

}
local Networker = {}
local serverTime = 0

function Networker.startServer(port)
    enet = require "enet"
    host = enet.host_create("*:" .. port)
end

function Networker.update(dt)
    serverTime = serverTime + dt

    -- Similar to the client side:
    -- For each event in the event queue, service it, until there are no more events to be found.
    -- Service is responsible for handling both in and out, which tricked me a bit in the first place.
    -- You can think of this as reading files using fgetc() in c, where you will continue to read, until there's nothing to read.

    local event = host:service()
    while event do
        if(event.type == "connect") then
            Networker.onConnect(event)
        elseif(event.type == "disconnect") then
            Networker.onDisconnect(event)
        elseif(event.type == "receive") then
            Networker.onReceive(event)
        end
        event = host:service()
    end
end

--- For sending packets out ---

function Networker.broadcast(...)
    local arg = {...}
    local message = ""
    for i,v in ipairs(arg) do
        message = message .. tostring(v)
        if(i ~= #arg) then
            message = message .. "\r\n"
        end
    end
    host:broadcast(message) -- By this point, the message is only queued. To send it, we need to call host:service()
                             -- (Which, is called in Networker.update())
end

--- For server side, sending message requires a target, unless you are broadcasting
--- So we also keep track of the peer info.
function Networker.sendMessage(peer, ...)
    local message = ""
    local arg = {...}
    for i,v in ipairs(arg) do
        message = message .. tostring(v)
        if(i ~= #arg) then
            message = message .. "\r\n"
        end
    end
    peer:send(message)    --Queue a message
end

--- For getting packets in ---

function Networker.onReceive(event)
    -- Data sent from the client has two parts: the type of the message, and the message body. Each part is separated by a carriage return.
    local eventData = Networker.parseEventData(event.data)
    if(eventData[1] == "msg") then --If the server receives a message from the client
        if(#eventData >= 2) then
            Networker.broadcast("msg", connectedPeers[event.peer].nick, eventData[2]) --Broadcast what has been sent
            print(connectedPeers[event.peer].nick .. ":" .. eventData[2])
        end
    elseif(eventData[1] == "nick") then --Change user nickname
        if(#eventData >= 2) then --
            connectedPeers[event.peer].nick = eventData[2]
            Networker.broadcast("msg", "[Server]", "Welcome to the Chat Server, " .. eventData[2] .. "!") --The nick is only set when login, so ...
            print("User ", event.peer, "'s Nickname is ", eventData[2], "!")
        end
    end
    connectedPeers[event.peer].last_seen = serverTime
end

function Networker.onConnect(event)
    print("Peer connected:", event.peer)
    connectedPeers[event.peer] = {
        --addr = event.peer,
        last_seen = serverTime, --The last time that the user send a message
        nick = "Canary#" .. math.random(1000, 9999) -- Just give him a random nick, in case anything goes wrong.
                                                            -- Usually it won't
    }
end

function Networker.onDisconnect(event)
    print("Peer disconnected:", event.peer)
    connectedPeers[event.peer] = nil --This will remove him from the table.
end

--- Helper Functions ---
function Networker.parseEventData(data)
    --Parse the data with ",". We only need to know the first two I assume?
    result = {};
    for match in (data.."\r\n"):gmatch("(.-)".."\r\n") do
        table.insert(result, match);
    end
    return result;
end

return Networker