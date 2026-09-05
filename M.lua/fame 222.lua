local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- =====================================
-- // ระบบป้องกันรันซ้อนและปุ่มปิด (Anti-Overlap & Stop)
-- =====================================
if getgenv().CrystalFarm_Disconnect then
    pcall(function() getgenv().CrystalFarm_Disconnect() end)
end

getgenv().CrystalFarm_Running = true
getgenv().CrystalFarm_Connections = {}
getgenv().CrystalFarm_ESP_Objects = {}
getgenv().CrystalFarm_Blacklist = getgenv().CrystalFarm_Blacklist or {}
getgenv().GodModeEnabled = getgenv().GodModeEnabled or false
getgenv().AutoGoHome = getgenv().AutoGoHome or false
getgenv().NoSwingCooldown = getgenv().NoSwingCooldown or false
getgenv().AutoDigTerrain = getgenv().AutoDigTerrain or false
getgenv().DigSpeed = getgenv().DigSpeed or 350
getgenv().TargetMaterial = getgenv().TargetMaterial or "Volcano Basalt"
getgenv().DigRadius = getgenv().DigRadius or 30

-- ระบบเบื้องหลัง (God Mode & Player Highlight)
task.spawn(function()
    while getgenv().CrystalFarm_Running do
        task.wait(0.1)
        local char = LocalPlayer.Character
        if char then
            -- God Mode
            if getgenv().GodModeEnabled then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then
                    hum.Health = hum.MaxHealth
                end
            end
            
            -- Player Highlight (Orange) ทำงานตลอดเวลา
            local hl = char:FindFirstChild("SelfHighlightESP")
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = "SelfHighlightESP"
                hl.FillColor = Color3.fromRGB(255, 128, 0) -- สีส้ม
                hl.FillTransparency = 0.5
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.OutlineTransparency = 0.2
                hl.Parent = char
            end
        end
    end
end)

-- Auto Go Home Loop
task.spawn(function()
    while getgenv().CrystalFarm_Running do
        task.wait(1)
        if getgenv().AutoGoHome then
            pcall(function()
                local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                if remotes and remotes:FindFirstChild("GoHome") then
                    remotes.GoHome:FireServer("home")
                end
            end)
        end
    end
end)

-- Auto Dig Terrain Loop
task.spawn(function()
    while getgenv().CrystalFarm_Running do
        if getgenv().AutoDigTerrain then
            task.wait()
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if hrp and getgenv().DigCenter then
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {Workspace.Terrain}
                params.FilterType = Enum.RaycastFilterType.Include
                
                local center = getgenv().DigCenter
                local closestPos = nil
                local shortestDist = math.huge
                local scanStep = 4
                local radius = getgenv().DigRadius
                
                getgenv().DigBlacklist = getgenv().DigBlacklist or {}
                getgenv().DigAttemptCounts = getgenv().DigAttemptCounts or {}
                
                local checks = 0
                for x = -radius, radius, scanStep do
                    for z = -radius, radius, scanStep do
                        checks = checks + 1
                        -- ให้หยุดพักให้คอมพิวเตอร์หายใจทุกๆ 150 การสแกน (กันคอมค้างเมื่อปรับรัศมีใหญ่ๆ)
                        if checks % 150 == 0 then
                            task.wait()
                            if not getgenv().AutoDigTerrain or not getgenv().CrystalFarm_Running then break end
                        end
                        
                        if (x*x + z*z) <= (radius * radius) then
                            local origin = Vector3.new(center.X + x, center.Y + 50, center.Z + z)
                            local result = Workspace:Raycast(origin, Vector3.new(0, -150, 0), params)
                            if result and result.Instance == Workspace.Terrain then
                                local rp = result.Position
                                local rPos = Vector3.new(math.floor(rp.X/4)*4, math.floor(rp.Y/4)*4, math.floor(rp.Z/4)*4)
                                local key = tostring(rPos)
                                
                                if not getgenv().DigBlacklist[key] then
                                    local dist = (Vector3.new(rp.X, hrp.Position.Y, rp.Z) - hrp.Position).Magnitude
                                    if dist < shortestDist then
                                        shortestDist = dist
                                        closestPos = rp
                                    end
                                end
                            end
                        end
                    end
                    if not getgenv().AutoDigTerrain or not getgenv().CrystalFarm_Running then break end
                end
                
                local bestCrystal = nil
                local CrystalsFolder = workspace:FindFirstChild("Crystals")
                if CrystalsFolder then
                    for _, crystal in pairs(CrystalsFolder:GetChildren()) do
                        local prompt = crystal:FindFirstChildWhichIsA("ProximityPrompt", true)
                        local crystalPart = crystal.PrimaryPart or crystal:FindFirstChildWhichIsA("BasePart")
                        if prompt and crystalPart then
                            local price = 0
                            local ui = crystal:FindFirstChild("CrystalUI", true) or crystal:FindFirstChildWhichIsA("BillboardGui", true)
                            if ui and ui:FindFirstChild("Frame") and ui.Frame:FindFirstChild("Price") then
                                local pTxt = string.gsub(ui.Frame.Price.Text, "[%$%,]", "")
                                pTxt = string.gsub(string.lower(pTxt), "kg", "")
                                local currStr, currMult = string.match(pTxt, "([%d%.]+)([kmb]*)")
                                if currStr then
                                    price = tonumber(currStr) or 0
                                    if string.find(currMult, "k") then price = price * 1000
                                    elseif string.find(currMult, "m") then price = price * 1000000
                                    elseif string.find(currMult, "b") then price = price * 1000000000 end
                                end
                            end
                            
                            if price >= (getgenv().CrystalFarm_MinPrice or 0) then
                                local distFromHRP = (crystalPart.Position - hrp.Position).Magnitude
                                if distFromHRP <= radius then
                                    bestCrystal = crystal
                                    break
                                end
                            end
                        end
                    end
                end
                
                if bestCrystal then
                    local crystalPart = bestCrystal.PrimaryPart or bestCrystal:FindFirstChildWhichIsA("BasePart")
                    local flyPos = crystalPart.Position + Vector3.new(0, 3.5, 0)
                    local distance = (hrp.Position - flyPos).Magnitude
                    
                    local bv = hrp:FindFirstChild("AutoDig_BV")
                    if not bv then
                        bv = Instance.new("BodyVelocity")
                        bv.Name = "AutoDig_BV"
                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bv.Velocity = Vector3.zero
                        bv.Parent = hrp
                    end
                    
                    if distance > 10 then
                        local tweenTime = distance / getgenv().DigSpeed
                        local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
                        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(flyPos)})
                        tween:Play()
                        local t = 0
                        while tween.PlaybackState == Enum.PlaybackState.Playing and t < 2 do
                            task.wait()
                            t = t + 0.015
                            if not getgenv().AutoDigTerrain or not getgenv().CrystalFarm_Running then break end
                        end
                        tween:Cancel()
                    end
                    
                    hrp.Anchored = true
                    local prompt = bestCrystal:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        fireproximityprompt(prompt, 1)
                    end
                    task.wait(0.2)
                    hrp.Anchored = false
                elseif closestPos then
                    local flyPos = closestPos + Vector3.new(0, 4, 0)
                    local distance = (hrp.Position - flyPos).Magnitude
                    
                    local bv = hrp:FindFirstChild("AutoDig_BV")
                    if not bv then
                        bv = Instance.new("BodyVelocity")
                        bv.Name = "AutoDig_BV"
                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bv.Velocity = Vector3.zero
                        bv.Parent = hrp
                    end
                    
                    -- บินไปหาเมื่ออยู่ไกลกว่า 10 studs (ถ้าน้อยกว่านั้นแปลว่าอยู่ในระยะที่เอื้อมถึง จะได้ขุดรัวๆ ไม่เสียเวลาบิน)
                    if distance > 10 then
                        local tweenTime = distance / getgenv().DigSpeed
                        local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
                        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(flyPos)})
                        tween:Play()
                        local t = 0
                        while tween.PlaybackState == Enum.PlaybackState.Playing and t < 2 do
                            task.wait()
                            t = t + 0.015
                            if not getgenv().AutoDigTerrain or not getgenv().CrystalFarm_Running then break end
                        end
                        tween:Cancel()
                    end
                    
                    if getgenv().AutoDigTerrain and getgenv().CrystalFarm_Running then
                        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                        if remotes and remotes:FindFirstChild("DigRequest") then
                            local tool = character:FindFirstChildOfClass("Tool")
                            if tool then
                                -- ระเบิดหลุมใหญ่ใน 1 ที โดยการส่งคำสั่งขุดจุดรอบๆ ไปพร้อมกัน
                                remotes.DigRequest:FireServer(tool.Name, closestPos)
                                remotes.DigRequest:FireServer(tool.Name, closestPos + Vector3.new(4, 0, 0))
                                remotes.DigRequest:FireServer(tool.Name, closestPos + Vector3.new(-4, 0, 0))
                                remotes.DigRequest:FireServer(tool.Name, closestPos + Vector3.new(0, 0, 4))
                                remotes.DigRequest:FireServer(tool.Name, closestPos + Vector3.new(0, 0, -4))
                                remotes.DigRequest:FireServer(tool.Name, closestPos + Vector3.new(0, -4, 0))
                            end
                            
                            local rPos = Vector3.new(math.floor(closestPos.X/4)*4, math.floor(closestPos.Y/4)*4, math.floor(closestPos.Z/4)*4)
                            local key = tostring(rPos)
                            getgenv().DigAttemptCounts[key] = (getgenv().DigAttemptCounts[key] or 0) + 1
                            
                            -- ถ้าพยายามขุดที่เดิม 50 ครั้ง (สแปมรัวๆ ประมาณ 1 วิ) แล้วยังอยู่ แสดงว่าเป็นหินที่ขุดไม่ได้
                            if getgenv().DigAttemptCounts[key] >= 50 then
                                getgenv().DigBlacklist[key] = true
                            end
                        end
                        -- ไม่มี Cooldown แล้ว ทำให้มันสแปมขุดรัวๆ ได้เลย
                    end
                else
                    task.wait(1)
                end
            else
                task.wait(1)
            end
        else
            task.wait(0.5)
        end
    end
end)

-- No Animation (Fast Attack / No Cooldown)
task.spawn(function()
    while true do
        task.wait()
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                if getgenv().CrystalFarm_Running and (getgenv().AutoFarm or getgenv().AutoDigTerrain) then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local animator = hum:FindFirstChildOfClass("Animator") or hum
                        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                            local name = track.Name:lower()
                            -- ข้ามอนิเมชั่นการโจมตี/ขุด ทำให้เล่นจบในพริบตา
                            if name:find("swing") or name:find("hit") or name:find("mine") or name:find("dig") or name:find("attack") or name:find("tool") then
                                track:AdjustSpeed(100) 
                            end
                        end
                    end
                end
                
                if getgenv().NoSwingCooldown then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool and not tool:GetAttribute("NoSwingCooldown") then
                        tool:SetAttribute("NoSwingCooldown", true)
                    end
                end
            end
        end)
    end
end)

getgenv().CrystalFarm_MinPrice = getgenv().CrystalFarm_MinPrice or 0
getgenv().CrystalFarm_MinY = getgenv().CrystalFarm_MinY or -99999999999
getgenv().CrystalFarm_MaxY = getgenv().CrystalFarm_MaxY or 999999999999
getgenv().CrystalFarm_Rarity = getgenv().CrystalFarm_Rarity or {
    ["[S]"] = true, ["[M]"] = true, ["[L]"] = true, ["[Giant]"] = true, ["[Titan]"] = true
}

getgenv().CrystalFarm_UseFilters = getgenv().CrystalFarm_UseFilters == nil and true or getgenv().CrystalFarm_UseFilters
getgenv().CrystalFarm_Mode = getgenv().CrystalFarm_Mode or "Expensive First"
getgenv().CrystalFarm_AutoUpgrade = getgenv().CrystalFarm_AutoUpgrade == nil and false or getgenv().CrystalFarm_AutoUpgrade
getgenv().CrystalFarm_DebugLogging = getgenv().CrystalFarm_DebugLogging == nil and false or getgenv().CrystalFarm_DebugLogging

getgenv().ESP_MaxDistance = getgenv().ESP_MaxDistance or 300
getgenv().ESP_Enabled = getgenv().ESP_Enabled == nil and true or getgenv().ESP_Enabled
getgenv().ESP_ShowHighlight = getgenv().ESP_ShowHighlight == nil and true or getgenv().ESP_ShowHighlight
getgenv().ESP_ShowText = getgenv().ESP_ShowText == nil and true or getgenv().ESP_ShowText

getgenv().ESP_ShowName = getgenv().ESP_ShowName == nil and true or getgenv().ESP_ShowName
getgenv().ESP_ShowWeight = getgenv().ESP_ShowWeight == nil and true or getgenv().ESP_ShowWeight
getgenv().ESP_ShowPrice = getgenv().ESP_ShowPrice == nil and true or getgenv().ESP_ShowPrice
getgenv().ESP_ShowDistance = getgenv().ESP_ShowDistance == nil and true or getgenv().ESP_ShowDistance

getgenv().ESP_UseRarityFilter = getgenv().ESP_UseRarityFilter == nil and false or getgenv().ESP_UseRarityFilter
getgenv().ESP_ShowRarities = getgenv().ESP_ShowRarities or {
    ["[S]"] = true, ["[M]"] = true, ["[L]"] = true, ["[Giant]"] = true, ["[Titan]"] = true
}
getgenv().CrystalFarm_Disconnect = function()
    getgenv().CrystalFarm_Running = false
    getgenv().AutoFarm = false
    
    -- ยกเลิกการบินปัจจุบันทันทีถ้ามี
    if getgenv().CrystalFarm_CurrentTween then
        pcall(function() getgenv().CrystalFarm_CurrentTween:Cancel() end)
        getgenv().CrystalFarm_CurrentTween = nil
    end
    
    -- คืนค่าตัวละคร (ปิด GhostFly)
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bv = hrp:FindFirstChild("AutoFarm_GhostFlyBV")
            if bv then bv:Destroy() end
            local bg = hrp:FindFirstChild("AutoFarm_GhostFlyBG")
            if bg then bg:Destroy() end
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
            hrp.Anchored = false
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    
    -- ลบข้อความ ESP และ Highlight บนหน้าจอ
    for _, espObj in pairs(getgenv().CrystalFarm_ESP_Objects) do
        if espObj then
            if typeof(espObj) == "Instance" then
                espObj:Destroy()
            else
                espObj:Remove()
            end
        end
    end
    getgenv().CrystalFarm_ESP_Objects = {}
    getgenv().CrystalFarm_Blacklist = {}
    
    -- ลบ Event Connections
    for _, conn in pairs(getgenv().CrystalFarm_Connections) do
        if conn then conn:Disconnect() end
    end
    getgenv().CrystalFarm_Connections = {}
    if getgenv().CrystalFarm_StopGui then
        getgenv().CrystalFarm_StopGui:Destroy()
        getgenv().CrystalFarm_StopGui = nil
    end
    
    if getgenv().DigZoneVisual then
        getgenv().DigZoneVisual:Destroy()
        getgenv().DigZoneVisual = nil
    end
    
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bv = hrp:FindFirstChild("AutoDig_BV")
            if bv then bv:Destroy() end
        end
    end
    
    local cg = game:GetService("CoreGui")
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if cg and cg:FindFirstChild("Dummy Kawaii") then
        cg:FindFirstChild("Dummy Kawaii"):Destroy()
    end
    if pg and pg:FindFirstChild("Dummy Kawaii") then
        pg:FindFirstChild("Dummy Kawaii"):Destroy()
    end
    
    print("Crystal Farm: Stopped and Cleaned up!")
end

-- =====================================
-- // UI — KT_UI-V1 Library
-- =====================================
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

    Title = "HYPER HUB",
    Desc = "Auto Farm Script [BATA]",
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

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "home"
})

MainTab:Toggle({
    Title = "Auto Farm",
    Desc = "Enable/Disable Auto Farm",
    Value = getgenv().AutoFarm,
    Callback = function(val)
        getgenv().AutoFarm = val
        if not val then
            -- ยกเลิกการบินปัจจุบันและเบรคตัวละครให้หยุด
            if getgenv().CrystalFarm_CurrentTween then
                getgenv().CrystalFarm_CurrentTween:Cancel()
                getgenv().CrystalFarm_CurrentTween = nil
            end
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local bv = hrp:FindFirstChild("AutoFarm_GhostFlyBV")
                if bv then bv:Destroy() end
                local bg = hrp:FindFirstChild("AutoFarm_GhostFlyBG")
                if bg then bg:Destroy() end
                hrp.Velocity = Vector3.zero
            end
        end
    end
})

MainTab:Button({
    Title = "Upgrade Air",
    Desc = "Buy 1 Air Upgrade",
    Callback = function()
        local event = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("UpgradeBuy")
        if event then event:FireServer("Air", 1) end
    end
})

MainTab:Button({
    Title = "Upgrade Weight",
    Desc = "Buy 1 Weight Upgrade",
    Callback = function()
        local event = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("UpgradeBuy")
        if event then event:FireServer("Weight", 1) end
    end
})

MainTab:Toggle({
    Title = "God Mode",
    Desc = "Auto heal / Prevent death",
    Value = getgenv().GodModeEnabled,
    Callback = function(val)
        getgenv().GodModeEnabled = val
    end
})

MainTab:Toggle({
    Title = "No Swing Cooldown",
    Desc = "Removes cooldown for manual tool mining",
    Value = getgenv().NoSwingCooldown,
    Callback = function(val)
        getgenv().NoSwingCooldown = val
    end
})

MainTab:Toggle({
    Title = "Auto Go Home",
    Desc = "Automatically teleport to home",
    Value = getgenv().AutoGoHome,
    Callback = function(val)
        getgenv().AutoGoHome = val
    end
})

MainTab:Button({
    Title = "Teleport Home",
    Desc = "Teleports you to home base",
    Callback = function()
        pcall(function()
            local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("GoHome") then
                remotes.GoHome:FireServer("home")
            end
        end)
    end
})

MainTab:Toggle({
    Title = "Auto Dig Terrain",
    Desc = "Digs terrain in a specified radius (Sets zone at current pos)",
    Value = getgenv().AutoDigTerrain,
    Callback = function(val)
        getgenv().AutoDigTerrain = val
        if val then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                getgenv().DigCenter = hrp.Position
                getgenv().DigBlacklist = {}
                getgenv().DigAttemptCounts = {}
                if getgenv().DigZoneVisual then getgenv().DigZoneVisual:Destroy() end
                getgenv().DigZoneVisual = nil
                -- เอาระบบสร้างพาร์ทวงกลมบอกอาณาเขตออก เพื่อลดอาการกระตุก
            end
        else
            if getgenv().DigZoneVisual then
                getgenv().DigZoneVisual:Destroy()
                getgenv().DigZoneVisual = nil
            end
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local bv = hrp:FindFirstChild("AutoDig_BV")
                if bv then bv:Destroy() end
                
                -- รีเซ็ตความเร็วเผื่อค้าง
                hrp.Velocity = Vector3.zero
                hrp.RotVelocity = Vector3.zero
            end
        end
    end
})

MainTab:Textbox({
    Title = "Dig Target Material",
    Value = getgenv().TargetMaterial,
    Callback = function(val)
        getgenv().TargetMaterial = val
    end
})

MainTab:Textbox({
    Title = "Dig Radius",
    Value = tostring(getgenv().DigRadius),
    Callback = function(val)
        getgenv().DigRadius = tonumber(val) or 30
    end
})

MainTab:Button({
    Title = "Hide Map (Reduce Lag)",
    Desc = "Makes all map parts invisible but keeps collisions",
    Callback = function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" and not v.Parent:FindFirstChild("Humanoid") then
                -- เช็คว่าเป็นหินที่ขุดหรือไม่ (ถ้าใช่ ไม่ต้องทำให้โปร่งใส)
                if not v:FindFirstChild("ProximityPrompt") and not (v.Parent and v.Parent:FindFirstChild("ProximityPrompt")) then
                    v.Transparency = 1
                    v.Material = Enum.Material.SmoothPlastic
                    -- ลบ Decal/Texture เพื่อลดแลคเพิ่ม
                    for _, sub in pairs(v:GetChildren()) do
                        if sub:IsA("Decal") or sub:IsA("Texture") then
                            sub:Destroy()
                        end
                    end
                end
            end
        end
        -- ถ้าเกมใช้ Smooth Terrain
        if workspace:FindFirstChild("Terrain") and workspace.Terrain:IsA("Terrain") then
            workspace.Terrain.WaterTransparency = 1
            workspace.Terrain.Decoration = false
            -- Terrain ปกติปรับ Transparency ไม่ได้ แต่ลบสี/Texture ได้บ้าง
        end
    end
})

MainTab:Button({
    Title = "Stop Script",
    Desc = "Cleans up all visuals and connections",
    Callback = function()
        if getgenv().CrystalFarm_Disconnect then getgenv().CrystalFarm_Disconnect() end
    end
})

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

SettingsTab:Section({ Title = "General Settings" })

SettingsTab:Dropdown({
    Title = "Mode",
    List = {"Expensive First", "Deep First", "Closest First"},
    Default = getgenv().CrystalFarm_Mode,
    Callback = function(val)
        getgenv().CrystalFarm_Mode = val
    end
})

SettingsTab:Toggle({
    Title = "Use Filters",
    Value = getgenv().CrystalFarm_UseFilters,
    Callback = function(val)
        getgenv().CrystalFarm_UseFilters = val
    end
})

SettingsTab:Toggle({
    Title = "Auto Upgrade",
    Value = getgenv().CrystalFarm_AutoUpgrade,
    Callback = function(val)
        getgenv().CrystalFarm_AutoUpgrade = val
    end
})

SettingsTab:Section({ Title = "Allowed Rarities" })

for _, r in ipairs({"[S]", "[M]", "[L]", "[Giant]", "[Titan]"}) do
    SettingsTab:Toggle({
        Title = "Mine " .. r,
        Value = getgenv().CrystalFarm_Rarity[r] or false,
        Callback = function(val)
            getgenv().CrystalFarm_Rarity[r] = val
        end
    })
end

SettingsTab:Section({ Title = "Advanced Filters" })

SettingsTab:Textbox({
    Title = "Min Price",
    Value = tostring(getgenv().CrystalFarm_MinPrice),
    Callback = function(val)
        getgenv().CrystalFarm_MinPrice = tonumber(val) or 0
    end
})

SettingsTab:Textbox({
    Title = "Min Y Level",
    Value = tostring(getgenv().CrystalFarm_MinY),
    Callback = function(val)
        getgenv().CrystalFarm_MinY = tonumber(val) or -99999999999
    end
})

SettingsTab:Textbox({
    Title = "Max Y Level",
    Value = tostring(getgenv().CrystalFarm_MaxY),
    Callback = function(val)
        getgenv().CrystalFarm_MaxY = tonumber(val) or 999999999999
    end
})

SettingsTab:Toggle({
    Title = "Debug Logging",
    Desc = "Print crystal data to F9 Console to diagnose issues",
    Value = getgenv().CrystalFarm_DebugLogging,
    Callback = function(val)
        getgenv().CrystalFarm_DebugLogging = val
    end
})

local ESPTab = Window:Tab({
    Title = "ESP",
    Icon = "eye"
})

ESPTab:Toggle({
    Title = "Enable ESP",
    Desc = "Toggle Master ESP",
    Value = getgenv().ESP_Enabled,
    Callback = function(val)
        getgenv().ESP_Enabled = val
    end
})

ESPTab:Toggle({
    Title = "Show Highlight",
    Desc = "Show highlight around crystals",
    Value = getgenv().ESP_ShowHighlight,
    Callback = function(val)
        getgenv().ESP_ShowHighlight = val
    end
})

ESPTab:Toggle({
    Title = "Show Text",
    Desc = "Show ESP info above crystals",
    Value = getgenv().ESP_ShowText,
    Callback = function(val)
        getgenv().ESP_ShowText = val
    end
})

ESPTab:Textbox({
    Title = "Max Distance",
    Value = tostring(getgenv().ESP_MaxDistance),
    Callback = function(val)
        getgenv().ESP_MaxDistance = tonumber(val) or 300
    end
})

ESPTab:Section({ Title = "Text Options" })

ESPTab:Toggle({ Title = "Show Name", Value = getgenv().ESP_ShowName, Callback = function(val) getgenv().ESP_ShowName = val end })
ESPTab:Toggle({ Title = "Show Weight", Value = getgenv().ESP_ShowWeight, Callback = function(val) getgenv().ESP_ShowWeight = val end })
ESPTab:Toggle({ Title = "Show Price", Value = getgenv().ESP_ShowPrice, Callback = function(val) getgenv().ESP_ShowPrice = val end })
ESPTab:Toggle({ Title = "Show Distance", Value = getgenv().ESP_ShowDistance, Callback = function(val) getgenv().ESP_ShowDistance = val end })

ESPTab:Section({ Title = "Rarity Options" })

ESPTab:Toggle({
    Title = "Use Rarity Filter",
    Desc = "If ON, only highlights selected rarities. If OFF, highlights all.",
    Value = getgenv().ESP_UseRarityFilter,
    Callback = function(val)
        getgenv().ESP_UseRarityFilter = val
    end
})

for _, r in ipairs({"[S]", "[M]", "[L]", "[Giant]", "[Titan]"}) do
    ESPTab:Toggle({
        Title = "Show " .. r,
        Value = getgenv().ESP_ShowRarities[r] or false,
        Callback = function(val)
            getgenv().ESP_ShowRarities[r] = val
        end
    })
end

Window:SelectTab(1)

local CrystalsFolder = Workspace:WaitForChild("Things"):WaitForChild("Crystals")

-- วนลูปทำให้ทะลุกำแพงได้ตลอดเวลาเมื่อเปิด AutoFarm
local noclipConnection = RunService.Stepped:Connect(function()
    if getgenv().CrystalFarm_Running and getgenv().AutoFarm then
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
table.insert(getgenv().CrystalFarm_Connections, noclipConnection)


-- =====================================
-- // การตั้งค่า (Settings)
-- =====================================
getgenv().AutoFarm = true 

-- [ ความเร็วในการบิน ] 
-- ปรับตัวเลขตรงนี้ได้เลย (ยิ่งเยอะยิ่งบินเร็ว แต่ระวังถ้าเร็วไปอาจจะทำให้เกมบัคหรือค้างได้)
getgenv().GhostFlySpeed = 200

local teleportDelay = 0.1 -- หน่วงเวลาหลังจากบินถึงหิน
local ESP_Color = Color3.fromRGB(0, 255, 128) 


getgenv().AutoSell = true 
getgenv().SellMethod = "UI" 
local timeToSell = 30 


-- ฟังก์ชั่นดึงข้อมูลหิน (ชื่อ, น้ำหนัก, ราคา) จาก ProximityPrompt
local function parseCrystalData(crystal)
    local name = crystal.Name
    local weight = 1
    local price = 0
    
    local prompt = crystal:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.ObjectText and prompt.ObjectText ~= "" then
        local text = prompt.ObjectText
        local parts = string.split(text, "•")
        if #parts >= 1 then
            name = string.gsub(parts[1], "^%s*(.-)%s*$", "%1")
        end
        if #parts >= 2 then
            local wStr = string.gsub(parts[2], "[,%s]", "")
            local numStr = string.match(wStr, "([%d%.]+)")
            if numStr then weight = tonumber(numStr) end
        end
        if #parts >= 3 then
            local pStr = parts[3]
            pStr = string.gsub(pStr, "<[^>]+>", "")
            pStr = string.gsub(pStr, "[,%s%$]", "")
            
            local multiplier = 1
            if string.find(pStr, "[Kk]") then multiplier = 1000; pStr = string.gsub(pStr, "[Kk]", "")
            elseif string.find(pStr, "[Mm]") then multiplier = 1000000; pStr = string.gsub(pStr, "[Mm]", "")
            elseif string.find(pStr, "[Bb]") then multiplier = 1000000000; pStr = string.gsub(pStr, "[Bb]", "") end
            
            local numStr = string.match(pStr, "([%d%.]+)")
            price = (tonumber(numStr) or 0) * multiplier
        end
    end
    
    return name, weight, price
end

local function createESP(crystal)
    local espText = Drawing.new("Text")
    espText.Visible = false
    espText.Center = true
    espText.Outline = true
    espText.Font = 0 -- ใช้ฟอนต์ UI ที่ดูโมเดิร์นและสบายตากว่าเดิม
    espText.Size = 16
    espText.Color = ESP_Color

    table.insert(getgenv().CrystalFarm_ESP_Objects, espText)
    
    -- สร้าง Highlight ให้เรืองแสงสวยๆ
    local highlight = Instance.new("Highlight")
    highlight.FillColor = ESP_Color
    highlight.FillTransparency = 0.6
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.2
    
    local crystalPart = crystal
    if crystal:IsA("Model") then
        crystalPart = crystal.PrimaryPart or crystal:FindFirstChildWhichIsA("BasePart")
    end
    
    if crystalPart then
        highlight.Parent = crystalPart
        table.insert(getgenv().CrystalFarm_ESP_Objects, highlight)
    end

    local renderConnection
    renderConnection = RunService.RenderStepped:Connect(function()
        if not getgenv().CrystalFarm_Running then return end

        if not crystal or not crystal.Parent then
            espText.Visible = false
            espText:Remove()
            if highlight then highlight:Destroy() end
            if renderConnection then renderConnection:Disconnect() end
            return
        end

        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if crystalPart and hrp then
            local pos, onScreen = Camera:WorldToViewportPoint(crystalPart.Position)

            if onScreen and getgenv().ESP_Enabled then
                local distance = math.floor((hrp.Position - crystalPart.Position).Magnitude)
                
                -- ซ่อน ESP ถ้าระยะห่างมากเกินไป เพื่อลดอาการหน้าจอรก
                if distance > getgenv().ESP_MaxDistance then
                    espText.Visible = false
                    highlight.Enabled = false
                    return
                end

                espText.Position = Vector2.new(pos.X, pos.Y)
                highlight.Enabled = getgenv().ESP_ShowHighlight

                local cName, cSize, cPrice = parseCrystalData(crystal)
                
                -- ตรวจสอบ Rarity Filter
                if getgenv().ESP_UseRarityFilter then
                    local allowed = false
                    for r, show in pairs(getgenv().ESP_ShowRarities) do
                        -- Escape วงเล็บเหลี่ยมเพื่อไม่ให้เกิด pattern error ใน string.find
                        local safePattern = string.gsub(r, "%[", "%%[")
                        safePattern = string.gsub(safePattern, "%]", "%%]")
                        
                        if show and string.find(cName, safePattern) then
                            allowed = true
                            break
                        end
                    end
                    if not allowed then
                        espText.Visible = false
                        highlight.Enabled = false
                        return
                    end
                end

                local priceText = cPrice > 0 and "$" .. tostring(cPrice) or "Unknown"

                -- กำหนดสีตามระดับของหิน (ยิ่งใหญ่ สียิ่งเด่น)
                local color = ESP_Color
                if string.find(cName, "%[S%]") then color = Color3.fromRGB(220, 220, 220) -- ขาวสว่าง
                elseif string.find(cName, "%[M%]") then color = Color3.fromRGB(80, 255, 100) -- เขียว
                elseif string.find(cName, "%[L%]") then color = Color3.fromRGB(50, 180, 255) -- ฟ้า
                elseif string.find(cName, "%[Giant%]") then color = Color3.fromRGB(220, 50, 255) -- ม่วง/ชมพู
                elseif string.find(cName, "%[Titan%]") then color = Color3.fromRGB(255, 50, 50) -- แดง
                end
                
                espText.Color = color
                highlight.FillColor = color

                -- จัดการข้อความ ESP
                local lines = {}
                if getgenv().ESP_ShowName then table.insert(lines, string.format("[%s]", cName)) end
                if getgenv().ESP_ShowWeight then table.insert(lines, string.format("Weight: %.1fkg", cSize)) end
                if getgenv().ESP_ShowPrice then table.insert(lines, string.format("Price: %s", priceText)) end
                if getgenv().ESP_ShowDistance then table.insert(lines, string.format("Dist: %d", distance)) end
                
                if #lines > 0 then
                    espText.Text = table.concat(lines, "\n")
                    espText.Visible = getgenv().ESP_ShowText
                else
                    espText.Visible = false
                end
            else
                espText.Visible = false
                highlight.Enabled = false
            end
        else
            espText.Visible = false
        end
    end)
    table.insert(getgenv().CrystalFarm_Connections, renderConnection)
end

for _, crystal in pairs(CrystalsFolder:GetChildren()) do
    createESP(crystal)
end

local childAddedConnection = CrystalsFolder.ChildAdded:Connect(function(crystal)
    createESP(crystal)
end)
table.insert(getgenv().CrystalFarm_Connections, childAddedConnection)


-- =====================================
-- // ระบบ Auto Farm (วาป + กด E)
-- =====================================
local lastSellTime = tick()

task.spawn(function()
    while task.wait(teleportDelay) and getgenv().CrystalFarm_Running do
        if getgenv().AutoFarm then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                -- ใช้ parseCrystalData จากด้านบนแทน

                -- เช็คพื้นที่กระเป๋าว่าง
                local spaceLeft = 9999
                local maxBagSize = 9999
                local explorerHud = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("ExplorerHud")
                if explorerHud then
                    local backpackPanel = explorerHud:FindFirstChild("BackpackPanel")
                    if backpackPanel then
                        local valueLabel = backpackPanel:FindFirstChild("Value")
                        if valueLabel and (valueLabel:IsA("TextLabel") or valueLabel:IsA("TextBox")) then
                            local txt = valueLabel.Text
                            if txt == "FULL!" or string.find(txt, "FULL!") then
                                spaceLeft = 0
                            else
                                local cleanTxt = string.gsub(txt, "[,%s]", "")
                                cleanTxt = string.gsub(string.lower(cleanTxt), "kg", "") -- ลบคำว่า kg ออกก่อนเพื่อไม่ให้ไปสับสนกับ K (พัน)
                                
                                -- จับคู่ตัวเลขและตัวอักษร K,M,B ที่ตามหลัง (ถ้ามี)
                                local currStr, currMult, maxStr, maxMult = string.match(cleanTxt, "([%d%.]+)([kmb]*)[^%d%.]-([%d%.]+)([kmb]*)")
                                
                                if currStr and maxStr then
                                    local function parseMult(str, m)
                                        local num = tonumber(str) or 0
                                        if string.find(m, "k") then num = num * 1000
                                        elseif string.find(m, "m") then num = num * 1000000
                                        elseif string.find(m, "b") then num = num * 1000000000 end
                                        return num
                                    end
                                    
                                    local maxNum = parseMult(maxStr, maxMult)
                                    local currNum = parseMult(currStr, currMult)
                                    
                                    if maxNum and currNum then
                                        maxBagSize = maxNum
                                        spaceLeft = maxNum - currNum
                                        if getgenv().CrystalFarm_DebugLogging then
                                            print(string.format("[DEBUG] Bag: %s / %s (Max: %s, Left: %s)", tostring(currNum), tostring(maxNum), tostring(maxBagSize), tostring(spaceLeft)))
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                -- ตรวจสอบและสั่งขายของ
                if getgenv().AutoSell then
                    local isFull = false
                    if getgenv().SellMethod == "Time" then
                        if tick() - lastSellTime >= timeToSell then isFull = true end
                    elseif getgenv().SellMethod == "UI" then
                        if spaceLeft <= 0 then isFull = true end
                    end
                    
                    if isFull then
                        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                        if remotes then
                            local goHome = remotes:FindFirstChild("GoHome")
                            local sellReq = remotes:FindFirstChild("SellRequest")
                            
                            if goHome then goHome:FireServer("sell") end
                            task.wait(0.5) -- วาร์ปไปที่ร้านก่อน
                            if sellReq then sellReq:FireServer("all") end
                            
                            print("Inventory Full! Teleported to shop and Sold. Resuming...")
                            lastSellTime = tick()
                            task.wait(2.5) -- รอซักพักให้ขายเสร็จ
                            
                            if getgenv().CrystalFarm_AutoUpgrade then
                                pcall(function()
                                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                    if hrp then
                                        hrp.CFrame = CFrame.new(17.8660469, 33.3744431, 1067.16968, -0.00865328312, 0.964186788, 0.265083045, -0.00215366483, 0.265074372, -0.964225531, -0.999960184, -0.00891461968, -0.000217199326)
                                        task.wait(0.5)
                                        local upgradeBuy = remotes:FindFirstChild("UpgradeBuy")
                                        if upgradeBuy then
                                            -- สแปมส่งคำสั่งอัพเกรดรัวๆ เพื่อให้มันอัพจนกว่าเงินจะหมดหรือตัน
                                            for i = 1, 35 do
                                                upgradeBuy:FireServer("Weight", 1)
                                                upgradeBuy:FireServer("Air", 1)
                                                task.wait(0.05)
                                            end
                                        end
                                        task.wait(0.5)
                                    end
                                end)
                            end
                            
                            continue
                        end
                    end
                end

                local bestCrystal = nil
                local highestScore = -math.huge
                
                -- ลูปหาหินที่แพงที่สุดและพอดีกระเป๋า
                for _, crystal in pairs(CrystalsFolder:GetChildren()) do
                    local prompt = crystal:FindFirstChildWhichIsA("ProximityPrompt", true)
                    local crystalPart = crystal
                    
                    if crystal:IsA("Model") then
                        crystalPart = crystal.PrimaryPart or crystal:FindFirstChildWhichIsA("BasePart")
                    end
                    
                    if prompt and crystalPart then
                        local cName, cSize, price = parseCrystalData(crystal)
                        
                        -- ตรวจสอบฟิลเตอร์ความแรร์
                        local rarity = ""
                        if string.find(cName, "%[S%]") then rarity = "[S]"
                        elseif string.find(cName, "%[M%]") then rarity = "[M]"
                        elseif string.find(cName, "%[L%]") then rarity = "[L]"
                        elseif string.find(cName, "%[Giant%]") then rarity = "[Giant]"
                        elseif string.find(cName, "%[Titan%]") then rarity = "[Titan]"
                        end
                        
                        local isAllowedRarity = (rarity == "" or getgenv().CrystalFarm_Rarity[rarity])
                        local isAllowedPrice = (price >= getgenv().CrystalFarm_MinPrice)
                        local isAllowedHeight = (crystalPart.Position.Y >= getgenv().CrystalFarm_MinY and crystalPart.Position.Y <= getgenv().CrystalFarm_MaxY)
                        
                        local passesFilters = true
                        if getgenv().CrystalFarm_UseFilters then
                            passesFilters = isAllowedRarity and isAllowedPrice and isAllowedHeight
                        end
                        
                        -- DEBUG: ดูค่าที่สคริปต์อ่านได้
                        if getgenv().CrystalFarm_DebugLogging then
                            print(string.format("[DEBUG] Name: %s | Weight: %s | Price: %s | Passed Filter: %s", tostring(cName), tostring(cSize), tostring(price), tostring(passesFilters)))
                        end

                        -- ห้ามเลือกหินที่ใหญ่กว่ากระเป๋าสูงสุด หินที่โดนแบล็คลิสต์ และต้องผ่านเงื่อนไข (ถ้าเปิดฟิลเตอร์ไว้)
                        if cSize <= maxBagSize and not getgenv().CrystalFarm_Blacklist[crystal] and passesFilters then
                            if cSize <= spaceLeft then -- เช็คว่าพื้นที่กระเป๋าเหลือพอไหม
                                local distance = (hrp.Position - crystalPart.Position).Magnitude
                                
                                local score = 0
                                if getgenv().CrystalFarm_Mode == "Expensive First" then
                                    score = (price * 1000) - crystalPart.Position.Y - (distance * 0.1)
                                elseif getgenv().CrystalFarm_Mode == "Deep First" then
                                    score = -crystalPart.Position.Y - (distance * 0.1)
                                elseif getgenv().CrystalFarm_Mode == "Closest First" then
                                    score = -distance
                                end
                                
                                if score > highestScore then
                                    highestScore = score
                                    bestCrystal = crystal
                                end
                            end
                        end
                    end
                end
                
                local closestCrystal = bestCrystal
                getgenv().CrystalFarm_CurrentTarget = closestCrystal
                
                if not closestCrystal and #CrystalsFolder:GetChildren() > 0 then
                    -- ถ้ารอบนี้หาหินที่ใส่กระเป๋าได้ไม่เจอเลย
                    if maxBagSize ~= 9999 and spaceLeft >= maxBagSize * 0.9 then
                        -- ถ้ากระเป๋ายังโล่งอยู่ แปลว่าหินทั้งแมพตอนนี้ "ใหญ่กว่ากระเป๋า" หรือ "ไม่ผ่านฟิลเตอร์ (ราคา/ระดับหิน)"
                        print("No crystals match your filters (or they are too big). Waiting...")
                        task.wait(2)
                        continue
                    else
                        -- ถ้ากระเป๋ามีของอยู่ แปลว่าที่เหลือน้อยจนหินยัดไม่ลงแล้ว ให้ไปขาย
                        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                        if remotes then
                            local goHome = remotes:FindFirstChild("GoHome")
                            local sellReq = remotes:FindFirstChild("SellRequest")
                            
                            if goHome then goHome:FireServer("sell") end
                            task.wait(0.5) -- วาร์ปไปที่ร้านก่อน
                            if sellReq then sellReq:FireServer("all") end
                            
                            print("Cannot fit any more crystals! Teleported to shop and Sold...")
                            lastSellTime = tick()
                            task.wait(2.5)
                            
                            if getgenv().CrystalFarm_AutoUpgrade then
                                pcall(function()
                                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                    if hrp then
                                        hrp.CFrame = CFrame.new(17.8660469, 33.3744431, 1067.16968, -0.00865328312, 0.964186788, 0.265083045, -0.00215366483, 0.265074372, -0.964225531, -0.999960184, -0.00891461968, -0.000217199326)
                                        task.wait(0.5)
                                        local upgradeBuy = remotes:FindFirstChild("UpgradeBuy")
                                        if upgradeBuy then
                                            upgradeBuy:FireServer("Air", 1)
                                            task.wait(0.2)
                                            upgradeBuy:FireServer("Weight", 1)
                                        end
                                        task.wait(0.5)
                                    end
                                end)
                            end
                            
                            continue
                        end
                    end
                end

                if closestCrystal then
                    local crystalPart = closestCrystal
                    if closestCrystal:IsA("Model") then
                        crystalPart = closestCrystal.PrimaryPart or closestCrystal:FindFirstChildWhichIsA("BasePart")
                    end
                    
                    if crystalPart then
                        -- ทำให้ตัวละครลอยไม่ตกพื้น
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then hum.PlatformStand = true end
                        
                        local bv = hrp:FindFirstChild("AutoFarm_GhostFlyBV")
                        if not bv then
                            bv = Instance.new("BodyVelocity")
                            bv.Name = "AutoFarm_GhostFlyBV"
                            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                            bv.Velocity = Vector3.new(0, 0, 0)
                            bv.Parent = hrp
                        end
                        
                        local bg = hrp:FindFirstChild("AutoFarm_GhostFlyBG")
                        if not bg then
                            bg = Instance.new("BodyGyro")
                            bg.Name = "AutoFarm_GhostFlyBG"
                            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                            bg.P = 3000
                            bg.D = 500
                            bg.Parent = hrp
                        end
                        -- ล็อคการหมุนตัวให้ตั้งตรงและไม่หมุนเปลี่ยนทิศทางใดๆ ทั้งสิ้น
                        bg.CFrame = CFrame.new(Vector3.zero)

                        -- คำนวณเวลาที่ใช้บินตามระยะทางและความเร็ว
                        local distance = (hrp.Position - crystalPart.Position).Magnitude
                        local tweenTime = distance / getgenv().GhostFlySpeed
                        
                        -- บินไปหาเป้าหมายอย่างสมูท (ไม่เด้ง)
                        local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
                        -- ใช้เฉพาะตำแหน่งของหิน ไม่หมุนตามเหลี่ยมของหิน เพื่อกันไม่ให้มันเด้ง
                        local targetCFrame = CFrame.new(crystalPart.Position)
                        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
                        getgenv().CrystalFarm_CurrentTween = tween
                        tween:Play()
                        
                        -- รอจนกว่าจะบินถึงเป้าหมาย หรือโดนสั่งหยุด
                        tween.Completed:Wait()
                        if not getgenv().CrystalFarm_Running then break end
                        
                        task.wait(0.1) 
                        if not getgenv().CrystalFarm_Running then break end
                        
                        -- ล็อคตัวละครชั่วคราวตอนขุด เพื่อกันไม่ให้อนิเมชั่นขุดไปขัดแย้งทำให้ตัวหมุนหรือสั่น
                        hrp.Anchored = true
                        
                        local prompt = closestCrystal:FindFirstChild("ProximityPrompt")
                        if prompt then
                            fireproximityprompt(prompt, 1)
                        end
                        
                        task.wait(0.2)
                        hrp.Anchored = false
                    end
                end
            end
        end
    end
end)

-- =====================================
-- // ระบบ Auto Minigame (ควบคุมเกจให้อยู่ในโซนสีเขียว)
-- =====================================
local vim = game:GetService("VirtualInputManager")
local isClicking = false

local minigameConnection = RunService.RenderStepped:Connect(function()
    if not getgenv().CrystalFarm_Running or not getgenv().AutoFarm then return end
    
    local heightBar = LocalPlayer.PlayerGui:FindFirstChild("HeightBar")
    if heightBar and ((heightBar:IsA("ScreenGui") and heightBar.Enabled) or (heightBar:IsA("GuiObject") and heightBar.Visible)) then
        local frame = heightBar:FindFirstChild("Frame")
        if frame then
            local human = frame:FindFirstChild("Human")
            local safeZone = frame:FindFirstChild("SafeZone")
            
            if human and safeZone then
                -- จุดศูนย์กลางของคน
                local hY = human.AbsolutePosition.Y + (human.AbsoluteSize.Y / 2)
                
                -- ตรวจจับว่าโดนดาเมจความหนาวอยู่ไหม (AirEffects > Bottom)
                local isFreezing = false
                local airEffects = LocalPlayer.PlayerGui:FindFirstChild("AirEffects")
                if airEffects then
                    local bottomEff = airEffects:FindFirstChild("Bottom")
                    if bottomEff and bottomEff.Visible then
                        isFreezing = true
                    end
                end

                -- ถ้าเริ่มโดนดาเมจ ให้จดจำระดับความสูงปัจจุบันไว้เป็น "เพดานอันตราย" (บวกเผื่อลงมานิดหน่อย)
                if isFreezing then
                    getgenv().CrystalFarm_DangerCeiling = human.AbsolutePosition.Y + (human.AbsoluteSize.Y * 0.8)
                    
                    -- แบล็คลิสต์หินก้อนนี้ทิ้งไปเลย บอทจะได้ไปหาหินก้อนอื่นแทน
                    if getgenv().CrystalFarm_CurrentTarget then
                        getgenv().CrystalFarm_Blacklist[getgenv().CrystalFarm_CurrentTarget] = true
                        getgenv().CrystalFarm_CurrentTarget = nil
                        getgenv().CrystalFarm_DangerCeiling = nil -- เคลียร์ทิ้งเพื่อเริ่มใหม่
                        
                        -- บังคับปล่อยเมาส์ทันที
                        if isClicking then
                            isClicking = false
                            pcall(function() if mouse1release then mouse1release() end end)
                            pcall(function() 
                                local cx = workspace.CurrentCamera.ViewportSize.X / 2
                                local cy = workspace.CurrentCamera.ViewportSize.Y / 2
                                vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0) 
                            end)
                        end
                        return
                    end
                end
                
                -- เป้าหมายคือให้อยู่ตรงกลางโซนสีเขียว (SafeZone) ตลอดเวลา
                local targetY = safeZone.AbsolutePosition.Y + (safeZone.AbsoluteSize.Y / 2)
                
                -- ถ้าระดับเป้าหมายมันสูงกว่าเพดานอันตราย (Y น้อยกว่า) ให้บังคับเป้าหมายลงมาที่เพดานอันตรายแทน
                if getgenv().CrystalFarm_DangerCeiling then
                    if targetY < getgenv().CrystalFarm_DangerCeiling then
                        targetY = getgenv().CrystalFarm_DangerCeiling
                    end
                    
                    -- รีเซ็ตเพดานอันตรายถ้า SafeZone ขยับหนีลงไปลึกมากแล้ว (เริ่มรอบใหม่หรือโซนเลื่อน)
                    if safeZone.AbsolutePosition.Y > getgenv().CrystalFarm_DangerCeiling + 150 then
                        getgenv().CrystalFarm_DangerCeiling = nil
                    end
                end
                
                -- ถ้าศูนย์กลางคนตกไปต่ำกว่าเป้าหมาย (Y มากกว่า) และไม่ได้กำลังโดนแช่แข็ง -> ให้คลิกบินขึ้น
                if hY > targetY and not isFreezing then
                    if not isClicking then
                        isClicking = true
                        pcall(function() if mouse1press then mouse1press() end end)
                        pcall(function() 
                            local cx = workspace.CurrentCamera.ViewportSize.X / 2
                            local cy = workspace.CurrentCamera.ViewportSize.Y / 2
                            vim:SendMouseButtonEvent(cx, cy, 0, true, game, 0) 
                        end)
                    end
                else
                    -- ถ้าสูงเกินเป้าหมาย หรือกำลังโดนแช่แข็ง ให้ปล่อยเมาส์ร่วงทันที!
                    if isClicking then
                        isClicking = false
                        pcall(function() if mouse1release then mouse1release() end end)
                        pcall(function() 
                            local cx = workspace.CurrentCamera.ViewportSize.X / 2
                            local cy = workspace.CurrentCamera.ViewportSize.Y / 2
                            vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0) 
                        end)
                    end
                end
            end
        end
    else
        -- คืนค่าเมาส์ถ้าหน้าต่างมินิเกมปิดไปแล้ว ป้องกันเมาส์ค้าง
        if isClicking then
            isClicking = false
            pcall(function() if mouse1release then mouse1release() end end)
            pcall(function() 
                local cx = workspace.CurrentCamera.ViewportSize.X / 2
                local cy = workspace.CurrentCamera.ViewportSize.Y / 2
                vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0) 
            end)
        end
    end
end)
table.insert(getgenv().CrystalFarm_Connections, minigameConnection)
