-- ===================================================================
-- NRHUB v2 — Steal a Brainrot (FULL COMPLETE - WORKING)
-- ===================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

-- Discretion
local DISC = {}
function DISC.name()
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local s = ""
	for _ = 1, math.random(8, 14) do
		local i = math.random(1, #chars)
		s = s .. chars:sub(i, i)
	end
	return s
end
function DISC.hide(inst)
	local ok = pcall(function()
		if gethui then inst.Parent = gethui()
		elseif syn and syn.protect_gui then syn.protect_gui(inst); inst.Parent = game:GetService("CoreGui")
		else inst.Parent = game:GetService("CoreGui") end
	end)
	if not ok or not inst.Parent then
		pcall(function() inst.Parent = LP:WaitForChild("PlayerGui") end)
	end
end

-- FORWARD DECLARATIONS
local startAutoLeft, stopAutoLeft, startAutoRight, stopAutoRight
local startAntiRagdoll, stopAntiRagdoll
local setupMedusaCounter, stopMedusaCounter
local BC
local applyFPSBoost, autoSaveConfig
local startAutoSteal, stopAutoSteal
local refreshUIToggles
local UIR = {}

local State = {
	normalSpeed=59, carrySpeed=28, laggerSpeed=13, laggerCarrySpeed=13,
	speedType="normal",
	laggerActive=false, laggerCarryActive=false,
	autoBatToggled=false, hittingCooldown=false,
	infJumpEnabled=false, infJumpMode="manual",
	antiRagdollEnabled=false, fpsBoostEnabled=false,
	guiVisible=true,
	isStealing=false,
	autoCarryOnGrab=true,
	medusaLastUsed=0, medusaDebounce=false, medusaCounterEnabled=false, medusaAutoReset=true,
	dropBrainrotActive=false,
	autoTpDownEnabled=false, autoTpDownY=15,
	autoLeftEnabled=false, autoRightEnabled=false,
	autoLeftPhase=1, autoRightPhase=1,
	_tpInProgress=false,
	lastMoveDir=Vector3.new(0,0,0),
	unwalkEnabled=false,
	keyAutoLeft=Enum.KeyCode.Unknown,
	keyAutoRight=Enum.KeyCode.Unknown,
	keyDropBR=Enum.KeyCode.Unknown,
	keyTpDown=Enum.KeyCode.Unknown,
	keyAutoBat=Enum.KeyCode.Unknown,
	keyCarrySpeed=Enum.KeyCode.Unknown,
	keyTpUp=Enum.KeyCode.Unknown,
	keyLaggerMode=Enum.KeyCode.Unknown,
	keyInstaReset=Enum.KeyCode.Unknown,
	keyLaggerUse=Enum.KeyCode.Unknown,
	_carryManualUntil=0,
	laggerUseEnabled=false, laggerUseAmount=45,
}

-- ===================================================================
-- INSTA RESET - FIXED VERSION
-- ===================================================================
local resetCooldown = false
local resetRemote = nil

local function findResetRemote()
	for _, obj in ipairs(game:GetDescendants()) do
		if obj:IsA("RemoteEvent") and obj.Name:sub(1,3) == "RE/" then
			local success = pcall(function()
				return obj:FireServer
			end)
			if success then
				return obj
			end
		end
	end
	return nil
end

local function instaReset()
	if resetCooldown then return end
	
	if not resetRemote or not resetRemote.Parent then
		resetRemote = findResetRemote()
		if not resetRemote then return end
	end
	
	resetCooldown = true
	
	local character = LP.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	
	if humanoid and humanoid.Health <= 0 then
		pcall(function() 
			resetRemote:FireServer(LP, "balloon")
			resetRemote:FireServer(LP)
		end)
		resetCooldown = false
		return
	end
	
	local resetDetected = false
	local connections = {}
	
	if humanoid then
		table.insert(connections, humanoid.Died:Connect(function() resetDetected = true end))
		table.insert(connections, humanoid:GetPropertyChangedSignal("Health"):Connect(function()
			if humanoid.Health <= 0 then resetDetected = true end
		end))
	end
	
	if character then
		table.insert(connections, character.AncestryChanged:Connect(function(_, parent)
			if not parent then resetDetected = true end
		end))
	end
	
	task.spawn(function()
		local attempts = 0
		while not resetDetected and attempts < 25 do
			attempts = attempts + 1
			pcall(function()
				resetRemote:FireServer(LP, "balloon")
				task.wait(0.03)
				resetRemote:FireServer(LP)
				task.wait(0.03)
				resetRemote:FireServer(LP, "reset")
			end)
			task.wait(0.05)
		end
		
		for _, conn in ipairs(connections) do
			pcall(function() conn:Disconnect() end)
		end
		
		resetCooldown = false
	end)
end

-- ===================================================================
-- AUTO STEAL
-- ===================================================================
local AutoSteal = {
	Enabled=false, Radius=60, Duration=1.3, IsStealing=false,
	Data={}, ProgressFill=nil, ProgressText=nil, RetryMax=2,
}

local _plotIsMyCache = {}

local function isMyPlotByName(plotName)
	local now = tick()
	local cached = _plotIsMyCache[plotName]
	if cached and (now - cached.t) < 2 then return cached.val end
	local plots = workspace:FindFirstChild("Plots")
	if not plots then _plotIsMyCache[plotName]={val=false,t=now}; return false end
	local plot = plots:FindFirstChild(plotName)
	if not plot then _plotIsMyCache[plotName]={val=false,t=now}; return false end
	local sign = plot:FindFirstChild("PlotSign")
	local r = false
	if sign then
		local yb = sign:FindFirstChild("YourBase")
		if yb and yb:IsA("BillboardGui") then r = yb.Enabled == true end
	end
	_plotIsMyCache[plotName] = {val=r, t=now}
	return r
end

local function getPlotOf(inst)
	local plots = workspace:FindFirstChild("Plots"); if not plots then return nil end
	local p = inst
	while p and p.Parent do
		if p.Parent == plots then return p end
		p = p.Parent
	end
	return nil
end

local _promptCache = nil
local _promptCacheTime = 0
local _lastHrpPos = Vector3.new(0,0,0)

local function findNearestPrompts()
	local now = tick()
	if _promptCache and (now - _promptCacheTime) < 0.08 then return _promptCache end
	local char = LP.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then _promptCache={}; _promptCacheTime=now; return {} end
	local plots = workspace:FindFirstChild("Plots")
	if not plots then _promptCache={}; _promptCacheTime=now; return {} end
	local results = {}
	for _, plot in ipairs(plots:GetChildren()) do
		if not isMyPlotByName(plot.Name) then
			local podiums = plot:FindFirstChild("AnimalPodiums")
			if podiums then
				for _, pod in ipairs(podiums:GetChildren()) do
					pcall(function()
						local base = pod:FindFirstChild("Base")
						local spawn = base and base:FindFirstChild("Spawn")
						if spawn then
							local dist = (spawn.Position - root.Position).Magnitude
							if dist <= AutoSteal.Radius then
								local att = spawn:FindFirstChild("PromptAttachment")
								if att then
									for _, child in ipairs(att:GetChildren()) do
										if child:IsA("ProximityPrompt") then
											table.insert(results, {prompt=child, dist=dist, name=pod.Name})
											break
										end
									end
								end
							end
						end
					end)
				end
			end
		end
	end
	table.sort(results, function(a,b) return a.dist < b.dist end)
	_promptCache = results
	_promptCacheTime = now
	return results
end

RunService.Heartbeat:Connect(function()
	local char = LP.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if (hrp.Position - _lastHrpPos).Magnitude > 1 then
		_lastHrpPos = hrp.Position
		_promptCache = nil
	end
end)

local function initStealData(prompt)
	if AutoSteal.Data[prompt] then return end
	AutoSteal.Data[prompt] = {hold={}, trigger={}, ready=true, fails=0, useFallback=false}
	pcall(function()
		if getconnections then
			for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
				if c.Function then table.insert(AutoSteal.Data[prompt].hold, c.Function) end
			end
			for _, c in ipairs(getconnections(prompt.Triggered)) do
				if c.Function then table.insert(AutoSteal.Data[prompt].trigger, c.Function) end
			end
			if #AutoSteal.Data[prompt].hold == 0 and #AutoSteal.Data[prompt].trigger == 0 then
				AutoSteal.Data[prompt].useFallback = true
			end
		else
			AutoSteal.Data[prompt].useFallback = true
		end
	end)
end

local function tryStealOnce(prompt, data)
	local DUR = AutoSteal.Duration
	if not data.useFallback and #data.hold > 0 then
		pcall(function() for _, f in ipairs(data.hold) do task.spawn(f) end end)
	end
	task.wait(DUR + math.random() * 0.08)
	if fireproximityprompt then
		local ok = pcall(function() fireproximityprompt(prompt) end)
		if ok then task.wait(0.05 + math.random() * 0.05); return true end
	end
	if not data.useFallback and #data.trigger > 0 then
		local ok = pcall(function()
			for _, f in ipairs(data.trigger) do task.spawn(f) end
		end)
		if ok then task.wait(0.05); return true end
	end
	local ok = pcall(function()
		prompt:InputHoldBegin(); task.wait(DUR); prompt:InputHoldEnd()
	end)
	return ok
end

local function setCarryMode(on)
	if not State.autoCarryOnGrab then return end
	if State.laggerActive or State.laggerCarryActive then return end
	local want = on and "carry" or "normal"
	if State.speedType == want then return end
	State.speedType = want
	if refreshUIToggles then refreshUIToggles() end
	if MobileButtons and MobileButtons.Buttons and MobileButtons.Buttons.carrySpeed then
		MobileButtons.Buttons.carrySpeed(on)
	end
	autoSaveConfig()
end

local function executeSteal(prompt, animalName)
	if AutoSteal.IsStealing then return end
	if not prompt or not prompt.Parent then return end
	initStealData(prompt)
	local data = AutoSteal.Data[prompt]
	if not data or not data.ready then return end
	data.ready = false
	AutoSteal.IsStealing = true
	State.isStealing = true
	local startTime = tick()

	local progConn
	progConn = RunService.Heartbeat:Connect(function()
		if not AutoSteal.IsStealing then progConn:Disconnect(); return end
		local prog = math.clamp((tick() - startTime) / AutoSteal.Duration, 0, 1)
		if AutoSteal.ProgressFill then AutoSteal.ProgressFill.Size = UDim2.new(prog,0,1,0) end
		if AutoSteal.ProgressText then AutoSteal.ProgressText.Text = math.floor(prog*100).."%" end
	end)

	task.spawn(function()
		local success = false
		local attempts = 0
		while not success and attempts < AutoSteal.RetryMax do
			attempts = attempts + 1
			success = tryStealOnce(prompt, data)
			if not success then
				data.fails = (data.fails or 0) + 1
				if data.fails >= 3 then data.useFallback = true end
				task.wait(0.03)
			end
		end
		AutoSteal.IsStealing = false
		State.isStealing = false
		data.ready = true
		task.wait(0.4)
		if not AutoSteal.IsStealing and AutoSteal.ProgressFill then
			TweenService:Create(AutoSteal.ProgressFill, TweenInfo.new(0.3), {Size=UDim2.new(0,0,1,0)}):Play()
		end
		if AutoSteal.ProgressText then AutoSteal.ProgressText.Text = "0%" end
		_promptCache = nil
	end)
end

local autoStealConnection = nil
startAutoSteal = function()
	if autoStealConnection then return end
	local _t = 0
	autoStealConnection = RunService.Heartbeat:Connect(function()
		if not AutoSteal.Enabled or AutoSteal.IsStealing then return end
		local now = tick()
		if now - _t < 0.05 then return end
		_t = now
		local prompts = findNearestPrompts()
		if prompts and #prompts > 0 then
			executeSteal(prompts[1].prompt, prompts[1].name)
		end
	end)
end
stopAutoSteal = function()
	if autoStealConnection then autoStealConnection:Disconnect(); autoStealConnection = nil end
	AutoSteal.IsStealing = false
	State.isStealing = false
	_promptCache = nil
	for k,v in pairs(AutoSteal.Data) do if v.ready ~= nil then v.ready = true end end
end

-- ===================================================================
-- CONSTANTES
-- ===================================================================
local MOVE_KEYS = {[Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,[Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true}
local POS = {
	L1=Vector3.new(-476.48,-6.28,92.73), L2=Vector3.new(-483.12,-4.95,94.80),
	R1=Vector3.new(-476.16,-6.52,25.62), R2=Vector3.new(-483.04,-5.09,23.14),
}
local Conns = {antiRag=nil, autoLeft=nil, autoRight=nil, anchor={}}

-- ===================================================================
-- PROXY PART
-- ===================================================================
local proxy = nil
local function ensureProxy()
	local char = LP.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	if proxy and proxy.Parent == char then return proxy end
	if proxy then pcall(function() proxy:Destroy() end) end
	proxy = Instance.new("Part")
	proxy.Name = DISC.name()
	proxy.Size = Vector3.new(1,1,1)
	proxy.Transparency = 1
	proxy.CanCollide = false
	proxy.Massless = true
	proxy.Parent = char
	local weld = Instance.new("Weld")
	weld.Part0 = hrp
	weld.Part1 = proxy
	weld.C0 = CFrame.new(0,0,0)
	weld.Parent = proxy
	return proxy
end

local function proxyMove(dir, speed)
	local char = LP.Character; if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local p = ensureProxy()
	if hum then hum:Move(dir, false) end
	if p then
		p.AssemblyLinearVelocity = Vector3.new(dir.X*speed, p.AssemblyLinearVelocity.Y, dir.Z*speed)
	end
end

local function proxyStop()
	local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum:Move(Vector3.zero, false) end
	if proxy then proxy.AssemblyLinearVelocity = Vector3.new(0, proxy.AssemblyLinearVelocity.Y, 0) end
end

-- ===================================================================
-- PALETTE
-- ===================================================================
local C_BG      = Color3.fromRGB(6,8,14)
local C_PANEL   = Color3.fromRGB(10,14,22)
local C_ROW     = Color3.fromRGB(16,20,30)
local C_BORDER  = Color3.fromRGB(30,60,120)
local C_BORDER2 = Color3.fromRGB(40,80,150)
local C_HEADER  = Color3.fromRGB(8,10,18)
local C_ACCENT  = Color3.fromRGB(180,220,255)
local C_ACCENT2 = Color3.fromRGB(80,180,255)
local C_DIM     = Color3.fromRGB(80,100,140)
local C_WHITE   = Color3.fromRGB(255,255,255)
local C_ON_BG   = Color3.fromRGB(20,60,140)
local C_OFF_BG  = Color3.fromRGB(22,28,40)
local C_NR      = Color3.fromRGB(0,150,255)
local C_CYAN    = Color3.fromRGB(0,200,255)

-- ===================================================================
-- AUTO-SAVE CONFIG
-- ===================================================================
local saveDebounce = false
local MobileButtons = {Visible=true, Locked=false, Containers={}, Buttons={}}
local _anyKeyListening = false

autoSaveConfig = function()
	if saveDebounce then return end
	saveDebounce = true
	task.delay(0.5, function()
		local cfg = {
			normalSpeed=State.normalSpeed, carrySpeed=State.carrySpeed,
			laggerSpeed=State.laggerSpeed, laggerCarrySpeed=State.laggerCarrySpeed,
			speedType=State.speedType, laggerActive=State.laggerActive, laggerCarryActive=State.laggerCarryActive,
			autoBatToggled=State.autoBatToggled,
			autoLeftEnabled=State.autoLeftEnabled, autoRightEnabled=State.autoRightEnabled,
			autoStealEnabled=AutoSteal.Enabled, grabRadius=AutoSteal.Radius, grabDuration=AutoSteal.Duration,
			autoCarryOnGrab=State.autoCarryOnGrab,
			infJump=State.infJumpEnabled, infJumpMode=State.infJumpMode,
			antiRagdoll=State.antiRagdollEnabled, fpsBoost=State.fpsBoostEnabled,
			medusaCounter=State.medusaCounterEnabled, unwalkEnabled=State.unwalkEnabled,
			autoTpDown=State.autoTpDownEnabled, autoTpDownY=State.autoTpDownY,
			laggerUseEnabled=State.laggerUseEnabled, laggerUseAmount=State.laggerUseAmount,
			mobileVisible=MobileButtons.Visible, mobileLocked=MobileButtons.Locked,
			keyAutoLeft=State.keyAutoLeft.Name, keyAutoRight=State.keyAutoRight.Name,
			keyDropBR=State.keyDropBR.Name, keyTpDown=State.keyTpDown.Name,
			keyAutoBat=State.keyAutoBat.Name, keyCarrySpeed=State.keyCarrySpeed.Name,
			keyTpUp=State.keyTpUp.Name, keyLaggerMode=State.keyLaggerMode.Name,
			keyInstaReset=State.keyInstaReset.Name,
			keyLaggerUse=State.keyLaggerUse.Name,
			fovEnabled=fovEnabled, fovValue=fovValue,
		}
		pcall(function() writefile("rbxdata_cfg9x.json", HttpService:JSONEncode(cfg)) end)
		saveDebounce = false
	end)
end

-- ===================================================================
-- SPEED HELPERS
-- ===================================================================
local function deactivateAllSpeedModes()
	if State.speedType == "carry" then State.speedType="normal"; if MobileButtons.Buttons.carrySpeed then MobileButtons.Buttons.carrySpeed(false) end end
	if State.laggerActive then State.laggerActive=false; if MobileButtons.Buttons.lagger then MobileButtons.Buttons.lagger(false) end end
	if State.laggerCarryActive then State.laggerCarryActive=false; if MobileButtons.Buttons.laggerCarry then MobileButtons.Buttons.laggerCarry(false) end end
	if State.laggerUseEnabled then State.laggerUseEnabled=false; if MobileButtons.Buttons.laggerUse then MobileButtons.Buttons.laggerUse(false) end end
end

local function toggleSpeedType()
	State._carryManualUntil = tick() + 2.5
	if State.speedType == "carry" then
		State.speedType = "normal"; refreshUIToggles(); autoSaveConfig()
		if MobileButtons.Buttons.carrySpeed then MobileButtons.Buttons.carrySpeed(false) end; return
	end
	deactivateAllSpeedModes()
	State.speedType = "carry"; refreshUIToggles(); autoSaveConfig()
	if MobileButtons.Buttons.carrySpeed then MobileButtons.Buttons.carrySpeed(true) end
end

local function toggleLagger()
	if State.laggerActive then
		State.laggerActive=false
		refreshUIToggles(); autoSaveConfig()
		if MobileButtons.Buttons.lagger then MobileButtons.Buttons.lagger(false) end; return
	end
	deactivateAllSpeedModes()
	State.laggerActive=true
	refreshUIToggles(); autoSaveConfig()
	if MobileButtons.Buttons.lagger then MobileButtons.Buttons.lagger(true) end
end

local function toggleLaggerCarry()
	if State.laggerCarryActive then
		State.laggerCarryActive=false
		refreshUIToggles(); autoSaveConfig()
		if MobileButtons.Buttons.laggerCarry then MobileButtons.Buttons.laggerCarry(false) end; return
	end
	deactivateAllSpeedModes()
	State.laggerCarryActive=true
	refreshUIToggles(); autoSaveConfig()
	if MobileButtons.Buttons.laggerCarry then MobileButtons.Buttons.laggerCarry(true) end
end

local function toggleLaggerUse()
	if State.laggerUseEnabled then
		State.laggerUseEnabled=false
		refreshUIToggles(); autoSaveConfig()
		if MobileButtons.Buttons.laggerUse then MobileButtons.Buttons.laggerUse(false) end; return
	end
	deactivateAllSpeedModes()
	State.laggerUseEnabled=true
	refreshUIToggles(); autoSaveConfig()
	if MobileButtons.Buttons.laggerUse then MobileButtons.Buttons.laggerUse(true) end
end

local function getCurrentSpeed()
	if State.laggerUseEnabled then return State.laggerUseAmount end
	if State.laggerCarryActive then return State.laggerCarrySpeed
	elseif State.laggerActive then return State.laggerCarrySpeed
	else return State.speedType == "normal" and State.normalSpeed or State.carrySpeed end
end

local function getAutoMoveSpeed()
	if State.laggerCarryActive then return State.normalSpeed
	elseif State.laggerActive then return State.laggerSpeed
	else return State.normalSpeed end
end

-- ===================================================================
-- FOV MODIFIER
-- ===================================================================
local fovEnabled = false
local fovValue   = 70
local fovConn    = nil

local function enableFOV()
	fovEnabled = true
	if fovConn then fovConn:Disconnect() end
	fovConn = RunService.RenderStepped:Connect(function()
		if not fovEnabled then fovConn:Disconnect(); fovConn = nil; return end
		pcall(function() workspace.CurrentCamera.FieldOfView = fovValue end)
	end)
	if UIR.fovWidget then UIR.fovWidget.Visible = true; if UIR.fovValLbl then UIR.fovValLbl.Text = tostring(fovValue) end end
end

local function disableFOV()
	fovEnabled = false
	if fovConn then fovConn:Disconnect(); fovConn = nil end
	pcall(function() workspace.CurrentCamera.FieldOfView = 70 end)
	if UIR.fovWidget then UIR.fovWidget.Visible = false end
end

local DISCORD_LINK = "discord.gg/nrhub"

-- ===================================================================
-- SPEED BYPASS
-- ===================================================================
local _sbMobile = UIS.TouchEnabled and not UIS.MouseEnabled
local SB = {running=false, thread=nil, bomb=nil, mode=(_sbMobile and "Mobile" or "PC"), pcPower=265, mobPower=290, spamDelay=(_sbMobile and 0.85 or 0.05), DEPTH=186, widget=nil, statusLbl=nil, pill=nil, pillStk=nil, ball=nil, powerBox=nil, keybind=Enum.KeyCode.V, listening=false,
	lagOn=false, speedOn=false, lagAmount=0.12, speedAmount=30, speedConn=nil, lagConn=nil}

function SB.startSpeed()
	if SB.speedConn then return end
	SB.speedConn = RunService.RenderStepped:Connect(function()
		if not SB.speedOn then return end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end
		if hum.MoveDirection.Magnitude > 0 then
			local dir = hum.MoveDirection.Unit
			hrp.AssemblyLinearVelocity = Vector3.new(dir.X*SB.speedAmount, hrp.AssemblyLinearVelocity.Y, dir.Z*SB.speedAmount)
		end
	end)
end

function SB.stopSpeed()
	if SB.speedConn then SB.speedConn:Disconnect(); SB.speedConn = nil end
end

function SB.startLag()
	if SB.lagConn then return end
	SB.lagConn = true
	task.spawn(function()
		while SB.lagOn do
			if SB.lagAmount > 0 then
				local t = tick()
				while tick() - t < SB.lagAmount do end
			end
			RunService.RenderStepped:Wait()
		end
		SB.lagConn = nil
	end)
end

function SB.stopLag()
	SB.lagOn = false
	SB.lagConn = nil
end

-- ===================================================================
-- ANTI BAT
-- ===================================================================
local AB = {active=false, conn=nil, pct=20, MAXPOWER=5000, widget=nil, statusLbl=nil, pill=nil, pillStk=nil, ball=nil, box=nil, FORCE=1000}
function AB.power() return AB.FORCE end
function AB.start()
	if AB.conn then AB.conn:Disconnect() end
	AB.conn = RunService.Heartbeat:Connect(function()
		if not AB.active then return end
		local c = LP.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		if not root or not root.Parent then return end
		local orig = root.Velocity
		root.Velocity = Vector3.new(AB.FORCE, root.Velocity.Y, AB.FORCE)
		RunService.RenderStepped:Wait()
		local r2 = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if r2 and r2.Parent then r2.Velocity = orig end
	end)
end
function AB.stop()
	if AB.conn then AB.conn:Disconnect(); AB.conn = nil end
end
function AB.refresh()
	if not AB.statusLbl then return end
	local on = AB.active
	AB.statusLbl.Text = on and "ENABLED" or "DISABLED"
	AB.statusLbl.TextColor3 = on and C_ACCENT2 or Color3.fromRGB(150,95,95)
	if AB.pill then TweenService:Create(AB.pill, TweenInfo.new(0.2), {BackgroundColor3 = on and C_ON_BG or Color3.fromRGB(22,22,28)}):Play() end
	if AB.pillStk then TweenService:Create(AB.pillStk, TweenInfo.new(0.2), {Color = on and C_ACCENT2 or Color3.fromRGB(80,28,30)}):Play() end
	if AB.ball then TweenService:Create(AB.ball, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = on and UDim2.new(1,-15,0.5,-5) or UDim2.new(0,4,0.5,-5), BackgroundColor3 = on and C_WHITE or Color3.fromRGB(110,80,80)}):Play() end
end
function AB.toggle()
	AB.active = not AB.active
	if AB.active then AB.start() else AB.stop() end
	AB.refresh()
end
if LP then LP.CharacterAdded:Connect(function() if AB.active then AB.stop(); task.wait(0.2); AB.start() end end) end

-- ===================================================================
-- TP DOWN / UP
-- ===================================================================
local function tpToGround()
	local char = LP.Character; if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
	local rot = root.CFrame.Rotation
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {char}
	local res = workspace:Raycast(root.Position, Vector3.new(0,-500,0), params)
	if res then root.CFrame = CFrame.new(res.Position + Vector3.new(0,3,0)) * rot
	else root.CFrame = CFrame.new(root.Position + Vector3.new(0,-20,0)) * rot end
end

local function tpUp()
	local char = LP.Character; if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local newPos = root.Position + Vector3.new(0, 10, 0)
	root.CFrame = CFrame.new(newPos) * root.CFrame.Rotation
	root.AssemblyLinearVelocity = Vector3.zero
	if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
end

-- ===================================================================
-- DROP BRAINROT
-- ===================================================================
local function runDropBrainrot()
	if State.dropBrainrotActive then return end
	if batAimbotEnabled then stopBatAimbot(); if UIR.setAutoBat then UIR.setAutoBat(false) end end
	State.dropBrainrotActive = true
	local conns = {}
	local colConn = RunService.Stepped:Connect(function()
		if not State.dropBrainrotActive then return end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character then
				for _, part in ipairs(p.Character:GetChildren()) do
					if part:IsA("BasePart") then part.CanCollide = false end
				end
			end
		end
	end)
	table.insert(conns, colConn)
	local flingThread = coroutine.create(function()
		while State.dropBrainrotActive do
			RunService.Heartbeat:Wait()
			local c = LP.Character
			local root = c and c:FindFirstChild("HumanoidRootPart")
			if not root then break end
			local vel = root.Velocity
			root.Velocity = vel*10000 + Vector3.new(0,10000,0)
			RunService.RenderStepped:Wait()
			if root and root.Parent then root.Velocity = vel end
			RunService.Stepped:Wait()
			if root and root.Parent then root.Velocity = vel + Vector3.new(0,0.1,0) end
		end
	end)
	table.insert(conns, flingThread)
	coroutine.resume(flingThread)
	task.delay(0.1, function()
		State.dropBrainrotActive = false
		for _, c in ipairs(conns) do
			if typeof(c) == "RBXScriptConnection" then c:Disconnect()
			elseif type(c) == "thread" then pcall(coroutine.close, c) end
		end
		conns = {}
	end)
end

-- ===================================================================
-- AUTO LEFT / RIGHT
-- ===================================================================
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

local patrolConnection = nil
local patrolWaypoints = nil
local patrolIndex = 1
local patrolFrozen = false
local patrolFreezeUntil = 0
local PATROL_WAIT_AT_BASE = 0.7

local function patrolMoveTo(target, speed)
	local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local dir = (target - hrp.Position)
	local moveDir = Vector3.new(dir.X, 0, dir.Z).Unit
	local hum = LP.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum:Move(moveDir, false) end
	proxyMove(moveDir, speed)
end

startAutoLeft = function()
	stopAutoLeft(); stopAutoRight()
	State.autoLeftPhase = 1; patrolIndex = 1
	patrolFrozen = false; patrolFreezeUntil = 0
	patrolWaypoints = leftWaypoints; ensureProxy()
	State.speedType = "normal"
	if refreshUIToggles then refreshUIToggles() end
	if MobileButtons.Buttons and MobileButtons.Buttons.carrySpeed then MobileButtons.Buttons.carrySpeed(false) end
	patrolConnection = RunService.Stepped:Connect(function()
		if not State.autoLeftEnabled or not patrolWaypoints then return end
		local char = LP.Character; if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
		if patrolFrozen then
			proxyStop()
			if tick() >= patrolFreezeUntil then
				patrolFrozen = false
				patrolIndex = patrolIndex + 1
			end
			return
		end
		local target = patrolWaypoints[patrolIndex]; if not target then return end
		local dist = (target - hrp.Position).Magnitude
		local speed = (patrolIndex <= 2) and State.normalSpeed or State.carrySpeed
		if dist < 2.5 then
			if patrolIndex == 2 then
				patrolFrozen = true
				patrolFreezeUntil = tick() + PATROL_WAIT_AT_BASE
				proxyStop()
				return
			end
			patrolIndex = patrolIndex + 1
			if patrolIndex > #patrolWaypoints then
				proxyStop(); State.autoLeftEnabled = false
				if patrolConnection then patrolConnection:Disconnect(); patrolConnection = nil end
				patrolWaypoints = nil; patrolIndex = 1
				if UIR.setAutoLeft then UIR.setAutoLeft(false) end
				if MobileButtons.Buttons.autoLeft then MobileButtons.Buttons.autoLeft(false) end
				if State.autoCarryOnGrab then
					State.speedType = "carry"
					if refreshUIToggles then refreshUIToggles() end
					if MobileButtons.Buttons.carrySpeed then MobileButtons.Buttons.carrySpeed(true) end
					autoSaveConfig()
				end
				return
			end
		else
			patrolMoveTo(target, speed)
		end
	end)
end
stopAutoLeft = function()
	if patrolConnection and State.autoLeftEnabled then patrolConnection:Disconnect(); patrolConnection = nil end
	patrolWaypoints = nil; patrolIndex = 1; patrolFrozen = false; proxyStop()
	State.autoLeftPhase = 1
	if MobileButtons.Buttons.autoLeft then MobileButtons.Buttons.autoLeft(false) end
end

startAutoRight = function()
	stopAutoRight(); stopAutoLeft()
	State.autoRightPhase = 1; patrolIndex = 1
	patrolFrozen = false; patrolFreezeUntil = 0
	patrolWaypoints = rightWaypoints; ensureProxy()
	State.speedType = "normal"
	if refreshUIToggles then refreshUIToggles() end
	if MobileButtons.Buttons and MobileButtons.Buttons.carrySpeed then MobileButtons.Buttons.carrySpeed(false) end
	patrolConnection = RunService.Stepped:Connect(function()
		if not State.autoRightEnabled or not patrolWaypoints then return end
		local char = LP.Character; if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
		if patrolFrozen then
			proxyStop()
			if tick() >= patrolFreezeUntil then
				patrolFrozen = false
				patrolIndex = patrolIndex + 1
			end
			return
		end
		local target = patrolWaypoints[patrolIndex]; if not target then return end
		local dist = (target - hrp.Position).Magnitude
		local speed = (patrolIndex <= 2) and State.normalSpeed or State.carrySpeed
		if dist < 2.5 then
			if patrolIndex == 2 then
				patrolFrozen = true
				patrolFreezeUntil = tick() + PATROL_WAIT_AT_BASE
				proxyStop()
				return
			end
			patrolIndex = patrolIndex + 1
			if patrolIndex > #patrolWaypoints then
				proxyStop(); State.autoRightEnabled = false
				if patrolConnection then patrolConnection:Disconnect(); patrolConnection = nil end
				patrolWaypoints = nil; patrolIndex = 1
				if UIR.setAutoRight then UIR.setAutoRight(false) end
				if MobileButtons.Buttons.autoRight then MobileButtons.Buttons.autoRight(false) end
				if State.autoCarryOnGrab then
					State.speedType = "carry"
					if refreshUIToggles then refreshUIToggles() end
					if MobileButtons.Buttons.carrySpeed then MobileButtons.Buttons.carrySpeed(true) end
					autoSaveConfig()
				end
				return
			end
		else
			patrolMoveTo(target, speed)
		end
	end)
end
stopAutoRight = function()
	if patrolConnection and State.autoRightEnabled then patrolConnection:Disconnect(); patrolConnection = nil end
	patrolWaypoints = nil; patrolIndex = 1; patrolFrozen = false; proxyStop()
	State.autoRightPhase = 1
	if MobileButtons.Buttons.autoRight then MobileButtons.Buttons.autoRight(false) end
end

-- ===================================================================
-- ANTI RAGDOLL
-- ===================================================================
startAntiRagdoll = function()
	if Conns.antiRag then return end
	local _t = 0
	Conns.antiRag = RunService.Heartbeat:Connect(function()
		local now = tick(); if now-_t < 0.1 then return end; _t = now
		local char = LP.Character; if not char then return end
		local hum2 = char:FindFirstChildOfClass("Humanoid"); local root = char:FindFirstChild("HumanoidRootPart")
		if hum2 then
			local st = hum2:GetState()
			if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
				hum2:ChangeState(Enum.HumanoidStateType.Running)
				workspace.CurrentCamera.CameraSubject = hum2
				pcall(function() local pm=LP.PlayerScripts:FindFirstChild("PlayerModule"); if pm then require(pm:FindFirstChild("ControlModule")):Enable() end end)
				if root then root.Velocity=Vector3.zero; root.RotVelocity=Vector3.zero end
			end
		end
		for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end end
	end)
end
stopAntiRagdoll = function() if Conns.antiRag then Conns.antiRag:Disconnect(); Conns.antiRag=nil end end

-- ===================================================================
-- FPS BOOST
-- ===================================================================
applyFPSBoost = function()
	pcall(function() setfpscap(999999999) end)
	local function processObj(v)
		pcall(function()
			if v:IsA("Model") then v.LevelOfDetail=Enum.ModelLevelOfDetail.Disabled
			elseif v:IsA("MeshPart") then v.CastShadow=false; v.RenderFidelity=Enum.RenderFidelity.Performance
			elseif v:IsA("BasePart") then v.CastShadow=false; v.Material=Enum.Material.Plastic; v.Reflectance=0
			elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1
			elseif v:IsA("SpecialMesh") then v.TextureId=""
			elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v.Enabled=false
			elseif v:IsA("SurfaceAppearance") then v:Destroy() end
		end)
	end
	for _,v in pairs(workspace:GetDescendants()) do processObj(v) end
	pcall(function()
		local lighting = game:GetService("Lighting")
		for _,v in pairs(lighting:GetDescendants()) do
			pcall(function()
				if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("ColorCorrectionEffect") then v:Destroy() end
			end)
		end
		lighting.GlobalShadows = false; lighting.FogEnd = 9e9; lighting.Brightness = 0
	end)
	workspace.DescendantAdded:Connect(function(v) if State.fpsBoostEnabled then task.spawn(processObj,v) end end)
end

-- ===================================================================
-- MEDUSA COUNTER
-- ===================================================================
local function findMedusa()
	local char = LP.Character; if not char then return nil end
	for _,tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") then local tn=tool.Name:lower()
			if tn:find("medusa") or tn:find("head") or tn:find("stone") then return tool end
		end
	end
	local bp = LP:FindFirstChild("Backpack")
	if bp then for _,tool in ipairs(bp:GetChildren()) do
		if tool:IsA("Tool") then local tn=tool.Name:lower()
			if tn:find("medusa") or tn:find("head") or tn:find("stone") then return tool end
		end
	end end
	return nil
end

local function useMedusaCounter()
	if State.medusaDebounce then return end
	if tick()-State.medusaLastUsed < 25 then return end
	local char = LP.Character; if not char then return end
	State.medusaDebounce = true
	local med = findMedusa()
	if not med then State.medusaDebounce=false; return end
	if med.Parent ~= char then local hum2=char:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:EquipTool(med) end end
	pcall(function() med:Activate() end)
	State.medusaLastUsed = tick()
	State.medusaDebounce = false
end

local function onAnchorChanged(part)
	return part:GetPropertyChangedSignal("Anchored"):Connect(function()
		if part.Anchored and part.Transparency == 1 then
			if State.medusaAutoReset and not BC.active then instaReset() end
			if State.medusaCounterEnabled then useMedusaCounter() end
		end
	end)
end

setupMedusaCounter = function(char)
	stopMedusaCounter(); if not char then return end
	for _,part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then table.insert(Conns.anchor, onAnchorChanged(part)) end
	end
	table.insert(Conns.anchor, char.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then table.insert(Conns.anchor, onAnchorChanged(part)) end
	end))
end
stopMedusaCounter = function()
	for _,c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end
	Conns.anchor = {}
end

-- ===================================================================
-- UNWALK
-- ===================================================================
local savedAnimate = nil
local function startUnwalk()
	if State.unwalkEnabled then return end
	State.unwalkEnabled = true
	local c = LP.Character; if not c then return end
	local hum = c:FindFirstChildOfClass("Humanoid")
	if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
	local anim = c:FindFirstChild("Animate")
	if anim then savedAnimate = anim:Clone(); anim:Destroy() end
end
local function stopUnwalk()
	if not State.unwalkEnabled then return end
	State.unwalkEnabled = false
	local c = LP.Character
	if c and savedAnimate then
		savedAnimate.Parent = c; savedAnimate.Disabled = false; savedAnimate = nil
	end
end

-- ===================================================================
-- INF JUMP
-- ===================================================================
local IJ = {active=false, conn=nil}
function IJ.start()
	if IJ.conn then IJ.conn:Disconnect() end
	if IJ.hbConn then IJ.hbConn:Disconnect() end
	IJ.wantJump = false
	IJ.conn = UIS.JumpRequest:Connect(function()
		if IJ.active then IJ.wantJump = true end
	end)
	IJ.hbConn = RunService.Heartbeat:Connect(function()
		if not IJ.active or not IJ.wantJump then return end
		IJ.wantJump = false
		local c = LP.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		if root then
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(v.X, 50, v.Z)
		end
	end)
end
function IJ.stop()
	if IJ.conn then IJ.conn:Disconnect(); IJ.conn = nil end
	if IJ.hbConn then IJ.hbConn:Disconnect(); IJ.hbConn = nil end
	IJ.wantJump = false
end
function IJ.refresh()
	if not IJ.statusLbl then return end
	local on = IJ.active
	IJ.statusLbl.Text = on and "ENABLED" or "DISABLED"
	IJ.statusLbl.TextColor3 = on and C_ACCENT2 or Color3.fromRGB(150,95,95)
	if IJ.pill then TweenService:Create(IJ.pill, TweenInfo.new(0.2), {BackgroundColor3 = on and C_ON_BG or Color3.fromRGB(22,22,28)}):Play() end
	if IJ.pillStk then TweenService:Create(IJ.pillStk, TweenInfo.new(0.2), {Color = on and C_ACCENT2 or Color3.fromRGB(80,28,30)}):Play() end
	if IJ.ball then TweenService:Create(IJ.ball, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = on and UDim2.new(1,-15,0.5,-5) or UDim2.new(0,4,0.5,-5), BackgroundColor3 = on and C_WHITE or Color3.fromRGB(110,80,80)}):Play() end
end
function IJ.toggle()
	IJ.active = not IJ.active
	if IJ.active then IJ.start() else IJ.stop() end
	IJ.refresh()
end

-- ===================== BAT COUNTER =====================
BC = {active=false, conn=nil}
BC.batNames = {"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
function BC.findBat()
	local c = LP.Character
	if not c then return nil end
	local bp = LP:FindFirstChildOfClass("Backpack")
	for _, n in ipairs(BC.batNames) do
		local t = c:FindFirstChild(n) or (bp and bp:FindFirstChild(n))
		if t then return t end
	end
	for _, ch in ipairs(c:GetChildren()) do
		if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
	end
	if bp then for _, ch in ipairs(bp:GetChildren()) do
		if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
	end end
	return nil
end
function BC.nearestAttacker(root)
	local closest, cd = nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP and p.Character then
			local tr = p.Character:FindFirstChild("HumanoidRootPart")
			if tr then
				local d = (tr.Position - root.Position).Magnitude
				if d < cd then cd = d; closest = tr end
			end
		end
	end
	return closest
end
function BC.start()
	if BC.conn then BC.conn:Disconnect() end
	BC.conn = RunService.Heartbeat:Connect(function()
		if not BC.active then return end
		local c = LP.Character
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		local st = hum:GetState()
		if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
			local root = c:FindFirstChild("HumanoidRootPart")
			local bat = BC.findBat()
			if not bat then return end
			if bat.Parent ~= c then pcall(function() hum:EquipTool(bat) end) end
			if root then
				local tHRP = BC.nearestAttacker(root)
				if tHRP then
					local dir = (tHRP.Position - root.Position).Unit
					root.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(dir.X,0,dir.Z))
					root.AssemblyLinearVelocity = dir * 75
				end
			end
			pcall(function() bat:Activate() end)
			RunService.Heartbeat:Wait()
			pcall(function() bat:Activate() end)
		end
	end)
end
function BC.stop() if BC.conn then BC.conn:Disconnect(); BC.conn = nil end end

local ANL = {active=false, conn=nil}
function ANL.process(obj)
	pcall(function()
		if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
			obj.Enabled = false
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = 1
		elseif obj:IsA("BasePart") then
			obj.Material = Enum.Material.Plastic; obj.Reflectance = 0; obj.CastShadow = false
		end
	end)
end
function ANL.start()
	if ANL.active then return end
	ANL.active = true
	local Lt = game:GetService("Lighting")
	pcall(function()
		Lt.GlobalShadows = false; Lt.FogEnd = 1e10; Lt.Brightness = 1
		Lt.EnvironmentDiffuseScale = 0; Lt.EnvironmentSpecularScale = 0
		for _, e in ipairs(Lt:GetChildren()) do
			if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then e.Enabled = false end
		end
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
	end)
	for _, obj in ipairs(workspace:GetDescendants()) do ANL.process(obj) end
	ANL.conn = workspace.DescendantAdded:Connect(function(obj)
		if ANL.active then ANL.process(obj) end
	end)
end
function ANL.stop()
	ANL.active = false
	if ANL.conn then ANL.conn:Disconnect(); ANL.conn = nil end
end

-- ===================================================================
-- HARDER HIT ANIM
-- ===================================================================
local HHA = {enabled=false, conn=nil, saved=nil,
	ids={
		idle1="rbxassetid://133806214992291", idle2="rbxassetid://94970088341563",
		walk="rbxassetid://707897309", run="rbxassetid://707861613",
		jump="rbxassetid://116936326516985", fall="rbxassetid://116936326516985",
		climb="rbxassetid://116936326516985", swim="rbxassetid://116936326516985",
		swimidle="rbxassetid://116936326516985",
	}}
function HHA.save(char)
	local a = char:FindFirstChild("Animate"); if not a then return end
	local function g(o) return o and o.AnimationId or nil end
	HHA.saved = {
		idle1=g(a.idle and a.idle.Animation1), idle2=g(a.idle and a.idle.Animation2),
		walk=g(a.walk and a.walk.WalkAnim), run=g(a.run and a.run.RunAnim),
		jump=g(a.jump and a.jump.JumpAnim), fall=g(a.fall and a.fall.FallAnim),
		climb=g(a.climb and a.climb.ClimbAnim), swim=g(a.swim and a.swim.Swim),
		swimidle=g(a.swimidle and a.swimidle.SwimIdle),
	}
end
function HHA.apply(char)
	local a = char:FindFirstChild("Animate"); if not a then return end
	local function s(o,id) if o then o.AnimationId = id end end
	s(a.idle and a.idle.Animation1, HHA.ids.idle1); s(a.idle and a.idle.Animation2, HHA.ids.idle2)
	s(a.walk and a.walk.WalkAnim, HHA.ids.walk); s(a.run and a.run.RunAnim, HHA.ids.run)
	s(a.jump and a.jump.JumpAnim, HHA.ids.jump); s(a.fall and a.fall.FallAnim, HHA.ids.fall)
	s(a.climb and a.climb.ClimbAnim, HHA.ids.climb); s(a.swim and a.swim.Swim, HHA.ids.swim)
	s(a.swimidle and a.swimidle.SwimIdle, HHA.ids.swimidle)
end
function HHA.restore(char)
	if not HHA.saved then return end
	local a = char:FindFirstChild("Animate"); if not a then return end
	local function s(o,id) if o and id then o.AnimationId = id end end
	s(a.idle and a.idle.Animation1, HHA.saved.idle1); s(a.idle and a.idle.Animation2, HHA.saved.idle2)
	s(a.walk and a.walk.WalkAnim, HHA.saved.walk); s(a.run and a.run.RunAnim, HHA.saved.run)
	s(a.jump and a.jump.JumpAnim, HHA.saved.jump); s(a.fall and a.fall.FallAnim, HHA.saved.fall)
	s(a.climb and a.climb.ClimbAnim, HHA.saved.climb); s(a.swim and a.swim.Swim, HHA.saved.swim)
	s(a.swimidle and a.swimidle.SwimIdle, HHA.saved.swimidle)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop(0) end end
end
function HHA.start()
	if HHA.conn then HHA.conn:Disconnect(); HHA.conn = nil end
	local char = LP.Character
	if char then
		HHA.save(char); HHA.apply(char)
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop(0) end end
	end
	HHA.conn = RunService.Heartbeat:Connect(function()
		if not HHA.enabled then return end
		local c = LP.Character
		if c then HHA.apply(c) end
	end)
end
function HHA.stop()
	if HHA.conn then HHA.conn:Disconnect(); HHA.conn = nil end
	local char = LP.Character
	if char then HHA.restore(char) end
end

-- ===================================================================
-- BAT AIMBOT
-- ===================================================================
local batAimbotEnabled = false
local aimbotConn = nil
local hittingCooldown = false

local aimbotHighlight = Instance.new("Highlight")
aimbotHighlight.Name = DISC.name()
aimbotHighlight.FillColor = Color3.fromRGB(0, 150, 255)
aimbotHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
aimbotHighlight.FillTransparency = 0.5
aimbotHighlight.OutlineTransparency = 0
DISC.hide(aimbotHighlight)

local function getBat()
	local char = LP.Character; if not char then return nil end
	local bp = LP:FindFirstChild("Backpack")
	local SlapList = {"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
	local tool = char:FindFirstChild("Bat")
	if tool then return tool end
	if bp then tool = bp:FindFirstChild("Bat"); if tool then tool.Parent = char; return tool end end
	for _, name in ipairs(SlapList) do
		local t = char:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
		if t then return t end
	end
end

local function tryHitBat()
	if hittingCooldown then return end
	hittingCooldown = true
	local bat = getBat()
	if bat then
		pcall(function()
			bat:Activate()
			local evt = bat:FindFirstChildWhichIsA("RemoteEvent")
			if evt then evt:FireServer() end
		end)
	end
	task.delay(0.12, function() hittingCooldown = false end)
end

local AIM = {SPEED=58, VERT=52, DIST=-2.8, HEIGHT=4.75, V_OFF=1, TURN=285, MAX_TURN=28, target=nil, lastScan=0}

function AIM.valid(targetRoot)
	if not targetRoot or not targetRoot.Parent then return false end
	local char = targetRoot.Parent
	local hum = char:FindFirstChildOfClass("Humanoid")
	local ff = char:FindFirstChildOfClass("ForceField")
	return hum and hum.Health > 0 and not ff
end

local function getAutoBatTarget()
	local char = LP.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	if AIM.target and AIM.valid(AIM.target) then return AIM.target end
	AIM.lastScan = tick()
	AIM.target = nil
	local closest, minDist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP and plr.Character then
			local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
			if tRoot and AIM.valid(tRoot) then
				local dist = (tRoot.Position - root.Position).Magnitude
				if dist < minDist then minDist = dist; closest = tRoot end
			end
		end
	end
	AIM.target = closest
	return AIM.target
end

local function startBatAimbot()
	if aimbotConn then return end
	batAimbotEnabled = true; State.autoBatToggled = true
	aimbotConn = RunService.Heartbeat:Connect(function()
		if not batAimbotEnabled then return end
		local char = LP.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local target = getAutoBatTarget()
		if target and target.Parent then
			aimbotHighlight.Adornee = target.Parent
			local tVel = target.AssemblyLinearVelocity
			local predict = math.clamp(tVel.Magnitude / 130, 0.05, 0.18)
			local predictedPos = target.Position + (tVel * predict)
			local forward = target.CFrame.LookVector
			local frontPos = predictedPos + forward * 4
			local dir = (frontPos - root.Position)
			if dir.Magnitude > 0.1 then
				dir = dir.Unit
				root.AssemblyLinearVelocity = Vector3.new(dir.X * 55, dir.Y * 55, dir.Z * 55)
			end
			local dist = (target.Position - root.Position).Magnitude
			if dist <= 8 then tryHitBat() end
		else
			aimbotHighlight.Adornee = nil
		end
	end)
end

local function stopBatAimbot()
	batAimbotEnabled = false; State.autoBatToggled = false
	if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
	aimbotHighlight.Adornee = nil
	if proxy then pcall(function() proxy.AssemblyLinearVelocity = Vector3.new(0, proxy.AssemblyLinearVelocity.Y, 0) end) end
	local c = LP.Character
	local myHRP = c and c:FindFirstChild("HumanoidRootPart")
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum then hum.AutoRotate = true end
	if myHRP then
		myHRP.AssemblyAngularVelocity = Vector3.zero
		myHRP.AssemblyLinearVelocity = myHRP.AssemblyLinearVelocity * 0.3
	end
end

-- ===================================================================
-- GUI COMPLETA
-- ===================================================================
local gui = Instance.new("ScreenGui")
gui.Name = DISC.name()
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
DISC.hide(gui)

local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.new(0, 320, 0, 480)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -240)
mainFrame.BackgroundColor3 = C_BG
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.92
local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 14)

local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = C_HEADER
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
local titleCorner = Instance.new("UICorner", titleBar)
titleCorner.CornerRadius = UDim.new(0, 14)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1, -80, 1, 0)
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "NRHUB v2"
titleText.TextColor3 = C_NR
titleText.Font = Enum.Font.GothamBlack
titleText.TextSize = 22
titleText.TextXAlignment = Enum.TextXAlignment.Left

local closeButton = Instance.new("TextButton", titleBar)
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -40, 0.5, -15)
closeButton.BackgroundColor3 = C_BORDER
closeButton.Text = "X"
closeButton.TextColor3 = C_WHITE
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
local closeCorner = Instance.new("UICorner", closeButton)
closeCorner.CornerRadius = UDim.new(0, 8)
closeButton.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

local miniButton = Instance.new("TextButton", titleBar)
miniButton.Size = UDim2.new(0, 30, 0, 30)
miniButton.Position = UDim2.new(1, -80, 0.5, -15)
miniButton.BackgroundColor3 = C_BORDER
miniButton.Text = "-"
miniButton.TextColor3 = C_WHITE
miniButton.Font = Enum.Font.GothamBold
miniButton.TextSize = 20
local miniCorner = Instance.new("UICorner", miniButton)
miniCorner.CornerRadius = UDim.new(0, 8)

local scrollFrame = Instance.new("ScrollingFrame", mainFrame)
scrollFrame.Size = UDim2.new(1, -20, 1, -65)
scrollFrame.Position = UDim2.new(0, 10, 0, 55)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = C_NR
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local scrollLayout = Instance.new("UIListLayout", scrollFrame)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Padding = UDim.new(0, 6)

local minimized = false
miniButton.MouseButton1Click:Connect(function()
	minimized = not minimized
	scrollFrame.Visible = not minimized
	mainFrame.Size = minimized and UDim2.new(0, 320, 0, 55) or UDim2.new(0, 320, 0, 480)
	mainFrame.Position = minimized and UDim2.new(0.5, -160, 0.5, -27.5) or UDim2.new(0.5, -160, 0.5, -240)
end)

local function createButton(text, color, callback)
	local btn = Instance.new("TextButton", scrollFrame)
	btn.Size = UDim2.new(1, 0, 0, 42)
	btn.BackgroundColor3 = C_ROW
	btn.BackgroundTransparency = 0.2
	btn.Text = text
	btn.TextColor3 = color or C_ACCENT
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	local btnCorner = Instance.new("UICorner", btn)
	btnCorner.CornerRadius = UDim.new(0, 8)
	local btnStroke = Instance.new("UIStroke", btn)
	btnStroke.Color = C_BORDER
	btnStroke.Thickness = 0.5
	btn.MouseButton1Click:Connect(callback)
	return btn
end

local function createToggleButton(text, getState, onToggle)
	local btn = Instance.new("TextButton", scrollFrame)
	btn.Size = UDim2.new(1, 0, 0, 42)
	btn.BackgroundColor3 = C_ROW
	btn.BackgroundTransparency = 0.2
	btn.TextColor3 = C_ACCENT
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	local btnCorner = Instance.new("UICorner", btn)
	btnCorner.CornerRadius = UDim.new(0, 8)
	local btnStroke = Instance.new("UIStroke", btn)
	btnStroke.Color = C_BORDER
	btnStroke.Thickness = 0.5
	
	local function updateText()
		btn.Text = text .. " [" .. (getState() and "ON" or "OFF") .. "]"
		btn.TextColor3 = getState() and C_NR or C_ACCENT
	end
	
	updateText()
	btn.MouseButton1Click:Connect(function()
		onToggle()
		updateText()
	end)
	return btn
end

-- ===================================================================
-- CREAR BOTONES DEL MENU
-- ===================================================================
createToggleButton("Auto Steal", function() return AutoSteal.Enabled end, function()
	AutoSteal.Enabled = not AutoSteal.Enabled
	if AutoSteal.Enabled then startAutoSteal() else stopAutoSteal() end
end)

createToggleButton("Auto Left", function() return State.autoLeftEnabled end, function()
	State.autoLeftEnabled = not State.autoLeftEnabled
	if State.autoLeftEnabled then startAutoLeft() else stopAutoLeft() end
end)

createToggleButton("Auto Right", function() return State.autoRightEnabled end, function()
	State.autoRightEnabled = not State.autoRightEnabled
	if State.autoRightEnabled then startAutoRight() else stopAutoRight() end
end)

createToggleButton("Carry Speed", function() return State.speedType == "carry" end, function()
	toggleSpeedType()
end)

createToggleButton("Lagger Mode", function() return State.laggerActive end, function()
	toggleLagger()
end)

createButton("Drop Brainrot", C_ACCENT2, function()
	runDropBrainrot()
end)

createButton("TP Down", C_ACCENT2, function()
	tpToGround()
end)

createButton("TP Up", C_ACCENT2, function()
	tpUp()
end)

createButton("Insta Reset", C_ACCENT2, function()
	instaReset()
end)

createToggleButton("Anti Ragdoll", function() return State.antiRagdollEnabled end, function()
	State.antiRagdollEnabled = not State.antiRagdollEnabled
	if State.antiRagdollEnabled then startAntiRagdoll() else stopAntiRagdoll() end
end)

createToggleButton("Infinite Jump", function() return State.infJumpEnabled end, function()
	State.infJumpEnabled = not State.infJumpEnabled
end)

createToggleButton("Auto TP Down", function() return State.autoTpDownEnabled end, function()
	State.autoTpDownEnabled = not State.autoTpDownEnabled
end)

createToggleButton("Auto Bat", function() return batAimbotEnabled end, function()
	if batAimbotEnabled then stopBatAimbot() else startBatAimbot() end
end)

createToggleButton("FPS Boost", function() return State.fpsBoostEnabled end, function()
	State.fpsBoostEnabled = not State.fpsBoostEnabled
	if State.fpsBoostEnabled then applyFPSBoost() end
end)

createToggleButton("Anti Lag", function() return ANL.active end, function()
	if ANL.active then ANL.stop() else ANL.start() end
end)

-- Footer
local footer = Instance.new("TextLabel", scrollFrame)
footer.Size = UDim2.new(1, 0, 0, 25)
footer.BackgroundTransparency = 1
footer.Text = "NRHub v2.1 | discord.gg/nrhub"
footer.TextColor3 = C_DIM
footer.Font = Enum.Font.GothamMedium
footer.TextSize = 10
footer.TextScaled = true

-- ===================================================================
-- CHARACTER SETUP
-- ===================================================================
local h, hrp, speedLbl
local function setupChar(char)
	task.wait(0.1)
	h = char:WaitForChild("Humanoid",5)
	hrp = char:WaitForChild("HumanoidRootPart",5)
	if not h or not hrp then return end
	if State.antiRagdollEnabled and not Conns.antiRag then task.wait(0.5); startAntiRagdoll() end
	stopMedusaCounter()
	setupMedusaCounter(char)
	if HHA.enabled then task.wait(0.3); HHA.start() end
	if State.unwalkEnabled then State.unwalkEnabled=false; task.wait(0.3); startUnwalk() end
	if batAimbotEnabled then stopBatAimbot() end
	patrolFrozen = false; patrolFreezeUntil = 0
	proxy = nil; ensureProxy()
	task.spawn(function()
		task.wait(0.5)
		if State.autoLeftEnabled then stopAutoLeft(); State.autoLeftEnabled = true; startAutoLeft()
		elseif State.autoRightEnabled then stopAutoRight(); State.autoRightEnabled = true; startAutoRight() end
		if AutoSteal.Enabled then
			stopAutoSteal()
			task.wait(0.1)
			startAutoSteal()
		end
	end)
	_promptCache = nil
	_plotIsMyCache = {}
end

LP.CharacterAdded:Connect(setupChar)
if LP.Character then task.spawn(function() setupChar(LP.Character) end) end

-- ===================================================================
-- NO COLLIDE
-- ===================================================================
local function setupNoCollideForChar(char)
	for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
	char.DescendantAdded:Connect(function(p) if p:IsA("BasePart") then p.CanCollide = false end end)
end
Players.PlayerAdded:Connect(function(p)
	if p == LP then return end
	p.CharacterAdded:Connect(setupNoCollideForChar)
	if p.Character then setupNoCollideForChar(p.Character) end
end)
for _,p in ipairs(Players:GetPlayers()) do
	if p ~= LP and p.Character then setupNoCollideForChar(p.Character) end
end

-- ===================================================================
-- MAIN LOOPS
-- ===================================================================
UIS.JumpRequest:Connect(function()
	if not State.infJumpEnabled then return end
	if State.infJumpMode ~= "manual" then return end
	local char = LP.Character; if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z) end
end)

RunService.Heartbeat:Connect(function()
	if not State.infJumpEnabled and not State.autoTpDownEnabled then return end
	local char = LP.Character; if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
	if State.infJumpEnabled then
		local hum2 = char:FindFirstChildOfClass("Humanoid")
		if State.infJumpMode == "hold" then
			local held = UIS:IsKeyDown(Enum.KeyCode.Space) or (hum2 and hum2.Jump == true)
			if held and root.Velocity.Y < 30 then
				root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z)
			end
		end
		if root.Velocity.Y < -120 then root.Velocity = Vector3.new(root.Velocity.X, -120, root.Velocity.Z) end
	end
	if State.autoTpDownEnabled and root.Position.Y >= State.autoTpDownY then
		local rot = root.CFrame.Rotation
		root.CFrame = CFrame.new(root.Position.X, -8.80, root.Position.Z) * rot
	end
end)

RunService.Stepped:Connect(function()
	if not (h and hrp) then return end
	if State._tpInProgress then return end
	if batAimbotEnabled then return end
	if State.autoLeftEnabled or State.autoRightEnabled then return end
	local md = h.MoveDirection
	local spd = getCurrentSpeed()
	if md.Magnitude > 0 then
		State.lastMoveDir = md
		proxyMove(md, spd)
	elseif State.antiRagdollEnabled and State.lastMoveDir.Magnitude > 0 then
		local anyHeld = false
		for key in pairs(MOVE_KEYS) do if UIS:IsKeyDown(key) then anyHeld=true; break end end
		if anyHeld then proxyMove(State.lastMoveDir, spd)
		else proxyStop() end
	else
		if proxy then proxy.AssemblyLinearVelocity = Vector3.new(0, proxy.AssemblyLinearVelocity.Y, 0) end
	end
end)

-- CARRY AUTO DETECT
local _carryRayParams = RaycastParams.new()
_carryRayParams.FilterType = Enum.RaycastFilterType.Exclude
local _carryLastCheck = 0
RunService.Heartbeat:Connect(function()
	local now = tick(); if now - _carryLastCheck < 0.15 then return end
	_carryLastCheck = now
	if tick() < State._carryManualUntil then return end
	local char = LP.Character; if not char then return end
	local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	_carryRayParams.FilterDescendantsInstances = {char}
	local res = workspace:Raycast(hrp.Position, Vector3.new(0,-5,0), _carryRayParams)
	if not res or not res.Instance then return end
	local plot = getPlotOf(res.Instance)
	if State.speedType ~= "carry" then
		if res.Instance.Name == "Part" and plot and not isMyPlotByName(plot.Name) then
			State.speedType = "carry"; refreshUIToggles()
			if MobileButtons.Buttons.carrySpeed then MobileButtons.Buttons.carrySpeed(true) end
		end
	else
		if plot and isMyPlotByName(plot.Name) then
			State.speedType = "normal"; refreshUIToggles()
			if MobileButtons.Buttons.carrySpeed then MobileButtons.Buttons.carrySpeed(false) end
		end
	end
end)

-- Anti-caida bajo el mapa
RunService.Stepped:Connect(function()
	local c = LP.Character
	if c then
		local r = c:FindFirstChild("HumanoidRootPart")
		if r and r.Position.Y < -10 then
			r.Position = Vector3.new(r.Position.X, -6.5, r.Position.Z)
		end
	end
end)

refreshUIToggles = function()
	if UIR.modeValLbl then
		if State.laggerUseEnabled then UIR.modeValLbl.Text = "Lagger Use"
		elseif State.laggerCarryActive then UIR.modeValLbl.Text = "Lagger Carry"
		elseif State.laggerActive then UIR.modeValLbl.Text = "Lagger Normal"
		else UIR.modeValLbl.Text = (State.speedType=="normal") and "Normal" or "Carry" end
	end
end

-- LOAD CONFIG
local function loadConfig()
	local hasFile = false; pcall(function() hasFile = isfile("rbxdata_cfg9x.json") end)
	if not hasFile then return end
	local ok, cfg = pcall(function() return HttpService:JSONDecode(readfile("rbxdata_cfg9x.json")) end)
	if not ok or not cfg then return end
	if cfg.normalSpeed then State.normalSpeed = cfg.normalSpeed end
	if cfg.carrySpeed then State.carrySpeed = cfg.carrySpeed end
	if cfg.laggerSpeed then State.laggerSpeed = cfg.laggerSpeed end
	if cfg.laggerCarrySpeed then State.laggerCarrySpeed = cfg.laggerCarrySpeed end
	if cfg.speedType then State.speedType = cfg.speedType end
	if cfg.laggerActive ~= nil then State.laggerActive = cfg.laggerActive end
	if cfg.laggerCarryActive ~= nil then State.laggerCarryActive = cfg.laggerCarryActive end
	if cfg.grabRadius then AutoSteal.Radius = cfg.grabRadius end
	if cfg.grabDuration then AutoSteal.Duration = cfg.grabDuration end
	if cfg.autoCarryOnGrab ~= nil then State.autoCarryOnGrab = cfg.autoCarryOnGrab end
	if cfg.autoStealEnabled then AutoSteal.Enabled = true; startAutoSteal() end
	if cfg.infJump then State.infJumpEnabled = true end
	if cfg.autoTpDown ~= nil then State.autoTpDownEnabled = cfg.autoTpDown end
	if cfg.autoTpDownY then State.autoTpDownY = cfg.autoTpDownY end
	if cfg.laggerUseAmount then State.laggerUseAmount = cfg.laggerUseAmount end
	if cfg.laggerUseEnabled then State.laggerUseEnabled = cfg.laggerUseEnabled end
	if cfg.antiRagdoll then State.antiRagdollEnabled = true; startAntiRagdoll() end
	if cfg.fpsBoost then State.fpsBoostEnabled = true; applyFPSBoost() end
	if cfg.medusaCounter then State.medusaCounterEnabled = true end
	if cfg.unwalkEnabled then task.spawn(function() task.wait(0.5); startUnwalk() end) end
	if cfg.autoBatToggled ~= nil then State.autoBatToggled = cfg.autoBatToggled end
	if cfg.autoLeftEnabled ~= nil then State.autoLeftEnabled = cfg.autoLeftEnabled end
	if cfg.autoRightEnabled ~= nil then State.autoRightEnabled = cfg.autoRightEnabled end
	if cfg.mobileLocked ~= nil then MobileButtons.Locked = cfg.mobileLocked end
	local function loadKey(k,s)
		if cfg[k] and type(cfg[k])=="string" then
			local ok2,kc = pcall(function() return Enum.KeyCode[cfg[k]] end)
			if ok2 and kc then State[s] = kc end
		end
	end
	loadKey("keyAutoLeft","keyAutoLeft"); loadKey("keyAutoRight","keyAutoRight")
	loadKey("keyDropBR","keyDropBR"); loadKey("keyTpDown","keyTpDown")
	loadKey("keyAutoBat","keyAutoBat"); loadKey("keyCarrySpeed","keyCarrySpeed")
	loadKey("keyTpUp","keyTpUp"); loadKey("keyLaggerMode","keyLaggerMode")
	loadKey("keyInstaReset","keyInstaReset")
	loadKey("keyLaggerUse","keyLaggerUse")
	if cfg.fovValue then fovValue=cfg.fovValue end
	if cfg.fovEnabled then fovEnabled=true; enableFOV() end
	task.spawn(function()
		task.wait(0.6)
		if State.laggerActive or State.laggerCarryActive then startAutoSteal() end
		if State.autoLeftEnabled then startAutoLeft() end
		if State.autoRightEnabled then startAutoRight() end
	end)
	refreshUIToggles()
end

loadConfig()
State.fpsBoostEnabled = true; pcall(applyFPSBoost)
if not ANL.active then ANL.start() end
refreshUIToggles()

print("[NRHub v2] Cargado con exito - GUI lista!")