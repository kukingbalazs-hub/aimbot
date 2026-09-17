--[[
    ═══════════════════════════════════════════════════════
              UTOPIA SCRIPT v3
           Minigame Skip + Rayfield UI
    ═══════════════════════════════════════════════════════
--]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════
-- ÁLLAPOT
-- ═══════════════════════════════════════════

local State = {
    -- ProximityPrompt
    PromptEnabled = false,
    HoldDuration = 0.5,

    -- Minigame Skip
    AutoSkipEnabled = false,
    SkipDelay = 0.1,

    -- Logolás
    LogEnabled = true,

    -- Stats
    PromptCount = 0,
    SkipCount = 0,
}

-- ═══════════════════════════════════════════
-- 1. MINIGAME UI KERESÉSE
-- ═══════════════════════════════════════════

-- A minigame-ek nevei (ezeket keressük a PlayerGui-ban)
local MINIGAME_NAMES = {
    "Trace", "Arc", "Quench", "Pull", "Hammer", "Smelt", "Craft",
    "Minigame", "MiniGame", "Forge", "Anvil", "Water", "Job"
}

local function findMinigameUI()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return {} end

    local found = {}
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("ScreenGui") or gui:IsA("Frame") then
            local nameLower = gui.Name:lower()
            for _, keyword in ipairs(MINIGAME_NAMES) do
                if nameLower:find(keyword:lower()) then
                    table.insert(found, gui)
                    break
                end
            end
        end
    end
    return found
end

-- ═══════════════════════════════════════════
-- 2. REMOTE LOGOLÁS (hogy megtaláljuk a completion remote-ot)
-- ═══════════════════════════════════════════

local Remotes = RS:FindFirstChild("Remotes")

if Remotes and State.LogEnabled then
    for _, remote in ipairs(Remotes:GetChildren()) do
        if remote:IsA("RemoteEvent") then
            -- FireServer hook
            local mtHook
            mtHook = hookmetamethod(game, "__namecall", function(...)
                if rawequal((...), remote) and getnamecallmethod() == "FireServer" then
                    print(`[REMOTE] {remote.Name}:FireServer`, ...)
                end
                return mtHook(...)
            end)
        end
    end
end

-- ═══════════════════════════════════════════
-- 3. MINIGAME AUTO-SKIP
-- ═══════════════════════════════════════════

-- Módszer A: A minigame UI befejezése kliensoldalon
-- (ha a szerver nem ellenőrzi, ez elég)

local function attemptSkipUI(gui)
    if not gui then return false end

    local skipped = false

    -- Keressünk egy "Complete" / "Finish" / "Done" gombot vagy értéket
    for _, d in ipairs(gui:GetDescendants()) do
        -- 1. Gomb megnyomása
        if d:IsA("TextButton") or d:IsA("ImageButton") then
            local nameLower = d.Name:lower()
            if nameLower:find("complete") or nameLower:find("finish") or
               nameLower:find("done") or nameLower:find("submit") then
                pcall(function()
                    d:Activate()
                end)
                skipped = true
            end
        end

        -- 2. Érték beállítása a végére (pl. progress bar)
        if d:IsA("NumberValue") or d:IsA("IntValue") then
            local nameLower = d.Name:lower()
            if nameLower:find("progress") or nameLower:find("percent") or
               nameLower:find("complete") then
                pcall(function()
                    d.Value = 100
                end)
                skipped = true
            end
        end

        -- 3. Bool érték beállítása true-ra
        if d:IsA("BoolValue") then
            local nameLower = d.Name:lower()
            if nameLower:find("complete") or nameLower:find("done") or
               nameLower:find("finish") then
                pcall(function()
                    d.Value = true
                end)
                skipped = true
            end
        end
    end

    return skipped
end

-- Módszer B: Az összes RemoteEvent "kényszerített" hívása
-- (ha a szerver vár egy jelet, de nem ellenőrzi a részleteket)

local function attemptSkipRemote()
    if not Remotes then return false end

    local success = false

    for _, remote in ipairs(Remotes:GetChildren()) do
        if remote:IsA("RemoteEvent") then
            local nameLower = remote.Name:lower()

            -- Olyan remote-okat keresünk, amik "complete", "finish", "done",
            -- "submit", "craft", "minigame" szavakat tartalmaznak
            if nameLower:find("complete") or nameLower:find("finish") or
               nameLower:find("done") or nameLower:find("submit") or
               nameLower:find("minigame") or nameLower:find("craft") then
                pcall(function()
                    remote:FireServer()
                    success = true
                end)
            end
        end
    end

    return success
end

-- Auto Skip ciklus
task.spawn(function()
    while task.wait(State.SkipDelay) do
        if State.AutoSkipEnabled then
            local guis = findMinigameUI()
            for _, gui in ipairs(guis) do
                if gui.Visible then
                    if attemptSkipUI(gui) then
                        State.SkipCount = State.SkipCount + 1
                        print(`[Utopia] Minigame skip kísérlet: {gui.Name}`)
                    end
                end
            end

            attemptSkipRemote()
        end
    end
end)

-- ═══════════════════════════════════════════
-- 4. PROXIMITY PROMPT KEZELŐ
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

workspace.DescendantAdded:Connect(function(d)
    if not State.PromptEnabled then return end
    if d:IsA("ProximityPrompt") then
        task.wait(0.1)
        applyPrompt(d)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if State.PromptEnabled then
            applyAllPrompts(workspace)
        end
    end
end)

-- ═══════════════════════════════════════════
-- 5. RAYFIELD UI
-- ═══════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "Utopia Script v3",
    LoadingTitle = "Utopia Script",
    LoadingSubtitle = "Minigame Skip Edition",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "UtopiaScript",
        FileName = "config"
    },
    KeySystem = false,
})

-- ─── TAB 1: MINIGAME SKIP ───

local Tab1 = Window:CreateTab("Minigame Skip", 4483362458)

Tab1:CreateSection("Auto Skip")

Tab1:CreateToggle({
    Name = "Auto Skip (minigame-ek)",
    CurrentValue = false,
    Flag = "AutoSkipEnabled",
    Callback = function(value)
        State.AutoSkipEnabled = value
        if value then
            Rayfield:Notify({
                Title = "Utopia",
                Content = "Auto Skip bekapcsolva. Figyeld a konzolt!",
                Duration = 3,
            })
        end
    end,
})

Tab1:CreateSlider({
    Name = "Skip Delay (másodperc)",
    Range = {0.05, 1},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = 0.1,
    Flag = "SkipDelay",
    Callback = function(value)
        State.SkipDelay = value
    end,
})

Tab1:CreateButton({
    Name = "Egyszeri Skip kísérlet",
    Callback = function()
        local guis = findMinigameUI()
        local count = 0
        for _, gui in ipairs(guis) do
            if attemptSkipUI(gui) then
                count = count + 1
            end
        end
        if attemptSkipRemote() then
            count = count + 1
        end
        Rayfield:Notify({
            Title = "Utopia",
            Content = `Skip kísérlet: {count} művelet`,
            Duration = 3,
        })
    end,
})

Tab1:CreateSection("Diagnosztika")

Tab1:CreateButton({
    Name = "Minigame UI-k listázása",
    Callback = function()
        local guis = findMinigameUI()
        print(`[Utopia] Talált minigame UI-k: {#guis}`)
        for _, gui in ipairs(guis) do
            print(`  - {gui:GetFullName()} (Visible: {gui.Visible})`)
        end
        Rayfield:Notify({
            Title = "Utopia",
            Content = `Talált UI-k: {#guis} (konzolban részletek)`,
            Duration = 3,
        })
    end,
})

Tab1:CreateButton({
    Name = "Remote-ok listázása",
    Callback = function()
        if not Remotes then
            Rayfield:Notify({
                Title = "Utopia",
                Content = "Remotes mappa nem található!",
                Duration = 3,
            })
            return
        end
        print("[Utopia] Remote-ok listája:")
        for _, remote in ipairs(Remotes:GetChildren()) do
            print(`  - {remote.Name} ({remote.ClassName})`)
        end
        Rayfield:Notify({
            Title = "Utopia",
            Content = "Remote-ok listázva a konzolban (F9)",
            Duration = 3,
        })
    end,
})

Tab1:CreateToggle({
    Name = "Remote logolás (konzolba)",
    CurrentValue = true,
    Flag = "LogEnabled",
    Callback = function(value)
        State.LogEnabled = value
    end,
})

-- ─── TAB 2: INTERAKCIÓK ───

local Tab2 = Window:CreateTab("Interakciók", 4483362458)

Tab2:CreateSection("ProximityPrompt")

Tab2:CreateToggle({
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

Tab2:CreateSlider({
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

-- ─── TAB 3: INFO ───

local Tab3 = Window:CreateTab("Info", 4483362458)

Tab3:CreateSection("Státusz")

local statusLabel = Tab3:CreateLabel("Promptok: 0 | Skipek: 0")

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            statusLabel:Set(`Promptok: {State.PromptCount} | Skipek: {State.SkipCount}`)
        end)
    end
end)

Tab3:CreateSection("Használat")

Tab3:CreateLabel("1. Menj a minigame-hez")
Tab3:CreateLabel("2. Kapcsold be az Auto Skip-et")
Tab3:CreateLabel("3. Nézd a konzolt (F9)")

-- ═══════════════════════════════════════════
-- ÉRTESÍTÉS
-- ═══════════════════════════════════════════

Rayfield:Notify({
    Title = "Utopia Script v3",
    Content = "Betöltve! Nézd a konzolt (F9)",
    Duration = 5,
})

print("[Utopia Script v3] Betöltve!")
