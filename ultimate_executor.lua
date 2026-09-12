-- Rayfield GUI betöltése
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Ablak
local Window = Rayfield:CreateWindow({
    Name = "Plot & Egg Teleport + Speed",
    LoadingTitle = "Betöltés...",
    LoadingSubtitle = "by Te",
    ConfigurationSaving = { Enabled = false }
})

-- Tabok
local MainTab = Window:CreateTab("Főmenü", 4483362458)
local SpeedTab = Window:CreateTab("Speed", 4483362458)
local EggsTab  = Window:CreateTab("LiveAreaEggs", 4483362458)

------------------------------------------------------------
-- 1) TELEK TELEPORT
------------------------------------------------------------
local function getPlotPosition()
    local plot = game.Workspace:FindFirstChild("Plot")
    if plot and plot:IsA("BasePart") then
        return plot.Position + Vector3.new(0, 5, 0)
    end
    local namedPlot = game.Workspace:FindFirstChild(LocalPlayer.Name .. "Plot")
    if namedPlot and namedPlot:IsA("BasePart") then
        return namedPlot.Position + Vector3.new(0, 5, 0)
    end
    local spawn = game.Workspace:FindFirstChild("SpawnLocation")
    if spawn and spawn:IsA("BasePart") then
        return spawn.Position + Vector3.new(0, 5, 0)
    end
    return nil
end

local function teleportTo(pos)
    local char = LocalPlayer.Character
    if not char then return false, "Nincs karaktered!" end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, "Nincs HumanoidRootPart!" end
    hrp.CFrame = CFrame.new(pos)
    return true
end

MainTab:CreateButton({
    Name = "Teleport a telekre",
    Callback = function()
        local pos = getPlotPosition()
        if not pos then
            Rayfield:Notify({Title="Hiba", Content="Nem találom a telket!", Duration=3})
            return
        end
        local ok, err = teleportTo(pos)
        Rayfield:Notify({
            Title = ok and "Siker" or "Hiba",
            Content = ok and "Teleportálva a telekre!" or err,
            Duration = 3
        })
    end
})

------------------------------------------------------------
-- 2) SPEED HACK
------------------------------------------------------------
local currentSpeed = 16
local defaultSpeed = 16

SpeedTab:CreateSlider({
    Name = "Speed érték",
    Range = {1, 500},
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
    Name = "Speed alkalmazása most",
    Callback = function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = currentSpeed
                Rayfield:Notify({Title="Speed", Content="Beállítva: "..currentSpeed, Duration=2})
            end
        end
    end
})

SpeedTab:CreateButton({
    Name = "Reset (16)",
    Callback = function()
        currentSpeed = defaultSpeed
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = defaultSpeed end
        end
        Rayfield:Notify({Title="Speed", Content="Visszaállítva 16-ra", Duration=2})
    end
})

-- Karakter újraéledéskor is tartsa a speedet
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = currentSpeed end
end)

------------------------------------------------------------
-- 3) LIVEAREAEGGS TELEPORT
------------------------------------------------------------
-- Beállítható: hol keresse a tojásokat
local EGG_FOLDER_NAMES = { "LiveAreaEggs", "Eggs", "LiveEggs" }

-- Tojás pozíciójának lekérése (BasePart, Model, vagy Attachment is lehet)
local function getPositionFromInstance(inst)
    if inst:IsA("BasePart") then
        return inst.Position
    elseif inst:IsA("Model") then
        local primary = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
        if primary then return primary.Position end
    elseif inst:IsA("Attachment") then
        return inst.WorldPosition
    end
    -- Ha van benne BasePart, azt használjuk
    local part = inst:FindFirstChildWhichIsA("BasePart", true)
    if part then return part.Position end
    return nil
end

-- Összegyűjti az összes tojást a megadott mappákból
local function collectEggs()
    local eggs = {}
    local seen = {}
    for _, folderName in ipairs(EGG_FOLDER_NAMES) do
        local folder = game.Workspace:FindFirstChild(folderName)
        if folder then
            for _, obj in ipairs(folder:GetDescendants()) do
                -- Csak olyan objektumok, amiknek van pozíciója és nem duplikált
                if not seen[obj] then
                    local pos = getPositionFromInstance(obj)
                    if pos then
                        -- Csak akkor vesszük fel, ha van neve és nem egy konténer
                        if obj.Name ~= "" and (obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Attachment")) then
                            seen[obj] = true
                            table.insert(eggs, { name = obj.Name, pos = pos, obj = obj })
                        end
                    end
                end
            end
        end
    end
    return eggs
end

-- UI elemek
local eggDropdown -- később töltjük fel
local eggList = {}

local refreshButton
local function refreshEggList()
    eggList = collectEggs()
    local names = {}
    for _, e in ipairs(eggList) do
        table.insert(names, e.name)
    end
    if #names == 0 then
        names = { "(nincs tojás)" }
    end
    if eggDropdown then
        eggDropdown:Refresh(names)
    end
    Rayfield:Notify({
        Title = "Refresh",
        Content = #eggList .. " tojás betöltve.",
        Duration = 3
    })
end

-- Dropdown létrehozása
eggDropdown = EggsTab:CreateDropdown({
    Name = "Válassz tojást",
    Options = { "(kattints a Refresh-re)" },
    CurrentOption = { "(kattints a Refresh-re)" },
    MultipleOptions = false,
    Flag = "EggDropdown",
    Callback = function(option)
        -- kiválasztott tojás neve
        local chosen = option
        if type(option) == "table" then chosen = option[1] end
        if not chosen or chosen == "(nincs tojás)" or chosen == "(kattints a Refresh-re)" then return end

        for _, e in ipairs(eggList) do
            if e.name == chosen then
                local ok, err = teleportTo(e.pos + Vector3.new(0, 3, 0))
                Rayfield:Notify({
                    Title = ok and "Teleport" or "Hiba",
                    Content = ok and ("Odamentél: "..chosen) or err,
                    Duration = 3
                })
                return
            end
        end
    end
})

-- Refresh gomb
EggsTab:CreateButton({
    Name = "🔄 Refresh tojáslista",
    Callback = function()
        refreshEggList()
    end
})

-- Automatikus első betöltés
task.spawn(function()
    task.wait(1)
    refreshEggList()
end)
