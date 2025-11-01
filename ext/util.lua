local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    ContextActionService = game:GetService("ContextActionService"),
    TweenService = game:GetService("TweenService"),
    MarketplaceService = game:GetService("MarketplaceService"),
    GuiService = game:GetService("GuiService"),
    SoundService = game:GetService("SoundService"),
    CollectionService = game:GetService("CollectionService"),
    PathfindingService = game:GetService("PathfindingService"),
    LocalizationService = game:GetService("LocalizationService"),
    BadgeService = game:GetService("BadgeService"),
    TeleportService = game:GetService("TeleportService"),
    TextService = game:GetService("TextService"),
    AnalyticsService = game:GetService("AnalyticsService"),
    Lighting = game:GetService("Lighting"),

    LocalPlayer = game:GetService("Players").LocalPlayer,
    Camera = workspace.CurrentCamera
}

local http_service = game:GetService("HttpService")
local connections = {}
local signal = {} -- Replace with your signal implementation if needed

local utility = {}

-- // Core Functions
utility.get_xmr_price = LPH_NO_VIRTUALIZE(function()
    local data = game:HttpGet("https://api.coincap.io/v2/assets/monero")
    local table_data = http_service:JSONDecode(data)
    return math.floor(tonumber(table_data.data.priceUsd) or 0)
end)

utility.world_to_screen = LPH_NO_VIRTUALIZE(function(position)
    local screen_pos, on_screen = Services.Camera:WorldToViewportPoint(position)
    return {
        position = Vector2.new(screen_pos.X, screen_pos.Y),
        on_screen = on_screen
    }
end)

utility.get_ping = LPH_NO_VIRTUALIZE(function()
    return Services.LocalPlayer:FindFirstChild("Stats") and
               Services.LocalPlayer.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() or
               0
end)

utility.has_character = LPH_NO_VIRTUALIZE(function(player)
    return player and player.Character and
               player.Character:FindFirstChild("Humanoid") ~= nil
end)

utility.new_connection = function(type, callback)
    local connection = type:Connect(callback)
    table.insert(connections, connection)
    return connection
end

utility.create_connection = function(signal_name)
    local connection = signal.new(signal_name)
    return connection
end

utility.is_in_air = LPH_NO_VIRTUALIZE(function(player)
    if not utility.has_character(player) then return false end
    local root_part = player.Character.HumanoidRootPart
    return root_part.Velocity.Y ~= 0
end)

utility.is_friends_with = LPH_NO_VIRTUALIZE(function(player)
    return player:IsFriendsWith(Services.LocalPlayer.UserId)
end)

utility.is_player_behind_a_wall = LPH_NO_VIRTUALIZE(function(player)
    local amount = Services.Camera:GetPartsObscuringTarget({
        Services.LocalPlayer.Character.HumanoidRootPart.Position,
        player.Character.HumanoidRootPart.Position
    }, {Services.LocalPlayer.Character, player.Character})
    return #amount ~= 0
end)

utility.drawing_new = function(type, properties)
    local obj = Drawing.new(type)
    for property, value in pairs(properties) do obj[property] = value end
    return obj
end

utility.instance_new = function(type, properties)
    local instance = Instance.new(type)
    for property, value in pairs(properties) do instance[property] = value end
    return instance
end

utility.generate_random_string = function(length)
    local characters =
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local str = ""
    for i = 1, length do
        str = str ..
                  characters:sub(math.random(1, #characters),
                                 math.random(1, #characters))
    end
    return str
end

utility.is_player_black = LPH_NO_VIRTUALIZE(function(player)
    if not utility.has_character(player) then return false end
    local head = player.Character.Head
    local h, _, _ = Color3.toHSV(head.Color)
    return h >= 0 and h <= 0.1
end)

utility.play_sound = LPH_NO_VIRTUALIZE(function(volume, sound_id)
    local sound = Instance.new("Sound")
    sound.Parent = workspace
    sound.SoundId = sound_id
    sound.Volume = volume
    sound:Play()
    utility.new_connection(sound.Ended, function() sound:Destroy() end)
end)

utility.clone_character = function(player, transparency, color, material,
                                   delete_hrp)
    local delete_hrp = delete_hrp ~= false
    player.Character.Archivable = true
    local new_character = player.Character:Clone()
    new_character.Parent = workspace
    player.Character.Archivable = false

    for _, part in ipairs(new_character:GetChildren()) do
        if part:IsA("MeshPart") then
            part.Anchored = true
            part.CanCollide = false
            part.Color = color
            part.Material = Enum.Material[material]
            part.Transparency = transparency
        else
            if part.Name ~= "HumanoidRootPart" and delete_hrp then
                part:Destroy()
            end
        end
        if part.Name == "Head" then
            local decal = part:FindFirstChild("face")
            if decal then decal:Destroy() end
        end
    end

    return new_character
end

-- // Beam and Impact
utility.create_beam = LPH_NO_VIRTUALIZE(function(from, to, color_1, color_2,
                                                 duration, fade_enabled,
                                                 fade_duration)
    local tween
    local total_time = 0

    local main_part = utility.instance_new("Part", {
        Parent = workspace,
        Size = Vector3.new(0, 0, 0),
        Massless = true,
        Transparency = 1,
        CanCollide = false,
        Position = from,
        Anchored = true
    })

    local part0 = utility.instance_new("Part", {
        Parent = main_part,
        Size = Vector3.new(0, 0, 0),
        Massless = true,
        Transparency = 1,
        CanCollide = false,
        Position = from,
        Anchored = true
    })
    local part1 = utility.instance_new("Part", {
        Parent = main_part,
        Size = Vector3.new(0, 0, 0),
        Massless = true,
        Transparency = 1,
        CanCollide = false,
        Position = to,
        Anchored = true
    })
    local attachment0 = utility.instance_new("Attachment", {Parent = part0})
    local attachment1 = utility.instance_new("Attachment", {Parent = part1})

    local beam = utility.instance_new("Beam", {
        Texture = "rbxassetid://446111271",
        TextureMode = Enum.TextureMode.Wrap,
        TextureLength = 10,
        LightEmission = 1,
        LightInfluence = 1,
        FaceCamera = true,
        ZOffset = -1,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)
        }),
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color_1),
            ColorSequenceKeypoint.new(1, color_2)
        }),
        Attachment0 = attachment0,
        Attachment1 = attachment1,
        Enabled = true,
        Parent = main_part
    })

    if fade_enabled then
        tween = utility.new_connection(Services.RunService.Heartbeat,
                                       function(dt)
            total_time = total_time + dt
            beam.Transparency = NumberSequence.new(
                                    Services.TweenService:GetValue(total_time /
                                                                       fade_duration,
                                                                   Enum.EasingStyle
                                                                       .Quad,
                                                                   Enum.EasingDirection
                                                                       .In))
        end)
    end

    task.delay(duration, function()
        main_part:Destroy()
        if tween then tween:Disconnect() end
    end)
end)

utility.create_impact = function(color, size, fade_enabled, fade_duration,
                                 duration, position)
    local impact = utility.instance_new("Part", {
        CanCollide = false,
        Material = Enum.Material.Neon,
        Size = Vector3.new(size, size, size),
        Color = color,
        Position = position,
        Anchored = true,
        Parent = workspace
    })

    local outline = utility.instance_new("SelectionBox", {
        LineThickness = 0.01,
        Color3 = color,
        SurfaceTransparency = 1,
        Adornee = impact,
        Visible = true,
        Parent = impact
    })

    if fade_enabled then
        local tween_info = TweenInfo.new(duration)
        local tween = Services.TweenService:Create(impact, tween_info,
                                                   {Transparency = 1})
        local tween_outline = Services.TweenService:Create(outline, tween_info,
                                                           {Transparency = 1})
        tween:Play()
        tween_outline:Play()
    end

    task.delay(duration, function() impact:Destroy() end)
end

return utility
