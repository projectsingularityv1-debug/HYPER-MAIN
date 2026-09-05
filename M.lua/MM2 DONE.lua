-- ============================================================
--   Singularity Hub — Murder Mystery 2
--   All-in-One Script
-- ============================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui      = game:GetService("CoreGui")
local Lighting     = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ป้องกันรันซ้อน
local env = (getgenv and getgenv()) or _G
local currentRunId = tick()
env.K2NTA_RunID = currentRunId

-- ล้างของเก่า (ล้าง UI เดิมเพื่อไม่ให้ซ้อนกันเวลาเปิดใหม่)
pcall(function()
    for _, v in ipairs(CoreGui:GetChildren()) do
        if v.Name == "Dummy Kawaii" then v:Destroy() end
    end
    for _, v in ipairs(player:WaitForChild("PlayerGui"):GetChildren()) do
        if v.Name == "Dummy Kawaii" then v:Destroy() end
    end
end)
if env.TeamESP_Folder   then pcall(function() env.TeamESP_Folder:Destroy() end) end
if env.GhostFly_Noclip  then env.GhostFly_Noclip:Disconnect() end
if env.AutoCoin_Noclip  then env.AutoCoin_Noclip:Disconnect() end
if env.Freecam then
    if env.Freecam.RenderConn then env.Freecam.RenderConn:Disconnect() end
    if env.Freecam.Part then env.Freecam.Part:Destroy() end
end
if env.FOVCircle then pcall(function() env.FOVCircle:Remove() end) end
if env.TracerLine then pcall(function() env.TracerLine:Remove() end) end

local hasDrawing = (type(Drawing) == "table" or type(Drawing) == "function")
if hasDrawing then
    env.FOVCircle = Drawing.new("Circle")
    env.FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    env.FOVCircle.Thickness = 1
    env.FOVCircle.Filled = false
    env.FOVCircle.Transparency = 1
    
    env.TracerLine = Drawing.new("Line")
    env.TracerLine.Color = Color3.fromRGB(255, 0, 0)
    env.TracerLine.Thickness = 1
    env.TracerLine.Transparency = 1
end
if env.GhostFly then
    if env.GhostFly.InputConn  then env.GhostFly.InputConn:Disconnect() end
    if env.GhostFly.RenderConn then env.GhostFly.RenderConn:Disconnect() end
    local gc = env.GhostFly.Char
    if gc then
        if gc:FindFirstChild("Humanoid") then
            gc.Humanoid.PlatformStand = false
            gc.Humanoid.AutoRotate = true
        end
        if gc:FindFirstChild("HumanoidRootPart") then
            gc.HumanoidRootPart.Anchored = false
        end
    end
end
local _c = player.Character
if _c and _c:FindFirstChild("HumanoidRootPart") then
    local _hrp = _c.HumanoidRootPart
    if _hrp:FindFirstChild("CoinBG") then _hrp.CoinBG:Destroy() end
    if _hrp:FindFirstChild("CoinBV") then _hrp.CoinBV:Destroy() end
end

-- ระบบ Config (Save/Load)
local HttpService = game:GetService("HttpService")
local CONFIG_FILE = "K2NTA_MM2_Config.json"

local rawState = {
    GhostFly     = false,
    TeamESP      = true,
    CoinESP      = true,
    AutoCoin     = true,
    FastAutoCoin = false,
    AutoGun      = false,
    KillMurderer = false,
    KillOthers   = false,
    InvisMap     = false,
    NightMode    = true,
    AntiMurderer = true,
    Freecam      = false,
    SilentAim    = false,
    AutoShoot    = false,
    SpeedEnabled = false,
    WalkSpeed    = 16,
    JumpPower    = 50,
    ShowFOV      = false,
    FOVSize      = 100,
    ShowTracer   = false,
    AimLock      = false,
    TargetMurdererOnly = true,
    AntiFling    = true,
    FarmSpeed    = 55,
    DebugMode    = false,
    GunESP       = false,
    HitboxExpander = false,
    HitboxSize   = 10,
    AutoFling    = false,
    InfiniteJump = false,
    Invisibility = false,
}

local function LoadConfig()
    if isfile and isfile(CONFIG_FILE) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if success and type(decoded) == "table" then
            for k, v in pairs(decoded) do
                if rawState[k] ~= nil then
                    rawState[k] = v
                end
            end
        end
    end
end
LoadConfig()

local saveDebounce = false
local function SaveConfig()
    if not writefile then return end
    if saveDebounce then return end
    saveDebounce = true
    task.delay(1, function()
        pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(rawState)) end)
        saveDebounce = false
    end)
end

-- สร้าง metatable ให้ดักจับการเปลี่ยนแปลงค่าและ Save อัตโนมัติ
env.State = setmetatable({}, {
    __index = rawState,
    __newindex = function(_, k, v)
        if rawState[k] ~= v then
            rawState[k] = v
            SaveConfig()
        end
    end
})

--------------------------------------------------------------------------------
-- UTIL: checkHasItem (นิยามก่อนทุกระบบ)
--------------------------------------------------------------------------------
local function checkHasItem(parentObj, keyword)
    if not parentObj then return false end
    for _, v in ipairs(parentObj:GetChildren()) do
        if v:IsA("Tool") and string.find(string.lower(v.Name), keyword) then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------
-- 1. UI — KT_UI-V1 Library
--------------------------------------------------------------------------------
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
local WindowSize = UIS.TouchEnabled and UDim2.fromOffset(550, 550) or UDim2.fromOffset(570,450 )


local KeyAvatarURL = getgenv().KeyAvatar
if not KeyAvatarURL then
    pcall(function()
        if isfile and isfile("SingularityKey.txt") then
            local savedKey = readfile("SingularityKey.txt")
            if savedKey and savedKey ~= "" then
                local req = (request or http_request or (syn and syn.request) or (http and http.request))
                local rbx_user = game:GetService("Players").LocalPlayer.Name
                local rbx_id = game:GetService("Players").LocalPlayer.UserId
                local url = "https://projectsingularity.online/raw/verify-key?k=" .. savedKey .. "&rbx_user=" .. rbx_user .. "&rbx_id=" .. tostring(rbx_id)
                if req then
                    local response = req({ Url = url, Method = "GET" })
                    if response and response.StatusCode == 200 then
                        local HttpService = game:GetService("HttpService")
                        local responseJson = HttpService:JSONDecode(response.Body)
                        if responseJson and responseJson.valid and responseJson.profile then
                            getgenv().KeyUsername = responseJson.profile.username
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
    KeyAvatarURL = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(game:GetService("Players").LocalPlayer.UserId) .. "&w=150&h=150"
end

local Window = Library:Window({

    Profile = {
        Username = getgenv().KeyUsername or "N/A",
        Email = "UID: " .. tostring(game:GetService("Players").LocalPlayer.UserId),
        AvatarUrl = KeyAvatarURL
    },

    Title = "HYPER HUB",
    Desc = "Murder Mystery 2",
    Icon = "rbxassetid://136264753381080",
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

local TPTab = Window:Tab({
    Title = "Teleport",
    Icon = "users"
})
local CreditTab = Window:Tab({
    Title = "Credit",
    Icon = "info"
})

--------------------------------------------------------------------------------
-- 2. Ghost Fly
--------------------------------------------------------------------------------
env.GhostFly = { Char = nil }
local flySystem = env.GhostFly
local FLY_SPEED = 50

local function setGhostFly(val)
    env.State.GhostFly = val
    local c = player.Character
    if not c or not c:FindFirstChild("HumanoidRootPart") then
        env.State.GhostFly = false; return
    end
    flySystem.Char = c
    local hrp = c.HumanoidRootPart
    local hum = c:FindFirstChild("Humanoid")
    if env.State.GhostFly then
        if hum then hum.PlatformStand = true; hum.AutoRotate = false end
        hrp.Anchored = true
        if env.GhostFly_Noclip then env.GhostFly_Noclip:Disconnect() end
        env.GhostFly_Noclip = RunService.Stepped:Connect(function()
            if player.Character then
                for _, p in ipairs(player.Character:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                end
            end
        end)
    else
        if hum then hum.PlatformStand = false; hum.AutoRotate = true end
        hrp.Anchored = false
        if env.GhostFly_Noclip then env.GhostFly_Noclip:Disconnect(); env.GhostFly_Noclip = nil end
    end
end

flySystem.RenderConn = RunService.RenderStepped:Connect(function(dt)
    if env.State.GhostFly then
        local c = player.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            local hrp = c.HumanoidRootPart
            local hum = c:FindFirstChild("Humanoid")
            if hum and not hum.PlatformStand then hum.PlatformStand = true; hum.AutoRotate = false end
            if not hrp.Anchored then hrp.Anchored = true end
            local mv = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + Vector3.new(0,0,-1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv + Vector3.new(0,0,1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv + Vector3.new(-1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + Vector3.new(1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv + Vector3.new(0,-1,0) end
            local cam = camera.CFrame
            local _, yaw, _ = cam:ToOrientation()
            if mv.Magnitude > 0 then
                mv = mv.Unit
                local dir = (cam * CFrame.new(mv)).Position - cam.Position
                hrp.CFrame = CFrame.new(hrp.Position + dir * (FLY_SPEED * dt)) * CFrame.Angles(0, yaw, 0)
            else
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, yaw, 0)
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- 3. Team ESP (Highlight + BillboardGui)
--------------------------------------------------------------------------------
local espFolder = Instance.new("Folder")
espFolder.Name = "MyTeamESP"
pcall(function() espFolder.Parent = CoreGui end)
if not espFolder.Parent then espFolder.Parent = player:WaitForChild("PlayerGui") end
env.TeamESP_Folder = espFolder

local espCache = {}

local function createESP(p)
    if espCache[p] then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = p.Name .. "_ESP"
    billboard.Size = UDim2.new(0, 160, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3.2, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.Parent = espFolder

    local lbl = Instance.new("TextLabel", billboard)
    lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
    lbl.TextScaled = false; lbl.TextSize = 13; lbl.Font = Enum.Font.GothamBold
    lbl.TextStrokeTransparency = 0; lbl.TextStrokeColor3 = Color3.new(0,0,0)
    lbl.TextColor3 = Color3.new(1,1,1); lbl.Text = p.Name

    local hl = Instance.new("Highlight")
    hl.Name = p.Name .. "_HL"
    hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    hl.Parent = espFolder

    espCache[p] = { Gui = billboard, Label = lbl, Highlight = hl }
end

local function removeESP(p)
    local d = espCache[p]
    if d then
        if d.Gui then d.Gui:Destroy() end
        if d.Highlight then d.Highlight:Destroy() end
        espCache[p] = nil
    end
end

-- Loop 1: เช็คผู้เล่นเข้า/ออก
task.spawn(function()
    while env.K2NTA_RunID == currentRunId do
        if env.State.TeamESP then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and not espCache[p] then createESP(p) end
            end
            for p in pairs(espCache) do
                if not p or not p.Parent then removeESP(p) end
            end
        else
            for p in pairs(espCache) do removeESP(p) end
        end
        task.wait(1)
    end
end)

-- Loop 2: อัปเดต Highlight + Label ทุก frame
task.spawn(function()
    while env.K2NTA_RunID == currentRunId do
        if env.State.TeamESP then
            for p, d in pairs(espCache) do
                local char = p.Character
                local head = char and char:FindFirstChild("Head")
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                local hum  = char and char:FindFirstChild("Humanoid")
                if head and hrp and hum and hum.Health > 0 then
                    local bp = p:FindFirstChild("Backpack")
                    local hasKnife = checkHasItem(char, "knife") or (bp and checkHasItem(bp, "knife"))
                    local hasGun   = checkHasItem(char, "gun")   or (bp and checkHasItem(bp, "gun"))
                    local fill, outline, tag
                    if hasKnife then
                        fill = Color3.fromRGB(255,55,55); outline = Color3.fromRGB(255,10,10); tag = " 🔪"
                    elseif hasGun then
                        fill = Color3.fromRGB(50,140,255); outline = Color3.fromRGB(20,90,220); tag = " 🔫"
                    else
                        fill = Color3.fromRGB(60,220,130); outline = Color3.fromRGB(30,180,100); tag = ""
                    end
                    local dist = 0
                    local mc = player.Character
                    if mc and mc:FindFirstChild("HumanoidRootPart") then
                        dist = math.floor((mc.HumanoidRootPart.Position - hrp.Position).Magnitude)
                    end
                    d.Gui.Adornee = head; d.Gui.Enabled = true
                    d.Label.Text = p.Name .. tag .. "\n[" .. dist .. "m]"
                    d.Label.TextColor3 = outline
                    d.Highlight.Adornee = char
                    d.Highlight.FillColor = fill
                    d.Highlight.OutlineColor = outline
                    d.Highlight.Enabled = true
                else
                    d.Gui.Enabled = false; d.Gui.Adornee = nil
                    d.Highlight.Enabled = false; d.Highlight.Adornee = nil
                end
            end
        end
        task.wait()
    end
end)

local function setESP(val)
    env.State.TeamESP = val
    if not env.State.TeamESP then for p in pairs(espCache) do removeESP(p) end end
end

--------------------------------------------------------------------------------
-- 4. Coin ESP (ไฮไลท์เหรียญบนแผนที่)
--------------------------------------------------------------------------------
local function getCoins()
    local coins = {}
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc.Name == "CoinContainer" then
            for _, coin in ipairs(desc:GetChildren()) do
                if coin:IsA("BasePart") then table.insert(coins, coin) end
            end
        end
    end
    if #coins == 0 then
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("BasePart") and desc.Name == "Coin_Server" then
                table.insert(coins, desc)
            end
        end
    end
    return coins
end

local function setCoinESP(val)
    env.State.CoinESP = val
    if not env.State.CoinESP then
        for _, coin in ipairs(getCoins()) do
            local b = coin:FindFirstChild("CoinESP_Box")
            if b then b:Destroy() end
        end
    end
end

task.spawn(function()
    while env.K2NTA_RunID == currentRunId do
        if env.State.CoinESP then
            for _, v in ipairs(getCoins()) do
                if v:IsA("BasePart") and not v:FindFirstChild("CoinESP_Box") then
                    local box = Instance.new("BoxHandleAdornment")
                    box.Name = "CoinESP_Box"; box.Size = v.Size + Vector3.new(0.5,0.5,0.5)
                    box.Adornee = v; box.AlwaysOnTop = true; box.ZIndex = 5
                    box.Transparency = 0.4; box.Color3 = Color3.fromRGB(255,215,0)
                    box.Parent = v
                end
            end
        end
        task.wait(1)
    end
end)

--------------------------------------------------------------------------------
-- 4.5 Gun ESP (ไฮไลท์ปืนตกพื้น)
--------------------------------------------------------------------------------
local gunEspObjects = {}
local function clearGunESP()
    for _, data in pairs(gunEspObjects) do
        if data.Billboard then data.Billboard:Destroy() end
        if data.Highlight then data.Highlight:Destroy() end
    end
    gunEspObjects = {}
end

task.spawn(function()
    while env.K2NTA_RunID == currentRunId do
        if not env.State.GunESP then
            clearGunESP()
            task.wait(1)
            continue
        end

        local activeGuns = {}
        
        local function scanFolder(parentContainer)
            for _, obj in pairs(parentContainer:GetChildren()) do
                local nameLower = obj.Name:lower()
                
                if nameLower == "gundrop" or nameLower == "droppedgun" or nameLower == "gun" or nameLower == "revolver" or nameLower == "sheriff" then
                    local isHeldOrEquipped = false
                    local currentParent = obj.Parent
                    
                    while currentParent and currentParent ~= game do
                        if currentParent:IsA("Model") and Players:GetPlayerFromCharacter(currentParent) then
                            isHeldOrEquipped = true
                            break
                        elseif currentParent:IsA("Backpack") or currentParent:IsA("Player") then
                            isHeldOrEquipped = true
                            break
                        end
                        currentParent = currentParent.Parent
                    end

                    if not isHeldOrEquipped then
                        local targetPart = nil
                        if obj:IsA("BasePart") then
                            targetPart = obj
                        elseif obj:IsA("Model") then
                            targetPart = obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
                        else
                            targetPart = obj:FindFirstChildOfClass("BasePart")
                        end

                        if targetPart then
                            activeGuns[obj] = targetPart

                            if not gunEspObjects[obj] then
                                local hl = Instance.new("Highlight")
                                hl.FillColor = Color3.fromRGB(255, 255, 0)
                                hl.OutlineColor = Color3.fromRGB(255, 200, 0)
                                hl.FillTransparency = 0.4
                                hl.OutlineTransparency = 0.1
                                hl.Parent = obj

                                local bb = Instance.new("BillboardGui")
                                bb.Size = UDim2.new(0, 90, 0, 35)
                                bb.StudsOffset = Vector3.new(0, 2.5, 0)
                                bb.AlwaysOnTop = true
                                bb.Parent = targetPart

                                local txt = Instance.new("TextLabel")
                                txt.Size = UDim2.new(1, 0, 1, 0)
                                txt.BackgroundTransparency = 1
                                txt.TextScaled = true
                                txt.Font = Enum.Font.GothamBold
                                txt.Text = "Dropped Gun"
                                txt.TextColor3 = Color3.fromRGB(255, 255, 0)
                                txt.TextStrokeTransparency = 0
                                txt.Parent = bb

                                gunEspObjects[obj] = { Billboard = bb, Highlight = hl }
                            end
                        end
                    end
                end
                
                if (obj:IsA("Folder") or obj:IsA("Model")) and not Players:GetPlayerFromCharacter(obj) then
                    scanFolder(obj)
                end
            end
        end

        scanFolder(workspace)

        for obj, data in pairs(gunEspObjects) do
            if not obj or not obj.Parent or not activeGuns[obj] then
                if data.Billboard then data.Billboard:Destroy() end
                if data.Highlight then data.Highlight:Destroy() end
                gunEspObjects[obj] = nil
            end
        end

        task.wait(0.3)
    end
end)

local function setGunESP(val)
    env.State.GunESP = val
    if not val then clearGunESP() end
end

--------------------------------------------------------------------------------
-- 5. Auto Farm Coin
--------------------------------------------------------------------------------
local function getNearestCoin(coinsList, originPos)
    local nearest, shortest = nil, math.huge
    for _, coin in ipairs(coinsList) do
        if coin and coin.Parent then
            local d = (coin.Position - originPos).Magnitude
            if d < shortest then shortest = d; nearest = coin end
        end
    end
    return nearest
end

local function tweenToCoin(targetPart)
    local c = player.Character
    if not c or not c:FindFirstChild("HumanoidRootPart") then return end
    local hrp = c.HumanoidRootPart
    if env.State.GhostFly then env.State.GhostFly = false end

    -- BodyGyro: ล็อคยืนตรง ไม่หมุน
    local bg = hrp:FindFirstChild("CoinBG") or Instance.new("BodyGyro")
    bg.Name = "CoinBG"; bg.P = 3e4; bg.D = 500
    bg.maxTorque = Vector3.new(0, 9e9, 0)
    bg.cframe = CFrame.new(hrp.Position)
    bg.Parent = hrp

    local bv = hrp:FindFirstChild("CoinBV") or Instance.new("BodyVelocity")
    bv.Name = "CoinBV"; bv.velocity = Vector3.new(0,0,0)
    bv.maxForce = Vector3.new(9e9,9e9,9e9); bv.Parent = hrp

    local touchFunc = firetouchinterest or fire_touch_interest
    local dist = (hrp.Position - targetPart.Position).Magnitude
    local flightTime = math.clamp(dist / env.State.FarmSpeed, 0.15, 5)

    local tween = TweenService:Create(hrp,
        TweenInfo.new(flightTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { CFrame = CFrame.new(targetPart.Position) }
    )
    if env.DebugLog then env.DebugLog("บินไปเก็บเหรียญ (AutoCoin): ระยะ " .. math.floor(dist) .. " studs (เวลา " .. string.format("%.2f", flightTime) .. "s)") end
    tween:Play()

    while tween.PlaybackState == Enum.PlaybackState.Playing do
        if not env.State.AutoCoin or env.K2NTA_RunID ~= currentRunId
            or not targetPart or not targetPart.Parent then
            tween:Cancel(); break
        end
        -- ป้องกันคนชนเด้งออกนอกโลก
        pcall(function()
            hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
            hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
        end)
        task.wait()
    end

    if targetPart and targetPart.Parent then
        local startCF = targetPart.CFrame
        local floatTime = 0
        while targetPart and targetPart.Parent and floatTime < 0.4 and env.State.AutoCoin do
            hrp.CFrame = startCF * CFrame.new(0, math.sin(floatTime * 15) * 1.5, 0)
            if touchFunc then
                pcall(function()
                    touchFunc(hrp, targetPart, 0)
                    touchFunc(hrp, targetPart, 1)
                end)
            end
            task.wait(0.03)
            floatTime = floatTime + 0.03
        end
    end
end

task.spawn(function()
    while env.K2NTA_RunID == currentRunId do
        if env.State.AutoCoin or env.State.FastAutoCoin then
            local isFast = env.State.FastAutoCoin

            -- ตรวจ priority: มีอาวุธ + auto kill เปิด → หยุดเก็บเหรียญ
            local mc0 = player.Character
            local bp0 = player:FindFirstChild("Backpack")
            local hasWeapon = (mc0 and (checkHasItem(mc0, "knife") or checkHasItem(mc0, "gun") or checkHasItem(mc0, "revolver") or checkHasItem(mc0, "sheriff") or checkHasItem(mc0, "pistol")))
                           or (bp0 and (checkHasItem(bp0, "knife") or checkHasItem(bp0, "gun") or checkHasItem(bp0, "revolver") or checkHasItem(bp0, "sheriff") or checkHasItem(bp0, "pistol")))
            local killActive = env.State.KillMurderer or env.State.KillOthers

            if hasWeapon and killActive then
                -- Auto Kill priority — หยุดเก็บเหรียญชั่วคราว
                if env.UpdateStatus then env.UpdateStatus("⚔️ Auto Kill priority — หยุดเก็บเหรียญ") end
            else
                -- ทำงานปกติ
                if not env.AutoCoin_Noclip then
                    env.AutoCoin_Noclip = RunService.Stepped:Connect(function()
                        if (env.State.AutoCoin or env.State.FastAutoCoin) and player.Character then
                            for _, p in ipairs(player.Character:GetDescendants()) do
                                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                            end
                        end
                    end)
                end
                local coins = getCoins()
                if #coins > 0 then
                    local c = player.Character
                    if c and c:FindFirstChild("HumanoidRootPart") then
                        if isFast then
                            while env.State.FastAutoCoin do
                                -- หยุด fast farm ถ้ามีอาวุธ + auto kill เปิดอยู่
                                local mc_f = player.Character
                                local bp_f = player:FindFirstChild("Backpack")
                                local hasWep_f = (mc_f and (checkHasItem(mc_f, "knife") or checkHasItem(mc_f, "gun") or checkHasItem(mc_f, "revolver") or checkHasItem(mc_f, "sheriff") or checkHasItem(mc_f, "pistol")))
                                             or (bp_f and (checkHasItem(bp_f, "knife") or checkHasItem(bp_f, "gun") or checkHasItem(bp_f, "revolver") or checkHasItem(bp_f, "sheriff") or checkHasItem(bp_f, "pistol")))
                                if hasWep_f and (env.State.KillMurderer or env.State.KillOthers) then
                                    if env.UpdateStatus then env.UpdateStatus("⚔️ Auto Kill priority") end
                                    task.wait(0.3)
                                    break
                                end
                                local remainingCoins = {}
                                for _, c_obj in ipairs(coins) do
                                    if c_obj and c_obj.Parent then table.insert(remainingCoins, c_obj) end
                                end
                                if #remainingCoins == 0 then break end
                                if env.UpdateStatus then env.UpdateStatus("⚡ บินกวาดเหรียญ (เหลือ " .. #remainingCoins .. ")") end

                                local hrp = c:FindFirstChild("HumanoidRootPart")
                                if not hrp then break end

                                local nearest = getNearestCoin(remainingCoins, hrp.Position)
                                if not nearest or not nearest.Parent then break end

                                local coin = nearest
                                local bg = hrp:FindFirstChild("CoinBG") or Instance.new("BodyGyro")
                                bg.Name = "CoinBG"; bg.P = 3e4; bg.D = 500
                                bg.maxTorque = Vector3.new(0, 9e9, 0)
                                bg.cframe = CFrame.new(hrp.Position)
                                bg.Parent = hrp

                                local pathfindingService = game:GetService("PathfindingService")
                                local path = pathfindingService:CreatePath({
                                    AgentRadius = 2,
                                    AgentHeight = 5,
                                    AgentCanJump = true,
                                    WaypointSpacing = 4
                                })
                                local success, _ = pcall(function()
                                    path:ComputeAsync(hrp.Position, coin.Position)
                                end)

                                if success and path.Status == Enum.PathStatus.Success then
                                    if env.DebugLog then env.DebugLog("FastAutoCoin: Path computed to coin, waypoints: " .. tostring(#path:GetWaypoints())) end
                                    local waypoints = path:GetWaypoints()
                                    for i, wp in ipairs(waypoints) do
                                        if i == 1 then continue end
                                        if not env.State.FastAutoCoin or not coin or not coin.Parent then break end
                                        local dist = (hrp.Position - wp.Position).Magnitude
                                        local flightTime = math.clamp(dist / env.State.FarmSpeed, 0.05, 1.5)
                                        local tween = TweenService:Create(hrp, TweenInfo.new(flightTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(wp.Position)})
                                        tween:Play()
                                        while tween.PlaybackState == Enum.PlaybackState.Playing do
                                            if not env.State.FastAutoCoin or not coin or not coin.Parent then tween:Cancel(); break end
                                            pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0,0,0); hrp.AssemblyAngularVelocity = Vector3.new(0,0,0) end)
                                            task.wait()
                                        end
                                    end
                                else
                                    if env.DebugLog then env.DebugLog("FastAutoCoin: Path failed or straight line used") end
                                    local dist = (hrp.Position - coin.Position).Magnitude
                                    local flightTime = math.clamp(dist / (env.State.FarmSpeed * 0.5), 0.2, 1.5)
                                    local tween = TweenService:Create(hrp, TweenInfo.new(flightTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(coin.Position)})
                                    tween:Play()
                                    while tween.PlaybackState == Enum.PlaybackState.Playing do
                                        if not env.State.FastAutoCoin or not coin or not coin.Parent then tween:Cancel(); break end
                                        pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0,0,0); hrp.AssemblyAngularVelocity = Vector3.new(0,0,0) end)
                                        task.wait()
                                    end
                                end
                                if coin and coin.Parent then
                                    hrp.CFrame = coin.CFrame
                                    local touchFunc = firetouchinterest or fire_touch_interest
                                    if touchFunc then pcall(function() touchFunc(hrp, coin, 0); touchFunc(hrp, coin, 1) end) end
                                    for i, v in ipairs(coins) do if v == coin then table.remove(coins, i) break end end
                                end
                            end
                        else
                            if env.UpdateStatus then env.UpdateStatus("⚡ เก็บเหรียญ (เหลือ " .. #coins .. ")") end
                            local nearest = getNearestCoin(coins, c.HumanoidRootPart.Position)
                            if nearest and nearest.Parent then tweenToCoin(nearest) end
                        end
                    end
                else
                    if env.UpdateStatus then env.UpdateStatus("รอเหรียญเกิดใหม่...") end
                    task.wait(0.5)
                end
            end
        else
            if env.AutoCoin_Noclip then env.AutoCoin_Noclip:Disconnect(); env.AutoCoin_Noclip = nil end
            local c = player.Character
            if c and c:FindFirstChild("HumanoidRootPart") then
                local hrp = c.HumanoidRootPart; local hum = c:FindFirstChild("Humanoid")
                hrp.Anchored = false
                if hum then hum.PlatformStand = false; hum.AutoRotate = true end
                if hrp:FindFirstChild("CoinBG") then hrp.CoinBG:Destroy() end
                if hrp:FindFirstChild("CoinBV") then hrp.CoinBV:Destroy() end
            end
        end
        task.wait(0.1)
    end
end)



local function resetCoinState()
    if env.AutoCoin_Noclip then env.AutoCoin_Noclip:Disconnect(); env.AutoCoin_Noclip = nil end
    local c = player.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        local hrp = c.HumanoidRootPart; local hum = c:FindFirstChild("Humanoid")
        hrp.Anchored = false
        if hum then hum.PlatformStand = false; hum.AutoRotate = true end
        if hrp:FindFirstChild("CoinBG") then hrp.CoinBG:Destroy() end
        if hrp:FindFirstChild("CoinBV") then hrp.CoinBV:Destroy() end
    end
end

local function setAutoCoin(val)
    env.State.AutoCoin = val
    if env.State.AutoCoin and env.State.FastAutoCoin then env.State.FastAutoCoin = false end
    if not env.State.AutoCoin and not env.State.FastAutoCoin then resetCoinState() end
end

local function setFastAutoCoin(val)
    env.State.FastAutoCoin = val
    if env.State.FastAutoCoin and env.State.AutoCoin then env.State.AutoCoin = false end
    if not env.State.FastAutoCoin and not env.State.AutoCoin then resetCoinState() end
end

--------------------------------------------------------------------------------
-- 6. Auto Get Gun
--------------------------------------------------------------------------------
-- keyword สำหรับปืน
local GUN_KEYWORDS = {"gun", "revolver", "sheriff", "pistol"}

local function isGunTool(v)
    if not v then return false end
    local name = string.lower(v.Name)
    for _, kw in ipairs(GUN_KEYWORDS) do
        if string.find(name, kw) then return true end
    end
    return false
end

-- หาปืนที่ drop อยู่บนพื้น
local function getDroppedGun()
    -- ค้นหาเฉพาะใน Workspace โดยตรง (MM2 ดรอปปืนในนี้)
    for _, v in ipairs(workspace:GetChildren()) do
        if (v:IsA("Tool") or v:IsA("Model")) and isGunTool(v) then
            local part = v:FindFirstChild("Handle") or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
            if part then 
                return v, part 
            end
        end
    end
    
    -- ค้นหาในโฟลเดอร์ Normal (แผนที่) แบบตื้นๆ (กันกระตุก)
    local normalMap = workspace:FindFirstChild("Normal")
    if normalMap then
        for _, v in ipairs(normalMap:GetChildren()) do
            if (v:IsA("Tool") or v:IsA("Model")) and isGunTool(v) then
                local part = v:FindFirstChild("Handle") or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                if part then 
                    return v, part 
                end
            end
        end
    end
    
    return nil, nil
end

-- ติดตามผู้เล่นที่มีปืน เพื่อดักตอนตาย
local trackedGunPlayers = {}

task.spawn(function()
    while env.K2NTA_RunID == currentRunId do
        if env.State.AutoGun then
            -- อัปเดต list คนที่มีปืน
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player then
                    local pc = p.Character
                    local bp = p:FindFirstChild("Backpack")
                    local hasGun = (pc and (checkHasItem(pc, "gun") or checkHasItem(pc, "revolver") or checkHasItem(pc, "sheriff") or checkHasItem(pc, "pistol")))
                               or (bp and (checkHasItem(bp, "gun") or checkHasItem(bp, "revolver") or checkHasItem(bp, "sheriff") or checkHasItem(bp, "pistol")))
                    if hasGun then
                        trackedGunPlayers[p] = true
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while env.K2NTA_RunID == currentRunId do
        if env.State.AutoGun then
            -- เช็คว่าเราไม่มีปืนแล้วค่อยหา
            local mc = player.Character
            local mybp = player:FindFirstChild("Backpack")
            local iHaveGun = mc and (checkHasItem(mc, "gun") or checkHasItem(mc, "revolver") or checkHasItem(mc, "sheriff") or checkHasItem(mc, "pistol"))
                          or mybp and (checkHasItem(mybp, "gun") or checkHasItem(mybp, "revolver") or checkHasItem(mybp, "sheriff") or checkHasItem(mybp, "pistol"))

            if not iHaveGun then
                local gunObj, gunPart = getDroppedGun()
                if gunObj and gunPart and mc and mc:FindFirstChild("HumanoidRootPart") then
                    local hrp = mc.HumanoidRootPart
                    local hum = mc:FindFirstChild("Humanoid")

                    if env.UpdateStatus then env.UpdateStatus("🔫 บินเก็บปืน!") end
                    if env.DebugLog then env.DebugLog("AutoGun: Flying to gun at distance " .. math.floor((hrp.Position - gunPart.Position).Magnitude)) end

                    -- บิน Tween เข้าหาปืนภายใน 3 วินาที
                    local dist = (hrp.Position - gunPart.Position).Magnitude
                    local flyTime = math.clamp(dist / 60, 0.3, 3)

                    local tween = TweenService:Create(hrp,
                        TweenInfo.new(flyTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        { CFrame = CFrame.new(gunPart.Position) }
                    )
                    tween:Play()

                    -- รอบินถึงหรือหมดเวลา
                    local elapsed = 0
                    while tween.PlaybackState == Enum.PlaybackState.Playing do
                        if not env.State.AutoGun or env.K2NTA_RunID ~= currentRunId then
                            tween:Cancel(); break
                        end
                        elapsed = elapsed + task.wait(0.05)
                        if elapsed > 3.5 then tween:Cancel(); break end
                    end

                    -- พยายามเก็บปืน
                    if gunPart and gunPart.Parent then
                        hrp.CFrame = CFrame.new(gunPart.Position)
                        local touchFunc = firetouchinterest or fire_touch_interest
                        if touchFunc then
                            pcall(function() touchFunc(hrp, gunPart, 0) end)
                            pcall(function() touchFunc(hrp, gunPart, 1) end)
                        end
                        -- ถ้าเป็น Tool ให้ Humanoid หยิบ
                        if gunObj:IsA("Tool") and hum then
                            pcall(function() hum:EquipTool(gunObj) end)
                        end
                        if env.UpdateStatus then env.UpdateStatus("✅ เก็บปืนแล้ว!") end
                        task.wait(1)
                    end
                end
            end
        end
        task.wait(0.3)
    end
end)

local function setAutoGun(val)
    env.State.AutoGun = val
    trackedGunPlayers = {}
end

--------------------------------------------------------------------------------
-- 7. Auto Kill (ฆาตกร / คนอื่น)
--------------------------------------------------------------------------------
local function isMurderer(p)
    if not p then return false end
    local c = p.Character; local bp = p:FindFirstChild("Backpack")
    return checkHasItem(c, "knife") or (bp and checkHasItem(bp, "knife"))
end

local function teleportAndAttack(target)
    local mc = player.Character; local tc = target.Character
    if not (mc and mc:FindFirstChild("HumanoidRootPart") and tc and tc:FindFirstChild("HumanoidRootPart")) then return end
    local mhrp = mc.HumanoidRootPart; local thrp = tc.HumanoidRootPart
    local bp = player:FindFirstChild("Backpack")
    local hum = mc:FindFirstChild("Humanoid")
    local hasGun   = checkHasItem(mc, "gun")   or (bp and checkHasItem(bp, "gun"))
    local hasKnife = checkHasItem(mc, "knife") or (bp and checkHasItem(bp, "knife"))

    -- ถ้ามีมีดใน Backpack ให้ equip ออกมาก่อน
    if hasKnife and hum then
        local knifeInBag = bp and bp:FindFirstChildWhichIsA("Tool")
        if knifeInBag and string.find(string.lower(knifeInBag.Name), "knife") then
            hum:EquipTool(knifeInBag)
            task.wait(0.05)
        end
    end

    if hasGun then
        local dir = (mhrp.Position - thrp.Position).Unit
        if dir.X ~= dir.X then dir = Vector3.new(0,0,1) end
        mhrp.CFrame = CFrame.lookAt(thrp.Position + dir * 15, thrp.Position)
        local cam = workspace.CurrentCamera
        if cam then cam.CFrame = CFrame.lookAt(cam.CFrame.Position, thrp.Position) end
    else
        mhrp.CFrame = thrp.CFrame * CFrame.new(0,0,3)
        mhrp.CFrame = CFrame.lookAt(mhrp.Position, thrp.Position)
    end

    -- หาและ activate tool ที่ equip อยู่ (มีด/ปืน)
    local tool = mc:FindFirstChildWhichIsA("Tool")
    if tool then tool:Activate() end
end

task.spawn(function()
    while env.K2NTA_RunID == currentRunId do
        if env.State.KillMurderer or env.State.KillOthers then
            local mc = player.Character; local mhrp = mc and mc:FindFirstChild("HumanoidRootPart")
            if mhrp then
                local bp = player:FindFirstChild("Backpack")
                local hasKnife = checkHasItem(mc, "knife") or (bp and checkHasItem(bp, "knife"))
                local hasGun   = checkHasItem(mc, "gun")   or (bp and checkHasItem(bp, "gun"))
                local canHunt = (env.State.KillOthers and hasKnife) or (env.State.KillMurderer and hasGun)
                if canHunt then
                    local target, shortest = nil, math.huge
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= player then
                            local pc = p.Character; local phrp = pc and pc:FindFirstChild("HumanoidRootPart")
                            local phum = pc and pc:FindFirstChild("Humanoid")
                            if phrp and phum and phum.Health > 0 then
                                local isT = (env.State.KillMurderer and isMurderer(p))
                                         or (env.State.KillOthers and not isMurderer(p))
                                if isT then
                                    local d = (mhrp.Position - phrp.Position).Magnitude
                                    if d < shortest then shortest = d; target = p end
                                end
                            end
                        end
                    end
                    if target then
                        if env.UpdateStatus then env.UpdateStatus("🎯 ไล่ล่า: " .. target.Name) end
                        if env.DebugLog then env.DebugLog("AutoKill: Target found -> " .. target.Name .. ", Dist: " .. math.floor(shortest)) end
                        teleportAndAttack(target)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

local function setKillMurderer(val)
    env.State.KillMurderer = val
    if env.State.KillMurderer then env.State.KillOthers = false end
end
local function setKillOthers(val)
    env.State.KillOthers = val
    if env.State.KillOthers then env.State.KillMurderer = false end
end

--------------------------------------------------------------------------------
-- 8. Anti-Murderer (หนีฆาตกรอัตโนมัติ)
--------------------------------------------------------------------------------
task.spawn(function()
    while env.K2NTA_RunID == currentRunId do
        if env.State.AntiMurderer then
            local mc = player.Character; local mhrp = mc and mc:FindFirstChild("HumanoidRootPart")
            if mhrp then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= player and isMurderer(p) then
                        local pc = p.Character; local phrp = pc and pc:FindFirstChild("HumanoidRootPart")
                        if phrp then
                            local d = (mhrp.Position - phrp.Position).Magnitude
                            if d <= 25 then
                                local dir = (mhrp.Position - phrp.Position).Unit
                                mhrp.CFrame = CFrame.new(mhrp.Position + dir * 30 + Vector3.new(0,5,0))
                                if env.UpdateStatus then env.UpdateStatus("⚠️ วาปหนี " .. p.Name) end
                                if env.DebugLog then env.DebugLog("AntiMurderer: Escaped from " .. p.Name .. ", Dist was " .. math.floor(d)) end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

local function setAntiMurderer(val)
    env.State.AntiMurderer = val
end

--------------------------------------------------------------------------------
-- 8.5 Aimbot & Auto Shoot (ปืน)
--------------------------------------------------------------------------------
local function setSilentAim(val)
    env.State.SilentAim = val
    if val and not env.SilentAimHooked then
        env.SilentAimHooked = true
        pcall(function()
            local mt = getrawmetatable(game)
            local oldNamecall = mt.__namecall
            setreadonly(mt, false)
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                if not checkcaller() and env.State.SilentAim then
                    if method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay" or method == "Raycast" then
                        local c = player.Character
                        if c and (checkHasItem(c, "gun") or checkHasItem(c, "revolver") or checkHasItem(c, "sheriff") or checkHasItem(c, "pistol")) then
                            local murd = nil
                            for _, p in ipairs(Players:GetPlayers()) do
                                if p ~= player and isMurderer(p) then
                                    local pc = p.Character
                                    local phum = pc and pc:FindFirstChild("Humanoid")
                                    if phum and phum.Health > 0 then murd = p; break end
                                end
                            end
                            if murd and murd.Character and murd.Character:FindFirstChild("Head") then
                                local head = murd.Character.Head
                                -- Wallbang: ย้าย origin ของ ray ไปข้างๆ หัวเป้าหมายเลย
                                -- กระสุนเริ่มต้นหลังกำแพง ผ่านได้ 100%
                                local wallbangOrigin = head.Position + Vector3.new(0.5, 0, 0)
                                if method == "Raycast" then
                                    args[1] = wallbangOrigin
                                    args[2] = (head.Position - wallbangOrigin).Unit * 10
                                else
                                    args[1] = Ray.new(wallbangOrigin, (head.Position - wallbangOrigin).Unit * 10)
                                end
                                return oldNamecall(self, unpack(args))
                            end
                        end
                    end
                end
                return oldNamecall(self, ...)
            end)
            setreadonly(mt, true)
        end)
    end
end

local function setAutoShoot(val)
    env.State.AutoShoot = val
end

task.spawn(function()
    while env.K2NTA_RunID == currentRunId do
        if env.State.AutoShoot then
            local c = player.Character
            if c then
                local hum = c:FindFirstChild("Humanoid")
                local bp = player:FindFirstChild("Backpack")

                -- หาปืนด้วย keyword (รองรับทุกชื่อ)
                local gunKeywords = {"gun", "revolver", "sheriff", "pistol"}
                local gun = nil

                -- ตรวจใน Character ก่อน
                for _, tool in ipairs(c:GetChildren()) do
                    if tool:IsA("Tool") then
                        for _, kw in ipairs(gunKeywords) do
                            if string.find(string.lower(tool.Name), kw) then
                                gun = tool; break
                            end
                        end
                    end
                    if gun then break end
                end

                -- ถ้าไม่เจอใน Character ตรวจใน Backpack
                if not gun and bp then
                    for _, tool in ipairs(bp:GetChildren()) do
                        if tool:IsA("Tool") then
                            for _, kw in ipairs(gunKeywords) do
                                if string.find(string.lower(tool.Name), kw) then
                                    gun = tool; break
                                end
                            end
                        end
                        if gun then break end
                    end
                end

                if gun and hum then
                    -- หาคนเป็นฆาตกร (มีชีวิตอยู่)
                    local murd = nil
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= player and isMurderer(p) then
                            local pc = p.Character
                            local phum = pc and pc:FindFirstChild("Humanoid")
                            if phum and phum.Health > 0 then
                                murd = p; break
                            end
                        end
                    end

                    if murd and murd.Character and murd.Character:FindFirstChild("Head") then
                        local hrp = c:FindFirstChild("HumanoidRootPart")
                        local mhrp = murd.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and mhrp then
                            -- equip ปืนจาก Backpack ถ้ายังไม่ได้ถือ
                            if gun.Parent == bp then
                                hum:EquipTool(gun)
                                task.wait(0.15)
                            end

                            -- === บินขึ้นไปลอยเหนือหัวฆาตกร ===
                            local savedCF = hrp.CFrame

                            -- จุดลอยอยู่ : เหนือหัว +30 studs ห่างออกมา 15 studs (มองลงมา)
                            local mPos   = mhrp.Position
                            local camDir = (camera.CFrame.LookVector * Vector3.new(1,0,1)).Unit
                            if camDir.Magnitude == 0 then camDir = Vector3.new(0,0,-1) end
                            local hoverPos = mPos + Vector3.new(0, 30, 0) + camDir * 15

                            hrp.CFrame = CFrame.new(hoverPos)
                            if env.DebugLog then env.DebugLog("AutoShoot: Teleported above murderer -> " .. murd.Name) end

                            -- หันกล้องลงไปหาหัวฆาตกร
                            local cam = workspace.CurrentCamera
                            if cam then
                                cam.CFrame = CFrame.lookAt(hoverPos, murd.Character.Head.Position)
                            end

                            -- ยิงลงไป
                            pcall(function() gun:Activate() end)
                            pcall(function() if mouse1click then mouse1click() end end)

                            -- วาปกลับตำแหน่งเดิมทันที
                            task.wait()
                            hrp.CFrame = savedCF

                            if env.UpdateStatus then
                                env.UpdateStatus("🎯 ยิงจากเหนือหัว: " .. murd.Name)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.15)
    end
end)

--------------------------------------------------------------------------------
-- 8.6 Aimbot FOV & Tracer Engine
--------------------------------------------------------------------------------
local AimbotTarget = nil
task.spawn(function()
    RunService.RenderStepped:Connect(function()
        if env.K2NTA_RunID ~= currentRunId then return end
        
        local mouseLoc = UserInputService:GetMouseLocation()
        
        if env.FOVCircle then
            env.FOVCircle.Visible = env.State.ShowFOV
            env.FOVCircle.Radius = env.State.FOVSize
            env.FOVCircle.Position = mouseLoc
        end
        
        local target = nil
        local shortestDist = env.State.FOVSize
        
        if env.State.AimLock or env.State.ShowTracer then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                    -- เช็คว่าเป็น Murderer เท่านั้นหรือไม่
                    local isValidTarget = true
                    if env.State.TargetMurdererOnly then
                        if not isMurderer(p) then isValidTarget = false end
                    end
                    
                    if isValidTarget then
                        local pos, onScreen = camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                        if onScreen then
                            local dist = (Vector2.new(pos.X, pos.Y) - mouseLoc).Magnitude
                            if dist < shortestDist then
                                target = p
                                shortestDist = dist
                            end
                        end
                    end
                end
            end
        end
        AimbotTarget = target
        
        if env.TracerLine then
            if env.State.ShowTracer and AimbotTarget and AimbotTarget.Character and AimbotTarget.Character:FindFirstChild("HumanoidRootPart") then
                local pos, _ = camera:WorldToViewportPoint(AimbotTarget.Character.HumanoidRootPart.Position)
                env.TracerLine.Visible = true
                env.TracerLine.From = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
                env.TracerLine.To = Vector2.new(pos.X, pos.Y)
            else
                env.TracerLine.Visible = false
            end
        end
        
        if env.State.AimLock and AimbotTarget and AimbotTarget.Character and AimbotTarget.Character:FindFirstChild("Head") then
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                camera.CFrame = CFrame.lookAt(camera.CFrame.Position, AimbotTarget.Character.Head.Position)
            end
        end
    end)
end)

--------------------------------------------------------------------------------
-- 8.7 Anti-Fling Engine
--------------------------------------------------------------------------------
local cachedPlayerParts = {}
task.spawn(function()
    RunService.Stepped:Connect(function()
        if env.K2NTA_RunID ~= currentRunId then return end
        if env.State.AntiFling then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    -- Cache BaseParts เพื่อลดภาระจาก GetDescendants ทุกเฟรม
                    local cache = cachedPlayerParts[p]
                    if not cache or cache.character ~= p.Character then
                        cache = { character = p.Character, parts = {} }
                        for _, part in ipairs(p.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                table.insert(cache.parts, part)
                            end
                        end
                        cachedPlayerParts[p] = cache
                    end
                    
                    -- ใช้ Cache เปลี่ยนค่า (ไม่ต้อง GetDescendants 60 ครั้งต่อวินาที)
                    for _, part in ipairs(cache.parts) do
                        if part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end
    end)
end)

--------------------------------------------------------------------------------
-- 8.8 Auto Fling Murderer
--------------------------------------------------------------------------------
task.spawn(function()
    RunService.Heartbeat:Connect(function()
        if env.K2NTA_RunID ~= currentRunId then return end
        if env.State.AutoFling then
            local char = player.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    -- check if Murderer
                    local isMurd = checkHasItem(p.Character, "knife") or (p:FindFirstChild("Backpack") and checkHasItem(p.Backpack, "knife"))
                    if isMurd then
                        local targetHrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if targetHrp then
                            local angle = math.rad(math.random(0, 360))
                            hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 1.5, 0) * CFrame.Angles(angle, angle, angle)
                        end
                    end
                end
            end
        end
    end)
end)

--------------------------------------------------------------------------------
-- 8.9 Hitbox Expander
--------------------------------------------------------------------------------
task.spawn(function()
    while env.K2NTA_RunID == currentRunId do
        if env.State.HitboxExpander then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        hrp.Size = Vector3.new(env.State.HitboxSize, env.State.HitboxSize, env.State.HitboxSize)
                        hrp.Transparency = 0.7
                        hrp.CanCollide = false
                    end
                end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and hrp.Size.X > 2 then
                        hrp.Size = Vector3.new(2, 2, 1)
                        hrp.Transparency = 1
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

--------------------------------------------------------------------------------
-- 9. Invisible Map
--------------------------------------------------------------------------------
local invisOriginals = {}
local function isPlayerPart(obj)
    for _, p in ipairs(Players:GetPlayers()) do
        local c = p.Character
        if c and obj:IsDescendantOf(c) then return true end
    end
    return false
end
local function applyInvisMap(enable)
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj and obj.Parent and not isPlayerPart(obj) then
            if obj:IsA("BasePart") or obj:IsA("UnionOperation") or obj:IsA("MeshPart")
               or obj:IsA("WedgePart") or obj:IsA("TrussPart") or obj:IsA("CornerWedgePart") then
                if enable then
                    invisOriginals[obj] = obj.Transparency
                    pcall(function() obj.Transparency = 1 end); count = count + 1
                else
                    if invisOriginals[obj] ~= nil then
                        pcall(function() obj.Transparency = invisOriginals[obj] end)
                        invisOriginals[obj] = nil; count = count + 1
                    end
                end
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                pcall(function() obj.Transparency = enable and 1 or 0 end)
            end
        end
        if count % 100 == 0 then task.wait() end
    end
    if enable then
        if env.UpdateStatus then env.UpdateStatus("👻 Map ล่องหน (" .. count .. " ชิ้น)") end
    else
        if env.UpdateStatus then env.UpdateStatus("👁 Map กลับมาแล้ว!") end
        invisOriginals = {}
    end
end
local function setInvisMap(val)
    env.State.InvisMap = val
    task.spawn(function() applyInvisMap(env.State.InvisMap) end)
end

--------------------------------------------------------------------------------
-- 10. Night Mode
--------------------------------------------------------------------------------
task.spawn(function()
    while env.K2NTA_RunID == currentRunId do
        if env.State.NightMode then Lighting.ClockTime = 0 end
        task.wait(1)
    end
end)
local function setNightMode(val)
    env.State.NightMode = val
    if not env.State.NightMode then Lighting.ClockTime = 14 end
end

--------------------------------------------------------------------------------
-- 11. Freecam (กล้องอิสระ)
--------------------------------------------------------------------------------
env.Freecam = { Part = nil, RenderConn = nil }
local FC_SPEED = 60

local function setFreecam(val)
    env.State.Freecam = val
    if env.State.Freecam then
        local p = Instance.new("Part")
        p.Anchored = true
        p.CanCollide = false
        p.Transparency = 1
        p.Size = Vector3.new(1,1,1)
        p.CFrame = camera.CFrame
        p.Parent = workspace
        env.Freecam.Part = p
        camera.CameraSubject = p
        
        env.Freecam.RenderConn = RunService.RenderStepped:Connect(function(dt)
            local mv = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + Vector3.new(0,0,-1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv + Vector3.new(0,0,1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv + Vector3.new(-1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + Vector3.new(1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv + Vector3.new(0,-1,0) end
            
            if mv.Magnitude > 0 then
                mv = mv.Unit
                local camCF = camera.CFrame
                local dir = camCF:VectorToWorldSpace(mv)
                if env.Freecam.Part then
                    env.Freecam.Part.CFrame = env.Freecam.Part.CFrame + (dir * (FC_SPEED * dt))
                end
            end
        end)
    else
        if env.Freecam.RenderConn then
            env.Freecam.RenderConn:Disconnect()
            env.Freecam.RenderConn = nil
        end
        if env.Freecam.Part then
            env.Freecam.Part:Destroy()
            env.Freecam.Part = nil
        end
        local c = player.Character
        if c and c:FindFirstChild("Humanoid") then
            camera.CameraSubject = c.Humanoid
        end
    end
end

--------------------------------------------------------------------------------
-- 12. Infinite Jump & Invisibility
--------------------------------------------------------------------------------
if env.InfiniteJumpConnection then
    env.InfiniteJumpConnection:Disconnect()
    env.InfiniteJumpConnection = nil
end
env.InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
    if env.K2NTA_RunID ~= currentRunId then return end
    if env.State.InfiniteJump then
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

local function SetInvisibility(state)
    local char = player.Character
    if not char then return end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.Transparency = state and 1 or 0
        elseif v:IsA("Decal") then
            v.Transparency = state and 1 or 0
        end
    end
end

if env.CharAddedConn then
    env.CharAddedConn:Disconnect()
end
env.CharAddedConn = player.CharacterAdded:Connect(function(char)
    if env.K2NTA_RunID ~= currentRunId then return end
    task.wait(0.5)
    if env.State.Invisibility then
        SetInvisibility(true)
    end
end)

local function setInvisibility(val)
    env.State.Invisibility = val
    SetInvisibility(val)
end

--------------------------------------------------------------------------------
-- ผูก UI (KT_UI-V1)
--------------------------------------------------------------------------------
local PlayerTab = Window:Tab({ Title = "Player Features", Icon = "user" })
PlayerTab:Toggle({ Title = "Anti-Fling (กันโดนชนกระเด็น/บัคตกแมพ)", Image = "shield", Callback = function(val)
    env.State.AntiFling = val
end })
PlayerTab:Toggle({ Title = "เปิดใช้งาน เดินเร็ว/กระโดดสูง", Image = "zap", Callback = function(val)
    env.State.SpeedEnabled = val
end })
PlayerTab:Slider({ Title = "ความเร็วเดิน (WalkSpeed)", Min = 16, Max = 150, Value = 16, Callback = function(val)
    env.State.WalkSpeed = val
    if env.State.SpeedEnabled then
        local c = player.Character; local hum = c and c:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
end })
PlayerTab:Slider({ Title = "ความสูงกระโดด (JumpPower)", Min = 50, Max = 200, Value = 50, Callback = function(val)
    env.State.JumpPower = val
    if env.State.SpeedEnabled then
        local c = player.Character; local hum = c and c:FindFirstChild("Humanoid")
        if hum then hum.JumpPower = val end
    end
end })

PlayerTab:Toggle({ Title = "Ghost Fly (บิน/วาป)", Image = "ghost", Callback = setGhostFly })
PlayerTab:Slider({ Title = "ความเร็ว Ghost Fly", Min = 20, Max = 200, Value = 50, Callback = function(val)
    FLY_SPEED = val
end })

PlayerTab:Toggle({ Title = "Freecam (กล้องอิสระ)", Image = "camera", Callback = setFreecam })
PlayerTab:Slider({ Title = "ความเร็ว Freecam", Min = 20, Max = 200, Value = 60, Callback = function(val)
    FC_SPEED = val
end })

PlayerTab:Toggle({ Title = "Infinite Jump (กระโดดรัวๆ)", Image = "chevron-up", Value = env.State.InfiniteJump, Callback = function(val)
    env.State.InfiniteJump = val
end })
PlayerTab:Toggle({ Title = "Character Invisibility (ล่องหนตัวละคร)", Image = "eye-off", Value = env.State.Invisibility, Callback = setInvisibility })

-- ลูปบังคับความเร็ว
task.spawn(function()
    while env.K2NTA_RunID == currentRunId do
        if env.State.SpeedEnabled then
            local c = player.Character; local hum = c and c:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = env.State.WalkSpeed
                if not hum.UseJumpPower then hum.UseJumpPower = true end
                hum.JumpPower = env.State.JumpPower
            end
        end
        task.wait(0.5)
    end
end)

local VisualTab = Window:Tab({ Title = "Visuals & ESP", Icon = "eye" })
VisualTab:Toggle({ Title = "Team ESP (มองทะลุ)", Image = "eye", Value = env.State.TeamESP, Callback = setESP })
VisualTab:Toggle({ Title = "Coin ESP (ไฮไลท์เหรียญ)", Image = "coins", Value = env.State.CoinESP, Callback = setCoinESP })
VisualTab:Toggle({ Title = "Gun ESP (มองทะลุปืนตกพื้น)", Image = "crosshair", Value = env.State.GunESP, Callback = setGunESP })
VisualTab:Toggle({ Title = "Invisible Map (ล่องหน)", Image = "map", Value = env.State.InvisMap, Callback = setInvisMap })
VisualTab:Toggle({ Title = "Night Mode (กลางคืน)", Image = "moon", Value = env.State.NightMode, Callback = setNightMode })

local FarmTab = Window:Tab({ Title = "Auto Farm", Icon = "zap" })
FarmTab:Toggle({ Title = "Auto Farm Coin", Image = "zap", Value = env.State.AutoCoin, Callback = setAutoCoin })
FarmTab:Keybind({ Title = "Keybind: Auto Farm Coin", Image = "zap", Key = Enum.KeyCode.F5, Value = false, Callback = function(val, key)
    if val then setAutoCoin(not env.State.AutoCoin) end
end })
FarmTab:Toggle({ Title = "Fast Sweep Coin (กวาดรวดเดียว)", Image = "zap", Value = env.State.FastAutoCoin, Callback = setFastAutoCoin })
FarmTab:Keybind({ Title = "Keybind: Fast Sweep", Image = "zap", Key = Enum.KeyCode.F6, Value = false, Callback = function(val, key)
    if val then setFastAutoCoin(not env.State.FastAutoCoin) end
end })
FarmTab:Slider({ Title = "ความเร็วบิน Auto Farm (studs/s)", Min = 20, Max = 300, Value = env.State.FarmSpeed, Callback = function(val)
    env.State.FarmSpeed = val
end })
FarmTab:Toggle({ Title = "Auto Get Gun (เก็บปืน)", Image = "crosshair", Value = env.State.AutoGun, Callback = setAutoGun })
FarmTab:Keybind({ Title = "Keybind: Auto Get Gun", Image = "crosshair", Key = Enum.KeyCode.F7, Value = false, Callback = function(val, key)
    if val then setAutoGun(not env.State.AutoGun) end
end })

local CombatTab = Window:Tab({ Title = "Aimbot & Combat", Icon = "swords" })
CombatTab:Toggle({ Title = "ล็อคเป้าเฉพาะฆาตกรเท่านั้น", Image = "shield", Value = env.State.TargetMurdererOnly, Callback = function(val) env.State.TargetMurdererOnly = val end })
CombatTab:Toggle({ Title = "แสดงวงกลมล็อคเป้า (FOV)", Image = "eye", Value = env.State.ShowFOV, Callback = function(val) env.State.ShowFOV = val end })
CombatTab:Slider({ Title = "ขนาด FOV", Min = 10, Max = 800, Value = env.State.FOVSize, Callback = function(val) env.State.FOVSize = val end })
CombatTab:Toggle({ Title = "แสดงเส้นชี้เป้า (Tracer)", Image = "crosshair", Value = env.State.ShowTracer, Callback = function(val) env.State.ShowTracer = val end })
CombatTab:Toggle({ Title = "ล็อคเป้า (Aim Lock) [คลิกขวาค้าง]", Image = "user", Value = env.State.AimLock, Callback = function(val) env.State.AimLock = val end })
CombatTab:Toggle({ Title = "Hitbox Expander (ขยายเป้าศัตรูใหญ่)", Image = "expand", Value = env.State.HitboxExpander, Callback = function(val) env.State.HitboxExpander = val end })
CombatTab:Slider({ Title = "Hitbox Size", Min = 5, Max = 50, Value = env.State.HitboxSize, Callback = function(val) env.State.HitboxSize = val end })
CombatTab:Toggle({ Title = "Auto Fling Murderer (ปั่นฆาตกรกระเด็น)", Image = "refresh-cw", Value = env.State.AutoFling, Callback = function(val) env.State.AutoFling = val end })
CombatTab:Toggle({ Title = "Silent Aim (ยิงโดนฆาตกรอัตโนมัติ)", Image = "crosshair", Value = env.State.SilentAim, Callback = setSilentAim })
CombatTab:Toggle({ Title = "Auto Shoot (ยิงฆาตกรทันทีที่เห็น)", Image = "zap", Value = env.State.AutoShoot, Callback = setAutoShoot })
CombatTab:Keybind({ Title = "Keybind: Auto Shoot", Image = "zap", Key = Enum.KeyCode.F1, Value = false, Callback = function(val)
    if val then setAutoShoot(not env.State.AutoShoot) end
end })
CombatTab:Toggle({ Title = "Auto Kill คนมีมีด", Image = "swords", Value = env.State.KillMurderer, Callback = setKillMurderer })
CombatTab:Keybind({ Title = "Keybind: Auto Kill มีด", Image = "swords", Key = Enum.KeyCode.F2, Value = false, Callback = function(val)
    if val then setKillMurderer(not env.State.KillMurderer) end
end })
CombatTab:Toggle({ Title = "Auto Kill คนอื่น", Image = "skull", Value = env.State.KillOthers, Callback = setKillOthers })
CombatTab:Keybind({ Title = "Keybind: Auto Kill คนอื่น", Image = "skull", Key = Enum.KeyCode.F3, Value = false, Callback = function(val)
    if val then setKillOthers(not env.State.KillOthers) end
end })
CombatTab:Toggle({ Title = "Anti-Murderer (วาปหนีมีด)", Image = "shield", Value = env.State.AntiMurderer, Callback = setAntiMurderer })
CombatTab:Keybind({ Title = "Keybind: Anti-Murderer", Image = "shield", Key = Enum.KeyCode.F4, Value = false, Callback = function(val)
    if val then setAntiMurderer(not env.State.AntiMurderer) end
end })

--------------------------------------------------------------------------------
-- Teleport ผู้เล่น & แผนที่
--------------------------------------------------------------------------------
TPTab:Button({
    Title = "วาปไป Lobby",
    Desc = "ล็อบบี้หลัก (Main Lobby)",
    Image = "home",
    Callback = function()
        local lobby = workspace:FindFirstChild("Lobby")
        if lobby and lobby:FindFirstChild("Spawns") then
            local spawns = lobby.Spawns:GetChildren()
            if #spawns > 0 then
                local spawnPt = spawns[math.random(1, #spawns)]
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = spawnPt.CFrame * CFrame.new(0,3,0) end
            end
        end
    end
})

TPTab:Button({
    Title = "วาปไปด่านปัจจุบัน",
    Desc = "สุ่มจุดเกิดภายในด่านปัจจุบัน (Current Map)",
    Image = "map",
    Callback = function()
        local normal = workspace:FindFirstChild("Normal")
        if normal and normal:FindFirstChild("Spawns") then
            local spawns = normal.Spawns:GetChildren()
            if #spawns > 0 then
                local spawnPt = spawns[math.random(1, #spawns)]
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = spawnPt.CFrame * CFrame.new(0,3,0) end
            end
        end
    end
})

TPTab:Button({
    Title = "วาปไปหา Murderer",
    Desc = "เทเลพอร์ตไปหาฆาตกร",
    Image = "swords",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                if checkHasItem(p.Character, "knife") or (p:FindFirstChild("Backpack") and checkHasItem(p.Backpack, "knife")) then
                    local mc = player.Character
                    if mc and mc:FindFirstChild("HumanoidRootPart") then
                        mc.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                        if env.UpdateStatus then env.UpdateStatus("✨ วาปไปหา Murderer: " .. p.Name) end
                        return
                    end
                end
            end
        end
        if env.UpdateStatus then env.UpdateStatus("❌ ไม่พบ Murderer ในรอบนี้") end
    end
})

TPTab:Button({
    Title = "วาปไปหา Sheriff",
    Desc = "เทเลพอร์ตไปหานายอำเภอ",
    Image = "crosshair",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                if checkHasItem(p.Character, "gun") or (p:FindFirstChild("Backpack") and checkHasItem(p.Backpack, "gun")) then
                    local mc = player.Character
                    if mc and mc:FindFirstChild("HumanoidRootPart") then
                        mc.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                        if env.UpdateStatus then env.UpdateStatus("✨ วาปไปหา Sheriff: " .. p.Name) end
                        return
                    end
                end
            end
        end
        if env.UpdateStatus then env.UpdateStatus("❌ ไม่พบ Sheriff ในรอบนี้") end
    end
})

TPTab:Button({
    Title = "วาปไปหาผู้เล่นสุ่ม",
    Desc = "เทเลพอร์ตไปหาผู้เล่นคนอื่นแบบสุ่ม (Innocent)",
    Image = "users",
    Callback = function()
        local availablePlayers = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(availablePlayers, p)
            end
        end
        
        if #availablePlayers > 0 then
            local targetPlayer = availablePlayers[math.random(1, #availablePlayers)]
            local mc = player.Character
            if mc and mc:FindFirstChild("HumanoidRootPart") then
                mc.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                if env.UpdateStatus then env.UpdateStatus("✨ วาปไปหาสุ่ม: " .. targetPlayer.Name) end
            end
        else
            if env.UpdateStatus then env.UpdateStatus("❌ ไม่มีผู้เล่นอื่นให้วาป") end
        end
    end
})

TPTab:Button({
    Title = "Server Hop (ย้ายเซิฟเวอร์)",
    Desc = "สุ่มหาห้องที่คนไม่เต็มและย้ายไปทันที",
    Image = "server",
    Callback = function()
        if env.UpdateStatus then env.UpdateStatus("🔄 กำลังหาห้องใหม่...") end
        local TeleportService = game:GetService("TeleportService")
        local servers = {}
        
        local function getServers()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
            local success, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(url))
            end)
            if success and result and result.data then
                for _, server in pairs(result.data) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        table.insert(servers, server.id)
                    end
                end
            end
        end
        
        getServers()
        
        if #servers > 0 then
            local randomServer = servers[math.random(1, #servers)]
            TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, player)
        else
            if env.UpdateStatus then env.UpdateStatus("❌ ไม่พบเซิฟเวอร์ว่าง") end
        end
    end
})

--------------------------------------------------------------------------------
-- Credit Tab
--------------------------------------------------------------------------------
local UserInfo = {
    DiscordLink = "https://discord.gg/KTutXbng",
    ScriptStore = "https://www.youtube.com/@KENTAAAEIEI",
    Developer = "XEROX HUP",
    Version = "v1.1",
    UpdateLog = "📝 อัพเดตล่าสุด:\n• เพิ่มระบบควบคุม RGB\n• เพิ่มตัวเลือกปุ่ม Aimbot\n• เพิ่ม Color Picker\n• ลบ Noclip ออก",
    Support = "สำหรับการสนับสนุนและรายงานบั๊ก"
}

CreditTab:Label({ Title = "ผู้พัฒนา", Desc = UserInfo.Developer })
CreditTab:Label({ Title = "เวอร์ชั่น", Desc = UserInfo.Version })
CreditTab:Label({ Title = UserInfo.Support })
if setclipboard then
    CreditTab:Button({ Title = "คัดลอกลิ้งค์ Discord", Callback = function() setclipboard(UserInfo.DiscordLink); env.UpdateStatus("Copied Discord Link!") end })
    CreditTab:Button({ Title = "คัดลอกลิ้งค์ Youtube", Callback = function() setclipboard(UserInfo.ScriptStore); env.UpdateStatus("Copied Youtube Link!") end })
end
CreditTab:Label({ Title = "Update Log", Desc = UserInfo.UpdateLog })

--------------------------------------------------------------------------------
-- Console Tab (Log ระบบ)
--------------------------------------------------------------------------------
local ConsoleTab = Window:Tab({ Title = "Console", Icon = "terminal" })
env.Console = ConsoleTab:Console({ Title = "K2NTA System Log", MaxLines = 150 })

ConsoleTab:Toggle({ Title = "เปิดโหมด Debug (แสดงข้อมูลเบื้องหลัง)", Image = "eye", Value = env.State.DebugMode, Callback = function(val)
    env.State.DebugMode = val
    if val then
        env.UpdateStatus("◈ Debug Mode: Enabled")
    else
        env.UpdateStatus("◈ Debug Mode: Disabled")
    end
end })

--------------------------------------------------------------------------------
-- Status & Debug Wrapper → ส่งไป Console UI
--------------------------------------------------------------------------------
env.UpdateStatus = function(text)
    if not text then return end
    -- ตรวจ level จาก emoji prefix อัตโนมัติ
    local level = "info"
    if text:match("^✅") or text:match("^✓") then
        level = "success"
    elseif text:match("^❌") or text:match("^✗") then
        level = "error"
    elseif text:match("^⚠") or text:match("^⚡") or text:match("^Auto Kill priority") then
        level = "warn"
    elseif text:match("^◈") or text:match("^K2NTA") then
        level = "system"
    end
    if env.Console then
        pcall(function() env.Console:Log(text, level) end)
    end
    print("[K2NTA] " .. text)
end

env.DebugLog = function(text)
    if env.State.DebugMode then
        env.UpdateStatus("◈ [DEBUG] " .. text)
    end
end

print("✅ K2NTA HUB (KT_UI-V1) โหลดสำเร็จ!")
env.UpdateStatus("✅ K2NTA HUB โหลดสำเร็จ!")
