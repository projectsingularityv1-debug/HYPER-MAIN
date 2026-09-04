local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- =====================================
-- // UI — KT_UI-V1 Library
-- =====================================
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
            "https://raw.githubusercontent.com/projectsingularityv1-debug/Scripts.xinz/refs/heads/main/ui.lua",
            "https://projectsingularity.online/raw/repos/191c9695-c9f9-4b5f-805f-d87e8e3b8fac/ui.lua"
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

    Title = "LK AUTO",
    Desc = "Quest Auto Farm",
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

-- ตัวแปรตั้งค่าต่างๆ
getgenv().LK_AutoFarm = false
getgenv().LK_SelectedQuest = "Kill 4 Soldiers"
getgenv().LK_SelectedMonster = "Soldier"
getgenv().LK_FarmDistance = 7

MainTab:Textbox({
    Title = "Quest Name (ชื่อเควส)",
    Value = getgenv().LK_SelectedQuest,
    Callback = function(val)
        getgenv().LK_SelectedQuest = val
    end
})

local function GetMonsterList()
    local list = {}
    local check = {}
    local folder = Workspace:FindFirstChild("Monster") and Workspace.Monster:FindFirstChild("Mon")
    if folder then
        for _, v in ipairs(folder:GetChildren()) do
            if not check[v.Name] then
                check[v.Name] = true
                table.insert(list, v.Name)
            end
        end
    end
    table.sort(list)
    if #list == 0 then table.insert(list, getgenv().LK_SelectedMonster) end
    return list
end

local MonsterDropdown = MainTab:Dropdown({
    Title = "Select Monster (เลือกมอนสเตอร์)",
    List = GetMonsterList(),
    Value = getgenv().LK_SelectedMonster,
    Callback = function(val)
        getgenv().LK_SelectedMonster = val
    end
})

MainTab:Button({
    Title = "Refresh Monster List (รีเฟรชรายชื่อ)",
    Callback = function()
        pcall(function()
            MonsterDropdown:Clear()
            local newList = GetMonsterList()
            for _, item in ipairs(newList) do
                MonsterDropdown:Add(item)
            end
        end)
    end
})

MainTab:Textbox({
    Title = "Distance (ระยะห่างจากหัวมอน)",
    Value = tostring(getgenv().LK_FarmDistance),
    Callback = function(val)
        getgenv().LK_FarmDistance = tonumber(val) or 7
    end
})

MainTab:Toggle({
    Title = "Fast Attack (ตีเร็ว & ข้ามอนิเมชัน)",
    Desc = "เคลียร์คูลดาวน์และเพิ่มความเร็วอนิเมชันฟัน",
    Value = getgenv().LK_FastAttack == nil and true or getgenv().LK_FastAttack,
    Callback = function(val)
        getgenv().LK_FastAttack = val
    end
})

MainTab:Toggle({
    Title = "Auto Farm",
    Desc = "เปิดบอทรับเควสและบินไปตีมอนบนหัว",
    Value = getgenv().LK_AutoFarm,
    Callback = function(val)
        getgenv().LK_AutoFarm = val
        if not val then
            local char = LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local bv = hrp:FindFirstChild("LK_AutoFarm_BV")
                    if bv then bv:Destroy() end
                    hrp.Velocity = Vector3.zero
                end
                
                -- คืนค่าการเดินชนกำแพงกลับมาเป็นปกติ
                for _, partName in ipairs({"HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "Head"}) do
                    local p = char:FindFirstChild(partName)
                    if p then p.CanCollide = true end
                end
                
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.PlatformStand = false end
            end
        end
    end
})

local StatsTab = Window:Tab({
    Title = "Stats",
    Icon = "bar-chart"
})

getgenv().LK_AutoStats = getgenv().LK_AutoStats or {
    Melee = false,
    Health = false,
    Sword = false,
    Fruit = false
}
getgenv().LK_StatsPointAmount = getgenv().LK_StatsPointAmount or 10

StatsTab:Textbox({
    Title = "Points to Add (จำนวนพอยท์ต่อครั้ง)",
    Value = tostring(getgenv().LK_StatsPointAmount),
    Callback = function(val)
        getgenv().LK_StatsPointAmount = tonumber(val) or 10
    end
})

for _, stat in ipairs({"Melee", "Health", "Sword", "Fruit"}) do
    StatsTab:Toggle({
        Title = "Auto " .. stat,
        Value = getgenv().LK_AutoStats[stat],
        Callback = function(val)
            getgenv().LK_AutoStats[stat] = val
        end
    })
end

-- =====================================
-- // ระบบ Auto Farm Core
-- =====================================
local function equipWeapon()
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") then
                item.Parent = char
                break
            end
        end
    end
end

local function attack()
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
    end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new())
    
    -- ส่งคำสั่งตีไปยังเซิร์ฟเวอร์
    task.spawn(function()
        pcall(function()
            local Event = ReplicatedStorage:FindFirstChild("Chest") 
                          and ReplicatedStorage.Chest:FindFirstChild("Remotes") 
                          and ReplicatedStorage.Chest.Remotes:FindFirstChild("Functions")
                          and ReplicatedStorage.Chest.Remotes.Functions:FindFirstChild("SkillAction")
            if Event then
                Event:InvokeServer("FS_None_M1")
            end
        end)
    end)
end

local function getQuest()
    local Event = ReplicatedStorage:FindFirstChild("Chest") 
                  and ReplicatedStorage.Chest:FindFirstChild("Remotes") 
                  and ReplicatedStorage.Chest.Remotes:FindFirstChild("Functions")
                  and ReplicatedStorage.Chest.Remotes.Functions:FindFirstChild("Quest")
    
    if Event then
        if not getgenv().LK_LastQuestTake or tick() - getgenv().LK_LastQuestTake > 3 then
            getgenv().LK_LastQuestTake = tick()
            task.spawn(function()
                pcall(function()
                    Event:InvokeServer("take", getgenv().LK_SelectedQuest)
                end)
            end)
        end
    end
end

local function getClosestMonster()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local targetMon = nil
    local shortestDist = math.huge
    local monstersFolder = Workspace:FindFirstChild("Monster") and Workspace.Monster:FindFirstChild("Mon")

    if monstersFolder then
        for _, mon in ipairs(monstersFolder:GetChildren()) do
            local monNameMatches = (getgenv().LK_SelectedMonster == "" or mon.Name == getgenv().LK_SelectedMonster)
            if monNameMatches then
                local mHRP = mon:FindFirstChild("HumanoidRootPart")
                local mHum = mon:FindFirstChildOfClass("Humanoid")
                
                if mHRP and mHum and mHum.Health > 0 then
                    local dist = (hrp.Position - mHRP.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        targetMon = mon
                    end
                end
            end
        end
    end
    
    return targetMon
end

task.spawn(function()
    while task.wait() do
        if getgenv().LK_AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    local targetMon = getClosestMonster()
                    
                    if targetMon then
                        local mHRP = targetMon:FindFirstChild("HumanoidRootPart")
                        if mHRP then
                            local bv = hrp:FindFirstChild("LK_AutoFarm_BV")
                            if not bv then
                                bv = Instance.new("BodyVelocity")
                                bv.Name = "LK_AutoFarm_BV"
                                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                bv.Parent = hrp
                            end
                            bv.Velocity = Vector3.zero
                            
                            local flyPos = mHRP.Position + Vector3.new(0, getgenv().LK_FarmDistance, 0)
                            hrp.CFrame = CFrame.lookAt(flyPos, mHRP.Position)
                            
                            equipWeapon()
                            attack()
                            
                            getQuest()
                        end
                    else
                        getQuest()
                    end
                end
            end)
        end
    end
end)

RunService.Stepped:Connect(function()
    if getgenv().LK_AutoFarm then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- ระบบตีเร็ว & ข้ามอนิเมชัน (Fast Attack / No Cooldown)
getgenv().LK_FastAttack = getgenv().LK_FastAttack == nil and true or getgenv().LK_FastAttack
task.spawn(function()
    while task.wait() do
        if getgenv().LK_FastAttack then
            pcall(function()
                -- ลบคูลดาวน์โดยใช้ฟังก์ชัน ForceResetCooldown ของตัวเกม
                if _G.Cooldowns then
                    _G.Cooldowns.ForceResetCooldown = true
                end
                
                -- เร่งความเร็วอนิเมชันให้ตีจบในพริบตา
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local animator = hum:FindFirstChildOfClass("Animator") or hum
                        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                            local name = string.lower(track.Name)
                            if string.find(name, "swing") or string.find(name, "attack") or string.find(name, "combat") or string.find(name, "hit") then
                                track:AdjustSpeed(100)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ระบบ Auto Stats อัพสเตตัสอัตโนมัติ
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local Event = LocalPlayer:FindFirstChild("PlayerGui")
                          and LocalPlayer.PlayerGui:FindFirstChild("MainGui")
                          and LocalPlayer.PlayerGui.MainGui:FindFirstChild("StarterFrame")
                          and LocalPlayer.PlayerGui.MainGui.StarterFrame:FindFirstChild("StatsFrame")
                          and LocalPlayer.PlayerGui.MainGui.StarterFrame.StatsFrame:FindFirstChild("RemoteEvent")
            
            if Event then
                for stat, isEnabled in pairs(getgenv().LK_AutoStats) do
                    if isEnabled then
                        Event:FireServer(stat, getgenv().LK_StatsPointAmount)
                        task.wait(0.1) -- ดีเลย์เล็กน้อยระหว่างการอัพแต่ละสเตตัส
                    end
                end
            end
        end)
    end
end)
