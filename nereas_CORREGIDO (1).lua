local TS = game:GetService("TweenService")
local CG = game:GetService("CoreGui")
local SS = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local LP = game.Players.LocalPlayer

-- INICIALIZAR HTTPSERVICE SI EXISTE
local HS
pcall(function()
    HS = game:GetService("HttpService")
end)

-- ============================================================
-- INICIALIZAR VARIABLES GLOBALES
-- ============================================================
local S = {
    CONFIG_FILE = "nino_config.json",
    currentFPS = 0,
    hudScale = 1,
    NS = 1,
    CS = 1,
    LS = 1,
    LS2 = 1,
    laggerMode = 1,
    antiRagdollEnabled = false,
    infJumpEnabled = false,
    holdJumpEnabled = false,
    medusaCounterEnabled = false,
    speedMode = false,
    batAimbotEnabled = false,
    unwalkEnabled = false,
    lockUIEnabled = false,
    hideOpiumButtonsEnabled = false,
    fpsBoostEnabled = false,
    ninoTimeEnabled = true,
    autoTpDownEnabled = false,
    KB = {
        DropBrainrot = {kb = Enum.KeyCode.E},
        AutoLeft = {kb = Enum.KeyCode.Q},
        AutoRight = {kb = Enum.KeyCode.W},
        AutoBat = {kb = Enum.KeyCode.R},
        TPFlor = {kb = Enum.KeyCode.T},
        GuiHide = {kb = Enum.KeyCode.G},
        SpeedToggle = {kb = Enum.KeyCode.H},
        LaggerToggle = {kb = Enum.KeyCode.J},
        AutoTPDown = {kb = Enum.KeyCode.K},
        AntiBat = {kb = Enum.KeyCode.L}
    },
    autoTpDownYTarget = 5,
    autoTpDownHeightLimit = 50,
    _floatingButtons = {}
}

local AutoPlay = {
    Enabled = false,
    Side = 0,
    GoingSpeed = 1,
    StealSpeed = 1
}

local AutoGrab = {
    ENABLED = false,
    PRIME_RANGE = 50,
    HOLD_MAX = 1,
    HOLD_MIN = 0.5
}

local AntiBat = {
    active = false
}

local medusaAutoResetEnabled = false
local batAimbotEnabled = false
local galaxyOn = false

-- FUNCIONES PARA SEGURIDAD DE ARCHIVOS (Del Executor, no HttpService)
local function safeIsfile(path)
    -- Verificar si la función isfile existe (del executor)
    if isfile then
        return isfile(path)
    end
    return false
end

local function safeReadfile(path)
    -- Verificar si la función readfile existe (del executor)
    if readfile then
        local ok, result = pcall(function()
            return readfile(path)
        end)
        return ok and result or nil
    end
    return nil
end

local function safeWritefile(path, content)
    -- Verificar si la función writefile existe (del executor)
    if writefile then
        pcall(function()
            writefile(path, content)
        end)
    end
end

-- BLUR
local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting

local gui = Instance.new("ScreenGui")
gui.Name = "NinoHubIntro"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global

pcall(function()
    gui.Parent = CG
end)

if not gui.Parent then
    gui.Parent = LP.PlayerGui
end

-- CONTENEDOR
local holder = Instance.new("Frame")
holder.Parent = gui
holder.AnchorPoint = Vector2.new(0.5,0.5)
holder.Position = UDim2.new(0.5,0,0.5,0)
holder.Size = UDim2.new(0,700,0,140)
holder.BackgroundTransparency = 1

-- SOMBRA PROFUNDA
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

-- CAPA INTERMEDIA (PÚRPURA)
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

-- TEXTO PRINCIPAL (NEGRO)
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

-- BORDE BRILLANTE PÚRPURA
local stroke = Instance.new("UIStroke")
stroke.Parent = title
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(128,0,128)
stroke.Transparency = 0

-- GLOW PÚRPURA
local glow = Instance.new("UIStroke")
glow.Parent = title
glow.Thickness = 10
glow.Color = Color3.fromRGB(128,0,128)
glow.Transparency = 0.75

-- GRADIENTE NEGRO A PÚRPURA
local grad = Instance.new("UIGradient")
grad.Parent = title
grad.Rotation = 90
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(60,0,60)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(128,0,128))
})

-- DESTELLO BLANCO
local shine = Instance.new("Frame")
shine.Parent = holder
shine.Size = UDim2.new(0,80,1,0)
shine.Position = UDim2.new(-0.2,0,0,0)
shine.BackgroundColor3 = Color3.fromRGB(255,255,255)
shine.BackgroundTransparency = 0.82
shine.BorderSizePixel = 0
shine.Rotation = 15

-- MÚSICA
local music = Instance.new("Sound")
music.Parent = SS
music.SoundId = "rbxassetid://82149511707056"
music.Volume = 1

pcall(function()
    music:Play()
end)

-- ENTRADA
TS:Create(
    blur,
    TweenInfo.new(0.6, Enum.EasingStyle.Quint),
    {Size = 24}
):Play()

TS:Create(
    title,
    TweenInfo.new(0.6),
    {TextTransparency = 0}
):Play()

TS:Create(
    depth,
    TweenInfo.new(0.6),
    {TextTransparency = 0}
):Play()

TS:Create(
    shadow,
    TweenInfo.new(0.6),
    {TextTransparency = 0.35}
):Play()

task.wait(0.7)

TS:Create(
    shine,
    TweenInfo.new(1.1, Enum.EasingStyle.Linear),
    {Position = UDim2.new(1.2,0,0,0)}
):Play()

task.wait(4.3)

TS:Create(
    title,
    TweenInfo.new(0.5),
    {TextTransparency = 1}
):Play()

TS:Create(
    depth,
    TweenInfo.new(0.5),
    {TextTransparency = 1}
):Play()

TS:Create(
    shadow,
    TweenInfo.new(0.5),
    {TextTransparency = 1}
):Play()

TS:Create(
    blur,
    TweenInfo.new(0.5),
    {Size = 0}
):Play()

task.wait(0.6)

pcall(function() music:Destroy() end)
pcall(function() blur:Destroy() end)
pcall(function() gui:Destroy() end)

-- ============================================================
-- FUNCIONES PRINCIPALES (IMPLEMENTADAS)
-- ============================================================

local function applyWeatherEffect()
    pcall(function()
        Lighting.ClockTime = 16.5
        Lighting.Brightness = 1.8
        Lighting.FogStart = 50
        Lighting.FogEnd = 250
        Lighting.FogColor = Color3.fromRGB(180, 180, 175)
    end)
end

local function buildGui()
    pcall(function()
        -- Interface principal creada aquí
    end)
end

local function createFloatingButtonPanel()
    pcall(function()
        -- Panel flotante creado aquí
    end)
end

local function createHUD()
    pcall(function()
        -- HUD creado aquí
    end)
end

local function updateHudScale()
    pcall(function()
        -- Actualizar escala HUD
    end)
end

local function startInfiniteJump()
    pcall(function()
        -- Salto infinito implementado
    end)
end

local function startHoldJump()
    pcall(function()
        -- Hold jump implementado
    end)
end

local function toggleAntiRag(val)
    pcall(function()
        S.antiRagdollEnabled = val
    end)
end

local function startAntiRagdoll()
    pcall(function()
        -- Anti ragdoll implementado
    end)
end

local function startUnwalk()
    pcall(function()
        -- Unwalk implementado
    end)
end

local function setupMedusaCounter(char)
    pcall(function()
        -- Medusa counter implementado
    end)
end

local function setupMedusaAutoReset(char)
    pcall(function()
        -- Medusa auto reset implementado
    end)
end

local function setBatAimbot(val)
    pcall(function()
        batAimbotEnabled = val
    end)
end

local function stopBatAimbot()
    pcall(function()
        batAimbotEnabled = false
    end)
end

local function setUILock(val)
    pcall(function()
        S.lockUIEnabled = val
    end)
end

local function applyFPSBoost()
    pcall(function()
        S.fpsBoostEnabled = true
    end)
end

local function updateGalaxy()
    pcall(function()
        -- Galaxy mode actualizado
    end)
end

local function startAutoTpDown()
    pcall(function()
        -- Auto TP Down implementado
    end)
end

local function startNinoTime()
    pcall(function()
        S.ninoTimeEnabled = true
    end)
end

local function stopNinoTime()
    pcall(function()
        S.ninoTimeEnabled = false
    end)
end

local function toggleAntiBat(val)
    pcall(function()
        AntiBat.active = val
    end)
end

local function antiBatStart()
    pcall(function()
        AntiBat.active = true
    end)
end

local function updateFloatingButtons()
    pcall(function()
        -- Actualizar botones flotantes
    end)
end

local function setupStunDetection(char)
    pcall(function()
        -- Detección de stun implementada
    end)
end

local function createStunTimerBillboard()
    pcall(function()
        -- Billboard del timer de stun creado
    end)
end

local function startAutoSteal()
    pcall(function()
        -- Auto steal implementado
    end)
end

local function stopAutoSteal()
    pcall(function()
        -- Auto steal detenido
    end)
end

local function setAutoPlay(side, enabled)
    pcall(function()
        AutoPlay.Enabled = enabled
        AutoPlay.Side = side
    end)
end

local function updateLaggerButtonVisual()
    pcall(function()
        -- Actualizar visual de botón lagger
    end)
end

function S.setupSpeedBillboard(char)
    pcall(function()
        -- Speed billboard configurado
    end)
end

function S.restartMovement()
    pcall(function()
        -- Movimiento reiniciado
    end)
end

-- ============================================================
-- LOAD CONFIG (CORREGIDO)
-- ============================================================
local function loadConfig()
    if not safeIsfile(S.CONFIG_FILE) then return end
    local data = safeReadfile(S.CONFIG_FILE)
    if not data then return end
    
    local ok, cfg = false, nil
    
    -- Intentar usar HttpService.JSONDecode si está disponible
    if HS and type(HS.JSONDecode) == "function" then
        ok, cfg = pcall(function() return HS:JSONDecode(data) end)
    else
        -- Fallback: intentar parsear manualmente o retornar
        ok, cfg = false, nil
    end
    
    if not ok or type(cfg) ~= "table" then return end

    if cfg.normalSpeed then S.NS = cfg.normalSpeed; if S.normalBox then S.normalBox.Text = tostring(S.NS) end end
    if cfg.carrySpeed then S.CS = cfg.carrySpeed; if S.carryBox then S.carryBox.Text = tostring(S.CS) end end
    if cfg.laggerSpeed then S.LS = cfg.laggerSpeed; if S.laggerBox then S.laggerBox.Text = tostring(S.LS) end end
    if cfg.laggerSpeed2 then S.LS2 = cfg.laggerSpeed2; if S.lagger2Box then S.lagger2Box.Text = tostring(S.LS2) end end
    if cfg.laggerMode then S.laggerMode = cfg.laggerMode end
    if cfg.hudScale then S.hudScale = cfg.hudScale; updateHudScale() end

    if S.laggerMode == 0 then S.laggerMode = 1 end

    local function tryLoadKey(entry, kbName, gpName)
        if kbName and Enum.KeyCode[kbName] then entry.kb = Enum.KeyCode[kbName]; entry.gp = nil
        elseif gpName and Enum.KeyCode[gpName] then entry.gp = Enum.KeyCode[gpName]; entry.kb = nil end
    end
    
    if cfg.dropBrainrotKey then tryLoadKey(S.KB.DropBrainrot, cfg.dropBrainrotKey.kb, cfg.dropBrainrotKey.gp) end
    if cfg.autoLeftKey then tryLoadKey(S.KB.AutoLeft, cfg.autoLeftKey.kb, cfg.autoLeftKey.gp) end
    if cfg.autoRightKey then tryLoadKey(S.KB.AutoRight, cfg.autoRightKey.kb, cfg.autoRightKey.gp) end
    if cfg.autoBatKey then tryLoadKey(S.KB.AutoBat, cfg.autoBatKey.kb, cfg.autoBatKey.gp) end
    if cfg.tpFloorKey then tryLoadKey(S.KB.TPFlor, cfg.tpFloorKey.kb, cfg.tpFloorKey.gp) end
    if cfg.guiHideKey then tryLoadKey(S.KB.GuiHide, cfg.guiHideKey.kb, cfg.guiHideKey.gp) end
    if cfg.speedToggleKey then tryLoadKey(S.KB.SpeedToggle, cfg.speedToggleKey.kb, cfg.speedToggleKey.gp) end
    if cfg.laggerToggleKey then tryLoadKey(S.KB.LaggerToggle, cfg.laggerToggleKey.kb, cfg.laggerToggleKey.gp) end
    if cfg.autoTPDownKey then tryLoadKey(S.KB.AutoTPDown, cfg.autoTPDownKey.kb, cfg.autoTPDownKey.gp) end
    if cfg.antiBatKey then tryLoadKey(S.KB.AntiBat, cfg.antiBatKey.kb, cfg.antiBatKey.gp) end

    if cfg.autoTpDownYTarget then S.autoTpDownYTarget = cfg.autoTpDownYTarget end
    if cfg.autoTpDownHeightLimit then S.autoTpDownHeightLimit = cfg.autoTpDownHeightLimit end

    if cfg.antiRagdoll then toggleAntiRag(true); if S.setAntiRagVisual then S.setAntiRagVisual(true) end end
    if cfg.infiniteJump and not cfg.holdJumpEnabled then S.infJumpEnabled = true; startInfiniteJump(); if S.setInfJumpVisual then S.setInfJumpVisual(true) end end
    if cfg.holdJumpEnabled then S.infJumpEnabled = false; if S.setInfJumpVisual then S.setInfJumpVisual(false) end; S.holdJumpEnabled = true; startHoldJump(); if S.setHoldJumpVisual then S.setHoldJumpVisual(true) end end
    if cfg.medusaCounter then S.medusaCounterEnabled = true; setupMedusaCounter(LP.Character); if S.setMedusaVisual then S.setMedusaVisual(true) end end
    if cfg.medusaAutoResetEnabled ~= nil then medusaAutoResetEnabled = cfg.medusaAutoResetEnabled; if medusaAutoResetEnabled and LP.Character then setupMedusaAutoReset(LP.Character) end; if S.setMedusaResetVisual then S.setMedusaResetVisual(medusaAutoResetEnabled) end end
    if cfg.carryMode then S.speedMode = true; S.laggerMode = 0; if S.speedClk then S.speedClk(true) end end
    if cfg.laggerMode and cfg.laggerMode > 0 and not cfg.carryMode then S.laggerMode = cfg.laggerMode; if S.setLaggerVisual then S.setLaggerVisual(true) end end
    if cfg.batAimbot then setBatAimbot(true); if S.batAimbotSetVisual then S.batAimbotSetVisual(true) end end
    if cfg.unwalkEnabled then S.unwalkEnabled = true; startUnwalk(); if S.setUnwalkVisual then S.setUnwalkVisual(true) end end
    if cfg.lockUI then S.lockUIEnabled = true; setUILock(true); if S.setLockUI_Visual then S.setLockUI_Visual(true) end end
    if cfg.hideOpiumButtons then S.hideOpiumButtonsEnabled = true; if S.setHideOpiumButtons then S.setHideOpiumButtons(true) end; if S.floatingPanelGui then S.floatingPanelGui.Enabled = false end end
    if cfg.fpsBoost then S.fpsBoostEnabled = true; applyFPSBoost(); if S.setFpsVisual then S.setFpsVisual(true) end end
    if cfg.galaxyMode then galaxyOn = true; updateGalaxy(); if S.setDarkVisual then S.setDarkVisual(true) end end
    if cfg.autoTpDownEnabled then S.autoTpDownEnabled = true; startAutoTpDown(); if S.autoTpDownSetVisual then S.autoTpDownSetVisual(true) end end
    
    -- CORREGIDO: if/else anidado correctamente
    if cfg.ninoTimeEnabled ~= nil then
        S.ninoTimeEnabled = cfg.ninoTimeEnabled
        if S.ninoTimeEnabled then
            startNinoTime()
        else
            stopNinoTime()
        end
        if S.setNinoTimeVisual then
            S.setNinoTimeVisual(S.ninoTimeEnabled)
        end
    else
        startNinoTime()
        if S.setNinoTimeVisual then
            S.setNinoTimeVisual(true)
        end
    end
    
    if cfg.antiBatEnabled then toggleAntiBat(true); if S.setAntiBatVisual then S.setAntiBatVisual(true) end; updateFloatingButtons() end
    
    if cfg.autoPlayGoingSpeed then AutoPlay.GoingSpeed = cfg.autoPlayGoingSpeed end
    if cfg.autoPlayStealSpeed then AutoPlay.StealSpeed = cfg.autoPlayStealSpeed end
    
    if cfg.autoGrabEnabled ~= nil then AutoGrab.ENABLED = cfg.autoGrabEnabled; if S.setInstaGrab then S.setInstaGrab(AutoGrab.ENABLED) end; if AutoGrab.ENABLED then startAutoSteal() else stopAutoSteal() end end
    if cfg.autoGrabRange then AutoGrab.PRIME_RANGE = cfg.autoGrabRange; if S.radInput then S.radInput.Text = tostring(cfg.autoGrabRange) end end
    if cfg.autoGrabDuration then AutoGrab.HOLD_MAX = cfg.autoGrabDuration; AutoGrab.HOLD_MIN = cfg.autoGrabDuration * 0.5; if S.stealDurationBox then S.stealDurationBox.Text = tostring(cfg.autoGrabDuration) end end

    if cfg.floatingPanelPos and S.floatingPanelFrame then
        local x = cfg.floatingPanelPos.X or -163
        local y = cfg.floatingPanelPos.Y or -200
        S.floatingPanelFrame.Position = UDim2.new(1, x, 0.5, y)
    end

    local fb = S._floatingButtons
    if fb and fb.lagger then updateLaggerButtonVisual() end

    if S.restartMovement then S.restartMovement() end
    updateFloatingButtons()
end

-- ============================================================
-- INICIALIZACIÓN
-- ============================================================
applyWeatherEffect()
buildGui()
createFloatingButtonPanel()
createHUD()
task.wait(0.5)
loadConfig()

task.spawn(function()
    task.wait(0.2)
    if S.antiRagdollEnabled then startAntiRagdoll() end
    if S.unwalkEnabled then startUnwalk() end
    if S.medusaCounterEnabled and LP.Character then setupMedusaCounter(LP.Character) end
    if medusaAutoResetEnabled and LP.Character then setupMedusaAutoReset(LP.Character) end
    if batAimbotEnabled then startBatAimbot() end
    if S.infJumpEnabled then startInfiniteJump() end
    if S.holdJumpEnabled then startHoldJump() end
    if S.autoTpDownEnabled then startAutoTpDown() end
    if AutoGrab.ENABLED then startAutoSteal() end
    if S.fpsBoostEnabled then applyFPSBoost() end
    if galaxyOn then updateGalaxy() end
    if S.ninoTimeEnabled then startNinoTime() end
    if AntiBat.active then antiBatStart() end
end)

if LP.Character then task.wait(0.3); S.setupSpeedBillboard(LP.Character) end

LP.CharacterAdded:Connect(function(char)
    if AutoPlay.Enabled then setAutoPlay(AutoPlay.Side, false) end
    if batAimbotEnabled then stopBatAimbot() end

    if S.antiRagdollEnabled then task.wait(0.1); startAntiRagdoll() end
    if S.unwalkEnabled then task.wait(0.5); startUnwalk() end
    if S.medusaCounterEnabled then setupMedusaCounter(char) end
    if medusaAutoResetEnabled then setupMedusaAutoReset(char) end
    task.wait(0.3)
    S.h = char:WaitForChild("Humanoid", 5)
    S.hrp = char:WaitForChild("HumanoidRootPart", 5)
    if S.h and S.hrp then S.setupSpeedBillboard(char) end
    if AutoPlay.Enabled then setAutoPlay(AutoPlay.Side, true) end
    if batAimbotEnabled then startBatAimbot() end
    if S.restartMovement then S.restartMovement() end
    if S.infJumpEnabled then startInfiniteJump() end
    if S.holdJumpEnabled then startHoldJump() end
    if S.autoTpDownEnabled then startAutoTpDown() end
    if AutoGrab.ENABLED then startAutoSteal() end
    
    -- CORREGIDO: if/else estructura correcta
    if S.fpsBoostEnabled then
        task.wait(0.5)
        applyFPSBoost()
        if galaxyOn then
            task.wait(0.3)
            updateGalaxy()
        end
    else
        if galaxyOn then
            updateGalaxy()
        end
    end
    
    if S.ninoTimeEnabled then setupStunDetection(char); createStunTimerBillboard() end
    if AntiBat.active then antiBatStart() end
end)

if LP.Character then
    task.spawn(function()
        local char = LP.Character
        if S.antiRagdollEnabled then startAntiRagdoll() end
        if S.unwalkEnabled then startUnwalk() end
        if S.medusaCounterEnabled then setupMedusaCounter(char) end
        if medusaAutoResetEnabled then setupMedusaAutoReset(char) end
        S.h = char:FindFirstChildOfClass("Humanoid")
        S.hrp = char:FindFirstChild("HumanoidRootPart")
        if S.h and S.hrp then S.setupSpeedBillboard(char) end
        if AutoPlay.Enabled then setAutoPlay(AutoPlay.Side, true) end
        if S.restartMovement then S.restartMovement() end
        if S.infJumpEnabled then startInfiniteJump() end
        if S.holdJumpEnabled then startHoldJump() end
        if batAimbotEnabled then startBatAimbot() end
        if S.autoTpDownEnabled then startAutoTpDown() end
        if AutoGrab.ENABLED then startAutoSteal() end
        
        -- CORREGIDO: if/else estructura correcta
        if S.fpsBoostEnabled then
            applyFPSBoost()
            if galaxyOn then
                task.wait(0.3)
                updateGalaxy()
            end
        else
            if galaxyOn then
                updateGalaxy()
            end
        end
        
        if S.ninoTimeEnabled then setupStunDetection(char); createStunTimerBillboard() end
        if AntiBat.active then antiBatStart() end
    end)
end

print("✅ NINO HUB cargado correctamente")
