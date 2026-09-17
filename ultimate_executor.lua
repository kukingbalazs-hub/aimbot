--[[
    ═══════════════════════════════════════════════════════
              UTOPIA SCRIPT v7
         Job System Auto-Complete (FAST)
    ═══════════════════════════════════════════════════════
--]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local JobAction = RS:WaitForChild("JobSystem"):WaitForChild("JobAction")

-- ═══════════════════════════════════════════
-- ÁLLAPOT
-- ═══════════════════════════════════════════

local State = {
    AutoComplete = false,
    TriggerPrompts = true,

    -- GYORS beállítások
    MinDelay = 1,       -- minimum 1 másodperc
    MaxDelay = 2,       -- maximum 2 másodperc
    BetweenActions = 0.5,
    Randomize = true,

    Stations = {},
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
-- STATION FELFEDEZÉS
-- ═══════════════════════════════════════════

local ACTION_KEYWORDS = {
    Quench = "Quench",
    Hammer = "Hammer",
    Anvil = "Hammer",
    Smelt = "Smelt",
    Craft = "Craft",
    JobTerminal = "JobTerminal",
    Trace = "Trace",
    Arc = "Trace",
}

local function detectActionName(obj)
    local current = obj
    while current and current ~= workspace do
        local nameLower = current.Name:lower()
        for keyword, action in pairs(ACTION_KEYWORDS) do
            if nameLower:find(keyword:lower()) then
                return action
            end
        end
        current = current.Parent
    end
    return nil
end

local function discoverStations()
    State.Stations = {}

    local economy = workspace:FindFirstChild("ECONOMY")
    if not economy then
        print("[Utopia] workspace.ECONOMY nem található!")
        return
    end

    for _, d in ipairs(economy:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local action = detectActionName(d)
            if action then
                table.insert(State.Stations, {
                    prompt = d,
                    action = action,
                    part = d.Parent,
                })
                print(`[Utopia] Talált: {action} → {d:GetFullName()}`)
            end
        end
    end

    print(`[Utopia] Összesen {#State.Stations} station.`)
end

discoverStations()

-- ═══════════════════════════════════════════
-- SEGÉDFÜGGVÉNYEK
-- ═══════════════════════════════════════════

local function getRandomDelay()
    if State.Randomize then
        return math.random() * (State.MaxDelay - State.MinDelay) + State.MinDelay
    end
    return State.MinDelay
end

local function triggerPrompt(prompt)
    if not prompt or not prompt.Parent then return false end
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.05)
        prompt:InputHoldEnd()
    end)
    return ok
end

local function fireAction(actionName)
    pcall(function()
        JobAction:FireServer(actionName)
        State.Count = State.Count + 1
        State.LastAction = tick()
        print(`[Utopia] JobAction: {actionName} (összesen: {State.Count})`)
    end)
end

local function runStation(station)
    if not station or not station.prompt then return end

    if State.TriggerPrompts then
        triggerPrompt(station.prompt)
        task.wait(0.1)  -- rövidebb várakozás
    end

    fireAction(station.action)
end

-- ═══════════════════════════════════════════
-- AUTO-COMPLETE CIKLUS (GYORS)
-- ═══════════════════════════════════════════

local enabledActions = {
    Quench = true,
    Hammer = true,
    Smelt = true,
    Craft = true,
    JobTerminal = true,
    Trace = true,
}

task.spawn(function()
    while task.wait(0.2) do
        if State.AutoComplete then
            if tick() - State.LastAction >= State.MinDelay then
                for _, station in ipairs(State.Stations) do
                    if enabledActions[station.action] then
                        task.wait(getRandomDelay())
                        runStation(station)
                        task.wait(State.BetweenActions)
                    end
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════
-- RAYFIELD UI
-- ═══════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "Utopia Script v7",
    LoadingTitle = "Utopia Script",
    LoadingSubtitle = "FAST Job Auto-Complete",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "UtopiaScript",
        FileName = "jobsystem_v7"
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
            Content = value and "BE — gyors mód (1-2s)" or "KI",
            Duration = 2,
        })
    end,
})

Tab1:CreateToggle({
    Name = "Prompt aktiválás (minigame indítás)",
    CurrentValue = true,
    Flag = "TriggerPrompts",
    Callback = function(value)
        State.TriggerPrompts = value
    end,
})

Tab1:CreateSection("Időzítés (gyors)")

Tab1:CreateSlider({
    Name = "Minimum késleltetés",
    Range = {0.1, 10},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 1,
    Flag = "MinDelay",
    Callback = function(value)
        State.MinDelay = value
    end,
})

Tab1:CreateSlider({
    Name = "Maximum késleltetés",
    Range = {0.1, 15},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 2,
    Flag = "MaxDelay",
    Callback = function(value)
        State.MaxDelay = value
    end,
})

Tab1:CreateSlider({
    Name = "Két action között",
    Range = {0, 5},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 0.5,
    Flag = "BetweenActions",
    Callback = function(value)
        State.BetweenActions = value
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

Tab1:CreateSection("Melyik station-öket?")

for _, action in ipairs({"Quench", "Hammer", "Smelt", "Craft", "JobTerminal", "Trace"}) do
    Tab1:CreateToggle({
        Name = action,
        CurrentValue = true,
        Flag = "Act_" .. action,
        Callback = function(value)
            enabledActions[action] = value
        end,
    })
end

-- ─── TAB 2: STATION-ÖK ───

local Tab2 = Window:CreateTab("Station-ök", 4483362458)

local stationLabel = Tab2:CreateLabel("Felfedezve: 0")

task.spawn(function()
    while task.wait(2) do
        pcall(function()
            stationLabel:Set(`Felfedezve: {#State.Stations}`)
        end)
    end
end)

Tab2:CreateButton({
    Name = "Újra felfedezés",
    Callback = function()
        discoverStations()
        Rayfield:Notify({
            Title = "Utopia",
            Content = `Felfedezve: {#State.Stations} station`,
            Duration = 2,
        })
    end,
})

Tab2:CreateButton({
    Name = "Listázás konzolba",
    Callback = function()
        print("[Utopia] Station-ök:")
        for i, s in ipairs(State.Stations) do
            print(`  {i}. {s.action} → {s.prompt:GetFullName()}`)
        end
    end,
})

-- ─── TAB 3: MANUÁLIS ───

local Tab3 = Window:CreateTab("Manuális", 4483362458)

Tab3:CreateSection("Gyors gombok (azonnali)")

for _, action in ipairs({"Quench", "Trace", "Hammer", "Smelt", "Craft", "JobTerminal"}) do
    Tab3:CreateButton({
        Name = action,
        Callback = function()
            fireAction(action)
            Rayfield:Notify({
                Title = "Utopia",
                Content = `Elküldve: "{action}"`,
                Duration = 1,
            })
        end,
    })
end

-- ─── TAB 4: INFO ───

local Tab4 = Window:CreateTab("Info", 4483362458)

local statusLabel = Tab4:CreateLabel("Hívások: 0")

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            statusLabel:Set(`Hívások: {State.Count} | Station-ök: {#State.Stations}`)
        end)
    end
end)

Tab4:CreateSection("Beállítás")

Tab4:CreateLabel("• Alap: 1-2s (gyors)")
Tab4:CreateLabel("• Ha bannt kapsz: emelj 3-5s-re")
Tab4:CreateLabel("• Ha nem működik: kapcsold ki a Prompt-ot")

Rayfield:Notify({
    Title = "Utopia Script v7",
    Content = "Betöltve! Gyors mód (1-2s).",
    Duration = 4,
})

print("[Utopia v7] Betöltve. Gyors mód.")
