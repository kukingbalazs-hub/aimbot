-- ============================================================
--  PLOT & EGG TELEPORT + SPEED  (by Te)
--  Rayfield GUI - Delta Executor kompatibilis
-- ============================================================

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
local MainTab  = Window:CreateTab("Főmenü", 4483362458)
local SpeedTab = Window:CreateTab("Speed", 4483362458)
local EggsTab  = Window:CreateTab("LiveAreaEggs", 4483362458)

-- ============================================================
--  TELEPORT SEGÉDFÜGGVÉNY
-- ============================================================
local function teleportTo(pos)
    local char = LocalPlayer.Character
    if not char then return false, "Nincs karaktered!" end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, "Nincs HumanoidRootPart!" end
    hrp.CFrame = CFrame.new(pos)
    return true
end

-- ============================================================
--  1) TELEK POZÍCIÓ (FEJLETT KERESÉS)
-- ============================================================
local function getPlotPosition()
    -- 1) Közvetlen nevek
    local directNames = {"Plot", "MyPlot", "Base", "House", "Home", "PlotArea", "Plot1", "Plot2"}
    for _, name in ipairs(directNames) do
        local obj = game.Workspace:FindFirstChild(name)
        if obj then
            if obj:IsA("BasePart") then
                return obj.Position + Vector3.new(0, 5, 0)
            end
            local part = obj:FindFirstChildWhichIsA("BasePart", true)
            if part then return part.Position + Vector3.new(0, 5, 0) end
        end
    end

    -- 2) Játékos nevéhez kötött plot
    local pname = LocalPlayer.Name
    local possibleNames = {
        pname .. "Plot",
        pname .. "'s Plot",
        pname .. "_Plot",
        pname .. "Base",
        pname .. "'s Base",
        "Plot_" .. pname,
        "Plot" .. pname,
    }
    for _, name in ipairs(possibleNames) do
        local obj = game.Workspace:FindFirstChild(name)
        if obj then
            if obj:IsA("BasePart") then
                return obj.Position + Vector3.new(0, 5, 0)
            end
            local part = obj:FindFirstChildWhichIsA("BasePart", true)
            if part then return part.Position + Vector3.new(0, 5, 0) end
        end
    end

    -- 3) Bejárás: plot/base/house/home nevű objektumok, ami a játékoshoz tartozik
    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        local lname = obj.Name:lower()
        if lname:find("plot") or lname:find("base") or lname:find("house") or lname:find("home") then
            local owner = obj:FindFirstChild("Owner")
                or obj:FindFirstChild("Player")
                or obj:FindFirstChild("OwnerName")
            local isMine = false
            if owner then
                if owner:IsA("ObjectValue") and owner.Value == LocalPlayer then
                    isMine = true
                elseif owner:IsA("StringValue") and owner.Value == LocalPlayer.Name then
                    isMine = true
                end
            end
            if obj.Name:find(LocalPlayer.Name, 1, true) then
                isMine = true
            end
            if isMine then
                if obj:IsA("BasePart") then
                    return obj.Position + Vector3.new(0, 5, 0)
                end
                local part = obj:FindFirstChildWhichIsA("BasePart", true)
                if part then return part.Position + Vector3.new(0, 5, 0) end
            end
        end
    end

    -- 4) SpawnLocation
    local spawn = game.Workspace:FindFirstChild("SpawnLocation")
    if spawn and spawn:IsA("BasePart") then
        return spawn.Position + Vector3.new(0, 5, 0)
    end

    -- 5) Fallback: jelenlegi pozíció
    if LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp.Position end
    end

    return nil
end

-- Debug: kiírja a konzolba a plot-szerű objektumokat
local function debugPlots()
    print("=== PLOT DEBUG ===")
    print("Játékos neve:", LocalPlayer.Name)
    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find("plot") or n:find("base") or n:find("house") or n:find("home") then
            print("Talált:", obj:GetFullName(), "| Típus:", obj.ClassName)
            local owner = obj:FindFirstChild("Owner") or obj:FindFirstChild("Player")
            if owner then
                print("  -> Owner:", owner.ClassName, owner.Value)
            end
        end
    end
    print("=== VÉGE ===")
end

-- ============================================================
--  FŐMENÜ
-- ============================================================
MainTab:CreateButton({
    Name = "🏠 Teleport a telekre",
    Callback = function()
        local pos = getPlotPosition()
        if not pos then
            Rayfield:Notify({Title="Hiba", Content="Nem találom a telket!", Duration=5})
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

MainTab:CreateButton({
    Name = "🔍 Debug (plot nevek az F9 konzolba)",
    Callback = function()
        debugPlots()
        Rayfield:Notify({Title="Debug", Content="Nézd meg az F9 konzolt!", Duration=3})
    end
})

-- ============================================================
--  2) SPEED HACK
-- ============================================================
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
    Name = "▶ Speed alkalmazása most",
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
    Name = "🔄 Reset (16)",
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

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = currentSpeed end
end)

-- ============================================================
--  3) LIVEAREAEGGS TELEPORT
-- ============================================================
local EGG_FOLDER_NAMES = { "LiveAreaEggs", "Eggs", "LiveEggs", "LiveAreaEgg" }

local function getPositionFromInstance(inst)
    if inst:IsA("BasePart") then
        return inst.Position
    elseif inst:IsA("Model") then
        local primary = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
        if primary then return primary.Position end
    elseif inst:IsA("Attachment") then
        return inst.WorldPosition
    end
    local part = inst:FindFirstChildWhichIsA("BasePart", true)
    if part then return part.Position end
    return nil
end

local function collectEggs()
    local eggs = {}
    local seen = {}
    for _, folderName in ipairs(EGG_FOLDER_NAMES) do
        local folder = game.Workspace:FindFirstChild(folderName)
        if folder then
            for _, obj in ipairs(folder:GetDescendants()) do
                if not seen[obj] then
                    local pos = getPositionFromInstance(obj)
                    if pos then
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

local eggDropdown
local eggList = {}

local function refreshEggList()
    eggList = collectEggs()
    local names = {}
    local seenNames = {}
    for _, e in ipairs(eggList) do
        local display = e.name
        local counter = 1
        while seenNames[display] do
            counter = counter + 1
            display = e.name .. " (" .. counter .. ")"
        end
        seenNames[display] = true
        e.display = display
        table.insert(names, display)
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

eggDropdown = EggsTab:CreateDropdown({
    Name = "Válassz tojást",
    Options = { "(kattints a Refresh-re)" },
    CurrentOption = { "(kattints a Refresh-re)" },
    MultipleOptions = false,
    Flag = "EggDropdown",
    Callback = function(option)
        local chosen = option
        if type(option) == "table" then chosen = option[1] end
        if not chosen or chosen == "(nincs tojás)" or chosen == "(kattints a Refresh-re)" then return end

        for _, e in ipairs(eggList) do
            if e.display == chosen or e.name == chosen then
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

EggsTab:CreateButton({
    Name = "🔄 Refresh tojáslista",
    Callback = function()
        refreshEggList()
    end
})

task.spawn(function()
    task.wait(1)
    refreshEggList()
end)

-- ============================================================
--  BETÖLTÉS KÉSZ
-- ============================================================
Rayfield:Notify({
    Title = "Betöltve!",
    Content = "Plot & Egg Teleport + Speed aktív.",
    Duration = 4
})
