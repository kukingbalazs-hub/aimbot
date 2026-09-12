-- ============================================================
--  KUKING HUB - Steal A Fish Egg (Rarity Auto Steal)
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
        if name:lower():find(r:lower(), 1, true) then
            return r
        end
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

local stealRange = 15
EggsTab:CreateSlider({
    Name = "Pickup Distance",
    Range = {5, 30},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 15,
    Flag = "StealRangeSlider",
    Callback = function(value) stealRange = value end,
})

local holdTime = 0.4
EggsTab:CreateSlider({
    Name = "Pickup Delay (sec)",
    Range = {0.1, 2},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 0.4,
    Flag = "HoldTimeSlider",
    Callback = function(value) holdTime = value end,
})

local returnDelay = 0.8
EggsTab:CreateSlider({
    Name = "Return to Plot Delay (sec)",
    Range = {0.1, 3},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 0.8,
    Flag = "ReturnDelaySlider",
    Callback = function(value) returnDelay = value end,
})

local sideOffset = 5
EggsTab:CreateSlider({
    Name = "Side Offset (studs)",
    Range = {2, 15},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 5,
    Flag = "SideOffsetSlider",
    Callback = function(value) sideOffset = value end,
})

-- ============================================================
--  AUTO STEAL LOOP
-- ============================================================
local autoStealEnabled = false
local stealing = false

EggsTab:CreateToggle({
    Name = "Auto Steal ON/OFF",
    CurrentValue = false,
    Flag = "AutoStealToggle",
    Callback = function(value)
        autoStealEnabled = value
        Rayfield:Notify({Title="Auto Steal", Content=value and "ENABLED" or "DISABLED", Duration=2})
    end
})

local function tpTo(pos)
    local hrp = getHRP()
    if hrp then hrp.CFrame = CFrame.new(pos) end
end

-- ============================================================
--  TRY PICKUP (6 METHODS)
-- ============================================================
local function tryPickup(eggInstance)
    local prompt = eggInstance:FindFirstChildWhichIsA("ProximityPrompt", true)

    if prompt then
        pcall(function() fireproximityprompt(prompt) end)

        pcall(function()
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration > 0 and prompt.HoldDuration + 0.1 or 0.3)
            prompt:InputHoldEnd()
        end)

        pcall(function()
            prompt:InputPressed()
            task.wait(0.15)
            prompt:InputReleased()
        end)

        pcall(function() fireproximityprompt(prompt) end)
    end

    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)

    pcall(function()
        local VU = game:GetService("VirtualUser")
        VU:Button1Down(Vector2.new(0, 0))
        task.wait(0.05)
        VU:Button1Up(Vector2.new(0, 0))
    end)
end

-- ============================================================
--  STEAL RARITY FLOW (line-of-sight fix)
-- ============================================================
local function stealRarity(rarity)
    if stealing then return end
    stealing = true

    local target, targetPos = nil, nil
    local hrp = getHRP()
    if not hrp then stealing = false; return end

    eggList = collectEggs()
    local bestDist = math.huge
    for _, e in ipairs(eggList) do
        if e.rarity == rarity and e.position then
            local d = (e.position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist = d
                target = e.instance
                targetPos = e.position
            end
        end
    end

    if not target or not targetPos then
        Rayfield:Notify({Title="Auto Steal", Content="No egg found with rarity: "..rarity, Duration=3})
        stealing = false
        return
    end

    -- DIAGNOSTIC
    local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        print("=== PROMPT DEBUG ===")
        print("Name:", prompt.Name)
        print("HoldDuration:", prompt.HoldDuration)
        print("MaxActivationDistance:", prompt.MaxActivationDistance)
        print("RequiresLineOfSight:", prompt.RequiresLineOfSight)
        print("Enabled:", prompt.Enabled)
        print("ActionText:", prompt.ActionText)
        print("ObjectText:", prompt.ObjectText)
        print("====================")
    else
        print("[Auto Steal] No ProximityPrompt found on target: "..target.Name)
    end

    -- Teleport BESIDE the egg (not on top of it) so line-of-sight works
    local offset = Vector3.new(sideOffset, 0, 0)
    local sidePos = targetPos + offset

    tpTo(sidePos)
    task.wait(0.15)

    -- Look at the egg
    if hrp then
        hrp.CFrame = CFrame.new(sidePos, targetPos)
    end

    task.wait(holdTime)

    tryPickup(target)

    task.wait(returnDelay)

    -- Return to plot
    local plotPos = getPlotPosition()
    if plotPos then
        tpTo(plotPos)
    end

    stealing = false
end

-- Main loop
task.spawn(function()
    while task.wait(0.5) do
        if autoStealEnabled and selectedRarity and not stealing then
            stealRarity(selectedRarity)
        end
    end
end)

-- ============================================================
--  AUTO REFRESH DROPDOWN
-- ============================================================
task.spawn(function()
    while task.wait(5) do
        if not selectedRarity then
            local rarities = getAvailableRarities()
            pcall(function() rarityDropdown:Refresh(rarities) end)
        end
    end
end)

-- ============================================================
--  FIRST LOAD
-- ============================================================
task.spawn(function()
    task.wait(1.5)
    local rarities = getAvailableRarities()
    pcall(function() rarityDropdown:Refresh(rarities) end)
end)

Rayfield:Notify({
    Title = "Kuking Hub",
    Content = "Loaded! Select a rarity, then enable Auto Steal.",
    Duration = 5
})
