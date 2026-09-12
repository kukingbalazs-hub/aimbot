-- ============================================================
--  STEAL A FISH EGG - Auto Steal JAVÍTVA
--  Rayfield GUI - Delta Executor kompatibilis
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Steal A Fish Egg - Auto Steal",
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
    if #names == 0 then names = { "Nincs spawnolt tojás" } end
    if eggDropdown then
        pcall(function() eggDropdown:Refresh(names) end)
    end
    Rayfield:Notify({Title="Refresh", Content=#eggList.." tojás a SpawnedEggs-ben.", Duration=2})
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
                if d < minDist then minDist = d; closest = eggPos end
            end
        end
        if closest then
            hrp.CFrame = CFrame.new(closest + Vector3.new(0, 5, 0))
            Rayfield:Notify({Title="Teleport", Content="Legközelebbi tojásnál vagy!", Duration=2})
        end
    end
})

-- ============================================================
--  AUTO STEAL (JAVÍTOTT - 3 MÓDSZER)
-- ============================================================
local autoStealEnabled = false
local stealRange = 15

EggsTab:CreateSection("Auto Steal")

EggsTab:CreateToggle({
    Name = "Auto Steal BE/KI",
    CurrentValue = false,
    Flag = "AutoStealToggle",
    Callback = function(value)
        autoStealEnabled = value
        Rayfield:Notify({Title="Auto Steal", Content=value and "BEKAPCSOLVA" or "KIKAPCSOLVA", Duration=2})
    end
})

EggsTab:CreateSlider({
    Name = "Steal távolság (stud)",
    Range = {5, 50},
    Increment = 1,
    Suffix = "stud",
    CurrentValue = 15,
    Flag = "StealRangeSlider",
    Callback = function(value)
        stealRange = value
    end
})

-- Auto Steal fő ciklus (külön szálon fut, nem akasztja a UI-t)
task.spawn(function()
    while task.wait(0.15) do
        if autoStealEnabled then
            local hrp = getHRP()
            if hrp then
                -- Legközelebbi tojás keresése
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
                    -- ProximityPrompt keresése
                    local prompt = closestEgg:FindFirstChildWhichIsA("ProximityPrompt", true)
                    
                    -- 1. MÓDSZER: fireproximityprompt (a legtöbb executor támogatja)
                    if prompt then
                        pcall(function()
                            fireproximityprompt(prompt)
                        end)

                        -- 2. MÓDSZER: Ha a prompt nyomvatartást igényel
                        if prompt.HoldDuration and prompt.HoldDuration > 0 then
                            pcall(function()
                                prompt:InputHoldBegin()
                                task.wait(prompt.HoldDuration + 0.05)
                                prompt:InputHoldEnd()
                            end)
                        end
                    end

                    -- 3. MÓDSZER: E gomb szimulálása (ez a legmegbízhatóbb)
                    pcall(function()
                        keypress(0x45) -- 0x45 = E gomb
                        task.wait(0.1)
                        keyrelease(0x45)
                    end)
                end
            end
        end
    end
end)

-- ============================================================
--  AUTOMATIKUS FRISSÍTÉS
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
    Content = "Auto Steal javított verzió aktív. Állítsd be a távolságot!",
    Duration = 5
})
