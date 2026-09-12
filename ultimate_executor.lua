-- ============================================================
--  STEAL A FISH EGG - SpawnedEggs Auto-Refresh
--  Rayfield GUI - Delta Executor kompatibilis
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Steal A Fish Egg - SpawnedEggs",
    LoadingTitle = "Betöltés...",
    LoadingSubtitle = "by Te",
    ConfigurationSaving = { Enabled = false }
})

local MainTab = Window:CreateTab("Főmenü", 4483362458)
local EggsTab = Window:CreateTab("FishEggs", 4483362458)

-- ============================================================
--  SEGÉDFÜGGVÉNYEK
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
    Name = "WalkSpeed (Gyorsaság)",
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
    Name = "▶ Speed alkalmazása most",
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
--  SPAWNEDEGGS KEZELÉSE
-- ============================================================
local eggList = {}
local eggDropdown

-- Megkeresi a SpawnedEggs mappát a Workspace-ben
local function findSpawnedEggs()
    local folder = game.Workspace:FindFirstChild("SpawnedEggs")
    if folder then return folder end
    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        if obj.Name == "SpawnedEggs" then return obj end
    end
    return nil
end

-- Összegyűjti a tojásokat a SpawnedEggs mappából
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

-- Frissíti a listát és a legördülő menüt
local function refreshEggs()
    eggList = collectEggs()
    local names = {}
    for i, e in ipairs(eggList) do
        table.insert(names, e.Name)
    end
    
    if #names == 0 then 
        names = { "Nincs spawnolt tojás" } 
    end

    if eggDropdown then
        pcall(function()
            eggDropdown:Refresh(names)
        end)
    end
    
    Rayfield:Notify({Title="Refresh", Content=#eggList.." tojás a SpawnedEggs-ben.", Duration=3})
end

-- ============================================================
--  TOJÁS LISTA ÉS TELEPORT
-- ============================================================
eggDropdown = EggsTab:CreateDropdown({
    Name = "Spawned tojások",
    Options = { "Kattints a Refresh-re" },
    CurrentOption = { "Kattints a Refresh-re" },
    MultipleOptions = false,
    Flag = "EggDropdown",
    Callback = function(opt)
        local chosen = type(opt) == "table" and opt[1] or opt
        if not chosen or chosen == "Nincs spawnolt tojás" or chosen == "Kattints a Refresh-re" then return end
        
        for _, e in ipairs(eggList) do
            if e.Name == chosen then
                local pos = getPositionFromInstance(e)
                if pos then
                    local hrp = getHRP()
                    if hrp then
                        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
                        Rayfield:Notify({Title="Teleport", Content="Odamentél: "..e.Name, Duration=2})
                    end
                else
                    Rayfield:Notify({Title="Hiba", Content="Nincs pozíciója a tojásnak!", Duration=3})
                end
                return
            end
        end
    end
})

EggsTab:CreateButton({
    Name = "🔄 Refresh lista",
    Callback = function() refreshEggs() end
})

EggsTab:CreateButton({
    Name = "🏃 Teleport a legközelebbi tojáshoz",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end
        
        local closest, minDist = nil, math.huge
        for _, egg in ipairs(eggList) do
            local eggPos = getPositionFromInstance(egg)
            if eggPos then
                local d = (eggPos - hrp.Position).Magnitude
                if d < minDist then 
                    minDist = d
                    closest = eggPos 
                end
            end
        end
        
        if closest then
            hrp.CFrame = CFrame.new(closest + Vector3.new(0, 5, 0))
            Rayfield:Notify({Title="Teleport", Content="Legközelebbi tojásnál vagy!", Duration=2})
        else
            Rayfield:Notify({Title="Hiba", Content="Nincs tojás a listában!", Duration=3})
        end
    end
})

-- ============================================================
--  AUTO STEAL
-- ============================================================
local autoStealEnabled = false

EggsTab:CreateToggle({
    Name = "Auto Steal (Prompt aktiválás)",
    CurrentValue = false,
    Flag = "AutoStealToggle",
    Callback = function(value)
        autoStealEnabled = value
    end
})

RunService.Heartbeat:Connect(function()
    if not autoStealEnabled then return end
    local hrp = getHRP()
    if not hrp then return end

    local closest, minDist = nil, math.huge
    for _, egg in ipairs(eggList) do
        local eggPos = getPositionFromInstance(egg)
        if eggPos then
            local d = (eggPos - hrp.Position).Magnitude
            if d < minDist then 
                minDist = d
                closest = egg 
            end
        end
    end

    if closest and minDist < 15 then
        local prompt = closest:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            pcall(function()
                fireproximityprompt(prompt)
                prompt:InputHoldBegin()
                task.wait(0.1)
                prompt:InputHoldEnd()
            end)
        end
    end
end)

-- ============================================================
--  AUTOMATIKUS FRISSÍTÉS (ha új tojás spawnol / eltűnik)
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
--  ELSŐ BETÖLTÉS
-- ============================================================
task.spawn(function()
    task.wait(1)
    refreshEggs()
end)

Rayfield:Notify({
    Title = "Betöltve!",
    Content = "SpawnedEggs script aktív. A lista automatikusan frissül!",
    Duration = 5
})
