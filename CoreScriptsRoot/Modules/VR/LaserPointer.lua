--LaserPointer.lua
--Implements the visual part of the VR laser pointer and implements
--VR teleporting and movement mechanics
--Written by Kyle, September 2016
local CoreGui = game.CoreGui
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local PathfindingService = game:GetService("PathfindingService")
local Utility = require(RobloxGui.Modules.Settings.Utility) --todo: use common utility module when it's done

local LocalPlayer = Players.LocalPlayer

--Pathfinding sort of works, but it's very slow and does not handle slopes very well.
--Use at your own risk.
local usePathfinding = false

local gamma, invGamma = 2.2, 1/2.2
local function fromLinearRGB(color)
	return Color3.new(color.r ^ gamma, color.g ^ gamma, color.b ^ gamma)
end
local function toLinearRGB(color)
	return Color3.new(color.r ^ invGamma, color.g ^ invGamma, color.b ^ invGamma)
end

local CONTAINER_FOLDER_NAME = "VRCorePanelParts"
local function setPartInGame(part, inGame)
	if not part then
		return
	end
	if inGame and not part:IsDescendantOf(game) then
		local container = workspace.CurrentCamera:FindFirstChild(CONTAINER_FOLDER_NAME)
		if not container then
			coroutine.wrap(function()
				part.Parent = workspace.CurrentCamera:WaitForChild(CONTAINER_FOLDER_NAME)
			end)()
		else
			part.Parent = container
		end
	else
		part.Parent = nil
	end
end

--Teleport visual configuration
local TELEPORT = {
	ARC_COLOR_GOOD = fromLinearRGB(Color3.fromRGB(0, 162, 255)),
	ARC_COLOR_BAD = fromLinearRGB(Color3.fromRGB(253, 68, 72)),
	ARC_THICKNESS = 0.05,

	PLOP_GOOD = "rbxasset://textures/ui/VR/VR Pointer Disc Blue.png",
	PLOP_BAD = "rbxasset://textures/ui/VR/VR Pointer Disc Red.png",
	PLOP_BALL_COLOR_GOOD = BrickColor.new("Bright green"),
	PLOP_BALL_COLOR_BAD = BrickColor.new("Bright red"),
	PLOP_BALL_SIZE = 0.5,
	PLOP_SIZE = 2,
	PLOP_PULSE_MIN_SIZE = 0,
	PLOP_PULSE_MAX_SIZE = 2,

	MAX_VALID_DISTANCE = 32,

	BUTTON_DOWN_THRESHOLD = 0.95,
	BUTTON_UP_THRESHOLD = 0.5,

	MIN_VELOCITY = 10,
	RANGE_T_EXP = 2,
	G = 50,

	PULSE_DURATION = 0.8,
	PULSE_PERIOD = 1,
	PULSE_EXP = 2,
	PULSE_SIZE_0 = 0.25,
	PULSE_SIZE_1 = 2,

	BALL_WAVE_PERIOD = 2,
	BALL_WAVE_AMPLITUDE = 0.5,
	BALL_WAVE_START = 0.25,
	BALL_WAVE_EXP = 0.8,

	FLOOR_OFFSET = 4.5,

	FADE_OUT_DURATION = 0.125,
	FADE_IN_DURATION = 0.125,

	CLEAR_AABB_SIZE = Vector3.new(2.5, 4, 2.5),

	SUCCESS_SOUND = "rbxassetid://147722227",
	FAIL_SOUND = "rbxassetid://138087015",

	PATH_RECOMPUTE_DIST_THRESHOLD = 4
}

local LASER = {
	ARC_COLOR_GOOD = TELEPORT.ARC_COLOR_GOOD,
	ARC_COLOR_BAD = TELEPORT.ARC_COLOR_BAD,
	ARC_THICKNESS = 0.025,

	MAX_DISTANCE = 100
}

local zeroVector2, identityVector2 = Vector2.new(0, 0), Vector2.new(1, 1)
local zeroVector3, identityVector3 = Vector3.new(0, 0, 0), Vector3.new(1, 1, 1)
local flattenMask = Vector3.new(1, 0, 1) --flattens a direction vector when multiplied by removing the vertical component
local minimumPartSize = Vector3.new(0.2, 0.2, 0.2)
local identity = CFrame.new()

local function applyExpCurve(x, exp)
	local y = x ^ exp
	if y ~= y then
		y = math.abs(x) ^ exp
	end
	return y
end

local LaserPointer = {}
LaserPointer.__index = LaserPointer

function LaserPointer.new()
	local self = setmetatable({}, LaserPointer)

	self.enabled = false

	self.teleportMode = true
	self.teleportMaxRangePerSecond = 16
	self.teleportRangeT = 0
	self.teleportPoint = zeroVector3
	self.teleportNormal = Vector3.new(0, 1, 0)
	self.teleportPart = nil
	self.teleportValid = false
	self.teleportButtonDown = false
	self.teleporting = false
	self.teleportBounceStart = tick()

	self.pathValid = false
	self.computingPath = false
	self.pathStart = zeroVector3
	self.pathEnd = zeroVector3

	do --Create the instances that make up the Laser Pointer
		self.originPart = Utility:Create("Part") {
			Name = "LaserPointerOrigin",
			Anchored = true,
			CanCollide = false,
			TopSurface = Enum.SurfaceType.SmoothNoOutlines,
			BottomSurface = Enum.SurfaceType.SmoothNoOutlines,
			Material = Enum.Material.SmoothPlastic,
			Size = minimumPartSize,
			Transparency = 1 --smallest size possible
		}
		self.parabola = Utility:Create("ParabolaAdornment") {
			Name = "LaserPointerParabola",
			Parent = CoreGui,
			Adornee = self.originPart,
			A = -1,
			B = 2,
			C = 0,
			Color3 = TELEPORT.COLOR_GOOD,
			Thickness = TELEPORT.ARC_THICKNESS
		}
		self.plopPart = Utility:Create("Part") {
			Name = "LaserPointerTeleportPlop",
			Anchored = true,
			CanCollide = false,
			Size = minimumPartSize,
			Transparency = 1
		}
		self.plopBall = Utility:Create("Part") {
			Name = "LaserPointerTeleportPlopBall",
			Anchored = true,
			CanCollide = false,
			TopSurface = Enum.SurfaceType.SmoothNoOutlines,
			BottomSurface = Enum.SurfaceType.SmoothNoOutlines,
			Material = Enum.Material.Neon,
			BrickColor = TELEPORT.PLOP_BALL_COLOR_GOOD,
			Shape = Enum.PartType.Ball,
			Size = identityVector3 * TELEPORT.PLOP_BALL_SIZE
		}
		self.plopAdorn = Utility:Create("ImageHandleAdornment") { --this feels hacky, but no good alternatives for unlit image in 3D that aren't SurfaceGuis w/ ImageLabels
			Name = "LaserPointerTeleportPlopAdorn",
			Parent = self.plopPart,
			Adornee = self.plopPart,
			Size = identityVector2 * TELEPORT.PLOP_SIZE,
			Image = TELEPORT.PLOP_GOOD
		}
		self.plopAdornPulse = Utility:Create("ImageHandleAdornment") {
			Name = "LaserPointerTeleportPlopAdornPulse",
			Parent = self.plopPart,
			Adornee = self.plopPart,
			Size = zeroVector2,
			Image = TELEPORT.PLOP_GOOD,
			Transparency = 0.5
		}

		--I want to nuke this part, but for now it's a necessary evil or very bad things happen when you try to teleport
		--where you don't fit...
		self.collisionTestPart = Utility:Create("Part") {
			Name = "LaserPointerTeleportCollisionTester",
			Size = TELEPORT.CLEAR_AABB_SIZE,
			Transparency = 0.5,
			Anchored = true,
			CanCollide = true,
			Parent = workspace.CurrentCamera
		}

		self.teleportSuccessSound = Utility:Create("Sound") {
			Name = "TeleportSuccessSound",
			SoundId = TELEPORT.SUCCESS_SOUND,
			Parent = self.originPart
		}
		self.teleportFailSound = Utility:Create("Sound") {
			Name = "TeleportFailSound",
			SoundId = TELEPORT.FAIL_SOUND,
			Parent = self.originPart
		}
	end

	self:setTeleportMode(true)

	return self
end

function LaserPointer:setArcLaunchParams(launchAngle, launchVelocity, gravity)
	local velocityX = math.cos(launchAngle) * launchVelocity
	local velocityY = math.sin(launchAngle) * launchVelocity

	--don't let velocityX = 0 or we get a divide-by-zero and bad things happen
	if velocityX == 0 then
		velocityX = 1e-6
	end

	self.parabola.A = (-0.5 * gravity) / (velocityX ^ 2)
	self.parabola.B = velocityY / velocityX
	self.parabola.C = 0
	self.parabola.Range = velocityX
end

function LaserPointer:getArcHit(pos, look, ignore)
	local lookFlat = look * flattenMask
	self.originPart.CFrame = CFrame.new(pos, pos + lookFlat) * CFrame.Angles(0, math.pi / 2, 0)

	local parabHitPart, parabHitPoint, parabHitNormal, parabHitMaterial, t = self.parabola:FindPartOnParabola(ignore)
	return parabHitPart, parabHitPoint, parabHitNormal, t
end

function LaserPointer:getLaserHit(pos, look, ignore)
	local ray = Ray.new(pos, look * LASER.MAX_DISTANCE)
	local laserHitPart, laserHitPoint, laserHitNormal, laserHitMaterial = workspace:FindPartOnRayWithIgnoreList(ray, ignore)
	local t = (laserHitPoint - pos) / LASER.MAX_DISTANCE
	return laserHitPart, laserHitPoint, laserHitNormal, t
end

function LaserPointer:setTeleportMaxRangePerSecond(maxRange)
	self.teleportMaxRangePerSecond = maxRange
end

function LaserPointer:calculateLaunchVelocity(gravity, launchAngle)
	local maxVelocity = TELEPORT.MAX_VALID_DISTANCE
	local minVelocity = TELEPORT.MIN_VELOCITY
	local velocityRange = math.max(0, maxVelocity - minVelocity)
	return ((self.teleportRangeT ^ TELEPORT.RANGE_T_EXP) * velocityRange) + minVelocity
end

function LaserPointer:recomputePath(startPos, endPos)
	self.computingPath = true

	self.pathStart = startPos
	self.pathEnd = endPos
	coroutine.wrap(function()
		self.lastPath = PathfindingService:ComputeRawPathAsync(startPos, endPos, TELEPORT.MAX_VALID_DISTANCE)
		self.computingPath = false
	end)()
end

function LaserPointer:checkLastPath()
	if not self.lastPath then
		self.pathValid = true
		return
	end
	if self.lastPath.Status ~= Enum.PathStatus.Success then
		self.pathValid = false
		return
	end
	local occludedPoint = self.lastPath:CheckOcclusionAsync(0)
	if occludedPoint < 0 then
		self.pathValid = true
	end
end

function LaserPointer:canTeleportTo(cameraPos, part, point, normal)
	local character = LocalPlayer.Character
	if not character then
		return false
	end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return false
	end

	if not part then
		return false
	end
	if normal.Y < 0 then
		return false
	end

	local dist = (point - cameraPos).magnitude
	if dist > TELEPORT.MAX_VALID_DISTANCE then
		return false
	end

	local bbPos = point
	local halfBbSize = TELEPORT.CLEAR_AABB_SIZE * 0.5
	local minBound = Vector3.new(bbPos.X - halfBbSize.X, bbPos.Y, bbPos.Z - halfBbSize.Z)
	local maxBound = minBound + TELEPORT.CLEAR_AABB_SIZE

	local theta = math.rad(90) - math.asin(normal.Y)
	local slopeOffset = math.sin(theta) * math.sqrt(halfBbSize.X^2 + halfBbSize.Z^2)
	self.collisionTestPart.CFrame = CFrame.new(point + Vector3.new(0, (TELEPORT.CLEAR_AABB_SIZE.Y / 2) + slopeOffset + 0.1, 0))
	
	--Not only does workspace:FindPartsInRegion3 only do AABBs, it also doesn't seem to like slopes.
	--Using an arbitary part here sounds nasty as an implementation detail, but the concept seems sound.
	--Getting the part out of the workspace entirely would be a good long-term solution.
	local foundParts = self.collisionTestPart:GetTouchingParts()
	--send it far away so it doesn't interfere with devs (I really hate doing this)
	self.collisionTestPart.CFrame = CFrame.new(1e10, 1e10, 1e10)

	for i, v in pairs(foundParts) do
		if v ~= self.plopPart and v ~= self.plopBall and not v:IsDescendantOf(LocalPlayer.Character) then
			return false
		end
	end

	if usePathfinding then
		self:checkLastPath()
		if not self.computingPath then
			local startPos = humanoidRootPart.Position
			local endPos = point + Vector3.new(0, 4, 0)

			local startDist = (self.pathStart - startPos).magnitude
			local endDist = (self.pathEnd - endPos).magnitude
			if startDist > TELEPORT.PATH_RECOMPUTE_DIST_THRESHOLD or endDist > TELEPORT.PATH_RECOMPUTE_DIST_THRESHOLD or not self.pathValid then
				self:recomputePath(startPos, endPos)
			end
		end
		
		if not self.pathValid then
			return false
		end
	end

	return true
end

function LaserPointer:onTeleportButtonDown()

end

function LaserPointer:onTeleportButtonUp()
	self.teleportRangeT = 0

	local teleportValid = self.teleportValid
	local teleportPoint = self.teleportPoint
	local teleportNormal = self.teleportNormal

	local character = LocalPlayer.Character
	if not character then
		return
	end

	if teleportValid then
		--play teleport success sound
		self.teleportSuccessSound:Play()
		self.teleporting = true

		wait(FADE_OUT_DURATION)

		local camera = workspace.CurrentCamera
		local flatLookDir = camera.CFrame.lookVector * flattenMask
		local pos = teleportPoint + (teleportNormal * TELEPORT.FLOOR_OFFSET)
		character:SetPrimaryPartCFrame(CFrame.new(pos, pos + flatLookDir))

		wait(FADE_IN_DURATION)
		self.teleporting = false
	else
		--play teleport failed sound
		self.teleportFailSound:Play()
	end
end

function LaserPointer:onTeleportButtonAction(actionName, inputState, inputObj)
	if self.teleporting then
		return
	end

	local state = inputObj.Position.Z
	if self.teleportButtonDown and state < TELEPORT.BUTTON_UP_THRESHOLD then
		self.teleportButtonDown = false
		coroutine.wrap(function() self:onTeleportButtonUp() end)()
		return
	end

	if not self.teleportButtonDown and state > TELEPORT.BUTTON_DOWN_THRESHOLD then
		self.teleportButtonDown = true
		coroutine.wrap(function() self:onTeleportButtonDown() end)()
	end
end

function LaserPointer:setEnabled(enabled)
	self.enabled = enabled
	if self.enabled then
		ContextActionService:BindCoreAction("TeleportImpl", function(...) self:onTeleportButtonAction(...) end, false, Enum.KeyCode.ButtonR2)
		setPartInGame(self.originPart, true)
		self:setTeleportMode(true)
	else
		ContextActionService:UnbindCoreAction("TeleportImpl")
		setPartInGame(self.originPart, false)
	end
end

function LaserPointer:setTeleportMode(enabled)
	self.teleportMode = enabled
	if self.teleportMode then
		setPartInGame(self.plopPart, true)
		setPartInGame(self.plopBall, true)
	else
		setPartInGame(self.plopPart, false)
		setPartInGame(self.plopBall, false)
	end
end

function LaserPointer:updateTeleportPlop(parabHitPoint, parabHitNormal)
	local now = tick() - self.teleportBounceStart

	--Make a CFrame out of our hit point and normal; tangent doesn't matter because it's all circular!
	local plopCF = CFrame.new(parabHitPoint, parabHitPoint + parabHitNormal)

	--Calculate the height of the ball from a sine wave raised to a configurable exponent
	if self.teleportValid then
		local ballWave = applyExpCurve(math.sin((now * 2 * math.pi) / TELEPORT.BALL_WAVE_PERIOD), TELEPORT.BALL_WAVE_EXP)
		ballHeight = TELEPORT.BALL_WAVE_START + (ballWave * TELEPORT.BALL_WAVE_AMPLITUDE)
	else
		ballHeight = TELEPORT.BALL_WAVE_AMPLITUDE
	end

	self.plopPart.CFrame = plopCF
	self.plopBall.CFrame = plopCF * CFrame.new(0, 0, -ballHeight)

	--Handle the pulse animation
	--We're basically scheduling it to begin every TELEPORT.PULSE_PERIOD seconds,
	--and the animation runs for TELEPORT.PULSE_DURATION seconds. TELEPORT.PULSE_EXP
	--affects the growth rate of the pulse size; ^2 is a good look, starts slow and accelerates.
	local timeSincePulseStart = now % TELEPORT.PULSE_PERIOD
	if timeSincePulseStart > 0 then
		local pulseSize = timeSincePulseStart / TELEPORT.PULSE_DURATION
		if pulseSize < 1 then
			self.plopAdornPulse.Visible = true
			self.plopAdornPulse.Size = identityVector2 * (TELEPORT.PULSE_SIZE_0 + applyExpCurve(pulseSize, TELEPORT.PULSE_EXP) * (TELEPORT.PULSE_SIZE_1 - TELEPORT.PULSE_SIZE_0))
			self.plopAdornPulse.Transparency = 0.5 + (pulseSize * 0.5)
		else
			self.plopAdornPulse.Visible = false
			self.plopAdornPulse.Size = zeroVector2
			self.pulseStartTime = tick() + TELEPORT.PULSE_PERIOD
		end
	end
end

function LaserPointer:setTeleportValidState(valid)
	if valid then
		self.parabola.Color3 = TELEPORT.ARC_COLOR_GOOD
		self.plopAdorn.Visible = true
		self.plopAdorn.Image = TELEPORT.PLOP_GOOD
		self.plopAdornPulse.Visible = true
		self.plopAdornPulse.Image = TELEPORT.PLOP_GOOD
		self.plopBall.BrickColor = TELEPORT.PLOP_BALL_COLOR_GOOD
	else
		self.parabola.Color3 = TELEPORT.ARC_COLOR_BAD
		self.plopAdorn.Visible = false
		self.plopAdorn.Image = TELEPORT.PLOP_BAD
		self.plopAdornPulse.Visible = false
		self.plopAdornPulse.Image = TELEPORT.PLOP_BAD
		self.plopBall.BrickColor = TELEPORT.PLOP_BALL_COLOR_BAD
	end
end

function LaserPointer:update(dt, originCFrame)
	if not self.enabled then
		return
	end

	--Increase launch velocity if teleport button is held and trigger mode is Timed
	if self.teleportButtonDown then
		self.teleportRangeT = math.min(1, self.teleportRangeT + dt)
	else
		self.teleportRangeT = 0
	end

	local originPos = originCFrame.p
	local originLook = originCFrame.lookVector
	local launchAngle = math.asin(originCFrame.lookVector.Y)
	local launchVelocity = self:calculateLaunchVelocity(TELEPORT.G, launchAngle)
	self:setArcLaunchParams(launchAngle, launchVelocity, TELEPORT.G)

	local ignore = { game.Players.LocalPlayer.Character, self.originPart, workspace.CurrentCamera, p }
	local parabHitPart, parabHitPoint, parabHitNormal, parabHitT = self:getArcHit(originPos, originLook, ignore)

--	ignore[3] = nil
--	local laserHitPart, laserHitPoint, laserHitNormal, laserHitT = self:getLaserHit(originPos, originLook, ignore)
--	todo: check if we should enter/leave teleport mode

	if self.teleportMode then
		--Cut the parabola off where it hit something
		self.parabola.Range = parabHitT * math.cos(launchAngle) * launchVelocity

		self.teleportPoint = parabHitPoint
		self.teleportNormal = parabHitNormal
		self.teleportPart = parabHitPart

		local wasValid = self.teleportValid
		self.teleportValid = self:canTeleportTo(workspace.CurrentCamera.CFrame.p, self.teleportPart, self.teleportPoint, self.teleportNormal)

		if not wasValid and self.teleportValid then
			--Just became valid, reset the bounce timer
			self.teleportBounceStart = tick()
		end

		self:updateTeleportPlop(parabHitPoint, parabHitNormal)
		self:setTeleportValidState(self.teleportValid)

		if not self.teleportValid then
			self.teleportPoint = zeroVector3
			self.teleportNormal = Vector3.new(0, 1, 0)
			self.teleportPart = nil
		end
	else
		--TODO: Laser mode
	end
end

return LaserPointer