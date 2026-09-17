--[[
    UTOPIA v11 — Rayfield nélkül
    Saját egyszerű UI
--]]

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
-- PROMPT KERESÉS
-- ═══════════════════════════════════════════

local function getPromptPosition(prompt)
    local parent = prompt.Parent
    if not parent then return nil end
    if parent:IsA("BasePart") then return parent.Position end
    if parent:IsA("Model") then
        if parent.PrimaryPart then return parent.PrimaryPart.Position end
        local part = parent:FindFirstChildWhichIsA("BasePart")
        if part then return part.Position end
    end
    return nil
end

local function getNearestPrompt()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local rootPos = char.HumanoidRootPart.Position
    local nearest, nearestDist = nil, State.Range

    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local pos = getPromptPosition(d)
            if pos then
                local dist = (pos - rootPos).Magnitude
                if dist < nearestDist then
                    nearest = d
                    nearestDist = dist
                end
            end
        end
    end
    return nearest, nearestDist
end

-- ═══════════════════════════════════════════
-- EGY LÉPÉS
-- ═══════════════════════════════════════════

local function doStep()
    local prompt, dist = getNearestPrompt()
    if not prompt then
        warn("[Utopia] Nincs prompt a hatótávon belül!")
        return false
    end

    print(`[Utopia] Prompt: "{prompt.Name}" ({dist:.1f} studs) — ActionText: "{prompt.ActionText}"`)

    pcall(function() prompt:InputHoldBegin() end)
    task.wait(State.TriggerHold)
    pcall(function() prompt:InputHoldEnd() end)
    task.wait(State.AfterTrigger)

    pcall(function()
        JobAction:FireServer(State.Action)
        State.Count = State.Count + 1
        print(`[Utopia] JobAction: {State.Action} (#{State.Count})`)
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
-- SAJÁT UI (Rayfield nélkül)
-- ═══════════════════════════════════════════

local gui = Instance.new("ScreenGui")
gui.Name = "UtopiaGUI"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Fő frame
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 300)
main.Position = UDim2.new(0, 20, 0, 100)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = main

-- Cím
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
title.BorderSizePixel = 0
title.Text = "Utopia v11"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = main

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

-- Action dropdown (egyszerű gombok)
local actions = {"Quench", "Trace", "Hammer", "Smelt", "Craft", "JobTerminal"}
local yPos = 45

for _, action in ipairs(actions) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 28)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = (action == State.Action) and Color3.fromRGB(0, 120, 215) or Color3.fromRGB(50, 50, 60)
    btn.Text = action
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Parent = main

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 5)
    bc.Parent = btn

    btn.MouseButton1Click:Connect(function()
        State.Action = action
        -- Frissítés
        for _, child in ipairs(main:GetChildren()) do
            if child:IsA("TextButton") and child ~= btn then
                if child.Name == "ActionBtn" then
                    child.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                end
            end
        end
        btn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        print(`[Utopia] Action: {action}`)
    end)
    btn.Name = "ActionBtn"

    yPos = yPos + 32
end

-- BE/KI gomb
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -20, 0, 35)
toggleBtn.Position = UDim2.new(0, 10, 0, yPos + 5)
toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
toggleBtn.Text = "BE (kikapcsolva)"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.Parent = main

local tbc = Instance.new("UICorner")
tbc.CornerRadius = UDim.new(0, 5)
tbc.Parent = toggleBtn

toggleBtn.MouseButton1Click:Connect(function()
    State.Enabled = not State.Enabled
    if State.Enabled then
        toggleBtn.Text = "BE (bekapcsolva)"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
    else
        toggleBtn.Text = "BE (kikapcsolva)"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    end
end)

-- Egyszeri gomb
local stepBtn = Instance.new("TextButton")
stepBtn.Size = UDim2.new(1, -20, 0, 30)
stepBtn.Position = UDim2.new(0, 10, 0, yPos + 45)
stepBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
stepBtn.Text = "Egyszeri lépés (most)"
stepBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stepBtn.Font = Enum.Font.Gotham
stepBtn.TextSize = 13
stepBtn.Parent = main

local sbc = Instance.new("UICorner")
sbc.CornerRadius = UDim.new(0, 5)
sbc.Parent = stepBtn

stepBtn.MouseButton1Click:Connect(function()
    doStep()
end)

-- Státusz
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 1, -25)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Hívások: 0"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.Parent = main

task.spawn(function()
    while task.wait(1) do
        statusLabel.Text = `Hívások: {State.Count}`
    end
end)

print("[Utopia v11] Betöltve! Bal felső sarokban a UI.")
