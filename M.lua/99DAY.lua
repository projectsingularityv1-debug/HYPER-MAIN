local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local function FlyAndDig()
    -- หาโฟลเดอร์ Foliage
    local map = workspace:FindFirstChild("Map")
    local foliage = map and map:FindFirstChild("Foliage")
    
    if foliage then
        local children = foliage:GetChildren()
        
        -- ตรวจสอบว่ามีต้นไม้ต้นที่ 25 และมี Trunk หรือไม่
        if children[25] then
            local targetTree = children[25]
            local trunk = targetTree:FindFirstChild("Trunk")
            
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if trunk and hrp then
                -- 1. คำนวณความเร็วและเวลาในการบิน
                local speed = 100 -- ความเร็วในการบิน (ปรับเพิ่ม/ลดได้)
                local distance = (hrp.Position - trunk.Position).Magnitude
                local timeToFly = distance / speed
                
                -- สร้าง BodyVelocity เพื่อกันตัวละครตกแมพขณะบิน
                local bodyVel = Instance.new("BodyVelocity")
                bodyVel.Velocity = Vector3.new(0, 0, 0)
                bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bodyVel.Parent = hrp
                


                
                -- 2. บิน (Tween) ไปหา Trunk
                local tween = TweenService:Create(hrp, TweenInfo.new(timeToFly, Enum.EasingStyle.Linear), {CFrame = trunk.CFrame})
                tween:Play()
                
                -- 3. เมื่อบินไปถึง ให้ทำการขุด
                tween.Completed:Connect(function()
                    bodyVel:Destroy() -- ลบตัวกันตกแมพออกเมื่อถึงที่หมาย
                    
                    -- ตรวจสอบหา Tool (อุปกรณ์) ที่ถืออยู่ในมือ
                    local tool = char:FindFirstChildOfClass("Tool")
                    local hitPart = nil
                    
                    if tool and tool:FindFirstChild("Handle") then
                        hitPart = tool.Handle
                    else
                        -- ถ้าไม่ได้ถือ Tool จะใช้ตัวละคร (HumanoidRootPart) ชนแทน
                        hitPart = hrp 
                    end
                    
                    -- จำลองการสัมผัสด้วย firetouchinterest รัวๆ จนกว่าไม้จะพัง (Trunk หายไป)
                    if hitPart then
                        print("เริ่มตีไม้...")
                        task.spawn(function()
                            while trunk and trunk.Parent do
                                -- จำลองการเอาขวาน/ตัว ไปชนไม้
                                firetouchinterest(hitPart, trunk, 0) 
                                task.wait(0.01) -- ความเร็วในการตีรัวๆ
                                firetouchinterest(hitPart, trunk, 1)
                                
                                -- สั่งให้ Tool ทำงาน (เผื่อเกมต้องการให้คลิกด้วย)
                                if tool and tool:FindFirstChild("Activate") then
                                    pcall(function() tool:Activate() end)
                                end
                                
                                task.wait(0.05) -- หน่วงเวลาเล็กน้อยกันเซิร์ฟเวอร์เตะ
                            end
                            print("ตีไม้สำเร็จ! ต้นไม้พังแล้ว")
                        end)
                    end
                end)
                
            else
                print("ไม่พบ Trunk หรือ HumanoidRootPart")
            end
        else
            print("ไม่พบต้นไม้ต้นที่ 25")
        end
    end
end

-- สั่งทำงาน
FlyAndDig()
