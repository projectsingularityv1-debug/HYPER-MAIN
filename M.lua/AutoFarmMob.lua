local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- ป้องกันการรันสคริปต์ซ้อนกัน (Anti-Overlap)
local env = (getgenv and getgenv()) or _G
if env.AutoFarmMobSystem then
    if env.AutoFarmMobSystem.InputConnection then env.AutoFarmMobSystem.InputConnection:Disconnect() end
    if env.AutoFarmMobSystem.NoclipConnection then env.AutoFarmMobSystem.NoclipConnection:Disconnect() end
    if env.AutoFarmMobSystem.CurrentTween then env.AutoFarmMobSystem.CurrentTween:Cancel() end
    env.AutoFarmMobSystem.Running = false
end
env.AutoFarmMobSystem = {
    Running = false,
    InputConnection = nil,
    NoclipConnection = nil,
    CurrentTween = nil
}
local system = env.AutoFarmMobSystem

local player = Players.LocalPlayer
local FLY_SPEED = 100 -- ความเร็วในการบินทะลุกำแพง

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
                    if humanoid and humanoid.Health > 0 and hrp then
                        return hrp
                    end
                end
            end
            
            local enemySpawns = world:FindFirstChild("EnemySpawns")
            if enemySpawns then
                for _, spawnPart in ipairs(enemySpawns:GetChildren()) do
                    if spawnPart:IsA("BasePart") then
                        return spawnPart
                    end
                end
            end
        end
    end
    return nil
end

local function toggleAutoFarm()
    system.Running = not system.Running
    
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if system.Running then
        print("🟢 เปิดระบบ Auto Farm (บินทะลุกำแพงตีมอน)")
        
        -- ทะลุกำแพง (Noclip)
        if not system.NoclipConnection then
            system.NoclipConnection = RunService.Stepped:Connect(function()
                if player.Character then
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
        
        -- ลูปการฟาร์ม
        task.spawn(function()
            while system.Running do
                char = player.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then
                    task.wait(1)
                    continue
                end
                
                hrp = char.HumanoidRootPart
                
                -- ล็อคตัวละครเพื่อไม่ให้สั่น (Jitter) และไม่ให้ตกแมพ
                hrp.Anchored = true
                
                local target = getTargetMonster()
                
                if target then
                    local distance = (hrp.Position - target.Position).Magnitude
                    local timeToReach = distance / FLY_SPEED
                    
                    local tweenInfo = TweenInfo.new(timeToReach, Enum.EasingStyle.Linear)
                    -- บินไปอยู่ด้านบนเป้าหมายเล็กน้อย และหันหน้ามองเป้าหมาย
                    local goalPos = target.Position + Vector3.new(0, 0, 3) -- ย้ายมาอยู่ด้านหลัง/ข้างๆ มอนแทนด้านบน เพื่อให้ระยะฟันถึงแน่นอน
                    local goalCFrame = CFrame.new(goalPos, target.Position)
                    
                    system.CurrentTween = TweenService:Create(hrp, tweenInfo, {CFrame = goalCFrame})
                    system.CurrentTween:Play()
                    
                    while system.Running and target and target.Parent do
                        local currentDist = (hrp.Position - target.Position).Magnitude
                        
                        -- ตรวจสอบว่าเป้าหมายมีเลือด (เป็นมอนสเตอร์) หรือไม่
                        local enemyHumanoid = nil
                        if target.Parent and target.Parent:FindFirstChild("Humanoid") then
                            enemyHumanoid = target.Parent:FindFirstChild("Humanoid")
                        end
                        
                        if currentDist < 10 then
                            -- ยกเลิกการบินเมื่อถึงตัว
                            if system.CurrentTween then system.CurrentTween:Cancel() end
                            
                            -- หันหน้าเข้าหามอนสเตอร์ตลอดเวลาตอนตี (ยังคงถูกล็อคให้อยู่กับที่ ไม่ตกแมพ)
                            hrp.CFrame = CFrame.new(hrp.Position, target.Position)
                            
                            -- ลูปออโต้คลิก (สแปมโจมตีจนกว่ามอนจะตาย)
                            local VirtualUser = game:GetService("VirtualUser")
                            while system.Running and target and target.Parent do
                                
                                -- ล็อคเป้าหันหน้าหามอนสเตอร์ตลอดเวลาป้องกันเป้าเคลื่อน
                                hrp.CFrame = CFrame.new(hrp.Position, target.Position)
                                
                                -- 1. บังคับสวมใส่อาวุธทั้งหมดที่มีในกระเป๋า (เผื่อลืมถือดาบ)
                                pcall(function()
                                    if player.Backpack then
                                        for _, tool in ipairs(player.Backpack:GetChildren()) do
                                            if tool:IsA("Tool") then
                                                char.Humanoid:EquipTool(tool)
                                            end
                                        end
                                    end
                                end)

                                -- 2. สั่งให้อาวุธที่ถืออยู่ทำงาน
                                pcall(function()
                                    for _, v in ipairs(char:GetChildren()) do
                                        if v:IsA("Tool") then
                                            v:Activate()
                                        end
                                    end
                                end)
                                
                                -- 3. จำลองการคลิกเมาส์ซ้ายของจริง (ใช้ได้กับตัวรันสคริปต์ส่วนใหญ่)
                                if mouse1click then
                                    pcall(mouse1click)
                                end
                                
                                -- 4. ใช้ VirtualUser เพื่อจำลองการคลิกเมาส์
                                pcall(function()
                                    VirtualUser:CaptureController()
                                    VirtualUser:ClickButton1(Vector2.new(500, 500))
                                end)

                                -- 5. ใช้ Remote Event ที่บันทึกมา (Cobalt)
                                pcall(function()
                                    local Event = game:GetService("Players").LocalPlayer:FindFirstChild("startevent")
                                    if Event then
                                        Event:FireServer("target", target)
                                    end
                                end)
                                
                                -- ถ้ามอนสเตอร์ตาย (เลือด <= 0) ให้หยุดตีเพื่อไปหาตัวใหม่ทันที
                                if enemyHumanoid and enemyHumanoid.Health <= 0 then
                                    break
                                end
                                
                                -- ถ้าระยะห่างมากเกินไป (มอนกระเด็น) ให้หลุดลูปเพื่อบินตามใหม่
                                local newDist = (hrp.Position - target.Position).Magnitude
                                if newDist > 15 then
                                    break
                                end
                                
                                task.wait(0.1) -- ความเร็วในการรัวคลิก
                            end
                            
                            -- หลุดออกจากลูปนี้เพื่อเริ่มหาตัวใหม่จาก getTargetMonster() ทันที
                            break
                        end
                        task.wait(0.1)
                    end
                else
                    task.wait(1) -- รอถ้าระบบหามอนสเตอร์ไม่เจอ
                end
            end
        end)
    else
        print("🔴 ปิดระบบ Auto Farm")
        if system.CurrentTween then
            system.CurrentTween:Cancel()
            system.CurrentTween = nil
        end
        if system.NoclipConnection then
            system.NoclipConnection:Disconnect()
            system.NoclipConnection = nil
        end
        -- ปลดล็อคตัวละครเมื่อปิดระบบ
        if hrp then
            hrp.Anchored = false
        end
    end
end

-- ตั้งค่าปุ่มเปิด/ปิด (ปัจจุบันคือปุ่ม H)
system.InputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.H then
        toggleAutoFarm()
    end
end)
