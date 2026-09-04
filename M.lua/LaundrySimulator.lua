--[[
__________                   __               __    __________              .__
\______   \_______  ____    |__| ____   _____/  |_  \______   \ ____ _____  |  |
 |     ___/\_  __ \/  _ \   |  |/ __ \_/ ___\   __\  |       _// __ \\__  \ |  |
 |    |     |  | \(  <_> )  |  \  ___/\  \___|  |    |    |   \  ___/ / __ \|  |__
 |____|     |__|   \____/\__|  |\___  >\___  >__|    |____|_  /\___  >____  /____/
                        \______|    \/     \/               \/     \/     \/
]]
--                           Project Real  |  Luau Decompiler
--                                   Made by @zinvera
--                File: Players.sdfgdsfgsdfg19.PlayerGui.Info.Info_Local
--                                Dumped in 0.861 seconds
--                          Bytecode version 9  |  32 functions

local NonSaveVars, OwnsPlot, SaveVars
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Events = game.ReplicatedStorage:WaitForChild("Events")
local TweenService = game:GetService("TweenService")
local u25 = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local u30 = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local LocalPlayer = game.Players.LocalPlayer
local Position = workspace._FinishChute.Abyss.Position
local CurrentCamera = workspace.CurrentCamera
local LocalPlayer_2 = game.Players.LocalPlayer
local Mouse = game.Players.LocalPlayer:GetMouse()
local Rep_Library = require(game.ReplicatedStorage.Modules.Rep_Library)
local WashingMachines = require(game.ReplicatedStorage.Modules.WashingMachines)
local HoverLabel = script.Parent:WaitForChild("HoverLabel")
local Clothing = workspace.Debris.Clothing
local WashingMachines_2 = nil
local u75 = Instance.new("SelectionBox", script.Parent)
u75.Color3 = Color3.fromRGB(95, 195, 84)
u75.LineThickness = 0.2
local v1 = game.ReplicatedFirst.Misc.PetStats:Clone()
local v2 = game.ReplicatedFirst.Misc.PetStats:Clone()
local u96 = {v1, v2}
local u99 = {0, 0}
local u102 = {false, false}
local u105 = {nil, nil}
local new = Ray.new
local u109 = nil
function getWashingMachineFromPart(p1) -- Line: 40 -- upvalues: WashingMachines_2 (ref)
    if not p1 or p1.Name == "Workspace" then
        return nil
    end
    if not (p1:IsA("Model")) or not p1.PrimaryPart then
        return getWashingMachineFromPart(p1.Parent)
    end
    if p1.Parent == WashingMachines_2 then
        return p1
    end
    return nil
end
function fireRay() -- Line: 59 -- upvalues: UserInputService (val), CurrentCamera (val), LocalPlayer (val), new (val), Clothing (val), WashingMachines_2 (ref), u109 (ref)
    local v1, v2
    local MouseLocation = UserInputService:GetMouseLocation()
    local v3 = CurrentCamera:ScreenPointToRay(MouseLocation.X, MouseLocation.Y - 36)
    if not LocalPlayer.NonSaveVars.PetSlot2.Value then
        if LocalPlayer.NonSaveVars.PetSlot1.Value then
            v2 = new(v3.Origin, v3.Direction * 45)
            v1 = workspace:FindPartOnRayWithWhitelist(v2, {
                Clothing,
                WashingMachines_2,
                workspace._FinishChute,
                u109,
                LocalPlayer.NonSaveVars.PetSlot1.Value,
            })
            return v1, MouseLocation
        end
        if LocalPlayer.NonSaveVars.PetSlot2.Value then
            v2 = new(v3.Origin, v3.Direction * 45)
            v1 = workspace:FindPartOnRayWithWhitelist(v2, {
                Clothing,
                WashingMachines_2,
                workspace._FinishChute,
                u109,
                LocalPlayer.NonSaveVars.PetSlot2.Value,
            })
            return v1, MouseLocation
        end
        v2 = new(v3.Origin, v3.Direction * 45)
        v1 = workspace:FindPartOnRayWithWhitelist(v2, {Clothing, WashingMachines_2, workspace._FinishChute, u109})
        return v1, MouseLocation
    end
    if LocalPlayer.NonSaveVars.PetSlot1.Value then
        v2 = new(v3.Origin, v3.Direction * 45)
        v1 = workspace:FindPartOnRayWithWhitelist(v2, {
            Clothing,
            WashingMachines_2,
            workspace._FinishChute,
            u109,
            LocalPlayer.NonSaveVars.PetSlot1.Value,
            LocalPlayer.NonSaveVars.PetSlot2.Value,
        })
        return v1, MouseLocation
    end
    if LocalPlayer.NonSaveVars.PetSlot1.Value then
        v2 = new(v3.Origin, v3.Direction * 45)
        v1 = workspace:FindPartOnRayWithWhitelist(v2, {
            Clothing,
            WashingMachines_2,
            workspace._FinishChute,
            u109,
            LocalPlayer.NonSaveVars.PetSlot1.Value,
        })
        return v1, MouseLocation
    end
    if LocalPlayer.NonSaveVars.PetSlot2.Value then
        v2 = new(v3.Origin, v3.Direction * 45)
        v1 = workspace:FindPartOnRayWithWhitelist(v2, {
            Clothing,
            WashingMachines_2,
            workspace._FinishChute,
            u109,
            LocalPlayer.NonSaveVars.PetSlot2.Value,
        })
        return v1, MouseLocation
    end
    v2 = new(v3.Origin, v3.Direction * 45)
    v1 = workspace:FindPartOnRayWithWhitelist(v2, {Clothing, WashingMachines_2, workspace._FinishChute, u109})
    return v1, MouseLocation
end
local Hinge = workspace._FinishChute.Hinge
local u115 = false
local function u116() -- Line: 77 -- upvalues: u115 (ref), Hinge (val), TweenService (val), u25 (val)
    if not u115 then
        u115 = true
        local v1 = {}
        local v2 = CFrame.new(Hinge.Position)
        v1.CFrame = v2 * CFrame.Angles(0, 0, -1.5707963267948966)
        TweenService:Create(Hinge, u25, v1):Play()
    end
end
local function u117() -- Line: 87 -- upvalues: u115 (ref), Hinge (val), TweenService (val), u25 (val)
    if u115 then
        u115 = false
        TweenService:Create(Hinge, u25, {CFrame = CFrame.new(Hinge.Position)}):Play()
    end
end
local u119 = false
local function u120(p1) -- Line: 205 -- upvalues: LocalPlayer_2 (val), u119 (ref), Rep_Library (val), Events (val)
    if LocalPlayer_2.Character and LocalPlayer_2.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer_2.Character.HumanoidRootPart.Position - p1.Position).Magnitude < 28 and not u119 then
        u119 = true
        local Egg = p1:FindFirstChild("Egg")
        if not Egg then
            Egg = p1.Name == "Magnet"
        end
        if LocalPlayer_2.NonSaveVars.BackpackAmount.Value < LocalPlayer_2.NonSaveVars.BasketSize.Value then
            if not LocalPlayer_2.NonSaveVars.OwnsPlot.Value then
                Rep_Library.notify(LocalPlayer_2, "You need to claim a plot")
                game.SoundService.Misc.Error:Play()
            else
                local v1 = LocalPlayer_2.NonSaveVars.BackpackAmount.Value + 1
                if LocalPlayer_2.NonSaveVars.TotalWashingMachineCapacity.Value >= v1 then
                    if 0 >= LocalPlayer_2.NonSaveVars.BackpackAmount.Value then
                        game.SoundService.Misc.Pick:Play()
                        Events.GrabClothing:FireServer(p1)
                        p1:Destroy()
                    elseif LocalPlayer_2.NonSaveVars.BasketStatus.Value ~= "Clean" then
                        game.SoundService.Misc.Pick:Play()
                        Events.GrabClothing:FireServer(p1)
                        p1:Destroy()
                    elseif Egg then
                        game.SoundService.Misc.Pick:Play()
                        Events.GrabClothing:FireServer(p1)
                        p1:Destroy()
                    else
                        Rep_Library.notify(LocalPlayer_2, "You can't put dirty laundry in a clean basket", 4)
                        game.SoundService.Misc.Error:Play()
                    end
                elseif not Egg then
                    Rep_Library.notify(LocalPlayer_2, "You don't have enough washing machine capacity", 4)
                    game.SoundService.Misc.Error:Play()
                end
            end
        elseif not Egg then
            Rep_Library.notify(LocalPlayer_2, "Your basket is full!")
            game.SoundService.Misc.Error:Play()
        end
        wait(0.1)
        u119 = false
    end
end
local function u121(p1) -- Line: 241 -- upvalues: LocalPlayer_2 (val), u119 (ref), WashingMachines (val), Rep_Library (val)
    if LocalPlayer_2.Character and LocalPlayer_2.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer_2.Character.HumanoidRootPart.Position - p1.MAIN.Position).Magnitude < 40 and not u119 then
        u119 = true
        if p1.Config.Capacity.Value >= WashingMachines[p1.Name].Capacity then
            if p1.Config.CycleFinished.Value then
                if LocalPlayer_2.NonSaveVars.BackpackAmount.Value == 0 then
                    if LocalPlayer_2.NonSaveVars.BackpackAmount.Value >= LocalPlayer_2.NonSaveVars.BasketSize.Value then
                        Rep_Library.notify(LocalPlayer_2, "Your basket is full!")
                        game.SoundService.Misc.Error:Play()
                    else
                        game.ReplicatedStorage.Events.UnloadWashingMachine:FireServer(p1)
                    end
                elseif LocalPlayer_2.NonSaveVars.BasketStatus.Value ~= "Clean" then
                    Rep_Library.notify(LocalPlayer_2, "You need an empty basket to pick up clean laundry!", 4)
                    game.SoundService.Misc.Error:Play()
                end
            end
        elseif not p1.Config.CycleFinished.Value then
            if 0 >= LocalPlayer_2.NonSaveVars.BackpackAmount.Value then
                if 0 < LocalPlayer_2.NonSaveVars.BackpackAmount.Value and LocalPlayer_2.NonSaveVars.BasketStatus.Value == "Clean" then
                    Rep_Library.notify(LocalPlayer_2, "Take your clean clothes to the laundry chute!", 4)
                    game.SoundService.Misc.Error:Play()
                end
            elseif LocalPlayer_2.NonSaveVars.BasketStatus.Value == "Dirty" then
                game.ReplicatedStorage.Events.LoadWashingMachine:FireServer(p1)
            end
        end
        wait(0.1)
        u119 = false
    end
end
local function u122(p1) -- Line: 277 -- upvalues: LocalPlayer_2 (val), u119 (ref), TweenService (val), Position (val), u30 (val), Events (val), Rep_Library (val)
    if LocalPlayer_2.Character and LocalPlayer_2.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer_2.Character.HumanoidRootPart.Position - workspace._FinishChute.Handle.Position).Magnitude < 35 and not u119 then
        u119 = true
        if 0 >= LocalPlayer_2.NonSaveVars.BackpackAmount.Value then
            if 0 < LocalPlayer_2.NonSaveVars.BackpackAmount.Value and LocalPlayer_2.NonSaveVars.BasketStatus.Value == "Dirty" then
                Rep_Library.notify(LocalPlayer_2, "You need to wash your clothes!", 2)
                game.SoundService.Misc.Error:Play()
            end
        elseif LocalPlayer_2.NonSaveVars.BasketStatus.Value == "Clean" then
            local u41 = (LocalPlayer_2.Character.Basket.Position - workspace._FinishChute.Entrance.Position).Magnitude / 30
            local u46 = TweenInfo.new(u41, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local u51 = Instance.new("Folder", LocalPlayer_2.Character)
            u51.Name = "ClothesToTween"
            local u53 = {}
            for k, v in pairs(LocalPlayer_2.Character.Basket.Clothing:GetChildren()) do
                table.insert(u53, v)
                v.Parent = u51
            end
            spawn(function() -- Line: 297 -- upvalues: u53 (val), TweenService (upval), u46 (val), Position (upval), u30 (upval), u41 (val), u51 (val)
                local v1
                for k, v in pairs(u53) do
                    v1 = TweenService:Create(v, u46, {CFrame = workspace._FinishChute.Entrance.CFrame * CFrame.new(0, 0, math.random(-6, 6))})
                    v1.Completed:Connect(function() -- Line: 302 -- upvalues: Position (upval), v (val), TweenService (upval), u30 (upval)
                        TweenService:Create(v, u30, {CFrame = CFrame.new(Position.X, Position.Y, v.Position.Z)})
                        v:Destroy()
                    end)
                    if v and v.Parent then
                        if v:FindFirstChild("WeldConstraint") then
                            v.WeldConstraint:Destroy()
                        end
                        v.Anchored = true
                        v1:Play()
                    end
                    wait()
                end
                wait(u41 + 0.3)
                u51:Destroy()
            end)
            Events.DropClothesInChute:FireServer()
            while 0 < LocalPlayer_2.NonSaveVars.CashToAwardFromLoad.Value do
                wait(0.08)
            end
        end
        wait(0.1)
        u119 = false
    end
end
local u123 = false
local function u124(p1) -- Line: 341 -- upvalues: LocalPlayer (val), LocalPlayer_2 (val), u123 (ref), Events (val), Rep_Library (val)
    if not LocalPlayer.NonSaveVars.OwnsPlot.Value then
        Rep_Library.notify(LocalPlayer, "You must claim a plot")
        return
    end
    if script.Parent.Parent.ClaimAward.Frame.Visible then
        Rep_Library.notify(LocalPlayer, "You need to claim your prize")
        return
    end
    if not LocalPlayer_2.Character or not (LocalPlayer_2.Character:FindFirstChild("HumanoidRootPart")) or (LocalPlayer_2.Character.HumanoidRootPart.Position - p1.Position).Magnitude >= 35 then
        return
    end
    if 0 >= p1.Parent.Timer.Value then
        Rep_Library.notify(LocalPlayer, "The timer has run out")
        return
    end
    if u123 or p1.Spun.Value then
        return
    end
    p1.Spun.Value = true
    u123 = true
    local v1 = Events.SpinTheWheel:InvokeServer()
    if v1 then
        local WheelCenter, WheelCenter_2, WheelCenter_3, WheelCenter_4, v2, v3, v4, v5
        local Wheel = p1.Parent.Wheel
        if v1.AwardType == "Cash Booster" then
            v5 = v1.AwardType .. " " .. v1.Amount
        elseif v1.AwardType ~= "Double Coins" then
            v5 = v1.AwardType .. " " .. v1.Slot
        else
            v5 = v1.AwardType .. " " .. v1.Duration
        end
        Wheel.WheelCenter.Anchored = true
        Wheel.WheelCenter.WeldConstraint:Destroy()
        local v6 = (Wheel.WheelPieces[v5].WheelPos.Value - 1) * 36
        local v7 = 18
        game.SoundService.Misc.WheelSpin:Play()
        local v8 = {}
        for k, v in pairs(Wheel.WheelPieces:GetChildren()) do
            v8[tostring(v.WheelPos.Value)] = v
        end
        local v9 = nil
        local v10 = 0
        local v11 = 80
        local v12 = 1
        for i = 1, v11, v12 do
            WheelCenter = Wheel.WheelCenter
            v3 = math.rad(i / 9)
            WheelCenter.CFrame = WheelCenter.CFrame * CFrame.Angles(0, v3, 0)
            v10 = v10 + i / 10
            wait()
        end
        v11 = 80
        v12 = 1
        for j = 1, v11, v12 do
            v7 = v7 + 9
            if 360 < v7 then
                v7 = v7 - 360
            end
            v2 = v8[tostring((math.ceil(v7 / 36)))]
            if v2 ~= v9 then
                if v9 then
                    v9.Material = Enum.Material.SmoothPlastic
                end
                v9 = v2
                game.SoundService.Misc.WheelDing:Play()
                v9.Material = Enum.Material.Neon
            end
            WheelCenter_2 = Wheel.WheelCenter
            WheelCenter_2.CFrame = WheelCenter_2.CFrame * CFrame.Angles(0, 0.15707963267948966, 0)
            wait()
        end
        v11 = v6 / 9
        v12 = 1
        for k2 = 1, v11, v12 do
            v7 = v7 + 9
            if 360 < v7 then
                v7 = v7 - 360
            end
            v2 = v8[tostring((math.ceil(v7 / 36)))]
            if v2 ~= v9 then
                v9.Material = Enum.Material.SmoothPlastic
                v9 = v2
                game.SoundService.Misc.WheelDing:Play()
                v9.Material = Enum.Material.Neon
            end
            WheelCenter_3 = Wheel.WheelCenter
            WheelCenter_3.CFrame = WheelCenter_3.CFrame * CFrame.Angles(0, 0.15707963267948966, 0)
            wait()
        end
        v11 = 1
        v12 = -1
        for n = 80, v11, v12 do
            v7 = v7 + n / 9
            if 360 < v7 then
                v7 = v7 - 360
            end
            v2 = v8[tostring((math.ceil(v7 / 36)))]
            if v2 ~= v9 then
                v9.Material = Enum.Material.SmoothPlastic
                v9 = v2
                game.SoundService.Misc.WheelDing:Play()
                v9.Material = Enum.Material.Neon
            end
            WheelCenter_4 = Wheel.WheelCenter
            v4 = math.rad(n / 9)
            WheelCenter_4.CFrame = WheelCenter_4.CFrame * CFrame.Angles(0, v4, 0)
            wait()
        end
        wait(0.2)
        if Events.ClaimWheelAward:InvokeServer() == "Failed" then
            script.Parent.Parent.ClaimAward.Frame.Background.AwardImage.Image = Wheel.WheelPieces[v5].AwardImage.SurfaceGui.Frame.Background.ImageLabel.Image
            script.Parent.Parent.ClaimAward.Frame.Background.AwardImage.ImageColor3 = Wheel.WheelPieces[v5].AwardImage.SurfaceGui.Frame.Background.ImageLabel.ImageColor3
            script.Parent.Parent.ClaimAward.Frame.Visible = true
        end
        if Wheel and Wheel.Parent then
            Wheel.WheelCenter.Anchored = false
            Rep_Library.weld(Wheel.WheelCenter, Wheel.Parent.Base)
            v12 = Wheel.WheelPieces[v5]
            v12.Material = Enum.Material.Neon
            v12 = Wheel.WheelPieces[v5]
            v12.Color = Color3.new(Wheel.WheelPieces[v5].Color.R / 1.5, Wheel.WheelPieces[v5].Color.G / 1.5, Wheel.WheelPieces[v5].Color.B / 1.5)
        end
    end
    wait(0.1)
    u123 = false
end
local function u125(p1) -- Line: 479 -- upvalues: LocalPlayer_2 (val), LocalPlayer (val), Rep_Library (val)
    if not (p1:FindFirstAncestor("Pets")) or not LocalPlayer_2.Character or not (LocalPlayer_2.Character:FindFirstChild("HumanoidRootPart")) or (LocalPlayer_2.Character.HumanoidRootPart.Position - p1.Position).Magnitude >= 35 then
        return
    end
    local Owner = p1.Parent:FindFirstChild("Owner")
    if not Owner or Owner.Value ~= LocalPlayer then
        return
    end
    if LocalPlayer.NonSaveVars.BasketSize.Value <= LocalPlayer.NonSaveVars.BackpackAmount.Value then
        Rep_Library.notify(LocalPlayer_2, "Your basket is full!")
        game.SoundService.Misc.Error:Play()
        return
    end
    if LocalPlayer.NonSaveVars.BasketStatus.Value == "Clean" then
        Rep_Library.notify(LocalPlayer_2, "You can't put dirty laundry in a clean basket", 4)
        game.SoundService.Misc.Error:Play()
        return
    end
    if LocalPlayer_2.NonSaveVars.TotalWashingMachineCapacity.Value == 0 then
        Rep_Library.notify(LocalPlayer_2, "You don't have enough washing machine capacity", 4)
        game.SoundService.Misc.Error:Play()
        return
    end
    if Owner.Parent == LocalPlayer.NonSaveVars.PetSlot1.Value then
        game.ReplicatedStorage.Events.CollectFromPet:FireServer(1)
        return
    end
    if Owner.Parent == LocalPlayer.NonSaveVars.PetSlot2.Value then
        game.ReplicatedStorage.Events.CollectFromPet:FireServer(2)
    end
end
local function checkHit(p1) -- Line: 515 -- upvalues: u124 (val), Clothing (val), u120 (val), WashingMachines_2 (ref), u121 (val), u122 (val), LocalPlayer (val), u125 (val)
    if p1 then
        return
    end
    local v1 = fireRay()
    if not v1 then
        return
    end
    if v1.Name == "_ClickToSpin" then
        u124(v1)
    end
    if v1.Parent == Clothing then
        u120(v1)
        return
    end
    if WashingMachines_2 then
        local v2 = getWashingMachineFromPart(v1)
        if v2 then
            u121(v2)
        end
        if v1.Parent and v1.Parent.Name == "_FinishChute" then
            u122()
        end
        if v1:FindFirstAncestor(LocalPlayer.Name) then
            u125(v1)
        end
    end
end
local function v3(p1) -- Line: 569 -- upvalues: Rep_Library (val)
    script.Parent.Frame.Coins.Label.Text = Rep_Library.getCoinsPrefixValue(p1)
end
LocalPlayer_2.NonSaveVars.BasketSize.Changed:Connect(function(p1) -- Line: 573 -- upvalues: LocalPlayer_2 (val)
    script.Parent.Frame.Backpack.Label.Text = LocalPlayer_2.NonSaveVars.BackpackAmount.Value .. "/" .. p1
end)
LocalPlayer_2.SaveVars.Coins.Changed:Connect(function(p1) -- Line: 577 -- upvalues: Rep_Library (val)
    script.Parent.Frame.Coins.Label.Text = Rep_Library.getCoinsPrefixValue(p1)
end)
local Label = script.Parent.Frame.Coins.Label
Label.Text = Rep_Library.getCoinsPrefixValue(LocalPlayer_2.SaveVars.Coins.Value)
LocalPlayer_2.SaveVars.Gems.Changed:Connect(function(p1) -- Line: 582
    script.Parent.Frame.Gems.Label.Text = p1
end)
script.Parent.Frame.Gems.Label.Text = LocalPlayer_2.SaveVars.Gems.Value
script.Parent.Frame.Coins.PlusIcon.MouseButton1Click:Connect(function() -- Line: 587 -- upvalues: LocalPlayer_2 (val)
    if LocalPlayer_2.PlayerGui:FindFirstChild("PurchaseCoins") then
        if LocalPlayer_2.PlayerGui:FindFirstChild("ArchysHardware") then
            LocalPlayer_2.PlayerGui.ArchysHardware.Enabled = true
        end
        LocalPlayer_2.PlayerGui.PurchaseCoins:Destroy()
        return
    end
    local v1 = game.ReplicatedStorage.GUIs.PurchaseCoins:Clone()
    v1.Parent = LocalPlayer_2.PlayerGui
    if not (LocalPlayer_2.PlayerGui:FindFirstChild("ArchysHardware")) then
        return
    end
    LocalPlayer_2.PlayerGui.ArchysHardware.Enabled = false
end)
script.Parent.Frame.Gems.PlusIcon.MouseButton1Click:Connect(function() -- Line: 603 -- upvalues: LocalPlayer_2 (val)
    if LocalPlayer_2.PlayerGui:FindFirstChild("PurchaseGems") then
        if LocalPlayer_2.PlayerGui:FindFirstChild("PetShop") then
            LocalPlayer_2.PlayerGui.PetShop.Enabled = true
        end
        LocalPlayer_2.PlayerGui.PurchaseGems:Destroy()
        return
    end
    local v1 = game.ReplicatedStorage.GUIs.PurchaseGems:Clone()
    v1.Parent = LocalPlayer_2.PlayerGui
    if not (LocalPlayer_2.PlayerGui:FindFirstChild("PetShop")) then
        return
    end
    LocalPlayer_2.PlayerGui.PetShop.Enabled = false
end)
script.Parent.CoinPrompt.Yes.MouseButton1Click:Connect(function() -- Line: 619 -- upvalues: LocalPlayer_2 (val)
    if not (LocalPlayer_2.PlayerGui:FindFirstChild("PurchaseCoins")) then
        local v1 = game.ReplicatedStorage.GUIs.PurchaseCoins:Clone()
        v1.Parent = LocalPlayer_2.PlayerGui
    end
    script.Parent.CoinPrompt.Visible = false
end)
script.Parent.CoinPrompt.No.MouseButton1Click:Connect(function() -- Line: 627 -- upvalues: LocalPlayer_2 (val)
    if LocalPlayer_2.PlayerGui:FindFirstChild("ArchysHardware") then
        LocalPlayer_2.PlayerGui.ArchysHardware.Enabled = true
    end
    script.Parent.CoinPrompt.Visible = false
end)
local u207 = true
script.Parent.Frame.Backpack.Magnet.MouseButton1Click:Connect(function() -- Line: 635 -- upvalues: u207 (ref), Rep_Library (val), LocalPlayer_2 (val), Events (val)
    if not u207 then
        u207 = true
        Events.GiveMagnet:FireServer()
        script.Parent.Frame.Backpack.Magnet.Image = "rbxassetid://6289256110"
        Rep_Library.notify(LocalPlayer_2, "Auto grab enabled")
        return
    end
    u207 = false
    script.Parent.Frame.Backpack.Magnet.Image = "rbxassetid://6306009290"
    Rep_Library.notify(LocalPlayer_2, "Auto grab disabled")
    if not (workspace.Debris.Magnets:FindFirstChild("BasketMagnet")) then
        return
    end
    workspace.Debris.Magnets.BasketMagnet:Destroy()
end)
NonSaveVars = LocalPlayer_2:WaitForChild("NonSaveVars")
NonSaveVars:WaitForChild("OwnsPlot")
LocalPlayer_2.NonSaveVars.Backpack.ChildAdded:Connect(function(p1) -- Line: 682
    if p1.Value ~= "" then
        game.SoundService.Misc.PositiveAlert:Play()
    end
end)
if not LocalPlayer_2.NonSaveVars.OwnsPlot.Value then
    LocalPlayer_2.NonSaveVars.OwnsPlot.Changed:Connect(function() -- Line: 692 -- upvalues: LocalPlayer_2 (val), WashingMachines_2 (ref)
        if LocalPlayer_2.NonSaveVars.OwnsPlot.Value then
            WashingMachines_2 = LocalPlayer_2.NonSaveVars.OwnsPlot.Value.WashingMachines
        end
    end)
end
local function u247() -- Line: 699 -- upvalues: Rep_Library (val), LocalPlayer (val)
    local SpinTheWheel = workspace.Debris.NPCVehicles.SpinTheWheel
    SpinTheWheel.Wheel.WheelPieces["Cash Booster 0.05"].AwardImage.SurfaceGui.Frame.TextLabel.Text = "+$" .. Rep_Library.getCoinsPrefixValue((math.ceil(math.max(200, LocalPlayer.SaveVars.MaxCoins.Value) * 0.05)))
    SpinTheWheel.Wheel.WheelPieces["Cash Booster 0.1"].AwardImage.SurfaceGui.Frame.TextLabel.Text = "+$" .. Rep_Library.getCoinsPrefixValue((math.ceil(math.max(200, LocalPlayer.SaveVars.MaxCoins.Value) * 0.1)))
    SpinTheWheel.Wheel.WheelPieces["Cash Booster 0.2"].AwardImage.SurfaceGui.Frame.TextLabel.Text = "+$" .. Rep_Library.getCoinsPrefixValue((math.ceil(math.max(200, LocalPlayer.SaveVars.MaxCoins.Value) * 0.2)))
    SpinTheWheel.Wheel.WheelPieces["Cash Booster 0.3"].AwardImage.SurfaceGui.Frame.TextLabel.Text = "+$" .. Rep_Library.getCoinsPrefixValue((math.ceil(math.max(200, LocalPlayer.SaveVars.MaxCoins.Value) * 0.3)))
end
game.ReplicatedStorage.Events.SpinTheWheelSpawned.OnClientEvent:Connect(function() -- Line: 707 -- upvalues: u247 (val), u109 (ref)
    local SpinTheWheel = workspace.Debris.NPCVehicles:WaitForChild("SpinTheWheel")
    SpinTheWheel:WaitForChild("_ClickToSpin")
    local SpinTheWheel_2 = workspace.Debris.NPCVehicles.SpinTheWheel
    local Wheel = SpinTheWheel_2:WaitForChild("Wheel")
    Wheel:WaitForChild("WheelPieces")
    local v1 = SpinTheWheel_2.Wheel.WheelPieces:WaitForChild("Cash Booster 0.05")
    local AwardImage = v1:WaitForChild("AwardImage")
    local SurfaceGui = AwardImage:WaitForChild("SurfaceGui")
    local Frame = SurfaceGui:WaitForChild("Frame")
    Frame:WaitForChild("TextLabel")
    v1 = SpinTheWheel_2.Wheel.WheelPieces:WaitForChild("Cash Booster 0.1")
    local AwardImage_2 = v1:WaitForChild("AwardImage")
    local SurfaceGui_2 = AwardImage_2:WaitForChild("SurfaceGui")
    local Frame_2 = SurfaceGui_2:WaitForChild("Frame")
    Frame_2:WaitForChild("TextLabel")
    v1 = SpinTheWheel_2.Wheel.WheelPieces:WaitForChild("Cash Booster 0.2")
    local AwardImage_3 = v1:WaitForChild("AwardImage")
    local SurfaceGui_3 = AwardImage_3:WaitForChild("SurfaceGui")
    local Frame_3 = SurfaceGui_3:WaitForChild("Frame")
    Frame_3:WaitForChild("TextLabel")
    v1 = SpinTheWheel_2.Wheel.WheelPieces:WaitForChild("Cash Booster 0.3")
    local AwardImage_4 = v1:WaitForChild("AwardImage")
    local SurfaceGui_4 = AwardImage_4:WaitForChild("SurfaceGui")
    local Frame_4 = SurfaceGui_4:WaitForChild("Frame")
    Frame_4:WaitForChild("TextLabel")
    u247()
    while not workspace.Debris.NPCVehicles.SpinTheWheel.Stopped.Value do
        wait(0.3)
    end
    u109 = workspace.Debris.NPCVehicles.SpinTheWheel._ClickToSpin
end)
RunService.RenderStepped:connect(function() -- Line: 97 -- upvalues: Clothing (val), LocalPlayer_2 (val), Mouse (val), HoverLabel (val), WashingMachines_2 (ref), WashingMachines (val), u75 (val), u116 (val), LocalPlayer (val), u99 (val), u96 (val), u105 (val), u102 (val), u117 (val)
    local u1, u213, v1, v2
    u1, v1 = fireRay()
    if not u1 then
        Mouse.Icon = ""
        HoverLabel.Visible = false
        u75.Adornee = nil
        u117()
        u213 = u105
        if u213[1] then
            u213 = u105
            if u213[1].IsPlaying then
                u105[1]:Stop()
            end
        end
        u213 = u105
        if u213[2] then
            u213 = u105
            if u213[2].IsPlaying then
                u105[2]:Stop()
            end
        end
        return
    end
    if u1.Parent ~= Clothing then
        if WashingMachines_2 then
            v2 = getWashingMachineFromPart(u1)
            if v2 then
                if v2.Config.Capacity.Value < WashingMachines[v2.Name].Capacity then
                    if LocalPlayer_2.Character and LocalPlayer_2.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer_2.Character.HumanoidRootPart.Position - v2.MAIN.Position).Magnitude < 40 then
                        Mouse.Icon = "rbxasset://textures/advCursor-openedHand.png"
                        u75.Adornee = v2.PrimaryPart
                    end
                elseif not v2.Config.CycleFinished.Value then
                end
            end
        end
    elseif LocalPlayer_2.Character and LocalPlayer_2.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer_2.Character.HumanoidRootPart.Position - u1.Position).Magnitude < 28 then
        Mouse.Icon = "rbxasset://textures/advCursor-openedHand.png"
        HoverLabel.Visible = true
        HoverLabel.Position = UDim2.new(0, v1.X, 0, v1.Y - 15)
        if not (u1:FindFirstChild("SpecialTag")) then
            if u1:GetAttribute("Nuclear") then
                HoverLabel.Text = "Nuclear " .. u1.Name
            elseif not (u1:GetAttribute("Cosmic")) then
                HoverLabel.Text = u1.Name
            else
                HoverLabel.Text = "Cosmic " .. u1.Name
            end
        elseif u1:GetAttribute("Nuclear") then
            HoverLabel.Text = "Nuclear " .. u1.SpecialTag.Value .. " " .. u1.Name
        elseif not (u1:GetAttribute("Cosmic")) then
            HoverLabel.Text = u1.SpecialTag.Value .. " " .. u1.Name
        else
            HoverLabel.Text = "Cosmic " .. u1.SpecialTag.Value .. " " .. u1.Name
        end
    end
    if u1.Parent.Name == "_FinishChute" and LocalPlayer_2.Character and LocalPlayer_2.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer_2.Character.HumanoidRootPart.Position - workspace._FinishChute.Handle.Position).Magnitude < 35 then
        Mouse.Icon = "rbxasset://textures/advCursor-openedHand.png"
        u75.Adornee = u1.Parent
        u116()
    end
    if u1.Name == "_ClickToSpin" and LocalPlayer_2.Character and LocalPlayer_2.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer_2.Character.HumanoidRootPart.Position - u1.Position).Magnitude < 35 then
        Mouse.Icon = "rbxasset://textures/advCursor-openedHand.png"
        u75.Adornee = u1
    end
    if not (u1:FindFirstAncestor("Pets")) then
        u213 = u105
        if u213[1] then
            u213 = u105
            if u213[1].IsPlaying then
                u105[1]:Stop()
            end
        end
        u213 = u105
        if u213[2] then
            u213 = u105
            if not (u213[2].IsPlaying) then
                return
            end
            u105[2]:Stop()
            return
        end
        return
    end
    v2 = u1.Parent:FindFirstChild("Owner")
    if not v2 or v2.Value ~= LocalPlayer or not LocalPlayer_2.Character or not (LocalPlayer_2.Character:FindFirstChild("HumanoidRootPart")) or (LocalPlayer_2.Character.HumanoidRootPart.Position - u1.Position).Magnitude >= 35 then
        return
    end
    Mouse.Icon = "rbxasset://textures/advCursor-openedHand.png"
    u213 = nil
    if u1.Parent == LocalPlayer.NonSaveVars.PetSlot1.Value then
        u213 = 1
    elseif u1.Parent == LocalPlayer.NonSaveVars.PetSlot2.Value then
        u213 = 2
    end
    u99[u213] = tick()
    u96[u213].Frame.EnergyBar.Percentage.Size = UDim2.new(u1.Parent.Stats.Energy.Value / 100, 0, 1, 0)
    u96[u213].Parent = u1
    u1.AnimalLabel.Enabled = false
    if u105[u213] and not (u105[u213].IsPlaying) then
        u105[u213]:Play()
    end
    if not (u102[u213]) then
        u102[u213] = true
        delay(2, function() -- Line: 170 -- upvalues: u99 (upval), u213 (ref), u1 (val), u96 (upval), u102 (upval)
            local v1
            while true do
                v1 = tick() - u99[u213]
                if v1 >= 2 then
                    break
                end
                wait()
            end
            u1.AnimalLabel.Enabled = true
            v1 = u96[u213]
            v1.Parent = nil
            u102[u213] = false
        end)
    end
end)
UserInputService.InputBegan:connect(function(p1, p2) -- Line: 540 -- upvalues: checkHit (val), LocalPlayer_2 (val)
    if p2 then
        return
    end
    if p1.UserInputType == Enum.UserInputType.MouseButton1 or p1.UserInputType == Enum.UserInputType.Touch then
        checkHit()
        return
    end
    if p1.UserInputType ~= Enum.UserInputType.Gamepad1 then
        return
    end
    if p1.KeyCode == Enum.KeyCode.ButtonR2 then
        checkHit()
        return
    end
    if p1.KeyCode ~= Enum.KeyCode.ButtonA then
        if p1.KeyCode == Enum.KeyCode.ButtonB and script.Parent.CoinPrompt.Visible then
            if LocalPlayer_2.PlayerGui:FindFirstChild("ArchysHardware") then
                LocalPlayer_2.PlayerGui.ArchysHardware.Enabled = true
            end
            script.Parent.CoinPrompt.Visible = false
        end
        return
    end
    if not script.Parent.CoinPrompt.Visible then
        return
    end
    if not (LocalPlayer_2.PlayerGui:FindFirstChild("PurchaseCoins")) then
        local v1 = game.ReplicatedStorage.GUIs.PurchaseCoins:Clone()
        v1.Parent = LocalPlayer_2.PlayerGui
    end
    script.Parent.CoinPrompt.Visible = false
end)
SaveVars = LocalPlayer:WaitForChild("SaveVars")
SaveVars:WaitForChild("MaxCoins").Changed:Connect(function() -- Line: 732 -- upvalues: u247 (val)
    if workspace.Debris.NPCVehicles:FindFirstChild("SpinTheWheel") and not workspace.Debris.NPCVehicles.SpinTheWheel._ClickToSpin.Spun.Value then
        u247()
    end
end)
local NonSaveVars_2 = LocalPlayer:WaitForChild("NonSaveVars")
NonSaveVars_2:WaitForChild("PetSlot1").Changed:Connect(function() -- Line: 740 -- upvalues: LocalPlayer (val), u105 (val)
    if LocalPlayer.NonSaveVars.PetSlot1.Value then
        wait()
        u105[1] = LocalPlayer.NonSaveVars.PetSlot1.Value.AnimationController:LoadAnimation(LocalPlayer.NonSaveVars.PetSlot1.Value.Animations.Bounce)
    end
end)
local NonSaveVars_3 = LocalPlayer:WaitForChild("NonSaveVars")
NonSaveVars_3:WaitForChild("PetSlot2").Changed:Connect(function() -- Line: 746 -- upvalues: LocalPlayer (val), u105 (val)
    if LocalPlayer.NonSaveVars.PetSlot2.Value then
        wait()
        u105[2] = LocalPlayer.NonSaveVars.PetSlot2.Value.AnimationController:LoadAnimation(LocalPlayer.NonSaveVars.PetSlot2.Value.Animations.Bounce)
    end
end)
wait()
if LocalPlayer.NonSaveVars.PetSlot1.Value and LocalPlayer.NonSaveVars.PetSlot1.Value.AnimationController:FindFirstAncestor("Workspace") then
    u105[1] = LocalPlayer.NonSaveVars.PetSlot1.Value.AnimationController:LoadAnimation(LocalPlayer.NonSaveVars.PetSlot1.Value.Animations.Bounce)
end
if LocalPlayer.NonSaveVars.PetSlot2.Value and LocalPlayer.NonSaveVars.PetSlot2.Value.AnimationController:FindFirstAncestor("Workspace") then
    u105[2] = LocalPlayer.NonSaveVars.PetSlot2.Value.AnimationController:LoadAnimation(LocalPlayer.NonSaveVars.PetSlot2.Value.Animations.Bounce)
end
