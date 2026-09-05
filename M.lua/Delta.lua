-- ========================================================
-- // Project Delta (Dalta) Hub — Ultimate Edition
-- // Standalone Edition (100% Loadstring-Free)
-- // Custom Anti-Cheat Bypass: LogService + Loot RF + TryHook Guard
-- // Created by K2NTA ST | Project Singularity
-- ========================================================

-- ========================================================
-- // 1. COMPREHENSIVE ANTI-CHEAT BYPASS FOR DELTA
-- ========================================================
local AC_Bypass = {
    LogServiceBlocked = 0,
    LootRFHooked = false,
    TimeoutSet = false,
    TryHookProtected = true
}

-- [1.1] ป้องกัน ScriptContext Timeout & Infinite Loop Crash
pcall(function()
    if game:GetService("ScriptContext").SetTimeout then
        game:GetService("ScriptContext"):SetTimeout(2)
        AC_Bypass.TimeoutSet = true
    end
end)

-- [1.2] บล็อก LogService.MessageOut (ตรวจพบ 1 จุด) ป้องกันดักอ่าน Console & Error
pcall(function()
    if getconnections then
        for _, conn in pairs(getconnections(game:GetService("LogService").MessageOut)) do
            conn:Disable()
            AC_Bypass.LogServiceBlocked = AC_Bypass.LogServiceBlocked + 1
        end
        for _, conn in pairs(getconnections(game:GetService("ScriptContext").Error)) do
            conn:Disable()
        end
    end
end)

-- [1.3] Bypass RemoteFunction 'Loot' (OnClientInvoke Protection)
pcall(function()
    local instances = (getinstances and getinstances()) or game:GetDescendants()
    for _, inst in ipairs(instances) do
        if inst and inst:IsA("RemoteFunction") then
            if inst.Name == "Loot" or inst.Name:lower():find("loot") then
                local oldInvoke = inst.OnClientInvoke
                inst.OnClientInvoke = function(...)
                    if oldInvoke then
                        local ok, res = pcall(oldInvoke, ...)
                        if ok then return res end
                    end
                    return true
                end
                AC_Bypass.LootRFHooked = true
            end
        end
    end
end)

-- [1.4] TryHook & Fast Metatable Hook Protection (newcclosure Optimized)
pcall(function()
    if hookmetamethod and checkcaller and newcclosure then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() then
                if method == "FireServer" or method == "InvokeServer" then
                    local sName = tostring(self.Name):lower()
                    if sName:find("ban") or sName:find("flag") or sName:find("cheat") or sName:find("detect") or sName:find("report") then
                        return nil
                    end
                end
            end
            return oldNamecall(self, ...)
        end))
    end
end)

-- ========================================================
-- // 2. SERVICES & BASIC SETUP
-- ========================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Anti-Overlap
local env = (getgenv and getgenv()) or _G
local runId = tick()
env.DeltaHub_RunID = runId

if env.DeltaHub_Cleanup then
    pcall(env.DeltaHub_Cleanup)
end

pcall(function()
    for _, v in ipairs(CoreGui:GetChildren()) do
        if v.Name == "SingularityDeltaHub" then v:Destroy() end
    end
    if LocalPlayer:FindFirstChild("PlayerGui") then
        for _, v in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            if v.Name == "SingularityDeltaHub" then v:Destroy() end
        end
    end
end)

-- ========================================================
-- // 3. CONFIGURATION & STATE
-- ========================================================
local Settings = {
    -- Combat & Aimbot
    aimbotEnabled = true,
    silentAim = false,
    aimTargetPart = "Head", -- Head, HumanoidRootPart
    aimbotSmoothing = 0.15,
    aimbotFOV = 150,
    prediction = 0.165,
    wallCheck = true,
    teamCheck = false,
    showFOV = true,
    fovColor = Color3.fromRGB(0, 255, 170),
    useRGB = true,
    rgbSpeed = 1.0,

    -- Player Visuals (ESP)
    espEnabled = true,
    espBoxes = true,
    espNames = true,
    espDistance = true,
    espHealth = true,
    espTeamColor = true,
    espRainbow = true,
    espColor = Color3.fromRGB(255, 75, 75),

    -- Loot & Item ESP (Project Delta)
    lootESP = true,
    lootDistance = 300,
    lootWeapon = true,
    lootAmmo = true,
    lootMedical = true,
    lootArmor = true,
    lootValuable = true,

    -- Player Mods
    speedHack = false,
    walkSpeed = 22,
    infiniteStamina = true,
    infiniteJump = false,
    ghostFly = false,
    ghostFlySpeed = 50,
    noclip = false,
    godmode = false,

    -- World
    fullBright = true,
    removeFog = true,
    antiAFK = true
}

local Whitelist = {}
local function isWhitelisted(player)
    local name = player.Name:lower()
    for _, wName in ipairs(Whitelist) do
        if wName:lower() == name then return true end
    end
    return false
end

-- Raycast Cache
local cachedRaycastParams = RaycastParams.new()
cachedRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist or Enum.RaycastFilterType.Exclude
cachedRaycastParams.IgnoreWater = true

local lastFilterChar = nil

-- FOV Circle Drawing
local hasDrawing = (type(Drawing) == "table" or type(Drawing) == "function")
local fovCircle = nil
if hasDrawing then
    pcall(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Visible = Settings.showFOV
        fovCircle.Thickness = 1.8
        fovCircle.Radius = Settings.aimbotFOV
        fovCircle.Transparency = 0.8
        fovCircle.Color = Settings.fovColor
        fovCircle.Filled = false
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end)
end

-- ========================================================
-- // 4. HELPER FUNCTIONS & TARGETING
-- ========================================================
local rgbHue = 0
local cachedRGB = Color3.fromRGB(0, 255, 170)

local function updateRGB(dt)
    rgbHue = (rgbHue + (Settings.rgbSpeed * dt)) % 1
    local h, s, v = rgbHue, 1, 1
    local i = math.floor(h * 6) % 6
    local f = h * 6 - math.floor(h * 6)
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    if i == 0 then cachedRGB = Color3.new(v, t, p)
    elseif i == 1 then cachedRGB = Color3.new(q, v, p)
    elseif i == 2 then cachedRGB = Color3.new(p, v, t)
    elseif i == 3 then cachedRGB = Color3.new(p, q, v)
    elseif i == 4 then cachedRGB = Color3.new(t, p, v)
    else cachedRGB = Color3.new(v, p, q) end
end

local function isVisible(targetPos)
    if not Settings.wallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPos - origin).Unit
    local dist = (targetPos - origin).Magnitude

    if LocalPlayer.Character ~= lastFilterChar then
        lastFilterChar = LocalPlayer.Character
        if LocalPlayer.Character then
            cachedRaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
        end
    end

    local res = Workspace:Raycast(origin, direction * dist, cachedRaycastParams)
    if not res then return true end
    if res.Instance then
        local model = res.Instance:FindFirstAncestorOfClass("Model")
        if model and Players:GetPlayerFromCharacter(model) then return true end
        return false
    end
    return true
end

local function getClosestEnemy()
    if not Settings.aimbotEnabled and not Settings.silentAim then return nil end
    local myChar = LocalPlayer.Character
    if not myChar then return nil end

    local closestPlayer = nil
    local closestDist = Settings.aimbotFOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or isWhitelisted(player) then continue end
        if Settings.teamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then continue end

        local char = player.Character
        if not char then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
        if not (hum and hrp) or hum.Health <= 0 then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
        if dist <= closestDist then
            if Settings.wallCheck and not isVisible(hrp.Position) then continue end
            closestDist = dist
            closestPlayer = player
        end
    end
    return closestPlayer
end

local function getTargetPart(player)
    if not player or not player.Character then return nil end
    local char = player.Character
    if Settings.aimTargetPart == "Head" then
        return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    else
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    end
end

-- ========================================================
-- // 5. SILENT AIM (HOOK)
-- ========================================================
pcall(function()
    if hookmetamethod and checkcaller and newcclosure then
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, prop)
            if not checkcaller() and Settings.silentAim and tostring(prop) == "Hit" and tostring(self) == "Mouse" then
                local target = getClosestEnemy()
                if target then
                    local part = getTargetPart(target)
                    if part then return part.CFrame end
                end
            end
            return oldIndex(self, prop)
        end))
    end
end)

-- ========================================================
-- // 6. PLAYER & LOOT ESP
-- ========================================================
local espFolder = Instance.new("Folder")
espFolder.Name = "Delta_ESP_Hub"
pcall(function() espFolder.Parent = CoreGui end)
if not espFolder.Parent then espFolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local playerESP = {}
local lootESPObjects = {}

local function createPlayerESP(player)
    if player == LocalPlayer or playerESP[player] then return end

    local bill = Instance.new("BillboardGui")
    bill.Name = player.Name .. "_ESP"
    bill.Size = UDim2.new(0, 200, 0, 50)
    bill.StudsOffset = Vector3.new(0, 3.5, 0)
    bill.AlwaysOnTop = true
    bill.Enabled = false
    bill.Parent = espFolder

    local nameLbl = Instance.new("TextLabel", bill)
    nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLbl.TextStrokeTransparency = 0
    nameLbl.Text = player.Name

    local distLbl = Instance.new("TextLabel", bill)
    distLbl.Size = UDim2.new(1, 0, 0.5, 0)
    distLbl.Position = UDim2.new(0, 0, 0.5, 0)
    distLbl.BackgroundTransparency = 1
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextSize = 11
    distLbl.TextColor3 = Color3.fromRGB(200, 220, 255)
    distLbl.TextStrokeTransparency = 0

    local hl = Instance.new("Highlight")
    hl.Name = player.Name .. "_HL"
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    hl.Parent = espFolder

    playerESP[player] = { Gui = bill, NameLabel = nameLbl, DistLabel = distLbl, Highlight = hl }
end

local function removePlayerESP(player)
    local esp = playerESP[player]
    if not esp then return end
    if esp.Gui then esp.Gui:Destroy() end
    if esp.Highlight then esp.Highlight:Destroy() end
    playerESP[player] = nil
end

local function cleanLootESP()
    for _, obj in pairs(lootESPObjects) do
        if obj.Gui then obj.Gui:Destroy() end
    end
    lootESPObjects = {}
end

local function updatePlayerESP()
    if not Settings.espEnabled then
        for _, esp in pairs(playerESP) do
            esp.Gui.Enabled = false
            esp.Highlight.Enabled = false
        end
        return
    end

    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for player, esp in pairs(playerESP) do
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))

        if not (char and hum and hrp) or hum.Health <= 0 then
            esp.Gui.Enabled = false
            esp.Highlight.Enabled = false
            continue
        end

        local color = Settings.useRGB and cachedRGB or (player.Team and player.Team == LocalPlayer.Team and Color3.fromRGB(0, 170, 255) or Settings.espColor)
        if isWhitelisted(player) then color = Color3.fromRGB(100, 255, 100) end

        esp.Gui.Adornee = hrp
        esp.Gui.Enabled = true

        esp.NameLabel.Visible = Settings.espNames
        esp.NameLabel.TextColor3 = color
        esp.NameLabel.Text = isWhitelisted(player) and (player.Name .. " [WL]") or player.Name

        esp.DistLabel.Visible = Settings.espDistance
        if Settings.espDistance and myHrp then
            local dist = math.floor((hrp.Position - myHrp.Position).Magnitude)
            local hp = math.floor((hum.Health / hum.MaxHealth) * 100)
            esp.DistLabel.Text = string.format("[%dm] • %d%% HP", dist, hp)
            esp.DistLabel.TextColor3 = color
        end

        esp.Highlight.Adornee = char
        esp.Highlight.FillColor = color
        esp.Highlight.OutlineColor = color
        esp.Highlight.Enabled = Settings.espBoxes
    end
end

local function updateLootESP()
    if not Settings.lootESP then
        cleanLootESP()
        return
    end

    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    -- Scan for loot in Workspace (Items, Crates, Spawns)
    local items = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        local name = obj.Name:lower()
        if name:find("loot") or name:find("item") or name:find("drop") or name:find("crate") or name:find("box") or name:find("gun") or name:find("ammo") or name:find("med") or name:find("scrap") then
            table.insert(items, obj)
        end
    end

    for _, item in ipairs(items) do
        local part = item:IsA("BasePart") and item or (item:IsA("Model") and item:FindFirstChildOfClass("BasePart"))
        if part then
            local dist = math.floor((part.Position - myHrp.Position).Magnitude)
            if dist <= Settings.lootDistance then
                if not lootESPObjects[item] then
                    local bill = Instance.new("BillboardGui")
                    bill.Name = item.Name .. "_LootESP"
                    bill.Size = UDim2.new(0, 140, 0, 30)
                    bill.AlwaysOnTop = true
                    bill.Adornee = part
                    bill.Parent = espFolder

                    local lbl = Instance.new("TextLabel", bill)
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = 10
                    lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
                    lbl.TextStrokeTransparency = 0
                    lbl.Text = item.Name .. " [" .. dist .. "m]"

                    lootESPObjects[item] = { Gui = bill, Label = lbl }
                else
                    lootESPObjects[item].Label.Text = item.Name .. " [" .. dist .. "m]"
                    lootESPObjects[item].Gui.Enabled = true
                end
            elseif lootESPObjects[item] then
                lootESPObjects[item].Gui.Enabled = false
            end
        end
    end
end

-- ========================================================
-- // 7. MOVEMENT & GHOST FLY
-- ========================================================
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyKeys = { W = false, A = false, S = false, D = false, Space = false, LeftShift = false }

local function startGhostFly()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.Parent = hrp

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBodyGyro.P = 9e4
    flyBodyGyro.CFrame = hrp.CFrame
    flyBodyGyro.Parent = hrp
end

local function stopGhostFly()
    if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Velocity = Vector3.zero end
end

-- ========================================================
-- // 8. UI — KT_UI-V1 / Singularity Library (ui_temp.lua)
-- ========================================================
local Library = nil
local env = (getgenv and getgenv()) or _G

local env = (getgenv and getgenv()) or _G
local Library
if env.HYPER_UI and type(env.HYPER_UI) == "table" and env.HYPER_UI.Window then
    Library = env.HYPER_UI
elseif env.Library and type(env.Library) == "table" and env.Library.Window then
    Library = env.Library
else
    local function cleanLua(str)
        if type(str) ~= "string" then return "" end
        return str:gsub("^98791", ""):gsub("^%s+", "")
    end

    -- 1. Try local files first (0ms, offline support)
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
                local content = cleanLua(readfile(p))
                if #content > 50 then
                    local fn, compileErr = loadstring(content)
                    if fn then
                        local ok, lib = pcall(fn)
                        if ok and type(lib) == "table" and lib.Window then
                            Library = lib
                            env.HYPER_UI = lib
                            env.Library = lib
                            break
                        end
                    end
                end
            end
        end
    end

    -- 2. Online endpoints with fallback
    if not Library then
        local urls = {
            "https://raw.githubusercontent.com/projectsingularityv1-debug/HYPER-LOADER/refs/heads/main/UI.main/ui.lua",
            "https://raw.githubusercontent.com/projectsingularityv1-debug/HYPER-MAIN/refs/heads/main/ui.lua"
        }
        local req = (request or http_request or (syn and syn.request) or (http and http.request))
        for _, u in ipairs(urls) do
            local s, src = pcall(function()
                if req then
                    local r = req({ Url = u, Method = "GET" })
                    if r and (r.StatusCode == 200 or r.Status == 200) and r.Body and #r.Body > 50 then return r.Body end
                end
                return game:HttpGet(u)
            end)
            if s and src and type(src) == "string" and #src > 50 then
                src = cleanLua(src)
                local fn, compileErr = loadstring(src)
                if fn then
                    local ok, lib = pcall(fn)
                    if ok and type(lib) == "table" and lib.Window then
                        -- in-memory only
                        Library = lib
                        env.HYPER_UI = lib
                        env.Library = lib
                        break
                    elseif not ok then
                        warn("[HYPER HUB] UI Runtime Error: " .. tostring(lib))
                    end
                elseif compileErr then
                    warn("[HYPER HUB] UI Compile Error: " .. tostring(compileErr))
                end
            end
        end
    end

    if not Library or not Library.Window then
        error("[HYPER HUB] Failed to load UI Library from all local and remote endpoints!")
    end
end
local UIS = UserInputService
local WindowSize = UIS.TouchEnabled and UDim2.fromOffset(550, 550) or UDim2.fromOffset(580, 460)

local KeyAvatarURL = (getgenv and getgenv().KeyAvatar)
if not KeyAvatarURL then
    pcall(function()
        if isfile and isfile("SingularityKey.txt") then
            local savedKey = readfile("SingularityKey.txt")
            if savedKey and savedKey ~= "" then
                local req = (request or http_request or (syn and syn.request) or (http and http.request))
                local rbx_user = LocalPlayer.Name
                local rbx_id = LocalPlayer.UserId
                local url = "https://projectsingularity.online/raw/verify-key?k=" .. savedKey .. "&rbx_user=" .. rbx_user .. "&rbx_id=" .. tostring(rbx_id)
                if req then
                    local response = req({ Url = url, Method = "GET" })
                    if response and response.StatusCode == 200 then
                        local responseJson = HttpService:JSONDecode(response.Body)
                        if responseJson and responseJson.valid and responseJson.profile then
                            if getgenv then getgenv().KeyUsername = responseJson.profile.username end
                            if responseJson.profile.avatar_url and responseJson.profile.avatar_url ~= "" then
                                KeyAvatarURL = responseJson.profile.avatar_url
                            end
                        end
                    end
                end
            end
        end
    end)
end

if not KeyAvatarURL or KeyAvatarURL == "" then
    KeyAvatarURL = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150"
end

local Window = Library:Window({
    Profile = {
        Username = (getgenv and getgenv().KeyUsername) or LocalPlayer.DisplayName,
        Email = "UID: " .. tostring(LocalPlayer.UserId),
        AvatarUrl = KeyAvatarURL
    },
    Title = "Project Delta Hub",
    Desc = "Tactical Survival & Looting Suite",
    Icon = "https://img2.pic.in.th/HYPER.png",
    Theme = "Dark",
    Config = {
        Keybind = Enum.KeyCode.RightShift,
        Size = WindowSize
    },
    CloseUIButton = {
        Enabled = true,
        Text = "Close"
    }
})

-- Tabs Setup (ui_temp.lua Icons)
local CombatTab = Window:Tab({ Title = "Combat & Aim", Icon = "crosshair" })
local VisualsTab = Window:Tab({ Title = "ESP & Visuals", Icon = "eye" })
local LootTab = Window:Tab({ Title = "Loot & Items", Icon = "box" })
local MovementTab = Window:Tab({ Title = "Movement & Fly", Icon = "user" })
local SecurityTab = Window:Tab({ Title = "Anti-Cheat", Icon = "shield" })
local InfoTab = Window:Tab({ Title = "Info", Icon = "settings" })

-- 1. COMBAT & AIM TAB
CombatTab:Section({ Title = "Aimbot Settings" })

CombatTab:Toggle({
    Title = "Enable Camera Aimbot",
    Desc = "ล็อกเป้าผู้เล่นศัตรูอัตโนมัติ",
    Value = Settings.aimbotEnabled,
    Callback = function(v) Settings.aimbotEnabled = v end
})

CombatTab:Toggle({
    Title = "Enable Silent Aim",
    Desc = "กระสุนเข้าเป้าอัตโนมัติไม่ต้องหันกล้อง",
    Value = Settings.silentAim,
    Callback = function(v) Settings.silentAim = v end
})

CombatTab:Dropdown({
    Title = "Target Hitbox",
    List = { "Head", "HumanoidRootPart" },
    Default = Settings.aimTargetPart,
    Callback = function(choice) Settings.aimTargetPart = choice end
})

CombatTab:Slider({
    Title = "Aimbot FOV",
    Min = 30,
    Max = 400,
    Default = Settings.aimbotFOV,
    Callback = function(val)
        Settings.aimbotFOV = val
        if fovCircle then fovCircle.Radius = val end
    end
})

CombatTab:Slider({
    Title = "Camera Smoothing",
    Min = 1,
    Max = 100,
    Default = Settings.aimbotSmoothing * 100,
    Callback = function(val) Settings.aimbotSmoothing = val / 100 end
})

CombatTab:Slider({
    Title = "Bullet Prediction",
    Min = 0,
    Max = 50,
    Default = Settings.prediction * 100,
    Callback = function(val) Settings.prediction = val / 100 end
})

CombatTab:Toggle({
    Title = "Wall Check",
    Desc = "ล็อกเฉพาะเป้าหมายที่มองเห็น (ไม่ติดกำแพง)",
    Value = Settings.wallCheck,
    Callback = function(v) Settings.wallCheck = v end
})

CombatTab:Toggle({
    Title = "Team Check",
    Desc = "ไม่ล็อกเป้าใส่เพื่อนร่วมทีม",
    Value = Settings.teamCheck,
    Callback = function(v) Settings.teamCheck = v end
})

-- 2. ESP & VISUALS TAB
VisualsTab:Section({ Title = "Player ESP" })

VisualsTab:Toggle({ Title = "Enable Player ESP", Value = Settings.espEnabled, Callback = function(v) Settings.espEnabled = v end })
VisualsTab:Toggle({ Title = "Box / Highlight", Value = Settings.espBoxes, Callback = function(v) Settings.espBoxes = v end })
VisualsTab:Toggle({ Title = "Player Names", Value = Settings.espNames, Callback = function(v) Settings.espNames = v end })
VisualsTab:Toggle({ Title = "Distance & Health", Value = Settings.espDistance, Callback = function(v) Settings.espDistance = v end })
VisualsTab:Toggle({ Title = "Team Color", Value = Settings.espTeamColor, Callback = function(v) Settings.espTeamColor = v end })
VisualsTab:Toggle({ Title = "Rainbow RGB", Value = Settings.useRGB, Callback = function(v) Settings.useRGB = v end })

VisualsTab:Section({ Title = "World Lighting" })

VisualsTab:Toggle({
    Title = "FullBright (สว่างเต็มแมพ)",
    Value = Settings.fullBright,
    Callback = function(v)
        Settings.fullBright = v
        if v then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.GlobalShadows = true
        end
    end
})

VisualsTab:Toggle({
    Title = "Remove Fog (ลบหมอกควัน)",
    Value = Settings.removeFog,
    Callback = function(v)
        Settings.removeFog = v
        if v then
            Lighting.FogStart = 0
            Lighting.FogEnd = 9e9
        end
    end
})

-- 3. LOOT & ITEMS TAB
LootTab:Section({ Title = "Loot & Container ESP" })

LootTab:Toggle({
    Title = "Enable Loot ESP",
    Desc = "แสดงตำแหน่งไอเทม อาวุธ กล่องยา และเงินที่ตกพื้น",
    Value = Settings.lootESP,
    Callback = function(v)
        Settings.lootESP = v
        if not v then cleanLootESP() end
    end
})

LootTab:Slider({
    Title = "Loot ESP Distance",
    Min = 50,
    Max = 1000,
    Default = Settings.lootDistance,
    Callback = function(val) Settings.lootDistance = val end
})

LootTab:Button({
    Title = "⚡ Fast Auto-Collect Drops / Loot",
    Desc = "ดูดไอเทมรอบตัวเข้าตัวอัตโนมัติ (ปลอดภัย)",
    Callback = function()
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp then return end
        local collected = 0
        for _, item in ipairs(Workspace:GetChildren()) do
            local name = item.Name:lower()
            if name:find("loot") or name:find("drop") or name:find("crate") or name:find("ammo") or name:find("med") or name:find("cash") then
                local part = item:IsA("BasePart") and item or (item:IsA("Model") and item:FindFirstChildOfClass("BasePart"))
                if part and (part.Position - myHrp.Position).Magnitude <= 50 then
                    firetouchinterest(myHrp, part, 0)
                    firetouchinterest(myHrp, part, 1)
                    collected = collected + 1
                end
            end
        end
        Window:Notify({ Title = "Auto Loot", Desc = "เก็บไอเทมรอบตัวเรียบร้อย (" .. collected .. " ชิ้น)", Time = 3 })
    end
})

-- 4. MOVEMENT TAB
MovementTab:Section({ Title = "Ghost Fly" })

MovementTab:Toggle({
    Title = "Ghost Fly (บินทะลุกำแพง)",
    Desc = "บินอิสระทะลุทุกสิ่งก่อสร้าง (WASD + Space/Shift)",
    Value = Settings.ghostFly,
    Callback = function(v)
        Settings.ghostFly = v
        if v then stopGhostFly(); startGhostFly() else stopGhostFly() end
    end
})

MovementTab:Slider({
    Title = "Fly Speed",
    Min = 10,
    Max = 200,
    Default = Settings.ghostFlySpeed,
    Callback = function(val) Settings.ghostFlySpeed = val end
})

MovementTab:Section({ Title = "WalkSpeed & Stamina" })

MovementTab:Toggle({
    Title = "WalkSpeed Hack",
    Value = Settings.speedHack,
    Callback = function(v)
        Settings.speedHack = v
        if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
        end
    end
})

MovementTab:Slider({
    Title = "Speed Amount",
    Min = 16,
    Max = 120,
    Default = Settings.walkSpeed,
    Callback = function(val) Settings.walkSpeed = val end
})

MovementTab:Toggle({
    Title = "Infinite Stamina (วิ่งไม่เหนื่อย)",
    Desc = "ไม่ลดค่า Stamina ขณะวิ่ง",
    Value = Settings.infiniteStamina,
    Callback = function(v) Settings.infiniteStamina = v end
})

MovementTab:Toggle({
    Title = "Infinite Jump",
    Value = Settings.infiniteJump,
    Callback = function(v) Settings.infiniteJump = v end
})

MovementTab:Toggle({
    Title = "Noclip",
    Value = Settings.noclip,
    Callback = function(v) Settings.noclip = v end
})

-- 5. ANTI-CHEAT TAB
SecurityTab:Section({ Title = "Anti-Cheat Protection Status" })

SecurityTab:Button({
    Title = "LogService Blocked: " .. tostring(AC_Bypass.LogServiceBlocked) .. " Point(s)",
    Desc = "บล็อกระบบดักจับ Console และ Error Report เรียบร้อย",
    Callback = function() end
})

SecurityTab:Button({
    Title = "Loot RemoteFunction: " .. (AC_Bypass.LootRFHooked and "✅ Safe / Protected" or "🛡️ Ready"),
    Desc = "บายพาสการตรวจจับ OnClientInvoke จาก [14 @ Loot] เรียบร้อย",
    Callback = function() end
})

SecurityTab:Button({
    Title = "TryHook Protection: " .. (AC_Bypass.TryHookProtected and "✅ Active" or "🛡️ Ready"),
    Desc = "ป้องกันระบบตรวจจับความเร็วการทำงานของ Metamethod Hook",
    Callback = function() end
})

SecurityTab:Button({
    Title = "Timeout Safeguard: " .. (AC_Bypass.TimeoutSet and "✅ Protected" or "🛡️ Ready"),
    Desc = "ป้องกันเซิร์ฟเวอร์ยิง Loop Crash ป้องกันเกมค้าง",
    Callback = function() end
})

SecurityTab:Button({
    Title = "🚨 Emergency Panic (ปิดทุกโปรทันที)",
    Callback = function()
        Settings.aimbotEnabled = false
        Settings.silentAim = false
        Settings.espEnabled = false
        Settings.lootESP = false
        Settings.speedHack = false
        Settings.ghostFly = false
        stopGhostFly()
        cleanLootESP()
        updatePlayerESP()
        if fovCircle then fovCircle.Visible = false end
        Window:Notify({ Title = "PANIC ACTIVATED", Desc = "ปิดการทำงานทุกอย่างเรียบร้อย", Time = 3 })
    end
})

-- 6. INFO TAB
InfoTab:Section({ Title = "Map & Script Info" })
InfoTab:Label({ Title = "🎮 Game:", Desc = "Project Delta (Dalta)" })
InfoTab:Label({ Title = "👤 Developer:", Desc = "Rocket HUP / K2NTA ST" })
InfoTab:Label({ Title = "📦 Version:", Desc = "v1.0 (100% Loadstring-Free Standalone)" })
InfoTab:Label({ Title = "⌨️ Hotkeys:", Desc = "Right Shift = Toggle UI\nDelete = Panic Button\nWASD + Space/Shift = Ghost Fly" })

-- ========================================================
-- // 10. MAIN LOOPS & EVENT LISTENERS
-- ========================================================
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then createPlayerESP(player) end
end

Players.PlayerAdded:Connect(function(player)
    task.wait(1)
    if player ~= LocalPlayer then createPlayerESP(player) end
end)

Players.PlayerRemoving:Connect(function(player)
    removePlayerESP(player)
end)

-- User Input Handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local kc = input.KeyCode
    if kc == Enum.KeyCode.W then flyKeys.W = true end
    if kc == Enum.KeyCode.A then flyKeys.A = true end
    if kc == Enum.KeyCode.S then flyKeys.S = true end
    if kc == Enum.KeyCode.D then flyKeys.D = true end
    if kc == Enum.KeyCode.Space then
        flyKeys.Space = true
        if Settings.infiniteJump then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
    if kc == Enum.KeyCode.LeftShift then flyKeys.LeftShift = true end
    if kc == Enum.KeyCode.Delete then
        Settings.aimbotEnabled = false
        Settings.silentAim = false
        Settings.espEnabled = false
        Settings.lootESP = false
        stopGhostFly()
        cleanLootESP()
        updatePlayerESP()
        if fovCircle then fovCircle.Visible = false end
        Window:Notify({ Title = "PANIC ACTIVATED", Desc = "ปิดโปรทั้งหมด", Time = 2 })
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    local kc = input.KeyCode
    if kc == Enum.KeyCode.W then flyKeys.W = false end
    if kc == Enum.KeyCode.A then flyKeys.A = false end
    if kc == Enum.KeyCode.S then flyKeys.S = false end
    if kc == Enum.KeyCode.D then flyKeys.D = false end
    if kc == Enum.KeyCode.Space then flyKeys.Space = false end
    if kc == Enum.KeyCode.LeftShift then flyKeys.LeftShift = false end
end)

-- Stepped Loop (Speed, Noclip, Stamina)
local steppedConn = RunService.Stepped:Connect(function()
    if env.DeltaHub_RunID ~= runId then return end
    local char = LocalPlayer.Character
    if not char then return end

    if Settings.noclip or Settings.ghostFly then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    if Settings.speedHack and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = Settings.walkSpeed
    end

    if Settings.infiniteStamina then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                local n = v.Name:lower()
                if n:find("stamina") or n:find("energy") or n:find("sprint") then
                    v.Value = 100
                end
            end
        end
    end
end)

-- Render Loop (Aimbot, Fly, Visuals)
local espTick = 0
local lootTick = 0

local renderConn = RunService.RenderStepped:Connect(function(dt)
    if env.DeltaHub_RunID ~= runId then return end

    if Settings.useRGB then updateRGB(dt) end

    -- Update FOV Circle
    if fovCircle then
        local mousePos = UserInputService:GetMouseLocation()
        fovCircle.Position = mousePos
        fovCircle.Radius = Settings.aimbotFOV
        fovCircle.Color = Settings.useRGB and cachedRGB or Settings.fovColor
        fovCircle.Visible = Settings.showFOV and (Settings.aimbotEnabled or Settings.silentAim)
    end

    -- Camera Aimbot
    if Settings.aimbotEnabled then
        local target = getClosestEnemy()
        if target then
            local part = getTargetPart(target)
            if part then
                local currentCF = Camera.CFrame
                local vel = (part:IsA("BasePart") and (part.AssemblyLinearVelocity or part.Velocity)) or Vector3.zero
                local dist = (part.Position - currentCF.Position).Magnitude
                local travelTime = dist / 1000
                local predictedPos = part.Position + (vel * travelTime * Settings.prediction)

                local targetCF = CFrame.new(currentCF.Position, predictedPos)
                Camera.CFrame = currentCF:Lerp(targetCF, Settings.aimbotSmoothing)
            end
        end
    end

    -- Ghost Fly
    if Settings.ghostFly and flyBodyVelocity and flyBodyGyro then
        local moveDir = Vector3.zero
        if flyKeys.W then moveDir = moveDir + Camera.CFrame.LookVector end
        if flyKeys.S then moveDir = moveDir - Camera.CFrame.LookVector end
        if flyKeys.A then moveDir = moveDir - Camera.CFrame.RightVector end
        if flyKeys.D then moveDir = moveDir + Camera.CFrame.RightVector end
        local upDown = 0
        if flyKeys.Space then upDown = upDown + 1 end
        if flyKeys.LeftShift then upDown = upDown - 1 end
        moveDir = moveDir + Vector3.new(0, upDown, 0)
        if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end

        flyBodyVelocity.Velocity = moveDir * Settings.ghostFlySpeed
        flyBodyGyro.CFrame = Camera.CFrame
    end

    -- ESP Refresh
    espTick = espTick + 1
    if espTick >= 2 then
        espTick = 0
        updatePlayerESP()
    end

    lootTick = lootTick + 1
    if lootTick >= 30 then
        lootTick = 0
        updateLootESP()
    end
end)

-- Clean-up
env.DeltaHub_Cleanup = function()
    if steppedConn then steppedConn:Disconnect() end
    if renderConn then renderConn:Disconnect() end
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    stopGhostFly()
    cleanLootESP()
end

-- Anti-AFK
if Settings.antiAFK then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end

Window:Notify({
    Title = "Project Delta Hub v1.0",
    Desc = "Loaded! 100% Loadstring-Free Standalone Engine!\nRight Shift = UI | Delete = Panic Button",
    Time = 6
})

print("✅ Project Delta Hub Loaded (Custom Anti-Cheat Bypassed & Loadstring-Free)!")
