-- ========================================================
-- // fame pl.lua
-- // Auto Farm & Auto Quest for Bandit Leader
-- ========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

getgenv().AutoFarm = false
getgenv().FarmDistance = 10 -- ระยะห่างในการโจมตี (ความสูงจากหัวมอน)
getgenv().FarmDistanceY = true -- ให้ลอยอยู่ด้านบน (true) หรืออยู่ด้านหลัง (false)

-- ========================================================
-- // Remotes
-- ========================================================
local function getQuestEvent()
    local p = ReplicatedStorage:FindFirstChild("Packages")
    if p then
        local idx = p:FindFirstChild("_Index")
        if idx then
            local slt = idx:FindFirstChild("sleitnick_net@0.2.0")
            if slt then
                return slt.net:FindFirstChild("RE/QuestEvent")
            end
        end
    end
    return nil
end

local function getActionRemote()
    local p = ReplicatedStorage:FindFirstChild("Packages")
    if p then
        local idx = p:FindFirstChild("_Index")
        if idx then
            local slt = idx:FindFirstChild("sleitnick_net@0.2.0")
            if slt then
                return slt.net:FindFirstChild("RE/ActionRemote")
            end
        end
    end
    return nil
end

-- ========================================================
-- // UI Setup
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
                        if typeof(writefile) == "function" then
                            pcall(function() writefile("HYPER_Cache/ui.lua", src) end)
                        end
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
local UIS = game:GetService("UserInputService")
local WindowSize = UIS.TouchEnabled and UDim2.fromOffset(550, 550) or UDim2.fromOffset(570,450)


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

    Title = "Fame PL Hub",
    Desc = "Auto Farm Bandit Leader",
    Icon = 115975178132422,
    Theme = "Amethyst",
    Config = {
        Keybind = Enum.KeyCode.RightShift,
        Size = WindowSize
    },
    CloseUIButton = {
        Enabled = true,
        Text = "Close"
    }
})

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "home"
})

MainTab:Toggle({
    Title = "Auto Farm (Bandit Leader)",
    Desc = "รับเควสและบินตีมอนออโต้",
    Value = getgenv().AutoFarm,
    Callback = function(val)
        getgenv().AutoFarm = val
        if val then
            -- รับเควส 1 ครั้งตอนเปิดสวิตช์
            pcall(function()
                local qEvent = getQuestEvent()
                if qEvent then qEvent:FireServer("Request", { Id = 2 }) end
            end)
        else
            -- ทำความสะอาดถ้ายกเลิก
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local bv = char.HumanoidRootPart:FindFirstChild("AutoFarm_BV")
                if bv then bv:Destroy() end
            end
            getgenv().LastTarget = nil
        end
    end
})

MainTab:Slider({
    Title = "Attack Distance",
    Default = 10,
    Min = 0,
    Max = 30,
    Callback = function(val)
        getgenv().FarmDistance = tonumber(val) or 10
    end
})

MainTab:Toggle({
    Title = "Float Above Monster (Y-Axis)",
    Desc = "ตีจากด้านบนหัวมอน (ปิด = ตีจากด้านหลัง)",
    Value = getgenv().FarmDistanceY,
    Callback = function(val)
        getgenv().FarmDistanceY = val
    end
})

MainTab:Button({
    Title = "Stop Script",
    Desc = "ปิดการทำงาน",
    Callback = function()
        getgenv().AutoFarm = false
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local bv = char.HumanoidRootPart:FindFirstChild("AutoFarm_BV")
            if bv then bv:Destroy() end
        end
        local cg = game:GetService("CoreGui")
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if cg and cg:FindFirstChild("Dummy Kawaii") then cg["Dummy Kawaii"]:Destroy() end
        if pg and pg:FindFirstChild("Dummy Kawaii") then pg["Dummy Kawaii"]:Destroy() end
    end
})


-- ========================================================
-- // Main Loops
-- ========================================================

local function hasQuest()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return false end
    
    -- วิธีที่ 1: หาจากโครงสร้าง Quest > Container ที่อยู่ใน ScreenGui ใดๆ
    for _, gui in pairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") then
            local q = gui:FindFirstChild("Quest") or gui:FindFirstChild("quest")
            if q then
                local cont = q:FindFirstChild("Container")
                if cont then
                    -- เช็คว่า Container ถูกแสดงผลอยู่บนหน้าจอหรือไม่ (บางเกมใช้ Visible, บางเกมเอาออกนอกจอ)
                    if cont.Visible and q.Visible then
                        return true
                    end
                end
            end
        end
    end
    
    -- วิธีที่ 2 (สำรองแบบเจาะลึกสุดๆ): หาข้อความบนจอที่มีคำว่า Bandit Leader
    for _, obj in pairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton") then
            if obj.Text and string.find(string.lower(obj.Text), "bandit leader") then
                -- เช็คว่ามันและ parent ของมันกำลัง Visible อยู่
                local isVisible = true
                local current = obj
                while current and current:IsA("GuiObject") do
                    if not current.Visible then
                        isVisible = false
                        break
                    end
                    current = current.Parent
                end
                
                if isVisible then
                    return true
                end
            end
        end
    end
    
    return false
end

-- 1. Auto Quest Loop
task.spawn(function()
    while task.wait(1) do
        if getgenv().AutoFarm and not hasQuest() then
            pcall(function()
                local qEvent = getQuestEvent()
                if qEvent then
                    qEvent:FireServer("Request", { Id = 2 })
                end
            end)
        end
    end
end)

-- 2. Auto Attack (M1) Loop
task.spawn(function()
    while task.wait(0.1) do
        if getgenv().AutoFarm then
            pcall(function()
                local aEvent = getActionRemote()
                if aEvent then
                    aEvent:FireServer("M1", "Combat")
                end
            end)
        end
    end
end)

-- 3. Teleport & Float (Noclip) Loop
RunService.Stepped:Connect(function()
    if getgenv().AutoFarm then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        -- ถ้ายังไม่มีเควส ให้หยุดบินแล้วรอ
        if not hasQuest() then
            local bv = hrp:FindFirstChild("AutoFarm_BV")
            if bv then bv:Destroy() end
            return
        end
        
        -- Noclip (กันตัวเราชนกำแพงหรือเด้งเวลาบิน)
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
        
        -- หา Bandit Leader ที่อยู่ใน Workspace > Enemies
        local enemiesFolder = Workspace:FindFirstChild("Enemies")
        if enemiesFolder then
            local target = nil
            local shortestDist = math.huge
            
            for _, v in pairs(enemiesFolder:GetChildren()) do
                -- ใช้ string.find เผื่อชื่อมอนสเตอร์มีเลเวลต่อท้าย เช่น "Bandit Leader [Lv.50]"
                if v.Name:match("Bandit Leader") or string.find(v.Name, "Bandit Leader") then
                    local hum = v:FindFirstChild("Humanoid")
                    local mobHrp = v:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and mobHrp then
                        local mag = (hrp.Position - mobHrp.Position).Magnitude
                        if mag < shortestDist then
                            shortestDist = mag
                            target = v
                        end
                    end
                end
            end
            
            -- ถ้าเจอมอนเตอร์
            if target then
                local mobHrp = target:FindFirstChild("HumanoidRootPart")
                local dist = getgenv().FarmDistance
                
                -- ล็อก BodyVelocity ให้ไม่ตกลงมา
                local bv = hrp:FindFirstChild("AutoFarm_BV")
                if not bv then
                    bv = Instance.new("BodyVelocity")
                    bv.Name = "AutoFarm_BV"
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv.Velocity = Vector3.new(0, 0, 0)
                    bv.Parent = hrp
                end
                
                -- คำนวณตำแหน่ง
                local targetCFrame
                if getgenv().FarmDistanceY then
                    -- บินอยู่ด้านบนหัวมอนเตอร์ (ยืนตัวตรง ไม่ก้มหน้าจนบัค)
                    targetCFrame = mobHrp.CFrame * CFrame.new(0, dist, 0)
                else
                    -- บินอยู่ด้านหลังมอนเตอร์
                    targetCFrame = mobHrp.CFrame * CFrame.new(0, 0, dist)
                end
                
                -- วาปไปตำแหน่งที่คำนวณไว้
                hrp.CFrame = targetCFrame
            else
                -- ถ้าไม่มีมอนเตอร์บนแมพ ให้ค้างไว้ที่เดิมหรือลบ BV เพื่อตกลงพื้น
                local bv = hrp:FindFirstChild("AutoFarm_BV")
                if bv then
                    bv.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end
end)
