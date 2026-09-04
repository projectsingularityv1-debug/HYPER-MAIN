-- ==========================================================
-- Combined Script: GhostFly + TeamESP + AutoFarmMob
-- ไม่เกี่ยวข้องกับ MM2
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local env = (getgenv and getgenv()) or _G

-- ==========================================================
-- 1. GhostFly System
-- ==========================================================
env.GhostFlyEnabled = false
env.GhostFlySpeed = 50

local flyVelocity, flyGyro
local renderSteppedConn, steppedConn

local keysDown = { W = false, A = false, S = false, D = false, Space = false, LeftShift = false }

local function startGhostFly()
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if humanoid then humanoid.PlatformStand = true end
    
    local oldBV = hrp:FindFirstChild("GhostFlyVelocity")
    if oldBV then oldBV:Destroy() end
    local oldBG = hrp:FindFirstChild("GhostFlyGyro")
    if oldBG then oldBG:Destroy() end

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
    flyGyro.CFrame = camera.CFrame
    flyGyro.Parent = hrp
    
    renderSteppedConn = RunService.RenderStepped:Connect(function()
        if not env.GhostFlyEnabled then return end
        
        local moveDir = Vector3.zero
        if keysDown.W then moveDir = moveDir + camera.CFrame.LookVector end
        if keysDown.S then moveDir = moveDir - camera.CFrame.LookVector end
        if keysDown.A then moveDir = moveDir - camera.CFrame.RightVector end
        if keysDown.D then moveDir = moveDir + camera.CFrame.RightVector end
        
        local upDown = 0
        if keysDown.Space then upDown = upDown + 1 end
        if keysDown.LeftShift then upDown = upDown - 1 end
        moveDir = moveDir + Vector3.new(0, upDown, 0)
        
        if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
        
        if flyVelocity then flyVelocity.Velocity = moveDir * env.GhostFlySpeed end
        if flyGyro then flyGyro.CFrame = camera.CFrame end
    end)
    
    steppedConn = RunService.Stepped:Connect(function()
        if not env.GhostFlyEnabled then return end
        if player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function stopGhostFly()
    if renderSteppedConn then renderSteppedConn:Disconnect() renderSteppedConn = nil end
    if steppedConn then steppedConn:Disconnect() steppedConn = nil end
    
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bv = hrp:FindFirstChild("GhostFlyVelocity")
            if bv then bv:Destroy() end
            local bg = hrp:FindFirstChild("GhostFlyGyro")
            if bg then bg:Destroy() end
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
        end
    end
end

local function toggleGhostFly(state)
    env.GhostFlyEnabled = state
    if state then stopGhostFly() startGhostFly() else stopGhostFly() end
    print(state and "🟢 เปิด GhostFly" or "🔴 ปิด GhostFly")
end

-- ==========================================================
-- 2. Team ESP System
-- ==========================================================
env.TeamESP_Running = false
task.wait(0.1)
env.TeamESP_Running = true

if env.TeamESP_Folder then env.TeamESP_Folder:Destroy() end

local espFolder = Instance.new("Folder")
espFolder.Name = "MyTeamESP"
pcall(function() espFolder.Parent = CoreGui end)
if not espFolder.Parent then espFolder.Parent = player:WaitForChild("PlayerGui") end
env.TeamESP_Folder = espFolder

local espCache = {}

local function createESP(targetPlayer)
    if espCache[targetPlayer] then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = targetPlayer.Name .. "_ESP"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextScaled = false
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.Parent = billboard
    billboard.Parent = espFolder
    
    local highlight = Instance.new("Highlight")
    highlight.Name = targetPlayer.Name .. "_Highlight"
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    highlight.Parent = espFolder
    
    espCache[targetPlayer] = { Gui = billboard, Label = textLabel, Highlight = highlight }
end

task.spawn(function()
    while env.TeamESP_Running do
        for _, p in ipairs(Players:GetPlayers()) do if not espCache[p] then createESP(p) end end
        for p, data in pairs(espCache) do
            if not p or not p.Parent then
                if data.Gui then data.Gui:Destroy() end
                if data.Highlight then data.Highlight:Destroy() end
                espCache[p] = nil
            end
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while env.TeamESP_Running do
        for targetPlayer, data in pairs(espCache) do
            local char = targetPlayer.Character
            local head = char and char:FindFirstChild("Head")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if head and hrp and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                data.Gui.Adornee = head
                data.Gui.Enabled = true
                
                local teamName = targetPlayer.Team and targetPlayer.Team.Name or "No Team"
                local teamColor = targetPlayer.Team and targetPlayer.TeamColor.Color or Color3.new(1, 1, 1)
                
                local distance = 0
                local myChar = player.Character
                if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                    distance = math.floor((myChar.HumanoidRootPart.Position - hrp.Position).Magnitude)
                end
                
                data.Label.Text = string.format("[%s]\n%s\n[%d m]", teamName, targetPlayer.Name, distance)
                data.Label.TextColor3 = teamColor
                
                data.Highlight.Adornee = char
                data.Highlight.FillColor = teamColor
                data.Highlight.OutlineColor = teamColor
                data.Highlight.Enabled = true
            else
                data.Gui.Enabled = false
                data.Gui.Adornee = nil
                data.Highlight.Enabled = false
                data.Highlight.Adornee = nil
            end
        end
        task.wait()
    end
end)
print("✅ ระบบ Team ESP ทำงานเรียบร้อยแล้ว!")

-- ==========================================================
-- 3. Auto Farm Mob System
-- ==========================================================
if env.AutoFarmMobSystem then
    if env.AutoFarmMobSystem.NoclipConnection then env.AutoFarmMobSystem.NoclipConnection:Disconnect() end
    if env.AutoFarmMobSystem.CurrentTween then env.AutoFarmMobSystem.CurrentTween:Cancel() end
    env.AutoFarmMobSystem.Running = false
end

env.AutoFarmMobSystem = { Running = false, NoclipConnection = nil, CurrentTween = nil }
local farmSystem = env.AutoFarmMobSystem
local FLY_SPEED = 100

local function getTargetMonster()
    local worlds = Workspace:FindFirstChild("Worlds")
    if worlds then
        local world = worlds:FindFirstChild("1")
        if world then
            local enemies = world:FindFirstChild("Enemies")
            if enemies then
                for _, enemy in ipairs(enemies:GetChildren()) do
                    local humanoid = enemy:FindFirstChild("Humanoid")
                    local hrp = enemy:FindFirstChild("HumanoidRootPart")
                    if humanoid and humanoid.Health > 0 and hrp then return hrp end
                end
            end
            local enemySpawns = world:FindFirstChild("EnemySpawns")
            if enemySpawns then
                for _, spawnPart in ipairs(enemySpawns:GetChildren()) do
                    if spawnPart:IsA("BasePart") then return spawnPart end
                end
            end
        end
    end
    return nil
end

local function toggleAutoFarm(state)
    farmSystem.Running = state
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if farmSystem.Running then
        print("🟢 เปิดระบบ Auto Farm")
        if not farmSystem.NoclipConnection then
            farmSystem.NoclipConnection = RunService.Stepped:Connect(function()
                if player.Character then
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end)
        end
        
        task.spawn(function()
            while farmSystem.Running do
                char = player.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then task.wait(1) continue end
                hrp = char.HumanoidRootPart
                hrp.Anchored = true
                
                -- ออโต้รับเควส "Kill 4 Soldiers"
                pcall(function()
                    game:GetService("ReplicatedStorage").Chest.Remotes.Functions.Quest:InvokeServer("take", "Kill 4 Soldiers")
                end)
                
                local target = getTargetMonster()
                if target then
                    local distance = (hrp.Position - target.Position).Magnitude
                    local tweenInfo = TweenInfo.new(distance / FLY_SPEED, Enum.EasingStyle.Linear)
                    local goalPos = target.Position + Vector3.new(0, 0, 3)
                    
                    farmSystem.CurrentTween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(goalPos, target.Position)})
                    farmSystem.CurrentTween:Play()
                    
                    while farmSystem.Running and target and target.Parent do
                        local currentDist = (hrp.Position - target.Position).Magnitude
                        local enemyHumanoid = target.Parent:FindFirstChild("Humanoid")
                        
                        if currentDist < 10 then
                            if farmSystem.CurrentTween then farmSystem.CurrentTween:Cancel() end
                            hrp.CFrame = CFrame.new(hrp.Position, target.Position)
                            
                            local VirtualUser = game:GetService("VirtualUser")
                            while farmSystem.Running and target and target.Parent do
                                hrp.CFrame = CFrame.new(hrp.Position, target.Position)
                                
                                pcall(function()
                                    if player.Backpack then
                                        for _, tool in ipairs(player.Backpack:GetChildren()) do
                                            if tool:IsA("Tool") then char.Humanoid:EquipTool(tool) end
                                        end
                                    end
                                end)
                                
                                pcall(function()
                                    for _, v in ipairs(char:GetChildren()) do
                                        if v:IsA("Tool") then v:Activate() end
                                    end
                                end)
                                
                                if mouse1click then pcall(mouse1click) end
                                
                                pcall(function()
                                    VirtualUser:CaptureController()
                                    VirtualUser:ClickButton1(Vector2.new(500, 500))
                                end)
                                
                                pcall(function()
                                    local Event = game:GetService("Players").LocalPlayer:FindFirstChild("startevent")
                                    if Event then Event:FireServer("target", target) end
                                end)
                                
                                -- สั่งใช้สกิลตี (M1)
                                pcall(function()
                                    game:GetService("ReplicatedStorage").Chest.Remotes.Functions.SkillAction:InvokeServer("FS_None_M1")
                                end)
                                
                                if enemyHumanoid and enemyHumanoid.Health <= 0 then break end
                                if (hrp.Position - target.Position).Magnitude > 15 then break end
                                task.wait(0.1)
                            end
                            break
                        end
                        task.wait(0.1)
                    end
                else
                    task.wait(1)
                end
            end
        end)
    else
        print("🔴 ปิดระบบ Auto Farm")
        if farmSystem.CurrentTween then farmSystem.CurrentTween:Cancel() farmSystem.CurrentTween = nil end
        if farmSystem.NoclipConnection then farmSystem.NoclipConnection:Disconnect() farmSystem.NoclipConnection = nil end
        if hrp then hrp.Anchored = false end
    end
end

-- ==========================================================
-- Input Keybinds (การกดปุ่ม)
-- X = Toggle GhostFly
-- Z = Toggle AutoFarmMob
-- ==========================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    -- GhostFly keys
    if input.KeyCode == Enum.KeyCode.W then keysDown.W = true end
    if input.KeyCode == Enum.KeyCode.A then keysDown.A = true end
    if input.KeyCode == Enum.KeyCode.S then keysDown.S = true end
    if input.KeyCode == Enum.KeyCode.D then keysDown.D = true end
    if input.KeyCode == Enum.KeyCode.Space then keysDown.Space = true end
    if input.KeyCode == Enum.KeyCode.LeftShift then keysDown.LeftShift = true end
    
    -- Toggles
    if input.KeyCode == Enum.KeyCode.X then
        toggleGhostFly(not env.GhostFlyEnabled)
    elseif input.KeyCode == Enum.KeyCode.Z then
        toggleAutoFarm(not farmSystem.Running)
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.W then keysDown.W = false end
    if input.KeyCode == Enum.KeyCode.A then keysDown.A = false end
    if input.KeyCode == Enum.KeyCode.S then keysDown.S = false end
    if input.KeyCode == Enum.KeyCode.D then keysDown.D = false end
    if input.KeyCode == Enum.KeyCode.Space then keysDown.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then keysDown.LeftShift = false end
end)

print("✅ โหลด Combined Script สำเร็จแล้ว! (กด X: บินผี, กด Z: ออโต้ฟาร์ม)")
