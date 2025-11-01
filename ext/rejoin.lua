local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local ServerHop = {}

-- Get servers safely
function ServerHop:GetServers()
    local servers = {}
    local cursor
    repeat
        local success, response = pcall(function()
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s"):format(game.PlaceId, cursor and "&cursor="..cursor or "")
            return HttpService:GetAsync(url)
        end)
        if not success then break end

        local data = HttpService:JSONDecode(response)
        for _, server in ipairs(data.data) do
            if server.playing < server.maxPlayers then
                table.insert(servers, server)
            end
        end
        cursor = data.nextPageCursor
    until not cursor
    return servers
end

-- Hop to random server
function ServerHop:RandomServerHop()
    local servers = self:GetServers()
    if #servers == 0 then return end
    local randomServer = servers[math.random(1, #servers)]
    TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer.id, LocalPlayer)
end

-- Rejoin same server
function ServerHop:RejoinSameServer()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

return ServerHop
