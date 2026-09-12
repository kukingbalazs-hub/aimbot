-- ============================================================
--  STEAL A FISH EGG - Végleges Javított (SpawnedEggs alapján)
--  Rayfield GUI - Delta Executor kompatibilis
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Steal A Fish Egg - Végleges",
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

local function teleportTo(pos)
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
        return true
    end
    return false
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
            if hum then
                hum.WalkSpeed = currentSpeed
                Rayfield:Notify({Title="Speed", Content="Beállítva: "..currentSpeed, Duration=2})
            end
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
--  FISHEGGS GYŰJTÉS (VÉGLEGES JAVÍTÁS)
-- ============================================================
local eggList = {}
local eggDropdown

-- Ezekben a mappákban keressük a tojásokat (közvetlenül a mappában lévő Model/BasePart)
local VALID_EGG_FOLDERS = {
    "SpawnedEggs",
    "PlacedEggs",
    "DroppedFishEggs",
    "CarriedEggs",
    "EggSpawns",
    "FishEggs"
}

local function getPositionFromInstance(inst)
    if inst:IsA("BasePart") then
        return inst.Position
    elseif inst:IsA("Model") then
        local primary = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
        if primary then return primary.Position end
    end
    local part = inst:FindFirstChildWhichIsA("BasePart", true)
    if part then return part.Position end
    return nil
end

local function collectFishEggs()
    local eggs = {}
    local seen = {}
    
    -- Végigmegyünk az egész Workspace-en, és megkeressük a fenti nevű mappákat
    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        for _, folderName in ipairs(VALID_EGG_FOLDERS) do
            if obj.Name == folderName then
                -- Megvan a mappa! Most végigmegyünk a gyerekein
                for _, child in ipairs(obj:GetChildren()) do
                    if (child:IsA("Model") or child:IsA("BasePart")) and not seen[child] then
                        seen[child] = true
                        table.insert(eggs, child)
                    end
                end
            end
        end
    end
    return eggs
end

local function refreshEggs()
    eggList = collectFishEggs()
    local names = {}
    local seenNames = {}
    
    for i, e in ipairs(eggList) do
        local display = e.Name
        local counter = 1
        while seenNames[display] do
            counter = counter + 1
            display = e.Name .. " (" .. counter .. ")"
        end
        seenNames[display] = true
        e.displayName = display
        table.insert(names, display)
    end
    
    if #names == 0 then names = { "(nincs tojás)" } end
    if eggDropdown then eggDropdown:Refresh(names) end
    Rayfield:Notify({Title="Refresh", Content=#eggList.." FishEgg betöltve.", Duration=3})
end

-- ============================================================
--  AUTO STEAL (Prompt aktiválás)
-- ============================================================
local autoStealEnabled = false

EggsTab:CreateToggle({
    Name = "Auto Steal (Prompt aktiválás)",
    CurrentValue = false,
    Flag = "AutoStealToggle",
    Callback = function(value)
        autoStealEnabled = value
        Rayfield:Notify({Title="Auto Steal", Content=value and "BE" or "KI", Duration=2})
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

    -- Ha elég közel van (20 stud), aktiváljuk a promptot
    if closest and minDist < 20 then
        local prompt = closest:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            pcall(function() fireproximityprompt(prompt) end)
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(0.1)
                prompt:InputHoldEnd()
            end)
        end
    end
end)

-- ============================================================
--  TOJÁS LISTA ÉS TELEPORT
-- ============================================================
eggDropdown = EggsTab:CreateDropdown({
    Name = "Válassz FishEgg-et",
    Options = { "(kattints a Refresh-re)" },
    CurrentOption = { "(kattints a Refresh-re)" },
    MultipleOptions = false,
    Flag = "EggDropdown",
    Callback = function(opt)
        local chosen = type(opt) == "table" and opt[1] or opt
        if not chosen or chosen == "(nincs tojás)" then return end
        
        for _, e in ipairs(eggList) do
            if e.displayName == chosen then
                local pos = getPositionFromInstance(e)
                if pos then
                    teleportTo(pos)
                    Rayfield:Notify({Title="Teleport", Content="Odamentél: "..e.Name, Duration=2})
                else
                    Rayfield:Notify({Title="Hiba", Content="Nincs pozíciója a tojásnak!", Duration=3})
                end
                return
            end
        end
    end
})

EggsTab:CreateButton({
    Name = "🔄 Refresh FishEgg lista",
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
            teleportTo(closest)
            Rayfield:Notify({Title="Teleport", Content="Legközelebbi tojásnál vagy!", Duration=2})
        else
            Rayfield:Notify({Title="Hiba", Content="Nincs tojás a listában! Nyomd meg a Refresh-t.", Duration=3})
        end
    end
})

-- ============================================================
--  ELSŐ AUTOMATIKUS BETÖLTÉS
-- ============================================================
task.spawn(function()
    task.wait(1)
    refreshEggs()
end)

Rayfield:Notify({
    Title = "Betöltve!",
    Content = "Végleges FishEggs script aktív. Refresh, majd válassz tojást!",
    Duration = 5
})
