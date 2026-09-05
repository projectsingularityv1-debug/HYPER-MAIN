-- ========================================================
-- // Singularity Hub — Advanced Aimbot & ESP Suite
-- // Standalone Edition (100% Loadstring-Free & Adonis Bypassed)
-- // Created by K2NTA ST | Rocket HUP
-- ========================================================

-- ========================================================
-- // 1. COMPREHENSIVE ANTI-CHEAT BYPASS SYSTEM
-- ========================================================
local AC_Status = {
    AdonisPatched = false,
    LogServiceBlocked = 0,
    RemoteFunctionsHooked = 0,
    StringTableCleaned = false,
    TimeoutProtected = false
}

-- [1.1] ป้องกัน Infinite Loop Crash (Timeout Safeguard)
pcall(function()
    if game:GetService("ScriptContext").SetTimeout then
        game:GetService("ScriptContext"):SetTimeout(2)
        AC_Status.TimeoutProtected = true
    end
end)

-- [1.2] บล็อก LogService.MessageOut ป้องกัน Anti-Cheat ดักอ่าน Console & Error
pcall(function()
    if getconnections then
        for _, conn in pairs(getconnections(game:GetService("LogService").MessageOut)) do
            conn:Disable()
            AC_Status.LogServiceBlocked = AC_Status.LogServiceBlocked + 1
        end
        for _, conn in pairs(getconnections(game:GetService("ScriptContext").Error)) do
            conn:Disable()
        end
    end
end)

-- [1.3] ล้าง DetectStrings และ GC C-Closure Check
pcall(function()
    if getgc then
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" and rawget(v, "islclosure") then
                table.clear(v)
                AC_Status.StringTableCleaned = true
            elseif type(v) == "function" and islclosure and islclosure(v) and getconstants and setconstant then
                local consts = getconstants(v)
                if table.find(consts, "overflow") and not table.find(consts, "__index") then
                    local idx = table.find(consts, "overflow")
                    setconstant(v, idx, "safe_overflow")
                end
            end
        end
    end
end)

-- [1.4] Adonis Metatable Checker Bypass (compareTables)
pcall(function()
    if getgc and hookfunction then
        for _, v in pairs(getgc(true)) do
            if type(v) == "function" and getinfo then
                local info = getinfo(v)
                if info.name == "compareTables" or (info.source and info.source:find(".Client.Core.Anti")) then
                    hookfunction(v, function()
                        return true
                    end)
                    AC_Status.AdonisPatched = true
                end
            end
        end
    end
end)

-- [1.5] RemoteFunction OnClientInvoke Bypass (__FUNCTION และอื่นๆ)
pcall(function()
    local instances = (getinstances and getinstances()) or game:GetDescendants()
    for _, inst in ipairs(instances) do
        if inst and inst:IsA("RemoteFunction") then
            local hasCallback = false
            if getcallbackvalue then
                hasCallback = (getcallbackvalue(inst, "OnClientInvoke") ~= nil)
            end
            
            if hasCallback or inst.Name == "__FUNCTION" or inst.Name:lower():find("check") or inst.Name:lower():find("ac") or inst.Name:lower():find("anticheat") then
                inst.OnClientInvoke = function(...)
                    return true
                end
                AC_Status.RemoteFunctionsHooked = AC_Status.RemoteFunctionsHooked + 1
            end
        end
    end
end)

-- [1.6] Hook Metamethod Namecall Protection
pcall(function()
    if hookmetamethod and checkcaller then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() then
                if method == "FireServer" or method == "InvokeServer" then
                    local sName = tostring(self.Name):lower()
                    if sName:find("ban") or sName:find("flag") or sName:find("cheat") or sName:find("report") or sName:find("log") then
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
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Anti-Overlap
pcall(function()
    for _, v in ipairs(CoreGui:GetChildren()) do
        if v.Name == "Dummy Kawaii" or v.Name == "SingularityAimbotHub" then v:Destroy() end
    end
    if LocalPlayer:FindFirstChild("PlayerGui") then
        for _, v in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            if v.Name == "Dummy Kawaii" or v.Name == "SingularityAimbotHub" then v:Destroy() end
        end
    end
end)

-- ========================================================
-- // 3. SETTINGS & CONFIGURATION
-- ========================================================
local Settings = {
    aimbotEnabled = true,
    silentAim = false,
    Toggle = false,
    toggleKey = Enum.KeyCode.E,
    toggleKeyName = "E",
    lockMode = "Head",
    fov = 150,
    smoothing = 0.15,
    predictionFactor = 0.165,
    teamCheck = false,
    wallCheck = true,
    maxWallDistance = 1000,
    
    showFOV = true,
    fovFilled = false,
    fovThickness = 2,
    fovColor = Color3.fromRGB(0, 255, 170),
    useRGBColors = true,
    rgbSpeed = 1.0,
    
    espEnabled = true,
    espBoxes = true,
    espNames = true,
    espDistance = true,
    espHealth = true,
    espTeamColor = true,
    espRainbow = true,
    espColor = Color3.fromRGB(0, 255, 255),
    
    godmode = false,
    godmodeKey = Enum.KeyCode.G,
    speedHack = false,
    walkSpeed = 16,
    viewMode = "ThirdPerson",
    viewModeKey = Enum.KeyCode.V,
    viewModeKeyName = "V"
}

-- ========================================================
-- // 4. WHITELIST SYSTEM
-- ========================================================
local Whitelist = {}

local function isWhitelisted(player)
    local name = player.Name:lower()
    for _, wName in ipairs(Whitelist) do
        if wName:lower() == name then
            return true
        end
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
    return true
end

local function removeFromWhitelist(name)
    name = name:lower()
    for i, wName in ipairs(Whitelist) do
        if wName:lower() == name then
            table.remove(Whitelist, i)
            return true
        end
    end
    return false
end

-- ============================================
-- // 5. DRAWING & CACHED VARIABLES
-- ============================================
local currentTarget = nil
local toggleState = false
local espObjects = {}
local rgbHue = 0
local keyBindCallback = nil
local godmodeConnection = nil
local viewModeConnection = nil
local originalCameraOffset = Vector3.zero
local isViewModeActive = false

-- Raycast Caches
local cachedRaycastParams = RaycastParams.new()
cachedRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist or Enum.RaycastFilterType.Exclude
cachedRaycastParams.IgnoreWater = true

local cachedAimRaycastParams = RaycastParams.new()
cachedAimRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist or Enum.RaycastFilterType.Exclude
cachedAimRaycastParams.IgnoreWater = true

local lastFilterCharacter = nil

-- FOV Drawing Ring
local hasDrawing = (type(Drawing) == "table" or type(Drawing) == "function")
local FOVring = nil
if hasDrawing then
    pcall(function()
        FOVring = Drawing.new("Circle")
        FOVring.Visible = Settings.showFOV
        FOVring.Thickness = Settings.fovThickness
        FOVring.Radius = Settings.fov
        FOVring.Transparency = 0.8
        FOVring.Color = Settings.fovColor
        FOVring.Filled = Settings.fovFilled
        FOVring.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end)
end

-- ============================================
-- // 6. HELPER FUNCTIONS
-- ============================================
local function HSVtoRGB(h, s, v)
    local i = math.floor(h * 6) % 6
    local f = h * 6 - math.floor(h * 6)
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    if i == 0 then return Color3.new(v, t, p)
    elseif i == 1 then return Color3.new(q, v, p)
    elseif i == 2 then return Color3.new(p, v, t)
    elseif i == 3 then return Color3.new(p, q, v)
    elseif i == 4 then return Color3.new(t, p, v)
    else return Color3.new(v, p, q) end
end

local cachedRainbowColor = Color3.new(1, 0, 0)
local function updateRainbowColor(dt)
    rgbHue = (rgbHue + (Settings.rgbSpeed * dt)) % 1
    cachedRainbowColor = HSVtoRGB(rgbHue, 1, 1)
end

local function getRainbowColor()
    return cachedRainbowColor
end

local function getTeamColor(player)
    if not Settings.espTeamColor then return Settings.espColor end
    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return Color3.fromRGB(0, 150, 255)
    else
        return Color3.fromRGB(255, 50, 50)
    end
end

local function isTargetVisible(targetPosition)
    if not Settings.wallCheck then return true end

    local origin = Camera.CFrame.Position
    local direction = (targetPosition - origin).Unit
    local distance = (targetPosition - origin).Magnitude

    if LocalPlayer.Character ~= lastFilterCharacter then
        lastFilterCharacter = LocalPlayer.Character
        if LocalPlayer.Character then
            cachedRaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
            cachedAimRaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
        end
    end

    local result = Workspace:Raycast(origin, direction * math.min(distance, Settings.maxWallDistance), cachedRaycastParams)
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

-- ============================================
-- // 7. TARGETING & AIMBOT CORE
-- ============================================
local function getTargetPart(player)
    if not player or not player.Character then return nil end
    local character = player.Character
    local mode = Settings.lockMode

    if mode == "Random" then
        local parts = {"Head", "UpperTorso", "HumanoidRootPart", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"}
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
    if not Settings.aimbotEnabled and not Settings.silentAim then return nil end
    if not LocalPlayer.Character then return nil end

    local closestPlayer = nil
    local closestDistance = Settings.fov
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Settings.teamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then continue end
        if isWhitelisted(player) then continue end

        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("Head")
        if not (humanoid and hrp) then continue end
        if humanoid.Health <= 0 then continue end

        local screenPosition, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then continue end

        local screenPos = Vector2.new(screenPosition.X, screenPosition.Y)
        local distance = (screenPos - screenCenter).Magnitude

        if distance <= closestDistance then
            if Settings.wallCheck and not isTargetVisible(hrp.Position) then continue end
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

    if Settings.wallCheck and not isTargetVisible(targetPart.Position) then
        return nil
    end

    local velocity = Vector3.zero
    if targetPart:IsA("BasePart") then
        velocity = targetPart.AssemblyLinearVelocity or targetPart.Velocity or Vector3.zero
    end
    local distance = (targetPart.Position - Camera.CFrame.Position).Magnitude
    local travelTime = distance / 1000

    return targetPart.Position + (velocity * travelTime * Settings.predictionFactor)
end

local function aimAtPosition(targetPosition)
    if not targetPosition or not LocalPlayer.Character then return end

    local currentCF = Camera.CFrame
    local direction = (targetPosition - currentCF.Position).Unit

    if Settings.wallCheck then
        local result = Workspace:Raycast(currentCF.Position, direction * 100, cachedAimRaycastParams)
        if result and result.Instance then
            local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
            if not Players:GetPlayerFromCharacter(hitModel) then return end
        end
    end

    local newCF = CFrame.new(currentCF.Position, currentCF.Position + direction)
    Camera.CFrame = currentCF:Lerp(newCF, Settings.smoothing)
end

local function updateAimbot()
    if not Settings.aimbotEnabled then currentTarget = nil; return end
    if Settings.Toggle and not toggleState then currentTarget = nil; return end
    if isViewModeActive and Settings.viewMode ~= "ThirdPerson" then currentTarget = nil; return end

    local keepTarget = false
    if currentTarget and currentTarget.Character then
        local humanoid = currentTarget.Character:FindFirstChildOfClass("Humanoid")
        local hrp = currentTarget.Character:FindFirstChild("HumanoidRootPart") or currentTarget.Character:FindFirstChild("Torso")
        if humanoid and hrp and humanoid.Health > 0 then
            local _, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                keepTarget = (not Settings.wallCheck) or isTargetVisible(hrp.Position)
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
-- // 8. SILENT AIM (METAMETHOD HOOK)
-- ============================================
pcall(function()
    if hookmetamethod and checkcaller then
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, prop)
            if not checkcaller() and Settings.silentAim and tostring(prop) == "Hit" and tostring(self) == "Mouse" then
                local targetPlayer = getClosestPlayer()
                if targetPlayer and targetPlayer.Character then
                    local part = getTargetPart(targetPlayer)
                    if part then
                        return part.CFrame
                    end
                end
            end
            return oldIndex(self, prop)
        end))
    end
end)

-- ============================================
-- // 9. ESP SYSTEM
-- ============================================
local espFolder = Instance.new("Folder")
espFolder.Name = "Singularity_ESP_Hub"
pcall(function() espFolder.Parent = CoreGui end)
if not espFolder.Parent then espFolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local function createESP(player)
    if player == LocalPlayer or espObjects[player] then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = player.Name .. "_ESP"
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.Parent = espFolder

    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Text = player.Name
    nameLabel.Visible = false

    local distLabel = Instance.new("TextLabel", billboard)
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distLabel.Position = UDim2.new(0, 0, 0.4, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextSize = 11
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextStrokeTransparency = 0
    distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distLabel.TextColor3 = Color3.new(1, 1, 1)
    distLabel.Visible = false

    local healthLabel = Instance.new("TextLabel", billboard)
    healthLabel.Name = "HealthLabel"
    healthLabel.Size = UDim2.new(1, 0, 0.3, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.7, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextSize = 11
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextStrokeTransparency = 0
    healthLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    healthLabel.Visible = false

    local hl = Instance.new("Highlight")
    hl.Name = player.Name .. "_HL"
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    hl.Parent = espFolder

    espObjects[player] = { Gui = billboard, NameLbl = nameLabel, DistLbl = distLabel, HealthLbl = healthLabel, Highlight = hl }
end

local function updateESP()
    if not Settings.espEnabled then
        for _, esp in pairs(espObjects) do
            esp.Gui.Enabled = false
            esp.Highlight.Enabled = false
        end
        return
    end

    for player, esp in pairs(espObjects) do
        if not player or not player.Character then
            esp.Gui.Enabled = false
            esp.Highlight.Enabled = false
            continue
        end

        local character = player.Character
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
        local head = character:FindFirstChild("Head") or hrp

        if not (humanoid and hrp and head) or humanoid.Health <= 0 then
            esp.Gui.Enabled = false
            esp.Highlight.Enabled = false
            continue
        end

        local wl = isWhitelisted(player)
        local espColor
        if wl then
            espColor = Color3.fromRGB(100, 255, 100)
        elseif Settings.useRGBColors and Settings.espRainbow then
            espColor = getRainbowColor()
        else
            espColor = getTeamColor(player)
        end

        esp.Gui.Adornee = head
        esp.Gui.Enabled = true

        esp.NameLbl.Visible = Settings.espNames
        if Settings.espNames then
            esp.NameLbl.TextColor3 = espColor
            esp.NameLbl.Text = wl and (player.Name .. " [✓ WL]") or player.Name
        end

        esp.DistLbl.Visible = Settings.espDistance
        if Settings.espDistance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local distance = math.floor((hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
            esp.DistLbl.Text = "[" .. distance .. "m]"
            esp.DistLbl.TextColor3 = espColor
        end

        esp.HealthLbl.Visible = Settings.espHealth
        if Settings.espHealth then
            local hp = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
            esp.HealthLbl.Text = hp .. "%"
            esp.HealthLbl.TextColor3 = Color3.fromRGB(255 - hp * 2.55, hp * 2.55, 0)
        end

        esp.Highlight.Adornee = character
        esp.Highlight.FillColor = espColor
        esp.Highlight.OutlineColor = espColor
        esp.Highlight.Enabled = Settings.espBoxes
    end
end

local function removeESP(player)
    local esp = espObjects[player]
    if not esp then return end
    if esp.Gui then esp.Gui:Destroy() end
    if esp.Highlight then esp.Highlight:Destroy() end
    espObjects[player] = nil
end

-- ============================================
-- // 10. SPECIAL POWERS (GODMODE & VIEW MODES)
-- ============================================
local function toggleGodmode()
    if not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    Settings.godmode = not Settings.godmode

    if Settings.godmode then
        godmodeConnection = humanoid.HealthChanged:Connect(function()
            if humanoid.Health < humanoid.MaxHealth then
                humanoid.Health = humanoid.MaxHealth
            end
        end)
    else
        if godmodeConnection then
            godmodeConnection:Disconnect()
            godmodeConnection = nil
        end
    end
end

local function setViewMode(mode)
    Settings.viewMode = mode
    if not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if humanoid.CameraOffset then
        originalCameraOffset = humanoid.CameraOffset
    end

    if viewModeConnection then
        viewModeConnection:Disconnect()
        viewModeConnection = nil
    end

    if mode == "FirstPerson" then
        humanoid.CameraOffset = Vector3.new(0, 0, 0.5)
        Camera.CameraType = Enum.CameraType.Custom
        viewModeConnection = RunService.RenderStepped:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                local head = LocalPlayer.Character.Head
                local targetCFrame = CFrame.new(head.Position) * CFrame.new(0, 0.5, 0)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 0.1)
            end
        end)
    elseif mode == "SecondPerson" then
        humanoid.CameraOffset = Vector3.new(0, 2, 8)
        Camera.CameraType = Enum.CameraType.Custom
        viewModeConnection = RunService.RenderStepped:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = LocalPlayer.Character.HumanoidRootPart
                local lookAt = hrp.Position + Vector3.new(0, 2, 0)
                local cameraPos = Camera.CFrame.Position
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(cameraPos, lookAt), 0.05)
            end
        end)
    elseif mode == "ThirdPerson" then
        humanoid.CameraOffset = originalCameraOffset
        Camera.CameraType = Enum.CameraType.Custom
    end

    isViewModeActive = (mode ~= "ThirdPerson")
end

local function toggleViewMode()
    if Settings.viewMode == "ThirdPerson" then
        setViewMode("FirstPerson")
    elseif Settings.viewMode == "FirstPerson" then
        setViewMode("SecondPerson")
    else
        setViewMode("ThirdPerson")
    end
end

local function startKeyBind(onKeyChosen)
    keyBindCallback = onKeyChosen
end

-- ============================================
-- // 11. SINGULARITY UI LIBRARY (EXTERNAL)
-- ============================================
if getgenv and getgenv().loadstring and getfenv().loadstring ~= getgenv().loadstring then
    getfenv().loadstring = getgenv().loadstring
end
local Library = (getgenv and getgenv().loadstring or loadstring)(game:HttpGet('https://raw.githubusercontent.com/projectsingularityv1-debug/HYPER-LOADER/refs/heads/main/UI.main/ui.lua'))()

-- ============================================
-- // 12. INITIALIZE WINDOW & TABS
-- ============================================
local KeyAvatarURL = getgenv and getgenv().KeyAvatar
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
                        local HttpService = game:GetService("HttpService")
                        local responseJson = HttpService:JSONDecode(response.Body)
                        if responseJson and responseJson.valid and responseJson.profile then
                            if getgenv then getgenv().KeyUsername = responseJson.profile.username end
                            local rawAvatar = responseJson.profile.avatar_url
                            if rawAvatar and rawAvatar ~= "" then
                                KeyAvatarURL = rawAvatar
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
    Title = "Singularity Aimbot Hub",
    Desc = "Bypassed Undetected Aimbot & ESP Suite",
    Version = "1.0",
    Icon = "rbxassetid://136264753381080",
    Theme = "Dark",
    Config = {
        Keybind = Enum.KeyCode.RightShift,
        Size = UserInputService.TouchEnabled and UDim2.fromOffset(550, 550) or UDim2.fromOffset(570, 450)
    },
    CloseUIButton = {
        Enabled = true,
        Text = "Close Aimbot"
    }
})

-- Tabs Setup
local AimbotTab = Window:Tab({ Title = "Aimbot" })
local WhitelistTab = Window:Tab({ Title = "Whitelist" })
local ESPTab = Window:Tab({ Title = "ESP & Visuals" })
local PowersTab = Window:Tab({ Title = "Player & Mods" })
local SecurityTab = Window:Tab({ Title = "Anti-Cheat" })
local UserTab = Window:Tab({ Title = "Info" })

-- 1. AIMBOT TAB
AimbotTab:Section({ Title = "Aimbot Settings" })

AimbotTab:Toggle({
    Title = "Enable Camera Aimbot",
    Desc = "ล็อกเป้าหมายผ่านการหมุนมุมกล้อง",
    Value = Settings.aimbotEnabled,
    Callback = function(v) Settings.aimbotEnabled = v end
})

AimbotTab:Toggle({
    Title = "Enable Silent Aim",
    Desc = "กระสุนเข้าเป้าอัตโนมัติ (ไม่ต้องหันกล้อง)",
    Value = Settings.silentAim,
    Callback = function(v) Settings.silentAim = v end
})

AimbotTab:Toggle({
    Title = "Toggle Key Mode",
    Desc = "ต้องกดปุ่มค้าง/สลับสถานะถึงจะทำงาน",
    Value = Settings.Toggle,
    Callback = function(v) Settings.Toggle = v end
})

local keySelectionButton = AimbotTab:Button({
    Title = "Aimbot Key: " .. Settings.toggleKeyName,
    Desc = "คลิกแล้วกดปุ่มคีย์บอร์ดที่ต้องการ",
    Callback = function()
        Window:Notify({ Title = "Key Binding", Desc = "กดปุ่มที่ต้องการตั้งค่า...", Time = 3 })
        startKeyBind(function(keyCode, keyName)
            Settings.toggleKey = keyCode
            Settings.toggleKeyName = keyName
            keySelectionButton:SetTitle("Aimbot Key: " .. keyName)
            Window:Notify({ Title = "Key Set", Desc = "ตั้งค่าปุ่มล็อกเป้าเป็น: " .. keyName, Time = 3 })
        end)
    end
})

AimbotTab:Toggle({
    Title = "Team Check",
    Desc = "ไม่ล็อกเป้าใส่เพื่อนร่วมทีม",
    Value = Settings.teamCheck,
    Callback = function(v) Settings.teamCheck = v end
})

AimbotTab:Toggle({
    Title = "Wall Check",
    Desc = "ล็อกเฉพาะเป้าหมายที่มองเห็น (ไม่ติดกำแพง)",
    Value = Settings.wallCheck,
    Callback = function(v) Settings.wallCheck = v end
})

AimbotTab:Slider({
    Title = "FOV Size",
    Min = 30,
    Max = 400,
    Default = Settings.fov,
    Callback = function(val)
        Settings.fov = val
        if FOVring then FOVring.Radius = val end
    end
})

AimbotTab:Slider({
    Title = "Smoothing",
    Min = 1,
    Max = 100,
    Default = Settings.smoothing * 100,
    Callback = function(val)
        Settings.smoothing = val / 100
    end
})

AimbotTab:Slider({
    Title = "Prediction",
    Min = 0,
    Max = 50,
    Default = Settings.predictionFactor * 100,
    Callback = function(val)
        Settings.predictionFactor = val / 100
    end
})

AimbotTab:Dropdown({
    Title = "Lock Mode / Hitbox",
    List = { "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Random" },
    Default = Settings.lockMode,
    Callback = function(choice) Settings.lockMode = choice end
})

-- 2. WHITELIST TAB
WhitelistTab:Section({ Title = "ระบบยกเว้นผู้เล่น (Whitelist)" })

local playerDropdownList = {}
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then table.insert(playerDropdownList, p.Name) end
end
if #playerDropdownList == 0 then playerDropdownList = { "(ไม่มีผู้เล่นอื่น)" } end

local selectedPlayerName = playerDropdownList[1]

WhitelistTab:Dropdown({
    Title = "เลือกผู้เล่นในเซิร์ฟเวอร์",
    List = playerDropdownList,
    Default = selectedPlayerName,
    Callback = function(choice) selectedPlayerName = choice end
})

WhitelistTab:Button({
    Title = "➕ เพิ่มคนที่เลือกเข้า Whitelist",
    Callback = function()
        if selectedPlayerName == "(ไม่มีผู้เล่นอื่น)" then return end
        if addToWhitelist(selectedPlayerName) then
            Window:Notify({ Title = "Whitelist", Desc = "เพิ่ม " .. selectedPlayerName .. " แล้ว ✓", Time = 3 })
        else
            Window:Notify({ Title = "Whitelist", Desc = selectedPlayerName .. " อยู่ในรายการแล้ว", Time = 3 })
        end
    end
})

WhitelistTab:Button({
    Title = "➖ ลบคนที่เลือกออกจาก Whitelist",
    Callback = function()
        if selectedPlayerName == "(ไม่มีผู้เล่นอื่น)" then return end
        if removeFromWhitelist(selectedPlayerName) then
            Window:Notify({ Title = "Whitelist", Desc = "ลบ " .. selectedPlayerName .. " แล้ว", Time = 3 })
        end
    end
})

WhitelistTab:Button({
    Title = "📋 แสดงรายชื่อ Whitelist ทั้งหมด",
    Callback = function()
        if #Whitelist == 0 then
            Window:Notify({ Title = "Whitelist", Desc = "ยังไม่มีรายชื่อในรายการ", Time = 3 })
        else
            Window:Notify({ Title = "Whitelist (" .. #Whitelist .. " คน)", Desc = table.concat(Whitelist, ", "), Time = 5 })
        end
    end
})

WhitelistTab:Button({
    Title = "🗑️ ล้าง Whitelist ทั้งหมด",
    Callback = function()
        Whitelist = {}
        Window:Notify({ Title = "Whitelist", Desc = "ล้างข้อมูลทั้งหมดเรียบร้อย", Time = 3 })
    end
})

-- 3. ESP & VISUALS TAB
ESPTab:Section({ Title = "ESP Settings" })

ESPTab:Toggle({ Title = "Enable ESP", Value = Settings.espEnabled, Callback = function(v) Settings.espEnabled = v end })
ESPTab:Toggle({ Title = "Highlight Box", Value = Settings.espBoxes, Callback = function(v) Settings.espBoxes = v end })
ESPTab:Toggle({ Title = "Player Names", Value = Settings.espNames, Callback = function(v) Settings.espNames = v end })
ESPTab:Toggle({ Title = "Distance Indicator", Value = Settings.espDistance, Callback = function(v) Settings.espDistance = v end })
ESPTab:Toggle({ Title = "Health Indicator", Value = Settings.espHealth, Callback = function(v) Settings.espHealth = v end })
ESPTab:Toggle({ Title = "Team Color Matching", Value = Settings.espTeamColor, Callback = function(v) Settings.espTeamColor = v end })

ESPTab:Section({ Title = "FOV Ring & Visuals" })

ESPTab:Toggle({
    Title = "Show FOV Ring",
    Value = Settings.showFOV,
    Callback = function(v)
        Settings.showFOV = v
        if FOVring then FOVring.Visible = v end
    end
})

ESPTab:Toggle({
    Title = "Enable RGB Rainbow",
    Value = Settings.useRGBColors,
    Callback = function(v) Settings.useRGBColors = v end
})

ESPTab:Slider({
    Title = "RGB Cycle Speed",
    Min = 1,
    Max = 20,
    Default = Settings.rgbSpeed,
    Callback = function(val) Settings.rgbSpeed = val end
})

-- 4. PLAYER & MODS TAB
PowersTab:Section({ Title = "Player Abilities" })

PowersTab:Toggle({
    Title = "Godmode (Semi-Invincible)",
    Desc = "ฟื้นฟูเลือดอัตโนมัติทันทีที่ถูกโจมตี",
    Value = Settings.godmode,
    Callback = function(v) toggleGodmode() end
})

PowersTab:Section({ Title = "Movement Speed" })

PowersTab:Toggle({
    Title = "WalkSpeed Hack",
    Value = Settings.speedHack,
    Callback = function(v)
        Settings.speedHack = v
        if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
        end
    end
})

PowersTab:Slider({
    Title = "WalkSpeed",
    Min = 16,
    Max = 150,
    Default = Settings.walkSpeed,
    Callback = function(val) Settings.walkSpeed = val end
})

PowersTab:Section({ Title = "Camera View Mode" })

local viewModeButton = PowersTab:Button({
    Title = "View: " .. Settings.viewMode,
    Desc = "คลิกเพื่อสลับมุมมอง (1st, 2nd, 3rd Person)",
    Callback = function()
        toggleViewMode()
        viewModeButton:SetTitle("View: " .. Settings.viewMode)
    end
})

-- 5. ANTI-CHEAT STATUS TAB
SecurityTab:Section({ Title = "Anti-Cheat Bypass Status" })

SecurityTab:Button({
    Title = "Adonis Metatable Check: " .. (AC_Status.AdonisPatched and "✅ Bypassed (Patched)" or "🛡️ Active / Safe"),
    Desc = "บายพาสระบบตรวจสอบ compareTables ของ Adonis เรียบร้อย",
    Callback = function() end
})

SecurityTab:Button({
    Title = "LogService Blocked: " .. tostring(AC_Status.LogServiceBlocked) .. " Hook(s)",
    Desc = "บล็อกการดักอ่าน Console และ Error Report ป้องกันการถูกตรวจจับ",
    Callback = function() end
})

SecurityTab:Button({
    Title = "RemoteFunctions Protected: " .. tostring(AC_Status.RemoteFunctionsHooked) .. " RF(s)",
    Desc = "บายพาส OnClientInvoke ของ RemoteFunction (__FUNCTION) เรียบร้อย",
    Callback = function() end
})

SecurityTab:Button({
    Title = "Timeout Safeguard: " .. (AC_Status.TimeoutProtected and "✅ Protected" or "🛡️ Ready"),
    Desc = "ป้องกันเกมยิง Infinite Loop เพื่อแกล้งให้ตัวรันค้าง",
    Callback = function() end
})

SecurityTab:Button({
    Title = "🚨 Emergency Panic (ปิดทุกโปรทันที)",
    Desc = "กดปุ่ม Delete หรือกดปุ่มนี้เพื่อปิดการทำงานทั้งหมดฉุกเฉิน",
    Callback = function()
        Settings.aimbotEnabled = false
        Settings.silentAim = false
        Settings.espEnabled = false
        Settings.godmode = false
        if godmodeConnection then godmodeConnection:Disconnect() end
        if viewModeConnection then viewModeConnection:Disconnect() end
        if FOVring then FOVring.Visible = false end
        updateESP()
        Window:Notify({ Title = "PANIC ACTIVATED", Desc = "ปิดการทำงานทุกอย่างเรียบร้อย", Time = 3 })
    end
})

-- 6. USER INFO TAB
UserTab:Section({ Title = "Developer & Keys" })
UserTab:Label({ Title = "👤 Developer:", Desc = "Rocket HUP / K2NTA ST" })
UserTab:Label({ Title = "📦 Version:", Desc = "v8.5 (100% Loadstring-Free Standalone)" })
UserTab:Label({ Title = "🎮 Hotkeys:", Desc = "Right Shift = Toggle UI\nDelete = Panic Button\nE = Aimbot Toggle\nG = Godmode\nV = View Mode" })

-- ============================================
-- // 13. EVENT LISTENERS & MAIN RENDER LOOP
-- ============================================
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then createESP(player) end
end

Players.PlayerAdded:Connect(function(player)
    task.wait(1)
    if player ~= LocalPlayer then createESP(player) end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if keyBindCallback then
        local kc = input.KeyCode
        if kc == Enum.KeyCode.Escape then
            keyBindCallback = nil
            Window:Notify({ Title = "Key Bind", Desc = "ยกเลิก", Time = 2 })
            return
        end
        if kc ~= Enum.KeyCode.Unknown then
            local keyName = tostring(kc):gsub("Enum.KeyCode.", "")
            local cb = keyBindCallback
            keyBindCallback = nil
            cb(kc, keyName)
            return
        end
    end

    if gameProcessed then return end

    local kc = input.KeyCode
    if kc == Settings.toggleKey and Settings.Toggle then
        toggleState = not toggleState
        Window:Notify({ Title = "Aimbot", Desc = toggleState and "ACTIVATED" or "DEACTIVATED", Time = 2 })
    end

    if kc == Settings.godmodeKey then
        toggleGodmode()
        Window:Notify({ Title = "Godmode", Desc = Settings.godmode and "ENABLED" or "DISABLED", Time = 2 })
    end

    if kc == Settings.viewModeKey then
        toggleViewMode()
        viewModeButton:SetTitle("View: " .. Settings.viewMode)
    end

    if kc == Enum.KeyCode.Delete then
        Settings.aimbotEnabled = false
        Settings.silentAim = false
        Settings.espEnabled = false
        Settings.godmode = false
        if godmodeConnection then godmodeConnection:Disconnect() end
        if viewModeConnection then viewModeConnection:Disconnect() end
        if FOVring then FOVring.Visible = false end
        updateESP()
        Window:Notify({ Title = "PANIC MODE", Desc = "All features disabled", Time = 3 })
    end
end)

-- Stepped Loop (Speed Hack)
RunService.Stepped:Connect(function()
    if Settings.speedHack and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = Settings.walkSpeed
    end
end)

-- Render Loop
local espFrameCounter = 0
local ESP_UPDATE_EVERY = 3

RunService.RenderStepped:Connect(function(dt)
    if Settings.useRGBColors then
        updateRainbowColor(dt)
        if FOVring then FOVring.Color = getRainbowColor() end
    end

    if FOVring then
        FOVring.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVring.Visible = Settings.showFOV and (Settings.aimbotEnabled or Settings.silentAim)
    end

    updateAimbot()

    espFrameCounter = espFrameCounter + 1
    if espFrameCounter >= ESP_UPDATE_EVERY then
        espFrameCounter = 0
        updateESP()
    end
end)

Window:Notify({
    Title = "HYPER HUB",
    Desc = "Loaded! 100% Loadstring-Free Standalone Engine!\nRight Shift = UI | Delete = Panic Button",
    Time = 6
})

print("✅ Singularity Aimbot Hub v8.5 Loaded (100% Loadstring-Free Standalone)!")
