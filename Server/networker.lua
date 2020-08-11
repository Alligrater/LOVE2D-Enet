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
    host:broadcast(message)
    --host:service()
    --print("Host -> All Peers: " .. message )
end

function Networker.sendMessage(peer, ...)
    --if(not connection) then return end
    local message = ""
    local arg = {...}
    for i,v in ipairs(arg) do
        message = message .. tostring(v)
        if(i ~= #arg) then
            message = message .. "\r\n"
        end
    end
    peer:send(message)    --Queue a message
    --host:service()    --Send it. Enet you little bad boi it took me so long to figure out how to send you correctly
end

--- For getting packets in ---

function Networker.onReceive(event)
    --print(event.peer, "-> Host:" .. event.data)
    local eventData = Networker.parseEventData(event.data)
    if(eventData[1] == "msg") then --If the server receives a message from the client
        if(#eventData >= 2) then
            Networker.broadcast("msg", connectedPeers[event.peer].nick, eventData[2]) --Broadcast what has been sent
            print(connectedPeers[event.peer].nick .. ":" .. eventData[2])
        end
    elseif(eventData[1] == "nick") then --Change user nickname
        if(#eventData >= 2) then
            --Networker.broadcast("msg\r\n" .. eventData[2]) --Broadcast what has been sent
            connectedPeers[event.peer].nick = eventData[2]
            Networker.broadcast("msg", "[Server]", "Welcome to the Chat Server, " .. eventData[2] .. "!")
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
        nick = "Canary#" .. math.random(1000, 9999)
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