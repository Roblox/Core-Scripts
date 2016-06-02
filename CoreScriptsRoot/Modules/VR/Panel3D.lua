--Panel3D: 3D GUI panels for VR
--written by 0xBAADF00D
--revised/refactored 5/11/16

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local PlayersService = game.Players


--Util
local Util = {}
do
	function Util.Create(instanceType)
		return function(data)
			local obj = Instance.new(instanceType)
			for k, v in pairs(data) do
				if type(k) == 'number' then
					v.Parent = obj
				else
					obj[k] = v
				end
			end
			return obj
		end
	end

	-- RayPlaneIntersection (shortened)
	-- http://www.siggraph.org/education/materials/HyperGraph/raytrace/rayplane_intersection.htm
	function Util.RayPlaneIntersection(ray, planeNormal, pointOnPlane)
		planeNormal = planeNormal.unit
		ray = ray.Unit

		local Vd = planeNormal:Dot(ray.Direction)
		if Vd == 0 then -- parallel, no intersection
			return nil
		end

		local V0 = planeNormal:Dot(pointOnPlane - ray.Origin)
		local t = V0 / Vd
		if t < 0 then --plane is behind ray origin, and thus there is no intersection
			return nil
		end
		
		return ray.Origin + ray.Direction * t
	end
end
--End of Util


--Panel3D State variables
local renderStepName = "Panel3DRenderStep-" .. game:GetService("HttpService"):GenerateGUID()
local defaultPixelsPerStud = 64
local pointUpCF = CFrame.Angles(math.rad(-90), math.rad(180), 0)
local zeroVector = Vector3.new(0, 0, 0)
local zeroVector2 = Vector2.new(0, 0)
local turnAroundCF = CFrame.Angles(0, math.rad(180), 0)
local fullyOpaqueAtPixelsFromEdge = 10
local fullyTransparentAtPixelsFromEdge = 80
local partThickness = 0.2

local cursorHidden = false
local cursorHideTime = 2.5

local currentModal = nil
local lastModal = nil
local currentMaxDist = math.huge
local currentClosest = nil
local lastClosest = nil
local currentHeadScale = 1
local panels = {}
local floorRotation = CFrame.new()
local cursor = Util.Create "ImageLabel" {
	Image = "rbxasset://textures/Cursors/Gamepad/Pointer.png",
	Size = UDim2.new(0, 8, 0, 8),
	BackgroundTransparency = 1,
	ZIndex = 10
}
--End of Panel3D State variables


--Panel3D Declaration and enumerations
local Panel3D = {}
Panel3D.Type = {
	None = 0,
	Floor = 1,
	Fixed = 2,
	HorizontalFollow = 3,
	FixedToHead = 4
}

Panel3D.OnPanelClosed = Util.Create 'BindableEvent' {
	Name = 'OnPanelClosed'
}

function Panel3D.GetHeadLookXZ(withTranslation)
	local userHeadCF = UserInputService:GetUserCFrame(Enum.UserCFrame.Head)
	local headLook = userHeadCF.lookVector
	local headYaw = math.atan2(-headLook.Z, headLook.X) + math.rad(90)
	local cf = CFrame.Angles(0, headYaw, 0)

	if withTranslation then
		cf = cf + userHeadCF.p
	end
	return cf
end

function Panel3D.FindContainerOf(element)
	for i, v in pairs(panels) do
		if v.gui and v.gui:IsAncestorOf(element) then
			return v
		end
	end
	return nil
end

function Panel3D.SetModalPanel(panel)
	if currentModal == panel then
		return
	end
	if currentModal then
		currentModal:OnModalChanged(false)
	end
	if panel then
		panel:OnModalChanged(true)
	end
	lastModal = currentModal
	currentModal = panel
end
--End of Panel3D Declaration and enumerations


--Cursor autohiding methods
local cursorHidden = false
local hasTool = false
local lastMouseActivity = tick()
local lastMouseBehavior = Enum.MouseBehavior.Default

local function OnCharacterAdded(character)
	hasTool = false
	for i, v in ipairs(character:GetChildren()) do
		if v:IsA("Tool") then
			hasTool = true
		end
	end
	character.ChildAdded:connect(function(child)
		if child:IsA("Tool") then
			hasTool = true
			lastMouseActivity = tick() --kick the mouse when a tool is equipped
		end
	end)
	character.ChildRemoved:connect(function(child)
		if child:IsA("Tool") then
			hasTool = false
		end
	end)
end
spawn(function()
	while not PlayersService.LocalPlayer do wait() end
	PlayersService.LocalPlayer.CharacterAdded:connect(OnCharacterAdded)
	if PlayersService.LocalPlayer.Character then OnCharacterAdded(PlayersService.LocalPlayer.Character) end
end)
local function autoHideCursor(hide)
	if not UserInputService.VREnabled then
		cursorHidden = false
		return
	end
	if hide then
		--don't hide if there's a tool in the character
		local character = PlayersService.LocalPlayer.Character
		if character and hasTool then
			return
		end
		cursorHidden = true
		UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.ForceHide
	else
		cursorHidden = false
		UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None
	end
end

local function isCursorVisible()
	--if ForceShow, the cursor is definitely visible at all times
	if UserInputService.OverrideMouseIconBehavior == Enum.OverrideMouseIconBehavior.ForceShow then
		return true
	end
	--if ForceHide, the cursor is definitely NOT visible
	if UserInputService.OverrideMouseIconBehavior == Enum.OverrideMouseIconBehavior.ForceHide then
		return false
	end
	--Otherwise, we need to check if the developer set MouseIconEnabled=false
	if UserInputService.MouseIconEnabled and UserInputService.OverrideMouseIconBehavior == Enum.OverrideMouseIconBehavior.None then
		return true
	end
	return false
end

--End of cursor autohiding methods


--Panel class implementation
local Panel = {}
Panel.mt = { __index = Panel }
function Panel.new(name)
	local instance = {
		name = name,

		part = nil,
		gui = nil,

		width = 1,
		height = 1,

		isVisible = false,
		isEnabled = false,
		panelType = Panel3D.Type.None,
		pixelScale = 1,
		showCursor = true,
		canFade = true,
		shouldFindLookAtGuiElement = false,
		ignoreModal = false,

		linkedTo = nil,
		subpanels = {},

		transparency = 1,
		forceShowUntilLookedAt = false,
		isLookedAt = false,
		isOffscreen = true,
		lookAtPixel = Vector2.new(-1, -1),
		lookAtDistance = math.huge,
		lookAtGuiElement = nil,
		isClosest = true
	}

	if panels[name] then
		error("A panel by the name of " .. name .. " already exists.")
	end
	panels[name] = instance

	return setmetatable(instance, Panel.mt)
end

--Panel accessor methods
function Panel:GetPart()
	if not self.part then
		self.part = Util.Create "Part" {
			Name = self.name,
			Parent = nil,

			Transparency = 1,

			CanCollide = false,
			Anchored = true,
			Archivable = false,

			Size = Vector3.new(1, 1, partThickness)
		}
	end
	return self.part
end

function Panel:GetGUI()
	if not self.gui then
		local part = self:GetPart()
		self.gui = Util.Create "SurfaceGui" {
			Parent = CoreGui,
			Adornee = part,
			Active = true,
			ToolPunchThroughDistance = 1000,
			CanvasSize = Vector2.new(0, 0),
			Enabled = self.isEnabled,
			AlwaysOnTop = true
		}
	end
	return self.gui
end

function Panel:FindHoveredGuiElement(elements)
	local x, y = self.lookAtPixel.X, self.lookAtPixel.Y
	for i, v in pairs(elements) do
		local minPt = v.AbsolutePosition
		local maxPt = v.AbsolutePosition + v.AbsoluteSize
		if minPt.X <= x and maxPt.X >= x and
		   minPt.Y <= y and maxPt.Y >= y then
			return v, i
		end
	end
end
--End of panel accessor methods


--Panel update methods
function Panel:SetPartCFrame(cframe)
	self:GetPart().CFrame = cframe * CFrame.new(0, 0, -0.5 * partThickness)
end

function Panel:SetEnabled(enabled)
	if self.isEnabled == enabled then
		return
	end

	self.isEnabled = enabled
	if enabled then
		self:GetPart().Parent = workspace.CurrentCamera --todo: Perhaps this can change soon.
		self:GetGUI().Enabled = true
		for i, v in pairs(self.subpanels) do
			v:GetPart().Parent = workspace.CurrentCamera
			v:GetGUI().Enabled = true
		end
	else
		self:GetPart().Parent = nil
		self:GetGUI().Enabled = false
		for i, v in pairs(self.subpanels) do
			v:GetPart().Parent = nil
			v:GetGUI().Enabled = false
		end
	end

	self:OnEnabled(enabled)
end

function Panel:EvaluatePositioning(cameraCF, cameraRenderCF, userHeadCF)
	if self.panelType == Panel3D.Type.Floor then
		--Floor panels simply... go on the floor.
		--Panel will be in camera's local space (which is assumed to be horizontal),
		--and floorRotation is derived from the user's head rotation (yaw only)
		local floorCF = cameraCF * CFrame.new(0, -headHeightFromFloor * currentHeadScale, 0) * floorRotation
		self:SetPartCFrame(floorCF * pointUpCF)
	elseif self.panelType == Panel3D.Type.Fixed then
		--Places the panel in the camera's local space, but doesn't follow the user's head.
		--Useful if you know what you're doing. localCF can be updated in PreUpdate for animation.
		local cf = self.localCF - self.localCF.p
		cf = cf + (self.localCF.p * currentHeadScale)
		self:SetPartCFrame(cameraCF * cf)
	elseif self.panelType == Panel3D.Type.HorizontalFollow then
		local headLook = userHeadCF.lookVector
		local headYaw = math.atan2(-headLook.Z, headLook.X) + math.rad(90)
		local headForwardCF = CFrame.Angles(0, headYaw, 0) + userHeadCF.p
		local localCF = (headForwardCF * self.angleFromForward) * --Rotate about Y (left-right)
						self.angleFromHorizon * --Rotate about X (up-down)
						(currentHeadScale * self.distance) * --Move into scene
						turnAroundCF --Turn around to face character
		self:SetPartCFrame(cameraCF * localCF)
	elseif self.panelType == Panel3D.Type.FixedToHead then
		--Places the panel in the user's head local space. localCF can be updated in PreUpdate for animation.
		local cf = self.localCF - self.localCF.p
		cf = cf + (self.localCF.p * currentHeadScale)
		self:SetPartCFrame(cameraRenderCF * cf)
	end
end

function Panel:EvaluateGaze(cameraCF, cameraRenderCF, userHeadCF, lookRay)
	--reset distance data
	self.isClosest = false
	self.lookAtPixel = zeroVector2
	self.lookAtDistance = math.huge

	--Evaluate the lookRay versus this panel
	local planeCF = self:GetPart().CFrame
	local planeNormal = planeCF.lookVector
	local pointOnPlane = planeCF.p + (planeNormal * partThickness * 0.5) --Move the point out by half the thickness of the part

	local worldIntersectPoint = Util.RayPlaneIntersection(lookRay, planeNormal, pointOnPlane)
	if worldIntersectPoint then
		self.isOffscreen = false

		--transform worldIntersectPoint to gui space
		local gui = self:GetGUI()
		local guiWidth, guiHeight = gui.AbsoluteSize.X, gui.AbsoluteSize.Y
		local localIntersectPoint = (planeCF:pointToObjectSpace(worldIntersectPoint) / currentHeadScale) * Vector3.new(-1, 1, 1) + Vector3.new(self.width / 2, -self.height / 2, 0)
		self.lookAtPixel = Vector2.new((localIntersectPoint.X / self.width) * gui.AbsoluteSize.X, (localIntersectPoint.Y / self.height) * -gui.AbsoluteSize.Y)
		
		--fire mouse enter/leave events if necessary
		local guiX, guiY = self.lookAtPixel.X, self.lookAtPixel.Y
		if guiX >= 0 and guiX <= guiWidth and
		   guiY >= 0 and guiY <= guiHeight then
		   	if not self.isLookedAt then
				self.isLookedAt = true
				self:OnMouseEnter(guiX, guiY)
				if self.forceShowUntilLookedAt then
					self.forceShowUntilLookedAt = false
				end
			end
		else
			if self.isLookedAt then
				self.isLookedAt = false
				self:OnMouseLeave(guiX, guiY)
			end
		end

		--evaluate distance
		self.lookAtDistance = (worldIntersectPoint - cameraRenderCF.p).magnitude
		if self.isLookedAt and self.lookAtDistance < currentMaxDist and self.showCursor then
			currentMaxDist = self.lookAtDistance
			currentClosest = self
		end
	else
		self.isOffscreen = true

		--Not looking at the plane at all, so fire off mouseleave if necessary.
		if self.isLookedAt then
			self.isLookedAt = false
			self:OnMouseLeave(self.lookAtPixel.X, self.lookAtPixel.Y)
		end
	end
end

function Panel:EvaluateTransparency()
	--Early exit if force shown
	if self.forceShowUntilLookedAt then
		self.transparency = 0
		return
	end
	--Early exit if we're looking at the panel (no transparency!)
	if self.isLookedAt then
		self.transparency = 0
		return
	end
	--Similarly, exit if we can't possibly see the panel.
	if self.isOffscreen then
		self.transparency = 1
		return
	end
	--Otherwise, we'll want to calculate the transparency.
	self.transparency = self:CalculateTransparency()
end

function Panel:Update(cameraCF, cameraRenderCF, userHeadCF, lookRay)
	if self.forceShowUntilLookedAt and not self.part then
		self:GetPart()
		self:GetGUI()
	end
	if not self.part then
		return
	end

	local isModal = (currentModal == self)
	if not isModal and self.linkedTo and self.linkedTo == currentModal then
		isModal = true
	end
	if currentModal and not isModal then
		self:SetEnabled(false)
		return
	end

	self:PreUpdate(cameraCF, cameraRenderCF, userHeadCF, lookRay)
	if self.isVisible then
		self:EvaluatePositioning(cameraCF, cameraRenderCF, userHeadCF)
		self:EvaluateGaze(cameraCF, cameraRenderCF, userHeadCF, lookRay)

		self:EvaluateTransparency(cameraCF, cameraRenderCF)
	end
end
--End of Panel update methods

--Panel virtual methods
function Panel:PreUpdate() --virtual: handle positioning here
end

function Panel:OnUpdate() --virtual: handle transparency here
end

function Panel:OnMouseEnter(x, y) --virtual
end

function Panel:OnMouseLeave(x, y) --virtual
end

function Panel:OnEnabled(enabled) --virtual
end

function Panel:OnModalChanged(isModal) --virtual
end

function Panel:OnVisibilityChanged(visible) --virtual
end

function Panel:CalculateTransparency() --virtual
	if not self.canFade then
		return 0
	end

	local guiWidth, guiHeight = self.gui.AbsoluteSize.X, self.gui.AbsoluteSize.Y
	local lookX, lookY = self.lookAtPixel.X, self.lookAtPixel.Y

	--Determine the distance from the edge; 
	--if x is negative it's on the left side, meaning the distance is just absolute value
	--if x is positive it's on the right side, meaning the distance is x minus the width
	local xEdgeDist = lookX < 0 and -lookX or (lookX - guiWidth)
	local yEdgeDist = lookY < 0 and -lookY or (lookY - guiHeight)
	if lookX > 0 and lookX < guiWidth then
		xEdgeDist = 0
	end
	if lookY > 0 and lookY < guiHeight then
		yEdgeDist = 0
	end
	local edgeDist = math.sqrt(xEdgeDist ^ 2 + yEdgeDist ^ 2)

	--since transparency is 0-1, we know how many pixels will give us 0 and how many will give us 1.
	local offset = fullyOpaqueAtPixelsFromEdge
	local interval = fullyTransparentAtPixelsFromEdge
	--then we just clamp between 0 and 1.
	return math.max(0, math.min(1, (edgeDist - offset) / interval))
end
--End of Panel virtual methods


--Panel configuration methods
function Panel:ResizeStuds(width, height, pixelsPerStud)
	pixelsPerStud = pixelsPerStud or defaultPixelsPerStud

	self.width = width
	self.height = height

	self.pixelScale = pixelsPerStud / defaultPixelsPerStud

	local part = self:GetPart()
	part.Size = Vector3.new(self.width * currentHeadScale, self.height * currentHeadScale, partThickness)

	local gui = self:GetGUI()
	gui.CanvasSize = Vector2.new(pixelsPerStud * self.width, pixelsPerStud * self.height)
end

function Panel:ResizePixels(width, height, pixelsPerStud)
	pixelsPerStud = pixelsPerStud or defaultPixelsPerStud

	local widthInStuds = width / pixelsPerStud
	local heightInStuds = height / pixelsPerStud
	self:ResizeStuds(widthInStuds, heightInStuds, pixelsPerStud)
end

function Panel:OnHeadScaleChanged(newHeadScale)
	local pixelsPerStud = self.pixelScale * defaultPixelsPerStud
	self:ResizeStuds(self.width, self.height, pixelsPerStud)
end

function Panel:SetType(panelType, config)
	self.panelType = panelType

	--clear out old type-specific members
	self.floorPos = nil

	self.localCF = nil

	self.angleFromHorizon = nil
	self.angleFromForward = nil
	self.distance = nil

	if not config then
		config = {}
	end

	if panelType == Panel3D.Type.None then
		--nothing to do
		return
	elseif panelType == Panel3D.Type.Floor then
		self.floorPos = config.FloorPosition or Vector3.new(0, 0, 0)
	elseif panelType == Panel3D.Type.Fixed then
		self.localCF = config.CFrame or CFrame.new()
	elseif panelType == Panel3D.Type.HorizontalFollow then
		self.angleFromHorizon = CFrame.Angles(config.angleFromHorizon or 0, 0, 0)
		self.angleFromForward = CFrame.Angles(0, config.angleFromForward or 0, 0)
		self.distance = CFrame.new(0, 0, config.distance or 5)
	elseif panelType == Panel3D.Type.FixedToHead then
		self.localCF = config.CFrame or CFrame.new()
	else
		error("Invalid Panel type")
	end
end

function Panel:SetVisible(visible, modal)
	if visible ~= self.isVisible then
		self:OnVisibilityChanged(visible)
		if not visible then
			Panel3D.OnPanelClosed:Fire(self.name)
		end
	end

	self.isVisible = visible
	self:SetEnabled(visible)
	if visible and modal then
		Panel3D.SetModalPanel(self)
	end
	if not visible and currentModal == self then
		if modal and not doNotRestore then
			--restore last modal panel
			Panel3D.SetModalPanel(lastModal)
		else
			Panel3D.SetModalPanel(nil)

			--if the coder explicitly wanted to hide this modal panel,
			--it follows that they don't want it to be restored when the next
			--modal panel is hidden.
			if lastModal == self then
				lastModal = nil
			end
		end
	end

	if not visible and self.forceShowUntilLookedAt then
		self.forceShowUntilLookedAt = false
	end
end

function Panel:LinkTo(panelName)
	if type(panelName) == "string" then
		self.linkedTo = Panel3D.Get(panelName)
	else
		self.linkedTo = panelName
	end
end

function Panel:ForceShowUntilLookedAt(makeModal)
	--ensure the part exists
	self:GetPart()
	self:GetGUI()

	self:SetVisible(true, makeModal)
	self.forceShowUntilLookedAt = true
end

function Panel:SetCanFade(canFade)
	self.canFade = canFade
end

--Child class, Subpanel
local Subpanel = {}
local Subpanel_mt = {}
function Subpanel.new(guiElement)
	local instance = {
		guiElement = guiElement
	}
	return setmetatable(instance, Subpanel_mt)
end

function Subpanel:GetPart()
	warn("Subpanel:GetPart() not yet implemented")
	return nil
end

function Subpanel:GetGUI()
	warn("Subpanel:GetGUI() not yet implemented")
	return nil
end

function Panel:AddSubpanel(guiElement)
	local subpanel = Subpanel.new(guiElement)
	self.subpanels[guiElement] = subpanel
end

function Panel:RemoveSubpanel(guiElement)
	self.subpanels[guiElement] = nil
end
--End of Panel configuration methods
--End of Panel class implementation


--Panel3D API
function Panel3D.Get(name)
	local panel = panels[name] 
	if not panels[name] then
		panels[name] = Panel.new(name)
		panel = panels[name]
	end
	return panel
end
--End of Panel3D API


--Panel3D Setup
local function onRenderStep()
	if not UserInputService.VREnabled then
		return
	end
	

	--reset distance info
	currentClosest = nil
	currentMaxDist = math.huge

	--figure out some useful stuff
	local camera = workspace.CurrentCamera
	local cameraCF = camera.CFrame
	local cameraRenderCF = camera:GetRenderCFrame()
	local userHeadCF = UserInputService:GetUserCFrame(Enum.UserCFrame.Head)
	local lookRay = Ray.new(cameraRenderCF.p, cameraRenderCF.lookVector)

	--allow all panels to run their own update code
	for i, v in pairs(panels) do
		v:Update(cameraCF, cameraRenderCF, userHeadCF, lookRay)
	end

	--evaluate linked panels
	local processed = {}
	for i, v in pairs(panels) do
		if not processed[v] and v.linkedTo and v.isVisible and v.linkedTo.isVisible then
			processed[v] = true
			processed[v.linkedTo] = true

			local minTransparency = math.min(v.transparency, v.linkedTo.transparency)
			v.transparency = minTransparency
			v.linkedTo.transparency = minTransparency
		end
	end

	--run post update because the distance information hasn't been
	--finalized until now.
	for i, v in pairs(panels) do
		--If the part is fully transparent, we don't want to keep it around in the workspace.
		if v.part and v.gui then
			--check if this panel is the current modal panel
			local isModal = (currentModal == v)
			--but also check if this panel is linked to the current modal panel
			if not isModal and v.linkedTo and v.linkedTo == currentModal then
				isModal = true
			end

			local show = v.isVisible
			if not isModal and currentModal then
				show = false
			end
			if v.transparency >= 1 then
				show = false
			end

			if v.forceShowUntilLookedAt then
				show = true
			end
			if not v.canFade and v.isVisible then
				show = true
			end
			
			v:SetEnabled(show)
		end

		v:OnUpdate()
	end

	--place the cursor on the closest panel (for now)
	if not currentClosest and lastClosest then
		UserInputService.MouseBehavior = lastMouseBehavior
	elseif currentClosest and not lastClosest then
		lastMouseBehavior = UserInputService.MouseBehavior
	end

	if currentClosest then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.ForceHide
		cursor.Parent = currentClosest:GetGUI()

		local x, y = currentClosest.lookAtPixel.X, currentClosest.lookAtPixel.Y
		cursor.Size = UDim2.new(0, 8 * currentClosest.pixelScale, 0, 8 * currentClosest.pixelScale)
		cursor.Position = UDim2.new(0, x - cursor.AbsoluteSize.x * 0.5, 0, y - cursor.AbsoluteSize.y * 0.5)
	else
		cursor.Parent = nil
	end
	lastClosest = currentClosest
end
RunService:BindToRenderStep(renderStepName, Enum.RenderPriority.Last.Value, onRenderStep)

--Implement cursor autohide functionality
UserInputService.InputChanged:connect(function(inputObj, processed)
	if inputObj.UserInputType == Enum.UserInputType.MouseMovement then
		lastMouseActivity = tick()
		autoHideCursor(false)
	end
end)
local function onHeartbeat()
	if isCursorVisible() then
		cursorHidden = false
	end
	if lastMouseActivity + cursorHideTime < tick() and not GuiService.MenuIsOpen and not cursorHidden then
		autoHideCursor(true)
	end
end
RunService.Heartbeat:connect(onHeartbeat)

--Handle camera changes
local cameraChangedConnection = nil
local function onCameraChanged(prop)
	if prop == "HeadScale" then
		pcall(function()
			currentHeadScale = workspace.CurrentCamera.HeadScale
		end)
		for i, v in pairs(panels) do
			v:OnHeadScaleChanged(currentHeadScale)
		end
	end
end

local function onWorkspaceChanged(prop)
	if prop == "CurrentCamera" then
		onCameraChanged("HeadScale")
		if cameraChangedConnection then
			cameraChangedConnection:disconnect()
		end
		cameraChangedConnection = workspace.CurrentCamera.Changed:connect(onCameraChanged)
	end
end
if workspace.CurrentCamera then
	onWorkspaceChanged("CurrentCamera")
end
workspace.Changed:connect(onWorkspaceChanged)

return Panel3D