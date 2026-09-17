--[[
    ═══════════════════════════════════════════════════════
              UTOPIA SCRIPT v6
        Remote Job Complete (no walking)
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
    TriggerPrompts = true,  -- aktiválja-e a promptokat is
    MinDelay = 3,
    MaxDelay = 8,
    Randomize = true,

    -- Action → ProximityPrompt mappa
    -- (auto-felfedezés a workspace.ECONOMY alatt)
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

-- Megkeresi az összes job station ProximityPrompt-ját
-- és megpróbálja kitalálni az action nevét a szülő mappából

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
    -- Végigmegyünk az objektum összes ősén, és megnézzük a nevüket
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

-- ProximityPrompt aktiválása távolról
local function triggerPrompt(prompt)
    if not prompt or not prompt.Parent then return false end
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.05)
        prompt:InputHoldEnd()
    end)
    return ok
end

-- JobAction küldése
local function fireAction(actionName)
    pcall(function()
        JobAction:FireServer(actionName)
        State.Count = State.Count + 1
        State.LastAction = tick()
        print(`[Utopia] JobAction: {actionName} (összesen: {State.Count})`)
    end)
end

-- Egy station teljes végrehajtása (trigger + complete)
local function runStation(station)
    if not station or not station.prompt then return end

    -- 1. Prompt aktiválása (minigame indítás)
    if State.TriggerPrompts then
        triggerPrompt(station.prompt)
        task.wait(0.3)  -- várjunk, hátha megnyílik a UI
    end

    -- 2. JobAction küldése (minigame befejezés)
    fireAction(station.action)
end

-- ═══════════════════════════════════════════
-- AUTO-COMPLETE CIKLUS
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
    while task.wait(0.5) do
        if State.AutoComplete then
            if tick() - State.LastAction >= State.MinDelay then
                for _, station in ipairs(State.Stations) do
                    if enabledActions[station.action] then
                        task.wait(getRandomDelay())
                        runStation(station)
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
    Name = "Utopia Script v6",
    LoadingTitle = "Utopia Script",
    LoadingSubtitle = "Remote Job Complete",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "UtopiaScript",
        FileName = "jobsystem_v6"
    },
    KeySystem = false,
})

-- ─── TAB 1: AUTO-COMPLETE ───

local Tab1 = Window:CreateTab("Auto-Complete", 4483362458)

Tab1:CreateSection("Fő kapcsoló")

Tab1:CreateToggle({
    Name = "Auto-Complete BE (távolról)",
    CurrentValue = false,
    Flag = "AutoComplete",
    Callback = function(value)
        State.AutoComplete = value
        Rayfield:Notify({
            Title = "Utopia",
            Content = value and "Auto-Complete BE — nem kell odamenni!" or "Auto-Complete KI",
            Duration = 3,
        })
    end,
})

Tab1:CreateToggle({
    Name = "Prompt aktiválás is (minigame indítás)",
    CurrentValue = true,
    Flag = "TriggerPrompts",
    Callback = function(value)
        State.TriggerPrompts = value
    end,
})

Tab1:CreateSection("Időzítés")

Tab1:CreateSlider({
    Name = "Minimum késleltetés",
    Range = {1, 30},
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = 3,
    Flag = "MinDelay",
    Callback = function(value)
        State.MinDelay = value
    end,
})

Tab1:CreateSlider({
    Name = "Maximum késleltetés",
    Range = {1, 60},
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = 8,
    Flag = "MaxDelay",
    Callback = function(value)
        State.MaxDelay = value
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

Tab2:CreateSection("Felfedezett station-ök")

local stationLabel = Tab2:CreateLabel("Felfedezve: 0")

local function updateStationLabel()
    pcall(function()
        stationLabel:Set(`Felfedezve: {#State.Stations}`)
    end)
end

task.spawn(function()
    while task.wait(2) do
        updateStationLabel()
    end
end)

Tab2:CreateButton({
    Name = "Újra felfedezés",
    Callback = function()
        discoverStations()
        updateStationLabel()
        Rayfield:Notify({
            Title = "Utopia",
            Content = `Felfedezve: {#State.Stations} station`,
            Duration = 3,
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

Tab3:CreateSection("Gyors gombok")

for _, action in ipairs({"Quench", "Trace", "Hammer", "Smelt", "Craft", "JobTerminal"}) do
    Tab3:CreateButton({
        Name = `{action} (azonnali)`,
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

Tab3:CreateSection("Prompt teszt")

Tab3:CreateButton({
    Name = "Összes prompt aktiválása",
    Callback = function()
        for _, s in ipairs(State.Stations) do
            triggerPrompt(s.prompt)
            task.wait(0.2)
        end
        Rayfield:Notify({
            Title = "Utopia",
            Content = "Promptok aktiválva!",
            Duration = 2,
        })
    end,
})

-- ─── TAB 4: INFO ───

local Tab4 = Window:CreateTab("Info", 4483362458)

Tab4:CreateSection("Státusz")

local statusLabel = Tab4:CreateLabel("Hívások: 0")

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            statusLabel:Set(`Hívások: {State.Count} | Station-ök: {#State.Stations}`)
        end)
    end
end)

Tab4:CreateSection("Hogyan működik?")

Tab4:CreateLabel("1. Auto-Complete BE")
Tab4:CreateLabel("2. Nem kell odamenni!")
Tab4:CreateLabel("3. A script aktiválja a promptot + JobAction-t")

Rayfield:Notify({
    Title = "Utopia Script v6",
    Content = "Betöltve! Nézd a konzolt (F9).",
    Duration = 5,
})

print("[Utopia v6] Betöltve.")
