--[[
    ═══════════════════════════════════════════════════════
              UTOPIA SCRIPT v10
       Auto Minigame — egérhúzás szimulálás
    ═══════════════════════════════════════════════════════
--]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer

local JobAction = RS:WaitForChild("JobSystem"):WaitForChild("JobAction")

-- ═══════════════════════════════════════════
-- ÁLLAPOT
-- ═══════════════════════════════════════════

local State = {
    Enabled = false,
    Action = "Trace",
    Interval = 2.5,
    Range = 30,
    Count = 0,
    UseClick = true,     -- E gomb szimulálás
    UseDrag = true,      -- egérhúzás minigame-hez
}

-- ═══════════════════════════════════════════
-- SEGÉD: egér szimulálás
-- ═══════════════════════════════════════════

-- Próbáljuk az executor beépített funkcióit
local hasMouseFuncs = (type(mousemoverel) == "function") and
                      (type(mouse1down) == "function") and
                      (type(mouse1up) == "function")

local function mouseMoveAbs(x, y)
    if hasMouseFuncs then
        local cur = getmousepos and getmousepos() or {X=0, Y=0}
        mousemoverel(x - cur.X, y - cur.Y)
    else
        VIM:SendMouseMoveEvent(x, y, false, game)
    end
end

local function mouseDown()
    if hasMouseFuncs then
        mouse1down()
    else
        local p = getmousepos and getmousepos() or {X=0, Y=0}
        VIM:SendMouseButtonEvent(p.X, p.Y, 0, true, game, 0)
    end
end

local function mouseUp()
    if hasMouseFuncs then
        mouse1up()
    else
        local p = getmousepos and getmousepos() or {X=0, Y=0}
        VIM:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 0)
    end
end

-- ═══════════════════════════════════════════
-- PROMPT KERESÉS
-- ═══════════════════════════════════════════

local function getPromptPos(p)
    local par = p.Parent
    if not par then return nil end
    if par:IsA("BasePart") then return par.Position end
    if par:IsA("Model") and par.PrimaryPart then return par.PrimaryPart.Position end
    if par:IsA("Model") then
        local b = par:FindFirstChildWhichIsA("BasePart")
        if b then return b.Position end
    end
    return nil
end

local function findNearestPrompt()
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return nil end
    local root = ch.HumanoidRootPart.Position
    local best, bd = nil, State.Range
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            local pp = getPromptPos(d)
            if pp then
                local dist = (pp - root).Magnitude
                if dist < bd then best, bd = d, dist end
            end
        end
    end
    return best, bd
end

local function triggerPrompt(prompt)
    if not prompt then return false end
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.05)
        prompt:InputHoldEnd()
    end)
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    return true
end

-- ═══════════════════════════════════════════
-- MINIGAME UI KERESÉS
-- ═══════════════════════════════════════════

local function findMinigameUI()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return nil end

    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            local txt = (d.Text or ""):lower()
            if txt:find("trace") or txt:find("arc") or
               txt:find("quench") or txt:find("pull") or
               txt:find("smelt") or txt:find("hammer") or
               txt:find("craft") or txt:find("wood") or
               txt:find("carpenter") or txt:find("saw") or
               txt:find("sand") or txt:find("plane") then
                -- Menjünk fel a ScreenGui-ig
                local root = d
                while root and not root:IsA("ScreenGui") do
                    root = root.Parent
                end
                return root, d.Text
            end
        end
    end
    return nil
end

-- ═══════════════════════════════════════════
-- SZÍNES PONTOK KERESÉSE (Trace the Arc)
-- ═══════════════════════════════════════════

local function isOrange(c)
    if not c then return false end
    return c.R > 0.7 and c.G > 0.3 and c.G < 0.9 and c.B < 0.4
end

local function collectOrangeDots(gui)
    local dots = {}
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("Frame") or d:IsA("ImageLabel") then
            local c = d.BackgroundColor3
            if d:IsA("ImageLabel") then c = d.ImageColor3 end
            if isOrange(c) then
                table.insert(dots, {
                    obj = d,
                    x = d.AbsolutePosition.X + d.AbsoluteSize.X / 2,
                    y = d.AbsolutePosition.Y + d.AbsoluteSize.Y / 2,
                })
            end
        end
    end
    return dots
end

-- ═══════════════════════════════════════════
-- TRACE THE ARC — egérhúzás az ív mentén
-- ═══════════════════════════════════════════

local function completeTraceArc(gui)
    local dots = collectOrangeDots(gui)
    if #dots < 2 then
        print("[Utopia] Trace: kevés pont (" .. #dots .. ")")
        return false
    end

    -- Rendezés X szerint (balról jobbra)
    table.sort(dots, function(a, b) return a.x < b.x end)

    local first = dots[1]
    local last = dots[#dots]

    -- Megkeressük a legmagasabb pontot (az ív teteje)
    local topY = first.y
    for _, d in ipairs(dots) do
        if d.y < topY then topY = d.y end
    end
    topY = topY - 25  -- kicsit feljebb

    print(`[Utopia] Trace: {#dots} pont, ({first.x:.0f},{first.y:.0f}) → ({last.x:.0f},{last.y:.0f})`)

    -- Egér a start pontra
    mouseMoveAbs(first.x, first.y)
    task.wait(0.1)

    -- Bal gomb lenyomás
    mouseDown()
    task.wait(0.1)

    -- Húzás az ív mentén (kvadratikus Bézier)
    local steps = 50
    for i = 1, steps do
        local t = i / steps
        local mt = 1 - t
        -- Kontrollpont az ív teteje
        local cx = (first.x + last.x) / 2
        local cy = topY
        -- Bézier
        local x = mt * mt * first.x + 2 * mt * t * cx + t * t * last.x
        local y = mt * mt * first.y + 2 * mt * t * cy + t * t * last.y
        mouseMoveAbs(x, y)
        task.wait(0.012)
    end

    task.wait(0.1)
    mouseUp()
    print("[Utopia] Trace: húzás kész")
    return true
end

-- ═══════════════════════════════════════════
-- PULL DOWN QUENCH — lehúzás
-- ═══════════════════════════════════════════

local function completePullDown(gui)
    local dots = collectOrangeDots(gui)
    if #dots < 2 then
        -- Nincs narancs pont, próbáljuk megkeresni a sávot
        print("[Utopia] Quench: nem találtam pontokat")
        return false
    end

    table.sort(dots, function(a, b) return a.y < b.y end)
    local top = dots[1]
    local bottom = dots[#dots]

    print(`[Utopia] Quench: ({top.x:.0f},{top.y:.0f}) → ({bottom.x:.0f},{bottom.y:.0f})`)

    mouseMoveAbs(top.x, top.y)
    task.wait(0.1)
    mouseDown()
    task.wait(0.1)

    local steps = 40
    for i = 1, steps do
        local t = i / steps
        local x = top.x + (bottom.x - top.x) * t
        local y = top.y + (bottom.y - top.y) * t
        mouseMoveAbs(x, y)
        task.wait(0.015)
    end

    task.wait(0.1)
    mouseUp()
    return true
end

-- ═══════════════════════════════════════════
-- ÁLTALÁNOS MINIGAME — próbál mindent
-- ═══════════════════════════════════════════

local function completeMinigame(gui, text)
    local lower = (text or ""):lower()

    if lower:find("trace") or lower:find("arc") then
        return completeTraceArc(gui)
    elseif lower:find("quench") or lower:find("pull") then
        return completePullDown(gui)
    else
        -- Ismeretlen: próbáljuk a Trace-t, aztán a Pull-t
        if completeTraceArc(gui) then return true end
        if completePullDown(gui) then return true end
        return false
    end
end

-- ═══════════════════════════════════════════
-- EGY CIKLUS
-- ═══════════════════════════════════════════

local function doStep()
    -- 1. Prompt aktiválás
    local prompt, dist = findNearestPrompt()
    if prompt then
        print(`[Utopia] Prompt: "{prompt.ActionText}" ({dist:.1f}s) — E`)
        triggerPrompt(prompt)
        task.wait(0.4)  -- várjunk, hátha megjelenik a UI
    else
        print("[Utopia] Nincs prompt a közelben")
    end

    -- 2. Minigame UI keresése
    local gui, text = findMinigameUI()
    if gui and State.UseDrag then
        print(`[Utopia] Minigame UI: "{text}"`)
        completeMinigame(gui, text)
        task.wait(0.3)
    end

    -- 3. JobAction küldés (biztos, ami biztos)
    if prompt then
        task.wait(0.4)
        pcall(function()
            JobAction:FireServer(State.Action)
            State.Count = State.Count + 1
            print(`[Utopia] JobAction: {State.Action} (#{State.Count})`)
        end)
    end
end

task.spawn(function()
    while task.wait(State.Interval) do
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
    LoadingSubtitle = "Auto Minigame",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false,
})

local Tab1 = Window:CreateTab("Auto", 4483362458)

Tab1:CreateSection("Fő kapcsoló")

Tab1:CreateToggle({
    Name = "BE (auto E + drag)",
    CurrentValue = false,
    Flag = "Enabled",
    Callback = function(value)
        State.Enabled = value
    end,
})

Tab1:CreateSlider({
    Name = "Intervallum",
    Range = {1, 10},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 2.5,
    Flag = "Interval",
    Callback = function(value)
        State.Interval = value
    end,
})

Tab1:CreateSlider({
    Name = "Hatótáv",
    Range = {5, 100},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 30,
    Flag = "Range",
    Callback = function(value)
        State.Range = value
    end,
})

Tab1:CreateSection("Action")

for _, action in ipairs({"Quench", "Trace", "Hammer", "Smelt", "Craft", "JobTerminal", "Wood", "Carpenter"}) do
    Tab1:CreateButton({
        Name = action,
        Callback = function()
            State.Action = action
            Rayfield:Notify({Title = "Utopia", Content = `Action: {action}`, Duration = 2})
        end,
    })
end

-- ─── TAB 2: TESZT ───

local Tab2 = Window:CreateTab("Teszt", 4483362458)

Tab2:CreateButton({
    Name = "Prompt keresés",
    Callback = function()
        local p, d = findNearestPrompt()
        if p then
            print(`[Utopia] Talált: "{p.ActionText}" ({d:.1f}s)`)
            Rayfield:Notify({Title = "Utopia", Content = `Talált: {p.ActionText}`, Duration = 3})
        else
            Rayfield:Notify({Title = "Utopia", Content = "Nincs prompt", Duration = 3})
        end
    end,
})

Tab2:CreateButton({
    Name = "Minigame UI keresés",
    Callback = function()
        local gui, text = findMinigameUI()
        if gui then
            print(`[Utopia] UI: {gui.Name}, szöveg: "{text}"`)
            Rayfield:Notify({Title = "Utopia", Content = `UI: {text}`, Duration = 3})
        else
            Rayfield:Notify({Title = "Utopia", Content = "Nincs minigame UI", Duration = 3})
        end
    end,
})

Tab2:CreateButton({
    Name = "Teljes ciklus (most)",
    Callback = function()
        doStep()
    end,
})

Tab2:CreateButton({
    Name = "Egér funkciók ellenőrzése",
    Callback = function()
        local msg = hasMouseFuncs and "Executor mouse funkciók: VAN" or "Executor mouse funkciók: NINCS (VIM fallback)"
        print(`[Utopia] {msg}`)
        Rayfield:Notify({Title = "Utopia", Content = msg, Duration = 4})
    end,
})

-- ─── TAB 3: INFO ───

local Tab3 = Window:CreateTab("Info", 4483362458)
local statusLabel = Tab3:CreateLabel("Hívások: 0")
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            statusLabel:Set(`Hívások: {State.Count} | Action: {State.Action}`)
        end)
    end
end)

Rayfield:Notify({
    Title = "Utopia v10",
    Content = "Betöltve. Auto E + egérhúzás.",
    Duration = 4,
})
