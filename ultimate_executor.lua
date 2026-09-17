--[[
    ═══════════════════════════════════════════════════════
              UTOPIA SCRIPT v8
        2 másodpercenként 1 action — NEM SPAM
    ═══════════════════════════════════════════════════════
--]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local RS = game:GetService("ReplicatedStorage")
local JobAction = RS:WaitForChild("JobSystem"):WaitForChild("JobAction")

local State = {
    Enabled = false,
    Action = "Quench",      -- CSAK EGY action
    Interval = 2.0,         -- 2 másodperc
    Randomize = true,       -- kis randomizálás
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

-- Egy action küldése
local function fireAction()
    pcall(function()
        JobAction:FireServer(State.Action)
        State.Count = State.Count + 1
        print(`[Utopia] {State.Action} (#{State.Count}) — vár {State.Interval}s`)
    end)
end

-- 2 másodpercenként EGY action
task.spawn(function()
    while task.wait(State.Interval) do
        if State.Enabled then
            fireAction()
        end
    end
end)

-- ═══════════════════════════════════════════
-- UI
-- ═══════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "Utopia v8",
    LoadingTitle = "Utopia",
    LoadingSubtitle = "1 Action / 2s",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false,
})

local Tab1 = Window:CreateTab("Auto", 4483362458)

Tab1:CreateSection("Fő kapcsoló")

Tab1:CreateToggle({
    Name = "BE (2s / 1 action)",
    CurrentValue = false,
    Flag = "Enabled",
    Callback = function(value)
        State.Enabled = value
        if value then
            Rayfield:Notify({
                Title = "Utopia",
                Content = `BE — {State.Action} 2 másodpercenként`,
                Duration = 3,
            })
        end
    end,
})

Tab1:CreateSlider({
    Name = "Intervallum (másodperc)",
    Range = {1, 10},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 2.0,
    Flag = "Interval",
    Callback = function(value)
        State.Interval = value
    end,
})

Tab1:CreateSection("Melyik action-t csinálja? (csak 1!)")

local actionButtons = {}

for _, action in ipairs({"Quench", "Trace", "Hammer", "Smelt", "Craft", "JobTerminal"}) do
    local btn
    btn = Tab1:CreateButton({
        Name = action,
        Callback = function()
            State.Action = action
            -- Frissítés
            for name, b in pairs(actionButtons) do
                pcall(function()
                    b:Set(`{name}{name == action and " ✓" or ""}`)
                end)
            end
            Rayfield:Notify({
                Title = "Utopia",
                Content = `Action: {action}`,
                Duration = 2,
            })
        end,
    })
    actionButtons[action] = btn
end

-- ─── TAB 2: MANUÁLIS ───

local Tab2 = Window:CreateTab("Manuális", 4483362458)

Tab2:CreateButton({
    Name = "Egyszeri action (most)",
    Callback = function()
        fireAction()
    end,
})

-- ─── TAB 3: INFO ───

local Tab3 = Window:CreateTab("Info", 4483362458)

local statusLabel = Tab3:CreateLabel("Hívások: 0")
local actionLabel = Tab3:CreateLabel("Action: Quench")

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            statusLabel:Set(`Hívások: {State.Count}`)
            actionLabel:Set(`Action: {State.Action}`)
        end)
    end
end)

Tab3:CreateSection("Miért nem spam?")
Tab3:CreateLabel("• Csak 1 action")
Tab3:CreateLabel("• 2 másodperc közöttük")
Tab3:CreateLabel("• Nem ismétli az összeset")

Rayfield:Notify({
    Title = "Utopia v8",
    Content = "Betöltve. Válassz 1 action-t!",
    Duration = 4,
})
