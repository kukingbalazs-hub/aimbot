--[[
    UTOPIA v5 — Biztonságos (minigame hosszúságú delay)
--]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local RS = game:GetService("ReplicatedStorage")
local JobAction = RS:WaitForChild("JobSystem"):WaitForChild("JobAction")
local Notification = RS:WaitForChild("Remotes"):FindFirstChild("Notification")

-- ═══════════════════════════════════════════
-- ACTION-ÖNKÉNTI DELAY (minigame valódi hossza)
-- ═══════════════════════════════════════════

local ACTION_DELAYS = {
    Quench = 3.5,
    Trace = 5.0,
    Hammer = 4.0,
    Smelt = 6.0,
    Craft = 4.0,
    JobTerminal = 2.0,
}

local State = {
    AutoComplete = false,
    Randomize = true,
    RandomSpread = 0.8,   -- ± 0.8s (emberibb)
    Actions = {
        Quench = false,
        Trace = false,
        Hammer = false,
        Smelt = false,
        Craft = false,
        JobTerminal = false,
    },
    Count = 0,
    ExploitDetected = false,
}

-- ═══════════════════════════════════════════
-- EXPLOIT DETEKTÁLÁS (Notification figyelés)
-- ═══════════════════════════════════════════

if Notification then
    for _, conn in ipairs(getconnections(Notification.OnClientEvent)) do
        local old; old = hookfunction(conn.Function, function(...)
            local args = {...}
            for _, arg in ipairs(args) do
                if type(arg) == "string" and (arg:lower():find("exploit") or arg:lower():find("too quickly")) then
                    State.ExploitDetected = true
                    State.AutoComplete = false  -- AZONNAL leáll
                    warn("[Utopia] ⚠️ EXPLOIT DETECTED! Auto-Complete leállítva.")
                end
            end
            return old(...)
        end)
    end
end

-- ═══════════════════════════════════════════
-- AUTO-COMPLETE
-- ═══════════════════════════════════════════

local function getDelay(action)
    local base = ACTION_DELAYS[action] or 3.0
    if State.Randomize then
        return base + (math.random() * State.RandomSpread * 2 - State.RandomSpread)
    end
    return base
end

local function fireAction(action)
    pcall(function()
        JobAction:FireServer(action)
        State.Count = State.Count + 1
        print(`[Utopia] {action} (#{State.Count})`)
    end)
end

-- Sorban halad, NEM egyszerre!
task.spawn(function()
    while task.wait(0.5) do
        if State.AutoComplete and not State.ExploitDetected then
            for action, enabled in pairs(State.Actions) do
                if enabled then
                    local delay = getDelay(action)
                    print(`[Utopia] Vár {delay:.1f}s — {action}`)
                    task.wait(delay)
                    if State.AutoComplete and not State.ExploitDetected then
                        fireAction(action)
                    end
                    task.wait(0.5)  -- kis szünet a következő előtt
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════
-- UI
-- ═══════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "Utopia v5 (Biztonságos)",
    LoadingTitle = "Utopia",
    LoadingSubtitle = "Safe Mode",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false,
})

local Tab1 = Window:CreateTab("Auto", 4483362458)

Tab1:CreateSection("⚠️ BIZTONSÁGI FIGYELMEZTETÉS")
Tab1:CreateLabel("• Csak 1 action egyszerre!")
Tab1:CreateLabel("• A delay a minigame valódi hossza")
Tab1:CreateLabel("• Ha 'Exploit Detected' jön → leáll")

Tab1:CreateSection("Fő kapcsoló")

Tab1:CreateToggle({
    Name = "Auto-Complete BE",
    CurrentValue = false,
    Flag = "AutoComplete",
    Callback = function(value)
        State.AutoComplete = value
    end,
})

Tab1:CreateToggle({
    Name = "Randomizálás (±0.8s)",
    CurrentValue = true,
    Flag = "Randomize",
    Callback = function(value)
        State.Randomize = value
    end,
})

Tab1:CreateSection("Action-ök (csak 1-et kapcsolj!)")

for _, action in ipairs({"Quench", "Trace", "Hammer", "Smelt", "Craft", "JobTerminal"}) do
    Tab1:CreateToggle({
        Name = `{action} ({ACTION_DELAYS[action]}s)`,
        CurrentValue = false,
        Flag = "Act_" .. action,
        Callback = function(value)
            State.Actions[action] = value
        end,
    })
end

local Tab2 = Window:CreateTab("Státusz", 4483362458)

local statusLabel = Tab2:CreateLabel("Hívások: 0")
local exploitLabel = Tab2:CreateLabel("Exploit: NEM")

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            statusLabel:Set(`Hívások: {State.Count}`)
            exploitLabel:Set(`Exploit: {State.ExploitDetected and "IGEN ⚠️" or "NEM"}`)
        end)
    end
end)

Tab2:CreateButton({
    Name = "Exploit flag törlése",
    Callback = function()
        State.ExploitDetected = false
    end,
})

Rayfield:Notify({
    Title = "Utopia v5",
    Content = "Biztonságos mód. Csak 1 action!",
    Duration = 5,
})
