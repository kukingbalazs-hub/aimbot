--[[
    ═══════════════════════════════════════════════════════
              UTOPIA SCRIPT v4.2
              Delay: 0.90s
    ═══════════════════════════════════════════════════════
--]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local RS = game:GetService("ReplicatedStorage")
local JobAction = RS:WaitForChild("JobSystem"):WaitForChild("JobAction")

local State = {
    AutoComplete = false,
    CompleteDelay = 0.9,
    Randomize = true,
    RandomSpread = 0.05,
    Actions = {
        Quench = false,
        Trace = false,
        Hammer = false,
        Smelt = false,
        Craft = false,
        JobTerminal = false,
    },
    Count = 0,
}

-- JobAction figyelő
local mtHook
mtHook = hookmetamethod(game, "__namecall", function(...)
    if rawequal((...), JobAction) and getnamecallmethod() == "FireServer" then
        print("[JobAction] FireServer:", ...)
    end
    return mtHook(...)
end)

local function fireAction(actionName)
    pcall(function()
        JobAction:FireServer(actionName)
        State.Count = State.Count + 1
        print(`[Utopia] {actionName} (#{State.Count})`)
    end)
end

local function getNextDelay()
    if State.Randomize then
        return State.CompleteDelay + (math.random() * State.RandomSpread * 2 - State.RandomSpread)
    end
    return State.CompleteDelay
end

task.spawn(function()
    while task.wait(getNextDelay()) do
        if State.AutoComplete then
            for action, enabled in pairs(State.Actions) do
                if enabled then
                    fireAction(action)
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════
-- RAYFIELD UI
-- ═══════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "Utopia v4.2",
    LoadingTitle = "Utopia Script",
    LoadingSubtitle = "Delay 0.90s",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false,
})

local Tab1 = Window:CreateTab("Auto", 4483362458)

Tab1:CreateToggle({
    Name = "Auto-Complete BE",
    CurrentValue = false,
    Flag = "AutoComplete",
    Callback = function(value)
        State.AutoComplete = value
    end,
})

Tab1:CreateSlider({
    Name = "Delay (másodperc)",
    Range = {0.3, 3},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = 0.9,
    Flag = "CompleteDelay",
    Callback = function(value)
        State.CompleteDelay = value
    end,
})

Tab1:CreateToggle({
    Name = "Randomizálás",
    CurrentValue = true,
    Flag = "Randomize",
    Callback = function(value)
        State.Randomize = value
    end,
})

Tab1:CreateSection("Action-ök")

for _, action in ipairs({"Quench", "Trace", "Hammer", "Smelt", "Craft", "JobTerminal"}) do
    Tab1:CreateToggle({
        Name = action,
        CurrentValue = false,
        Flag = "Act_" .. action,
        Callback = function(value)
            State.Actions[action] = value
        end,
    })
end

local Tab2 = Window:CreateTab("Manuális", 4483362458)

for _, action in ipairs({"Quench", "Trace", "Hammer", "Smelt", "Craft", "JobTerminal"}) do
    Tab2:CreateButton({
        Name = action,
        Callback = function()
            fireAction(action)
        end,
    })
end

local Tab3 = Window:CreateTab("Info", 4483362458)
local statusLabel = Tab3:CreateLabel("Hívások: 0")
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            statusLabel:Set(`Hívások: {State.Count}`)
        end)
    end
end)

Rayfield:Notify({
    Title = "Utopia v4.2",
    Content = "Betöltve. Delay: 0.90s",
    Duration = 4,
})
