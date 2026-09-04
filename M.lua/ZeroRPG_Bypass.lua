-- ==============================================================================
--  HYPER HUB - Zero RPG Anti-Cheat Bypass
-- ==============================================================================

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
            "https://raw.githubusercontent.com/projectsingularityv1-debug/HYPER-LOADER/refs/heads/main/UI.main/ui.lua",
            "https://raw.githubusercontent.com/projectsingularityv1-debug/HYPER-LOADER/refs/heads/main/UI.main/ui.lua"
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
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local WindowSize = UIS.TouchEnabled and UDim2.fromOffset(550, 550) or UDim2.fromOffset(570, 450)

local KeyAvatarURL = getgenv().KeyAvatar
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
    KeyAvatarURL = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150"
end

local Window = Library:Window({
    Profile = {
        Username = getgenv().KeyUsername or "N/A",
        Email = "UID: " .. tostring(LocalPlayer.UserId),
        AvatarUrl = KeyAvatarURL
    },
    Title = "HYPER HUB",
    Desc = "Zero RPG Bypass",
    Icon = "112209635962758",
    Version = "1.0",
    Theme = "Amethyst",
    Config = {
        Keybind = Enum.KeyCode.RightShift,
        Size = WindowSize
    },
    CloseUIButton = {
        Enabled = true,
        Text = "Close Menu"
    }
})

-- ==========================================
-- 1. Main Tab (Bypass Control)
-- ==========================================
local MainTab = Window:Tab({ Title = "Main Bypass", Icon = "shield" })

MainTab:Paragraph({
    Title = "Zero RPG Anti-Cheat",
    Desc = "This bypass disables server checks for WalkSpeed, Client Info, and Rank configurations. \nOnce executed, the hooks will remain active until you rejoin the game."
})

getgenv().ZeroRPG_BypassExecuted = getgenv().ZeroRPG_BypassExecuted or false

MainTab:Button({
    Title = "Execute Bypass",
    Desc = "Run this before using any other cheats.",
    Image = "unlock",
    Callback = function()
        if getgenv().ZeroRPG_BypassExecuted then
            warn("[HYPER HUB] Bypass is already active!")
            return
        end
        getgenv().ZeroRPG_BypassExecuted = true
        
        -- ==========================================
        -- Zero RPG Bypass Logic
        -- ==========================================
        local BlockedRemotes = {
            ["Guilds_GetRankColor"] = true,
            ["FunctionGetProductPrice"] = true,
            ["Skillset_Hunter_GetWalkspeed"] = function(...)
                return 16 
            end,
            ["Guilds_GetPermissionColor"] = true,
            ["FunctionGetClientInfo"] = function(...)
                return {
                    ["Platform"] = "PC",
                    ["Ping"] = math.random(30, 80)
                }
            end
        }

        local function HookExistingRemote(remote)
            if typeof(remote) == "Instance" and remote:IsA("RemoteFunction") then
                local bypassAction = BlockedRemotes[remote.Name]
                if bypassAction then
                    print("[HYPER HUB] Hooking AC RemoteFunction: " .. remote.Name)
                    remote.OnClientInvoke = function(...)
                        if type(bypassAction) == "function" then
                            return bypassAction(...)
                        end
                        return wait(9e9)
                    end
                end
            end
        end

        for _, v in pairs(game:GetDescendants()) do
            HookExistingRemote(v)
        end

        game.DescendantAdded:Connect(function(v)
            HookExistingRemote(v)
        end)

        local mt = getrawmetatable(game)
        local oldNewIndex = mt.__newindex

        setreadonly(mt, false)

        mt.__newindex = newcclosure(function(t, k, v)
            if k == "OnClientInvoke" and typeof(t) == "Instance" and t.ClassName == "RemoteFunction" then
                local bypassAction = BlockedRemotes[t.Name]
                if bypassAction then
                    v = newcclosure(function(...)
                        if type(bypassAction) == "function" then
                            return bypassAction(...)
                        end
                        return wait(9e9)
                    end)
                end
            end
            return oldNewIndex(t, k, v)
        end)

        setreadonly(mt, true)
        
        print("=================================================================")
        print("[HYPER HUB] Zero RPG Bypass Executed Successfully!")
        print("=================================================================")
    end
})

MainTab:Label({
    Title = "Status",
    Desc = "Check console (F9) for execution logs.",
    Image = "terminal"
})

-- ==========================================
-- 2. Auto Farm Tab
-- ==========================================
local FarmTab = Window:Tab({ Title = "Auto Farm", Icon = "crosshair" })

getgenv().AutoAttack = false

FarmTab:Toggle({
    Title = "Auto Attack (Tool:Activate)",
    Desc = "Automatically swings your equipped weapon.",
    Value = false,
    Callback = function(val)
        getgenv().AutoAttack = val
        if val then
            task.spawn(function()
                while getgenv().AutoAttack do
                    task.wait(0.05)
                    pcall(function()
                        local char = LocalPlayer.Character
                        if char then
                            local tool = char:FindFirstChildOfClass("Tool")
                            if tool then
                                tool:Activate()
                            end
                        end
                    end)
                end
            end)
        end
    end
})

-- ==========================================
-- 3. Settings Tab (Standard XINZ)
-- ==========================================
local SettingsTab = Window:Tab({ Title = "UI Settings", Icon = "settings", LayoutOrder = 9999 })

SettingsTab:Keybind({
    Title = "Toggle UI Keybind",
    Desc = "Change the key used to hide/show the UI",
    Default = Enum.KeyCode.RightShift,
    Callback = function(key)
    end
})

SettingsTab:Dropdown({
    Title = "Closed UI Style",
    Desc = "Select the style of the minimized UI",
    List = {"Breadcrumb", "Gooey plus menu"},
    Default = "Gooey plus menu",
    Callback = function(style)
        if Window.SetClosedUIStyle then
            Window.SetClosedUIStyle(style)
        end
    end
})


