--[[
    ═══════════════════════════════════════════════════════
              UTOPIA SCRIPT v4.1
           Job System Auto-Complete
           Delay: 0.70s | Távolról működik
    ═══════════════════════════════════════════════════════
--]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local RS = game:GetService("ReplicatedStorage")
local JobAction = RS:WaitForChild("JobSystem"):WaitForChild("JobAction")

-- ═══════════════════════════════════════════
-- ÁLLAPOT
-- ═══════════════════════════════════════════

local State = {
    AutoComplete = false,
    CompleteDelay = 0.7,        -- alap: 0.70 másodperc
    Randomize = true,           -- 0.65 - 0.75 között random
    RandomSpread = 0.05,        -- +- 0.05

    Actions = {
        Quench = false,
        Trace = false,
        Hammer = false,
        Smelt = false,
        Craft = false,
        JobTerminal = false,
    },
    Count = 0,
    LastAction = 0,
}

-- ═══════════════════════════════════════════
-- JOBSYSTEM FIGYELŐ
-- ═══════════════════════════════════════════

local mtHook
mtHook = hookmetamethod(game, "__namecall", function(...)
    if rawequal((...), JobAction) and getnamecallmethod() == "FireServer" then
        print("[JobAction] FireServer:", ...)
    end
    return mtHook(...)
end)

-- ═══════════════════════════════════════════
-- AUTO-COMPLETE LOGIKA
-- ═══════════════════════════════════════════

local function fireAction(actionName)
    pcall(function()
        JobAction:FireServer(actionName)
        State.Count = State.Count + 1
        State.LastAction = tick()
        print(`[Utopia] {actionName} (#{State.Count})`)
    end)
end

-- Kiszámolja a következő delay-t (randommal vagy fixen)
local function getNextDelay()
    if State.Randomize then
        local spread = State.RandomSpread
        return State.CompleteDelay + (math.random() * spread * 2 - spread)
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
    Name = "Utopia Script v4.1",
    LoadingTitle = "Utopia Script",
    LoadingSubtitle = "Job Auto-Complete 0.7s",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "UtopiaScript",
        FileName = "jobsystem_v41"
    },
    KeySystem = false,
})

-- ─── TAB 1: AUTO-COMPLETE ───

local Tab1 = Window:CreateTab("Auto-Complete", 4483362458)

Tab1:CreateSection("Fő kapcsoló")

Tab1:CreateToggle({
    Name = "Auto-Complete BE",
    CurrentValue = false,
    Flag = "AutoComplete",
    Callback = function(value)
        State.AutoComplete = value
        Rayfield:Notify({
            Title = "Utopia",
            Content = value and "BE — távolról működik!" or "KI",
            Duration = 3,
        })
    end,
})

Tab1:CreateSlider({
    Name = "Delay (másodperc)",
    Range = {0.3, 3},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = 0.7,
    Flag = "CompleteDelay",
    Callback = function(value)
        State.CompleteDelay = value
    end,
})

Tab1:CreateToggle({
    Name = "Randomizálás (0.65 - 0.75)",
    CurrentValue = true,
    Flag = "Randomize",
    Callback = function(value)
        State.Randomize = value
    end,
})

Tab1:CreateSlider({
    Name = "Random szórás (±)",
    Range = {0, 0.2},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0.05,
    Flag = "RandomSpread",
    Callback = function(value)
        State.RandomSpread = value
    end,
})

Tab1:CreateSection("Melyik minigame-eket?")

Tab1:CreateToggle({
    Name = "Quench",
    CurrentValue = false,
    Flag = "ActQuench",
    Callback = function(value)
        State.Actions.Quench = value
    end,
})

Tab1:CreateToggle({
    Name = "Trace",
    CurrentValue = false,
    Flag = "ActTrace",
    Callback = function(value)
        State.Actions.Trace = value
    end,
})

Tab1:CreateToggle({
    Name = "Hammer",
    CurrentValue = false,
    Flag = "ActHammer",
    Callback = function(value)
        State.Actions.Hammer = value
    end,
})

Tab1:CreateToggle({
    Name = "Smelt",
    CurrentValue = false,
    Flag = "ActSmelt",
    Callback = function(value)
        State.Actions.Smelt = value
    end,
})

Tab1:CreateToggle({
    Name = "Craft",
    CurrentValue = false,
    Flag = "ActCraft",
    Callback = function(value)
        State.Actions.Craft = value
    end,
})

-- ─── TAB 2: MANUÁLIS ───

local Tab2 = Window:CreateTab("Manuális", 4483362458)

Tab2:CreateSection("Egyedi hívás")

local inputAction = "Quench"

Tab2:CreateInput({
    Name = "Action név",
    CurrentValue = "Quench",
    PlaceholderText = "pl. Quench, Trace, Hammer",
    Flag = "InputAction",
    Callback = function(value)
        inputAction = value
    end,
})

Tab2:CreateButton({
    Name = "Küldés",
    Callback = function()
        fireAction(inputAction)
        Rayfield:Notify({
            Title = "Utopia",
            Content = `Elküldve: "{inputAction}"`,
            Duration = 3,
        })
    end,
})

Tab2:CreateSection("Gyors gombok")

for _, action in ipairs({"Quench", "Trace", "Hammer", "Smelt", "Craft", "JobTerminal"}) do
    Tab2:CreateButton({
        Name = action,
        Callback = function()
            fireAction(action)
            Rayfield:Notify({
                Title = "Utopia",
                Content = `Elküldve: "{action}"`,
                Duration = 2,
            })
        end,
    })
end

-- ─── TAB 3: INFO ───

local Tab3 = Window:CreateTab("Info", 4483362458)

Tab3:CreateSection("Státusz")

local statusLabel = Tab3:CreateLabel("Hívások: 0")

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local since = State.LastAction > 0 and string.format("%.1f", tick() - State.LastAction) or "-"
            statusLabel:Set(`Hívások: {State.Count} | Utolsó: {since}s`)
        end)
    end
end)

Tab3:CreateSection("Használat")

Tab3:CreateLabel("1. Auto-Complete BE")
Tab3:CreateLabel("2. Action(ök) be")
Tab3:CreateLabel("3. NEM kell odamenni!")
Tab3:CreateLabel("4. Nézd a konzolt (F9)")

Rayfield:Notify({
    Title = "Utopia Script v4.1",
    Content = "Betöltve! 0.70s delay, távolról működik.",
    Duration = 5,
})

print("[Utopia v4.1] Betöltve. Delay: 0.7s. Távolról működik.")
