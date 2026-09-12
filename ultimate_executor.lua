-- ============================================================
--  KUKING HUB - Steal A Fish Egg
--  Rayfield GUI - Delta Executor compatible
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Kuking Hub",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by Kuking",
    ConfigurationSaving = { Enabled = false }
})

local MainTab = Window:CreateTab("Main", 4483362458)
local EggsTab = Window:CreateTab("FishEggs", 4483362458)

-- ============================================================
--  HELPER FUNCTIONS
-- ============================================================
local function getHRP()
    local char = LocalPlayer.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
    return nil
end

local function getPositionFromInstance(inst)
    if inst:IsA("BasePart") then return inst.Position end
    if inst:IsA("Model") then
        local primary = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
        if primary then return primary.Position end
    end
    local part = inst:FindFirstChildWhichIsA("BasePart", true)
    if part then return part.Position end
    return nil
end

-- ============================================================
--  SPEED HACK
-- ============================================================
local currentSpeed = 16

MainTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 500},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 16,
    Flag = "SpeedSlider",
    Callback = function(value)
        currentSpeed = value
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = value end
        end
    end,
})

MainTab:CreateButton({
    Name = "▶ Apply Speed Now",
    Callback = function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = currentSpeed end
        end
    end
})

MainTab:CreateButton({
    Name = "🔄 Reset Speed (16)",
    Callback = function()
        currentSpeed = 16
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = currentSpeed end
end)

-- ============================================================
--  SPAWNEDEGGS HANDLING
-- ============================================================
local eggList = {}
local eggDropdown

local function findSpawnedEggs()
    local folder = game.Workspace:FindFirstChild("SpawnedEggs")
    if folder then return folder end
    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        if obj.Name == "SpawnedEggs" then return obj end
    end
    return nil
end

local function collectEggs()
    local eggs = {}
    local folder = findSpawnedEggs()
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Model") or child:IsA("BasePart") then
                table.insert(eggs, child)
            end
        end
    end
    return eggs
end

local function refreshEggs()
    eggList = collectEggs()
    local names = {}
    for i, e in ipairs(eggList) do
        table.insert(names, e.Name)
    end
    if #names == 0 then names = { "No spawned eggs" } end
    if eggDropdown then
        pcall(function() eggDropdown:Refresh(names) end)
    end
    Rayfield:Notify({Title="Refresh", Content=#eggList.." eggs in SpawnedEggs.", Duration=2})
end

-- ============================================================
--  EGG LIST & TELEPORT
-- ============================================================
eggDropdown = EggsTab:CreateDropdown({
    Name = "Spawned Eggs",
    Options = { "Click Refresh" },
    CurrentOption = { "Click Refresh" },
    MultipleOptions = false,
    Flag = "EggDropdown",
    Callback = function(opt)
        local chosen = type(opt) == "table" and opt[1] or opt
        if not chosen or chosen == "No spawned eggs" or chosen == "Click Refresh" then return end
        for _, e in ipairs(eggList) do
            if e.Name == chosen then
                local pos = getPositionFromInstance(e)
                if pos then
                    local hrp = getHRP()
                    if hrp then
                        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
                        Rayfield:Notify({Title="Teleport", Content="Teleported to: "..e.Name, Duration=2})
                    end
                end
                return
            end
        end
    end
})

EggsTab:CreateButton({
    Name = "🔄 Refresh List",
    Callback = function() refreshEggs() end
})

EggsTab:CreateButton({
    Name = "🏃 Teleport to Closest Egg",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end
        local closest, minDist = nil, math.huge
        for _, egg in ipairs(eggList) do
            local eggPos = getPositionFromInstance(egg)
            if eggPos then
                local d = (eggPos - hrp.Position).Magnitude
                if d < minDist then minDist = d; closest = eggPos end
            end
        end
        if closest then
            hrp.CFrame = CFrame.new(closest + Vector3.new(0, 5, 0))
            Rayfield:Notify({Title="Teleport", Content="You are at the closest egg!", Duration=2})
        end
    end
})

-- ============================================================
--  AUTO STEAL (IMPROVED - 3 METHODS)
-- ============================================================
local autoStealEnabled = false
local stealRange = 15

EggsTab:CreateSection("Auto Steal")

EggsTab:CreateToggle({
    Name = "Auto Steal ON/OFF",
    CurrentValue = false,
    Flag = "AutoStealToggle",
    Callback = function(value)
        autoStealEnabled = value
        Rayfield:Notify({Title="Auto Steal", Content=value and "ENABLED" or "DISABLED", Duration=2})
    end
})

EggsTab:CreateSlider({
    Name = "Steal Range (studs)",
    Range = {5, 50},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 15,
    Flag = "StealRangeSlider",
    Callback = function(value)
        stealRange = value
    end
})

-- Main Auto Steal loop (runs in separate thread)
task.spawn(function()
    while task.wait(0.15) do
        if autoStealEnabled then
            local hrp = getHRP()
            if hrp then
                -- Find closest egg
                local closestEgg, minDist = nil, math.huge
                for _, egg in ipairs(eggList) do
                    local eggPos = getPositionFromInstance(egg)
                    if eggPos then
                        local d = (eggPos - hrp.Position).Magnitude
                        if d < minDist then
                            minDist = d
                            closestEgg = egg
                        end
                    end
                end

                if closestEgg and minDist <= stealRange then
                    -- Search for ProximityPrompt
                    local prompt = closestEgg:FindFirstChildWhichIsA("ProximityPrompt", true)
                    
                    -- METHOD 1: fireproximityprompt
                    if prompt then
                        pcall(function()
                            fireproximityprompt(prompt)
                        end)

                        -- METHOD 2: If prompt requires holding
                        if prompt.HoldDuration and prompt.HoldDuration > 0 then
                            pcall(function()
                                prompt:InputHoldBegin()
                                task.wait(prompt.HoldDuration + 0.05)
                                prompt:InputHoldEnd()
                            end)
                        end
                    end

                    -- METHOD 3: Simulate E key press
                    pcall(function()
                        keypress(0x45) -- 0x45 = E key
                        task.wait(0.1)
                        keyrelease(0x45)
                    end)
                end
            end
        end
    end
end)

-- ============================================================
--  AUTO REFRESH
-- ============================================================
task.spawn(function()
    local folder = findSpawnedEggs()
    if folder then
        folder.ChildAdded:Connect(function()
            task.wait(0.5)
            refreshEggs()
        end)
        folder.ChildRemoved:Connect(function()
            task.wait(0.5)
            refreshEggs()
        end)
    end
end)

-- ============================================================
--  FIRST LOAD
-- ============================================================
task.spawn(function()
    task.wait(1)
    refreshEggs()
end)

Rayfield:Notify({
    Title = "Kuking Hub",
    Content = "Loaded! Auto Steal improved version active.",
    Duration = 5
})
