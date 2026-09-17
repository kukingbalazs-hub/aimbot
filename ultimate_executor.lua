--[[
    ═══════════════════════════════════════════════════════
                    UTOPIA SCRIPT
              Jump for Brainrots / Animals
              Rayfield UI Edition
    ═══════════════════════════════════════════════════════
--]]

-- ═══════════════════════════════════════════
-- RAYFIELD BETÖLTÉSE
-- ═══════════════════════════════════════════

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ═══════════════════════════════════════════
-- SZOLGÁLTATÁSOK
-- ═══════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════
-- ÁLLAPOT
-- ═══════════════════════════════════════════

local State = {
    -- ProximityPrompt
    PromptEnabled = false,
    HoldDuration = 0.5,

    -- Auto Collect
    AutoCollectEnabled = false,
    CollectRange = 50,

    -- ESP
    ESPEnabled = false,

    -- Stats
    PromptCount = 0,
}

-- ═══════════════════════════════════════════
-- PROXIMITY PROMPT KEZELŐ
-- ═══════════════════════════════════════════

local function applyPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    if prompt.HoldDuration ~= State.HoldDuration then
        prompt.HoldDuration = State.HoldDuration
        State.PromptCount = State.PromptCount + 1
    end
end

local function applyAllPrompts(root)
    if not root then return end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            applyPrompt(d)
        end
    end
end

-- Új promptok figyelése
workspace.DescendantAdded:Connect(function(d)
    if not State.PromptEnabled then return end
    if d:IsA("ProximityPrompt") then
        task.wait(0.1)
        applyPrompt(d)
    end
end)

-- Folyamatos frissítés
task.spawn(function()
    while task.wait(0.5) do
        if State.PromptEnabled then
            applyAllPrompts(workspace)
        end
    end
end)

-- ═══════════════════════════════════════════
-- AUTO COLLECT
-- ═══════════════════════════════════════════

local function getNearbyPrompts(range)
    local found = {}
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return found end

    local rootPos = char.HumanoidRootPart.Position

    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local parent = d.Parent
            if parent and parent:IsA("BasePart") then
                local dist = (parent.Position - rootPos).Magnitude
                if dist <= range then
                    table.insert(found, {prompt = d, dist = dist, part = parent})
                end
            end
        end
    end
    return found
end

task.spawn(function()
    while task.wait(0.2) do
        if State.AutoCollectEnabled then
            local nearby = getNearbyPrompts(State.CollectRange)
            for _, info in ipairs(nearby) do
                pcall(function()
                    info.prompt:InputHoldBegin()
                    task.wait(0.05)
                    info.prompt:InputHoldEnd()
                end)
            end
        end
    end
end)

-- ═══════════════════════════════════════════
-- ESP
-- ═══════════════════════════════════════════

local espObjects = {}

local function createESP(part, color)
    if not part or not part:IsA("BasePart") then return end
    if espObjects[part] then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Size = part.Size
    box.Adornee = part
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Transparency = 0.5
    box.Color3 = color or Color3.fromRGB(0, 255, 100)
    box.Parent = part

    espObjects[part] = box
end

local function clearESP()
    for part, box in pairs(espObjects) do
        if box and box.Parent then
            box:Destroy()
        end
    end
    espObjects = {}
end

task.spawn(function()
    while task.wait(0.5) do
        if State.ESPEnabled then
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("ProximityPrompt") and d.Parent and d.Parent:IsA("BasePart") then
                    createESP(d.Parent, Color3.fromRGB(0, 255, 100))
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════
-- RAYFIELD UI
-- ═══════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "Utopia Script",
    LoadingTitle = "Utopia Script",
    LoadingSubtitle = "Jump for Brainrots",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "UtopiaScript",
        FileName = "config"
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

-- ─── TAB 1: INTERAKCIÓK ───

local Tab1 = Window:CreateTab("Interakciók", 4483362458)

Tab1:CreateSection("ProximityPrompt")

Tab1:CreateToggle({
    Name = "Prompt módosítás",
    CurrentValue = false,
    Flag = "PromptEnabled",
    Callback = function(value)
        State.PromptEnabled = value
        if value then
            applyAllPrompts(workspace)
        end
    end,
})

Tab1:CreateSlider({
    Name = "HoldDuration (másodperc)",
    Range = {0, 3},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 0.5,
    Flag = "HoldDuration",
    Callback = function(value)
        State.HoldDuration = value
    end,
})

Tab1:CreateButton({
    Name = "Promptok frissítése most",
    Callback = function()
        applyAllPrompts(workspace)
        Rayfield:Notify({
            Title = "Utopia",
            Content = "Promptok frissítve!",
            Duration = 3,
        })
    end,
})

Tab1:CreateSection("Auto Collect")

Tab1:CreateToggle({
    Name = "Auto Collect (brainrotok)",
    CurrentValue = false,
    Flag = "AutoCollectEnabled",
    Callback = function(value)
        State.AutoCollectEnabled = value
    end,
})

Tab1:CreateSlider({
    Name = "Collect Range (studs)",
    Range = {10, 200},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 50,
    Flag = "CollectRange",
    Callback = function(value)
        State.CollectRange = value
    end,
})

-- ─── TAB 2: VIZUÁLIS ───

local Tab2 = Window:CreateTab("Vizuális", 4483362458)

Tab2:CreateSection("ESP")

Tab2:CreateToggle({
    Name = "Brainrot ESP",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(value)
        State.ESPEnabled = value
        if not value then
            clearESP()
        end
    end,
})

Tab2:CreateButton({
    Name = "ESP törlése",
    Callback = function()
        clearESP()
    end,
})

-- ─── TAB 3: INFO ───

local Tab3 = Window:CreateTab("Info", 4483362458)

Tab3:CreateSection("Státusz")

local statusLabel = Tab3:CreateLabel("Promptok módosítva: 0")

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            statusLabel:Set(`Promptok módosítva: {State.PromptCount}`)
        end)
    end
end)

Tab3:CreateSection("Névjegy")

Tab3:CreateLabel("Utopia Script v2.0")
Tab3:CreateLabel("Jump for Brainrots / Animals")
Tab3:CreateLabel("Készült: Rayfield UI-val")

-- ═══════════════════════════════════════════
-- ÉRTESÍTÉS
-- ═══════════════════════════════════════════

Rayfield:Notify({
    Title = "Utopia Script",
    Content = "Sikeresen betöltve!",
    Duration = 5,
})

print("[Utopia Script] Betöltve!")
