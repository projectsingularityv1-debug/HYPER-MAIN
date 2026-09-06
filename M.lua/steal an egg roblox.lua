-- ==============================================================================
--  HYPER HUB - Steal an Egg Roblox
--  Features: God Mode, Zone Fly/Tween (Height 160), Noclip, Speed Controller
--  Created by K2NTA ST | Project Singularity
-- ==============================================================================

local _cloneref = (cloneref or function(...) return ... end)
local function getService(name)
    local ok, s = pcall(function() return game:GetService(name) end)
    return ok and _cloneref(s) or nil
end

local Players = getService("Players")
local RunService = getService("RunService")
local TweenService = getService("TweenService")
local UserInputService = getService("UserInputService")
local Workspace = getService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ==============================================================================
-- // UI Library Loader
-- ==============================================================================
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

    if typeof(isfile) == "function" and typeof(readfile) == "function" then
        local paths = { "ui.lua", "UI.main/ui.lua", "Scripts/UI.main/ui.lua", "Scripts/ui.lua", "HYPER_Cache/ui.lua" }
        for _, p in ipairs(paths) do
            if isfile(p) then
                local content = cleanLua(readfile(p))
                if #content > 50 then
                    local fn = loadstring(content)
                    if fn then
                        local ok, lib = pcall(fn)
                        if ok and type(lib) == "table" and lib.Window then
                            Library = lib
                            env.HYPER_UI = lib
                            break
                        end
                    end
                end
            end
        end
    end

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
                local fn = loadstring(src)
                if fn then
                    local ok, lib = pcall(fn)
                    if ok and type(lib) == "table" and lib.Window then
                        Library = lib
                        env.HYPER_UI = lib
                        break
                    end
                end
            end
        end
    end

    if not Library or not Library.Window then
        error("[HYPER HUB] Failed to load UI Library!")
    end
end

-- ==============================================================================
-- // Configuration & Zone Coordinates
-- ==============================================================================
local Zones = {
    ["Home"]    = Vector3.new(539, 70, -364),
    ["Zone 1"]  = Vector3.new(605, 70, -368),
    ["Zone 2"]  = Vector3.new(716, 70, -368),
    ["Zone 3"]  = Vector3.new(889, 70, -366),
    ["Zone 4"]  = Vector3.new(1136, 70, -364),
    ["Zone 5"]  = Vector3.new(1491, 70, -361),
    ["Zone 6"]  = Vector3.new(1885, 70, -358),
    ["Zone 7"]  = Vector3.new(2284, 70, -355),
    ["Zone 8"]  = Vector3.new(2809, 70, -355),
    ["Zone 9"]  = Vector3.new(3389, 70, -357),
    ["Zone 10"] = Vector3.new(4021, 70, -359),
    ["Zone 11"] = Vector3.new(4787, 70, -375),
}

local ZoneOrder = {
    "Home", "Zone 1", "Zone 2", "Zone 3", "Zone 4", "Zone 5",
    "Zone 6", "Zone 7", "Zone 8", "Zone 9", "Zone 10", "Zone 11"
}

local State = {
    SelectedZone = "Home",
    TweenSpeed = 110,       -- ความเร็วทางตรง (ช้าลง นุ่มนวล ไม่โดนดีดกลับ)
    AscendSpeed = 380,      -- ความเร็วพุ่งขึ้นฟ้า (พุ่งขึ้นไวทันใจ)
    DescendSpeed = 220,     -- ความเร็วร่อนลงเป้าหมาย
    TweenHeight = 160,
    IsTweening = false,
    CurrentTween = nil,
    GodMode = true, -- Auto-enabled on script execution
    Noclip = false,
    InfJump = false,
    GodHeartbeat = nil,
    NoclipConnection = nil,
    WalkSpeed = 16,
    JumpPower = 50,
}

-- ==============================================================================
local function notify(title, desc, icon, time)
    if Window and Window.Notify then
        Window:Notify({ Title = title, Desc = desc, Icon = icon or "rbxassetid://10709791437", Time = time or 3 })
    elseif Library and Library.Notify then
        Library:Notify({ Title = title, Desc = desc, Icon = icon or "rbxassetid://10709791437", Time = time or 3 })
    end
end

-- // Character & Utility Helpers
-- ==============================================================================
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    local char = getCharacter()
    return char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 3)
end

local function getHumanoid()
    local char = getCharacter()
    return char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 3)
end

-- ==============================================================================
-- // Auto God Mode / Health Lock (setupGodState Engine)
-- ==============================================================================
local H = RunService or game:GetService("RunService")
local R = H.RenderStepped
local RE = H.RenderStepped.Wait

local currentCharacter = nil
local currentHumanoid = nil
local godConnections = {}

local function cleanupGodConnections()
    for _, conn in ipairs(godConnections) do
        if typeof(conn) == "RBXScriptConnection" and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(godConnections)
end

local function restoreHealth(hum)
    if not hum or not hum.Parent then return end
    pcall(function()
        if hum.MaxHealth < 100 then
            hum.MaxHealth = 100
        end
        hum.Health = hum.MaxHealth
    end)
end

local function setupGodState(character)
    if not character then return end
    local oldHumanoid = character:WaitForChild("Humanoid", 5) or character:FindFirstChildOfClass("Humanoid")
    if not oldHumanoid then return end

    cleanupGodConnections()

    -- 0. Recreate / Clone Humanoid ตัวใหม่ (ตัดขาดจากระบบดาเมจและการตายของเซิร์ฟเวอร์ - โหมดอมตะเดิม)
    local humanoid = oldHumanoid
    if not oldHumanoid:GetAttribute("IsGodHumanoid") then
        local ok, cloned = pcall(function()
            local newHum = oldHumanoid:Clone()
            newHum.Name = "Humanoid"
            newHum:SetAttribute("IsGodHumanoid", true)
            newHum.Parent = character
            oldHumanoid:Destroy()
            return newHum
        end)

        if ok and cloned then
            humanoid = cloned

            -- รีเซ็ตกล้อง (CameraSubject) ให้จับที่ Humanoid ตัวใหม่ทันที
            pcall(function()
                local camera = Workspace.CurrentCamera or workspace.CurrentCamera
                if camera then
                    camera.CameraSubject = humanoid
                end
            end)

            -- รีเฟรช Animate Script เพื่อให้ท่าทางการเดินเล่นได้อย่างสมบูรณ์
            pcall(function()
                local animate = character:FindFirstChild("Animate")
                if animate and animate:IsA("LocalScript") then
                    animate.Disabled = true
                    task.wait(0.05)
                    animate.Disabled = false
                end
            end)
        end
    end

    currentCharacter = character
    currentHumanoid = humanoid

    -- 1. ป้องกันข้อต่อหลุดเมื่อตัวละครโดนดาเมจ
    humanoid.BreakJointsOnDeath = false

    -- 2. ปิด State การตาย
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end)

    restoreHealth(humanoid)

    -- 3. ดักจับเมื่อสถานะเปลี่ยนเป็น Dead ให้บังคับเปลี่ยนเป็น GettingUp
    local stateConn = humanoid.StateChanged:Connect(function(_, state)
        if State.GodMode and state == Enum.HumanoidStateType.Dead then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            restoreHealth(humanoid)
        end
    end)
    table.insert(godConnections, stateConn)

    -- 4. ตรวจสอบและล็อคสถานะทุกเฟรม (Heartbeat)
    local heartbeatConn = H.Heartbeat:Connect(function()
        if not State.GodMode then return end
        if not character or not character.Parent or not humanoid or not humanoid.Parent then
            return
        end

        if humanoid:GetState() == Enum.HumanoidStateType.Dead then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end

        if humanoid.Health < humanoid.MaxHealth or humanoid.Health <= 0 then
            restoreHealth(humanoid)
        end
    end)
    table.insert(godConnections, heartbeatConn)

    -- 5. เติมเลือดระดับเฟรมภาพ (RenderStepped)
    local renderConn = H.RenderStepped:Connect(function()
        if not State.GodMode then return end
        if not character or not character.Parent or not humanoid or not humanoid.Parent then
            return
        end
        if humanoid.Health < humanoid.MaxHealth then
            humanoid.Health = humanoid.MaxHealth
        end
    end)
    table.insert(godConnections, renderConn)
end

-- ลูปตรวจสอบเพิ่มเติมใน Background Thread
task.spawn(function()
    while true do
        if State.GodMode and currentHumanoid and currentHumanoid.Parent then
            if currentHumanoid.Health < currentHumanoid.MaxHealth then
                currentHumanoid.Health = currentHumanoid.MaxHealth
            end
        end
        RE(R)
    end
end)

-- ทำงานกับตัวละครปัจจุบันทันทีที่รันสคริปต์
if LocalPlayer.Character then
    task.spawn(setupGodState, LocalPlayer.Character)
end

-- ทำงานอัตโนมัติทุกครั้งที่เกิดใหม่ (Respawn)
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    setupGodState(char)
end)

local function toggleGodMode(enabled)
    State.GodMode = enabled
    if enabled then
        if LocalPlayer.Character then
            setupGodState(LocalPlayer.Character)
        end
        notify("GOD MODE", "Recreate Humanoid God Mode Active", "rbxassetid://10709791437", 2.5)
    else
        cleanupGodConnections()
        if currentHumanoid then
            pcall(function()
                currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            end)
        end
        notify("GOD MODE", "God Mode Disabled", "rbxassetid://10709791437", 2.5)
    end
end

-- ==============================================================================
-- // Noclip Handler
-- ==============================================================================
local function toggleNoclip(enabled)
    State.Noclip = enabled
    if enabled then
        if State.NoclipConnection then State.NoclipConnection:Disconnect() end
        State.NoclipConnection = RunService.Stepped:Connect(function()
            if not State.Noclip then
                if State.NoclipConnection then State.NoclipConnection:Disconnect() State.NoclipConnection = nil end
                return
            end
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if State.NoclipConnection then
            State.NoclipConnection:Disconnect()
            State.NoclipConnection = nil
        end
    end
end

-- ==============================================================================
-- // Smooth 3-Stage Tween Fly Engine (Sky Height: 160)
-- ==============================================================================
local function cancelTween()
    if State.CurrentTween then
        State.CurrentTween:Cancel()
        State.CurrentTween = nil
    end
    State.IsTweening = false
    local hrp = getHRP()
    if hrp then
        hrp.Anchored = false
        local bv = hrp:FindFirstChild("HyperFlyVelocity")
        if bv then bv:Destroy() end
    end
end

local function flyToTarget(targetPos, onFinished)
    local hrp = getHRP()
    if not hrp then return end

    cancelTween()
    State.IsTweening = true

    -- Anti-physics fall prevention during fly
    local bv = Instance.new("BodyVelocity")
    bv.Name = "HyperFlyVelocity"
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.MaxForce = Vector3.new(0, math.huge, 0)
    bv.Parent = hrp

    task.spawn(function()
        local currentPos = hrp.Position
        local skyY = State.TweenHeight -- Default 160

        -- Stage 1: Ascend rapidly to sky altitude (160) - พุ่งขึ้นฟ้าอย่างรวดเร็ว
        local startSkyPos = Vector3.new(currentPos.X, skyY, currentPos.Z)
        local dist1 = math.abs(skyY - currentPos.Y)
        local ascendSpeed = State.AscendSpeed or 380
        local time1 = math.clamp(dist1 / ascendSpeed, 0.05, 3.0)

        local tInfo1 = TweenInfo.new(time1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        State.CurrentTween = TweenService:Create(hrp, tInfo1, { CFrame = CFrame.new(startSkyPos) })
        State.CurrentTween:Play()
        State.CurrentTween.Completed:Wait()

        if not State.IsTweening then if bv then bv:Destroy() end return end

        -- Stage 2: Smooth straight flight across the sky (ทางตรง)
        local targetSkyPos = Vector3.new(targetPos.X, skyY, targetPos.Z)
        local dist2 = (Vector3.new(startSkyPos.X, 0, startSkyPos.Z) - Vector3.new(targetSkyPos.X, 0, targetSkyPos.Z)).Magnitude
        local straightSpeed = State.TweenSpeed or 110
        local time2 = math.clamp(dist2 / straightSpeed, 0.08, 90)

        local tInfo2 = TweenInfo.new(time2, Enum.EasingStyle.Linear)
        State.CurrentTween = TweenService:Create(hrp, tInfo2, { CFrame = CFrame.new(targetSkyPos) })
        State.CurrentTween:Play()
        State.CurrentTween.Completed:Wait()

        if not State.IsTweening then if bv then bv:Destroy() end return end

        -- Stage 3: Descend smoothly to the zone target
        local dist3 = math.abs(skyY - targetPos.Y)
        local descendSpeed = State.DescendSpeed or 220
        local time3 = math.clamp(dist3 / descendSpeed, 0.05, 3.0)

        local tInfo3 = TweenInfo.new(time3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        State.CurrentTween = TweenService:Create(hrp, tInfo3, { CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0)) })
        State.CurrentTween:Play()
        State.CurrentTween.Completed:Wait()

        if bv and bv.Parent then bv:Destroy() end
        State.IsTweening = false
        State.CurrentTween = nil

        if onFinished then onFinished() end
    end)
end

local function teleportDirect(targetPos)
    local hrp = getHRP()
    if hrp then
        cancelTween()
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
    end
end

-- ==============================================================================
-- // Jump Controller (Fixes Jump on Cloned Humanoid + Infinite Jump)
-- ==============================================================================
UserInputService.JumpRequest:Connect(function()
    local hum = currentHumanoid or getHumanoid()
    if not hum or not hum.Parent then return end

    if State.InfJump then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    else
        hum.Jump = true
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Running 
           or state == Enum.HumanoidStateType.RunningNoPhysics 
           or state == Enum.HumanoidStateType.Landed 
           or hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ==============================================================================
-- // UI Window Creation (HYPER HUB UI)
-- ==============================================================================
local Window = Library:Window({
    Title = "HYPER HUB",
    Desc = "Steal an Egg Roblox | Pro Automation",
    Version = "v3.0",
    Icon = "https://img2.pic.in.th/HYPER.png",
    Theme = "Dark",
    Config = {
        Keybind = Enum.KeyCode.RightControl,
        Size = UDim2.new(0, 560, 0, 440)
    },
    CloseUIButton = {
        Enabled = true
    },
    Profile = {
        Username = LocalPlayer.Name,
        Email = "Steal an Egg Hub",
        AvatarUrl = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150"
    }
})

-- TAB 1: FLIGHT & ZONES
local MainTab = Window:Tab({ Title = "Flight & Zones", Icon = "rbxassetid://10709790948" })

MainTab:Section({ Title = "Zone Teleportation & Fly Control" })

MainTab:Dropdown({
    Title = "Select Destination Zone",
    Desc = "Choose a destination zone to fly or teleport to",
    List = ZoneOrder,
    Value = State.SelectedZone,
    Callback = function(val)
        State.SelectedZone = val
    end
})

MainTab:Button({
    Title = "Fly to Selected Zone (Height 160)",
    Desc = "Starts 3-stage smooth flight to target coordinate",
    Callback = function()
        local pos = Zones[State.SelectedZone]
        if pos then
            notify("Flying to " .. State.SelectedZone, "Alt: " .. tostring(State.TweenHeight) .. " | Straight: " .. tostring(State.TweenSpeed) .. " | Ascend: " .. tostring(State.AscendSpeed), "rbxassetid://10709790948", 2.5)
            flyToTarget(pos, function()
                notify("Arrived!", "Successfully reached " .. State.SelectedZone, "rbxassetid://10709791437", 2.5)
            end)
        end
    end
})

MainTab:Button({
    Title = "Instant Teleport to Selected Zone",
    Desc = "Instantly warps your character directly to the zone",
    Callback = function()
        local pos = Zones[State.SelectedZone]
        if pos then
            teleportDirect(pos)
            notify("Teleported", "Warped to " .. State.SelectedZone, "rbxassetid://10709791437", 2)
        end
    end
})

MainTab:Button({
    Title = "Cancel Flight / Tween",
    Desc = "Stops current flight immediately",
    Callback = function()
        cancelTween()
        notify("Flight Cancelled", "Tween stopped.", "rbxassetid://10709791437", 2)
    end
})

MainTab:Section({ Title = "Flight Physics & Speed Adjustments" })

MainTab:Slider({
    Title = "Straight Flight Speed (ทางตรง)",
    Desc = "Cruise speed during straight flight (default: 110 | Max: 1200)",
    Min = 20,
    Max = 1200,
    Value = State.TweenSpeed,
    Callback = function(val)
        State.TweenSpeed = val
    end
})

MainTab:Slider({
    Title = "Ascend Launch Speed (พุ่งขึ้นฟ้า)",
    Desc = "Fast launch speed when ascending (default: 380 | Max: 1500)",
    Min = 50,
    Max = 1500,
    Value = State.AscendSpeed,
    Callback = function(val)
        State.AscendSpeed = val
    end
})

MainTab:Slider({
    Title = "Descend Landing Speed (ร่อนลงพื้น)",
    Desc = "Smooth descent speed to target zone (default: 220 | Max: 1000)",
    Min = 50,
    Max = 1000,
    Value = State.DescendSpeed,
    Callback = function(val)
        State.DescendSpeed = val
    end
})

MainTab:Slider({
    Title = "Flight Altitude Height (ความสูงเพดานบิน)",
    Desc = "Height during cruise stage (default: 160 | Max: 500)",
    Min = 50,
    Max = 500,
    Value = State.TweenHeight,
    Callback = function(val)
        State.TweenHeight = val
    end
})

-- TAB 2: QUICK ZONE TELEPORTS
local ZonesTab = Window:Tab({ Title = "Quick Zones", Icon = "rbxassetid://10709791437" })

ZonesTab:Section({ Title = "Direct 1-Click Zone Flights" })

for _, zName in ipairs(ZoneOrder) do
    local coord = Zones[zName]
    ZonesTab:Button({
        Title = "Fly to " .. zName,
        Desc = string.format("Coord: %d, %d, %d", coord.X, coord.Y, coord.Z),
        Callback = function()
            State.SelectedZone = zName
            flyToTarget(coord, function()
                notify("Arrived", "Reached " .. zName, "rbxassetid://10709791437", 2)
            end)
        end
    })
end

-- TAB 3: PLAYER & GOD MODE
local PlayerTab = Window:Tab({ Title = "Player & GodMode", Icon = "rbxassetid://10709791523" })

PlayerTab:Section({ Title = "Invincibility & Protection" })

PlayerTab:Toggle({
    Title = "God Mode (Recreate Humanoid)",
    Desc = "Clone Humanoid & sever server damage link (Old God Mode)",
    Value = State.GodMode,
    Callback = function(val)
        toggleGodMode(val)
    end
})

PlayerTab:Toggle({
    Title = "Noclip (Walk Through Walls)",
    Desc = "Disables collision on all character parts",
    Value = State.Noclip,
    Callback = function(val)
        toggleNoclip(val)
    end
})

PlayerTab:Toggle({
    Title = "Infinite Jump",
    Desc = "Allows jumping continuously in air",
    Value = State.InfJump,
    Callback = function(val)
        State.InfJump = val
    end
})

PlayerTab:Section({ Title = "Speed & Jump Modifications" })

PlayerTab:Slider({
    Title = "Walk Speed",
    Desc = "Adjust character walking speed (default: 16 | Max: 500)",
    Min = 16,
    Max = 500,
    Value = 16,
    Callback = function(val)
        State.WalkSpeed = val
        local hum = currentHumanoid or getHumanoid()
        if hum then hum.WalkSpeed = val end
    end
})

PlayerTab:Button({
    Title = "Egg Safe Runner Speed (35 studs/s)",
    Desc = "Safe running speed that prevents server speed-check from resetting the egg",
    Callback = function()
        State.WalkSpeed = 35
        local hum = currentHumanoid or getHumanoid()
        if hum then hum.WalkSpeed = 35 end
        notify("SPEED PRESET", "WalkSpeed set to 35 (Safe for Egg Delivery)! Run to base on ground.", "rbxassetid://10709791437", 3)
    end
})

PlayerTab:Button({
    Title = "Egg Fast Runner Speed (60 studs/s)",
    Desc = "Faster ground speed for returning",
    Callback = function()
        State.WalkSpeed = 60
        local hum = currentHumanoid or getHumanoid()
        if hum then hum.WalkSpeed = 60 end
        notify("SPEED PRESET", "WalkSpeed set to 60! Run to base on ground.", "rbxassetid://10709791437", 3)
    end
})

PlayerTab:Button({
    Title = "Reset Normal Speed (16 studs/s)",
    Desc = "Resets walking speed back to Roblox default (16)",
    Callback = function()
        State.WalkSpeed = 16
        local hum = currentHumanoid or getHumanoid()
        if hum then hum.WalkSpeed = 16 end
        notify("SPEED PRESET", "WalkSpeed reset to 16 (Normal).", "rbxassetid://10709791437", 2)
    end
})

PlayerTab:Slider({
    Title = "Jump Power",
    Desc = "Adjust character jumping power (default: 50 | Max: 600)",
    Min = 50,
    Max = 600,
    Value = 50,
    Callback = function(val)
        State.JumpPower = val
        local hum = currentHumanoid or getHumanoid()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = val
        end
    end
})

-- Maintain WalkSpeed/JumpPower after respawn
RunService.Heartbeat:Connect(function()
    if State.WalkSpeed ~= 16 or State.JumpPower ~= 50 then
        local hum = currentHumanoid or getHumanoid()
        if hum then
            if State.WalkSpeed ~= 16 and hum.WalkSpeed ~= State.WalkSpeed then
                hum.WalkSpeed = State.WalkSpeed
            end
            if State.JumpPower ~= 50 and hum.JumpPower ~= State.JumpPower then
                hum.UseJumpPower = true
                hum.JumpPower = State.JumpPower
            end
        end
    end
end)

-- TAB 4: MISC & SETTINGS
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "rbxassetid://10709791130" })

SettingsTab:Section({ Title = "Theme & Configuration" })

SettingsTab:Dropdown({
    Title = "Change UI Theme",
    Desc = "Select visual style",
    List = { "Dark", "Amethyst", "Liquid Glass", "Rose", "Ocean", "Neon", "Gold", "Light" },
    Value = "Dark",
    Callback = function(tName)
        Library:SetTheme(tName)
    end
})

SettingsTab:Keybind({
    Title = "Toggle UI Keybind",
    Desc = "Key to show/hide the interface",
    Value = Enum.KeyCode.RightControl,
    Callback = function(key)
        -- Keybind updated
    end
})

SettingsTab:Button({
    Title = "Unload & Destroy UI",
    Desc = "Cleanly removes the script interface",
    Callback = function()
        cancelTween()
        toggleGodMode(false)
        toggleNoclip(false)
        Window:Destroy()
    end
})

notify("HYPER HUB LOADED", "Steal an Egg Roblox loaded! Auto God Mode is ACTIVE.", "rbxassetid://10709791437", 4)
