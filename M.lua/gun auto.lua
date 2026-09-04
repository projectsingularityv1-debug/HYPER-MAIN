local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

pcall(function()
    LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoomless
    LocalPlayer.CameraMode = Enum.CameraMode.Classic
end)

local robbedBanks = {}

local function getBankState(bank)
    local laserDisabler = bank:FindFirstChild("LaserDisabler")
    if laserDisabler then
        local main = laserDisabler:FindFirstChild("Main")
        if main then
            local color = main.Color
            local r = math.round(color.R * 255)
            local g = math.round(color.G * 255)
            local b = math.round(color.B * 255)
            
            if (r == 255 and g == 0 and b == 0) then
                return "READY", main
            elseif (r == 0 and g == 170 and b == 0) then
                return "ROBBABLE", main
            else
                return "COOLDOWN", main
            end
        end
    end
    return "NONE", nil
end

local function getBanks()
    local banks = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "Bank" then
            table.insert(banks, child)
            local state, main = getBankState(child)
            if state == "COOLDOWN" or state == "NONE" then
                robbedBanks[child] = nil
            end
        end
    end
    return banks
end

local function flyTo(targetCFrame)
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end
    
    humanoid.PlatformStand = true
    
    local oldBv = hrp:FindFirstChild("GhostFlyVelocity")
    if oldBv then oldBv:Destroy() end
    local oldBg = hrp:FindFirstChild("GhostFlyGyro")
    if oldBg then oldBg:Destroy() end
    
    local bv = Instance.new("BodyVelocity")
    bv.Name = "GhostFlyVelocity"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp
    
    local bg = Instance.new("BodyGyro")
    bg.Name = "GhostFlyGyro"
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.P = 3000
    bg.D = 500
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp
    
    local speed = getgenv().FlySpeed or 100
    local flying = true
    local startTime = tick()
    local startDist = (targetCFrame.Position - hrp.Position).Magnitude
    local timeout = (startDist / speed) + 5
    
    local steppedConn = RunService.Stepped:Connect(function()
        if not flying then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
    
    while flying and char and hrp.Parent and getgenv().AutoRobBank do
        local dist = (targetCFrame.Position - hrp.Position).Magnitude
        if dist < 5 or (tick() - startTime) > timeout then
            flying = false
            break
        end
        
        local dir = (targetCFrame.Position - hrp.Position).Unit
        bv.Velocity = dir * speed
        bg.CFrame = CFrame.new(hrp.Position, targetCFrame.Position)
        
        task.wait()
    end
    
    if steppedConn then steppedConn:Disconnect() end
    if bv then bv:Destroy() end
    if bg then bg:Destroy() end
    
    if humanoid then humanoid.PlatformStand = false end
    if hrp then 
        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
    end
end

local Library = nil
local env = (getgenv and getgenv()) or _G

if env.HYPER_UI and type(env.HYPER_UI) == "table" and env.HYPER_UI.Window then
    Library = env.HYPER_UI
elseif env.Library and type(env.Library) == "table" and env.Library.Window then
    Library = env.Library
else
    local ok, res = pcall(function()
        -- 1. Local files first (0ms, offline support)
        if typeof(isfile) == "function" and typeof(readfile) == "function" then
            local paths = {
                "ui.lua",
                "UI.main/ui.lua",
                "Scripts/UI.main/ui.lua",
                "Scripts/ui.lua",
                "HYPER_Cache/ui.lua"
            }
            for _, p in ipairs(paths) do
                if isfile(p) then
                    local fn = loadstring(readfile(p))
                    if fn then
                        local lib = fn()
                        if type(lib) == "table" and lib.Window then return lib end
                    end
                end
            end
        end

        -- 2. Online endpoints with fallback
        local urls = {
            "https://raw.githubusercontent.com/projectsingularityv1-debug/HYPER-LOADER/refs/heads/main/UI.main/ui.lua",
            "https://raw.githubusercontent.com/projectsingularityv1-debug/HYPER-LOADER/refs/heads/main/UI.main/ui.lua"
        }
        for _, u in ipairs(urls) do
            local s, src = pcall(function()
                local req = (request or http_request or (syn and syn.request) or (http and http.request))
                if req then
                    local r = req({ Url = u, Method = "GET" })
                    if r and r.StatusCode == 200 then return r.Body end
                end
                return game:HttpGet(u)
            end)
            if s and src and #src > 0 then
                local fn = loadstring(src)
                if fn then
                    local lib = fn()
                    if type(lib) == "table" and lib.Window then
                        if typeof(writefile) == "function" then
                            pcall(function() writefile("HYPER_Cache/ui.lua", src) end)
                        end
                        return lib
                    end
                end
            end
        end
        return nil
    end)

    if ok and type(res) == "table" and res.Window then
        Library = res
        env.HYPER_UI = Library
    else
        error("[Singularity] Failed to load UI Library from all local and remote endpoints!")
    end
end
local UIS = game:GetService("UserInputService")
local WindowSize = UIS.TouchEnabled and UDim2.fromOffset(550, 550) or UDim2.fromOffset(570,450)


local KeyAvatarURL = getgenv().KeyAvatar

-- Attempt to read saved key if no KeyAvatar is provided
if not KeyAvatarURL then
    pcall(function()
        if isfile and isfile("SingularityKey.txt") then
            local savedKey = readfile("SingularityKey.txt")
            if savedKey and savedKey ~= "" then
                local rbx_user = game:GetService("Players").LocalPlayer.Name
                local rbx_id = game:GetService("Players").LocalPlayer.UserId
                
                local url = "https://projectsingularity.online/raw/verify-key?k=" .. savedKey .. "&rbx_user=" .. rbx_user .. "&rbx_id=" .. tostring(rbx_id)
                local req = (request or http_request or (syn and syn.request) or (http and http.request))
                
                local responseJson = nil
                if req then
                    local res = req({
                        Url = "https://projectsingularity.online/raw/verify-key",
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = game:GetService("HttpService"):JSONEncode({ key = savedKey, rbx_user = rbx_user, rbx_id = rbx_id })
                    })
                    responseJson = game:GetService("HttpService"):JSONDecode(res.Body)
                else
                    responseJson = game:GetService("HttpService"):JSONDecode(game:HttpGet(url))
                end

                if responseJson and responseJson.valid and responseJson.profile then
                    getgenv().KeyUsername = responseJson.profile.username
                    local rawAvatar = responseJson.profile.avatar_url
                    
                    if rawAvatar and rawAvatar ~= "" then
                        KeyAvatarURL = rawAvatar
                    end
                end
            end
        end
    end)
end

if not KeyAvatarURL or KeyAvatarURL == "" then
    KeyAvatarURL = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(game:GetService("Players").LocalPlayer.UserId) .. "&w=150&h=150"
end

local Window = Library:Window({
    Title = "HYPER HUB",
    Desc = "Auto Bank Robbery",
    Version = "1.0",
    Icon = 115975178132422,
    Theme = "Amethyst",
    Config = {
        Keybind = Enum.KeyCode.RightShift,
        Size = WindowSize
    },
    CloseUIButton = {
        Enabled = true,
        Text = "Close"
    },
    Profile = {
        Username = getgenv().KeyUsername or "N/A",
        Email = "UID: " .. tostring(game:GetService("Players").LocalPlayer.UserId),
        AvatarUrl = KeyAvatarURL
    }
})

-- ============================================
-- CONFIGURATION MANAGER (AUTO SAVE & LOAD)
-- ============================================
local HttpService = game:GetService("HttpService")
local CONFIG_FILE = "Singularity_CaliShootout_Config.json"

local DefaultConfig = {
    -- Auto Farm
    AutoRobBank = false,
    AutoServerHop = false,
    FastCollect = true,
    FlySpeed = 150,

    -- Player
    GhostFlyEnabled = false,
    GhostFlySpeed = 50,
    GhostFlyNoclip = true,
    GodmodeEnabled = false,
    AntiFallDamage = true,

    -- ESP
    BankESP = false,
    PlayerESP = false,
    NameESP = true,
    HealthESP = true,
    ToolESP = true,
    DistESP = true,
    BoxESP = true,
    TracerESP = true,
    ESPStyle = "2D",
    ESPColorName = "Red",

    -- Aimbot
    aimbotEnabled = true,
    Toggle = false,
    teamCheck = false,
    wallCheck = true,
    lockMode = "Head",
    fov = 150,
    smoothing = 0.15,
    predictionFactor = 0.165,
    showFOV = true,
    fovFilled = false,

    -- Teleport & Orbit
    OrbitAttack = false,
    OrbitDistance = 15,
    OrbitSpeed = 3,
    OrbitHeight = 5,

    -- Whitelist & System
    Whitelist = {},
    AutoSave = true,
}

local ConfigState = {}
for k, v in pairs(DefaultConfig) do
    ConfigState[k] = v
end

local function LoadConfig()
    pcall(function()
        if isfile and isfile(CONFIG_FILE) then
            local content = readfile(CONFIG_FILE)
            if content and content ~= "" then
                local decoded = HttpService:JSONDecode(content)
                if type(decoded) == "table" then
                    for k, v in pairs(decoded) do
                        ConfigState[k] = v
                    end
                end
            end
        end
    end)

    getgenv().AutoRobBank = ConfigState.AutoRobBank
    getgenv().AutoServerHop = ConfigState.AutoServerHop
    getgenv().FastCollect = ConfigState.FastCollect
    getgenv().FlySpeed = ConfigState.FlySpeed
    
    getgenv().GhostFlyEnabled = ConfigState.GhostFlyEnabled
    getgenv().GhostFlySpeed = ConfigState.GhostFlySpeed
    getgenv().GhostFlyNoclip = ConfigState.GhostFlyNoclip
    getgenv().GodmodeEnabled = ConfigState.GodmodeEnabled
    getgenv().AntiFallDamage = ConfigState.AntiFallDamage
    
    getgenv().BankESP = ConfigState.BankESP
    getgenv().PlayerESP = ConfigState.PlayerESP
    getgenv().NameESP = ConfigState.NameESP
    getgenv().HealthESP = ConfigState.HealthESP
    getgenv().ToolESP = ConfigState.ToolESP
    getgenv().DistESP = ConfigState.DistESP
    getgenv().BoxESP = ConfigState.BoxESP
    getgenv().TracerESP = ConfigState.TracerESP
    getgenv().ESPStyle = ConfigState.ESPStyle
    getgenv().ESPColorName = ConfigState.ESPColorName or "Red"

    getgenv().OrbitAttack = ConfigState.OrbitAttack
    getgenv().OrbitDistance = ConfigState.OrbitDistance
    getgenv().OrbitSpeed = ConfigState.OrbitSpeed
    getgenv().OrbitHeight = ConfigState.OrbitHeight
end

LoadConfig()

local saveDebounce = false
local function SaveConfig()
    if not writefile then return end
    if not (ConfigState.AutoSave == nil or ConfigState.AutoSave == true) then return end
    if saveDebounce then return end
    saveDebounce = true
    task.delay(0.4, function()
        pcall(function()
            ConfigState.AutoRobBank = getgenv().AutoRobBank
            ConfigState.AutoServerHop = getgenv().AutoServerHop
            ConfigState.FastCollect = getgenv().FastCollect
            ConfigState.FlySpeed = getgenv().FlySpeed

            ConfigState.GhostFlyEnabled = getgenv().GhostFlyEnabled
            ConfigState.GhostFlySpeed = getgenv().GhostFlySpeed
            ConfigState.GhostFlyNoclip = getgenv().GhostFlyNoclip
            ConfigState.GodmodeEnabled = getgenv().GodmodeEnabled
            ConfigState.AntiFallDamage = getgenv().AntiFallDamage

            ConfigState.BankESP = getgenv().BankESP
            ConfigState.PlayerESP = getgenv().PlayerESP
            ConfigState.NameESP = getgenv().NameESP
            ConfigState.HealthESP = getgenv().HealthESP
            ConfigState.ToolESP = getgenv().ToolESP
            ConfigState.DistESP = getgenv().DistESP
            ConfigState.BoxESP = getgenv().BoxESP
            ConfigState.TracerESP = getgenv().TracerESP
            ConfigState.ESPStyle = getgenv().ESPStyle
            ConfigState.ESPColorName = getgenv().ESPColorName or "Red"

            if AimbotSettings then
                ConfigState.aimbotEnabled = AimbotSettings.aimbotEnabled
                ConfigState.Toggle = AimbotSettings.Toggle
                ConfigState.teamCheck = AimbotSettings.teamCheck
                ConfigState.wallCheck = AimbotSettings.wallCheck
                ConfigState.lockMode = AimbotSettings.lockMode
                ConfigState.fov = AimbotSettings.fov
                ConfigState.smoothing = AimbotSettings.smoothing
                ConfigState.predictionFactor = AimbotSettings.predictionFactor
                ConfigState.showFOV = AimbotSettings.showFOV
                ConfigState.fovFilled = AimbotSettings.fovFilled
            end

            ConfigState.OrbitAttack = getgenv().OrbitAttack
            ConfigState.OrbitDistance = getgenv().OrbitDistance
            ConfigState.OrbitSpeed = getgenv().OrbitSpeed
            ConfigState.OrbitHeight = getgenv().OrbitHeight

            ConfigState.Whitelist = Whitelist

            writefile(CONFIG_FILE, HttpService:JSONEncode(ConfigState))
        end)
        saveDebounce = false
    end)
end

local FarmTab = Window:Tab({ Title = "Auto Farm", Icon = "zap" })
local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
local ESPTab = Window:Tab({ Title = "ESP", Icon = "eye" })
local AimbotTab = Window:Tab({ Title = "Aimbot", Icon = "crosshair" })
local WhitelistTab = Window:Tab({ Title = "Whitelist", Icon = "shield" })
local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "navigation" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- ============================================
-- AUTO SERVER HOP & TELEPORT PERSISTENCE
-- ============================================
local isHopping = false
local function serverHop()
    if isHopping then return end
    isHopping = true

    pcall(function()
        Window:Notify({
            Title = "Auto Server Hop",
            Desc = "Queueing script & finding new server...",
            Time = 6
        })
    end)

    local queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
    if queueteleport then
        queueteleport([[
            task.wait(3)
            pcall(function()
                loadstring(game:HttpGet("https://projectsingularity.online/raw/repos/191c9695-c9f9-4b5f-805f-d87e8e3b8fac/gun%20auto.lua"))()
            end)
        ]])
    end

    task.spawn(function()
        local placeId = game.PlaceId
        local currentJobId = game.JobId
        local serverListUrl = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Desc&limit=100"
        
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(serverListUrl))
        end)

        local targetJob = nil
        if success and result and result.data then
            local validServers = {}
            for _, s in ipairs(result.data) do
                if type(s) == "table" and s.id and s.id ~= currentJobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers and s.playing > 1 then
                    table.insert(validServers, s.id)
                end
            end
            if #validServers > 0 then
                targetJob = validServers[math.random(1, #validServers)]
            end
        end

        if targetJob then
            pcall(function()
                Window:Notify({
                    Title = "Server Found",
                    Desc = "Teleporting to server (" .. tostring(targetJob):sub(1, 8) .. ")...",
                    Time = 5
                })
            end)
            task.wait(1.5)
            TeleportService:TeleportToPlaceInstance(placeId, targetJob, LocalPlayer)
        else
            pcall(function()
                Window:Notify({
                    Title = "Server Hop",
                    Desc = "Connecting to new server instance...",
                    Time = 5
                })
            end)
            task.wait(1.5)
            TeleportService:Teleport(placeId, LocalPlayer)
        end
    end)
end

-- ============================================
-- GHOST FLY SYSTEM
-- ============================================
getgenv().GhostFlyKey = Enum.KeyCode.X

local ghostFlyVelocity = nil
local ghostFlyGyro = nil
local ghostRenderConn = nil
local ghostSteppedConn = nil

local ghostKeys = {
    W = false,
    A = false,
    S = false,
    D = false,
    Space = false,
    LeftShift = false
}

local function startGhostFly()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if humanoid then
        humanoid.PlatformStand = true
    end
    
    local oldBV = hrp:FindFirstChild("GhostFlyVelocity_Manual")
    if oldBV then oldBV:Destroy() end
    local oldBG = hrp:FindFirstChild("GhostFlyGyro_Manual")
    if oldBG then oldBG:Destroy() end

    ghostFlyVelocity = Instance.new("BodyVelocity")
    ghostFlyVelocity.Name = "GhostFlyVelocity_Manual"
    ghostFlyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    ghostFlyVelocity.Velocity = Vector3.new(0, 0, 0)
    ghostFlyVelocity.Parent = hrp
    
    ghostFlyGyro = Instance.new("BodyGyro")
    ghostFlyGyro.Name = "GhostFlyGyro_Manual"
    ghostFlyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    ghostFlyGyro.P = 3000
    ghostFlyGyro.D = 500
    ghostFlyGyro.CFrame = workspace.CurrentCamera.CFrame
    ghostFlyGyro.Parent = hrp
    
    if ghostRenderConn then ghostRenderConn:Disconnect() end
    ghostRenderConn = RunService.RenderStepped:Connect(function()
        if not getgenv().GhostFlyEnabled then return end
        local cam = workspace.CurrentCamera
        local moveDir = Vector3.new(0, 0, 0)
        
        if ghostKeys.W then moveDir = moveDir + cam.CFrame.LookVector end
        if ghostKeys.S then moveDir = moveDir - cam.CFrame.LookVector end
        if ghostKeys.A then moveDir = moveDir - cam.CFrame.RightVector end
        if ghostKeys.D then moveDir = moveDir + cam.CFrame.RightVector end
        
        local upDown = 0
        if ghostKeys.Space then upDown = upDown + 1 end
        if ghostKeys.LeftShift then upDown = upDown - 1 end
        
        moveDir = moveDir + Vector3.new(0, upDown, 0)
        
        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
        end
        
        if ghostFlyVelocity and ghostFlyVelocity.Parent then
            ghostFlyVelocity.Velocity = moveDir * (getgenv().GhostFlySpeed or 50)
        end
        if ghostFlyGyro and ghostFlyGyro.Parent then
            ghostFlyGyro.CFrame = cam.CFrame
        end
    end)
    
    if ghostSteppedConn then ghostSteppedConn:Disconnect() end
    ghostSteppedConn = RunService.Stepped:Connect(function()
        if not getgenv().GhostFlyEnabled then return end
        if getgenv().GhostFlyNoclip and character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function stopGhostFly()
    if ghostRenderConn then 
        ghostRenderConn:Disconnect() 
        ghostRenderConn = nil
    end
    if ghostSteppedConn then 
        ghostSteppedConn:Disconnect() 
        ghostSteppedConn = nil
    end
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bv = hrp:FindFirstChild("GhostFlyVelocity_Manual")
            if bv then bv:Destroy() end
            local bg = hrp:FindFirstChild("GhostFlyGyro_Manual")
            if bg then bg:Destroy() end
            
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
        end
    end
end

local function toggleGhostFly(state)
    getgenv().GhostFlyEnabled = state
    if state then
        stopGhostFly()
        startGhostFly()
        Window:Notify({Title = "Ghost Fly", Desc = "Ghost Fly Enabled (WASD + Space/Shift)", Time = 3})
    else
        stopGhostFly()
        Window:Notify({Title = "Ghost Fly", Desc = "Ghost Fly Disabled", Time = 3})
    end
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.W then ghostKeys.W = true end
    if input.KeyCode == Enum.KeyCode.A then ghostKeys.A = true end
    if input.KeyCode == Enum.KeyCode.S then ghostKeys.S = true end
    if input.KeyCode == Enum.KeyCode.D then ghostKeys.D = true end
    if input.KeyCode == Enum.KeyCode.Space then ghostKeys.Space = true end
    if input.KeyCode == Enum.KeyCode.LeftShift then ghostKeys.LeftShift = true end
    
    if input.KeyCode == (getgenv().GhostFlyKey or Enum.KeyCode.X) then
        toggleGhostFly(not getgenv().GhostFlyEnabled)
    end
end)

UIS.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.W then ghostKeys.W = false end
    if input.KeyCode == Enum.KeyCode.A then ghostKeys.A = false end
    if input.KeyCode == Enum.KeyCode.S then ghostKeys.S = false end
    if input.KeyCode == Enum.KeyCode.D then ghostKeys.D = false end
    if input.KeyCode == Enum.KeyCode.Space then ghostKeys.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then ghostKeys.LeftShift = false end
end)

-- ============================================
-- GODMODE SYSTEM
-- ============================================
getgenv().GodmodeEnabled = false
getgenv().AntiFallDamage = true

local godmodeConn = nil
local function applyGodmode(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    
    if godmodeConn then godmodeConn:Disconnect() godmodeConn = nil end
    
    if getgenv().GodmodeEnabled then
        godmodeConn = hum.HealthChanged:Connect(function(newHealth)
            if getgenv().GodmodeEnabled and newHealth < hum.MaxHealth and newHealth > 0 then
                hum.Health = hum.MaxHealth
            end
        end)
        
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        end)
    end
end

local function toggleGodmode(state)
    getgenv().GodmodeEnabled = state
    local char = LocalPlayer.Character
    if state then
        applyGodmode(char)
        Window:Notify({Title = "Godmode", Desc = "Godmode Enabled (Health Lock & Anti-Ragdoll)", Time = 3})
    else
        if godmodeConn then godmodeConn:Disconnect() godmodeConn = nil end
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function()
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                end)
            end
        end
        Window:Notify({Title = "Godmode", Desc = "Godmode Disabled", Time = 3})
    end
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    if getgenv().GodmodeEnabled then
        applyGodmode(newChar)
    end
end)


-- ============================================
-- AIMBOT SETTINGS & VARIABLES
-- ============================================
local AimbotSettings = {
    teamCheck = ConfigState.teamCheck,
    fov = ConfigState.fov,
    smoothing = ConfigState.smoothing,
    predictionFactor = ConfigState.predictionFactor,
    aimbotEnabled = ConfigState.aimbotEnabled,
    Toggle = ConfigState.Toggle,
    toggleKey = Enum.KeyCode.E,
    toggleKeyName = "E",
    lockMode = ConfigState.lockMode,
    wallCheck = ConfigState.wallCheck,
    maxWallDistance = 1000,
    showFOV = ConfigState.showFOV,
    fovFilled = ConfigState.fovFilled,
    fovThickness = 2,
    fovColor = Color3.fromRGB(255, 50, 50),
}

local Whitelist = (type(ConfigState.Whitelist) == "table" and ConfigState.Whitelist) or {}
local function isWhitelisted(player)
    local name = player.Name:lower()
    for _, wName in ipairs(Whitelist) do
        if wName:lower() == name then return true end
    end
    return false
end
local function addToWhitelist(name)
    name = name:match("^%s*(.-)%s*$")
    if name == "" then return false end
    local nameLower = name:lower()
    for _, wName in ipairs(Whitelist) do
        if wName:lower() == nameLower then return false end
    end
    table.insert(Whitelist, name)
    SaveConfig()
    return true
end
local function removeFromWhitelist(name)
    name = name:lower()
    for i, wName in ipairs(Whitelist) do
        if wName:lower() == name then
            table.remove(Whitelist, i)
            SaveConfig()
            return true
        end
    end
    return false
end

local currentTarget = nil
local aimbotToggleState = false
local aimbotCamera = workspace.CurrentCamera

local cachedRaycastParams = RaycastParams.new()
cachedRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
cachedRaycastParams.IgnoreWater = true

local cachedAimRaycastParams = RaycastParams.new()
cachedAimRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
cachedAimRaycastParams.IgnoreWater = true

local lastFilterCharacter = nil

local FOVring = Drawing.new("Circle")
FOVring.Visible = AimbotSettings.showFOV
FOVring.Thickness = AimbotSettings.fovThickness
FOVring.Radius = AimbotSettings.fov
FOVring.Transparency = 0.8
FOVring.Color = AimbotSettings.fovColor
FOVring.Filled = AimbotSettings.fovFilled
FOVring.Position = Vector2.new(aimbotCamera.ViewportSize.X / 2, aimbotCamera.ViewportSize.Y / 2)

local function isTargetVisible(targetPosition)
    if not AimbotSettings.wallCheck then return true end
    local origin = aimbotCamera.CFrame.Position
    local direction = (targetPosition - origin).Unit
    local distance = (targetPosition - origin).Magnitude

    if LocalPlayer.Character ~= lastFilterCharacter then
        lastFilterCharacter = LocalPlayer.Character
        if LocalPlayer.Character then
            cachedRaycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
            cachedAimRaycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        end
    end

    local result = workspace:Raycast(origin, direction * math.min(distance, AimbotSettings.maxWallDistance), cachedRaycastParams)
    if not result then return true end

    local hitPart = result.Instance
    if hitPart then
        local hitModel = hitPart:FindFirstAncestorOfClass("Model")
        if hitModel and Players:GetPlayerFromCharacter(hitModel) then
            return true
        end
        return false
    end
    return true
end

local function getTargetPart(player)
    if not player or not player.Character then return nil end
    local character = player.Character
    local mode = AimbotSettings.lockMode

    if mode == "Random" then
        local parts = {"Head","UpperTorso","HumanoidRootPart","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg"}
        local available = {}
        for _, name in ipairs(parts) do
            local p = character:FindFirstChild(name)
            if p then table.insert(available, p) end
        end
        if #available > 0 then return available[math.random(1, #available)] end
    end

    if mode == "Head" then return character:FindFirstChild("Head")
    elseif mode == "Torso" then return character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
    elseif mode == "LeftArm" then return character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("LeftLowerArm")
    elseif mode == "RightArm" then return character:FindFirstChild("RightUpperArm") or character:FindFirstChild("RightLowerArm")
    elseif mode == "LeftLeg" then return character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("LeftLowerLeg")
    elseif mode == "RightLeg" then return character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("RightLowerLeg")
    end

    return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

local function getClosestPlayer()
    if not AimbotSettings.aimbotEnabled then return nil end
    if not LocalPlayer.Character then return nil end

    local closestPlayer = nil
    local closestDistance = AimbotSettings.fov
    local screenCenter = Vector2.new(aimbotCamera.ViewportSize.X / 2, aimbotCamera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if AimbotSettings.teamCheck and player.Team == LocalPlayer.Team then continue end
        if isWhitelisted(player) then continue end

        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChild("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not (humanoid and hrp) then continue end
        if humanoid.Health <= 0 then continue end

        local screenPosition, onScreen = aimbotCamera:WorldToViewportPoint(hrp.Position)
        if not onScreen then continue end

        local screenPos = Vector2.new(screenPosition.X, screenPosition.Y)
        local distance = (screenPos - screenCenter).Magnitude

        if distance <= closestDistance then
            if AimbotSettings.wallCheck and not isTargetVisible(hrp.Position) then continue end
            closestDistance = distance
            closestPlayer = player
        end
    end
    return closestPlayer
end

local function getTargetPosition(player)
    if not player or not player.Character then return nil end
    local targetPart = getTargetPart(player)
    if not targetPart then return nil end
    if AimbotSettings.wallCheck and not isTargetVisible(targetPart.Position) then
        return nil
    end
    local velocity = targetPart.AssemblyLinearVelocity
    local distance = (targetPart.Position - aimbotCamera.CFrame.Position).Magnitude
    local travelTime = distance / 1000
    return targetPart.Position + (velocity * travelTime * AimbotSettings.predictionFactor)
end

local function aimAtPosition(targetPosition)
    if not targetPosition or not LocalPlayer.Character then return end
    local currentCF = aimbotCamera.CFrame
    local direction = (targetPosition - currentCF.Position).Unit

    if AimbotSettings.wallCheck then
        local result = workspace:Raycast(currentCF.Position, direction * 100, cachedAimRaycastParams)
        if result and result.Instance then
            local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
            if not Players:GetPlayerFromCharacter(hitModel) then return end
        end
    end

    local newCF = CFrame.new(currentCF.Position, currentCF.Position + direction)
    aimbotCamera.CFrame = currentCF:Lerp(newCF, AimbotSettings.smoothing)
end

local function updateAimbot()
    if not AimbotSettings.aimbotEnabled then currentTarget = nil; return end
    if AimbotSettings.Toggle and not aimbotToggleState then currentTarget = nil; return end

    local keepTarget = false
    if currentTarget and currentTarget.Character then
        local humanoid = currentTarget.Character:FindFirstChild("Humanoid")
        local hrp = currentTarget.Character:FindFirstChild("HumanoidRootPart")
        if humanoid and hrp and humanoid.Health > 0 then
            local _, onScreen = aimbotCamera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                if AimbotSettings.wallCheck then
                    keepTarget = isTargetVisible(hrp.Position)
                else
                    keepTarget = true
                end
            end
        end
    end

    if not keepTarget then
        currentTarget = getClosestPlayer()
    end

    if currentTarget then
        local targetPosition = getTargetPosition(currentTarget)
        if targetPosition then
            aimAtPosition(targetPosition)
        else
            currentTarget = nil
        end
    end
end

-- ============================================
-- AIMBOT UI SETUP
-- ============================================
AimbotTab:Section({Title = "Main Settings"})

AimbotTab:Toggle({
    Title = "Enable Aimbot",
    Desc = "Enable Aimbot",
    Value = AimbotSettings.aimbotEnabled,
    Callback = function(v) 
        AimbotSettings.aimbotEnabled = v 
        SaveConfig()
    end
})

AimbotTab:Toggle({
    Title = "Keybind Mode",
    Desc = "Use key to toggle",
    Value = AimbotSettings.Toggle,
    Callback = function(v) 
        AimbotSettings.Toggle = v 
        SaveConfig()
    end
})

AimbotTab:Keybind({
    Title = "Target Key",
    Desc = "Aimbot toggle keybind",
    Key = AimbotSettings.toggleKey,
    Value = aimbotToggleState,
    Callback = function(val, key)
        AimbotSettings.toggleKey = key
        if AimbotSettings.Toggle then
            aimbotToggleState = val
            Window:Notify({Title = "Aimbot", Desc = aimbotToggleState and "ACTIVATED" or "DEACTIVATED", Time = 2})
        end
    end
})

AimbotTab:Section({Title = "Targeting Rules"})

AimbotTab:Toggle({
    Title = "Team Check", 
    Desc = "Don't aim at teammates", 
    Value = AimbotSettings.teamCheck, 
    Callback = function(v) 
        AimbotSettings.teamCheck = v 
        SaveConfig()
    end
})

AimbotTab:Toggle({
    Title = "Wall Check", 
    Desc = "Wall check", 
    Value = AimbotSettings.wallCheck, 
    Callback = function(v) 
        AimbotSettings.wallCheck = v 
        SaveConfig()
    end
})

AimbotTab:Dropdown({
    Title = "Target Part",
    Desc = "Target part to aim",
    List = {"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Random"},
    Value = AimbotSettings.lockMode,
    Callback = function(choice) 
        AimbotSettings.lockMode = choice 
        SaveConfig()
    end
})

AimbotTab:Section({Title = "Accuracy & Prediction"})

AimbotTab:Slider({
    Title = "FOV Radius", 
    Desc = "Aimbot FOV radius", 
    Min = 50, 
    Max = 300, 
    Rounding = 0, 
    Value = AimbotSettings.fov,
    Callback = function(val) 
        AimbotSettings.fov = val 
        FOVring.Radius = val 
        SaveConfig()
    end
})

AimbotTab:Slider({
    Title = "Smoothness", 
    Desc = "Aimbot smoothing (lower is faster)", 
    Min = 1, 
    Max = 50, 
    Rounding = 0, 
    Value = AimbotSettings.smoothing * 100,
    Callback = function(val) 
        AimbotSettings.smoothing = val / 100 
        SaveConfig()
    end
})

AimbotTab:Slider({
    Title = "Prediction", 
    Desc = "Target prediction", 
    Min = 0, 
    Max = 30, 
    Rounding = 0, 
    Value = AimbotSettings.predictionFactor * 100,
    Callback = function(val) 
        AimbotSettings.predictionFactor = val / 100 
        SaveConfig()
    end
})

AimbotTab:Section({Title = "Visuals"})

AimbotTab:Toggle({
    Title = "Draw FOV Circle", 
    Desc = "Show FOV Circle", 
    Value = AimbotSettings.showFOV,
    Callback = function(v) 
        AimbotSettings.showFOV = v 
        FOVring.Visible = v 
        SaveConfig()
    end
})

AimbotTab:Toggle({
    Title = "Fill FOV Area", 
    Desc = "Fill FOV Area", 
    Value = AimbotSettings.fovFilled,
    Callback = function(v) 
        AimbotSettings.fovFilled = v 
        FOVring.Filled = v 
        SaveConfig()
    end
})

-- ============================================
-- WHITELIST UI SETUP
-- ============================================
WhitelistTab:Section({Title = "Whitelist Configuration"})
WhitelistTab:Label({
    Title = "Instructions",
    Desc = "Select player for Whitelist\nPlayer will be ignored by Aimbot"
})

local playerDropdownList = {}
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        table.insert(playerDropdownList, p.Name)
    end
end
if #playerDropdownList == 0 then
    playerDropdownList = {"(No Players)"}
end

local selectedPlayerName = playerDropdownList[1]
WhitelistTab:Dropdown({
    Title = "Select Player",
    Desc = "Select from online players",
    List = playerDropdownList,
    Value = selectedPlayerName,
    Callback = function(choice)
        selectedPlayerName = choice
    end
})

WhitelistTab:Button({
    Title = "Add Selected Player",
    Desc = "Add selected to Whitelist",
    Callback = function()
        if selectedPlayerName == "(No Players)" then return end
        if addToWhitelist(selectedPlayerName) then
            Window:Notify({Title = "Whitelist", Desc = "Added " .. selectedPlayerName, Time = 3})
        else
            Window:Notify({Title = "Whitelist", Desc = selectedPlayerName .. " is already in list", Time = 3})
        end
    end
})

WhitelistTab:Button({
    Title = "Remove Selected Player",
    Desc = "Remove selected from Whitelist",
    Callback = function()
        if selectedPlayerName == "(No Players)" then return end
        if removeFromWhitelist(selectedPlayerName) then
            Window:Notify({Title = "Whitelist", Desc = "Removed " .. selectedPlayerName, Time = 3})
        else
            Window:Notify({Title = "Whitelist", Desc = selectedPlayerName .. " is not in list", Time = 3})
        end
    end
})

WhitelistTab:Section({Title = "Whitelist Management"})
WhitelistTab:Button({
    Title = "View Whitelist",
    Desc = "Show all names",
    Callback = function()
        if #Whitelist == 0 then
            Window:Notify({Title = "Whitelist", Desc = "No names yet", Time = 3})
        else
            local names = table.concat(Whitelist, ", ")
            Window:Notify({Title = "Whitelist (" .. #Whitelist .. " players)", Desc = names, Time = 5})
        end
    end
})
WhitelistTab:Button({
    Title = "Clear Whitelist",
    Desc = "Clear all names",
    Callback = function()
        Whitelist = {}
        SaveConfig()
        Window:Notify({Title = "Whitelist", Desc = "Cleared all names", Time = 3})
    end
})

FarmTab:Toggle({ 
    Title = "Auto Rob Bank", 
    Image = "user", 
    Value = getgenv().AutoRobBank, 
    Callback = function(val) 
        getgenv().AutoRobBank = val 
        SaveConfig()
    end 
})

FarmTab:Toggle({ 
    Title = "Auto Server Hop", 
    Desc = "Auto hop server when all banks are robbed / on cooldown",
    Image = "refresh-cw", 
    Value = getgenv().AutoServerHop, 
    Callback = function(val) 
        getgenv().AutoServerHop = val 
        SaveConfig()
    end 
})

FarmTab:Button({
    Title = "Server Hop Now",
    Desc = "Switch server and continue script automatically",
    Callback = function()
        serverHop()
    end
})

FarmTab:Toggle({ 
    Title = "Fast Collect", 
    Desc = "Disable to hold E normally (reduces ban risk)",
    Image = "zap", 
    Value = getgenv().FastCollect, 
    Callback = function(val) 
        getgenv().FastCollect = val 
        SaveConfig()
    end 
})

FarmTab:Slider({
    Title = "Auto Rob Fly Speed",
    Desc = "Adjust fly speed for bank robbery",
    Min = 50,
    Max = 300,
    Default = getgenv().FlySpeed or 150,
    Value = getgenv().FlySpeed or 150,
    Callback = function(val)
        getgenv().FlySpeed = val
        SaveConfig()
    end
})

-- ============================================
-- PLAYER TAB CONTROLS (GHOST FLY & GODMODE)
-- ============================================
PlayerTab:Section({ Title = "Ghost Flight" })

PlayerTab:Toggle({
    Title = "Ghost Fly",
    Desc = "Fly with WASD + Space (Up) / Shift (Down) [Key: X]",
    Image = "navigation",
    Value = getgenv().GhostFlyEnabled,
    Callback = function(val)
        toggleGhostFly(val)
        SaveConfig()
    end
})

PlayerTab:Slider({
    Title = "Ghost Fly Speed",
    Desc = "Adjust manual flying speed",
    Min = 10,
    Max = 300,
    Default = getgenv().GhostFlySpeed,
    Callback = function(val)
        getgenv().GhostFlySpeed = val
        SaveConfig()
    end
})

PlayerTab:Toggle({
    Title = "Noclip While Flying",
    Desc = "Pass through walls and obstacles",
    Image = "shield",
    Value = getgenv().GhostFlyNoclip,
    Callback = function(val)
        getgenv().GhostFlyNoclip = val
        SaveConfig()
    end
})

PlayerTab:Section({ Title = "Godmode & Defense" })

PlayerTab:Toggle({
    Title = "Godmode",
    Desc = "Continuous health lock & anti-ragdoll",
    Image = "shield",
    Value = getgenv().GodmodeEnabled,
    Callback = function(val)
        toggleGodmode(val)
        SaveConfig()
    end
})

PlayerTab:Toggle({
    Title = "Anti Fall Damage",
    Desc = "Prevents damage and knockdown from falling",
    Image = "activity",
    Value = getgenv().AntiFallDamage,
    Callback = function(val)
        getgenv().AntiFallDamage = val
        SaveConfig()
    end
})

-- ============================================
-- ESP TAB CONTROLS
-- ============================================
ESPTab:Section({ Title = "Main ESP" })

ESPTab:Toggle({ 
    Title = "Bank ESP", 
    Image = "eye", 
    Value = getgenv().BankESP, 
    Callback = function(val) 
        getgenv().BankESP = val 
        SaveConfig()
    end 
})

ESPTab:Toggle({
    Title = "Player ESP Master",
    Image = "users",
    Value = getgenv().PlayerESP,
    Callback = function(val)
        getgenv().PlayerESP = val
        SaveConfig()
    end
})

ESPTab:Section({ Title = "Player ESP Elements" })

ESPTab:Toggle({
    Title = "Name ESP",
    Image = "user",
    Value = getgenv().NameESP,
    Callback = function(val)
        getgenv().NameESP = val
        SaveConfig()
    end
})

ESPTab:Toggle({
    Title = "Health Bar & Numbers",
    Desc = "Shows health bar and HP number",
    Image = "activity",
    Value = getgenv().HealthESP,
    Callback = function(val)
        getgenv().HealthESP = val
        SaveConfig()
    end
})

ESPTab:Toggle({
    Title = "Inventory / Tool Icons ESP",
    Desc = "Shows equipped gun & backpack items as icons",
    Image = "briefcase",
    Value = getgenv().ToolESP,
    Callback = function(val)
        getgenv().ToolESP = val
        SaveConfig()
    end
})

ESPTab:Toggle({
    Title = "Distance ESP",
    Image = "navigation",
    Value = getgenv().DistESP,
    Callback = function(val)
        getgenv().DistESP = val
        SaveConfig()
    end
})

ESPTab:Toggle({
    Title = "2D Box ESP",
    Image = "box",
    Value = getgenv().BoxESP,
    Callback = function(val)
        getgenv().BoxESP = val
        SaveConfig()
    end
})

ESPTab:Toggle({
    Title = "Tracer Lines ESP",
    Image = "arrow-up-right",
    Value = getgenv().TracerESP,
    Callback = function(val)
        getgenv().TracerESP = val
        SaveConfig()
    end
})

ESPTab:Section({ Title = "Visual Customization" })

ESPTab:Dropdown({
    Title = "ESP Style",
    Desc = "Select ESP visual style",
    List = {"2D", "3D"},
    Value = getgenv().ESPStyle,
    Callback = function(val)
        getgenv().ESPStyle = val
        SaveConfig()
    end
})

ESPTab:Dropdown({
    Title = "ESP Color",
    Desc = "Select color for ESP highlights and boxes",
    List = {"Red", "Green", "Blue", "Yellow", "Orange", "Purple", "Cyan", "White"},
    Value = getgenv().ESPColorName or "Red",
    Callback = function(val)
        getgenv().ESPColorName = val
        if val == "Red" then getgenv().ESPColor = Color3.fromRGB(255, 60, 60)
        elseif val == "Green" then getgenv().ESPColor = Color3.fromRGB(40, 240, 80)
        elseif val == "Blue" then getgenv().ESPColor = Color3.fromRGB(60, 160, 255)
        elseif val == "Yellow" then getgenv().ESPColor = Color3.fromRGB(255, 230, 40)
        elseif val == "Orange" then getgenv().ESPColor = Color3.fromRGB(255, 140, 30)
        elseif val == "Purple" then getgenv().ESPColor = Color3.fromRGB(180, 80, 255)
        elseif val == "Cyan" then getgenv().ESPColor = Color3.fromRGB(40, 240, 240)
        elseif val == "White" then getgenv().ESPColor = Color3.fromRGB(255, 255, 255)
        end
        SaveConfig()
    end
})

-- ============================================
-- TELEPORT TAB
-- ============================================
local tpDropdownList = {}
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        table.insert(tpDropdownList, p.Name)
    end
end
if #tpDropdownList == 0 then
    tpDropdownList = {"(No Players)"}
end

local tpSelectedPlayer = tpDropdownList[1]

local tpDropdown = TeleportTab:Dropdown({
    Title = "Select Player",
    Desc = "Select from online players",
    List = tpDropdownList,
    Value = tpSelectedPlayer,
    Callback = function(choice)
        tpSelectedPlayer = choice
    end
})

TeleportTab:Button({
    Title = "Teleport To Player",
    Desc = "Teleport to selected player",
    Callback = function()
        if tpSelectedPlayer == "(No Players)" then return end
        local p = Players:FindFirstChild(tpSelectedPlayer)
        if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local targetCFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                hrp.CFrame = targetCFrame
                Window:Notify({Title = "Teleport", Desc = "Teleported to " .. tpSelectedPlayer, Time = 3})
            end
        else
            Window:Notify({Title = "Teleport", Desc = "Target character not found", Time = 3})
        end
    end
})

TeleportTab:Button({
    Title = "Refresh Players",
    Desc = "Refresh player list",
    Callback = function()
        tpDropdown:Clear()
        local foundAny = false
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                tpDropdown:Add(p.Name)
                foundAny = true
            end
        end
        if not foundAny then
            tpDropdown:Add("(No Players)")
        end
        Window:Notify({Title = "Teleport", Desc = "Player list updated", Time = 3})
    end
})

getgenv().OrbitAttack = false
getgenv().OrbitDistance = 15
getgenv().OrbitSpeed = 3
getgenv().OrbitHeight = 5

TeleportTab:Toggle({
    Title = "Orbit & Attack",
    Desc = "Orbit selected player and auto-attack",
    Value = getgenv().OrbitAttack,
    Callback = function(val)
        getgenv().OrbitAttack = val
        SaveConfig()
    end
})

TeleportTab:Slider({
    Title = "Orbit Distance",
    Desc = "Distance from target player",
    Min = 5,
    Max = 50,
    Default = getgenv().OrbitDistance,
    Callback = function(val)
        getgenv().OrbitDistance = val
        SaveConfig()
    end
})

TeleportTab:Slider({
    Title = "Orbit Speed",
    Desc = "Orbiting speed",
    Min = 1,
    Max = 15,
    Default = getgenv().OrbitSpeed,
    Callback = function(val)
        getgenv().OrbitSpeed = val
        SaveConfig()
    end
})

-- ============================================
-- SETTINGS TAB (CONFIG MANAGEMENT)
-- ============================================
SettingsTab:Section({ Title = "Configuration Manager" })

SettingsTab:Button({
    Title = "Save Config Now",
    Desc = "Manually save all current settings to disk",
    Callback = function()
        SaveConfig()
        Window:Notify({Title = "Config Saved", Desc = "Settings saved to " .. CONFIG_FILE, Time = 3})
    end
})

SettingsTab:Button({
    Title = "Reload Config",
    Desc = "Reload saved settings from disk",
    Callback = function()
        LoadConfig()
        Window:Notify({Title = "Config Reloaded", Desc = "Settings reloaded from disk", Time = 3})
    end
})

SettingsTab:Button({
    Title = "Reset to Defaults",
    Desc = "Reset all settings to initial defaults",
    Callback = function()
        pcall(function()
            if delfile and isfile(CONFIG_FILE) then
                delfile(CONFIG_FILE)
            end
        end)
        for k, v in pairs(DefaultConfig) do
            ConfigState[k] = v
        end
        Window:Notify({Title = "Config Reset", Desc = "Settings reset to defaults", Time = 3})
    end
})

SettingsTab:Toggle({
    Title = "Auto Save Changes",
    Desc = "Automatically save settings whenever modified",
    Image = "save",
    Value = ConfigState.AutoSave == nil and true or ConfigState.AutoSave,
    Callback = function(val)
        ConfigState.AutoSave = val
        if val then SaveConfig() end
    end
})

local orbitAngle = 0
RunService.Stepped:Connect(function(time, deltaTime)
    if getgenv().OrbitAttack and tpSelectedPlayer and tpSelectedPlayer ~= "(No Players)" then
        local targetPlayer = Players:FindFirstChild(tpSelectedPlayer)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
            if targetHum and targetHum.Health > 0 then
                local myChar = LocalPlayer.Character
                if myChar and myChar:FindFirstChild("HumanoidRootPart") and myChar:FindFirstChild("Humanoid") then
                    local myHrp = myChar.HumanoidRootPart
                    local targetHrp = targetPlayer.Character.HumanoidRootPart
                    
                    orbitAngle = orbitAngle + (getgenv().OrbitSpeed * deltaTime)
                    local offset = Vector3.new(math.cos(orbitAngle) * getgenv().OrbitDistance, getgenv().OrbitHeight or 5, math.sin(orbitAngle) * getgenv().OrbitDistance)
                    local targetPos = targetHrp.Position + offset
                    
                    myChar.Humanoid.PlatformStand = true
                    myHrp.CFrame = CFrame.new(targetPos, targetHrp.Position)
                    myHrp.Velocity = Vector3.zero
                    myHrp.RotVelocity = Vector3.zero
                    
                    local tool = myChar:FindFirstChildOfClass("Tool")
                    if tool then
                        tool:Activate()
                    end
                end
            end
        end
    else
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            if not LocalPlayer.Character.HumanoidRootPart:FindFirstChild("GhostFlyVelocity") and getgenv().OrbitAttack == false then
                -- Only disable if not using AutoRob fly
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if getgenv().BankESP then
            for _, bank in ipairs(workspace:GetChildren()) do
                if bank.Name == "Bank" then
                    local laserDisabler = bank:FindFirstChild("LaserDisabler")
                    local main = laserDisabler and laserDisabler:FindFirstChild("Main")
                    if main then
                        local esp = main:FindFirstChild("BankESP")
                        if not esp then
                            esp = Instance.new("BillboardGui")
                            esp.Name = "BankESP"
                            esp.Adornee = main
                            esp.Size = UDim2.new(0, 150, 0, 50)
                            esp.StudsOffset = Vector3.new(0, 5, 0)
                            esp.AlwaysOnTop = true
                            
                            local textLabel = Instance.new("TextLabel")
                            textLabel.Parent = esp
                            textLabel.BackgroundTransparency = 1
                            textLabel.Size = UDim2.new(1, 0, 1, 0)
                            textLabel.TextScaled = true
                            textLabel.Font = Enum.Font.GothamBold
                            textLabel.TextStrokeTransparency = 0
                            
                            esp.Parent = main
                        end
                        
                        local textLabel = esp:FindFirstChildWhichIsA("TextLabel")
                        if textLabel then
                            local color = main.Color
                            local r = math.round(color.R * 255)
                            local g = math.round(color.G * 255)
                            local b = math.round(color.B * 255)
                            
                            if r == 255 and g == 0 and b == 0 then
                                textLabel.Text = "READY [RED]"
                                textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                            elseif r == 0 and g == 170 and b == 0 then
                                textLabel.Text = "ROBBABLE [GREEN]"
                                textLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
                            else
                                textLabel.Text = "COOLDOWN [YELLOW]"
                                textLabel.TextColor3 = Color3.fromRGB(255, 255, 50)
                            end
                        end
                    end
                end
            end
        else
            for _, bank in ipairs(workspace:GetChildren()) do
                if bank.Name == "Bank" then
                    local laserDisabler = bank:FindFirstChild("LaserDisabler")
                    local main = laserDisabler and laserDisabler:FindFirstChild("Main")
                    if main and main:FindFirstChild("BankESP") then
                        main.BankESP:Destroy()
                    end
                end
            end
        end
    end
end)

local function getPromptPart(prompt)
    if not prompt then return nil end
    local parent = prompt.Parent
    if not parent then return nil end
    
    if parent:IsA("BasePart") then
        return parent
    elseif parent:IsA("Model") then
        return parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart", true)
    elseif parent.Parent and parent.Parent:IsA("Model") then
        return parent.Parent.PrimaryPart or parent.Parent:FindFirstChildWhichIsA("BasePart", true)
    end
    return parent:FindFirstChildWhichIsA("BasePart", true)
end

local function triggerPrompt(prompt)
    if not prompt or not prompt.Enabled then return end
    
    local part = getPromptPart(prompt)
    if part then
        flyTo(part.CFrame)
        task.wait(0.15)
    end
    
    if getgenv().FastCollect == nil or getgenv().FastCollect == true then
        if fireproximityprompt then
            local oldHold = prompt.HoldDuration
            prompt.HoldDuration = 0
            fireproximityprompt(prompt, 0)
            task.wait(0.15)
            prompt.HoldDuration = oldHold
        end
    else
        -- Normal Hold E
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration + 0.1)
        prompt:InputHoldEnd()
        task.wait(0.15)
    end
end

local function getBankPrompts(bank)
    local laserPrompt = nil
    local vaultPrompt = nil
    local lootList = {}
    
    for _, desc in ipairs(bank:GetDescendants()) do
        if desc:IsA("ProximityPrompt") and desc.Enabled then
            local pName = string.lower(desc.Parent and desc.Parent.Name or "")
            local oName = string.lower(desc.Name or "")
            local grandName = string.lower(desc.Parent and desc.Parent.Parent and desc.Parent.Parent.Name or "")
            local actionText = string.lower(desc.ActionText or "")
            local objectText = string.lower(desc.ObjectText or "")
            
            -- Filter out purchase prompts
            if string.find(actionText, "buy") or string.find(objectText, "buy") or 
               string.find(pName, "robbery tools") or string.find(oName, "robbery tools") or 
               string.find(objectText, "robbery tools") then
                continue
            end
            
            if string.find(pName, "laser") or string.find(grandName, "laser") then
                laserPrompt = desc
            elseif string.find(pName, "vault") or string.find(grandName, "vault") or string.find(pName, "door") then
                vaultPrompt = desc
            elseif not string.find(pName, "document") and not string.find(oName, "document") then
                local part = getPromptPart(desc)
                if part then
                    table.insert(lootList, {
                        prompt = desc,
                        part = part
                    })
                end
            end
        end
    end
    
    -- Also search folders named Loot, Cash, Money for any parts/prompts
    local lootFolder = bank:FindFirstChild("Loot", true) or bank:FindFirstChild("Cash", true) or bank:FindFirstChild("Money", true)
    if lootFolder then
        for _, item in ipairs(lootFolder:GetChildren()) do
            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
            local part = item:IsA("BasePart") and item or (item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)))
            
            if prompt and prompt.Enabled and part then
                local pName = string.lower(prompt.Parent and prompt.Parent.Name or "")
                local oName = string.lower(prompt.Name or "")
                local actionText = string.lower(prompt.ActionText or "")
                local objectText = string.lower(prompt.ObjectText or "")
                
                -- Filter out purchase prompts
                if string.find(actionText, "buy") or string.find(objectText, "buy") or 
                   string.find(pName, "robbery tools") or string.find(oName, "robbery tools") or 
                   string.find(objectText, "robbery tools") then
                    continue
                end
                
                local alreadyAdded = false
                for _, lp in ipairs(lootList) do
                    if lp.prompt == prompt then
                        alreadyAdded = true
                        break
                    end
                end
                if not alreadyAdded then
                    table.insert(lootList, {
                        prompt = prompt,
                        part = part
                    })
                end
            end
        end
    end
    
    return laserPrompt, vaultPrompt, lootList
end

task.spawn(function()
    while task.wait(1) do
        if not getgenv().AutoRobBank then continue end
        local banks = getBanks()
        local targetBank = nil
        local targetMain = nil
        local bankState = "NONE"
        
        local priorityLevel = 0 -- 0=none, 1=COOLDOWN, 2=ROBBABLE, 3=READY
        
        for _, bank in ipairs(banks) do
            local state, mainPart = getBankState(bank)
            if mainPart and not robbedBanks[bank] then
                if state == "READY" and priorityLevel < 3 then
                    targetBank = bank
                    targetMain = mainPart
                    bankState = state
                    priorityLevel = 3
                elseif state == "ROBBABLE" and priorityLevel < 2 then
                    targetBank = bank
                    targetMain = mainPart
                    bankState = state
                    priorityLevel = 2
                end
            end
        end
        
        if targetBank and targetMain then
            
            print("Target found! Flying to rob...")
            flyTo(targetMain.CFrame)
            
            local emptyCounter = 0
            while task.wait(0.3) do
                if not getgenv().AutoRobBank then break end
                
                -- Check if bag is full
                local isBagFull = false
                pcall(function()
                    local gui = LocalPlayer.PlayerGui:FindFirstChild("BankRobberyGUI")
                    if gui and gui:FindFirstChild("MainRobbery") and gui.MainRobbery:FindFirstChild("MoneyCollectedLabel") then
                        local text = gui.MainRobbery.MoneyCollectedLabel.Text
                        local cleanText = string.gsub(text, "[$,]", "") 
                        local current, max = string.match(cleanText, "(%d+)%s*/%s*(%d+)")
                        if current and max and tonumber(current) >= tonumber(max) then
                            isBagFull = true
                        end
                    end
                end)
                
                if isBagFull then
                    print("Bag full! (From GUI) Going to cashout...")
                    break
                end
                
                local laserPrompt, vaultPrompt, lootList = getBankPrompts(targetBank)
                
                -- Step 1: Laser Disabler
                if laserPrompt and laserPrompt.Enabled then
                    print("Disabling laser...")
                    triggerPrompt(laserPrompt)
                    emptyCounter = 0
                    task.wait(0.3)
                -- Step 2: Vault Door
                elseif vaultPrompt and vaultPrompt.Enabled then
                    print("Opening vault door...")
                    triggerPrompt(vaultPrompt)
                    emptyCounter = 0
                    task.wait(0.5)
                -- Step 3: Collect Loot Items
                elseif #lootList > 0 then
                    emptyCounter = 0
                    print("Found " .. #lootList .. " valuable items. Collecting...")
                    for _, lootItem in ipairs(lootList) do
                        if not getgenv().AutoRobBank then break end
                        
                        -- Check bag before each loot
                        local fullNow = false
                        pcall(function()
                            local gui = LocalPlayer.PlayerGui:FindFirstChild("BankRobberyGUI")
                            if gui and gui:FindFirstChild("MainRobbery") and gui.MainRobbery:FindFirstChild("MoneyCollectedLabel") then
                                local text = gui.MainRobbery.MoneyCollectedLabel.Text
                                local cleanText = string.gsub(text, "[$,]", "") 
                                local current, max = string.match(cleanText, "(%d+)%s*/%s*(%d+)")
                                if current and max and tonumber(current) >= tonumber(max) then
                                    fullNow = true
                                end
                            end
                        end)
                        
                        if fullNow then
                            isBagFull = true
                            break
                        end
                        
                        if lootItem.prompt and lootItem.prompt.Enabled and lootItem.part then
                            triggerPrompt(lootItem.prompt)
                            task.wait(0.2)
                        end
                    end
                    
                    if isBagFull then
                        print("Bag full! Going to cashout...")
                        break
                    end
                else
                    emptyCounter = emptyCounter + 1
                    if emptyCounter <= 20 then
                        -- Wait a moment for door animation or loot spawn (up to ~10 seconds)
                        task.wait(0.5)
                    else
                        print("No more loot. Cashing out and changing bank.")
                        break
                    end
                end
            end
            
            print("Searching for valid CashoutPoint...")
            pcall(function()
                local destination = nil
                
                for _, desc in ipairs(workspace:GetDescendants()) do
                    if desc:IsA("BillboardGui") and desc.Enabled and desc.Parent and desc.Parent.Name == "Marker" then
                        destination = desc.Parent.Parent
                        if destination then break end
                    end
                end
                
                if not destination then
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") and obj.Enabled then
                            local n = string.lower(obj.Parent and obj.Parent.Name or "")
                            if string.find(n, "cashout") or string.find(n, "dealer") or string.find(n, "dropoff") or string.find(n, "sell") then
                                destination = obj.Parent
                                break
                            end
                        end
                    end
                end
                
                if destination then
                    local destCFrame = destination:IsA("Model") and (destination.PrimaryPart and destination.PrimaryPart.CFrame or destination:GetModelCFrame()) or destination:IsA("BasePart") and destination.CFrame
                    
                    if not destCFrame then
                        local part = destination:FindFirstChildWhichIsA("BasePart", true)
                        if part then destCFrame = part.CFrame end
                    end
                    
                    if destCFrame then
                        flyTo(destCFrame)
                        task.wait(0.5)
                        
                        for _, obj in ipairs(destination:GetDescendants()) do
                            if obj:IsA("ProximityPrompt") and obj.Enabled then
                                local pName = string.lower(obj.Parent.Name)
                                local oName = string.lower(obj.Name)
                                if not string.find(pName, "document") and not string.find(oName, "document") then
                                    local oldHold = obj.HoldDuration
                                    obj.HoldDuration = 0
                                    fireproximityprompt(obj, 0)
                                    task.wait(0.1)
                                    obj.HoldDuration = oldHold
                                end
                            end
                        end
                        task.wait(1.5)
                    end
                else
                    print("Could not find active CashoutPoint")
                end
            end)
            robbedBanks[targetBank] = true
            
            -- Check if all robbable banks in this server are now completed
            local hasRobbableLeft = false
            for _, b in ipairs(getBanks()) do
                local st, _ = getBankState(b)
                if (st == "READY" or st == "ROBBABLE") and not robbedBanks[b] then
                    hasRobbableLeft = true
                    break
                end
            end
            
            if not hasRobbableLeft and getgenv().AutoServerHop and getgenv().AutoRobBank then
                print("[Singularity] All banks in server completed! Triggering Server Hop in 3s...")
                pcall(function()
                    Window:Notify({
                        Title = "Auto Server Hop",
                        Desc = "All banks completed! Switching server in 3s...",
                        Time = 4
                    })
                end)
                task.wait(3)
                serverHop()
                task.wait(10)
            end
        else
            -- No robbable banks currently found in server
            if getgenv().AutoServerHop and getgenv().AutoRobBank then
                print("[Singularity] No robbable banks in current server. Triggering Server Hop...")
                pcall(function()
                    Window:Notify({
                        Title = "Auto Server Hop",
                        Desc = "No robbable banks available. Hopping to another server in 3s...",
                        Time = 4
                    })
                end)
                task.wait(3)
                serverHop()
                task.wait(10)
            end
        end
    end
end)

-- ============================================
-- PLAYER ESP LOGIC (HEALTH, NAME, WEAPON ICONS)
-- ============================================
local espObjects = {}
local camera = workspace.CurrentCamera

local function getToolCategoryIcon(toolName)
    local n = string.lower(toolName or "")
    if string.find(n, "gun") or string.find(n, "ak") or string.find(n, "m4") or string.find(n, "rifle") or string.find(n, "shotgun") or string.find(n, "glock") or string.find(n, "pistol") or string.find(n, "deagle") or string.find(n, "sniper") or string.find(n, "revolver") or string.find(n, "smg") or string.find(n, "uzi") or string.find(n, "weapon") then
        return "rbxassetid://6031086178" -- Gun / Weapon Icon
    elseif string.find(n, "knife") or string.find(n, "blade") or string.find(n, "sword") or string.find(n, "bat") or string.find(n, "axe") or string.find(n, "katana") or string.find(n, "melee") or string.find(n, "fist") then
        return "rbxassetid://6034684937" -- Melee / Knife Icon
    elseif string.find(n, "med") or string.find(n, "heal") or string.find(n, "bandage") or string.find(n, "potion") or string.find(n, "food") or string.find(n, "apple") or string.find(n, "drink") then
        return "rbxassetid://6031094667" -- Health / Medkit Icon
    else
        return "rbxassetid://6031068426" -- General Inventory Icon
    end
end

local function getActiveESPColor()
    local c = getgenv().ESPColor
    if typeof(c) == "Color3" then
        return c
    elseif typeof(c) == "table" and c.R and c.G and c.B then
        return Color3.new(c.R, c.G, c.B)
    elseif typeof(c) == "string" then
        if c == "Red" then return Color3.fromRGB(255, 60, 60)
        elseif c == "Green" then return Color3.fromRGB(40, 240, 80)
        elseif c == "Blue" then return Color3.fromRGB(60, 160, 255)
        elseif c == "Yellow" then return Color3.fromRGB(255, 230, 40)
        elseif c == "Orange" then return Color3.fromRGB(255, 140, 30)
        elseif c == "Purple" then return Color3.fromRGB(180, 80, 255)
        elseif c == "Cyan" then return Color3.fromRGB(40, 240, 240)
        elseif c == "White" then return Color3.fromRGB(255, 255, 255)
        end
    end
    return Color3.fromRGB(255, 60, 60)
end

local function createPlayerESP(player)
    if espObjects[player] then return end
    
    local objects = {}
    local activeColor = getActiveESPColor()

    pcall(function()
        objects.Tracer = Drawing.new("Line")
        objects.Tracer.Visible = false
        objects.Tracer.Color = activeColor
        objects.Tracer.Thickness = 1
        objects.Tracer.Transparency = 1
        
        objects.Box = Drawing.new("Square")
        objects.Box.Visible = false
        objects.Box.Color = activeColor
        objects.Box.Thickness = 1
        objects.Box.Transparency = 1
        objects.Box.Filled = false
    end)
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.FillColor = activeColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Enabled = false
    objects.Highlight = highlight
    
    local espGui = Instance.new("BillboardGui")
    espGui.Name = "PlayerESP"
    espGui.Size = UDim2.new(5, 0, 6, 0)
    espGui.AlwaysOnTop = true
    espGui.MaxDistance = 6000
    espGui.ExtentsOffset = Vector3.new(0, 3, 0)
    
    -- Name Label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.Position = UDim2.new(0, 0, 0, -28)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.Parent = espGui
    
    -- Health Text Label
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.new(1, 0, 0, 14)
    healthText.Position = UDim2.new(0, 0, 0, -12)
    healthText.BackgroundTransparency = 1
    healthText.TextColor3 = Color3.fromRGB(0, 255, 120)
    healthText.TextStrokeTransparency = 0.3
    healthText.Font = Enum.Font.GothamMedium
    healthText.TextSize = 11
    healthText.Parent = espGui
    
    -- Distance Label
    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, 0, 0, 14)
    distLabel.Position = UDim2.new(0, 0, 1, 6)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    distLabel.TextStrokeTransparency = 0.4
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 11
    distLabel.Parent = espGui
    
    -- Health Bar Container
    local healthBarBg = Instance.new("Frame")
    healthBarBg.Name = "HealthBarBg"
    healthBarBg.Size = UDim2.new(0, 4, 1, 0)
    healthBarBg.Position = UDim2.new(0, -8, 0, 0)
    healthBarBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    healthBarBg.BorderSizePixel = 0
    healthBarBg.Parent = espGui
    
    local hbCorner = Instance.new("UICorner")
    hbCorner.CornerRadius = UDim.new(0, 2)
    hbCorner.Parent = healthBarBg
    
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
    healthBar.BorderSizePixel = 0
    healthBar.AnchorPoint = Vector2.new(0, 1)
    healthBar.Position = UDim2.new(0, 0, 1, 0)
    healthBar.Parent = healthBarBg
    
    local hbFillCorner = Instance.new("UICorner")
    hbFillCorner.CornerRadius = UDim.new(0, 2)
    hbFillCorner.Parent = healthBar
    
    -- Inventory / Tools Frame
    local invContainer = Instance.new("Frame")
    invContainer.Name = "InvContainer"
    invContainer.Size = UDim2.new(0, 110, 1, 0)
    invContainer.Position = UDim2.new(1, 8, 0, 0)
    invContainer.BackgroundTransparency = 1
    invContainer.Parent = espGui
    
    local invLayout = Instance.new("UIListLayout")
    invLayout.FillDirection = Enum.FillDirection.Vertical
    invLayout.SortOrder = Enum.SortOrder.LayoutOrder
    invLayout.Padding = UDim.new(0, 3)
    invLayout.Parent = invContainer
    
    objects.Gui = espGui
    objects.ToolBadges = {}
    espObjects[player] = objects
end

local function removePlayerESP(player)
    if espObjects[player] then
        if espObjects[player].Tracer then pcall(function() espObjects[player].Tracer:Remove() end) end
        if espObjects[player].Box then pcall(function() espObjects[player].Box:Remove() end) end
        if espObjects[player].Highlight then pcall(function() espObjects[player].Highlight:Destroy() end) end
        if espObjects[player].Gui then pcall(function() espObjects[player].Gui:Destroy() end) end
        espObjects[player] = nil
    end
end

RunService.RenderStepped:Connect(function()
    if FOVring and aimbotCamera then
        FOVring.Position = Vector2.new(aimbotCamera.ViewportSize.X / 2, aimbotCamera.ViewportSize.Y / 2)
    end
    if updateAimbot then
        updateAimbot()
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local objects = espObjects[player]
        if not objects then continue end
        
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if getgenv().PlayerESP and char and hrp and hum and hum.Health > 0 then
            if objects.Gui.Parent ~= hrp then
                objects.Gui.Parent = hrp
                objects.Gui.Adornee = hrp
            end
            
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local dist = myHrp and (hrp.Position - myHrp.Position).Magnitude or 0
            
            -- Distance
            objects.Gui.DistLabel.Text = "[ " .. math.floor(dist) .. " studs ]"
            objects.Gui.DistLabel.Visible = getgenv().DistESP
            
            -- Name
            objects.Gui.NameLabel.Text = (player.DisplayName or player.Name) .. " (@" .. player.Name .. ")"
            objects.Gui.NameLabel.Visible = getgenv().NameESP
            
            -- Health
            local hp = math.max(0, math.floor(hum.Health))
            local maxHp = math.max(1, math.floor(hum.MaxHealth))
            local healthPct = math.clamp(hp / maxHp, 0, 1)
            local hpColor = Color3.fromRGB(math.floor((1 - healthPct) * 255), math.floor(healthPct * 255), 40)
            
            objects.Gui.HealthBarBg.HealthBar.Size = UDim2.new(1, 0, healthPct, 0)
            objects.Gui.HealthBarBg.HealthBar.BackgroundColor3 = hpColor
            objects.Gui.HealthBarBg.Visible = getgenv().HealthESP
            
            objects.Gui.HealthText.Text = hp .. " / " .. maxHp .. " HP"
            objects.Gui.HealthText.TextColor3 = hpColor
            objects.Gui.HealthText.Visible = getgenv().HealthESP
            
            -- Inventory / Tool Icons
            if getgenv().ToolESP then
                objects.Gui.InvContainer.Visible = true
                local tools = {}
                
                -- Equipped Tool
                local equipped = char:FindFirstChildOfClass("Tool")
                if equipped then
                    table.insert(tools, {Tool = equipped, Equipped = true})
                end
                
                -- Backpack Tools
                local bp = player:FindFirstChild("Backpack")
                if bp then
                    for _, t in ipairs(bp:GetChildren()) do
                        if t:IsA("Tool") then
                            table.insert(tools, {Tool = t, Equipped = false})
                        end
                    end
                end
                
                -- Update tool badges
                for i = 1, math.max(#tools, #objects.ToolBadges) do
                    local item = tools[i]
                    local badge = objects.ToolBadges[i]
                    
                    if item and i <= 4 then
                        if not badge then
                            badge = Instance.new("Frame")
                            badge.Name = "ItemBadge_" .. tostring(i)
                            badge.Size = UDim2.new(1, 0, 0, 18)
                            badge.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
                            badge.BackgroundTransparency = 0.3
                            badge.BorderSizePixel = 0
                            badge.Parent = objects.Gui.InvContainer
                            
                            local bCorner = Instance.new("UICorner")
                            bCorner.CornerRadius = UDim.new(0, 4)
                            bCorner.Parent = badge
                            
                            local bStroke = Instance.new("UIStroke")
                            bStroke.Name = "BadgeStroke"
                            bStroke.Thickness = 1
                            bStroke.Transparency = 0.4
                            bStroke.Parent = badge
                            
                            local icon = Instance.new("ImageLabel")
                            icon.Name = "ItemIcon"
                            icon.AnchorPoint = Vector2.new(0, 0.5)
                            icon.Position = UDim2.new(0, 3, 0.5, 0)
                            icon.Size = UDim2.new(0, 13, 0, 13)
                            icon.BackgroundTransparency = 1
                            icon.Parent = badge
                            
                            local label = Instance.new("TextLabel")
                            label.Name = "ItemName"
                            label.AnchorPoint = Vector2.new(0, 0.5)
                            label.Position = UDim2.new(0, 19, 0.5, 0)
                            label.Size = UDim2.new(1, -21, 1, 0)
                            label.BackgroundTransparency = 1
                            label.Font = Enum.Font.GothamMedium
                            label.TextSize = 10
                            label.TextColor3 = Color3.fromRGB(240, 240, 245)
                            label.TextXAlignment = Enum.TextXAlignment.Left
                            label.TextTruncate = Enum.TextTruncate.AtEnd
                            label.Parent = badge
                            
                            objects.ToolBadges[i] = badge
                        end
                        
                        local toolObj = item.Tool
                        local toolName = toolObj.Name or "Item"
                        local textureId = (toolObj.TextureId and toolObj.TextureId ~= "") and toolObj.TextureId or getToolCategoryIcon(toolName)
                        
                        badge.ItemIcon.Image = textureId
                        badge.ItemName.Text = toolName
                        
                        local bStroke = badge:FindFirstChild("BadgeStroke")
                        if item.Equipped then
                            if bStroke then bStroke.Color = Color3.fromRGB(255, 180, 40) end
                            badge.BackgroundColor3 = Color3.fromRGB(35, 30, 18)
                        else
                            if bStroke then bStroke.Color = Color3.fromRGB(60, 60, 80) end
                            badge.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
                        end
                        badge.Visible = true
                    elseif badge then
                        badge.Visible = false
                    end
                end
            else
                objects.Gui.InvContainer.Visible = false
            end
            
            local activeColor = getActiveESPColor()
            
            if objects.Tracer then objects.Tracer.Color = activeColor end
            if objects.Box then objects.Box.Color = activeColor end
            if objects.Highlight then objects.Highlight.FillColor = activeColor end
            
            if getgenv().ESPStyle == "2D" then
                if objects.Highlight.Parent then
                    objects.Highlight.Parent = nil
                    objects.Highlight.Enabled = false
                end
                
                if objects.Tracer and objects.Box then
                    local hrpPos, hrpOnScreen = camera:WorldToViewportPoint(hrp.Position)
                    if hrpOnScreen then
                        local head = char:FindFirstChild("Head")
                        local headPos = head and camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2, 0))
                        local legPos = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                        
                        local height = math.abs(headPos.Y - legPos.Y)
                        local width = height / 2
                        
                        if getgenv().BoxESP then
                            objects.Box.Size = Vector2.new(width, height)
                            objects.Box.Position = Vector2.new(hrpPos.X - width / 2, headPos.Y)
                            objects.Box.Visible = true
                        else
                            objects.Box.Visible = false
                        end
                        
                        if getgenv().TracerESP then
                            objects.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                            objects.Tracer.To = Vector2.new(hrpPos.X, hrpPos.Y)
                            objects.Tracer.Visible = true
                        else
                            objects.Tracer.Visible = false
                        end
                    else
                        objects.Box.Visible = false
                        objects.Tracer.Visible = false
                    end
                end
            else
                if objects.Box then objects.Box.Visible = false end
                if objects.Tracer then objects.Tracer.Visible = false end
                
                if objects.Highlight.Parent ~= char then
                    objects.Highlight.Parent = char
                end
                objects.Highlight.Enabled = true
            end
        else
            if objects.Gui.Parent then objects.Gui.Parent = nil end
            if objects.Tracer then objects.Tracer.Visible = false end
            if objects.Box then objects.Box.Visible = false end
            if objects.Highlight then 
                objects.Highlight.Parent = nil
                objects.Highlight.Enabled = false 
            end
        end
    end
end)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then createPlayerESP(p) end
end
Players.PlayerAdded:Connect(createPlayerESP)
Players.PlayerRemoving:Connect(removePlayerESP)

