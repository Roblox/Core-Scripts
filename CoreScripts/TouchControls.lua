-- This is responsible for all touch controls we show (as of this writing, only on iOS)
-- this includes character move thumbsticks, and buttons for jump, use of items, camera, etc.
-- Written by Ben Tkacheff/Jason Roth, Copyright Roblox 2014
local UserInputService = game:GetService('UserInputService')
local GuiService = game:GetService('GuiService')
local Players = game:GetService('Players')

local success = pcall(function() UserInputService:IsLuaTouchControls() end)
if not success then
	script:Destroy()
end

--[[ Variables ]]--
local CoreGui = game:WaitForChild('CoreGui')
local RobloxGui = CoreGui:WaitForChild('RobloxGui')
local ScreenResolution = GuiService:GetScreenResolution()

local function isSmallScreenDevice()
	return ScreenResolution.y <= 500
end

local GameSettings = UserSettings().GameSettings
local Player = nil
while not Players.LocalPlayer do wait() end
Player = Players.LocalPlayer

--[[ Constants ]]--
local CAMERA_ZOOM_SENSITIVITY = 0.03
local CAMERA_ROTATE_SENSITIVITY = 0.007
local JUMP_BUTTON_SIZE = isSmallScreenDevice() and 70 or 90
local THUMBSTICK_SIZE = isSmallScreenDevice() and 70 or 120

--[[ Images ]]--
local TOUCH_CONTROL_SHEET = "rbxasset://textures/ui/TouchControlsSheet.png"
local DPAD_SHEET = "rbxasset://textures/ui/DPadSheet.png"

----------------------------------------------------------------------------
----------------------------------------------------------------------------
--
-- Helper Functions
--
-- used to create arrows for both dpad and new controls
local function createArrowLabel(name, parent, pos, size, spOffset, spSize)
	local arrow = Instance.new('ImageLabel')
	arrow.Name = name
	arrow.Image = DPAD_SHEET
	arrow.ImageRectOffset = spOffset
	arrow.ImageRectSize = spSize
	arrow.BackgroundTransparency = 1
	arrow.Size = size
	arrow.Position = pos
	arrow.Parent = parent
	
	return arrow
end

local function createControlFrame(name, position, size)
	local frame = Instance.new('Frame')
	frame.Name = name
	frame.Active = true
	frame.Size = UDim2.new(0, size, 0, size)
	frame.Position = position
	frame.BackgroundTransparency = 1
	
	return frame
end

local function createOuterImage(name, position, parent)
	local image = Instance.new('ImageLabel')
	image.Name = name
	image.Image = TOUCH_CONTROL_SHEET
	image.ImageRectOffset = Vector2.new(0, 0)
	image.ImageRectSize = Vector2.new(220, 220)
	image.BackgroundTransparency = 1
	image.Size = UDim2.new(0, THUMBSTICK_SIZE, 0, THUMBSTICK_SIZE)
	image.Position = position
	image.Parent = parent
	
	return image
end

----------------------------------------------------------------------------
----------------------------------------------------------------------------
--
-- Jump Controls
--
local JumpButton = nil
local JumpTouchObject = nil
local function setupJumpButton(parentFrame)
	if not JumpButton then
		JumpButton = Instance.new('ImageButton')
		JumpButton.Name = "JumpButton"
		JumpButton.BackgroundTransparency = 1
		JumpButton.Image = TOUCH_CONTROL_SHEET
		JumpButton.ImageRectOffset = Vector2.new(176, 222)
		JumpButton.ImageRectSize = Vector2.new(174, 174)
		JumpButton.Size = UDim2.new(0, JUMP_BUTTON_SIZE, 0, JUMP_BUTTON_SIZE)
		if isSmallScreenDevice() then
			JumpButton.Position = UDim2.new(1, JUMP_BUTTON_SIZE * -2.25, 1, -JUMP_BUTTON_SIZE - 20)
		else
			JumpButton.Position = UDim2.new(1, JUMP_BUTTON_SIZE * -2.75, 1, -JUMP_BUTTON_SIZE - 120)
		end
		
		local playerJump_func = Player.JumpCharacter
		local doJumpLoop = function()
			while JumpTouchObject do
				if Player then
					playerJump_func(Player)
				end
				wait(1/60)
			end
		end
		
		JumpButton.InputBegan:connect(function(inputObject)
			if inputObject.UserInputType ~= Enum.UserInputType.Touch or JumpTouchObject then
				return
			end
			
			JumpTouchObject = inputObject
			JumpButton.ImageRectOffset = Vector2.new(0, 222)
			doJumpLoop()
		end)
		
		JumpButton.InputEnded:connect(function(inputObject)
			if inputObject.UserInputType ~= Enum.UserInputType.Touch then return end
			if inputObject == JumpTouchObject then
				JumpTouchObject = nil
				JumpButton.ImageRectOffset = Vector2.new(176, 222)
			end
		end)
		
		JumpButton.Parent = parentFrame
		JumpButton.Visible = not UserInputService.ModalEnabled
	end
end

----------------------------------------------------------------------------
----------------------------------------------------------------------------
--
-- Thumbstick Controls
--
local ThumbstickFrame = nil
local IsFollowStick = true
local function setupThumbstick(parentFrame)
	if ThumbstickFrame then return end
	
	local isSmallScreen = isSmallScreenDevice()
	local position = isSmallScreen and UDim2.new(0, (THUMBSTICK_SIZE/2) - 10, 1, -THUMBSTICK_SIZE - 20) or
		UDim2.new(0, THUMBSTICK_SIZE/2, 1, -THUMBSTICK_SIZE * 1.75)
		
	ThumbstickFrame = createControlFrame("ThumbstickFrame", position, THUMBSTICK_SIZE)
	local outerImage = createOuterImage("OuterImage", UDim2.new(0, 0, 0, 0), ThumbstickFrame)
	
	local innerImage = Instance.new('ImageLabel')
	innerImage.Name = "InnerImage"
	innerImage.Image = TOUCH_CONTROL_SHEET
	innerImage.ImageRectOffset = Vector2.new(220, 0)
	innerImage.ImageRectSize = Vector2.new(111, 111)
	innerImage.BackgroundTransparency = 1
	innerImage.Size = UDim2.new(0, THUMBSTICK_SIZE/2, 0, THUMBSTICK_SIZE/2)
	innerImage.Position = UDim2.new(0, ThumbstickFrame.Size.X.Offset/2 - THUMBSTICK_SIZE/4, 0, ThumbstickFrame.Size.Y.Offset/2 - THUMBSTICK_SIZE/4)
	innerImage.ZIndex = 2
	innerImage.Parent = ThumbstickFrame
	
	local centerPosition = nil
	local deadZone = 0.05
	local function doMove(direction)
		local inputAxis = direction / (THUMBSTICK_SIZE/2)
		
		-- Scaled Radial Dead Zone
		local inputAxisMagnitude = inputAxis.magnitude
		if inputAxisMagnitude < deadZone then
			inputAxis = Vector3.new()
		else
			inputAxis = inputAxis.unit * ((inputAxisMagnitude - deadZone) / (1 - deadZone))
			-- NOTE: Making this a unit vector will cause the player to instantly go max speed
			inputAxis = Vector3.new(inputAxis.x, 0, inputAxis.y)
		end
		
		if Player then
			Player:Move(inputAxis, true)
		end
	end
	
	local function moveStick(position)
		local relativePosition = Vector2.new(position.x - centerPosition.x, position.y - centerPosition.y)
		local length = relativePosition.magnitude
		local maxLength = ThumbstickFrame.AbsoluteSize.x/2
		if IsFollowStick and length > maxLength then
			local offset = relativePosition.unit * maxLength
			ThumbstickFrame.Position = UDim2.new(
				0, position.x - ThumbstickFrame.AbsoluteSize.x/2 - offset.x,
				0, position.y - ThumbstickFrame.AbsoluteSize.y/2 - offset.y)
		else
			length = math.min(length, maxLength)
			relativePosition = relativePosition.unit * length
		end
		innerImage.Position = UDim2.new(0, relativePosition.x + innerImage.AbsoluteSize.x/2, 0, relativePosition.y + innerImage.AbsoluteSize.y/2)
	end
	
	-- input connections
	local moveTouchObject = nil
	ThumbstickFrame.InputBegan:connect(function(inputObject)
		if moveTouchObject or inputObject.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		
		moveTouchObject = inputObject
		ThumbstickFrame.Position = UDim2.new(0, inputObject.Position.x - ThumbstickFrame.Size.X.Offset/2, 0, inputObject.Position.y - ThumbstickFrame.Size.Y.Offset/2)
		centerPosition = Vector2.new(ThumbstickFrame.AbsolutePosition.x + ThumbstickFrame.AbsoluteSize.x/2,
			ThumbstickFrame.AbsolutePosition.y + ThumbstickFrame.AbsoluteSize.y/2)
		local direction = Vector2.new(inputObject.Position.x - centerPosition.x, inputObject.Position.y - centerPosition.y)
		moveStick(inputObject.Position)
	end)
	
	UserInputService.TouchMoved:connect(function(inputObject, isProcessed)
		if inputObject == moveTouchObject then
			centerPosition = Vector2.new(ThumbstickFrame.AbsolutePosition.x + ThumbstickFrame.AbsoluteSize.x/2,
				ThumbstickFrame.AbsolutePosition.y + ThumbstickFrame.AbsoluteSize.y/2)
			local direction = Vector2.new(inputObject.Position.x - centerPosition.x, inputObject.Position.y - centerPosition.y)
			doMove(direction)
			moveStick(inputObject.Position)
		end
	end)
	
	UserInputService.TouchEnded:connect(function(inputObject, isProcessed)
		if inputObject == moveTouchObject then
			ThumbstickFrame.Position = position
			innerImage.Position = UDim2.new(0, ThumbstickFrame.Size.X.Offset/2 - THUMBSTICK_SIZE/4, 0, ThumbstickFrame.Size.Y.Offset/2 - THUMBSTICK_SIZE/4)
			moveTouchObject = nil
			if Player then
				Player:Move(Vector3.new(), true)
			end
		end
	end)
	
	ThumbstickFrame.Parent = parentFrame
end

----------------------------------------------------------------------------
----------------------------------------------------------------------------
--
-- DPad Control
--
local DPadFrame = nil
local function setupDPadControls(parentFrame)
	if DPadFrame then return end
	
	local position = UDim2.new(0, 10, 1, -230)
	DPadFrame = createControlFrame("DPadFrame", position, 192)
	
	local smArrowSize = UDim2.new(0, 23, 0, 23)
	local lgArrowSize = UDim2.new(0, 64, 0, 64)
	local smImgOffset = Vector2.new(46, 46)
	local lgImgOffset = Vector2.new(128, 128)
	
	local bBtn = createArrowLabel("BackButton", DPadFrame, UDim2.new(0.5, -32, 1, -64), lgArrowSize, Vector2.new(0, 0), lgImgOffset)
	local fBtn = createArrowLabel("ForwardButton", DPadFrame, UDim2.new(0.5, -32, 0, 0), lgArrowSize, Vector2.new(0, 258), lgImgOffset)
	local lBtn = createArrowLabel("LeftButton", DPadFrame, UDim2.new(0, 0, 0.5, -32), lgArrowSize, Vector2.new(129, 129), lgImgOffset)
	local rBtn = createArrowLabel("RightButton", DPadFrame, UDim2.new(1, -64, 0.5, -32), lgArrowSize, Vector2.new(0, 129), lgImgOffset)
	local jumpBtn = createArrowLabel("JumpButton", DPadFrame, UDim2.new(0.5, -32, 0.5, -32), lgArrowSize, Vector2.new(129, 0), lgImgOffset)
	local flBtn = createArrowLabel("ForwardLeftButton", DPadFrame, UDim2.new(0, 35, 0, 35), smArrowSize, Vector2.new(129, 258), smImgOffset)
	local frBtn = createArrowLabel("ForwardRightButton", DPadFrame, UDim2.new(1, -55, 0, 35), smArrowSize, Vector2.new(176, 258), smImgOffset)
	flBtn.Visible = false
	frBtn.Visible = false
	
	-- input connections
	local playerJump_func = Player.JumpCharacter
	jumpBtn.InputBegan:connect(function(inputObject)
		playerJump_func(Player)
	end)
	
	local compassDir = {
		Vector3.new(1, 0, 0),			-- E
		Vector3.new(1, 0, 1).unit,		-- SE
		Vector3.new(0, 0, 1),			-- S
		Vector3.new(-1, 0, 1).unit,		-- SW
		Vector3.new(-1, 0, 0),			-- W
		Vector3.new(-1, 0, -1).unit,	-- NW
		Vector3.new(0, 0, -1),			-- N
		Vector3.new(1, 0, -1).unit,		-- NE
	}
	local movementVector = Vector3.new(0, 0, 0)
	local function setDirection(inputPosition)
		local jumpRadius = jumpBtn.AbsoluteSize.x/2
		local centerPos = Vector2.new(DPadFrame.AbsolutePosition.x + DPadFrame.AbsoluteSize.x/2, DPadFrame.AbsolutePosition.y + DPadFrame.AbsoluteSize.y/2)
		local direction = Vector2.new(inputPosition.x - centerPos.x, inputPosition.y - centerPos.y)
		
		if direction.magnitude > jumpRadius then
			local angle = math.atan2(direction.y, direction.x)
			local octant = (math.floor(8 * angle / (2 * math.pi) + 8.5)%8) + 1
			movementVector = compassDir[octant]
		end
		
		if not flBtn.Visible and movementVector == compassDir[7] then
			flBtn.Visible = true
			frBtn.Visible = true
		end
	end
	
	local moveTouchObject = nil
	local endStep = 0.1
	local function endMoveFunc()
		flBtn.Visible = false
		frBtn.Visible = false
		
		spawn(function()
			while not moveTouchObject and movementVector.magnitude ~= 0 do
				local newX = movementVector.x
				local newZ = movementVector.y
				
				if movementVector.x > 0 then
					newX = movementVector.x - endStep
					if newX < 0 then newX = 0 end
				elseif movementVector.x < 0 then
					newX = movementVector.x + endStep
					if newX > 0 then newX = 0 end
				end
				
				if movementVector.z > 0 then
					newZ = movementVector.z - endStep
					if newZ < 0 then newZ = 0 end
				elseif movementVector.z < 0 then
					newZ = movementVector.z + endStep
					if newZ > 0 then newZ = 0 end
				end
				
				movementVector = Vector3.new(newX, 0, newZ)
				Player:Move(movementVector, true)
				wait()
			end
			
			if movementVector.magnitude ~= 0 then
				movementVector = Vector3.new(0, 0, 0)
				Player:Move(movementVector, true)
			end
		end)
	end
	
	DPadFrame.InputBegan:connect(function(inputObject)
		if moveTouchObject or inputObject.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		
		moveTouchObject = inputObject
		setDirection(inputObject.Position)
		Player:Move(movementVector, true)
	end)
	
	DPadFrame.InputChanged:connect(function(inputObject)
		if inputObject == moveTouchObject then
			setDirection(inputObject.Position)
			Player:Move(movementVector, true)
		end
	end)
	
	DPadFrame.InputEnded:connect(function(inputObject)
		if inputObject == moveTouchObject then
			moveTouchObject = nil
			endMoveFunc()
		end
	end)
	
	DPadFrame.Parent = parentFrame
end

----------------------------------------------------------------------------
----------------------------------------------------------------------------
--
-- New Thumbpad Controls
--
local ThumbpadFrame = nil
local function setupThumbpad(parentFrame)
	if ThumbpadFrame then return end
	
	local isSmallScreen = isSmallScreenDevice()
	local position = isSmallScreen and UDim2.new(0, THUMBSTICK_SIZE * 1.25, 1, -THUMBSTICK_SIZE - 20) or
		UDim2.new(0, THUMBSTICK_SIZE/2 - 10, 1, -THUMBSTICK_SIZE * 1.75 - 10)
	
	ThumbpadFrame = createControlFrame("ThumbpadFrame", position, THUMBSTICK_SIZE + 20)
	local outerImage = createOuterImage("OuterImage", UDim2.new(0, 10, 0, 10), ThumbpadFrame)
	
	-- arrow set up
	local smArrowSize = isSmallScreen and UDim2.new(0, 32, 0, 32) or UDim2.new(0, 64, 0, 64)
	local lgArrowSize = UDim2.new(0, smArrowSize.X.Offset * 2, 0, smArrowSize.Y.Offset * 2)
	local imgRectSize = Vector2.new(116, 116)
	local smImgOffset = isSmallScreen and -4 or -9
	local lgImgOffset = isSmallScreen and -28 or -55
	
	local dArrow = createArrowLabel("DownArrow", outerImage, UDim2.new(0.5, -smArrowSize.X.Offset/2, 1, lgImgOffset), smArrowSize, Vector2.new(6, 6), imgRectSize)
	local uArrow = createArrowLabel("UpArrow", outerImage, UDim2.new(0.5, -smArrowSize.X.Offset/2, 0, smImgOffset), smArrowSize, Vector2.new(6, 264), imgRectSize)
	local lArrow = createArrowLabel("LeftArrow", outerImage, UDim2.new(0, smImgOffset, 0.5, -smArrowSize.Y.Offset/2), smArrowSize, Vector2.new(135, 135), imgRectSize)
	local rArrow = createArrowLabel("RightArrow", outerImage, UDim2.new(1, lgImgOffset, 0.5, -smArrowSize.Y.Offset/2), smArrowSize, Vector2.new(6, 135), imgRectSize)
	
	local function doTween(guiObject, endSize, endPosition)
		guiObject:TweenSizeAndPosition(endSize, endPosition, Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0.15, true)
	end
	
	local padOrigin = nil
	local deadZone = 0.1	
	local isRight, isLeft, isUp, isDown = false, false, false, false
	local vForward = Vector3.new(0, 0, -1)
	local vRight = Vector3.new(1, 0, 0)
	local function doMove(pos)
		local delta = Vector2.new(pos.x, pos.y) - padOrigin
		local inputAxis = delta / (THUMBSTICK_SIZE/2)
		
		-- Scaled Radial Dead Zone
		local inputAxisMagnitude = inputAxis.magnitude
		if inputAxisMagnitude < deadZone then
			inputAxis = Vector3.new(0, 0, 0)
		else
			inputAxis = inputAxis.unit * ((inputAxisMagnitude - deadZone) / (1 - deadZone))
			inputAxis = Vector3.new(inputAxis.x, 0, inputAxis.y).unit
		end
		
		if Player then
			Player:Move(inputAxis, true)
		end
		
		local forwardDot = inputAxis:Dot(vForward)
		local rightDot = inputAxis:Dot(vRight)
		if forwardDot > 0.5 then		-- UP
			if not isUp then
				isUp, isDown = true, false
				doTween(uArrow, lgArrowSize, UDim2.new(0.5, -smArrowSize.X.Offset, 0, smImgOffset - smArrowSize.Y.Offset * 1.5))
				doTween(dArrow, smArrowSize, UDim2.new(0.5, -smArrowSize.X.Offset/2, 1, lgImgOffset))
			end
		elseif forwardDot < -0.5 then	-- DOWN
			if not isDown then
				isDown, isUp = true, false
				doTween(dArrow, lgArrowSize, UDim2.new(0.5, -smArrowSize.X.Offset, 1, lgImgOffset + smArrowSize.Y.Offset/2))
				doTween(uArrow, smArrowSize, UDim2.new(0.5, -smArrowSize.X.Offset/2, 0, smImgOffset))
			end
		else
			isUp, isDown = false, false
			doTween(dArrow, smArrowSize, UDim2.new(0.5, -smArrowSize.X.Offset/2, 1, lgImgOffset))
			doTween(uArrow, smArrowSize, UDim2.new(0.5, -smArrowSize.X.Offset/2, 0, smImgOffset))
		end
		
		if rightDot > 0.5 then
			if not isRight then
				isRight, isLeft = true, false
				doTween(rArrow, lgArrowSize, UDim2.new(1, lgImgOffset + smArrowSize.X.Offset/2, 0.5, -smArrowSize.Y.Offset))
				doTween(lArrow, smArrowSize, UDim2.new(0, smImgOffset, 0.5, -smArrowSize.Y.Offset/2))
			end
		elseif rightDot < -0.5 then
			if not isLeft then
				isLeft, isRight = true, false
				doTween(lArrow, lgArrowSize, UDim2.new(0, smImgOffset - smArrowSize.X.Offset * 1.5, 0.5, -smArrowSize.Y.Offset))
				doTween(rArrow, smArrowSize, UDim2.new(1, lgImgOffset, 0.5, -smArrowSize.Y.Offset/2))
			end
		else
			isRight, isLeft = false, false
			doTween(lArrow, smArrowSize, UDim2.new(0, smImgOffset, 0.5, -smArrowSize.Y.Offset/2))
			doTween(rArrow, smArrowSize, UDim2.new(1, lgImgOffset, 0.5, -smArrowSize.Y.Offset/2))
		end
	end
	
	--input connections
	local moveTouchObject = nil
	ThumbpadFrame.InputBegan:connect(function(inputObject)
		if moveTouchObject or inputObject.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		
		moveTouchObject = inputObject
		padOrigin = Vector2.new(ThumbpadFrame.AbsolutePosition.x + ThumbpadFrame.AbsoluteSize.x/2,
			ThumbpadFrame.AbsolutePosition.y + ThumbpadFrame.AbsoluteSize.y/2)
		doMove(inputObject.Position)
	end)
	
	UserInputService.InputChanged:connect(function(inputObject, isProcessed)
		if inputObject == moveTouchObject then
			doMove(inputObject.Position)
		end
	end)
	
	UserInputService.InputEnded:connect(function(inputObject)
		if inputObject == moveTouchObject then
			if Player then
				Player:Move(Vector3.new(), true)
			end
			moveTouchObject = nil
			isUp, isDown, isLeft, isRight = false, false, false, false
			doTween(dArrow, smArrowSize, UDim2.new(0.5, -smArrowSize.X.Offset/2, 1, lgImgOffset))
			doTween(uArrow, smArrowSize, UDim2.new(0.5, -smArrowSize.X.Offset/2, 0, smImgOffset))
			doTween(lArrow, smArrowSize, UDim2.new(0, smImgOffset, 0.5, -smArrowSize.Y.Offset/2))
			doTween(rArrow, smArrowSize, UDim2.new(1, lgImgOffset, 0.5, -smArrowSize.Y.Offset/2))
		end
	end)
	
	ThumbpadFrame.Parent = parentFrame
end

----------------------------------------------------------------------------
----------------------------------------------------------------------------
--
-- Movement Mode Setup/Config
--
local function configTouchControls()
	if UserInputService.ModalEnabled then
		JumpButton.Visible = false
		ThumbstickFrame.Visible = false
		ThumbpadFrame.Visible = false
		DPadFrame.Visible = false
	else
		local isThumbstickMode = false
		local isThumbpadMode = false
		local modeName = GameSettings.TouchMovementMode.Name
		
		-- TODO: Need option from c++, is called "Thumbpad"
		if modeName == "Default" or modeName == "Thumbstick" then
			isThumbstickMode = true
			isThumbpadMode = false
		elseif modeName == "Thumbpad" then
			isThumbstickMode = false
			isThumbpadMode = true
		else
			isThumbstickMode = false
			isThumbpadMode = false
		end
		
		JumpButton.Visible = isThumbstickMode or isThumbpadMode
		ThumbstickFrame.Visible = isThumbstickMode
		ThumbpadFrame.Visible = isThumbpadMode
		DPadFrame.Visible = not isThumbstickMode and not isThumbpadMode
	end
end

local function setupTouchControls()
	local touchControlFrame = Instance.new('Frame')
	touchControlFrame.Name = "TouchControlFrame"
	touchControlFrame.Size = UDim2.new(1, 0, 1, 0)
	touchControlFrame.BackgroundTransparency = 1
	touchControlFrame.Parent = RobloxGui
	
	setupJumpButton(touchControlFrame)
	setupThumbstick(touchControlFrame)
	setupDPadControls(touchControlFrame)
	setupThumbpad(touchControlFrame)	
	
	UserInputService.Changed:connect(function(property)
		if property == "ModalEnabled" then
			configTouchControls()
		end
	end)
	
	configTouchControls()
end

----------------------------------------------------------------------------
----------------------------------------------------------------------------
--
-- Camera Control
--
local CameraTouchObject = nil
local PinchTouchObject = nil
local LastCameraInputPosition = nil
local LastPinchScale = nil
local function onTouchStarted(inputObject, isProcessed)
	if isProcessed then return end
	
	if CameraTouchObject then
		PinchTouchObject = inputObject
	else
		CameraTouchObject = inputObject
		LastCameraInputPosition = inputObject.Position
	end
end

local function onTouchMoved(inputObject, isProcessed)
	-- pinch zoom
	if CameraTouchObject and PinchTouchObject then
		if not LastPinchScale then
			if inputObject == CameraTouchObject then
				LastPinchScale = (inputObject.Position - PinchTouchObject.Position).magnitude
			elseif inputObject == PinchTouchObject then
				LastPinchScale = (inputObject.Position - CameraTouchObject.Position).magnitude
			end
		else
			local newPinchScale = 0
			if inputObject == CameraTouchObject then
				newPinchScale = (inputObject.Position - PinchTouchObject.Position).magnitude
			elseif inputObject == PinchTouchObject then
				newPinchScale = (inputObject.Position - CameraTouchObject.Position).magnitude
			end
			if newPinchScale ~= 0 then
				local delta = newPinchScale - LastPinchScale
				if delta ~= 0 then
					UserInputService:ZoomCamera(delta * CAMERA_ZOOM_SENSITIVITY)
				end
				LastPinchScale = newPinchScale
			end
		end
	-- camera pan
	elseif inputObject == CameraTouchObject then
		local currentPosition = inputObject.Position
		if LastCameraInputPosition then
			local touchDelta = (LastCameraInputPosition - currentPosition) * CAMERA_ROTATE_SENSITIVITY
			UserInputService:RotateCamera(Vector2.new(touchDelta.x, touchDelta.y))
		end
		LastCameraInputPosition = currentPosition
	end
end

local function onTouchEnded(inputObject, isProcessed)
	if inputObject == CameraTouchObject then
		-- swap input objects
		if PinchTouchObject then
			CameraTouchObject = PinchTouchObject
			LastCameraInputPosition = CameraTouchObject.Position
			PinchTouchObject = nil
			LastPinchScale = nil
		else
			CameraTouchObject = nil
			LastCameraInputPosition = nil
		end
	elseif inputObject == PinchTouchObject then
		if CameraTouchObject then
			LastCameraInputPosition = CameraTouchObject.Position
		end
		PinchTouchObject = nil
		LastPinchScale = nil
	end
end

UserInputService.TouchStarted:connect(onTouchStarted)
UserInputService.TouchMoved:connect(onTouchMoved)
UserInputService.TouchEnded:connect(onTouchEnded)

if UserInputService:IsLuaTouchControls() then
	setupTouchControls()
else
	script:Destroy()
end

GameSettings.Changed:connect(function(property)
	if property == "TouchMovementMode" then
		configTouchControls()
	end
end)
