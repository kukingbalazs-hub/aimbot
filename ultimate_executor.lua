--[[
    ═══════════════════════════════════════════════
    ⚡ RAYFIELD EXECUTOR SCRIPT (FIXED) ⚡
    Speed Hack + Aimbot + ESP + Fly
    ═══════════════════════════════════════════════
    Toggle key: K
--]]

-- ═══════════ RAYFIELD BETÖLTÉSE ═══════════
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ═══════════ SZOLGÁLTATÁSOK ═══════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local LocalPlayer       = Players.LocalPlayer

-- ═══════════ KONFIGURÁCIÓ ═══════════
local Config = {
    WalkSpeed       = 50,
    JumpPower       = 100,
    SpeedEnabled    = false,
    AimbotEnabled   = false,
    AimbotKey       = Enum.KeyCode.E,
    AimbotFOV       = 150,
    AimbotSmooth    = 0.15,
    AimbotPart      = "Head",
    AimbotVisible   = true,
    TeamCheck       = true,         -- ✅ HOZZÁADVA
    ESPEnabled      = false,
    ESPBox          = true,
    ESPName         = true,
    ESPHealth       = true,
    ESPDistance     = true,
    ESPTracer       = false,
    ESPTeamCheck    = true,
    FlyEnabled      = false,
    FlySpeed        = 80,
    InfJump         = false,
}

-- ═══════════ ELŐRE DEKLARÁLT FÜGGVÉNYEK ═══════════
local startFly, stopFly, clearAllESP

-- ═══════════ RAYFIELD WINDOW ═══════════
local Window = Rayfield:CreateWindow({
    Name = "⚡ Ultimate Executor",
    Icon = 0,
    LoadingTitle = "Ultimate Executor",
    LoadingSubtitle = "by AI",
    Theme = "Amethyst",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "UltimateExecutor",
        FileName = "Config"
    },
    Discord = { Enabled = false },
    KeySystem = false
})

-- ═══════════ TABOK ═══════════
local SpeedTab = Window:CreateTab("🚀 Speed", 4483362458)
local AimTab   = Window:CreateTab("🎯 Aimbot", 4483362458)
local EspTab   = Window:CreateTab("👁 ESP", 4483362458)
local MiscTab  = Window:CreateTab("⚙ Misc", 4483362458)

-- ═══════════ SPEED TAB ═══════════
SpeedTab:CreateSection("Speed Beállítások")

SpeedTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Flag = "SpeedToggle",
    Callback = function(Value)
        Config.SpeedEnabled = Value
    end,
})

SpeedTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 300},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 50,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        Config.WalkSpeed = Value
    end,
})

SpeedTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 500},
    Increment = 5,
    Suffix = "Jump",
    CurrentValue = 100,
    Flag = "JumpSlider",
    Callback = function(Value)
        Config.JumpPower = Value
    end,
})

SpeedTab:CreateSection("Fly")

SpeedTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(Value)
        Config.FlyEnabled = Value
        if Value then
            if startFly then startFly() end
        else
            if stopFly then stopFly() end
        end
    end,
})

SpeedTab:CreateSlider({
    Name = "Fly Speed",
    Range = {20, 500},
    Increment = 5,
    Suffix = "Speed",
    CurrentValue = 80,
    Flag = "FlySpeedSlider",
    Callback = function(Value)
        Config.FlySpeed = Value
    end,
})

SpeedTab:CreateSection("Jump")

SpeedTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(Value)
        Config.InfJump = Value
    end,
})

-- ═══════════ AIMBOT TAB ═══════════
AimTab:CreateSection("Aimbot")

AimTab:CreateToggle({
    Name = "Aimbot Enabled",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(Value)
        Config.AimbotEnabled = Value
    end,
})

AimTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "TeamCheck",
    Callback = function(Value)
        Config.TeamCheck = Value
    end,
})

AimTab:CreateToggle({
    Name = "Visible Check",
    CurrentValue = true,
    Flag = "VisibleCheck",
    Callback = function(Value)
        Config.AimbotVisible = Value
    end,
})

AimTab:CreateSlider({
    Name = "FOV",
    Range = {10, 500},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 150,
    Flag = "FOVSlider",
    Callback = function(Value)
        Config.AimbotFOV = Value
    end,
})

AimTab:CreateSlider({
    Name = "Smoothness",
    Range = {1, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 15,
    Flag = "SmoothSlider",
    Callback = function(Value)
        Config.AimbotSmooth = Value / 100
    end,
})

AimTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso"},
    CurrentOption = "Head",
    Flag = "TargetPart",
    Callback = function(Option)
        Config.AimbotPart = Option
    end,
})

-- ═══════════ ESP TAB ═══════════
EspTab:CreateSection("ESP Beállítások")

EspTab:CreateToggle({
    Name = "ESP Enabled",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(Value)
        Config.ESPEnabled = Value
        if not Value and clearAllESP then clearAllESP() end
    end,
})

EspTab:CreateToggle({
    Name = "Box",
    CurrentValue = true,
    Flag = "ESPBox",
    Callback = function(Value) Config.ESPBox = Value end,
})

EspTab:CreateToggle({
    Name = "Name",
    CurrentValue = true,
    Flag = "ESPName",
    Callback = function(Value) Config.ESPName = Value end,
})

EspTab:CreateToggle({
    Name = "Health Bar",
    CurrentValue = true,
    Flag = "ESPHealth",
    Callback = function(Value) Config.ESPHealth = Value end,
})

EspTab:CreateToggle({
    Name = "Distance",
    CurrentValue = true,
    Flag = "ESPDistance",
    Callback = function(Value) Config.ESPDistance = Value end,
})

EspTab:CreateToggle({
    Name = "Tracer",
    CurrentValue = false,
    Flag = "ESPTracer",
    Callback = function(Value) Config.ESPTracer = Value end,
})

EspTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "ESPTeamCheck",
    Callback = function(Value) Config.ESPTeamCheck = Value end,
})

-- ═══════════ MISC TAB ═══════════
MiscTab:CreateSection("Játékos")

MiscTab:CreateButton({
    Name = "🔄 Respawn",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
        end
    end,
})

MiscTab:CreateButton({
    Name = "💀 Reset Character",
    Callback = function()
        LocalPlayer:LoadCharacter()
    end,
})

MiscTab:CreateParagraph({
    Title = "Info",
    Content = "Rayfield UI-val készült. Toggle key: K"
})

-- ═══════════ SPEED LOGIKA ═══════════
local function applySpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if Config.SpeedEnabled then
        hum.WalkSpeed = Config.WalkSpeed
        hum.JumpPower = Config.JumpPower
        hum.UseJumpPower = true
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    applySpeed()
end)

RunService.Heartbeat:Connect(function()
    if Config.SpeedEnabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if hum.WalkSpeed ~= Config.WalkSpeed then hum.WalkSpeed = Config.WalkSpeed end
            if hum.UseJumpPower and hum.JumpPower ~= Config.JumpPower then hum.JumpPower = Config.JumpPower end
        end
    end
end)

-- ═══════════ INFINITE JUMP ═══════════
UserInputService.JumpRequest:Connect(function()
    if Config.InfJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ═══════════ FLY LOGIKA ═══════════
local flyConn, flyBV, flyBG

startFly = function()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    flyBV = Instance.new("BodyVelocity")
    flyBV.Velocity = Vector3.zero
    flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Parent = hrp

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBG.P = 1000
    flyBG.D = 50
    flyBG.Parent = hrp

    flyConn = RunService.RenderStepped:Connect(function()
        if not Config.FlyEnabled then return end
        local cam = Workspace.CurrentCamera
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0, 1, 0) end

        flyBV.Velocity = moveDir * Config.FlySpeed
        flyBG.CFrame = cam.CFrame
    end)
end

stopFly = function()
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
end

-- ═══════════ AIMBOT LOGIKA ═══════════
local function isVisible(target)
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local targetPart = target:FindFirstChild(Config.AimbotPart) or target:FindFirstChild("HumanoidRootPart")
    if not targetPart then return false end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char, target}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local result = Workspace:Raycast(hrp.Position, targetPart.Position - hrp.Position, params)
    return result == nil
end

local function getClosestTarget()
    local closest, closestDist = nil, math.huge
    local cam = Workspace.CurrentCamera
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    local isTeammate = Config.TeamCheck and player.Team == LocalPlayer.Team
                    if not isTeammate then
                        local targetPart = char:FindFirstChild(Config.AimbotPart) or hrp
                        local screenPos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                            if dist < Config.AimbotFOV and dist < closestDist then
                                if not Config.AimbotVisible or isVisible(char) then
                                    closest = targetPart
                                    closestDist = dist
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if Config.AimbotEnabled and UserInputService:IsKeyDown(Config.AimbotKey) then
        local target = getClosestTarget()
        if target then
            local cam = Workspace.CurrentCamera
            local goal = CFrame.new(cam.CFrame.Position, target.Position)
            cam.CFrame = cam.CFrame:Lerp(goal, Config.AimbotSmooth)
        end
    end
end)

-- ═══════════ ESP LOGIKA ═══════════
local espObjects = {}

local function createESP(player)
    if player == LocalPlayer then return end
    if espObjects[player] then return end

    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "RayfieldESP"
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = hrp
    billboard.Parent = CoreGui

    local box = Instance.new("Frame")
    box.Name = "Box"
    box.Size = UDim2.new(0, 50, 0, 60)
    box.Position = UDim2.new(0.5, -25, 0.5, -30)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = Config.ESPBox
    box.Parent = billboard

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.fromRGB(138, 43, 226)
    boxStroke.Thickness = 1.5
    boxStroke.Parent = box

    local hpBarBg = Instance.new("Frame")
    hpBarBg.Name = "HPBarBg"
    hpBarBg.Size = UDim2.new(0, 3, 0, 60)
    hpBarBg.Position = UDim2.new(0.5, 27, 0.5, -30)
    hpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBarBg.BorderSizePixel = 0
    hpBarBg.Visible = Config.ESPHealth
    hpBarBg.Parent = billboard

    local hpBar = Instance.new("Frame")
    hpBar.Name = "HPBar"
    hpBar.Size = UDim2.new(1, 0, 1, 0)
    hpBar.Position = UDim2.new(0, 0, 1, 0)
    hpBar.AnchorPoint = Vector2.new(0, 1)
    hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    hpBar.BorderSizePixel = 0
    hpBar.Parent = hpBarBg

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.Position = UDim2.new(0, 0, 0, -18)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.Visible = Config.ESPName
    nameLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, 0, 0, 14)
    distLabel.Position = UDim2.new(0, 0, 1, 2)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.fromRGB(138, 43, 226)
    distLabel.TextStrokeTransparency = 0
    distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 11
    distLabel.Visible = Config.ESPDistance
    distLabel.Parent = billboard

    local tracer = Instance.new("Frame")
    tracer.Name = "Tracer"
    tracer.AnchorPoint = Vector2.new(0.5, 0)
    tracer.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    tracer.BorderSizePixel = 0
    tracer.Size = UDim2.new(0, 1, 0, 0)
    tracer.ZIndex = 2
    tracer.Visible = Config.ESPTracer
    tracer.Parent = CoreGui

    -- ✅ FIX: Nincs Player kulcs a táblában!
    espObjects[player] = {
        Billboard = billboard,
        Box = box,
        BoxStroke = boxStroke,
        HPBar = hpBar,
        HPBarBg = hpBarBg,
        NameLabel = nameLabel,
        DistLabel = distLabel,
        Tracer = tracer,
    }
end

local function removeESP(player)
    if espObjects[player] then
        for _, obj in pairs(espObjects[player]) do
            if typeof(obj) == "Instance" then obj:Destroy() end
        end
        espObjects[player] = nil
    end
end

clearAllESP = function()
    for player, _ in pairs(espObjects) do
        removeESP(player)
    end
end

RunService.RenderStepped:Connect(function()
    if not Config.ESPEnabled then return end
    local cam = Workspace.CurrentCamera

    for player, data in pairs(espObjects) do
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local isEnemy = not (player.Team == LocalPlayer.Team)
                if not Config.ESPTeamCheck or isEnemy then
                    data.Billboard.Enabled = true
                    data.Tracer.Visible = Config.ESPTracer

                    data.Box.Visible = Config.ESPBox
                    data.BoxStroke.Color = isEnemy and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(60, 255, 60)

                    data.HPBarBg.Visible = Config.ESPHealth
                    local hpRatio = hum.Health / hum.MaxHealth
                    data.HPBar.Size = UDim2.new(1, 0, hpRatio, 0)
                    data.HPBar.BackgroundColor3 = Color3.fromRGB(
                        math.floor(255 * (1 - hpRatio)),
                        math.floor(255 * hpRatio),
                        0
                    )

                    data.NameLabel.Visible = Config.ESPName
                    data.NameLabel.Text = player.Name

                    if Config.ESPDistance then
                        local dist = math.floor((hrp.Position - cam.CFrame.Position).Magnitude)
                        data.DistLabel.Visible = true
                        data.DistLabel.Text = dist .. "m"
                    else
                        data.DistLabel.Visible = false
                    end

                    if Config.ESPTracer then
                        local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter)
                            local length = dist.Magnitude
                            local angle = math.deg(math.atan2(dist.Y, dist.X)) - 90

                            data.Tracer.Position = UDim2.new(0, screenCenter.X, 0, screenCenter.Y)
                            data.Tracer.Size = UDim2.new(0, 1, 0, length)
                            data.Tracer.Rotation = angle
                        end
                    end
                else
                    data.Billboard.Enabled = false
                    data.Tracer.Visible = false
                end
            else
                data.Billboard.Enabled = false
                data.Tracer.Visible = false
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if Config.ESPEnabled then createESP(p) end
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    removeESP(p)
end)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if Config.ESPEnabled then createESP(p) end
        end)
        if p.Character and Config.ESPEnabled then
            createESP(p)
        end
    end
end

-- ═══════════ ÉRTESÍTÉS ═══════════
Rayfield:Notify({
    Title = "⚡ Ultimate Executor",
    Content = "Script sikeresen betöltve! Toggle: K",
    Duration = 5,
    Image = 4483362458,
})

print("[⚡ Ultimate Executor] Betöltve Rayfield UI-val")
print("  • Toggle GUI: K")
print("  • Aimbot key: E")