-- ==============================================================================
--  HYPER HUB - Basketball Hub (Native Standalone Clean UI Edition)
--  Clean Modern UI (No Emojis, Standardized Typography)
--  Created by K2NTA ST | Project Singularity
-- ==============================================================================

local _cloneref = (cloneref or function(...) return ... end)
local function getService(name)
    local ok, s = pcall(function() return game:GetService(name) end)
    return ok and _cloneref(s) or nil
end

local Players = getService("Players")
local ReplicatedStorage = getService("ReplicatedStorage")
local RunService = getService("RunService")
local UserInputService = getService("UserInputService")
local TweenService = getService("TweenService")
local CoreGui = getService("CoreGui")
local VirtualUser = getService("VirtualUser")
local VirtualInputManager = getService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- Prevent multiple script executions (Anti-Overlap)
local env = (getgenv and getgenv()) or _G
local runId = tick()
env.BasketballHYPER_RunID = runId

if env.BasketballHYPER_Cleanup then
    pcall(env.BasketballHYPER_Cleanup)
end

pcall(function()
    for _, v in ipairs(CoreGui:GetChildren()) do
        if v.Name == "SingularityHoopsHub" then v:Destroy() end
    end
    if LocalPlayer:FindFirstChild("PlayerGui") then
        for _, v in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            if v.Name == "SingularityHoopsHub" then v:Destroy() end
        end
    end
end)

-- 1. Safely retrieve game controllers with dynamic reload support (Dynamic Safe Loader) --
local Knit = nil
local function initKnit()
    if not Knit then
        pcall(function()
            if ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Knit") then
                local kClient = ReplicatedStorage.Packages.Knit:FindFirstChild("KnitClient") or ReplicatedStorage.Packages.Knit
                Knit = require(kClient)
            end
        end)
    end
    return Knit
end
initKnit()

local function getSafeController(name)
    local ctrl = nil
    initKnit()
    if Knit and Knit.GetController then
        pcall(function() ctrl = Knit.GetController(name) end)
    end
    if not ctrl and ReplicatedStorage:FindFirstChild("Controllers") then
        local mod = ReplicatedStorage.Controllers:FindFirstChild(name)
        if mod and mod:IsA("ModuleScript") then
            pcall(function() ctrl = require(mod) end)
        end
    end
    return ctrl
end

local BallController      = getSafeController("BallController")
local DefenseController   = getSafeController("DefenseController")
local AbilityController   = getSafeController("AbilityController")
local AwakeningController = getSafeController("AwakeningController")
local MovementController  = getSafeController("MovementController")
local MatchController     = getSafeController("MatchController")
local CourtController     = getSafeController("CourtController")

-- 
local Config = {
    AutoGetBall = false,
    GetBallMode = "TP",        -- "TP" (Instant Teleport) or "Fly" (Fly Mode)
    FlySpeed = 55,
    BallESP = false,
    InstantShoot = true,       -- Instant Shoot (Simulate click + 100% hoop score teleport)
    AutoShoot = false,
    AutoPerfectShoot = true,   -- 100% score from anywhere (Teleport above rim and drop)
    DoubleClickShoot = true,   -- Simulate double-click for shooting
    InstantShootKey = "E",     -- Instant shoot hotkey [E] or [F]
    ShootMode = "Instant",     -- "Instant" (Teleport above hoop and drop)
    ClickHoldTime = 0.12,      -- Click charge duration in seconds
    TeleportHeight = 9.0,      -- Height above hoop rim in studs
    AutoFaceNet = false,       -- Automatically face the hoop when shooting
    AutoBlock = false,
    AutoBlockRange = 14,
    AutoSteal = false,
    AutoStealRange = 15,
    StealCooldown = 0.25,
    BlockCooldown = 0.6,
    SpeedEnabled = false,
    CustomSpeed = 28,
    SpeedMethod = "Hybrid",    -- "Hybrid", "CFrame", "Velocity", "WalkSpeed"
    InfJump = false,
    Noclip = false,
    AntiAFK = true
}

-- 2. Team Check System -----------------------------------------
local function isTeammate(player)
    if not player or player == LocalPlayer then return true end
    if LocalPlayer.Team and player.Team then return LocalPlayer.Team == player.Team end
    if LocalPlayer.TeamColor and player.TeamColor then return LocalPlayer.TeamColor == player.TeamColor end
    if LocalPlayer.Character and player.Character then
        local myTeam = LocalPlayer.Character:GetAttribute("Team") or LocalPlayer:GetAttribute("Team")
        local targetTeam = player.Character:GetAttribute("Team") or player:GetAttribute("Team")
        if myTeam and targetTeam and myTeam == targetTeam then return true end
    end
    return false
end

-- 3. Prevent game WalkSpeed reset (Metamethod Hook) ------------
pcall(function()
    if hookmetamethod and checkcaller and newcclosure then
        local oldNewIndex
        oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, prop, val)
            if not checkcaller() and Config.SpeedEnabled and tostring(prop) == "WalkSpeed" and self:IsA("Humanoid") then
                local char = LocalPlayer.Character
                if char and self:IsDescendantOf(char) then
                    return oldNewIndex(self, prop, Config.CustomSpeed)
                end
            end
            return oldNewIndex(self, prop, val)
        end))
    end
end)

-- 4. Game Loops & Multi-Layer Speed ----------------------------

-- Movement Tab
local renderConn = RunService.RenderStepped:Connect(function(dt)
    if env.BasketballHYPER_RunID ~= runId then return end
    local char = LocalPlayer.Character
    if not char then return end

    if Config.SpeedEnabled then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if hum and hrp then
            hum.WalkSpeed = Config.CustomSpeed

            if hum.MoveDirection.Magnitude > 0 then
                local moveDir = hum.MoveDirection
                local extraSpeed = math.max(0, Config.CustomSpeed - 16)

                if Config.SpeedMethod == "CFrame" then
                    hrp.CFrame = hrp.CFrame + (moveDir * (extraSpeed * dt))
                elseif Config.SpeedMethod == "Velocity" then
                    local curY = (hrp.AssemblyLinearVelocity and hrp.AssemblyLinearVelocity.Y) or hrp.Velocity.Y
                    local targetVel = Vector3.new(moveDir.X * Config.CustomSpeed, curY, moveDir.Z * Config.CustomSpeed)
                    if hrp.AssemblyLinearVelocity then
                        hrp.AssemblyLinearVelocity = targetVel
                    else
                        hrp.Velocity = targetVel
                    end
                elseif Config.SpeedMethod == "Hybrid" then
                    hrp.CFrame = hrp.CFrame + (moveDir * (extraSpeed * dt * 0.4))
                    local curY = (hrp.AssemblyLinearVelocity and hrp.AssemblyLinearVelocity.Y) or hrp.Velocity.Y
                    local targetVel = Vector3.new(moveDir.X * (Config.CustomSpeed * 0.8), curY, moveDir.Z * (Config.CustomSpeed * 0.8))
                    if hrp.AssemblyLinearVelocity then
                        hrp.AssemblyLinearVelocity = targetVel
                    else
                        hrp.Velocity = targetVel
                    end
                end
            end
        end

        if MovementController then
            pcall(function()
                if MovementController.SetSpeed then MovementController:SetSpeed(Config.CustomSpeed) end
                if MovementController.Speed then MovementController.Speed = Config.CustomSpeed end
                if MovementController.SprintSpeed then MovementController.SprintSpeed = Config.CustomSpeed end
                if MovementController.BaseSpeed then MovementController.BaseSpeed = Config.CustomSpeed end
            end)
        end
    end
end)

-- 4.2 Noclip (Stepped)
local steppedConn = RunService.Stepped:Connect(function()
    if env.BasketballHYPER_RunID ~= runId then return end
    local char = LocalPlayer.Character
    if not char then return end

    if Config.Noclip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    if Config.SpeedEnabled then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= Config.CustomSpeed then
            hum.WalkSpeed = Config.CustomSpeed
        end
    end
end)

-- 4.3 Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Config.InfJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- 5. PERFECT SHOOT & BALL TRAJECTORY (100% Swish Score) --------
local function isAttachedToPlayer(item)
    if not item or not item.Parent then return true end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and item:IsDescendantOf(p.Character) then
            return true
        end
    end
    return false
end

-- Valid ball filter (excludes map decorations, ball racks, anchored parts)
local function isValidGameBall(part)
    if not part or not part:IsA("BasePart") or not part.Parent then return false end
    if isAttachedToPlayer(part) then return false end
    if part.Anchored then return false end -- Active basketball must not be anchored

    local name = part.Name:lower()
    local pName = part.Parent.Name:lower()

    -- 
    if name:find("spawn") or name:find("rack") or name:find("stand") or name:find("holder") or name:find("gui") or name:find("decal") or name:find("light") or name:find("shop") or name:find("display") or name:find("particle") or name:find("icon") or name:find("ring") or name:find("net") or name:find("rim") or name:find("hoop") or name:find("board") or name:find("post") or name:find("pole") or name:find("court") or name:find("floor") or name:find("ground") then
        return false
    end
    if pName:find("rack") or pName:find("stand") or pName:find("shop") or pName:find("display") or pName:find("hoop") or pName:find("court") then
        return false
    end

    -- Valid basketball dimensions (0.8 to 4.5 studs)
    local sz = part.Size
    if sz.X < 0.5 or sz.X > 5.0 or sz.Y < 0.5 or sz.Y > 5.0 or sz.Z < 0.5 or sz.Z > 5.0 then
        return false
    end

    return true
end

local function findFreeBasketball()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position

    -- 1.  BallController  ( 100%)
    if BallController then
        local b = BallController.Ball or BallController.CurrentBall or BallController._ball or BallController.BallInstance
        if b and typeof(b) == "Instance" and b.Parent then
            local p = b:IsA("BasePart") and b or b:FindFirstChildWhichIsA("BasePart")
            if p and isValidGameBall(p) then return p end
        end
        if BallController.GetBall then
            local success, b2 = pcall(function() return BallController:GetBall() end)
            if success and b2 and typeof(b2) == "Instance" and b2.Parent then
                local p2 = b2:IsA("BasePart") and b2 or b2:FindFirstChildWhichIsA("BasePart")
                if p2 and isValidGameBall(p2) then return p2 end
            end
        end
    end

    -- 2.  Workspace  ( 35 studs)
    local candidateBall = nil
    local minDistance = 35

    for _, folderName in ipairs({"Balls", "GameBalls", "Gameplay", "Court", "Visuals", "Debris"}) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                if isValidGameBall(item) and item.Name:lower():find("ball") then
                    if myPos then
                        local dist = (myPos - item.Position).Magnitude
                        if dist < minDistance then
                            minDistance = dist
                            candidateBall = item
                        end
                    else
                        return item
                    end
                end
            end
        end
    end

    if candidateBall then return candidateBall end

    -- 3.  Workspace 
    for _, item in ipairs(workspace:GetChildren()) do
        if isValidGameBall(item) and item.Name:lower():find("ball") then
            if myPos then
                local dist = (myPos - item.Position).Magnitude
                if dist < minDistance then
                    minDistance = dist
                    candidateBall = item
                end
            else
                return item
            end
        end
    end

    if candidateBall then return candidateBall end

    -- 4.  Descendants ()
    for _, item in ipairs(workspace:GetDescendants()) do
        if isValidGameBall(item) then
            local n = item.Name:lower()
            local pn = item.Parent.Name:lower()
            if (n:find("ball") or pn:find("ball")) then
                if myPos then
                    local dist = (myPos - item.Position).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        candidateBall = item
                    end
                else
                    return item
                end
            end
        end
    end

    return candidateBall
end

local function findBasketball()
    -- Find ball including possessed/held by players
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("BasePart") and item.Name:lower():find("ball") then return item end
            if item:IsA("Tool") or item:IsA("Model") then
                local p = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
                if p and (item.Name:lower():find("ball") or p.Name:lower():find("ball")) then return p end
            end
        end
    end
    return findFreeBasketball()
end

local hookedShoots = {}
local guideBallToHoop
local getNearestHoop

local function refreshAndHookControllers()
    BallController      = getSafeController("BallController") or BallController
    DefenseController   = getSafeController("DefenseController") or DefenseController
    AbilityController   = getSafeController("AbilityController") or AbilityController
    AwakeningController = getSafeController("AwakeningController") or AwakeningController
    MovementController  = getSafeController("MovementController") or MovementController
    MatchController     = getSafeController("MatchController") or MatchController
    CourtController     = getSafeController("CourtController") or CourtController
end

local function getExactHoopCenter(targetHoop)
    if not targetHoop or not targetHoop.Parent then return nil end
    local p = targetHoop.Parent
    if p and (p:IsA("Model") or p:IsA("Folder")) then
        for _, exactName in ipairs({"Swish", "swish", "Score", "score", "Trigger", "trigger", "Net", "net", "Rim", "rim", "Ring", "ring"}) do
            local found = p:FindFirstChild(exactName, true)
            if found and found:IsA("BasePart") then
                return found.Position
            end
        end
    end
    return targetHoop.Position
end

getNearestHoop = function()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    refreshAndHookControllers()

-- 1. Safely retrieve game controllers with dynamic reload support (Dynamic Safe Loader) --
    if BallController then
        if BallController.GetGoal then
            local success, g = pcall(function() return BallController:GetGoal() end)
            if success and g and g.Parent then
                local part = g:FindFirstChild("Swish", true) or g:FindFirstChild("Score", true) or g:FindFirstChild("Trigger", true) or g:FindFirstChild("Net", true) or g:FindFirstChild("Rim", true) or g:FindFirstChild("Ring", true) or (g:IsA("BasePart") and g) or g:FindFirstChildWhichIsA("BasePart")
                if part then return part end
            end
        end
        if BallController.Goal and typeof(BallController.Goal) == "Instance" and BallController.Goal.Parent then
            local part = BallController.Goal:FindFirstChild("Swish", true) or BallController.Goal:FindFirstChild("Score", true) or BallController.Goal:FindFirstChild("Trigger", true) or BallController.Goal:FindFirstChild("Net", true) or BallController.Goal:FindFirstChild("Rim", true) or BallController.Goal:FindFirstChild("Ring", true) or (BallController.Goal:IsA("BasePart") and BallController.Goal) or BallController.Goal:FindFirstChildWhichIsA("BasePart")
            if part then return part end
        end
    end

    if MatchController and MatchController.GetAttackingGoal then
        local success, g = pcall(function() return MatchController:GetAttackingGoal() end)
        if success and g and g.Parent then
            local part = g:FindFirstChild("Swish", true) or g:FindFirstChild("Score", true) or g:FindFirstChild("Trigger", true) or g:FindFirstChild("Net", true) or g:FindFirstChild("Rim", true) or g:FindFirstChild("Ring", true) or (g:IsA("BasePart") and g) or g:FindFirstChildWhichIsA("BasePart")
            if part then return part end
        end
    end

-- Exclude backboard, poles, or support structures
    local closestHoop = nil
    local minDistance = math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Parent then
            local name = obj.Name:lower()
-- Exclude backboard, poles, or support structures
            if not name:find("backboard") and not name:find("board") and not name:find("pole") and not name:find("stand") and not name:find("support") and not name:find("post") and not name:find("glass") then
                if name:find("swish") or name:find("score") or name:find("trigger") or name == "rim" or name:find("rim") or name == "net" or name:find("net") or name == "ring" or name:find("ring") then
                    if obj.Position.Y > 4 then
                        local dist = (myRoot.Position - obj.Position).Magnitude
                        if dist < minDistance then
                            minDistance = dist
                            closestHoop = obj
                        end
                    end
                end
            end
        end
    end

    if closestHoop then return closestHoop end

    --  ()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Parent then
            local name = obj.Name:lower()
            if not name:find("backboard") and not name:find("board") and not name:find("pole") and not name:find("stand") then
                if name:find("hoop") or name:find("goal") or name:find("basket") then
                    if obj.Position.Y > 4 then
                        local dist = (myRoot.Position - obj.Position).Magnitude
                        if dist < minDistance then
                            minDistance = dist
                            closestHoop = obj
                        end
                    end
                end
            end
        end
    end

    return closestHoop
end

local lastLocalShootTime = 0
local isGuidingBall = false

-- :  100%
-- Ball Trajectory Guide: Teleport released ball above rim and drop through net 100%
guideBallToHoop = function(targetHoop)
    if not (Config.InstantShoot or Config.AutoPerfectShoot) then return end
    targetHoop = targetHoop or getNearestHoop()
    if not targetHoop or not targetHoop.Parent then return end

    if isGuidingBall and (tick() - lastLocalShootTime < 1.0) then return end
    isGuidingBall = true
    lastLocalShootTime = tick()

    task.spawn(function()
        local ball = nil
        --  Free Ball  Workspace ( 2.5 )
        for _ = 1, 150 do
            ball = findFreeBasketball()
            if ball and ball.Parent and not isAttachedToPlayer(ball) then break end
            task.wait(0.015)
        end

        if ball and targetHoop and targetHoop.Parent then
            local rimPos = getExactHoopCenter(targetHoop)
            local spawnHeight = Config.TeleportHeight or 9.0

            --  CanCollide  100% 
            local oldCanCollide = ball.CanCollide
            pcall(function() ball.CanCollide = false end)

            -- 1. Teleport ball directly above hoop center
            local aboveRimPos = Vector3.new(rimPos.X, rimPos.Y + spawnHeight, rimPos.Z)
            ball.CFrame = CFrame.new(aboveRimPos)

            local downVelocity = Vector3.new(0, -35, 0)
            if ball.AssemblyLinearVelocity then
                ball.AssemblyLinearVelocity = downVelocity
                ball.AssemblyAngularVelocity = Vector3.zero
            else
                ball.Velocity = downVelocity
                ball.RotVelocity = Vector3.zero
            end

            -- 2. Step drop vertically through net center
            local dropYOffsets = {
                spawnHeight * 0.75,
                spawnHeight * 0.50,
                spawnHeight * 0.25,
                2.0,   -- Above rim
                0.8,   -- At rim level
                0.0,   -- Hoop center
                -1.0,  -- Inside net
                -2.5   -- Below net exit
            }

            for _, yOff in ipairs(dropYOffsets) do
                if not ball or not ball.Parent or not targetHoop.Parent then break end

                --  X  Z  100% 
                ball.CFrame = CFrame.new(Vector3.new(rimPos.X, rimPos.Y + yOff, rimPos.Z))

                if ball.AssemblyLinearVelocity then
                    ball.AssemblyLinearVelocity = downVelocity
                    ball.AssemblyAngularVelocity = Vector3.zero
                else
                    ball.Velocity = downVelocity
                    ball.RotVelocity = Vector3.zero
                end

                task.wait(0.018)
            end

            --  CanCollide 
            task.wait(0.1)
            pcall(function() ball.CanCollide = oldCanCollide end)
        end
        isGuidingBall = false
    end)
end

--  BallController.Shoot 
refreshAndHookControllers()

-- Shoot animation detection & re-bind on round reset
local function bindCharacter(char)
    if not char then return end
    isGuidingBall = false
    lastLocalShootTime = 0
    refreshAndHookControllers()

    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        local animator = hum:WaitForChild("Animator", 3) or hum
        if animator then
            animator.AnimationPlayed:Connect(function(track)
                if not (Config.InstantShoot or Config.AutoPerfectShoot) then return end
                local anim = track.Animation
                local animName = (anim and anim.Name:lower()) or ""
                if animName:find("shoot") or animName:find("shot") or animName:find("jumpshot") or animName:find("fadeaway") or animName:find("stepback") or animName:find("pullup") then
                    task.spawn(function()
                        task.wait(0.04)
                        guideBallToHoop()
                    end)
                end
            end)
        end
    end
end

if LocalPlayer.Character then
    task.spawn(function() bindCharacter(LocalPlayer.Character) end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.spawn(function()
        task.wait(0.15)
        bindCharacter(char)
        if Config.BallESP then
            pcall(updateBallESP)
        end
    end)
end)

-- Continuous shoot detection and controller refresh listener
task.spawn(function()
    local hadBall = false
    local refreshCounter = 0
    while true do
        task.wait(0.02)
        if env.BasketballHYPER_RunID ~= runId then break end

        refreshCounter = refreshCounter + 1
        if refreshCounter >= 50 then
            refreshCounter = 0
            refreshAndHookControllers()
        end

        local hasBall = false
        if BallController and BallController.LocalPlayerPossessesBall then
            pcall(function() hasBall = BallController:LocalPlayerPossessesBall() end)
        end

        if hadBall and not hasBall and (Config.InstantShoot or Config.AutoPerfectShoot) then
            task.spawn(function()
                guideBallToHoop()
            end)
        end
        hadBall = hasBall
    end
end)

local function simulateMouseClick(holdTime)
    holdTime = holdTime or Config.ClickHoldTime or 0.12
    local mousePos = Vector2.new(400, 300)
    pcall(function()
        if workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize then
            local vs = workspace.CurrentCamera.ViewportSize
            mousePos = Vector2.new(vs.X / 2, vs.Y / 2)
        elseif UserInputService and UserInputService.GetMouseLocation then
            mousePos = UserInputService:GetMouseLocation()
        end
    end)

    -- Step 1: Send mouse button down event
    pcall(function()
        if VirtualInputManager then
            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
        end
    end)
    pcall(function()
        if mouse1press then
            mouse1press()
        end
    end)
    pcall(function()
        if VirtualUser then
            VirtualUser:CaptureController()
            VirtualUser:Button1Down(Vector2.new(mousePos.X, mousePos.Y))
        end
    end)

    -- Step 2: Hold charge duration
    task.wait(holdTime)

    -- Step 3: Send mouse button up event
    pcall(function()
        if VirtualInputManager then
            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
        end
    end)
    pcall(function()
        if mouse1release then
            mouse1release()
        elseif mouse1click then
            mouse1click()
        end
    end)
    pcall(function()
        if VirtualUser then
            VirtualUser:Button1Up(Vector2.new(mousePos.X, mousePos.Y))
        end
    end)
end

local function executePerfectShot()
    local hoop = getNearestHoop()
    lastLocalShootTime = tick()

    -- 1. Face the hoop if AutoFaceNet is enabled
    if Config.AutoFaceNet and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myRoot = LocalPlayer.Character.HumanoidRootPart
        if AbilityController and AbilityController.LookingAtNet then
            pcall(function() AbilityController:LookingAtNet() end)
        end
        if hoop then
            myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(hoop.Position.X, myRoot.Position.Y, hoop.Position.Z))
        end
    end

    -- 2. 
    local hold = Config.ClickHoldTime or 0.12
    simulateMouseClick(hold)
    if Config.DoubleClickShoot then
        task.wait(0.2)
        simulateMouseClick(hold)
    end

    -- 3. Trigger ball trajectory guide after release
    if Config.AutoPerfectShoot then
        guideBallToHoop(hoop)
    end
end

-- 5.0 Auto Shoot on Possession
task.spawn(function()
    local isAutoShootingPossess = false
    while true do
        task.wait(0.05)
        if env.BasketballHYPER_RunID ~= runId then break end
        if Config.AutoShoot and not isAutoShootingPossess then
            local hasBall = false
            if BallController and BallController.LocalPlayerPossessesBall then
                pcall(function() hasBall = BallController:LocalPlayerPossessesBall() end)
            end
            if hasBall and (tick() - lastLocalShootTime > 1.2) then
                isAutoShootingPossess = true
                task.wait(0.08)
                executePerfectShot()
                task.wait(0.8)
                isAutoShootingPossess = false
            end
        end
    end
end)

-- 5.1 Auto Get Ball (Collect free balls only)
task.spawn(function()
    while true do
        task.wait(0.03)
        if env.BasketballHYPER_RunID ~= runId then break end
        if Config.AutoGetBall and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                if tick() - lastLocalShootTime < 2.5 then return end

                local hasBall = BallController and BallController.LocalPlayerPossessesBall and BallController:LocalPlayerPossessesBall()
                if not hasBall then
                    local ballHolder = BallController and BallController.GetPlayerPossessingBall and BallController:GetPlayerPossessingBall()
                    
                    local isShootingState = false
                    if BallController then
                        if BallController.BallIFrameIsActive and BallController:BallIFrameIsActive() then
                            isShootingState = true
                        elseif BallController.BallTeamIFrameIsActive and BallController:BallTeamIFrameIsActive() then
                            isShootingState = true
                        elseif BallController.BallSpeedIsLessThan and not BallController:BallSpeedIsLessThan(35) then
                            isShootingState = true
                        end
                    end

                    if not ballHolder and not isShootingState then
                        local ballPos = nil
                        local ballObj = nil
                        if BallController and BallController.GetServerBallPosition then
                            ballPos = BallController:GetServerBallPosition()
                        end

                        if not ballPos or ballPos == Vector3.new(0, 0, 0) then
                            for _, item in pairs(workspace:GetChildren()) do
                                if item.Name:lower():find("ball") and item:IsA("BasePart") then
                                    ballPos = item.Position
                                    ballObj = item
                                    break
                                end
                            end
                        end

                        if ballObj and (ballObj.AssemblyLinearVelocity or ballObj.Velocity) then
                            local speed = (ballObj.AssemblyLinearVelocity or ballObj.Velocity).Magnitude
                            if speed > 35 then return end
                        end

                        if ballPos then
                            local myRoot = LocalPlayer.Character.HumanoidRootPart
                            local dist = (myRoot.Position - ballPos).Magnitude
                            if dist > 1.5 then
                                if Config.GetBallMode == "Fly" then
                                    local dir = (ballPos - myRoot.Position).Unit
                                    myRoot.Velocity = dir * Config.FlySpeed
                                    myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(ballPos.X, myRoot.Position.Y, ballPos.Z))
                                else
                                    myRoot.CFrame = CFrame.new(ballPos.X, ballPos.Y + 1.2, ballPos.Z)
                                    myRoot.Velocity = Vector3.new(0, 0, 0)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 5.2 Auto Steal
local lastStealTime = 0
task.spawn(function()
    while true do
        task.wait(0.05)
        if env.BasketballHYPER_RunID ~= runId then break end
        if Config.AutoSteal and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                if tick() - lastStealTime < Config.StealCooldown then return end
                local myPos = LocalPlayer.Character.HumanoidRootPart.Position

                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and not isTeammate(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local targetPos = player.Character.HumanoidRootPart.Position
                        local dist = (myPos - targetPos).Magnitude

                        if dist <= Config.AutoStealRange then
                            local enemyHasBall = false
                            if BallController and BallController.GetPlayerPossessingBall then
                                enemyHasBall = (BallController:GetPlayerPossessingBall() == player)
                            end

                            if not enemyHasBall then
                                for _, item in pairs(player.Character:GetDescendants()) do
                                    if item.Name:lower():find("ball") and item:IsA("BasePart") then
                                        enemyHasBall = true
                                        break
                                    end
                                end
                            end

                            if enemyHasBall then
                                lastStealTime = tick()
                                if DefenseController and DefenseController.Input then
                                    DefenseController:Input("Steal")
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 5.3 Auto Block
local lastBlockTime = 0
task.spawn(function()
    while true do
        task.wait(0.04)
        if env.BasketballHYPER_RunID ~= runId then break end
        if Config.AutoBlock and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                if tick() - lastBlockTime < Config.BlockCooldown then return end
                local myPos = LocalPlayer.Character.HumanoidRootPart.Position

                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and not isTeammate(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local enemyChar = player.Character
                        local targetPos = enemyChar.HumanoidRootPart.Position
                        local dist = (myPos - targetPos).Magnitude

                        if dist <= Config.AutoBlockRange then
                            local isEnemyShooting = false
                            local enemyHum = enemyChar:FindFirstChildOfClass("Humanoid")
                            
                            if enemyHum then
                                local state = enemyHum:GetState()
                                if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
                                    local enemyBall = false
                                    if BallController and BallController.GetPlayerPossessingBall then
                                        enemyBall = (BallController:GetPlayerPossessingBall() == player)
                                    end
                                    if not enemyBall then
                                        for _, item in pairs(enemyChar:GetDescendants()) do
                                            if item.Name:lower():find("ball") and item:IsA("BasePart") then
                                                enemyBall = true
                                                break
                                            end
                                        end
                                    end
                                    if enemyBall then isEnemyShooting = true end
                                end
                            end

                            if isEnemyShooting then
                                lastBlockTime = tick()
                                local myHum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                                if myHum then myHum:ChangeState(Enum.HumanoidStateType.Jumping) end
                                if DefenseController and DefenseController.Input then
                                    DefenseController:Input("Block")
                                    DefenseController:Input("Contest")
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 5.4 Ball ESP
local function updateBallESP()
    for _, item in pairs(workspace:GetChildren()) do
        if item.Name:lower():find("ball") and item:IsA("BasePart") then
            local highlight = item:FindFirstChild("XINZ_BallHighlight")
            local billboard = item:FindFirstChild("XINZ_BallBillboard")

            if Config.BallESP then
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "XINZ_BallHighlight"
                    highlight.FillColor = Color3.fromRGB(255, 140, 0)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.35
                    highlight.OutlineTransparency = 0
                    highlight.Parent = item
                end

                if not billboard then
                    billboard = Instance.new("BillboardGui")
                    billboard.Name = "XINZ_BallBillboard"
                    billboard.Size = UDim2.new(0, 120, 0, 30)
                    billboard.StudsOffset = Vector3.new(0, 2, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = item

                    local label = Instance.new("TextLabel", billboard)
                    label.Name = "Label"
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = "Ball"
                    label.TextColor3 = Color3.fromRGB(255, 200, 0)
                    label.Font = Enum.Font.GothamBold
                    label.TextSize = 11
                    label.TextStrokeTransparency = 0.3
                end

                if billboard and billboard:FindFirstChild("Label") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - item.Position).Magnitude)
                    billboard.Label.Text = string.format("Ball [%dm]", dist)
                end
            else
                if highlight then highlight:Destroy() end
                if billboard then billboard:Destroy() end
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if env.BasketballHYPER_RunID ~= runId then break end
        if Config.BallESP then
            pcall(updateBallESP)
        end
    end
end)

-- ==================================================================
-- // UI ENGINE: HYPER HUB Standalone UI Library
-- ==================================================================
local Library
local okLoad, resLoad = pcall(function()
    local code = ""
    local source = ""
    local _isfile = (typeof(isfile) == "function" and isfile) or nil
    local _readfile = (typeof(readfile) == "function" and readfile) or nil
    
    -- 1. Try local executor workspace files
    local localCandidates = {
        "ui.lua",
        "ui_temp.lua",
        "UI.main/ui.lua",
        "UI.main/ui_temp.lua",
        "Scripts/UI.main/ui.lua",
        "Scripts/UI.main/ui_temp.lua",
        "Scripts/ui.lua",
        "Scripts/ui_temp.lua",
        "K2NTA ST/Scripts/UI.main/ui.lua",
        "K2NTA ST/Scripts/UI.main/ui_temp.lua"
    }
    
    if _isfile and _readfile then
        for _, path in ipairs(localCandidates) do
            if _isfile(path) then
                code = _readfile(path)
                source = "Local workspace/" .. path
                break
            end
        end
    end
    
    -- 2. If no local file found, download from GitHub or Singularity Server
    if code == "" then
        local urls = {
            "https://raw.githubusercontent.com/projectsingularityv1-debug/HYPER-LOADER/refs/heads/main/UI.main/ui.lua",
            "https://raw.githubusercontent.com/projectsingularityv1-debug/HYPER-LOADER/refs/heads/main/UI.main/ui.lua"
        }
        
        for _, rawUrl in ipairs(urls) do
            local okHttp, httpBody = pcall(function()
                return game:HttpGet(rawUrl .. "?t=" .. tostring(tick()))
            end)
            if okHttp and httpBody and #httpBody > 100 then
                code = httpBody
                source = rawUrl
                break
            end
        end
    end
    
    if code == "" then
        error("Unable to read local ui.lua and online fallback fetch failed.")
    end
    
    local func, compileErr = loadstring(code)
    if not func then
        error("[" .. source .. " Compilation Error]: " .. tostring(compileErr))
    end
    
    local execOk, execRes = pcall(func)
    if not execOk then
        error("[" .. source .. " Execution Error]: " .. tostring(execRes))
    end
    
    return execRes
end)

if not okLoad or not resLoad or type(resLoad) ~= "table" or not resLoad.Window then
    warn("[XINZ] Failed to load UI Library: " .. tostring(resLoad))
    return
end

Library = resLoad

-- 7. INITIALIZE HUB WINDOW ------------------------------------
local KeyAvatarURL = (getgenv and getgenv().KeyAvatar) or ("rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150")

local Window = Library:Window({
    Profile = {
        Username = (getgenv and getgenv().KeyUsername) or LocalPlayer.DisplayName,
        Email = "UID: " .. tostring(LocalPlayer.UserId),
        AvatarUrl = KeyAvatarURL
    },
    Title = "HYPER HUB",
    Desc = "Basketball Automation & Knit Suite",
    Icon = "rbxassetid://136264753381080",
    Theme = "Dark",
    Config = {
        Keybind = Enum.KeyCode.RightShift,
        Size = UDim2.fromOffset(570, 450)
    },
    CloseUIButton = {
        Enabled = true
    }
})
-- Tabs Setup
local OffenseTab  = Window:Tab({ Title = "Offense",  Icon = "rbxassetid://136264753381080" })
local DefenseTab  = Window:Tab({ Title = "Defense",  Icon = "rbxassetid://136264753381080" })
local MovementTab = Window:Tab({ Title = "Movement", Icon = "rbxassetid://136264753381080" })
local InfoTab     = Window:Tab({ Title = "Info",     Icon = "rbxassetid://136264753381080" })

-- Offense Tab
OffenseTab:Section({ Title = "Ball Automation", Icon = "rbxassetid://136264753381080" })

OffenseTab:Toggle({
    Title = "Auto TP Get Ball",
    Desc = "Teleport to free ball immediately (Instant TP)",
    Value = Config.AutoGetBall,
    Callback = function(v) Config.AutoGetBall = v end
})

OffenseTab:Toggle({
    Title = "Ball ESP",
    Desc = "Highlight basketball aura and distance through walls",
    Value = Config.BallESP,
    Callback = function(v)
        Config.BallESP = v
        pcall(updateBallESP)
    end
})

OffenseTab:Dropdown({
    Title = "Get Ball Mode",
    List = { "TP (Instant)", "Fly" },
    Default = Config.GetBallMode == "TP" and "TP (Instant)" or "Fly",
    Callback = function(choice)
        Config.GetBallMode = choice:find("TP") and "TP" or "Fly"
    end
})

OffenseTab:Slider({
    Title = "Fly Speed",
    Min = 20,
    Max = 120,
    Default = Config.FlySpeed,
    Callback = function(v) Config.FlySpeed = v end
})

OffenseTab:Section({ Title = "Shooting & Actions", Icon = "rbxassetid://136264753381080" })

OffenseTab:Toggle({
    Title = "Instant Shoot",
    Desc = "Teleport ball above hoop for a 100% swish score",
    Value = Config.InstantShoot,
    Callback = function(v)
        Config.InstantShoot = v
        Config.AutoPerfectShoot = v
    end
})

OffenseTab:Toggle({
    Title = "Auto Shoot on Possess",
    Desc = "Automatically shoot as soon as ball is possessed",
    Value = Config.AutoShoot,
    Callback = function(v) Config.AutoShoot = v end
})

OffenseTab:Toggle({
    Title = "Double Click Shoot",
    Desc = "Simulate double-click shoot for reliable release",
    Value = Config.DoubleClickShoot,
    Callback = function(v) Config.DoubleClickShoot = v end
})

OffenseTab:Slider({
    Title = "Teleport Height (Studs)",
    Min = 3,
    Max = 30,
    Default = math.floor(Config.TeleportHeight or 9),
    Callback = function(v)
        Config.TeleportHeight = v
    end
})

OffenseTab:Slider({
    Title = "Click Hold Duration (ms)",
    Min = 20,
    Max = 1000,
    Default = math.floor((Config.ClickHoldTime or 0.12) * 1000),
    Callback = function(v)
        Config.ClickHoldTime = v / 1000
    end
})

OffenseTab:Toggle({
    Title = "Auto Face Net on Shoot",
    Desc = "Automatically face hoop when shooting (disable for backwards shots)",
    Value = Config.AutoFaceNet,
    Callback = function(v) Config.AutoFaceNet = v end
})

OffenseTab:Button({
    Title = "Instant Shoot Now [Hotkey: E / F]", Image = "play",
    Desc = "Teleport ball above hoop for a 100% swish score",
    Callback = function() executePerfectShot() end
})

OffenseTab:Button({
    Title = "Auto TP Dunk", Image = "rocket",
    Desc = "Teleport under hoop and perform immediate dunk",
    Callback = function()
        if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then return end
        if not (BallController and BallController.LocalPlayerPossessesBall and BallController:LocalPlayerPossessesBall()) then return end
        
        local myRoot = LocalPlayer.Character.HumanoidRootPart
        local hoop = getNearestHoop()
        
        if hoop then
            local floorY = myRoot.Position.Y
            local targetPos = Vector3.new(hoop.Position.X, floorY, hoop.Position.Z)
            myRoot.CFrame = CFrame.new(targetPos, Vector3.new(hoop.Position.X, floorY, hoop.Position.Z))
            myRoot.Velocity = Vector3.new(0, 0, 0)
            
            task.wait(0.04)
            if LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
            
            task.wait(0.06)
            if BallController and BallController.Dunk then
                pcall(function() BallController:Dunk() end)
            end
        end
    end
})

OffenseTab:Button({
    Title = "Safe Dribble", Icon = "rbxassetid://136264753381080",
    Desc = "Perform dribble and crossovers only while possessing ball",
    Callback = function()
        if not (BallController and BallController.LocalPlayerPossessesBall and BallController:LocalPlayerPossessesBall()) then return end
        if BallController and BallController.Dribble then
            pcall(function() BallController:Dribble() end)
        end
    end
})

OffenseTab:Button({
    Title = "Face Net",
    Callback = function()
        if AbilityController and AbilityController.LookingAtNet then pcall(function() AbilityController:LookingAtNet() end) end
    end
})

OffenseTab:Button({
    Title = "Instant Awakening",
    Callback = function()
        if AwakeningController and AwakeningController.Input then pcall(function() AwakeningController:Input() end) end
    end
})

-- Defense Tab
DefenseTab:Section({ Title = "Auto Defense", Icon = "rbxassetid://136264753381080" })

DefenseTab:Toggle({
    Title = "Auto Block",
    Desc = "Automatically block opponent shots (ignores teammates)",
    Value = Config.AutoBlock,
    Callback = function(v) Config.AutoBlock = v end
})

DefenseTab:Slider({
    Title = "Block Range",
    Min = 6,
    Max = 30,
    Default = Config.AutoBlockRange,
    Callback = function(v) Config.AutoBlockRange = v end
})

DefenseTab:Toggle({
    Title = "Auto Steal",
    Desc = "Steal basketball from opponents within range",
    Value = Config.AutoSteal,
    Callback = function(v) Config.AutoSteal = v end
})

DefenseTab:Slider({
    Title = "Steal Range",
    Min = 6,
    Max = 30,
    Default = Config.AutoStealRange,
    Callback = function(v) Config.AutoStealRange = v end
})

DefenseTab:Button({
    Title = "Force Block", Icon = "rbxassetid://136264753381080",
    Desc = "Perform a single emergency block jump",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        if DefenseController and DefenseController.Input then
            pcall(function() DefenseController:Input("Block") end)
        end
    end
})

-- Movement Tab
MovementTab:Section({ Title = "Movement & Speed", Icon = "rbxassetid://136264753381080" })

MovementTab:Toggle({
    Title = "WalkSpeed Boost",
    Desc = "Enable custom movement speed (works across all courts)",
    Value = Config.SpeedEnabled,
    Callback = function(v)
        Config.SpeedEnabled = v
        if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end
})

MovementTab:Dropdown({
    Title = "Speed Mode",
    List = { "Hybrid (Recommended)", "CFrame (Bypass 100%)", "Velocity (Smooth)", "WalkSpeed (Standard)" },
    Default = "Hybrid (Recommended)",
    Callback = function(choice)
        if choice:find("CFrame") then
            Config.SpeedMethod = "CFrame"
        elseif choice:find("Velocity") then
            Config.SpeedMethod = "Velocity"
        elseif choice:find("WalkSpeed") then
            Config.SpeedMethod = "WalkSpeed"
        else
            Config.SpeedMethod = "Hybrid"
        end
    end
})

MovementTab:Slider({
    Title = "Speed Amount",
    Min = 16,
    Max = 120,
    Default = Config.CustomSpeed,
    Callback = function(v) Config.CustomSpeed = v end
})

MovementTab:Toggle({
    Title = "Infinite Jump",
    Desc = "Allow continuous jumping in mid-air",
    Value = Config.InfJump,
    Callback = function(v) Config.InfJump = v end
})

MovementTab:Toggle({
    Title = "Noclip",
    Desc = "Walk through walls and obstacles",
    Value = Config.Noclip,
    Callback = function(v) Config.Noclip = v end
})

-- Info Tab
InfoTab:Section({ Title = "Hub Information", Icon = "rbxassetid://136264753381080" })
InfoTab:Label({ Title = "Game:", Desc = "Basketball / Hoops" })
InfoTab:Label({ Title = "Engine:", Desc = "Knit Controller Full Integration" })
InfoTab:Label({ Title = "UI Version:", Desc = "100% Native Standalone (Loadstring-Free)" })
-- Hotkeys (E / F = Instant Shoot, Delete = Emergency Panic)
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe then
        if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.F then
            if Config.InstantShoot or Config.AutoPerfectShoot then
                executePerfectShot()
            end
        elseif input.KeyCode == Enum.KeyCode.Delete then
            Config.AutoGetBall = false
            Config.AutoBlock = false
            Config.AutoSteal = false
            Config.BallESP = false
            Config.SpeedEnabled = false
            Config.InfJump = false
            Config.Noclip = false
            Config.AutoShoot = false
            pcall(updateBallESP)
            Window:Notify({ Title = "PANIC ACTIVATED", Desc = "All cheat features disabled!", Time = 3 })
        end
    end
end)

env.BasketballHYPER_Cleanup = function()
    if renderConn then renderConn:Disconnect() end
    if steppedConn then steppedConn:Disconnect() end
end

-- Anti-AFK
if Config.AntiAFK then
    LocalPlayer.Idled:Connect(function()
        pcall(function()
            if VirtualUser then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.zero)
            end
        end)
    end)
end

Window:Notify({
    Title = "HYPER HUB",
    Desc = "Basketball Hub Ready!\nRight Shift = Toggle UI",
    Time = 5
})
