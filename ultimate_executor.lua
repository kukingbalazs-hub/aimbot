-- ============================================================
--  STEAL AN EGG - Rayfield GUI Script
--  Delta Executor kompatibilis
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Steal An Egg - Script",
    LoadingTitle = "Betöltés...",
    LoadingSubtitle = "by Te",
    ConfigurationSaving = { Enabled = false }
})

local MainTab  = Window:CreateTab("Főmenü", 4483362458)
local SpeedTab = Window:CreateTab("Speed", 4483362458)
local EggTab   = Window:CreateTab("Tojások", 4483362458)
local DebugTab = Window:CreateTab("Debug", 4483362458)

-- ============================================================
--  SEGÉDFÜGGVÉNYEK
-- ============================================================
local function getHRP()
    local char = LocalPlayer.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
    return nil
end

local function teleportTo(pos)
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = CFrame.new(pos)
        return true
    end
    return false
end

-- ============================================================
--  SPEED
-- ============================================================
local currentSpeed = 16

SpeedTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 500},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 16,
    Flag = "SpeedSlider",
    Callback = function(value)
        currentSpeed = value
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = value end
        end
    end,
})

SpeedTab:CreateButton({
    Name = "▶ Alkalmazás most",
    Callback = function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = currentSpeed end
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = currentSpeed end
end)

-- ============================================================
--  TOJÁSOK
-- ============================================================
-- A játékban a tojások általában "Egg" vagy "Nest" nevű objektumok.
local function collectEggs()
    local eggs = {}
    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find("egg") or n:find("nest") then
            if obj:IsA("Model") or obj:IsA("BasePart") then
                table.insert(eggs, obj)
            end
        end
    end
    return eggs
end

local eggList = {}
local eggDropdown

local function refreshEggs()
    eggList = collectEggs()
    local names = {}
    for i, e in ipairs(eggList) do
        table.insert(names, e.Name .. " #" .. i)
    end
    if #names == 0 then names = { "(nincs tojás)" } end
    if eggDropdown then eggDropdown:Refresh(names) end
    Rayfield:Notify({Title="Refresh", Content=#eggList.." tojás", Duration=2})
end

eggDropdown = EggTab:CreateDropdown({
    Name = "Válassz tojást",
    Options = { "(kattints a Refresh-re)" },
    CurrentOption = { "(kattints a Refresh-re)" },
    MultipleOptions = false,
    Flag = "EggDropdown",
    Callback = function(opt)
        local chosen = type(opt) == "table" and opt[1] or opt
        for i, e in ipairs(eggList) do
            if (e.Name .. " #" .. i) == chosen then
                local pos
                if e:IsA("BasePart") then pos = e.Position
                else
                    local part = e:FindFirstChildWhichIsA("BasePart", true)
                    if part then pos = part.Position end
                end
                if pos then
                    teleportTo(pos + Vector3.new(0, 5, 0))
                    Rayfield:Notify({Title="Teleport", Content="Odamentél: "..e.Name, Duration=2})
                end
                return
            end
        end
    end
})

EggTab:CreateButton({
    Name = "🔄 Refresh tojáslista",
    Callback = function() refreshEggs() end
})

-- Auto Steal (kísérleti)
local autoStealEnabled = false
EggTab:CreateToggle({
    Name = "Auto Steal (kísérleti)",
    CurrentValue = false,
    Flag = "AutoStealToggle",
    Callback = function(value)
        autoStealEnabled = value
    end
})

-- Auto steal logika: megkeresi a legközelebbi tojást és odamegy
RunService.Heartbeat:Connect(function()
    if not autoStealEnabled then return end
    local hrp = getHRP()
    if not hrp then return end
    local closest, minDist = nil, math.huge
    for _, e in ipairs(eggList) do
        local pos
        if e:IsA("BasePart") then pos = e.Position
        else
            local part = e:FindFirstChildWhichIsA("BasePart", true)
            if part then pos = part.Position end
        end
        if pos then
            local d = (pos - hrp.Position).Magnitude
            if d < minDist then minDist = d; closest = pos end
        end
    end
    if closest and minDist > 10 then
        hrp.CFrame = CFrame.new(closest + Vector3.new(0, 5, 0))
    end
end)

-- ============================================================
--  DEBUG
-- ============================================================
DebugTab:CreateButton({
    Name = "🔍 Workspace objektumok kiírása",
    Callback = function()
        print("=== WORKSPACE DEBUG ===")
        for _, obj in ipairs(game.Workspace:GetChildren()) do
            print(obj.Name, "|", obj.ClassName)
        end
        print("=== VÉGE ===")
        Rayfield:Notify({Title="Debug", Content="Nézd meg az F9 konzolt!", Duration=3})
    end
})

-- ============================================================
--  BETÖLTÉS KÉSZ
-- ============================================================
Rayfield:Notify({
    Title = "Betöltve!",
    Content = "Steal An Egg script aktív.",
    Duration = 4
})
