local getgenv = getgenv or function() return _G end

-- เปลี่ยนเป็น false หากต้องการหยุดทำงาน
getgenv().AutoFarmTree5 = true 

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Network = ReplicatedStorage:WaitForChild("Network")
local Items = Network:WaitForChild("Items")
local EquipItemEvent = Items:WaitForChild("EquipItem")
local ToolActionEvent = Items:WaitForChild("ToolAction")

print("เริ่มระบบ Auto-Farm ต้นไม้...")

task.spawn(function()
    while getgenv().AutoFarmTree5 do
        -- ความเร็วในการยิงคำสั่ง (ลดได้ แต่อย่าให้ไวเกินเดี๋ยวเกมค้าง)
        task.wait(0.1) 
        
        -- ถือขวานวนไปเรื่อยๆ เพื่อให้ชัวร์ว่าถืออยู่
        EquipItemEvent:FireServer(1)
        
        local treesFound = 0
        
        for _, instance in ipairs(Workspace:GetDescendants()) do
            if instance.Name == "Tree5" then
                treesFound = treesFound + 1
                
                task.spawn(function()
                    -- ยิงคำสั่งรัวๆ เนื่องจากต้นไม้อาจจะมีเลือด (HP) หรือต้องตีหลายครั้งกว่าจะแตก
                    ToolActionEvent:FireServer("click", nil, true)
                end)
                
                -- หากตีแล้วไม่เข้า อาจเป็นเพราะเกมบังคับให้ "ตัวละครต้องอยู่ใกล้ต้นไม้"
                -- หากเป็นกรณีนั้น ให้ลบเครื่องหมาย -- หน้าบรรทัดด้านล่างออก เพื่อเปิดระบบวาร์ปไปหาต้นไม้
                --[[
                local Players = game:GetService("Players")
                local char = Players.LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") and instance:IsA("Model") and instance.PrimaryPart then
                    char.HumanoidRootPart.CFrame = instance.PrimaryPart.CFrame
                elseif char and char:FindFirstChild("HumanoidRootPart") and instance:IsA("BasePart") then
                    char.HumanoidRootPart.CFrame = instance.CFrame
                end
                ]]--
            end
        end
        
        -- ถ้าไม่มีต้นไม้ให้รอสักพักก่อนเริ่มหาใหม่ จะได้ไม่กินสเปคคอม
        if treesFound == 0 then
            task.wait(1)
        end
    end
end)
