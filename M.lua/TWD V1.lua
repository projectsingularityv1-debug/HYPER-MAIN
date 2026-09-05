-- ========================================================
-- // TWD V1 / Zombie Apocalypse Hub — Ultimate Edition
-- // Created by K2NTA ST | Project Singularity
-- ========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ========================================================
-- // Anti-Overlap & Clean Up Old Runs
-- ========================================================
local env = (getgenv and getgenv()) or _G
local runId = tick()
env.ZombieApocalypse_RunID = runId

if env.ZombieApocalypse_Cleanup then
    pcall(env.ZombieApocalypse_Cleanup)
end

pcall(function()
    for _, v in ipairs(CoreGui:GetChildren()) do
        if v.Name == "Dummy Kawaii" or v.Name == "ZombieApocalypseHub" then v:Destroy() end
    end
    if LocalPlayer:FindFirstChild("PlayerGui") then
        for _, v in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            if v.Name == "Dummy Kawaii" or v.Name == "ZombieApocalypseHub" then v:Destroy() end
        end
    end
end)

-- ========================================================
-- // 1. Built-in Anti-Cheat Bypass & Safety Layer
-- ========================================================
local AC_Bypass = {
    ProtectedRemoteFunctions = {},
    BlockedEvents = {},
    TimeoutSet = false
}

-- ป้องกัน Script Crash จาก Infinite Loops ของเซิร์ฟเวอร์
pcall(function()
    if game:GetService("ScriptContext").SetTimeout then
        game:GetService("ScriptContext"):SetTimeout(2)
        AC_Bypass.TimeoutSet = true
    end
end)

-- ดักและ Bypass RemoteFunction OnClientInvoke
pcall(function()
    local instances = (getinstances and getinstances()) or Workspace:GetDescendants()
    for _, inst in ipairs(instances) do
        if inst:IsA("RemoteFunction") then
            local origCallback = nil
            if getcallbackvalue then
                origCallback = getcallbackvalue(inst, "OnClientInvoke")
            end
            
            if origCallback or inst.Name:lower():find("check") or inst.Name:lower():find("anticheat") or inst.Name:lower():find("ac") or inst.Name:lower():find("detect") then
                table.insert(AC_Bypass.ProtectedRemoteFunctions, inst.Name)
                inst.OnClientInvoke = function(...)
                    return true
                end
            end
        end
    end
end)

-- ป้องกันการตรวจจับ Metamethod (__namecall / __index)
pcall(function()
    if hookmetamethod and checkcaller then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if not checkcaller() then
                -- บล็อกการส่งรีพอร์ตแบนหรือรีโมทแอนตี้ชีตที่สงสัย
                if tostring(method) == "FireServer" or tostring(method) == "InvokeServer" then
                    local name = tostring(self.Name):lower()
                    if name:find("ban") or name:find("flag") or name:find("cheat") or name:find("detection") or name:find("report") then
                        return nil
                    end
                end
            end
            
            return oldNamecall(self, ...)
        end))
    end
end)

-- ========================================================
-- // 2. State & Configurations
-- ========================================================
local State = {
    -- Auto Farm / Combat
    AutoFarm = false,
    FarmMode = "Float Above", -- "Float Above", "Behind"
    FarmDistance = 9,
    AutoAttack = false,
    KillAura = false,
    KillAuraRadius = 25,
    AutoEquipWeapon = true,
    
    -- Gun Mods / Silent Aim
    SilentAim = false,
    AimTargetPart = "Head", -- "Head", "HumanoidRootPart"
    SilentAimFOV = 180,
    ShowFOV = false,
    WallCheck = false,
    InfiniteAmmo = false,
    FastReload = false,
    NoRecoil = false,
    NoSpread = false,
    
    -- Visuals / ESP
    ZombieESP = true,
    ZombieESP_Box = true,
    ZombieESP_Name = true,
    ZombieESP_Health = true,
    ZombieESP_Distance = true,
    ZombieESP_Tracer = false,
    PlayerESP = false,
    DropESP = true,
    
    -- Player / Movement
    GhostFly = false,
    GhostFlySpeed = 60,
    SpeedHack = false,
    WalkSpeed = 16,
    JumpPowerHack = false,
    JumpPower = 50,
    InfiniteJump = false,
    Noclip = false,
    
    -- Utilities
    AutoCollectDrops = false,
    FullBright = false,
    RemoveFog = false,
    AntiAFK = true
}

-- ========================================================
-- // 3. Target Detection Helpers (Zombies & Items)
-- ========================================================
local function isAlive(model)
    if not model or not model.Parent then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
    return hum and hum.Health > 0 and hrp ~= nil
end

local function isPlayerModel(model)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then
            return true
        end
    end
    return false
end

local function isZombie(model)
    if not model:IsA("Model") then return false end
    if isPlayerModel(model) then return false end
    if not isAlive(model) then return false end
    
    local name = model.Name:lower()
    local parentName = (model.Parent and model.Parent.Name:lower()) or ""
    
    if name:find("zombie") or name:find("walker") or name:find("infected") or name:find("enemy") or name:find("mutant") or name:find("runner") or name:find("crawler") or name:find("boss") or name:find("undead") or name:find("monster") then
        return true
    end
    if parentName:find("zombie") or parentName:find("enemies") or parentName:find("mobs") or parentName:find("badguys") or parentName:find("spawns") or parentName:find("npcs") then
        return true
    end
    
    if model:FindFirstChildOfClass("Humanoid") then
        return true
    end
    
    return false
end

local function getAllZombies()
    local list = {}
    
    local searchFolders = {
        Workspace:FindFirstChild("Zombies"),
        Workspace:FindFirstChild("Enemies"),
        Workspace:FindFirstChild("Mobs"),
        Workspace:FindFirstChild("BadGuys"),
        Workspace:FindFirstChild("NPCs"),
        Workspace:FindFirstChild("Infected"),
        Workspace:FindFirstChild("Characters")
    }
    
    for _, folder in ipairs(searchFolders) do
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if isZombie(child) then
                    table.insert(list, child)
                end
            end
        end
    end
    
    if #list == 0 then
        for _, child in ipairs(Workspace:GetChildren()) do
            if isZombie(child) then
                table.insert(list, child)
            end
        end
    end
    
    return list
end

local function getClosestZombie(maxDistance)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = char.HumanoidRootPart.Position
    
    local closest = nil
    local shortestDist = maxDistance or math.huge
    
    for _, z in ipairs(getAllZombies()) do
        local hrp = z:FindFirstChild("HumanoidRootPart") or z:FindFirstChild("Torso") or z:FindFirstChild("UpperTorso")
        if hrp then
            local dist = (myPos - hrp.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                closest = z
            end
        end
    end
    
    return closest, shortestDist
end

-- ========================================================
-- // 4. FOV Circle & Silent Aim Logic
-- ========================================================
local hasDrawing = (type(Drawing) == "table" or type(Drawing) == "function")
local fovCircle = nil
if hasDrawing then
    pcall(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Color = Color3.fromRGB(0, 255, 170)
        fovCircle.Thickness = 1.5
        fovCircle.NumSides = 64
        fovCircle.Radius = State.SilentAimFOV
        fovCircle.Filled = false
        fovCircle.Transparency = 0.9
        fovCircle.Visible = false
    end)
end

local function getSilentAimTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local bestTarget = nil
    local bestDist = State.SilentAimFOV
    
    for _, z in ipairs(getAllZombies()) do
        local part = z:FindFirstChild(State.AimTargetPart) or z:FindFirstChild("HumanoidRootPart") or z:FindFirstChild("Head")
        if part then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < bestDist then
                    if State.WallCheck then
                        local origin = Camera.CFrame.Position
                        local dir = (part.Position - origin)
                        local rayParams = RaycastParams.new()
                        rayParams.FilterType = Enum.RaycastFilterType.Blacklist or Enum.RaycastFilterType.Exclude
                        rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                        local result = Workspace:Raycast(origin, dir, rayParams)
                        if result and result.Instance and result.Instance:IsDescendantOf(z) then
                            bestDist = dist
                            bestTarget = part
                        end
                    else
                        bestDist = dist
                        bestTarget = part
                    end
                end
            end
        end
    end
    
    return bestTarget
end

-- Silent Aim Hook
pcall(function()
    if hookmetamethod and checkcaller then
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, prop)
            if not checkcaller() and State.SilentAim and tostring(prop) == "Hit" and tostring(self) == "Mouse" then
                local targetPart = getSilentAimTarget()
                if targetPart then
                    return targetPart.CFrame
                end
            end
            return oldIndex(self, prop)
        end))
    end
end)

-- ========================================================
-- // 5. Ghost Fly & Movement
-- ========================================================
local flyVelocity = nil
local flyGyro = nil
local flyKeys = { W = false, A = false, S = false, D = false, Space = false, LeftShift = false }

local function startGhostFly()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end
    
    if hrp:FindFirstChild("GhostFlyVelocity") then hrp.GhostFlyVelocity:Destroy() end
    if hrp:FindFirstChild("GhostFlyGyro") then hrp.GhostFlyGyro:Destroy() end
    
    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.Name = "GhostFlyVelocity"
    flyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = hrp
    
    flyGyro = Instance.new("BodyGyro")
    flyGyro.Name = "GhostFlyGyro"
    flyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyGyro.P = 3000
    flyGyro.D = 500
    flyGyro.CFrame = Camera.CFrame
    flyGyro.Parent = hrp
end

local function stopGhostFly()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if hrp:FindFirstChild("GhostFlyVelocity") then hrp.GhostFlyVelocity:Destroy() end
            if hrp:FindFirstChild("GhostFlyGyro") then hrp.GhostFlyGyro:Destroy() end
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
        end
    end
end

-- ========================================================
-- // 6. Weapons & Combat Actions
-- ========================================================
local function equipBestWeapon()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then return item end
    end
    
    if LocalPlayer.Backpack then
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                hum:EquipTool(tool)
                return tool
            end
        end
    end
    return nil
end

local function triggerAttack(targetPart)
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = equipBestWeapon()
    if tool then
        pcall(function() tool:Activate() end)
    end
    
    if mouse1click then
        pcall(mouse1click)
    else
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2))
        end)
    end
    
    pcall(function()
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local rName = obj.Name:lower()
                if rName:find("hit") or rName:find("damage") or rName:find("attack") or rName:find("shoot") or rName:find("bullet") then
                    if targetPart then
                        obj:FireServer(targetPart, targetPart.Position)
                    end
                end
            end
        end
    end)
end

-- ========================================================
-- // 7. ESP System
-- ========================================================
local function createZombieESP(model)
    if not model or not model:FindFirstChild("HumanoidRootPart") then return end
    local hrp = model.HumanoidRootPart
    if hrp:FindFirstChild("ZombieHighlight") then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ZombieHighlight"
    highlight.FillColor = Color3.fromRGB(255, 45, 45)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.1
    highlight.Adornee = model
    highlight.Parent = hrp
    
    local bill = Instance.new("BillboardGui")
    bill.Name = "ZombieTag"
    bill.Adornee = hrp
    bill.Size = UDim2.new(0, 100, 0, 40)
    bill.StudsOffset = Vector3.new(0, 3, 0)
    bill.AlwaysOnTop = true
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 80, 80)
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Text = model.Name
    label.Parent = bill
    
    bill.Parent = hrp
end

local function cleanZombieESP()
    for _, z in ipairs(getAllZombies()) do
        local hrp = z:FindFirstChild("HumanoidRootPart")
        if hrp then
            if hrp:FindFirstChild("ZombieHighlight") then hrp.ZombieHighlight:Destroy() end
            if hrp:FindFirstChild("ZombieTag") then hrp.ZombieTag:Destroy() end
        end
    end
end

-- ========================================================
-- // 8. Core Background Loops
-- ========================================================
local steppedConn = RunService.Stepped:Connect(function()
    if env.ZombieApocalypse_RunID ~= runId then return end
    
    local char = LocalPlayer.Character
    if char and (State.Noclip or State.GhostFly or State.AutoFarm) then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
    
    if State.SpeedHack and char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = State.WalkSpeed
    end
    
    if State.JumpPowerHack and char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").JumpPower = State.JumpPower
    end
end)

local renderConn = RunService.RenderStepped:Connect(function()
    if env.ZombieApocalypse_RunID ~= runId then return end
    
    if fovCircle then
        local mousePos = UserInputService:GetMouseLocation()
        fovCircle.Position = mousePos
        fovCircle.Radius = State.SilentAimFOV
        fovCircle.Visible = State.ShowFOV and State.SilentAim
    end
    
    if State.GhostFly and flyVelocity and flyGyro then
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
        
        flyVelocity.Velocity = moveDir * State.GhostFlySpeed
        flyGyro.CFrame = Camera.CFrame
    end
    
    if State.ZombieESP then
        for _, z in ipairs(getAllZombies()) do
            createZombieESP(z)
            local hrp = z:FindFirstChild("HumanoidRootPart")
            if hrp and hrp:FindFirstChild("ZombieTag") and hrp.ZombieTag:FindFirstChildOfClass("TextLabel") then
                local hum = z:FindFirstChildOfClass("Humanoid")
                local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local dist = myHrp and math.floor((myHrp.Position - hrp.Position).Magnitude) or 0
                local hp = hum and math.floor(hum.Health) or 0
                local maxHp = hum and math.floor(hum.MaxHealth) or 100
                hrp.ZombieTag.TextLabel.Text = string.format("%s\n[%d/%d HP] (%dm)", z.Name, hp, maxHp, dist)
            end
        end
    end
end)

-- Main Farm Task
task.spawn(function()
    while env.ZombieApocalypse_RunID == runId do
        if State.AutoFarm then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                local target, dist = getClosestZombie()
                if target and target:FindFirstChild("HumanoidRootPart") then
                    local targetHrp = target.HumanoidRootPart
                    local targetHead = target:FindFirstChild("Head") or targetHrp
                    
                    local goalPos
                    if State.FarmMode == "Float Above" then
                        goalPos = targetHrp.Position + Vector3.new(0, State.FarmDistance, 0)
                    else
                        goalPos = targetHrp.Position - (targetHrp.CFrame.LookVector * State.FarmDistance) + Vector3.new(0, 3, 0)
                    end
                    
                    hrp.CFrame = CFrame.new(goalPos, targetHrp.Position)
                    hrp.Velocity = Vector3.zero
                    
                    if State.AutoAttack then
                        triggerAttack(targetHead)
                    end
                end
            end
        end
        
        if State.KillAura and not State.AutoFarm then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, z in ipairs(getAllZombies()) do
                    local zHrp = z:FindFirstChild("HumanoidRootPart")
                    if zHrp and (zHrp.Position - hrp.Position).Magnitude <= State.KillAuraRadius then
                        local head = z:FindFirstChild("Head") or zHrp
                        triggerAttack(head)
                        break
                    end
                end
            end
        end
        
        if State.AutoCollectDrops then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, item in ipairs(Workspace:GetChildren()) do
                        local iName = item.Name:lower()
                        if iName:find("drop") or iName:find("ammo") or iName:find("medkit") or iName:find("box") or iName:find("cash") or iName:find("coin") then
                            if item:IsA("BasePart") then
                                firetouchinterest(hrp, item, 0)
                                firetouchinterest(hrp, item, 1)
                            elseif item:IsA("Model") and item:FindFirstChildOfClass("BasePart") then
                                firetouchinterest(hrp, item:FindFirstChildOfClass("BasePart"), 0)
                                firetouchinterest(hrp, item:FindFirstChildOfClass("BasePart"), 1)
                            end
                        end
                    end
                end
            end)
        end
        
        task.wait(0.08)
    end
end)

-- ========================================================
-- // 9. Key Bindings
-- ========================================================
local inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.W then flyKeys.W = true end
    if input.KeyCode == Enum.KeyCode.A then flyKeys.A = true end
    if input.KeyCode == Enum.KeyCode.S then flyKeys.S = true end
    if input.KeyCode == Enum.KeyCode.D then flyKeys.D = true end
    if input.KeyCode == Enum.KeyCode.Space then 
        flyKeys.Space = true 
        if State.InfiniteJump then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
    if input.KeyCode == Enum.KeyCode.LeftShift then flyKeys.LeftShift = true end
end)

local inputEndedConn = UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.W then flyKeys.W = false end
    if input.KeyCode == Enum.KeyCode.A then flyKeys.A = false end
    if input.KeyCode == Enum.KeyCode.S then flyKeys.S = false end
    if input.KeyCode == Enum.KeyCode.D then flyKeys.D = false end
    if input.KeyCode == Enum.KeyCode.Space then flyKeys.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then flyKeys.LeftShift = false end
end)

if State.AntiAFK then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end

env.ZombieApocalypse_Cleanup = function()
    if steppedConn then steppedConn:Disconnect() end
    if renderConn then renderConn:Disconnect() end
    if inputBeganConn then inputBeganConn:Disconnect() end
    if inputEndedConn then inputEndedConn:Disconnect() end
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    stopGhostFly()
    cleanZombieESP()
end

-- ========================================================
-- // 10. STANDALONE SINGULARITY UI LIBRARY (NATIVE)
-- ========================================================
local Library = {}

function Library:Window(options)
    options = options or {}
    local Title = options.Title or "TWD V1 Hub"
    local Desc = options.Desc or ""
    local Profile = options.Profile or {}
    local ProfileUsername = Profile.Username or LocalPlayer.DisplayName
    local ProfileEmail = Profile.Email or ("UID: " .. tostring(LocalPlayer.UserId))
    local ProfileAvatar = Profile.AvatarUrl or ("rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150")
    local ToggleKey = (options.Config and options.Config.Keybind) or Enum.KeyCode.RightShift

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SingularityTWDHub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
            ScreenGui.Parent = CoreGui
        elseif gethui then
            ScreenGui.Parent = gethui()
        else
            ScreenGui.Parent = CoreGui
        end
    end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.fromOffset(590, 430)
    MainFrame.Position = UDim2.new(0.5, -295, 0.5, -215)
    MainFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner", MainFrame)
    MainCorner.CornerRadius = UDim.new(0, 10)

    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color = Color3.fromRGB(35, 40, 55)
    MainStroke.Thickness = 1.2

    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local Sidebar = Instance.new("Frame", MainFrame)
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 175, 1, 0)
    Sidebar.BackgroundColor3 = Color3.fromRGB(12, 14, 19)
    Sidebar.BorderSizePixel = 0
    local SidebarCorner = Instance.new("UICorner", Sidebar)
    SidebarCorner.CornerRadius = UDim.new(0, 10)

    local ProfileFrame = Instance.new("Frame", Sidebar)
    ProfileFrame.Size = UDim2.new(1, -16, 0, 50)
    ProfileFrame.Position = UDim2.new(0, 8, 0, 8)
    ProfileFrame.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    local PCorner = Instance.new("UICorner", ProfileFrame)
    PCorner.CornerRadius = UDim.new(0, 8)

    local AvatarImg = Instance.new("ImageLabel", ProfileFrame)
    AvatarImg.Size = UDim2.fromOffset(36, 36)
    AvatarImg.Position = UDim2.new(0, 7, 0.5, -18)
    AvatarImg.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
    AvatarImg.Image = ProfileAvatar
    local ACorner = Instance.new("UICorner", AvatarImg)
    ACorner.CornerRadius = UDim.new(1, 0)

    local UserLabel = Instance.new("TextLabel", ProfileFrame)
    UserLabel.Size = UDim2.new(1, -52, 0, 16)
    UserLabel.Position = UDim2.new(0, 48, 0, 9)
    UserLabel.BackgroundTransparency = 1
    UserLabel.Font = Enum.Font.GothamBold
    UserLabel.TextSize = 12
    UserLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    UserLabel.TextXAlignment = Enum.TextXAlignment.Left
    UserLabel.TextTruncate = Enum.TextTruncate.AtEnd
    UserLabel.Text = ProfileUsername

    local UidLabel = Instance.new("TextLabel", ProfileFrame)
    UidLabel.Size = UDim2.new(1, -52, 0, 14)
    UidLabel.Position = UDim2.new(0, 48, 0, 26)
    UidLabel.BackgroundTransparency = 1
    UidLabel.Font = Enum.Font.Gotham
    UidLabel.TextSize = 10
    UidLabel.TextColor3 = Color3.fromRGB(130, 140, 165)
    UidLabel.TextXAlignment = Enum.TextXAlignment.Left
    UidLabel.TextTruncate = Enum.TextTruncate.AtEnd
    UidLabel.Text = ProfileEmail

    local TabButtonContainer = Instance.new("ScrollingFrame", Sidebar)
    TabButtonContainer.Size = UDim2.new(1, -12, 1, -70)
    TabButtonContainer.Position = UDim2.new(0, 6, 0, 64)
    TabButtonContainer.BackgroundTransparency = 1
    TabButtonContainer.ScrollBarThickness = 2
    TabButtonContainer.BorderSizePixel = 0
    local TabListLayout = Instance.new("UIListLayout", TabButtonContainer)
    TabListLayout.Padding = UDim.new(0, 4)
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local Header = Instance.new("Frame", MainFrame)
    Header.Size = UDim2.new(1, -185, 0, 44)
    Header.Position = UDim2.new(0, 180, 0, 0)
    Header.BackgroundTransparency = 1

    local TitleLabel = Instance.new("TextLabel", Header)
    TitleLabel.Size = UDim2.new(1, -40, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 14
    TitleLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Text = Title .. "  <font color='rgb(0,255,170)'>•</font> <font color='rgb(140,150,175)' size='11'>" .. Desc .. "</font>"
    TitleLabel.RichText = true

    local CloseBtn = Instance.new("TextButton", Header)
    CloseBtn.Size = UDim2.fromOffset(26, 26)
    CloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(200, 205, 220)
    CloseBtn.TextSize = 12
    local CBCorner = Instance.new("UICorner", CloseBtn)
    CBCorner.CornerRadius = UDim.new(0, 6)
    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
    end)

    local PageContainer = Instance.new("Frame", MainFrame)
    PageContainer.Size = UDim2.new(1, -190, 1, -54)
    PageContainer.Position = UDim2.new(0, 180, 0, 48)
    PageContainer.BackgroundTransparency = 1

    local NotifContainer = Instance.new("Frame", ScreenGui)
    NotifContainer.Size = UDim2.new(0, 260, 1, -20)
    NotifContainer.Position = UDim2.new(1, -270, 0, 10)
    NotifContainer.BackgroundTransparency = 1
    local NotifLayout = Instance.new("UIListLayout", NotifContainer)
    NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    NotifLayout.Padding = UDim.new(0, 6)

    local WindowObj = {}
    local tabs = {}
    local activeTab = nil

    function WindowObj:Notify(nOpt)
        nOpt = nOpt or {}
        local nTitle = nOpt.Title or "Notification"
        local nDesc = nOpt.Desc or ""
        local nTime = nOpt.Time or 3

        local Card = Instance.new("Frame", NotifContainer)
        Card.Size = UDim2.new(1, 0, 0, 52)
        Card.BackgroundColor3 = Color3.fromRGB(18, 21, 29)
        local CCorner = Instance.new("UICorner", Card)
        CCorner.CornerRadius = UDim.new(0, 8)
        local CStroke = Instance.new("UIStroke", Card)
        CStroke.Color = Color3.fromRGB(0, 255, 170)
        CStroke.Thickness = 1

        local Txt1 = Instance.new("TextLabel", Card)
        Txt1.Size = UDim2.new(1, -16, 0, 16)
        Txt1.Position = UDim2.new(0, 10, 0, 6)
        Txt1.BackgroundTransparency = 1
        Txt1.Font = Enum.Font.GothamBold
        Txt1.TextSize = 12
        Txt1.TextColor3 = Color3.fromRGB(0, 255, 170)
        Txt1.TextXAlignment = Enum.TextXAlignment.Left
        Txt1.Text = nTitle

        local Txt2 = Instance.new("TextLabel", Card)
        Txt2.Size = UDim2.new(1, -16, 0, 22)
        Txt2.Position = UDim2.new(0, 10, 0, 24)
        Txt2.BackgroundTransparency = 1
        Txt2.Font = Enum.Font.Gotham
        Txt2.TextSize = 11
        Txt2.TextColor3 = Color3.fromRGB(220, 225, 235)
        Txt2.TextXAlignment = Enum.TextXAlignment.Left
        Txt2.TextTruncate = Enum.TextTruncate.AtEnd
        Txt2.Text = nDesc

        task.spawn(function()
            task.wait(nTime)
            TweenService:Create(Card, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            TweenService:Create(Txt1, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            TweenService:Create(Txt2, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            TweenService:Create(CStroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
            task.wait(0.35)
            Card:Destroy()
        end)
    end

    function WindowObj:Tab(tOpt)
        tOpt = tOpt or {}
        local tTitle = tOpt.Title or "Tab"

        local TabBtn = Instance.new("TextButton", TabButtonContainer)
        TabBtn.Size = UDim2.new(1, 0, 0, 32)
        TabBtn.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Font = Enum.Font.GothamSemibold
        TabBtn.Text = "  " .. tTitle
        TabBtn.TextColor3 = Color3.fromRGB(140, 150, 175)
        TabBtn.TextSize = 12
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        local TBCorner = Instance.new("UICorner", TabBtn)
        TBCorner.CornerRadius = UDim.new(0, 6)

        local Page = Instance.new("ScrollingFrame", PageContainer)
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Color3.fromRGB(45, 52, 70)
        Page.BorderSizePixel = 0
        Page.Visible = false
        local PLayout = Instance.new("UIListLayout", Page)
        PLayout.Padding = UDim.new(0, 6)
        PLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local function switchTab()
            for _, t in ipairs(tabs) do
                t.Page.Visible = false
                t.Btn.TextColor3 = Color3.fromRGB(140, 150, 175)
                t.Btn.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
                t.Btn.BackgroundTransparency = 1
            end
            Page.Visible = true
            TabBtn.TextColor3 = Color3.fromRGB(0, 255, 170)
            TabBtn.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
            TabBtn.BackgroundTransparency = 0
            activeTab = Page
        end

        TabBtn.MouseButton1Click:Connect(switchTab)

        local TabObj = { Page = Page, Btn = TabBtn }
        table.insert(tabs, TabObj)

        if #tabs == 1 then
            switchTab()
        end

        function TabObj:Section(sOpt)
            local sTitle = sOpt.Title or "Section"
            local SecFrame = Instance.new("Frame", Page)
            SecFrame.Size = UDim2.new(1, -6, 0, 22)
            SecFrame.BackgroundTransparency = 1

            local SecLbl = Instance.new("TextLabel", SecFrame)
            SecLbl.Size = UDim2.new(1, 0, 1, 0)
            SecLbl.BackgroundTransparency = 1
            SecLbl.Font = Enum.Font.GothamBold
            SecLbl.TextSize = 11
            SecLbl.TextColor3 = Color3.fromRGB(0, 255, 170)
            SecLbl.TextXAlignment = Enum.TextXAlignment.Left
            SecLbl.Text = string.upper(sTitle)
        end

        function TabObj:Toggle(togOpt)
            togOpt = togOpt or {}
            local tgTitle = togOpt.Title or "Toggle"
            local tgDesc = togOpt.Desc or ""
            local tgVal = (togOpt.Value == true or togOpt.Default == true)
            local tgCallback = togOpt.Callback or function() end

            local Row = Instance.new("Frame", Page)
            Row.Size = UDim2.new(1, -6, 0, tgDesc ~= "" and 42 or 34)
            Row.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
            local RCorner = Instance.new("UICorner", Row)
            RCorner.CornerRadius = UDim.new(0, 6)

            local TLbl = Instance.new("TextLabel", Row)
            TLbl.Size = UDim2.new(1, -60, 0, 18)
            TLbl.Position = UDim2.new(0, 10, 0, tgDesc ~= "" and 4 or 8)
            TLbl.BackgroundTransparency = 1
            TLbl.Font = Enum.Font.GothamSemibold
            TLbl.TextSize = 12
            TLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
            TLbl.TextXAlignment = Enum.TextXAlignment.Left
            TLbl.Text = tgTitle

            if tgDesc ~= "" then
                local DLbl = Instance.new("TextLabel", Row)
                DLbl.Size = UDim2.new(1, -60, 0, 14)
                DLbl.Position = UDim2.new(0, 10, 0, 22)
                DLbl.BackgroundTransparency = 1
                DLbl.Font = Enum.Font.Gotham
                DLbl.TextSize = 10
                DLbl.TextColor3 = Color3.fromRGB(130, 140, 165)
                DLbl.TextXAlignment = Enum.TextXAlignment.Left
                DLbl.TextTruncate = Enum.TextTruncate.AtEnd
                DLbl.Text = tgDesc
            end

            local Switch = Instance.new("TextButton", Row)
            Switch.Size = UDim2.fromOffset(40, 20)
            Switch.Position = UDim2.new(1, -48, 0.5, -10)
            Switch.BackgroundColor3 = tgVal and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(35, 40, 52)
            Switch.Text = ""
            local SCorner = Instance.new("UICorner", Switch)
            SCorner.CornerRadius = UDim.new(1, 0)

            local Dot = Instance.new("Frame", Switch)
            Dot.Size = UDim2.fromOffset(16, 16)
            Dot.Position = tgVal and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            local DCorner = Instance.new("UICorner", Dot)
            DCorner.CornerRadius = UDim.new(1, 0)

            local function updateToggle(newVal)
                tgVal = newVal
                TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = tgVal and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(35, 40, 52)}):Play()
                TweenService:Create(Dot, TweenInfo.new(0.2), {Position = tgVal and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
                pcall(tgCallback, tgVal)
            end

            Switch.MouseButton1Click:Connect(function()
                updateToggle(not tgVal)
            end)

            local ClickArea = Instance.new("TextButton", Row)
            ClickArea.Size = UDim2.new(1, -50, 1, 0)
            ClickArea.BackgroundTransparency = 1
            ClickArea.Text = ""
            ClickArea.MouseButton1Click:Connect(function()
                updateToggle(not tgVal)
            end)
        end

        function TabObj:Slider(slOpt)
            slOpt = slOpt or {}
            local sTitle = slOpt.Title or "Slider"
            local sMin = slOpt.Min or 0
            local sMax = slOpt.Max or 100
            local sDefault = slOpt.Default or slOpt.Value or sMin
            local sCallback = slOpt.Callback or function() end
            local curVal = sDefault

            local Row = Instance.new("Frame", Page)
            Row.Size = UDim2.new(1, -6, 0, 48)
            Row.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
            local RCorner = Instance.new("UICorner", Row)
            RCorner.CornerRadius = UDim.new(0, 6)

            local TLbl = Instance.new("TextLabel", Row)
            TLbl.Size = UDim2.new(1, -70, 0, 16)
            TLbl.Position = UDim2.new(0, 10, 0, 6)
            TLbl.BackgroundTransparency = 1
            TLbl.Font = Enum.Font.GothamSemibold
            TLbl.TextSize = 12
            TLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
            TLbl.TextXAlignment = Enum.TextXAlignment.Left
            TLbl.Text = sTitle

            local ValLbl = Instance.new("TextLabel", Row)
            ValLbl.Size = UDim2.new(0, 50, 0, 16)
            ValLbl.Position = UDim2.new(1, -60, 0, 6)
            ValLbl.BackgroundTransparency = 1
            ValLbl.Font = Enum.Font.GothamBold
            ValLbl.TextSize = 12
            ValLbl.TextColor3 = Color3.fromRGB(0, 255, 170)
            ValLbl.TextXAlignment = Enum.TextXAlignment.Right
            ValLbl.Text = tostring(math.floor(curVal))

            local Bar = Instance.new("Frame", Row)
            Bar.Size = UDim2.new(1, -20, 0, 6)
            Bar.Position = UDim2.new(0, 10, 0, 30)
            Bar.BackgroundColor3 = Color3.fromRGB(32, 37, 50)
            local BCorner = Instance.new("UICorner", Bar)
            BCorner.CornerRadius = UDim.new(1, 0)

            local pct = math.clamp((curVal - sMin) / (sMax - sMin), 0, 1)
            local Fill = Instance.new("Frame", Bar)
            Fill.Size = UDim2.new(pct, 0, 1, 0)
            Fill.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
            local FCorner = Instance.new("UICorner", Fill)
            FCorner.CornerRadius = UDim.new(1, 0)

            local sliding = false
            local function moveSlider(input)
                local posX = input.Position.X - Bar.AbsolutePosition.X
                local percent = math.clamp(posX / Bar.AbsoluteSize.X, 0, 1)
                Fill.Size = UDim2.new(percent, 0, 1, 0)
                curVal = math.floor(sMin + ((sMax - sMin) * percent))
                ValLbl.Text = tostring(curVal)
                pcall(sCallback, curVal)
            end

            Bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    moveSlider(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    moveSlider(input)
                end
            end)
        end

        function TabObj:Button(bOpt)
            bOpt = bOpt or {}
            local bTitle = bOpt.Title or "Button"
            local bDesc = bOpt.Desc or ""
            local bCallback = bOpt.Callback or function() end

            local BtnRow = Instance.new("TextButton", Page)
            BtnRow.Size = UDim2.new(1, -6, 0, bDesc ~= "" and 42 or 34)
            BtnRow.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
            BtnRow.AutoButtonColor = false
            BtnRow.Text = ""
            local BRCorner = Instance.new("UICorner", BtnRow)
            BRCorner.CornerRadius = UDim.new(0, 6)

            local TLbl = Instance.new("TextLabel", BtnRow)
            TLbl.Size = UDim2.new(1, -20, 0, 18)
            TLbl.Position = UDim2.new(0, 10, 0, bDesc ~= "" and 4 or 8)
            TLbl.BackgroundTransparency = 1
            TLbl.Font = Enum.Font.GothamSemibold
            TLbl.TextSize = 12
            TLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
            TLbl.TextXAlignment = Enum.TextXAlignment.Left
            TLbl.Text = bTitle

            if bDesc ~= "" then
                local DLbl = Instance.new("TextLabel", BtnRow)
                DLbl.Size = UDim2.new(1, -20, 0, 14)
                DLbl.Position = UDim2.new(0, 10, 0, 22)
                DLbl.BackgroundTransparency = 1
                DLbl.Font = Enum.Font.Gotham
                DLbl.TextSize = 10
                DLbl.TextColor3 = Color3.fromRGB(130, 140, 165)
                DLbl.TextXAlignment = Enum.TextXAlignment.Left
                DLbl.TextTruncate = Enum.TextTruncate.AtEnd
                DLbl.Text = bDesc
            end

            BtnRow.MouseButton1Click:Connect(function()
                TweenService:Create(BtnRow, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30, 36, 50)}):Play()
                delay(0.1, function()
                    TweenService:Create(BtnRow, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 23, 31)}):Play()
                end)
                pcall(bCallback)
            end)

            return {
                SetTitle = function(self, newText)
                    TLbl.Text = newText
                end
            }
        end

        function TabObj:Dropdown(dOpt)
            dOpt = dOpt or {}
            local dTitle = dOpt.Title or "Dropdown"
            local dList = dOpt.List or {}
            local dCur = dOpt.Default or dOpt.Value or dList[1] or ""
            local dCallback = dOpt.Callback or function() end

            local DropFrame = Instance.new("Frame", Page)
            DropFrame.Size = UDim2.new(1, -6, 0, 48)
            DropFrame.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
            DropFrame.ClipsDescendants = true
            local DCorner = Instance.new("UICorner", DropFrame)
            DCorner.CornerRadius = UDim.new(0, 6)

            local TLbl = Instance.new("TextLabel", DropFrame)
            TLbl.Size = UDim2.new(1, -20, 0, 16)
            TLbl.Position = UDim2.new(0, 10, 0, 6)
            TLbl.BackgroundTransparency = 1
            TLbl.Font = Enum.Font.GothamSemibold
            TLbl.TextSize = 12
            TLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
            TLbl.TextXAlignment = Enum.TextXAlignment.Left
            TLbl.Text = dTitle

            local SelectBtn = Instance.new("TextButton", DropFrame)
            SelectBtn.Size = UDim2.new(1, -20, 0, 20)
            SelectBtn.Position = UDim2.new(0, 10, 0, 24)
            SelectBtn.BackgroundColor3 = Color3.fromRGB(28, 33, 44)
            SelectBtn.Font = Enum.Font.Gotham
            SelectBtn.Text = "  " .. tostring(dCur) .. "  ▼"
            SelectBtn.TextColor3 = Color3.fromRGB(0, 255, 170)
            SelectBtn.TextSize = 11
            SelectBtn.TextXAlignment = Enum.TextXAlignment.Left
            local SBCorner = Instance.new("UICorner", SelectBtn)
            SBCorner.CornerRadius = UDim.new(0, 4)

            local DropListFrame = Instance.new("ScrollingFrame", DropFrame)
            DropListFrame.Size = UDim2.new(1, -20, 0, 100)
            DropListFrame.Position = UDim2.new(0, 10, 0, 48)
            DropListFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
            DropListFrame.ScrollBarThickness = 2
            local DListLayout = Instance.new("UIListLayout", DropListFrame)
            DListLayout.Padding = UDim.new(0, 2)

            local isOpen = false
            local function refreshOptions()
                for _, child in ipairs(DropListFrame:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, item in ipairs(dList) do
                    local ItemBtn = Instance.new("TextButton", DropListFrame)
                    ItemBtn.Size = UDim2.new(1, 0, 0, 22)
                    ItemBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
                    ItemBtn.Font = Enum.Font.Gotham
                    ItemBtn.Text = " " .. tostring(item)
                    ItemBtn.TextColor3 = Color3.fromRGB(200, 210, 230)
                    ItemBtn.TextSize = 11
                    ItemBtn.TextXAlignment = Enum.TextXAlignment.Left
                    ItemBtn.MouseButton1Click:Connect(function()
                        dCur = item
                        SelectBtn.Text = "  " .. tostring(dCur) .. "  ▼"
                        isOpen = false
                        TweenService:Create(DropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -6, 0, 48)}):Play()
                        pcall(dCallback, dCur)
                    end)
                end
            end

            SelectBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    refreshOptions()
                    TweenService:Create(DropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -6, 0, 154)}):Play()
                else
                    TweenService:Create(DropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -6, 0, 48)}):Play()
                end
            end)
        end

        function TabObj:Label(lOpt)
            lOpt = lOpt or {}
            local lTitle = lOpt.Title or ""
            local lDesc = lOpt.Desc or ""

            local Row = Instance.new("Frame", Page)
            Row.Size = UDim2.new(1, -6, 0, lDesc ~= "" and 44 or 28)
            Row.BackgroundColor3 = Color3.fromRGB(18, 21, 29)
            local RCorner = Instance.new("UICorner", Row)
            RCorner.CornerRadius = UDim.new(0, 6)

            local TLbl = Instance.new("TextLabel", Row)
            TLbl.Size = UDim2.new(1, -20, 0, 16)
            TLbl.Position = UDim2.new(0, 10, 0, 6)
            TLbl.BackgroundTransparency = 1
            TLbl.Font = Enum.Font.GothamBold
            TLbl.TextSize = 11
            TLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
            TLbl.TextXAlignment = Enum.TextXAlignment.Left
            TLbl.Text = lTitle

            if lDesc ~= "" then
                local DLbl = Instance.new("TextLabel", Row)
                DLbl.Size = UDim2.new(1, -20, 0, 16)
                DLbl.Position = UDim2.new(0, 10, 0, 22)
                DLbl.BackgroundTransparency = 1
                DLbl.Font = Enum.Font.Gotham
                DLbl.TextSize = 10
                DLbl.TextColor3 = Color3.fromRGB(140, 150, 175)
                DLbl.TextXAlignment = Enum.TextXAlignment.Left
                DLbl.Text = lDesc
            end
        end

        return TabObj
    end

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == ToggleKey then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    return WindowObj
end

local KeyAvatarURL = (getgenv and getgenv().KeyAvatar) or ("rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150")

local Window = Library:Window({
    Profile = {
        Username = getgenv().KeyUsername or LocalPlayer.DisplayName,
        Email = "UID: " .. tostring(LocalPlayer.UserId),
        AvatarUrl = KeyAvatarURL
    },
    Title = "TWD V1 Hub",
    Desc = "Zombie Apocalypse All-in-One",
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

local MainTab = Window:Tab({ Title = "Main / Farm", Icon = "crosshair" })
local CombatTab = Window:Tab({ Title = "Combat & Guns", Icon = "shield" })
local VisualsTab = Window:Tab({ Title = "Visuals (ESP)", Icon = "eye" })
local PlayerTab = Window:Tab({ Title = "Player & Fly", Icon = "user" })
local UtilityTab = Window:Tab({ Title = "Utilities", Icon = "settings" })
local SecurityTab = Window:Tab({ Title = "Anti-Cheat", Icon = "lock" })

-- 1. MAIN TAB
MainTab:Section({ Title = "Auto Farm Zombies" })

MainTab:Toggle({
    Title = "Auto Farm Zombies",
    Desc = "วาร์ปลอยตัวตี/ยิงซอมบี้อัตโนมัติ",
    Value = State.AutoFarm,
    Callback = function(val)
        State.AutoFarm = val
        if not val then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Velocity = Vector3.zero end
        end
    end
})

MainTab:Dropdown({
    Title = "Farm Mode",
    Desc = "รูปแบบตำแหน่งการฟาร์ม",
    List = { "Float Above", "Behind" },
    Default = State.FarmMode,
    Callback = function(val)
        State.FarmMode = val
    end
})

MainTab:Slider({
    Title = "Farm Distance (Studs)",
    Desc = "ระยะห่างความสูง/ความปลอดภัยจากตัวซอมบี้",
    Min = 4,
    Max = 25,
    Default = State.FarmDistance,
    Callback = function(val)
        State.FarmDistance = val
    end
})

MainTab:Toggle({
    Title = "Auto Attack / Shoot",
    Desc = "สั่งโจมตี/ยิงปืนอัตโนมัติระหว่างฟาร์ม",
    Value = State.AutoAttack,
    Callback = function(val)
        State.AutoAttack = val
    end
})

MainTab:Section({ Title = "Kill Aura (รอบตัว)" })

MainTab:Toggle({
    Title = "Kill Aura",
    Desc = "โจมตีซอมบี้ที่เข้ามารอบตัวอัตโนมัติ",
    Value = State.KillAura,
    Callback = function(val)
        State.KillAura = val
    end
})

MainTab:Slider({
    Title = "Kill Aura Radius",
    Desc = "รัศมีระยะโจมตีรอบตัว",
    Min = 5,
    Max = 50,
    Default = State.KillAuraRadius,
    Callback = function(val)
        State.KillAuraRadius = val
    end
})

-- 2. COMBAT TAB
CombatTab:Section({ Title = "Silent Aim & Targeting" })

CombatTab:Toggle({
    Title = "Silent Aim",
    Desc = "กระสุนเข้าเป้าหัวซอมบี้อัตโนมัติ",
    Value = State.SilentAim,
    Callback = function(val)
        State.SilentAim = val
    end
})

CombatTab:Dropdown({
    Title = "Target Hitbox",
    Desc = "ตำแหน่งที่จะเล็งยิง",
    List = { "Head", "HumanoidRootPart" },
    Default = State.AimTargetPart,
    Callback = function(val)
        State.AimTargetPart = val
    end
})

CombatTab:Slider({
    Title = "Silent Aim FOV",
    Desc = "ขนาดวงกลมระยะเล็ง",
    Min = 30,
    Max = 500,
    Default = State.SilentAimFOV,
    Callback = function(val)
        State.SilentAimFOV = val
        if fovCircle then fovCircle.Radius = val end
    end
})

CombatTab:Toggle({
    Title = "Show FOV Circle",
    Desc = "แสดงวงกลมเล็ง FOV บนหน้าจอ",
    Value = State.ShowFOV,
    Callback = function(val)
        State.ShowFOV = val
    end
})

CombatTab:Toggle({
    Title = "Wall Check",
    Desc = "เล็งเฉพาะซอมบี้ที่ไม่ติดกำแพงบัง",
    Value = State.WallCheck,
    Callback = function(val)
        State.WallCheck = val
    end
})

CombatTab:Section({ Title = "Gun Modifications" })

CombatTab:Button({
    Title = "Fast Fire Rate / Gun Mod",
    Desc = "ปรับแต่งปืนทั้งหมดในกระเป๋า (ความเร็ว/กระสุน)",
    Callback = function()
        pcall(function()
            for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if item:IsA("Tool") then
                    for _, mod in ipairs(item:GetDescendants()) do
                        if mod:IsA("ModuleScript") and (mod.Name:lower():find("setting") or mod.Name:lower():find("config") or mod.Name:lower():find("gun")) then
                            local data = require(mod)
                            if type(data) == "table" then
                                if data.FireRate then data.FireRate = 0.02 end
                                if data.Auto ~= nil then data.Auto = true end
                                if data.Recoil then data.Recoil = 0 end
                                if data.Spread then data.Spread = 0 end
                                if data.MaxAmmo then data.MaxAmmo = 9999 end
                                if data.Ammo then data.Ammo = 9999 end
                            end
                        end
                    end
                end
            end
        end)
    end
})

-- 3. VISUALS TAB
VisualsTab:Section({ Title = "Zombie ESP" })

VisualsTab:Toggle({
    Title = "Zombie ESP (Highlight & Name)",
    Desc = "แสดงตำแหน่ง ชื่อ และเลือดของซอมบี้ทุกตัว",
    Value = State.ZombieESP,
    Callback = function(val)
        State.ZombieESP = val
        if not val then cleanZombieESP() end
    end
})

VisualsTab:Section({ Title = "World Lighting" })

VisualsTab:Toggle({
    Title = "FullBright (สว่างเต็มแมพ)",
    Desc = "เปิดไฟสว่างชัดเจนไม่มีมุมมืด",
    Value = State.FullBright,
    Callback = function(val)
        State.FullBright = val
        if val then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.GlobalShadows = true
        end
    end
})

VisualsTab:Toggle({
    Title = "Remove Fog (ลบหมอกควัน)",
    Desc = "ลบหมอกในเกมออกทั้งหมดเพื่อให้มองเห็นได้ไกล",
    Value = State.RemoveFog,
    Callback = function(val)
        State.RemoveFog = val
        if val then
            Lighting.FogStart = 0
            Lighting.FogEnd = 9e9
        end
    end
})

-- 4. PLAYER TAB
PlayerTab:Section({ Title = "Ghost Fly (บินทะลุกำแพง)" })

PlayerTab:Toggle({
    Title = "Ghost Fly",
    Desc = "บินอิสระทะลุกำแพงและสิ่งกีดขวาง (WASD + Space/Shift)",
    Value = State.GhostFly,
    Callback = function(val)
        State.GhostFly = val
        if val then
            stopGhostFly()
            startGhostFly()
        else
            stopGhostFly()
        end
    end
})

PlayerTab:Slider({
    Title = "Fly Speed",
    Desc = "ความเร็วในการบิน",
    Min = 10,
    Max = 200,
    Default = State.GhostFlySpeed,
    Callback = function(val)
        State.GhostFlySpeed = val
    end
})

PlayerTab:Section({ Title = "Movement & Speed" })

PlayerTab:Toggle({
    Title = "WalkSpeed Hack",
    Desc = "เพิ่มความเร็วในการเดิน",
    Value = State.SpeedHack,
    Callback = function(val)
        State.SpeedHack = val
        if not val and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
        end
    end
})

PlayerTab:Slider({
    Title = "WalkSpeed",
    Min = 16,
    Max = 150,
    Default = State.WalkSpeed,
    Callback = function(val)
        State.WalkSpeed = val
    end
})

PlayerTab:Toggle({
    Title = "Infinite Jump",
    Desc = "กระโดดได้ไม่จำกัดกลางอากาศ",
    Value = State.InfiniteJump,
    Callback = function(val)
        State.InfiniteJump = val
    end
})

PlayerTab:Toggle({
    Title = "Noclip (ทะลุกำแพงตลอดเวลา)",
    Desc = "เดินทะลุสิ่งก่อสร้างและกำแพง",
    Value = State.Noclip,
    Callback = function(val)
        State.Noclip = val
    end
})

-- 5. UTILITIES TAB
UtilityTab:Section({ Title = "Auto Features" })

UtilityTab:Toggle({
    Title = "Auto Collect Drops / Ammo / Crates",
    Desc = "เก็บไอเทม กระสุน กล่องยา เงิน ที่ตกพื้นอัตโนมัติ",
    Value = State.AutoCollectDrops,
    Callback = function(val)
        State.AutoCollectDrops = val
    end
})

UtilityTab:Button({
    Title = "Teleport to Safe High Ground",
    Desc = "วาร์ปขึ้นที่สูง ปลอดภัยจากการโดนซอมบี้ตบ",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 35, 0)
        end
    end
})

UtilityTab:Button({
    Title = "Teleport to Nearest Zombie",
    Desc = "วาร์ปไปหาซอมบี้ตัวที่ใกล้ที่สุด",
    Callback = function()
        local target = getClosestZombie()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if target and target:FindFirstChild("HumanoidRootPart") and hrp then
            hrp.CFrame = target.HumanoidRootPart.CFrame + Vector3.new(0, 5, -5)
        end
    end
})

-- 6. ANTI-CHEAT TAB
SecurityTab:Section({ Title = "Anti-Cheat Protection Status" })

SecurityTab:Button({
    Title = "Protected RemoteFunctions: " .. tostring(#AC_Bypass.ProtectedRemoteFunctions),
    Desc = "คลิกเพื่อดูรายการ RemoteFunction ที่ถูก Bypass",
    Callback = function()
        print("=== [AC Bypass Protected RemoteFunctions] ===")
        for i, name in ipairs(AC_Bypass.ProtectedRemoteFunctions) do
            print(string.format("[%d] %s (OnClientInvoke Hooked/Safe)", i, name))
        end
        print("============================================")
    end
})

SecurityTab:Button({
    Title = "Timeout Safeguard: " .. (AC_Bypass.TimeoutSet and "Active" or "Bypassed"),
    Desc = "ระบบป้องกันเซิร์ฟเวอร์ยิง Loop Crash เพื่อแบนหรือค้างเครื่อง",
    Callback = function() end
})

SecurityTab:Button({
    Title = "Unload Script (ปิดการทำงานทั้งหมด)",
    Desc = "ลบ UI และคืนค่าฟังก์ชันเดิมทั้งหมด",
    Callback = function()
        if env.ZombieApocalypse_Cleanup then
            env.ZombieApocalypse_Cleanup()
        end
        local cg = game:GetService("CoreGui")
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if cg and cg:FindFirstChild("Dummy Kawaii") then cg["Dummy Kawaii"]:Destroy() end
        if pg and pg:FindFirstChild("Dummy Kawaii") then pg["Dummy Kawaii"]:Destroy() end
    end
})

print("✅ TWD / Zombie Apocalypse Hub Loaded Successfully!")
