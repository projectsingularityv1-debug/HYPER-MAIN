local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- // ระบบเปิด-ปิด (Toggle) //
local env = (getgenv and getgenv()) or _G
env.AutoCoin_Running = not env.AutoCoin_Running

if env.AutoCoin_Running then
    print("🟢 เปิดระบบ: บินเก็บเหรียญอัตโนมัติ")
else
    print("🔴 ปิดระบบ: บินเก็บเหรียญอัตโนมัติ")
    return
end

local function getCoins()
    -- อ้างอิงโฟลเดอร์ตามรูปภาพที่ให้มา: Workspace -> Yacht -> CoinContainer
    local yacht = workspace:FindFirstChild("Yacht")
    if not yacht then return {} end
    
    local container = yacht:FindFirstChild("CoinContainer")
    if not container then return {} end
    
    local coins = {}
    for _, v in ipairs(container:GetChildren()) do
        if v.Name == "Coin_Server" and v:IsA("BasePart") then
            table.insert(coins, v)
        end
    end
    return coins
end

local function tweenTo(targetPart)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    
    -- สร้างระบบต้านแรงโน้มถ่วง (กันตกแมพและกันหมุน)
    local bg = hrp:FindFirstChild("CoinBG") or Instance.new("BodyGyro")
    bg.Name = "CoinBG"
    bg.P = 9e4
    bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.cframe = hrp.CFrame
    bg.Parent = hrp
    
    local bv = hrp:FindFirstChild("CoinBV") or Instance.new("BodyVelocity")
    bv.Name = "CoinBV"
    bv.velocity = Vector3.new(0, 0, 0)
    bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent = hrp
    
    -- เปิดระบบ Noclip เดินทะลุกำแพงขณะบิน
    local noclip
    noclip = RunService.Stepped:Connect(function()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
    
    -- คำนวณความเร็วในการบิน
    local distance = (hrp.Position - targetPart.Position).Magnitude
    local speed = 60 -- ปรับความเร็วในการบินไปเก็บเหรียญ (ถ้าไวไปโดนเตะให้ลดลง)
    local time = distance / speed
    
    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetPart.CFrame})
    
    tween:Play()
    
    -- รอจนกว่าจะบินไปถึงเป้าหมาย
    while tween.PlaybackState == Enum.PlaybackState.Playing do
        -- ถ้าปิดสคริปต์ หรือเหรียญถูกคนอื่นเก็บไปแล้ว ให้หยุดบินทันที
        if not env.AutoCoin_Running or not targetPart or not targetPart.Parent then
            tween:Cancel()
            break
        end
        task.wait()
    end
    
    noclip:Disconnect()
end

task.spawn(function()
    while env.AutoCoin_Running do
        local coins = getCoins()
        
        if #coins > 0 then
            for _, coin in ipairs(coins) do
                if not env.AutoCoin_Running then break end
                if coin and coin.Parent then
                    tweenTo(coin)
                    task.wait(0.2) -- หน่วงเวลาเล็กน้อยตอนเก็บเหรียญเข้าตัว
                end
            end
        else
            -- ถ้าเหรียญหมด ให้รอเหรียญเกิดใหม่
            task.wait(1)
        end
        
        task.wait(0.1)
    end
    
    -- ลบเอฟเฟกต์บินทิ้งเมื่อปิดสคริปต์
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        if hrp:FindFirstChild("CoinBG") then hrp.CoinBG:Destroy() end
        if hrp:FindFirstChild("CoinBV") then hrp.CoinBV:Destroy() end
    end
end)
