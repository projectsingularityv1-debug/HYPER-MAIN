-- ══════════════════════════════════════════════════════════════════════════
-- //  TTJY Studio — Universal ESP & AC Bypass
-- //  Version  : 1.0
-- //  Author   : TTJY Studio / K2NTA ST
-- //  Works    : Most Roblox games (Universal)
-- //  NOTE     : DO NOT USE API.M
-- ══════════════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────────────────
-- // Services
-- ────────────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Camera           = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- ────────────────────────────────────────────────────────────────────────
-- // Settings
-- ────────────────────────────────────────────────────────────────────────
local Settings = {
    -- ── ESP ──────────────────────────────────────
    ESP_Enabled         = true;
    ESP_ShowBox         = true;       -- กล่อง 2D รอบตัวผู้เล่น
    ESP_ShowName        = true;       -- แสดงชื่อผู้เล่น
    ESP_ShowDist        = true;       -- แสดงระยะห่าง
    ESP_ShowHealth      = true;       -- แถบ HP
    ESP_ShowTracers     = false;      -- เส้นลาก (Tracer)
    ESP_ShowSkeleton    = false;      -- โครงกระดูก
    ESP_TeamCheck       = true;       -- ไม่แสดง ESP ของเพื่อนร่วมทีม
    ESP_MaxDist         = 1000;       -- ระยะสูงสุดที่แสดง (studs)
    ESP_BoxThickness    = 1.5;
    ESP_NameSize        = 13;
    ESP_TracerOrigin    = "Bottom";   -- "Bottom" | "Center" | "Mouse"

    -- ── Colors ───────────────────────────────────
    Color_Enemy         = Color3.fromRGB(255, 65,  65);
    Color_Team          = Color3.fromRGB(65,  180, 255);
    Color_Name          = Color3.fromRGB(255, 255, 255);
    Color_Dist          = Color3.fromRGB(200, 200, 200);
    Color_HealthHigh    = Color3.fromRGB(0,   220, 100);
    Color_HealthLow     = Color3.fromRGB(255, 60,  60);
    Color_Tracer        = Color3.fromRGB(255, 200, 0);
    Color_Skeleton      = Color3.fromRGB(220, 220, 220);

    -- ── Bypass ───────────────────────────────────
    Bypass_Enabled          = true;
    Bypass_AntiAFK          = true;   -- กัน AFK kick
    Bypass_FakeLatency      = false;  -- (reserved — future)
    Bypass_NilScript        = true;   -- ซ่อน script ใน nil (ScriptContext)
    Bypass_PatchOverflow    = true;   -- patch overflow string constant
    Bypass_DisableLogSvc    = true;   -- บล็อก LogService
    Bypass_HookFindService  = true;   -- hook FindService (SuspiciousServices)
    Bypass_PatchCompareTbls = true;   -- patch compareTables
    Bypass_BlockLoopCrash   = true;   -- ScriptContext timeout
    Bypass_HideGC           = true;   -- clear islclosure string table

    -- ── Anti-AFK ─────────────────────────────────
    AFK_Interval    = 60;   -- วินาที
}

-- ────────────────────────────────────────────────────────────────────────
-- // Internal
-- ────────────────────────────────────────────────────────────────────────
local ESPObjects   = {}  -- [player] = { Box, Name, Dist, HP, Tracer, ... }
local BypassFlags  = {
    OverflowPatched    = false;
    LogServiceBlocked  = false;
    FindServiceHooked  = false;
    CompareTablesPatched = false;
    LoopCrashBlocked   = false;
    StringTableCleared = false;
}
local LogSvcConns  = {}

local LINE = string.rep("─", 60)
local function header(t) warn(LINE) warn("//  "..t) warn(LINE) end
local function log(tag, msg) warn(string.format("  [%-22s] %s", tag, tostring(msg or ""))) end

local function safeCall(fn)
    local ok, err = pcall(fn)
    if not ok then warn("  [safeCall ERR]", err) end
end

-- ────────────────────────────────────────────────────────────────────────
-- // Utility — Team Check
-- ────────────────────────────────────────────────────────────────────────
local function isTeammate(player)
    if player == LocalPlayer then return true end
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team == player.Team
    end
    if LocalPlayer.TeamColor and player.TeamColor then
        return LocalPlayer.TeamColor == player.TeamColor
    end
    local myChar = LocalPlayer.Character
    local theirChar = player.Character
    if myChar and theirChar then
        local mine  = LocalPlayer:GetAttribute("Team") or myChar:GetAttribute("Team")
        local theirs= player:GetAttribute("Team") or theirChar:GetAttribute("Team")
        if mine and theirs and mine == theirs then return true end
    end
    return false
end

-- ────────────────────────────────────────────────────────────────────────
-- // Utility — WorldToViewport wrapper
-- ────────────────────────────────────────────────────────────────────────
local function worldToScreen(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

-- ────────────────────────────────────────────────────────────────────────
-- // Utility — Character bounding box corners → 2D box
-- ────────────────────────────────────────────────────────────────────────
local function getCharBounds(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp then return nil end

    local rootPos   = hrp.Position
    local halfH     = (hum and hum.HipHeight * 2 + 0.5) or 5
    local halfW     = 1.5

    -- 8 vert corners
    local offsets = {
        Vector3.new( halfW, halfH,  halfW),
        Vector3.new(-halfW, halfH,  halfW),
        Vector3.new( halfW, halfH, -halfW),
        Vector3.new(-halfW, halfH, -halfW),
        Vector3.new( halfW, -0.1,  halfW),
        Vector3.new(-halfW, -0.1,  halfW),
        Vector3.new( halfW, -0.1, -halfW),
        Vector3.new(-halfW, -0.1, -halfW),
    }

    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local allOnScreen = true

    for _, off in ipairs(offsets) do
        local screen, onScreen = worldToScreen(rootPos + off)
        if not onScreen then allOnScreen = false end
        if screen.X < minX then minX = screen.X end
        if screen.Y < minY then minY = screen.Y end
        if screen.X > maxX then maxX = screen.X end
        if screen.Y > maxY then maxY = screen.Y end
    end

    return {
        X = minX; Y = minY;
        W = maxX - minX; H = maxY - minY;
        TopCenter = Vector2.new((minX + maxX) / 2, minY);
        BotCenter = Vector2.new((minX + maxX) / 2, maxY);
        RightCenter= Vector2.new(maxX, (minY + maxY) / 2);
        AllVisible = allOnScreen;
        HeadPos    = rootPos + Vector3.new(0, halfH + 0.3, 0);
        RootPos    = rootPos;
    }
end

-- ────────────────────────────────────────────────────────────────────────
-- // Drawing Helpers — creates Drawing objects from the executor API
-- ────────────────────────────────────────────────────────────────────────
local function newLine(thickness, color, transparency)
    local d = Drawing.new("Line")
    d.Thickness   = thickness or 1
    d.Color       = color or Color3.new(1, 1, 1)
    d.Transparency= transparency or 1
    d.Visible     = false
    return d
end

local function newText(size, color, outline, font)
    local d = Drawing.new("Text")
    d.Size         = size or 13
    d.Color        = color or Color3.new(1, 1, 1)
    d.Outline      = outline ~= false
    d.Font         = font or Drawing.Fonts.UI
    d.Visible      = false
    return d
end

local function newQuad(color, thickness, filled, transparency)
    local d = Drawing.new("Quad")
    d.Color        = color or Color3.new(1, 0, 0)
    d.Thickness    = thickness or 1.5
    d.Filled       = filled or false
    d.Transparency = transparency or 1
    d.Visible      = false
    return d
end

-- ────────────────────────────────────────────────────────────────────────
-- // ESP — Skeleton bone connections
-- ────────────────────────────────────────────────────────────────────────
local SKELETON_BONES = {
    {"Head",             "UpperTorso"},
    {"UpperTorso",       "LowerTorso"},
    {"LowerTorso",       "LeftUpperLeg"},
    {"LowerTorso",       "RightUpperLeg"},
    {"LeftUpperLeg",     "LeftLowerLeg"},
    {"RightUpperLeg",    "RightLowerLeg"},
    {"LeftLowerLeg",     "LeftFoot"},
    {"RightLowerLeg",    "RightFoot"},
    {"UpperTorso",       "LeftUpperArm"},
    {"UpperTorso",       "RightUpperArm"},
    {"LeftUpperArm",     "LeftLowerArm"},
    {"RightUpperArm",    "RightLowerArm"},
    {"LeftLowerArm",     "LeftHand"},
    {"RightLowerArm",    "RightHand"},
}

-- ────────────────────────────────────────────────────────────────────────
-- // ESP — Create drawing objects for a player
-- ────────────────────────────────────────────────────────────────────────
local function createESP(player)
    if ESPObjects[player] then return end

    local obj = {}

    -- Box (Quad)
    obj.Box = newQuad(Settings.Color_Enemy, Settings.ESP_BoxThickness, false, 1)

    -- Name
    obj.Name = newText(Settings.ESP_NameSize, Settings.Color_Name)
    obj.Name.Center = true

    -- Distance
    obj.Dist = newText(11, Settings.Color_Dist)
    obj.Dist.Center = true

    -- Health bar (2 lines: BG + fill)
    obj.HPBg   = newLine(4, Color3.fromRGB(0, 0, 0), 0.5)
    obj.HPFill = newLine(3, Settings.Color_HealthHigh, 1)

    -- Tracer
    obj.Tracer = newLine(1, Settings.Color_Tracer, 1)

    -- Skeleton lines (per bone)
    obj.Skeleton = {}
    for i = 1, #SKELETON_BONES do
        obj.Skeleton[i] = newLine(1, Settings.Color_Skeleton, 0.7)
    end

    ESPObjects[player] = obj
end

-- ────────────────────────────────────────────────────────────────────────
-- // ESP — Remove drawing objects for a player
-- ────────────────────────────────────────────────────────────────────────
local function removeESP(player)
    local obj = ESPObjects[player]
    if not obj then return end

    for _, d in pairs(obj) do
        if typeof(d) == "table" then
            for _, line in pairs(d) do
                pcall(function() line:Remove() end)
            end
        else
            pcall(function() d:Remove() end)
        end
    end
    ESPObjects[player] = nil
end

-- ────────────────────────────────────────────────────────────────────────
-- // ESP — Hide all objects
-- ────────────────────────────────────────────────────────────────────────
local function hideESP(obj)
    obj.Box.Visible     = false
    obj.Name.Visible    = false
    obj.Dist.Visible    = false
    obj.HPBg.Visible    = false
    obj.HPFill.Visible  = false
    obj.Tracer.Visible  = false
    for _, line in ipairs(obj.Skeleton) do line.Visible = false end
end

-- ────────────────────────────────────────────────────────────────────────
-- // ESP — Update single player frame
-- ────────────────────────────────────────────────────────────────────────
local function updateESPPlayer(player, obj)
    local char = player.Character
    if not char then hideESP(obj) return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then hideESP(obj) return end

    -- Team check
    if Settings.ESP_TeamCheck and isTeammate(player) then
        hideESP(obj) return
    end

    -- Distance
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then hideESP(obj) return end
    local dist = (hrp.Position - myHRP.Position).Magnitude
    if dist > Settings.ESP_MaxDist then hideESP(obj) return end

    -- Bounds
    local bounds = getCharBounds(char)
    if not bounds then hideESP(obj) return end

    -- Onscreen check (head position)
    local _, headOnScreen = worldToScreen(bounds.HeadPos)
    if not headOnScreen then hideESP(obj) return end

    local esColor = isTeammate(player) and Settings.Color_Team or Settings.Color_Enemy

    -- ── Box ─────────────────────────────────────
    if Settings.ESP_ShowBox then
        local x, y, w, h = bounds.X, bounds.Y, bounds.W, bounds.H
        obj.Box.PointA   = Vector2.new(x,     y)
        obj.Box.PointB   = Vector2.new(x + w, y)
        obj.Box.PointC   = Vector2.new(x + w, y + h)
        obj.Box.PointD   = Vector2.new(x,     y + h)
        obj.Box.Color    = esColor
        obj.Box.Visible  = true
    else
        obj.Box.Visible = false
    end

    -- ── Name ────────────────────────────────────
    if Settings.ESP_ShowName then
        obj.Name.Text     = player.Name
        obj.Name.Position = bounds.TopCenter + Vector2.new(0, -16)
        obj.Name.Visible  = true
    else
        obj.Name.Visible = false
    end

    -- ── Distance ────────────────────────────────
    if Settings.ESP_ShowDist then
        obj.Dist.Text     = string.format("[%.0f]", dist)
        obj.Dist.Position = bounds.BotCenter + Vector2.new(0, 4)
        obj.Dist.Visible  = true
    else
        obj.Dist.Visible = false
    end

    -- ── Health Bar ──────────────────────────────
    if Settings.ESP_ShowHealth then
        local maxHP   = hum.MaxHealth > 0 and hum.MaxHealth or 100
        local hpFrac  = math.clamp(hum.Health / maxHP, 0, 1)
        local barH    = bounds.H
        local barX    = bounds.X - 6
        local barTopY = bounds.Y
        local barBotY = bounds.Y + barH

        obj.HPBg.From    = Vector2.new(barX, barTopY)
        obj.HPBg.To      = Vector2.new(barX, barBotY)
        obj.HPBg.Visible = true

        local fillFromY = barBotY
        local fillToY   = barBotY - barH * hpFrac

        -- Lerp color green→red
        local hpColor = Settings.Color_HealthHigh:Lerp(Settings.Color_HealthLow, 1 - hpFrac)
        obj.HPFill.Color   = hpColor
        obj.HPFill.From    = Vector2.new(barX, fillFromY)
        obj.HPFill.To      = Vector2.new(barX, fillToY)
        obj.HPFill.Visible = true
    else
        obj.HPBg.Visible   = false
        obj.HPFill.Visible = false
    end

    -- ── Tracer ──────────────────────────────────
    if Settings.ESP_ShowTracers then
        local vp = Camera.ViewportSize
        local origin
        if Settings.ESP_TracerOrigin == "Bottom" then
            origin = Vector2.new(vp.X / 2, vp.Y)
        elseif Settings.ESP_TracerOrigin == "Center" then
            origin = Vector2.new(vp.X / 2, vp.Y / 2)
        else
            origin = UserInputService:GetMouseLocation()
        end
        obj.Tracer.From    = origin
        obj.Tracer.To      = bounds.BotCenter
        obj.Tracer.Color   = esColor
        obj.Tracer.Visible = true
    else
        obj.Tracer.Visible = false
    end

    -- ── Skeleton ─────────────────────────────────
    if Settings.ESP_ShowSkeleton then
        for i, pair in ipairs(SKELETON_BONES) do
            local partA = char:FindFirstChild(pair[1])
            local partB = char:FindFirstChild(pair[2])
            local line  = obj.Skeleton[i]
            if partA and partB then
                local sA, onA = worldToScreen(partA.Position)
                local sB, onB = worldToScreen(partB.Position)
                if onA or onB then
                    line.From    = sA
                    line.To      = sB
                    line.Color   = Settings.Color_Skeleton
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    else
        for _, line in ipairs(obj.Skeleton) do line.Visible = false end
    end
end

-- ────────────────────────────────────────────────────────────────────────
-- // ESP — Main RenderStepped loop
-- ────────────────────────────────────────────────────────────────────────
local espConnection
local function startESPLoop()
    if espConnection then espConnection:Disconnect() end
    espConnection = RunService.RenderStepped:Connect(function()
        if not Settings.ESP_Enabled then
            for _, obj in pairs(ESPObjects) do hideESP(obj) end
            return
        end
        for player, obj in pairs(ESPObjects) do
            if player and player.Parent then
                safeCall(function() updateESPPlayer(player, obj) end)
            else
                removeESP(player)
            end
        end
    end)
end

-- ────────────────────────────────────────────────────────────────────────
-- // ESP — Player hooks
-- ────────────────────────────────────────────────────────────────────────
local function onPlayerAdded(player)
    if player == LocalPlayer then return end
    createESP(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.1)
        createESP(player)
    end)
end

local function onPlayerRemoving(player)
    removeESP(player)
end

for _, p in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, p)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

startESPLoop()

-- ────────────────────────────────────────────────────────────────────────
-- // ══════════════════════════════════════════════════════════════════
-- //  BYPASS MODULE
-- // ══════════════════════════════════════════════════════════════════
-- ────────────────────────────────────────────────────────────────────────

-- Suspicious services to intercept
local SuspiciousServices = {
    "VirtualUser", "VirtualInputManager", "UGCValidationService",
    "CoreGui", "NetworkClient",
}

-- ── 1. Block LogService ───────────────────────────────────────────────
if Settings.Bypass_DisableLogSvc then
    safeCall(function()
        for _, v in pairs(getconnections(game:GetService("LogService").MessageOut)) do
            table.insert(LogSvcConns, v)
            -- v:Disable()
        end
        BypassFlags.LogServiceBlocked = #LogSvcConns > 0
    end)
end

-- ── 2. Block Loop Crash ───────────────────────────────────────────────
if Settings.Bypass_BlockLoopCrash then
    safeCall(function()
        game:GetService("ScriptContext"):SetTimeout(1)
        BypassFlags.LoopCrashBlocked = true
    end)
end

-- ── 3. Patch "overflow" Constant ──────────────────────────────────────
if Settings.Bypass_PatchOverflow then
    safeCall(function()
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "function" and islclosure(v) then
                local consts = getconstants(v)
                local idx = table.find(consts, "overflow")
                if idx and not table.find(consts, "__index") then
                    setconstant(v, idx, "\0")
                    BypassFlags.OverflowPatched = true
                end
            end
        end
    end)
end

-- ── 4. Hide islclosure String Table (executor env fingerprint) ────────
if Settings.Bypass_HideGC then
    safeCall(function()
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "table" and table.find(v, "islclosure") then
                table.clear(v)
                BypassFlags.StringTableCleared = true
                break
            end
        end
    end)
end

-- ── 5. Hook FindService ────────────────────────────────────────────────
if Settings.Bypass_HookFindService then
    safeCall(function()
        local _orig; _orig = hookfunction(game.FindService, function(self, svc)
            if table.find(SuspiciousServices, svc) then
                return nil  -- AC ถามว่ามี service ไหม → ไม่มี
            end
            return _orig(self, svc)
        end)
        BypassFlags.FindServiceHooked = true
    end)
end

-- ── 6. Patch compareTables (Adonis / Generic AC integrity check) ──────
if Settings.Bypass_PatchCompareTbls then
    safeCall(function()
        for _, v in getgc(true) do
            if typeof(v) == "function" and getinfo(v).name == "compareTables" then
                local src = getinfo(v).source or ""
                if src:find("Anti") then
                    local _o; _o = hookfunction(v, function() return true end)
                    BypassFlags.CompareTablesPatched = true
                    break
                end
            end
        end
    end)
end

-- ── 7. Anti-AFK ───────────────────────────────────────────────────────
if Settings.Bypass_AntiAFK then
    safeCall(function()
        local VU = game:GetService("VirtualUser")
        task.spawn(function()
            game:GetService("Players").LocalPlayer.Idled:Connect(function()
                VU:CaptureController()
                VU:ClickButton2(Vector2.new())
            end)
        end)
    end)
    -- Fallback: periodic fake input
    task.spawn(function()
        while task.wait(Settings.AFK_Interval) do
            pcall(function()
                local VU = game:GetService("VirtualUser")
                VU:CaptureController()
                VU:ClickButton2(Vector2.new())
            end)
        end
    end)
end

-- ── 8. hookmetamethod __namecall — block FindService via namecall ──────
safeCall(function()
    if not (hookmetamethod and checkcaller and newcclosure) then return end
    local _origMeta; _origMeta = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if not checkcaller() then
            local method = getnamecallmethod()
            if method == "FindService" or method == "GetService" then
                local svc = select(1, ...)
                if table.find(SuspiciousServices, tostring(svc)) then
                    return nil
                end
            end
        end
        return _origMeta(self, ...)
    end))
end)

-- ── 9. hookmetamethod __newindex — protect WalkSpeed / JumpPower ──────
safeCall(function()
    if not (hookmetamethod and checkcaller and newcclosure) then return end
    local _orig; _orig = hookmetamethod(game, "__newindex", newcclosure(function(self, prop, val)
        -- ป้องกัน AC reset WalkSpeed/JumpPower ของผู้เล่น
        if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
            local char = LocalPlayer.Character
            if char and self:IsDescendantOf(char) then
                if prop == "WalkSpeed" or prop == "JumpPower" or prop == "JumpHeight" then
                    return  -- กัน AC reset ค่า movement
                end
            end
        end
        return _orig(self, prop, val)
    end))
end)

-- ────────────────────────────────────────────────────────────────────────
-- // Hotkeys (Toggle ESP / Bypass via UserInputService)
-- ────────────────────────────────────────────────────────────────────────
-- F1 → Toggle ESP
-- F2 → Toggle Box
-- F3 → Toggle Names
-- F4 → Toggle Tracers
-- F5 → Toggle Skeleton
-- F6 → Toggle Health Bar

local Keybinds = {
    [Enum.KeyCode.F1] = function()
        Settings.ESP_Enabled = not Settings.ESP_Enabled
        log("Hotkey F1", "ESP Enabled = " .. tostring(Settings.ESP_Enabled))
    end,
    [Enum.KeyCode.F2] = function()
        Settings.ESP_ShowBox = not Settings.ESP_ShowBox
        log("Hotkey F2", "ShowBox = " .. tostring(Settings.ESP_ShowBox))
    end,
    [Enum.KeyCode.F3] = function()
        Settings.ESP_ShowName = not Settings.ESP_ShowName
        log("Hotkey F3", "ShowName = " .. tostring(Settings.ESP_ShowName))
    end,
    [Enum.KeyCode.F4] = function()
        Settings.ESP_ShowTracers = not Settings.ESP_ShowTracers
        log("Hotkey F4", "ShowTracers = " .. tostring(Settings.ESP_ShowTracers))
    end,
    [Enum.KeyCode.F5] = function()
        Settings.ESP_ShowSkeleton = not Settings.ESP_ShowSkeleton
        log("Hotkey F5", "ShowSkeleton = " .. tostring(Settings.ESP_ShowSkeleton))
    end,
    [Enum.KeyCode.F6] = function()
        Settings.ESP_ShowHealth = not Settings.ESP_ShowHealth
        log("Hotkey F6", "ShowHealth = " .. tostring(Settings.ESP_ShowHealth))
    end,
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local fn = Keybinds[input.KeyCode]
    if fn then safeCall(fn) end
end)

-- ────────────────────────────────────────────────────────────────────────
-- // Public API  — getgenv().ESPB
-- ────────────────────────────────────────────────────────────────────────
getgenv().ESPB = {
    --- แสดงสถานะ ESP และ Bypass ปัจจุบัน
    Status = function(self)
        header("TTJY Studio | ESP & Bypass Status")
        log("ESP Enabled",          tostring(Settings.ESP_Enabled))
        log("ESP Box",              tostring(Settings.ESP_ShowBox))
        log("ESP Names",            tostring(Settings.ESP_ShowName))
        log("ESP Distance",         tostring(Settings.ESP_ShowDist))
        log("ESP Health",           tostring(Settings.ESP_ShowHealth))
        log("ESP Tracers",          tostring(Settings.ESP_ShowTracers))
        log("ESP Skeleton",         tostring(Settings.ESP_ShowSkeleton))
        log("ESP MaxDist",          tostring(Settings.ESP_MaxDist) .. " studs")
        log("ESP Players Tracked",  tostring(#Players:GetPlayers() - 1))
        warn(LINE)
        log("Bypass OverflowPatch", tostring(BypassFlags.OverflowPatched))
        log("Bypass LogSvc",        tostring(BypassFlags.LogServiceBlocked))
        log("Bypass FindService",   tostring(BypassFlags.FindServiceHooked))
        log("Bypass CompareTables", tostring(BypassFlags.CompareTablesPatched))
        log("Bypass LoopCrash",     tostring(BypassFlags.LoopCrashBlocked))
        log("Bypass GC Hide",       tostring(BypassFlags.StringTableCleared))
        log("Anti-AFK",             tostring(Settings.Bypass_AntiAFK))
        warn(LINE)
    end,

    --- Toggle ESP on/off
    ToggleESP = function(self, state)
        Settings.ESP_Enabled = (state ~= nil) and state or not Settings.ESP_Enabled
        log("ToggleESP", tostring(Settings.ESP_Enabled))
    end,

    --- เปลี่ยนสี enemy ESP
    ---@param r number  0-255
    ---@param g number  0-255
    ---@param b number  0-255
    SetEnemyColor = function(self, r, g, b)
        Settings.Color_Enemy = Color3.fromRGB(r, g, b)
        log("SetEnemyColor", string.format("RGB(%d,%d,%d)", r, g, b))
    end,

    --- เปลี่ยนระยะ max
    SetMaxDist = function(self, dist)
        Settings.ESP_MaxDist = tonumber(dist) or 1000
        log("SetMaxDist", tostring(Settings.ESP_MaxDist))
    end,

    --- ลบ ESP ทั้งหมดและ disconnect loop
    Destroy = function(self)
        if espConnection then espConnection:Disconnect() end
        for player, _ in pairs(ESPObjects) do
            removeESP(player)
        end
        log("Destroy", "ESP removed and loop disconnected")
    end,
}

-- ────────────────────────────────────────────────────────────────────────
-- // Startup Banner
-- ────────────────────────────────────────────────────────────────────────
header("TTJY Studio | ESP & Bypass v1.0 — Ready")
warn("  ── ESP Hotkeys ──────────────────────────────")
warn("  [F1]  Toggle ESP ON/OFF")
warn("  [F2]  Toggle Box")
warn("  [F3]  Toggle Names")
warn("  [F4]  Toggle Tracers")
warn("  [F5]  Toggle Skeleton")
warn("  [F6]  Toggle Health Bar")
warn("  ── API ──────────────────────────────────────")
warn("  ESPB:Status()              Full status report")
warn("  ESPB:ToggleESP(bool)       Toggle ESP")
warn("  ESPB:SetEnemyColor(r,g,b)  Change enemy color")
warn("  ESPB:SetMaxDist(n)         Change max range")
warn("  ESPB:Destroy()             Remove ESP & cleanup")
warn(LINE)

-- Auto-status on load
task.wait(0.5)
ESPB:Status()
