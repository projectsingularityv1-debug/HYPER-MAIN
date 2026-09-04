-- GithubImageTest.lua (Mini Key Verifier Test)
-- โค้ดสำหรับทดสอบใส่คีย์ -> ตรวจสอบ -> ดึงรูปโปรไฟล์และชื่อเจ้าของคีย์มาแสดงผล

local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- ตั้งค่า URL ของ API ที่ใช้ตรวจสอบคีย์
local KeyVerifyURL = "https://projectsingularity.online/raw/verify-key"

-- ฟังก์ชันสำหรับดาวน์โหลดและแปลงเป็น Asset ID ของ Roblox
local function LoadCustomImage(url, fileName)
    if not url or url == "" then return "" end
    if not isfile or not writefile or not getcustomasset then
        warn("Executor ของคุณไม่รองรับ getcustomasset")
        return ""
    end

    local success, imageData = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or not imageData then
        warn("ดาวน์โหลดรูปภาพไม่สำเร็จ: " .. tostring(url))
        return ""
    end

    writefile(fileName, imageData)
    return getcustomasset(fileName)
end

-- ==========================================================
-- สร้าง UI
-- ==========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GithubImageTestGUI"
ScreenGui.Parent = gethui and gethui() or CoreGui

-- ลบอันเก่าทิ้งถ้ามี
for _, v in pairs(ScreenGui.Parent:GetChildren()) do
    if v.Name == "GithubImageTestGUI" and v ~= ScreenGui then
        v:Destroy()
    end
end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 350, 0, 400)
Frame.Position = UDim2.new(0.5, -175, 0.5, -200)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 15)
UICorner.Parent = Frame

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -10, 0, -10)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = Frame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.Position = UDim2.new(0, 0, 0, 10)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Mini Key Verifier Test"
TitleLabel.TextColor3 = Color3.fromRGB(255, 128, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 20
TitleLabel.Parent = Frame

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1, -40, 0, 40)
KeyBox.Position = UDim2.new(0, 20, 0, 60)
KeyBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyBox.PlaceholderText = "Enter your key here..."
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextSize = 14

-- Auto load saved key
local savedKey = ""
pcall(function()
    if isfile and isfile("SingularityKey.txt") then
        savedKey = readfile("SingularityKey.txt")
    end
end)
KeyBox.Text = savedKey

KeyBox.Parent = Frame

local BoxCorner = Instance.new("UICorner")
BoxCorner.CornerRadius = UDim.new(0, 8)
BoxCorner.Parent = KeyBox

local VerifyButton = Instance.new("TextButton")
VerifyButton.Size = UDim2.new(1, -40, 0, 40)
VerifyButton.Position = UDim2.new(0, 20, 0, 110)
VerifyButton.BackgroundColor3 = Color3.fromRGB(255, 128, 0)
VerifyButton.Text = "Verify & Load Profile"
VerifyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
VerifyButton.Font = Enum.Font.GothamBold
VerifyButton.TextSize = 16
VerifyButton.Parent = Frame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = VerifyButton

-- ส่วนแสดงผล Profile
local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Size = UDim2.new(0, 120, 0, 120)
AvatarImage.Position = UDim2.new(0.5, -60, 0, 170)
AvatarImage.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
AvatarImage.ScaleType = Enum.ScaleType.Fit
AvatarImage.Parent = Frame

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0) -- วงกลม
AvatarCorner.Parent = AvatarImage

local UsernameLabel = Instance.new("TextLabel")
UsernameLabel.Size = UDim2.new(1, 0, 0, 30)
UsernameLabel.Position = UDim2.new(0, 0, 0, 300)
UsernameLabel.BackgroundTransparency = 1
UsernameLabel.Text = "Username: ???"
UsernameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
UsernameLabel.Font = Enum.Font.GothamBold
UsernameLabel.TextSize = 18
UsernameLabel.Parent = Frame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Position = UDim2.new(0, 0, 0, 340)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Waiting for key..."
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 14
StatusLabel.Parent = Frame

-- ==========================================================
-- ฟังก์ชันตรวจสอบคีย์
-- ==========================================================
VerifyButton.MouseButton1Click:Connect(function()
    local key = KeyBox.Text
    if key == "" then
        StatusLabel.Text = "Please enter a key!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        return
    end

    StatusLabel.Text = "Verifying..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    VerifyButton.Text = "..."
    
    task.spawn(function()
        local rbx_id = 0
        pcall(function()
            rbx_id = game:GetService("Players").LocalPlayer.UserId
        end)
        
        local success, response = pcall(function()
            local requestFunc = (request or http_request or (syn and syn.request) or (http and http.request))
            if requestFunc then
                local body = HttpService:JSONEncode({ key = key, rbx_user = "Tester", rbx_id = rbx_id })
                local res = requestFunc({
                    Url = KeyVerifyURL,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = body
                })
                return HttpService:JSONDecode(res.Body)
            else
                -- Fallback using GET if request is not available
                local url = KeyVerifyURL .. "?k=" .. key .. "&rbx_user=Tester&rbx_id=" .. tostring(rbx_id)
                return HttpService:JSONDecode(game:HttpGet(url))
            end
        end)
        
        VerifyButton.Text = "Verify & Load Profile"

        if success and response then
            if response.valid then
                StatusLabel.Text = "Valid Key! Loading avatar..."
                StatusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
                
                -- ดึงชื่อและรูปลง UI
                local profile = response.profile or {}
                local username = profile.username or "Unknown User"
                local avatarUrl = profile.avatar_url or ""
                
                UsernameLabel.Text = "User: " .. username
                
                if avatarUrl ~= "" then
                    local savedFileName = "test_profile_avatar_" .. tostring(math.random(1000, 9999)) .. ".png"
                    local customAsset = LoadCustomImage(avatarUrl, savedFileName)
                    
                    if customAsset ~= "" then
                        AvatarImage.Image = customAsset
                        StatusLabel.Text = "Avatar Loaded Successfully!"
                    else
                        StatusLabel.Text = "Failed to load Avatar"
                        StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                    end
                else
                    StatusLabel.Text = "No Avatar URL found"
                end
            else
                StatusLabel.Text = "Invalid Key: " .. tostring(response.message)
                StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            end
        else
            StatusLabel.Text = "Error connecting to server"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
    end)
end)
