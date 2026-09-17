--[[
    UTOPIA v10 — Egy script, mindent lát
--]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local JobAction = RS:WaitForChild("JobSystem"):WaitForChild("JobAction")

local State = {
    Enabled = false,
    Action = "Smelt",
    Range = 20,
    TriggerHold = 0.15,
    AfterTrigger = 0.3,
    Delay = 2,
    Count = 0,
}

-- ═══════════════════════════════════════════
-- Prompt keresés (BasePart ÉS Model alatt is)
-- ═══════════════════════════════════════════

local function getPromptPosition(prompt)
    local parent = prompt.Parent
    if not parent then return nil end

    -- Ha BasePart, akkor a Position
    if parent:IsA("BasePart") then
        return parent.Position
    end

    -- Ha Model, akkor a PrimaryPart vagy az első BasePart
    if parent:IsA("Model") then
        if parent.PrimaryPart then
            return parent.PrimaryPart.Position
        end
        local part = parent:FindFirstChildWhichIsA("BasePart")
        if part then return part.Position end
    end
    return nil
end

local function getNearestPrompt()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end

    local rootPos = char.HumanoidRootPart.Position
    local nearest, nearestDist, nearestPos = nil, State.Range, nil

    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local pos = getPromptPosition(d)
            if pos then
                local dist = (pos - rootPos).Magnitude
                if dist < nearestDist then
                    nearest = d
                    nearestDist = dist
                    nearestPos = pos
                end
            end
        end
    end
    return nearest, nearestDist
end

-- ═══════════════════════════════════════════
-- Egy lépés
-- ═══════════════════════════════════════════

local function doStep()
    local prompt, dist = getNearestPrompt()
    if not prompt then
        warn("[Utopia] Nincs prompt a hatótávon belül!")
        return false
    end

    print(`[Utopia] Legközelebbi prompt: "{prompt.Name}" ({dist:.1f} studs)`)
    print(`[Utopia]   ObjectText: "{prompt.ObjectText}"`)
    print(`[Utopia]   ActionText: "{prompt.ActionText}"`)

    -- 1. Prompt aktiválás
    print("[Utopia] → InputHoldBegin")
    pcall(function()
        prompt:InputHoldBegin()
    end)

    task.wait(State.TriggerHold)

    print("[Utopia] → InputHoldEnd")
    pcall(function()
        prompt:InputHoldEnd()
    end)

    task.wait(State.AfterTrigger)

    -- 2. JobAction
    print(`[Utopia] → JobAction:FireServer("{State.Action}")`)
    pcall(function()
        JobAction:FireServer(State.Action)
        State.Count = State.Count + 1
    end)

    return true
end

task.spawn(function()
    while task.wait(State.Delay) do
        if State.Enabled then
            doStep()
        end
    end
end)

-- ═══════════════════════════════════════════
-- UI
-- ═══════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "Utopia v10",
    LoadingTitle = "Utopia",
    LoadingSubtitle = "Single Script Edition",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false,
})

local Tab = Window:CreateTab("Auto", 4483362458)

Tab:CreateDropdown({
    Name = "Action",
    Options = {"Quench", "Trace", "Hammer", "Smelt", "Craft", "JobTerminal"},
    CurrentOption = {"Smelt"},
    Flag = "ActionSelect",
    Callback = function(option)
        State.Action = option[1] or option
    end,
})

Tab:CreateSlider({
    Name = "Hatótáv (studs)",
    Range = {5, 100},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 20,
    Flag = "Range",
    Callback = function(value)
        State.Range = value
    end,
})

Tab:CreateToggle({
    Name = "BE",
    CurrentValue = false,
    Flag = "Enabled",
    Callback = function(value)
        State.Enabled = value
    end,
})

Tab:CreateButton({
    Name = "Egyszeri lépés (most)",
    Callback = function()
        doStep()
    end,
})

local statusLabel = Tab:CreateLabel("Hívások: 0")
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            statusLabel:Set(`Hívások: {State.Count}`)
        end)
    end
end)

Rayfield:Notify({
    Title = "Utopia v10",
    Content = "CSAK EZT futtasd! Menj a Smelt-hez, nyomd meg az Egyszeri lépést.",
    Duration = 5,
})
