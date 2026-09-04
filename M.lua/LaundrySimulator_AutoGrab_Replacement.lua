-- Replace the original "-- // Auto Grab" task.spawn block with this block.
-- Client-only: it reads LocalPlayer state and sends only GrabClothing requests.

local clothingFolder = workspace:WaitForChild("Debris"):WaitForChild("Clothing")
local queuedClothes = setmetatable({}, { __mode = "k" })
local pickupQueue = {}
local queueHead = 1
local queueTail = 0

-- Preserve the original pickup throughput for new clothes while avoiding spam.
local REQUEST_INTERVAL = 0.05
local RETRY_DELAY = 0.45
local IDLE_INTERVAL = 0.10

local function enqueueCloth(cloth)
    if not getgenv().AutoGrab or not cloth or cloth.Parent ~= clothingFolder or queuedClothes[cloth] then
        return
    end

    queuedClothes[cloth] = true
    queueTail = queueTail + 1
    pickupQueue[queueTail] = cloth
end

local function getNextCloth()
    while queueHead <= queueTail do
        local cloth = pickupQueue[queueHead]
        pickupQueue[queueHead] = nil
        queueHead = queueHead + 1
        if cloth then
            queuedClothes[cloth] = nil
        end

        if cloth and cloth.Parent == clothingFolder then
            return cloth
        end
    end

    -- Release processed entries instead of letting the queue grow during long sessions.
    pickupQueue = {}
    queueHead = 1
    queueTail = 0
    return nil
end

local childAddedConnection = clothingFolder.ChildAdded:Connect(enqueueCloth)

task.spawn(function()
    local wasAutoGrabEnabled = false

    while getgenv().LaundryFarmRunning do
        if not getgenv().AutoGrab then
            wasAutoGrabEnabled = false
            task.wait(IDLE_INTERVAL)
            continue
        end

        -- Scan existing clothes only once when Auto Grab is enabled.
        if not wasAutoGrabEnabled then
            wasAutoGrabEnabled = true
            for _, cloth in ipairs(clothingFolder:GetChildren()) do
                enqueueCloth(cloth)
            end
        end

        local ok, clothOrError = pcall(function()
            if LocalPlayer.NonSaveVars.BackpackAmount.Value >= LocalPlayer.NonSaveVars.BasketSize.Value then
                return nil
            end
            return getNextCloth()
        end)

        if not ok then
            DebugLog("AutoGrab queue error: " .. tostring(clothOrError))
            task.wait(0.25)
            continue
        end

        local cloth = clothOrError
        if not cloth then
            task.wait(IDLE_INTERVAL)
            continue
        end

        local sent, sendError = pcall(function()
            Events.GrabClothing:FireServer(cloth)
        end)

        if not sent then
            DebugLog("AutoGrab request error: " .. tostring(sendError))
        end

        -- Requeue only after the server/replication has had time to remove the cloth.
        task.delay(sent and RETRY_DELAY or 0.25, function()
            if getgenv().LaundryFarmRunning and getgenv().AutoGrab and cloth.Parent == clothingFolder then
                enqueueCloth(cloth)
            end
        end)

        task.wait(REQUEST_INTERVAL)
    end

    childAddedConnection:Disconnect()
end)
