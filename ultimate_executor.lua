-- ============================================================
--  KUKING HUB - Steal A Fish Egg (v6 - Teleport Only)
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
local EggsTab = Window:CreateTab("Auto Steal", 4483362458)

-- ============================================================
--  HELPERS
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

local function getEggRarity(egg)
    local attr = egg:GetAttribute("Rarity")
    if attr then return tostring(attr) end
    local rarityVal = egg:FindFirstChild("Rarity") or egg:FindFirstChild("RarityValue")
    if rarityVal then
        if rarityVal:IsA("StringValue") then return rarityVal.Value end
        if rarityVal:IsA("ObjectValue") and rarityVal.Value then return rarityVal.Value.Name end
    end
    local name = egg.Name
    local knownRarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Godly", "Divine"}
    for _, r in ipairs(knownRarities) do
        if name:lower():find(r:lower(), 1, true) then return r end
    end
    return "Unknown"
end

-- ============================================================
--  PLOT FINDER
-- ============================================================
local function getPlotPosition()
    local directNames = {"Plot", "MyPlot", "Base", "House", "Home", "PlotArea", "PlayerPlot"}
    for _, name in ipairs(directNames) do
        local obj = game.Workspace:FindFirstChild(name)
        if obj then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
            if part then return part.Position + Vector3.new(0, 5, 0) end
        end
    end
    local pname = LocalPlayer.Name
    local named = game.Workspace:FindFirstChild(pname .. "Plot")
        or game.Workspace:FindFirstChild(pname .. "'s Plot")
        or game.Workspace:FindFirstChild(pname .. "Base")
    if named then
        local part = named:IsA("BasePart") and named or named:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position + Vector3.new(0, 5, 0) end
    end
    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find("plot") or n:find("base") then
            local owner = obj:FindFirstChild("Owner") or obj:FindFirstChild("Player") or obj:FindFirstChild("OwnerName")
            local isMine = false
            if owner then
                if owner:IsA("ObjectValue") and owner.Value == LocalPlayer then isMine = true
                elseif owner:IsA("StringValue") and owner.Value == LocalPlayer.Name then isMine = true end
            end
            if obj.Name:find(LocalPlayer.Name, 1, true) then isMine = true end
            if isMine then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                if part then return part.Position + Vector3.new(0, 5, 0) end
            end
        end
    end
    local spawn = game.Workspace:FindFirstChild("SpawnLocation")
    if spawn and spawn:IsA("BasePart") then
        return spawn.Position + Vector3.new(0, 5, 0)
    end
    return nil
end

-- ============================================================
--  SPEED
-- ============================================================
local currentSpeed = 16
local originalSpeed = 16

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
        currentSpeed = originalSpeed
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = originalSpeed end
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = currentSpeed end
end)

-- ============================================================
--  EGG COLLECTION
-- ============================================================
local eggList = {}

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
                table.insert(eggs, {
                    instance = child,
                    name = child.Name,
                    rarity = getEggRarity(child),
                    position = getPositionFromInstance(child)
                })
            end
        end
    end
    return eggs
end

-- ============================================================
--  RARITY DROPDOWN
-- ============================================================
local selectedRarity = nil
local rarityDropdown

local function getAvailableRarities()
    eggList = collectEggs()
    local rarities = {}
    local seen = {}
    for _, e in ipairs(eggList) do
        if not seen[e.rarity] then
            seen[e.rarity] = true
            table.insert(rarities, e.rarity)
        end
    end
    table.sort(rarities)
    if #rarities == 0 then rarities = { "(No eggs found)" } end
    return rarities
end

EggsTab:CreateSection("Steal Settings")

rarityDropdown = EggsTab:CreateDropdown({
    Name = "Select Rarity to Steal",
    Options = { "Click Refresh" },
    CurrentOption = { "Click Refresh" },
    MultipleOptions = false,
    Flag = "RarityDropdown",
    Callback = function(opt)
        local chosen = type(opt) == "table" and opt[1] or opt
        if chosen and chosen ~= "(No eggs found)" and chosen ~= "Click Refresh" then
            selectedRarity = chosen
            Rayfield:Notify({Title="Rarity Selected", Content="Target: "..chosen, Duration=2})
        end
    end
})

EggsTab:CreateButton({
    Name = "🔄 Refresh Rarities",
    Callback = function()
        local rarities = getAvailableRarities()
        pcall(function() rarityDropdown:Refresh(rarities) end)
        Rayfield:Notify({Title="Refresh", Content=#eggList.." eggs, "..#rarities.." rarities.", Duration=3})
    end
})

-- Time you have to press E at the egg
local waitAtEgg = 2.5
EggsTab:CreateSlider({
    Name = "Time to Press E (sec)",
    Range = {0.5, 10},
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = 2.5,
    Flag = "WaitAtEggSlider",
    Callback = function(value) waitAtEgg = value end,
})

local sideOffset = 4
EggsTab:CreateSlider({
    Name = "Stand Distance (studs)",
    Range = {2, 10},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 4,
    Flag = "SideOffsetSlider",
    Callback = function(value) sideOffset = value end,
})

-- ============================================================
--  AUTO STEAL (TELEPORT ONLY - NO E PRESS)
-- ============================================================
local autoStealEnabled = false
local stealing = false

EggsTab:CreateSection("Auto Steal")

EggsTab:CreateToggle({
    Name = "Auto Steal ON/OFF (Teleport Only)",
    CurrentValue = false,
    Flag = "AutoStealToggle",
    Callback = function(value)
        autoStealEnabled = value
        if value then
            Rayfield:Notify({
                Title = "Auto Steal",
                Content = "Teleport mode - you press E manually!",
                Duration = 3
            })
        else
            Rayfield:Notify({Title="Auto Steal", Content="DISABLED", Duration=2})
        end
    end
})

-- ============================================================
--  TELEPORT + LOOK AT TARGET
-- ============================================================
local function tpAndLookAt(targetPos)
    local hrp = getHRP()
    if not hrp then return end

    local direction = (hrp.Position - targetPos)
    direction = Vector3.new(direction.X, 0, direction.Z).Unit
    if direction.Magnitude < 0.01 then
        direction = Vector3.new(1, 0, 0)
    end
    local standPos = targetPos + direction * sideOffset + Vector3.new(0, 2, 0)

    hrp.CFrame = CFrame.new(standPos, targetPos)

    local camera = game.Workspace.CurrentCamera
    if camera then
        camera.CFrame = CFrame.new(camera.CFrame.Position, targetPos)
    end
end

-- ============================================================
--  STEAL FLOW (ONLY TELEPORT, NO E PRESS)
-- ============================================================
local function stealRarity(rarity)
    if stealing then return end
    stealing = true

    local hrp = getHRP()
    if not hrp then stealing = false; return end

    eggList = collectEggs()

    local rarityMatches = {}
    for _, e in ipairs(eggList) do
        if e.rarity == rarity and e.position then
            table.insert(rarityMatches, e)
        end
    end

    local candidates = (#rarityMatches > 0) and rarityMatches or eggList

    local target, targetPos = nil, nil
    local bestDist = math.huge
    for _, e in ipairs(candidates) do
        if e.position then
            local d = (e.position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist = d
                target = e.instance
                targetPos = e.position
            end
        end
    end

    if not target or not targetPos then
        Rayfield:Notify({Title="Auto Steal", Content="No egg found.", Duration=3})
        stealing = false
        return
    end

    -- Teleport to the egg
    tpAndLookAt(targetPos)

    -- Notify the user to press E
    Rayfield:Notify({
        Title = "🎯 Press E!",
        Content = target.Name,
        Duration = waitAtEgg
    })

    -- Wait for user to press E
    task.wait(waitAtEgg)

    -- Return to plot
    local plotPos = getPlotPosition()
    if plotPos then
        local hrp2 = getHRP()
        if hrp2 then hrp2.CFrame = CFrame.new(plotPos) end
    end

    -- Short cooldown before next egg
    task.wait(0.4)

    stealing = false
end

-- Main loop
task.spawn(function()
    while task.wait(0.3) do
        if autoStealEnabled and selectedRarity and not stealing then
            stealRarity(selectedRarity)
        end
    end
end)

-- ============================================================
--  AUTO REFRESH
-- ============================================================
task.spawn(function()
    while task.wait(5) do
        if not selectedRarity then
            local rarities = getAvailableRarities()
            pcall(function() rarityDropdown:Refresh(rarities) end)
        end
    end
end)

task.spawn(function()
    task.wait(1.5)
    local rarities = getAvailableRarities()
    pcall(function() rarityDropdown:Refresh(rarities) end)
end)

Rayfield:Notify({
    Title = "Kuking Hub",
    Content = "Loaded! Teleport-only mode. You press E at each egg.",
    Duration = 5
})
