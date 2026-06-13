--[[
    NINO HUB - FULL COMPLETO
    Todas las funciones originales + Auto Grab Prime + Auto Play + Anti Bat + Medusa Reset
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

-- ============================================================
-- EFECTO DE CLIMA
-- ============================================================
local function applyWeatherEffect()
    pcall(function()
        Lighting.ClockTime = 16.5
        Lighting.Brightness = 1.8
        Lighting.FogStart = 50
        Lighting.FogEnd = 250
        Lighting.FogColor = Color3.fromRGB(180, 180, 175)

        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if not atmosphere then
            atmosphere = Instance.new("Atmosphere")
            atmosphere.Parent = Lighting
        end
        atmosphere.Density = 0.45
        atmosphere.Haze = 3
        atmosphere.Glare = 0.15

        local terrain = workspace.Terrain
        if terrain then
            local clouds = terrain:FindFirstChildOfClass("Clouds")
            if clouds then
                clouds.Cover = 0.65
                clouds.Density = 0.5
                clouds.Color = Color3.fromRGB(220, 220, 220)
            end
        end
    end)
end
applyWeatherEffect()

-- ============================================================
-- ANIMACIÓN DE ENTRADA (efecto visual + música)
-- ============================================================
local function playIntro()
    local TS = TweenService
    local CG = game:GetService("CoreGui")
    local SS = game:GetService("SoundService")
    
    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = Lighting

    local gui = Instance.new("ScreenGui")
    gui.Name = "NinoHubIntro"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    pcall(function() gui.Parent = CG end)
    if not gui.Parent then gui.Parent = LP.PlayerGui end

    local holder = Instance.new("Frame")
    holder.Parent = gui
    holder.AnchorPoint = Vector2.new(0.5,0.5)
    holder.Position = UDim2.new(0.5,0,0.5,0)
    holder.Size = UDim2.new(0,700,0,140)
    holder.BackgroundTransparency = 1

    local shadow = Instance.new("TextLabel")
    shadow.Parent = holder
    shadow.Size = UDim2.fromScale(1,1)
    shadow.Position = UDim2.new(0,8,0,8)
    shadow.BackgroundTransparency = 1
    shadow.Text = "NINO HUB"
    shadow.Font = Enum.Font.Antique
    shadow.TextSize = 82
    shadow.TextColor3 = Color3.fromRGB(0,0,0)
    shadow.TextTransparency = 1

    local depth = Instance.new("TextLabel")
    depth.Parent = holder
    depth.Size = UDim2.fromScale(1,1)
    depth.Position = UDim2.new(0,4,0,4)
    depth.BackgroundTransparency = 1
    depth.Text = "NINO HUB"
    depth.Font = Enum.Font.Antique
    depth.TextSize = 82
    depth.TextColor3 = Color3.fromRGB(128,0,128)
    depth.TextTransparency = 1

    local title = Instance.new("TextLabel")
    title.Parent = holder
    title.Size = UDim2.fromScale(1,1)
    title.BackgroundTransparency = 1
    title.Text = "NINO HUB"
    title.Font = Enum.Font.Antique
    title.TextSize = 82
    title.TextColor3 = Color3.fromRGB(0,0,0)
    title.TextTransparency = 1
    title.TextStrokeTransparency = 0
    title.TextStrokeColor3 = Color3.fromRGB(128,0,128)

    local stroke = Instance.new("UIStroke")
    stroke.Parent = title
    stroke.Thickness = 3
    stroke.Color = Color3.fromRGB(128,0,128)
    stroke.Transparency = 0

    local glow = Instance.new("UIStroke")
    glow.Parent = title
    glow.Thickness = 10
    glow.Color = Color3.fromRGB(128,0,128)
    glow.Transparency = 0.75

    local grad = Instance.new("UIGradient")
    grad.Parent = title
    grad.Rotation = 90
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(60,0,60)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(128,0,128))
    })

    local shine = Instance.new("Frame")
    shine.Parent = holder
    shine.Size = UDim2.new(0,80,1,0)
    shine.Position = UDim2.new(-0.2,0,0,0)
    shine.BackgroundColor3 = Color3.fromRGB(255,255,255)
    shine.BackgroundTransparency = 0.82
    shine.BorderSizePixel = 0
    shine.Rotation = 15

    local music = Instance.new("Sound")
    music.Parent = SS
    music.SoundId = "rbxassetid://82149511707056"
    music.Volume = 1
    pcall(function() music:Play() end)

    TS:Create(blur, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Size = 24}):Play()
    TS:Create(title, TweenInfo.new(0.6), {TextTransparency = 0}):Play()
    TS:Create(depth, TweenInfo.new(0.6), {TextTransparency = 0}):Play()
    TS:Create(shadow, TweenInfo.new(0.6), {TextTransparency = 0.35}):Play()
    task.wait(0.7)
    TS:Create(shine, TweenInfo.new(1.1, Enum.EasingStyle.Linear), {Position = UDim2.new(1.2,0,0,0)}):Play()
    task.wait(4.3)
    TS:Create(title, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    TS:Create(depth, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    TS:Create(shadow, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    TS:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()
    task.wait(0.6)
    pcall(function() music:Destroy() end)
    pcall(function() blur:Destroy() end)
    pcall(function() gui:Destroy() end)
end
task.spawn(playIntro)

-- ============================================================
-- AUTO GRAB (Prime Hub)
-- ============================================================
local AutoGrab = {
    ENABLED = true,
    HOLD_MAX = 2.6,
    PRIME_RANGE = 80,
    isStealing = false,
    progressFill = nil,
    percentLabel = nil,
    allAnimalsCache = {},
    PromptMemoryCache = {},
    stealConnection = nil,
}

local function updateGrabProgress(p)
    if AutoGrab.progressFill then
        AutoGrab.progressFill.Size = UDim2.new(p, 0, 1, 0)
    end
    if AutoGrab.percentLabel then
        AutoGrab.percentLabel.Text = math.floor(p * 100) .. "%"
    end
end

local function setupAutoGrabUI()
    local sg = LP.PlayerGui:FindFirstChild("PrimeHub")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "PrimeHub"
        sg.ResetOnSpawn = false
        sg.Parent = LP.PlayerGui
    end

    if not AutoGrab.progressFill then
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0, 260, 0, 60)
        container.Position = UDim2.new(0.5, -130, 0, 80)
        container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        container.BackgroundTransparency = 0.85
        container.BorderSizePixel = 0
        container.Parent = sg
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)

        local bannerFrame = Instance.new("Frame")
        bannerFrame.Size = UDim2.new(1, 0, 0, 32)
        bannerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bannerFrame.BackgroundTransparency = 0
        bannerFrame.BorderSizePixel = 0
        bannerFrame.Parent = container
        Instance.new("UICorner", bannerFrame).CornerRadius = UDim.new(0, 10)

        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, 0, 1, 0)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Font = Enum.Font.GothamBold
        infoLabel.TextSize = 13
        infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        infoLabel.Text = "Auto Grab"
        infoLabel.TextXAlignment = Enum.TextXAlignment.Center
        infoLabel.Parent = bannerFrame

        local progressBg = Instance.new("Frame")
        progressBg.Size = UDim2.new(0.85, 0, 0, 14)
        progressBg.Position = UDim2.new(0.075, 0, 0, 38)
        progressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        progressBg.BorderSizePixel = 0
        progressBg.Parent = container
        Instance.new("UICorner", progressBg).CornerRadius = UDim.new(0, 8)

        AutoGrab.progressFill = Instance.new("Frame")
        AutoGrab.progressFill.Size = UDim2.new(0, 0, 1, 0)
        AutoGrab.progressFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        AutoGrab.progressFill.BorderSizePixel = 0
        AutoGrab.progressFill.Parent = progressBg
        Instance.new("UICorner", AutoGrab.progressFill).CornerRadius = UDim.new(0, 8)

        AutoGrab.percentLabel = Instance.new("TextLabel")
        AutoGrab.percentLabel.Size = UDim2.new(1, 0, 1, 0)
        AutoGrab.percentLabel.BackgroundTransparency = 1
        AutoGrab.percentLabel.Font = Enum.Font.GothamBold
        AutoGrab.percentLabel.TextSize = 10
        AutoGrab.percentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        AutoGrab.percentLabel.Text = "0%"
        AutoGrab.percentLabel.Parent = progressBg

        local frames = 0
        local last = tick()
        RunService.RenderStepped:Connect(function()
            frames = frames + 1
            if tick() - last >= 1 then
                local fps = frames
                frames = 0
                last = tick()
                local ping = 0
                local net = Stats:FindFirstChild("Network")
                if net and net:FindFirstChild("ServerStatsItem") then
                    local dp = net.ServerStatsItem:FindFirstChild("Data Ping")
                    if dp then ping = math.floor(dp:GetValue()) end
                end
                infoLabel.Text = "Auto Grab | " .. fps .. " FPS | " .. ping .. "ms"
            end
        end)
    end
end

local function findNearestAnimal()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    
    local best, bestDist = nil, AutoGrab.PRIME_RANGE
    
    for _, plot in ipairs(plots:GetChildren()) do
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if podiums then
            for _, podium in ipairs(podiums:GetChildren()) do
                local base = podium:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist = (spawn.Position - root.Position).Magnitude
                    if dist < bestDist then
                        local attach = spawn:FindFirstChild("PromptAttachment")
                        if attach then
                            for _, prompt in ipairs(attach:GetChildren()) do
                                if prompt:IsA("ProximityPrompt") then
                                    bestDist = dist
                                    best = prompt
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function executeSteal(prompt)
    if AutoGrab.isStealing or not prompt or not prompt.Parent then return end
    AutoGrab.isStealing = true
    local start = tick()
    
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not AutoGrab.isStealing then conn:Disconnect(); return end
        local p = math.clamp((tick() - start) / AutoGrab.HOLD_MAX, 0, 1)
        updateGrabProgress(p)
    end)
    
    task.spawn(function()
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(AutoGrab.HOLD_MAX)
            prompt:InputHoldEnd()
        end)
        task.wait(0.3)
        AutoGrab.isStealing = false
        updateGrabProgress(0)
        if conn then conn:Disconnect() end
    end)
end

local function startAutoSteal()
    if AutoGrab.stealConnection then return end
    AutoGrab.stealConnection = RunService.Heartbeat:Connect(function()
        if not AutoGrab.ENABLED or AutoGrab.isStealing then return end
        local prompt = findNearestAnimal()
        if prompt then executeSteal(prompt) end
    end)
end

local function stopAutoSteal()
    if AutoGrab.stealConnection then
        AutoGrab.stealConnection:Disconnect()
        AutoGrab.stealConnection = nil
    end
    AutoGrab.isStealing = false
    updateGrabProgress(0)
end

setupAutoGrabUI()
if AutoGrab.ENABLED then startAutoSteal() end

-- ============================================================
-- AUTO PLAY (waypoints)
-- ============================================================
local leftWaypoints = {
    Vector3.new(-476.85, -6.59, 94.91),
    Vector3.new(-485.55, -4.53, 100.61),
    Vector3.new(-475.60, -6.59, 92.80),
    Vector3.new(-475.26, -6.57, 21.54),
}

local rightWaypoints = {
    Vector3.new(-475.77, -6.57, 26.76),
    Vector3.new(-485.85, -4.48, 20.13),
    Vector3.new(-475.83, -6.59, 26.54),
    Vector3.new(-476.17, -6.09, 97.73),
}

local autoPlay = { enabled = false, side = "left", proxy = nil, conn = nil, waypoints = nil, index = 1, frozen = false, freezeUntil = 0 }

local function ensureProxy()
    local char = LP.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    if not autoPlay.proxy or autoPlay.proxy.Parent ~= char then
        if autoPlay.proxy then autoPlay.proxy:Destroy() end
        autoPlay.proxy = Instance.new("Part")
        autoPlay.proxy.Size = Vector3.new(1, 1, 1)
        autoPlay.proxy.Transparency = 1
        autoPlay.proxy.CanCollide = false
        autoPlay.proxy.Massless = true
        autoPlay.proxy.Parent = char
        local weld = Instance.new("Weld")
        weld.Part0 = hrp
        weld.Part1 = autoPlay.proxy
        weld.C0 = CFrame.new(0, 0, 0)
        weld.Parent = autoPlay.proxy
    end
    return autoPlay.proxy
end

local function moveTo(target, speed)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dir = (target - hrp.Position)
    local moveDir = Vector3.new(dir.X, 0, dir.Z).Unit
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:Move(moveDir, false) end
    if autoPlay.proxy then
        autoPlay.proxy.AssemblyLinearVelocity = Vector3.new(moveDir.X * speed, autoPlay.proxy.AssemblyLinearVelocity.Y, moveDir.Z * speed)
    end
end

local function stopMoving()
    if autoPlay.proxy then autoPlay.proxy.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:Move(Vector3.zero, false) end
end

local function startPatrol(waypoints)
    if autoPlay.conn then autoPlay.conn:Disconnect() end
    autoPlay.waypoints = waypoints
    autoPlay.index = 1
    autoPlay.frozen = false
    ensureProxy()
    autoPlay.conn = RunService.Stepped:Connect(function()
        if not autoPlay.enabled or not autoPlay.waypoints then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        if autoPlay.frozen then
            stopMoving()
            if tick() >= autoPlay.freezeUntil then
                autoPlay.frozen = false
                autoPlay.index = autoPlay.index + 1
            end
            return
        end
        
        local target = autoPlay.waypoints[autoPlay.index]
        if not target then return end
        
        local dist = (target - hrp.Position).Magnitude
        local speed = (autoPlay.index <= 2) and 55 or 29
        
        if dist < 2.5 then
            if autoPlay.index == 2 then
                autoPlay.frozen = true
                autoPlay.freezeUntil = tick() + 0.7
                stopMoving()
                return
            end
            autoPlay.index = autoPlay.index + 1
            if autoPlay.index > #autoPlay.waypoints then
                autoPlay.enabled = false
                stopMoving()
                if autoPlay.conn then autoPlay.conn:Disconnect(); autoPlay.conn = nil end
                if uiUpdate then uiUpdate() end
            end
        else
            moveTo(target, speed)
        end
    end)
end

local function stopPatrol()
    if autoPlay.conn then autoPlay.conn:Disconnect(); autoPlay.conn = nil end
    autoPlay.waypoints = nil
    autoPlay.index = 1
    stopMoving()
end

-- ============================================================
-- ANTI BAT
-- ============================================================
local antiBat = { enabled = false, conn = nil }

local function startAntiBat()
    if antiBat.conn then return end
    antiBat.conn = RunService.Heartbeat:Connect(function()
        if not antiBat.enabled then return end
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local orig = root.Velocity
        root.Velocity = Vector3.new(1000, orig.Y, 1000)
        task.wait()
        local r2 = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if r2 then r2.Velocity = orig end
    end)
end

local function stopAntiBat()
    if antiBat.conn then antiBat.conn:Disconnect(); antiBat.conn = nil end
end

-- ============================================================
-- INSTA RESET
-- ============================================================
local resetRemote = nil
local resetCD = false

local function findRemote()
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") and string.sub(obj.Name, 1, 3) == "RE/" then
            resetRemote = obj
            return true
        end
    end
    return false
end

local function instaReset()
    if resetCD then return end
    if not resetRemote and not findRemote() then return end
    resetCD = true
    pcall(function() resetRemote:FireServer("f888ee6e-c86d-46e1-93d7-0639d6635d42", LP, "balloon") end)
    task.wait(0.5)
    resetCD = false
end

-- ============================================================
-- MEDUSA AUTO RESET
-- ============================================================
local medusaReset = { enabled = true, conns = {} }

local function onPartAnchor(part)
    return part:GetPropertyChangedSignal("Anchored"):Connect(function()
        if part.Anchored and part.Transparency == 1 and medusaReset.enabled then
            instaReset()
        end
    end)
end

local function setupMedusa(char)
    for _, c in pairs(medusaReset.conns) do pcall(function() c:Disconnect() end) end
    medusaReset.conns = {}
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(medusaReset.conns, onPartAnchor(part))
        end
    end
    table.insert(medusaReset.conns, char.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then
            table.insert(medusaReset.conns, onPartAnchor(part))
        end
    end))
end

-- ============================================================
-- BAT AIMBOT
-- ============================================================
local batAimbot = { enabled = false, conn = nil, cooldown = false }
local batHighlight = Instance.new("Highlight")
batHighlight.FillColor = Color3.fromRGB(128, 0, 128)
batHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
batHighlight.FillTransparency = 0.5
pcall(function() batHighlight.Parent = LP.PlayerGui end)

local function getBat()
    local char = LP.Character
    if not char then return nil end
    local bp = LP:FindFirstChildOfClass("Backpack")
    local names = {"Bat", "Slap", "Iron Slap", "Gold Slap", "Diamond Slap", "Emerald Slap", "Ruby Slap", "Dark Matter Slap", "Flame Slap", "Nuclear Slap", "Galaxy Slap", "Glitched Slap"}
    for _, n in ipairs(names) do
        local t = char:FindFirstChild(n) or (bp and bp:FindFirstChild(n))
        if t then return t end
    end
    return nil
end

local function hitBat()
    if batAimbot.cooldown then return end
    batAimbot.cooldown = true
    local bat = getBat()
    if bat then pcall(function() bat:Activate() end) end
    task.delay(0.12, function() batAimbot.cooldown = false end)
end

local function getTarget()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local best, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if tr and h and h.Health > 0 and not p.Character:FindFirstChildOfClass("ForceField") then
                local d = (tr.Position - root.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = tr
                end
            end
        end
    end
    return best
end

local function startBatAimbot()
    if batAimbot.conn then return end
    batAimbot.enabled = true
    batAimbot.conn = RunService.Heartbeat:Connect(function()
        if not batAimbot.enabled then return end
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local target = getTarget()
        if target then
            batHighlight.Adornee = target.Parent
            local vel = target.AssemblyLinearVelocity
            local pred = math.clamp(vel.Magnitude / 130, 0.05, 0.18)
            local pos = target.Position + (vel * pred) + target.CFrame.LookVector * 4
            local dir = (pos - root.Position)
            if dir.Magnitude > 0.1 then
                dir = dir.Unit
                root.AssemblyLinearVelocity = Vector3.new(dir.X * 58, dir.Y * 58, dir.Z * 58)
            end
            if (target.Position - root.Position).Magnitude <= 8 then hitBat() end
        else
            batHighlight.Adornee = nil
        end
    end)
end

local function stopBatAimbot()
    batAimbot.enabled = false
    if batAimbot.conn then batAimbot.conn:Disconnect(); batAimbot.conn = nil end
    batHighlight.Adornee = nil
end

-- ============================================================
-- FUNCIONES ADICIONALES
-- ============================================================
local function tpToFloor()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local res = workspace:Raycast(root.Position, Vector3.new(0, -500, 0), params)
    if res then
        root.CFrame = CFrame.new(root.Position.X, res.Position.Y + root.Size.Y/2 + 0.5, root.Position.Z)
        root.AssemblyLinearVelocity = Vector3.zero
    end
end

local function dropBrainrot()
    local active = false
    local conn = RunService.Stepped:Connect(function()
        if not active then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                for _, part in ipairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
    end)
    active = true
    task.spawn(function()
        while active do
            local char = LP.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local v = root.Velocity
                root.Velocity = v * 10000 + Vector3.new(0, 10000, 0)
                task.wait()
                if root and root.Parent then root.Velocity = v end
                task.wait()
            end
        end
    end)
    task.delay(0.3, function() active = false; conn:Disconnect() end)
end

-- ============================================================
-- VARIABLES PRINCIPALES
-- ============================================================
local state = {
    normalSpeed = 60,
    carrySpeed = 30,
    laggerSpeed = 10.1,
    laggerSpeed2 = 10,
    speedMode = false,
    laggerMode = 0,
    antiRagdoll = false,
    infJump = false,
    holdJump = false,
    fpsBoost = false,
    galaxyMode = false,
    autoTpDown = false,
    unwalk = false,
    medusaCounter = false,
}

local h, hrp, speedLabel

-- ============================================================
-- MOVEMENT
-- ============================================================
local moveConn = nil

local function getActiveSpeed()
    if state.laggerMode == 1 then return state.laggerSpeed
    elseif state.laggerMode == 2 then return state.laggerSpeed2
    elseif state.speedMode then return state.carrySpeed
    else return state.normalSpeed end
end

local function startMovement()
    if moveConn then moveConn:Disconnect() end
    moveConn = RunService.RenderStepped:Connect(function()
        if not (h and hrp) then return end
        if batAimbot.enabled or autoPlay.enabled then return end
        local md = h.MoveDirection
        if md.Magnitude > 0 then
            local s = getActiveSpeed()
            hrp.Velocity = Vector3.new(md.X * s, hrp.Velocity.Y, md.Z * s)
        end
    end)
end

local function stopMovement()
    if moveConn then moveConn:Disconnect(); moveConn = nil end
end

-- ============================================================
-- INF JUMP
-- ============================================================
local function startInfJump()
    local conn = UIS.JumpRequest:Connect(function()
        if state.infJump and hrp then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, 50, hrp.Velocity.Z)
        end
    end)
    return conn
end

local infJumpConn = nil

-- ============================================================
-- ANTI RAGDOLL
-- ============================================================
local antiRagConn = nil

local function startAntiRag()
    if antiRagConn then return end
    antiRagConn = RunService.Heartbeat:Connect(function()
        if not state.antiRagdoll then return end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                if hrp then hrp.Velocity = Vector3.zero end
            end
        end
    end)
end

-- ============================================================
-- AUTO TP DOWN
-- ============================================================
local autoTpConn = nil

local function startAutoTp()
    if autoTpConn then return end
    autoTpConn = RunService.Heartbeat:Connect(function()
        if not state.autoTpDown then return end
        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if root and root.Position.Y >= 20 then
            local rot = root.CFrame.Rotation
            root.CFrame = CFrame.new(root.Position.X, -9, root.Position.Z) * rot
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
        end
    end)
end

-- ============================================================
-- FPS BOOST
-- ============================================================
local function boostFPS()
    pcall(function()
        for _, v in pairs(workspace:GetDescendants()) do
            pcall(function()
                if v:IsA("BasePart") then
                    v.CastShadow = false
                    v.Material = Enum.Material.Plastic
                elseif v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") then
                    v.Enabled = false
                elseif v:IsA("Decal") then
                    v.Transparency = 1
                end
            end)
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 999999
    end)
end

-- ============================================================
-- GALAXY MODE
-- ============================================================
local defBright, defClock

local function applyGalaxy()
    if state.galaxyMode then
        defBright = Lighting.Brightness
        defClock = Lighting.ClockTime
        local sky = Lighting:FindFirstChild("GalaxySky") or Instance.new("Sky")
        sky.Name = "GalaxySky"
        sky.SkyboxBk = "rbxassetid://90008389385236"
        sky.SkyboxDn = "rbxassetid://135894687762727"
        sky.SkyboxFt = "rbxassetid://135894687762727"
        sky.SkyboxLf = "rbxassetid://135894687762727"
        sky.SkyboxRt = "rbxassetid://135894687762727"
        sky.SkyboxUp = "rbxassetid://135894687762727"
        sky.Parent = Lighting
        Lighting.Brightness = 0
        Lighting.ClockTime = 0
    else
        if Lighting:FindFirstChild("GalaxySky") then Lighting.GalaxySky:Destroy() end
        Lighting.Brightness = defBright or 1.8
        Lighting.ClockTime = defClock or 16.5
    end
end

-- ============================================================
-- MEDUSA COUNTER (original)
-- ============================================================
local medusaLast = 0
local medusaCD = 25

local function useMedusa()
    if tick() - medusaLast < medusaCD then return end
    local char = LP.Character
    if not char then return end
    local med = nil
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") and (t.Name:lower():find("medusa") or t.Name:lower():find("head")) then
            med = t; break
        end
    end
    if not med then
        local bp = LP:FindFirstChildOfClass("Backpack")
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and (t.Name:lower():find("medusa") or t.Name:lower():find("head")) then
                    med = t
                    break
                end
            end
        end
    end
    if med then
        if med.Parent ~= char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:EquipTool(med) end
        end
        pcall(function() med:Activate() end)
        medusaLast = tick()
    end
end

-- ============================================================
-- SPEED BILLBOARD
-- ============================================================
local function setupSpeedBB(char)
    local head = char:FindFirstChild("Head")
    if not head then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "SpeedBB"
    bb.Size = UDim2.new(0, 100, 0, 32)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head
    speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(1, 0, 1, 0)
    speedLabel.BackgroundTransparency = 1
    speedLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
    speedLabel.Font = Enum.Font.GothamBlack
    speedLabel.TextScaled = true
    speedLabel.Parent = bb
    return speedLabel
end

-- ============================================================
-- SPEED COUNTER LOOP
-- ============================================================
local lastSpeed = -1
RunService.Heartbeat:Connect(function()
    if speedLabel then
        local s = getActiveSpeed()
        if s ~= lastSpeed then
            lastSpeed = s
            speedLabel.Text = tostring(s)
        end
    end
end)

-- ============================================================
-- NOCLIP
-- ============================================================
RunService.Stepped:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

-- ============================================================
-- FPS COUNTER
-- ============================================================
local fps = 0
local fpsCount = 0
local fpsLast = tick()
RunService.RenderStepped:Connect(function()
    fpsCount = fpsCount + 1
    if tick() - fpsLast >= 1 then
        fps = fpsCount
        fpsCount = 0
        fpsLast = tick()
    end
end)

-- ============================================================
-- UI PRINCIPAL
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NinoHub"
screenGui.ResetOnSpawn = false
pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
if not screenGui.Parent then screenGui.Parent = LP.PlayerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 300, 0, 500)
main.Position = UDim2.new(0.5, -150, 0.5, -250)
main.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
main.BorderSizePixel = 0
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundColor3 = Color3.fromRGB(128, 0, 128)
header.BorderSizePixel = 0
header.Parent = main
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local headerText = Instance.new("TextLabel")
headerText.Size = UDim2.new(1, 0, 1, 0)
headerText.BackgroundTransparency = 1
headerText.Text = "NINO HUB"
headerText.TextColor3 = Color3.fromRGB(255, 255, 255)
headerText.Font = Enum.Font.GothamBlack
headerText.TextSize = 20
headerText.Parent = header

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -60)
scroll.Position = UDim2.new(0, 10, 0, 55)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local function makeBtn(text, color, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = color or Color3.fromRGB(25, 25, 30)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

local function makeToggle(text, get, set)
    local btn = makeBtn(text .. ": OFF", nil, function()
        set(not get())
        btn.Text = text .. ": " .. (get() and "ON" or "OFF")
    end)
    return function() btn.Text = text .. ": " .. (get() and "ON" or "OFF") end
end

-- Variables UI
local updateAutoGrab, updateAutoLeft, updateAutoRight, updateAntiBat, updateMedusaReset, updateBatAimbot
local updateCarry, updateLagger, updateAntiRag, updateInfJump, updateAutoTp, updateGalaxy, updateFps

-- Auto Grab
updateAutoGrab = makeToggle("Auto Grab", function() return AutoGrab.ENABLED end, function(v)
    AutoGrab.ENABLED = v
    if v then startAutoSteal() else stopAutoSteal() end
end)

-- Auto Left
updateAutoLeft = makeToggle("Auto Left", function() return autoPlay.enabled and autoPlay.side == "left" end, function(v)
    if v then
        if autoPlay.enabled then stopPatrol() end
        autoPlay.enabled = true
        autoPlay.side = "left"
        startPatrol(leftWaypoints)
        if batAimbot.enabled then stopBatAimbot(); updateBatAimbot() end
    else
        if autoPlay.enabled and autoPlay.side == "left" then
            autoPlay.enabled = false
            stopPatrol()
        end
    end
    updateAutoLeft()
    updateAutoRight()
end)

-- Auto Right
updateAutoRight = makeToggle("Auto Right", function() return autoPlay.enabled and autoPlay.side == "right" end, function(v)
    if v then
        if autoPlay.enabled then stopPatrol() end
        autoPlay.enabled = true
        autoPlay.side = "right"
        startPatrol(rightWaypoints)
        if batAimbot.enabled then stopBatAimbot(); updateBatAimbot() end
    else
        if autoPlay.enabled and autoPlay.side == "right" then
            autoPlay.enabled = false
            stopPatrol()
        end
    end
    updateAutoLeft()
    updateAutoRight()
end)

-- Anti Bat
updateAntiBat = makeToggle("Anti Bat", function() return antiBat.enabled end, function(v)
    antiBat.enabled = v
    if v then startAntiBat() else stopAntiBat() end
end)

-- Medusa Auto Reset
updateMedusaReset = makeToggle("Medusa Auto Reset", function() return medusaReset.enabled end, function(v)
    medusaReset.enabled = v
end)

-- Bat Aimbot
updateBatAimbot = makeToggle("Bat Aimbot", function() return batAimbot.enabled end, function(v)
    if v then
        if autoPlay.enabled then
            autoPlay.enabled = false
            stopPatrol()
            updateAutoLeft()
            updateAutoRight()
        end
        startBatAimbot()
    else
        stopBatAimbot()
    end
end)

-- Carry Mode
updateCarry = makeToggle("Carry Mode", function() return state.speedMode end, function(v)
    if v and state.laggerMode ~= 0 then
        state.laggerMode = 0
        updateLagger()
    end
    state.speedMode = v
    if not v and state.laggerMode == 0 then state.laggerMode = 1; updateLagger() end
end)

-- Lagger Mode
updateLagger = makeToggle("Lagger Mode", function() return state.laggerMode > 0 end, function(v)
    if v then
        if state.speedMode then
            state.speedMode = false
            updateCarry()
        end
        if state.laggerMode == 0 then state.laggerMode = 1
        elseif state.laggerMode == 1 then state.laggerMode = 2
        else state.laggerMode = 0 end
    else
        state.laggerMode = 0
    end
end)

-- Anti Ragdoll
updateAntiRag = makeToggle("Anti Ragdoll", function() return state.antiRagdoll end, function(v)
    state.antiRagdoll = v
    if v then startAntiRag() elseif antiRagConn then antiRagConn:Disconnect(); antiRagConn = nil end
end)

-- Infinite Jump
updateInfJump = makeToggle("Infinite Jump", function() return state.infJump end, function(v)
    state.infJump = v
    if v then
        if infJumpConn then infJumpConn:Disconnect() end
        infJumpConn = startInfJump()
    elseif infJumpConn then
        infJumpConn:Disconnect()
        infJumpConn = nil
    end
end)

-- Auto TP Down
updateAutoTp = makeToggle("Auto TP Down", function() return state.autoTpDown end, function(v)
    state.autoTpDown = v
    if v then startAutoTp() elseif autoTpConn then autoTpConn:Disconnect(); autoTpConn = nil end
end)

-- Galaxy Mode
updateGalaxy = makeToggle("Galaxy Mode", function() return state.galaxyMode end, function(v)
    state.galaxyMode = v
    applyGalaxy()
end)

-- FPS Boost
updateFps = makeToggle("FPS Boost", function() return state.fpsBoost end, function(v)
    state.fpsBoost = v
    if v then boostFPS() end
end)

-- Botones de acción
makeBtn("Insta Reset", Color3.fromRGB(200, 50, 50), instaReset)
makeBtn("Medusa Counter", Color3.fromRGB(50, 50, 200), useMedusa)
makeBtn("Drop Brainrot", Color3.fromRGB(200, 100, 0), dropBrainrot)
makeBtn("TP al Piso", Color3.fromRGB(50, 100, 200), tpToFloor)

-- Información de velocidad
local speedFrame = Instance.new("Frame")
speedFrame.Size = UDim2.new(1, 0, 0, 35)
speedFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
speedFrame.BorderSizePixel = 0
speedFrame.Parent = scroll
Instance.new("UICorner", speedFrame).CornerRadius = UDim.new(0, 8)

local speedInfo = Instance.new("TextLabel")
speedInfo.Size = UDim2.new(1, 0, 1, 0)
speedInfo.BackgroundTransparency = 1
speedInfo.Text = "Velocidad: 60"
speedInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
speedInfo.Font = Enum.Font.GothamBold
speedInfo.TextSize = 12
speedInfo.Parent = speedFrame

local fpsInfo = Instance.new("TextLabel")
fpsInfo.Size = UDim2.new(1, 0, 0, 20)
fpsInfo.Position = UDim2.new(0, 0, 1, -25)
fpsInfo.BackgroundTransparency = 1
fpsInfo.Text = "FPS: 0"
fpsInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
fpsInfo.Font = Enum.Font.Gotham
fpsInfo.TextSize = 10
fpsInfo.Parent = scroll

-- Actualizar UI
local function updateUI()
    updateAutoGrab()
    updateAutoLeft()
    updateAutoRight()
    updateAntiBat()
    updateMedusaReset()
    updateBatAimbot()
    updateCarry()
    updateLagger()
    updateAntiRag()
    updateInfJump()
    updateAutoTp()
    updateGalaxy()
    updateFps()
    
    local speed = getActiveSpeed()
    if autoPlay.enabled then speed = 55 end
    speedInfo.Text = "Velocidad: " .. speed
    fpsInfo.Text = "FPS: " .. fps
end

-- ============================================================
-- INICIALIZACIÓN
-- ============================================================
startMovement()
startAntiRag()
setupMedusa(LP.Character)

-- Character respawn
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    h = char:WaitForChild("Humanoid", 5)
    hrp = char:WaitForChild("HumanoidRootPart", 5)
    setupSpeedBB(char)
    setupMedusa(char)
    
    if antiBat.enabled then
        stopAntiBat()
        task.wait(0.1)
        startAntiBat()
    end
    
    if batAimbot.enabled then
        stopBatAimbot()
        task.wait(0.1)
        startBatAimbot()
    end
    
    if autoPlay.enabled then
        stopPatrol()
        task.wait(0.1)
        if autoPlay.side == "left" then startPatrol(leftWaypoints)
        else startPatrol(rightWaypoints) end
    end
    
    if state.autoTpDown and not autoTpConn then startAutoTp() end
end)

if LP.Character then
    task.wait(0.5)
    h = LP.Character:FindFirstChildOfClass("Humanoid")
    hrp = LP.Character:FindFirstChild("HumanoidRootPart")
    setupSpeedBB(LP.Character)
end

updateUI()

print("✅ NINO HUB cargado correctamente - Todas las funciones activas")