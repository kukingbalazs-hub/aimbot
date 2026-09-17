--[[
    ═══════════════════════════════════════════════════════
              UTOPIA SCRIPT v4
           Job System Auto-Complete
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
    CompleteDelay = 0.5,
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

-- ═══════════════════════════════════════════
-- JOBSYSTEM FIGYELŐ (hogy lásd, mit küld a játék)
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
    end)
end

task.spawn(function()
    while task.wait(State.CompleteDelay) do
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
    Name = "Utopia Script v4",
    LoadingTitle = "Utopia Script",
    LoadingSubtitle = "Job System Auto-Complete",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "UtopiaScript",
        FileName = "jobsystem"
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
            Content = value and "Auto-Complete bekapcsolva!" or "Auto-Complete kikapcsolva.",
            Duration = 3,
        })
    end,
})

Tab1:CreateSlider({
    Name = "Delay (másodperc)",
    Range = {0.1, 3},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 0.5,
    Flag = "CompleteDelay",
    Callback = function(value)
        State.CompleteDelay = value
    end,
})

Tab1:CreateSection("Melyik minigame-eket skipelje?")

Tab1:CreateToggle({
    Name = "Quench (Pull Down Quench)",
    CurrentValue = false,
    Flag = "ActQuench",
    Callback = function(value)
        State.Actions.Quench = value
    end,
})

Tab1:CreateToggle({
    Name = "Trace (Trace the Arc)",
    CurrentValue = false,
    Flag = "ActTrace",
    Callback = function(value)
        State.Actions.Trace = value
    end,
})

Tab1:CreateToggle({
    Name = "Hammer (Anvil)",
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
            statusLabel:Set(`Hívások: {State.Count}`)
        end)
    end
end)

Tab3:CreateSection("Használat")

Tab3:CreateLabel("1. Kapcsold be az Auto-Complete-et")
Tab3:CreateLabel("2. Kapcsold be a kívánt action(öke)t")
Tab3:CreateLabel("3. Nézd a konzolt (F9)")

Rayfield:Notify({
    Title = "Utopia Script v4",
    Content = "Betöltve! JobAction hook aktív.",
    Duration = 5,
})

print("[Utopia v4] Betöltve. JobAction hook aktív.")
