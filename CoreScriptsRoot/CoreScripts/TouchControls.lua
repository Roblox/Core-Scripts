-- This is responsible for all touch controls we show (as of this writing, only on iOS/Android)
-- this includes character move thumbsticks, and buttons for jump, use of items, camera, etc.
-- Written by Ben Tkacheff/Jason Roth, Copyright Roblox 2013

-- fast flag for new controls
local touchFlagExists, touchFlagValue = pcall(function () return settings():GetFFlag("NewTouchControlScript") end)
local hasNewTouchControls = touchFlagExists and touchFlagValue
if hasNewTouchControls then		-- NEW TOUCH CONTROLS WITH THUMBPAD
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
		local position = isSmallScreen and UDim2.new(0, THUMBSTICK_SIZE * 0.5 - 20, 1, -THUMBSTICK_SIZE - 30) or
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
		local deadZone = 0.5	
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
				-- catch possible NAN vector
				if inputAxis.magnitude == 0 then
					inputAxis = Vector3.new(0, 0, 0)
				else
					inputAxis = Vector3.new(inputAxis.x, 0, inputAxis.y).unit
				end
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
			if JumpTouchObject then
				JumpTouchObject = nil
			end
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
else	-- OLD TOUCH CONTROLS WITH THUMBPAD
	-- obligatory stuff to make sure we don't access nil data
	while not Game do
		wait()
	end
	while not Game:FindFirstChild("Players") do
		wait()
	end
	while not Game:GetService("Players").LocalPlayer do
		wait()
	end
	while not Game:FindFirstChild("CoreGui") do
		wait()
	end
	while not Game:GetService("CoreGui"):FindFirstChild("RobloxGui") do
		wait()
	end

	local userInputService = Game:GetService("UserInputService")
	local success = pcall(function() userInputService:IsLuaTouchControls() end)
	if not success then
		script:Destroy()
	end

	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	-- Variables
	local screenResolution = Game:GetService("GuiService"):GetScreenResolution()
	function isSmallScreenDevice()
		return screenResolution.y <= 500
	end

	local GameSettings = UserSettings().GameSettings

	local localPlayer = Game:GetService("Players").LocalPlayer

	local isInThumbstickMode = false

	local thumbstickInactiveAlpha = 0.3
	local thumbstickSize = 120
	if isSmallScreenDevice() then 
		thumbstickSize = 70
	end

	local touchControlsSheet = "rbxasset://textures/ui/TouchControlsSheet.png"
	local DPadSheet = "rbxasset://textures/ui/DPadSheet.png"
	local ThumbstickDeadZone = 5
	local ThumbstickMaxPercentGive = 0.92
	local thumbstickTouches = {}

	local jumpButtonSize = 90
	if isSmallScreenDevice() then 
		jumpButtonSize = 70
	end
	local oldJumpTouches = {}
	local currentJumpTouch = nil

	local CameraRotateSensitivity = 0.007
	local CameraRotateDeadZone = CameraRotateSensitivity * 16
	local CameraZoomSensitivity = 0.03
	local PinchZoomDelay = 0.2
	local cameraTouch = nil
	local dpadTouch = nil
	local thumbpadTouchObject = nil


	-- make sure all of our images are good to go
	Game:GetService("ContentProvider"):Preload(touchControlsSheet)
	Game:GetService("ContentProvider"):Preload(DPadSheet)

	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	-- Functions

	local isPointInRect = function(point, rectPos, rectSize)
		if point.x >= rectPos.x and point.x <= (rectPos.x + rectSize.x) then
			if point.y >= rectPos.y and point.y <= (rectPos.y + rectSize.y) then
				return true
			end
		end
		
		return false
	end


	--
	-- Thumbstick Control
	--

	function setCameraTouch(newTouch)
		cameraTouch = newTouch
		if newTouch == nil then
			pcall(function() userInputService.InCameraGesture = false end)
		else
			pcall(function() userInputService.InCameraGesture = true end)
		end
	end

	function DistanceBetweenTwoPoints(point1, point2)
		local dx = point2.x - point1.x
		local dy = point2.y - point1.y
		return math.sqrt( (dx*dx) + (dy*dy) )
	end

	function transformFromCenterToTopLeft(pointToTranslate, guiObject)
		return UDim2.new(0,pointToTranslate.x - guiObject.AbsoluteSize.x/2,0,pointToTranslate.y - guiObject.AbsoluteSize.y/2)
	end

	function rotatePointAboutLocation(pointToRotate, pointToRotateAbout, radians)
		local sinAnglePercent = math.sin(radians)
		local cosAnglePercent = math.cos(radians)
		
		local transformedPoint = pointToRotate
		
		-- translate point back to origin:
		transformedPoint = Vector2.new(transformedPoint.x - pointToRotateAbout.x, transformedPoint.y - pointToRotateAbout.y)
		
		-- rotate point
		local xNew = transformedPoint.x * cosAnglePercent - transformedPoint.y * sinAnglePercent
		local yNew = transformedPoint.x * sinAnglePercent + transformedPoint.y * cosAnglePercent
		
		-- translate point back:
		transformedPoint = Vector2.new(xNew + pointToRotateAbout.x, yNew + pointToRotateAbout.y)

		return transformedPoint
	end

	function dotProduct(v1,v2)
		return ((v1.x*v2.x) + (v1.y*v2.y))
	end

	function stationaryThumbstickTouchMove(thumbstickFrame, thumbstickOuter, touchLocation)
		local thumbstickOuterCenterPosition = Vector2.new(thumbstickOuter.Position.X.Offset + thumbstickOuter.AbsoluteSize.x/2, thumbstickOuter.Position.Y.Offset + thumbstickOuter.AbsoluteSize.y/2)
		local centerDiff = DistanceBetweenTwoPoints(touchLocation, thumbstickOuterCenterPosition)
		
		-- thumbstick is moving outside our region, need to cap its distance
		if centerDiff > (thumbstickSize/2) then
			local thumbVector = Vector2.new(touchLocation.x - thumbstickOuterCenterPosition.x,touchLocation.y - thumbstickOuterCenterPosition.y);
			local normal = thumbVector.unit
			if normal.x == math.nan or normal.x == math.inf then
				normal = Vector2.new(0,normal.y)
			end
			if normal.y == math.nan or normal.y == math.inf then
				normal = Vector2.new(normal.x,0)
			end
			
			local newThumbstickInnerPosition = thumbstickOuterCenterPosition + (normal * (thumbstickSize/2))
			thumbstickFrame.Position = transformFromCenterToTopLeft(newThumbstickInnerPosition, thumbstickFrame)
		else
			thumbstickFrame.Position = transformFromCenterToTopLeft(touchLocation,thumbstickFrame)
		end

		return Vector2.new(thumbstickFrame.Position.X.Offset - thumbstickOuter.Position.X.Offset,thumbstickFrame.Position.Y.Offset - thumbstickOuter.Position.Y.Offset)
	end

	function followThumbstickTouchMove(thumbstickFrame, thumbstickOuter, touchLocation)
		local thumbstickOuterCenter = Vector2.new(thumbstickOuter.Position.X.Offset + thumbstickOuter.AbsoluteSize.x/2, thumbstickOuter.Position.Y.Offset + thumbstickOuter.AbsoluteSize.y/2)
		
		-- thumbstick is moving outside our region, need to position outer thumbstick texture carefully (to make look and feel like actual joystick controller)
		if DistanceBetweenTwoPoints(touchLocation, thumbstickOuterCenter) > thumbstickSize/2 then
			local thumbstickInnerCenter = Vector2.new(thumbstickFrame.Position.X.Offset + thumbstickFrame.AbsoluteSize.x/2, thumbstickFrame.Position.Y.Offset + thumbstickFrame.AbsoluteSize.y/2)
			local movementVectorUnit = Vector2.new(touchLocation.x - thumbstickInnerCenter.x, touchLocation.y - thumbstickInnerCenter.y).unit

			local outerToInnerVectorCurrent = Vector2.new(thumbstickInnerCenter.x - thumbstickOuterCenter.x, thumbstickInnerCenter.y - thumbstickOuterCenter.y)
			local outerToInnerVectorCurrentUnit = outerToInnerVectorCurrent.unit
			local movementVector = Vector2.new(touchLocation.x - thumbstickInnerCenter.x, touchLocation.y - thumbstickInnerCenter.y)
			
			-- First, find the angle between the new thumbstick movement vector,
			-- and the vector between thumbstick inner and thumbstick outer.
			-- We will use this to pivot thumbstick outer around thumbstick inner, gives a nice joystick feel
			local crossOuterToInnerWithMovement = (outerToInnerVectorCurrentUnit.x * movementVectorUnit.y) - (outerToInnerVectorCurrentUnit.y * movementVectorUnit.x)
			local angle = math.atan2(crossOuterToInnerWithMovement, dotProduct(outerToInnerVectorCurrentUnit, movementVectorUnit))
			local anglePercent = angle * math.min( (movementVector.magnitude)/(outerToInnerVectorCurrent.magnitude), 1.0);
			
			-- If angle is significant, rotate about the inner thumbsticks current center
			if math.abs(anglePercent) > 0.00001 then
				local outerThumbCenter = rotatePointAboutLocation(thumbstickOuterCenter, thumbstickInnerCenter, anglePercent)
				thumbstickOuter.Position = transformFromCenterToTopLeft(Vector2.new(outerThumbCenter.x,outerThumbCenter.y), thumbstickOuter)
			end

			-- now just translate outer thumbstick to make sure it stays nears inner thumbstick
			thumbstickOuter.Position = UDim2.new(0,thumbstickOuter.Position.X.Offset+movementVector.x,0,thumbstickOuter.Position.Y.Offset+movementVector.y)
		end

		thumbstickFrame.Position = transformFromCenterToTopLeft(touchLocation,thumbstickFrame)

		-- a bit of error checking to make sure thumbsticks stay close to eachother
		thumbstickFramePosition = Vector2.new(thumbstickFrame.Position.X.Offset,thumbstickFrame.Position.Y.Offset)
		thumbstickOuterPosition = Vector2.new(thumbstickOuter.Position.X.Offset,thumbstickOuter.Position.Y.Offset)
		if DistanceBetweenTwoPoints(thumbstickFramePosition, thumbstickOuterPosition) > thumbstickSize/2 then
			local vectorWithLength = (thumbstickOuterPosition - thumbstickFramePosition).unit * thumbstickSize/2
			thumbstickOuter.Position = UDim2.new(0,thumbstickFramePosition.x + vectorWithLength.x,0,thumbstickFramePosition.y + vectorWithLength.y)
		end

		return Vector2.new(thumbstickFrame.Position.X.Offset - thumbstickOuter.Position.X.Offset,thumbstickFrame.Position.Y.Offset - thumbstickOuter.Position.Y.Offset)
	end

	function movementOutsideDeadZone(movementVector)
		return ( (math.abs(movementVector.x) > ThumbstickDeadZone) or (math.abs(movementVector.y) > ThumbstickDeadZone) )
	end

	function constructThumbstick(defaultThumbstickPos, updateFunction, stationaryThumbstick)
		local thumbstickFrame = Instance.new("Frame")
		thumbstickFrame.Name = "ThumbstickFrame"
		thumbstickFrame.Active = true
		thumbstickFrame.Size = UDim2.new(0,thumbstickSize,0,thumbstickSize)
		thumbstickFrame.Position = defaultThumbstickPos
		thumbstickFrame.BackgroundTransparency = 1

		local outerThumbstick = Instance.new("ImageLabel")
		outerThumbstick.Name = "OuterThumbstick"
		outerThumbstick.Image = touchControlsSheet
		outerThumbstick.ImageRectOffset = Vector2.new(0,0)
		outerThumbstick.ImageRectSize = Vector2.new(220,220)
		outerThumbstick.BackgroundTransparency = 1
		outerThumbstick.Size = UDim2.new(0,thumbstickSize,0,thumbstickSize)
		outerThumbstick.Position = defaultThumbstickPos
		outerThumbstick.Parent = Game:GetService("CoreGui").RobloxGui

		local innerThumbstick = Instance.new("ImageLabel")
		innerThumbstick.Name = "InnerThumbstick"
		innerThumbstick.Image = touchControlsSheet
		innerThumbstick.ImageRectOffset = Vector2.new(220,0)
		innerThumbstick.ImageRectSize = Vector2.new(111,111)
		innerThumbstick.BackgroundTransparency = 1
		innerThumbstick.Size = UDim2.new(0,thumbstickSize/2,0,thumbstickSize/2)
		innerThumbstick.Position = UDim2.new(0, thumbstickFrame.Size.X.Offset/2 - thumbstickSize/4, 0, thumbstickFrame.Size.Y.Offset/2 - thumbstickSize/4)
		innerThumbstick.Parent = thumbstickFrame
		innerThumbstick.ZIndex = 2

		local thumbstickTouch = nil
		local userInputServiceTouchMovedCon = nil
		local userInputSeviceTouchEndedCon = nil

		local startInputTracking = function(inputObject)
			if thumbstickTouch then return end
			if inputObject == cameraTouch then return end
			if inputObject == currentJumpTouch then return end
			if inputObject.UserInputType ~= Enum.UserInputType.Touch then return end

			thumbstickTouch = inputObject
			table.insert(thumbstickTouches,thumbstickTouch)

			thumbstickFrame.Position = transformFromCenterToTopLeft(thumbstickTouch.Position,thumbstickFrame)
			outerThumbstick.Position = thumbstickFrame.Position

			userInputServiceTouchMovedCon = userInputService.TouchMoved:connect(function(movedInput)
				if movedInput == thumbstickTouch then
					local movementVector = nil
					if stationaryThumbstick then
						movementVector = stationaryThumbstickTouchMove(thumbstickFrame,outerThumbstick,Vector2.new(movedInput.Position.x,movedInput.Position.y))
					else
						movementVector = followThumbstickTouchMove(thumbstickFrame,outerThumbstick,Vector2.new(movedInput.Position.x,movedInput.Position.y))
					end

					if updateFunction then
						updateFunction(movementVector,outerThumbstick.Size.X.Offset/2)
					end
				end
			end)
			userInputSeviceTouchEndedCon = userInputService.TouchEnded:connect(function(endedInput)
				if endedInput == thumbstickTouch then
					if updateFunction then
						updateFunction(Vector2.new(0,0),1)
					end

					userInputSeviceTouchEndedCon:disconnect()
					userInputServiceTouchMovedCon:disconnect()

					thumbstickFrame.Position = defaultThumbstickPos
					outerThumbstick.Position = defaultThumbstickPos

					for i, object in pairs(thumbstickTouches) do
						if object == thumbstickTouch then
							table.remove(thumbstickTouches,i)
							break
						end
					end
					thumbstickTouch = nil
				end
			end)
		end

		thumbstickFrame.Visible = not userInputService.ModalEnabled
		outerThumbstick.Visible = not userInputService.ModalEnabled

		thumbstickFrame.InputBegan:connect(startInputTracking)
		return thumbstickFrame, outerThumbstick
	end

	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	--
	-- DPad Control
	--

	function createDPadArrowButton(name, parent, position, size, image, spriteOffset, spriteSize)
		local DPadArrow = Instance.new("ImageButton")
		DPadArrow.Name = name
		DPadArrow.Image = image
		DPadArrow.ImageRectOffset = spriteOffset
		DPadArrow.ImageRectSize = spriteSize
		DPadArrow.BackgroundTransparency = 1
		DPadArrow.Size = size
		DPadArrow.Position = position
		DPadArrow.Parent = parent
		return DPadArrow
	end

	function createDPad()
		local DPadFrame = Instance.new("Frame")
		DPadFrame.Name = "DPadFrame"
		DPadFrame.Active = true
		DPadFrame.Size = UDim2.new(0,192,0,192)
		DPadFrame.Position = UDim2.new(0,10,1,-230)
		DPadFrame.BackgroundTransparency = 1

		-- local image = "rbxassetid://133293265"
		local image = DPadSheet
		local bigSize = UDim2.new(0,64,0,64)
		local smallSize = UDim2.new(0,23,0,23)
		local spriteSizeLarge = Vector2.new(128, 128)
		local spriteSizeSmall = Vector2.new(46, 46)

		createDPadArrowButton("BackButton", DPadFrame, UDim2.new(0.5, -32, 1, -64), bigSize, image, Vector2.new(0, 0), spriteSizeLarge)
		createDPadArrowButton("ForwardButton", DPadFrame, UDim2.new(0.5, -32, 0, 0), bigSize, image, Vector2.new(0, 258), spriteSizeLarge)
		createDPadArrowButton("JumpButton", DPadFrame, UDim2.new(0.5, -32, 0.5, -32), bigSize, image, Vector2.new(129, 0), spriteSizeLarge)
		createDPadArrowButton("LeftButton", DPadFrame, UDim2.new(0, 0, 0.5, -32), bigSize, image, Vector2.new(129,129), spriteSizeLarge)
		createDPadArrowButton("RightButton", DPadFrame, UDim2.new(1, -64, 0.5, -32), bigSize, image, Vector2.new(0, 129), spriteSizeLarge)
		createDPadArrowButton("forwardLeftButton", DPadFrame, UDim2.new(0, 35, 0, 35), smallSize, image, Vector2.new(129,258), spriteSizeSmall)
		createDPadArrowButton("forwardRightButton", DPadFrame, UDim2.new(1, -55, 0, 35), smallSize, image, Vector2.new(176,258), spriteSizeSmall)
		
		return DPadFrame
	end



		
	function setupDPadControls(DPadFrame)
		
		local moveCharacterFunc = localPlayer.MoveCharacter
		DPadFrame.JumpButton.InputBegan:connect(function(inputObject)
			localPlayer:JumpCharacter()
		end)
		local movementVector = Vector2.new(0,0)
		
		function setupButton(button,funcToCallBegin,funcToCallEnd)
			button.InputBegan:connect(function(inputObject)
				if not dpadTouch and inputObject.UserInputType == Enum.UserInputType.Touch and inputObject.UserInputState == Enum.UserInputState.Begin then
					dpadTouch = inputObject
					funcToCallBegin()
				end
			end)
			button.InputEnded:connect(function(inputObject)
				if dpadTouch == inputObject then
					if funcToCallEnd then
						funcToCallEnd()
					end
				end
			end)
		end
		
		local forwardButtonBegin = function()
			movementVector = Vector2.new(0,-1)
			moveCharacterFunc(localPlayer, Vector2.new(0,-1), 1)
			
			DPadFrame.forwardLeftButton.Visible = true
			DPadFrame.forwardRightButton.Visible = true
		end
		
		local backwardButtonBegin = function()
			movementVector = Vector2.new(0,1)
			moveCharacterFunc(localPlayer, Vector2.new(0,1),1)
		end
		
		local leftButtonBegin = function()
			movementVector = Vector2.new(-1,0)
			moveCharacterFunc(localPlayer, Vector2.new(-1,0),1)
		end
		
		local rightButtonBegin = function()
			movementVector = Vector2.new(1,0)
			moveCharacterFunc(localPlayer,  Vector2.new(1,0),1)
		end
		
		DPadFrame.InputEnded:connect(function()
			DPadFrame.forwardLeftButton.Visible = false
			DPadFrame.forwardRightButton.Visible = false
		end)
		
		local endStep = 0.08
		local endMovementFunc = function()
			DPadFrame.forwardLeftButton.Visible = false
			DPadFrame.forwardRightButton.Visible = false
			
			Spawn(function()
				while not dpadTouch and movementVector ~= Vector2.new(0,0) do
					local newX = movementVector.x
					local newY = movementVector.y
					
					if movementVector.x > 0 then
						newX = movementVector.x - endStep
						if newX < 0 then newX = 0 end
					elseif movementVector.x < 0 then
						newX = movementVector.x + endStep
						if newX > 0 then newX = 0 end
					end
					
					if movementVector.y > 0 then
						newY = movementVector.y - endStep
						if newY < 0 then newY = 0 end
					elseif movementVector.y < 0 then
						newY = movementVector.y + endStep
						if newY > 0 then newY = 0 end
					end
					
					movementVector = Vector2.new(newX,newY)
					moveCharacterFunc(localPlayer, movementVector,1)
					wait(1/60)
				end
				
				if movementVector ~= Vector2.new(0,0) then
					movementVector = Vector2.new(0,0) 
					moveCharacterFunc(localPlayer,Vector2.new(0,0) ,0)
				end
			end)
		end
		
		local removeDiagonalButtons = function()
			if isPointInRect(dpadTouch.Position,DPadFrame.ForwardButton.AbsolutePosition,DPadFrame.ForwardButton.AbsoluteSize) then
				DPadFrame.forwardLeftButton.Visible = false
				DPadFrame.forwardRightButton.Visible = false
			end
		end
		
		setupButton(DPadFrame.ForwardButton,forwardButtonBegin,removeDiagonalButtons)
		setupButton(DPadFrame.BackButton,backwardButtonBegin,nil)
		setupButton(DPadFrame.LeftButton,leftButtonBegin,nil)
		setupButton(DPadFrame.RightButton,rightButtonBegin,nil)
		
		local getMovementVector = function(touchPosition)
			local xDiff = touchPosition.x - (DPadFrame.AbsolutePosition.x + DPadFrame.AbsoluteSize.x/2)
			local yDiff = touchPosition.y - (DPadFrame.AbsolutePosition.y + DPadFrame.AbsoluteSize.y/2)
			local vectorNew = Vector2.new(xDiff,yDiff)
			
			movementVector = vectorNew.unit
			return vectorNew.unit
		end
		
		Game:GetService("UserInputService").TouchMoved:connect(function(touchObject)
			if touchObject == dpadTouch then
				if isPointInRect(dpadTouch.Position,DPadFrame.AbsolutePosition,DPadFrame.AbsoluteSize) then
					moveCharacterFunc(localPlayer, getMovementVector(dpadTouch.Position),1)
				else
					endMovementFunc()
				end
			end
		end)
		Game:GetService("UserInputService").TouchEnded:connect(function(touchObject)
			if touchObject == dpadTouch then
				dpadTouch = nil
				endMovementFunc()
			end
		end)


		DPadFrame.Visible = not userInputService.ModalEnabled
			
	end

	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	--
	-- Character Movement
	--
	local characterThumbstick = nil
	local characterOuterThumbstick = nil

	function setupCharacterMovement( parentFrame )
		local lastMovementVector, lastMaxMovement = nil
		local moveCharacterFunc = localPlayer.MoveCharacter
		local moveCharacterFunction = function ( movementVector, maxMovement )
			if localPlayer then
				if movementOutsideDeadZone(movementVector) then
					lastMovementVector = movementVector
					lastMaxMovement = maxMovement
					-- sometimes rounding error will not allow us to go max speed at some
					-- thumbstick angles, fix this with a bit of fudging near 100% throttle
					if movementVector.magnitude/maxMovement > ThumbstickMaxPercentGive then
						maxMovement = movementVector.magnitude - 1
					end
					moveCharacterFunc(localPlayer, movementVector, maxMovement)
				else
					lastMovementVector = Vector2.new(0,0)
					lastMaxMovement = 1
					moveCharacterFunc(localPlayer, lastMovementVector, lastMaxMovement)
				end
			end
		end

		local thumbstickPos = UDim2.new(0,thumbstickSize/2,1,-thumbstickSize*1.75)
		if isSmallScreenDevice() then
			thumbstickPos = UDim2.new(0,(thumbstickSize/2) - 10,1,-thumbstickSize - 20)
		end
		
		characterThumbstick, characterOuterThumbstick  = constructThumbstick(thumbstickPos, moveCharacterFunction, false)
		characterThumbstick.Name = "CharacterThumbstick"
		characterThumbstick.Parent = parentFrame

		local refreshCharacterMovement = function()
			if localPlayer and isInThumbstickMode and moveCharacterFunc and lastMovementVector and lastMaxMovement then
				moveCharacterFunc(localPlayer, lastMovementVector, lastMaxMovement)
			end
		end
		return refreshCharacterMovement
	end

	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	--
	-- Jump Button
	--
	local jumpButton = nil

	function setupJumpButton( parentFrame )
		if (jumpButton == nil) then
			jumpButton = Instance.new("ImageButton")
			jumpButton.Name = "JumpButton"
			jumpButton.BackgroundTransparency = 1
			jumpButton.Image = touchControlsSheet
			jumpButton.ImageRectOffset = Vector2.new(176,222)
			jumpButton.ImageRectSize = Vector2.new(174,174)
			jumpButton.Size = UDim2.new(0,jumpButtonSize,0,jumpButtonSize)
			if isSmallScreenDevice() then 
				jumpButton.Position = UDim2.new(1, -(jumpButtonSize*2.25), 1, -jumpButtonSize - 20)
			else
				jumpButton.Position = UDim2.new(1, -(jumpButtonSize*2.75), 1, -jumpButtonSize - 120)
			end
		
			local playerJumpFunc = localPlayer.JumpCharacter
		
			local doJumpLoop = function ()
				while currentJumpTouch do
					if localPlayer then
						playerJumpFunc(localPlayer)
					end
					wait(1/60)
				end
			end
		
			jumpButton.InputBegan:connect(function(inputObject)
				if inputObject.UserInputType ~= Enum.UserInputType.Touch then return end
				if currentJumpTouch then return end
				if inputObject == cameraTouch then return end
				for i, touch in pairs(oldJumpTouches) do
					if touch == inputObject then
						return
					end
				end
		
				currentJumpTouch = inputObject
				jumpButton.ImageRectOffset = Vector2.new(0,222)
				jumpButton.ImageRectSize = Vector2.new(174,174)
				doJumpLoop()		
			end)
			jumpButton.InputEnded:connect(function (inputObject)
				if inputObject.UserInputType ~= Enum.UserInputType.Touch then return end
				
				jumpButton.ImageRectOffset = Vector2.new(176,222)
				jumpButton.ImageRectSize = Vector2.new(174,174)
		
				if inputObject == currentJumpTouch then
					table.insert(oldJumpTouches,currentJumpTouch)
					currentJumpTouch = nil
				end
			end)
			userInputService.InputEnded:connect(function ( globalInputObject )
				for i, touch in pairs(oldJumpTouches) do
					if touch == globalInputObject then
						table.remove(oldJumpTouches,i)
						break
					end
				end
			end)
			jumpButton.Parent = parentFrame
		end
		jumpButton.Visible = not userInputService.ModalEnabled
	end

	function  isTouchUsedByJumpButton( touch )
		if touch == currentJumpTouch then return true end
		for i, touchToCompare in pairs(oldJumpTouches) do
			if touch == touchToCompare then
				return true
			end
		end

		return false
	end

	function isTouchUsedByThumbstick(touch)
		for i, touchToCompare in pairs(thumbstickTouches) do
			if touch == touchToCompare then
				return true
			end
		end

		return false
	end

	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	--
	-- Camera Control
	--

	function setupCameraControl(parentFrame, refreshCharacterMoveFunc)
		local lastPos = nil
		local hasRotatedCamera = false
		local rotateCameraFunc = userInputService.RotateCamera

		local pinchTime = -1
		local shouldPinch = false
		local lastPinchScale = nil
		local zoomCameraFunc = userInputService.ZoomCamera
		local pinchTouches = {}
		local pinchFrame = nil
		local pinchInputChangedCon = nil
		local pinchInputEndedCon = nil

		local resetCameraRotateState = function()
			setCameraTouch(nil)
			hasRotatedCamera = false
			lastPos = nil
		end

		local resetPinchState = function ()
			pinchTouches = {}

			pinchTime = -1
			lastPinchScale = nil
			shouldPinch = false
			pinchFrame:Destroy() 
			pinchFrame = nil
		end

		local startPinch = function(firstTouch, secondTouch)
			-- track pinching in new frame
			if pinchFrame then pinchFrame:Destroy() end -- make sure we didn't track in any mud
			pinchFrame = Instance.new("Frame")
			pinchFrame.Name = "PinchFrame"
			pinchFrame.BackgroundTransparency = 1
			pinchFrame.Parent = parentFrame
			pinchFrame.Size = UDim2.new(1,0,1,0)

			pinchFrame.InputChanged:connect(function(inputObject)
				if inputObject.UserInputType ~= Enum.UserInputType.Touch then return end

				if not shouldPinch then 
					resetPinchState()
					return
				end

				if lastPinchScale == nil then -- first pinch move, just set up scale
					if inputObject == firstTouch then
						lastPinchScale = (inputObject.Position - secondTouch.Position).magnitude
						firstTouch = inputObject
					elseif inputObject == secondTouch then
						lastPinchScale = (inputObject.Position - firstTouch.Position).magnitude
						secondTouch = inputObject
					end
				else -- we are now actually pinching, do comparison to last pinch size
					local newPinchDistance = 0
					if inputObject == firstTouch then
						newPinchDistance = (inputObject.Position - secondTouch.Position).magnitude
						firstTouch = inputObject
					elseif inputObject == secondTouch then
						newPinchDistance = (inputObject.Position - firstTouch.Position).magnitude
						secondTouch = inputObject
					end
					if newPinchDistance ~= 0 then
						local pinchDiff = newPinchDistance - lastPinchScale
						if pinchDiff ~= 0 then
							zoomCameraFunc(userInputService, (pinchDiff * CameraZoomSensitivity))
						end
						lastPinchScale = newPinchDistance
					end
				end
			end)
			pinchFrame.InputEnded:connect(function(inputObject) -- pinch is over, destroy all
				if inputObject == firstTouch or inputObject == secondTouch then
					resetPinchState() 
				end
			end)
		end

		local pinchGestureReceivedTouch = function(inputObject)
			if #pinchTouches < 1 then
				table.insert(pinchTouches,inputObject)
				pinchTime = tick()
				shouldPinch = false
			elseif #pinchTouches == 1 then
				shouldPinch = ( (tick() - pinchTime) <= PinchZoomDelay )

				if shouldPinch then
					table.insert(pinchTouches,inputObject)
					startPinch(pinchTouches[1], pinchTouches[2])
					resetCameraRotateState()
					return true
				else -- shouldn't ever get here, but just in case
					pinchTouches = {}
				end
			end

			return false
		end

		parentFrame.InputBegan:connect(function (inputObject)
			if inputObject.UserInputType ~= Enum.UserInputType.Touch then return end
			if isTouchUsedByJumpButton(inputObject) then return end
			if thumbpadTouchObject == inputObject then return end

			local usedByThumbstick = isTouchUsedByThumbstick(inputObject)
			local isPinching = false
			if not usedByThumbstick then
				isPinching = pinchGestureReceivedTouch(inputObject)
			end

			if cameraTouch == nil and not usedByThumbstick and not isPinching then
				setCameraTouch(inputObject)
				lastPos = Vector2.new(cameraTouch.Position.x,cameraTouch.Position.y)
				lastTick = tick()
			end
		end)
		
		userInputService.InputChanged:connect(function (inputObject)
			if inputObject.UserInputType ~= Enum.UserInputType.Touch then return end
			if cameraTouch ~= inputObject then return end

			local newPos = Vector2.new(cameraTouch.Position.x,cameraTouch.Position.y)
			local touchDiff = Vector2.new(0,0)
			if lastPos then
				touchDiff = (lastPos - newPos) * CameraRotateSensitivity
			end

			-- first time rotating outside deadzone, just setup for next changed event
			if not hasRotatedCamera and (touchDiff.magnitude > CameraRotateDeadZone) then
				hasRotatedCamera = true
				lastPos = newPos
			end

			-- fire everytime after we have rotated out of deadzone
			if hasRotatedCamera and (lastPos ~= newPos) then
				rotateCameraFunc(userInputService, touchDiff)
				refreshCharacterMoveFunc()
				lastPos = newPos
			end
		end)
		userInputService.InputEnded:connect(function (inputObject)
			if cameraTouch == inputObject or cameraTouch == nil then
				resetCameraRotateState()
			end

			for i, touch in pairs(pinchTouches) do
				if touch == inputObject then
					table.remove(pinchTouches,i)
				end
			end
		end)
	end

	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	--
	-- Thumbpad		-- Jason
	--
	local thumbpadFrame = nil
	function setupThumbpad(parentFrame)
		local isSmallScreen = isSmallScreenDevice()
		local position = isSmallScreen and UDim2.new(0, thumbstickSize * 0.5 - 20, 1, -thumbstickSize - 30) or
			UDim2.new(0, thumbstickSize/2 - 10, 1, -thumbstickSize * 1.75 - 10)
		
		thumbpadFrame = Instance.new('Frame')	-- container
		thumbpadFrame.Name = "NewThumbstickFrame"
		thumbpadFrame.Active = true
		thumbpadFrame.Size = UDim2.new(0, thumbstickSize + 20, 0, thumbstickSize + 20)
		thumbpadFrame.Position = position
		thumbpadFrame.BackgroundTransparency = 1
		
		local outerStickFrame = Instance.new('ImageLabel')	-- circle image
		outerStickFrame.Name = "OuterImage"
		outerStickFrame.Image = touchControlsSheet
		outerStickFrame.ImageRectOffset = Vector2.new()
		outerStickFrame.ImageRectSize = Vector2.new(220, 220)
		outerStickFrame.BackgroundTransparency = 1
		outerStickFrame.Size = UDim2.new(0, thumbstickSize, 0, thumbstickSize)
		outerStickFrame.Position = UDim2.new(0, 10, 0, 10)
		outerStickFrame.Parent = thumbpadFrame
		
		-- arrow set up
		local arrowSize = isSmallScreen and UDim2.new(0, 32, 0, 32) or UDim2.new(0, 64, 0, 64)
		local tweenSize = UDim2.new(0, arrowSize.X.Offset * 2, 0, arrowSize.Y.Offset * 2)
		local rectSize = Vector2.new(116, 116)
		local smallOffset = isSmallScreen and -4 or -9
		local largeOffset = isSmallScreen and -28 or -55
		
		local function createArrow(name, position, size, offset)
			local arrow = Instance.new('ImageLabel')
			arrow.Name = name
			arrow.Image = DPadSheet
			arrow.ImageRectOffset = offset
			arrow.ImageRectSize = rectSize
			arrow.BackgroundTransparency = 1
			arrow.Size = size
			arrow.Position = position
			arrow.Parent = outerStickFrame
			return arrow
		end
		--
		local dArrow = createArrow("DownImage", UDim2.new(0.5, -arrowSize.X.Offset/2, 1, largeOffset), arrowSize, Vector2.new(6, 6))
		local uArrow = createArrow("UpImage", UDim2.new(0.5, -arrowSize.X.Offset/2, 0, smallOffset), arrowSize, Vector2.new(6, 264))
		local lArrow = createArrow("LeftImage", UDim2.new(0, smallOffset, 0.5, -arrowSize.Y.Offset/2), arrowSize, Vector2.new(135, 135))
		local rArrow = createArrow("RightImage", UDim2.new(1, largeOffset, 0.5, -arrowSize.Y.Offset/2), arrowSize, Vector2.new(6, 135))
		
		local function doTween(guiObject, endSize, endPosition)
			guiObject:TweenSizeAndPosition(endSize, endPosition, Enum.EasingDirection.InOut,
				Enum.EasingStyle.Linear, 0.15, true)
		end	
		
		local padOrigin = nil
		local deadZone = 0.5
		
		local isRight, isLeft, isUp, isDown = false, false, false, false
		local function move(pos)
			local delta = Vector2.new(pos.x, pos.y) - padOrigin
			local inputAxis = delta / (thumbstickSize/2)
			
			-- Dead Zone
			local inputAxisMagnitude = inputAxis.magnitude
			if inputAxisMagnitude < deadZone then
				inputAxis = Vector3.new(0, 0, 0)
			else
				inputAxis = inputAxis.unit * ((inputAxisMagnitude - deadZone) / (1 - deadZone))
				-- catch possible NAN Vector
				if inputAxis.magnitude == 0 then
					inputAxis = Vector3.new(0, 0, 0)
				else
					inputAxis = Vector3.new(inputAxis.x, 0, inputAxis.y).unit
				end
			end
			
			localPlayer:Move(inputAxis, true)
			
			-- arrow tweening
			local forwardDot = inputAxis:Dot(Vector3.new(0, 0, -1))
			local rightDot = inputAxis:Dot(Vector3.new(1, 0, 0))		
			if forwardDot > 0.5 then		-- UP
				if not isUp then
					isUp = true
					isDown = false
					doTween(uArrow, tweenSize, UDim2.new(0.5, -arrowSize.X.Offset, 0, smallOffset - arrowSize.Y.Offset * 1.5))
					doTween(dArrow, arrowSize, UDim2.new(0.5, -arrowSize.X.Offset/2, 1, largeOffset))
				end
			elseif forwardDot < -0.5 then	-- DOWN
				if not isDown then
					isDown = true
					isUp = false
					doTween(dArrow, tweenSize, UDim2.new(0.5, -arrowSize.X.Offset, 1, largeOffset + arrowSize.Y.Offset/2))
					doTween(uArrow, arrowSize, UDim2.new(0.5, -arrowSize.X.Offset/2, 0, smallOffset))
				end
			else
				isDown, isUp = false, false
				doTween(dArrow, arrowSize, UDim2.new(0.5, -arrowSize.X.Offset/2, 1, largeOffset))
				doTween(uArrow, arrowSize, UDim2.new(0.5, -arrowSize.X.Offset/2, 0, smallOffset))
			end
			
			if rightDot > 0.5 then		-- RIGHT
				if not isRight then
					isRight = true
					isLeft = false
					doTween(rArrow, tweenSize, UDim2.new(1, largeOffset + arrowSize.X.Offset/2, 0.5, -arrowSize.Y.Offset))
					doTween(lArrow, arrowSize, UDim2.new(0, smallOffset, 0.5, -arrowSize.Y.Offset/2))
				end
			elseif rightDot < -0.5 then	-- LEFT
				if not isLeft then
					isLeft = true
					isRight = false
					doTween(lArrow, tweenSize, UDim2.new(0, smallOffset - arrowSize.X.Offset * 1.5, 0.5, -arrowSize.Y.Offset))
					doTween(rArrow, arrowSize, UDim2.new(1, largeOffset, 0.5, -arrowSize.Y.Offset/2))
				end
			else
				isRight, isLeft = false, false
				doTween(lArrow, arrowSize, UDim2.new(0, smallOffset, 0.5, -arrowSize.Y.Offset/2))
				doTween(rArrow, arrowSize, UDim2.new(1, largeOffset, 0.5, -arrowSize.Y.Offset/2))
			end
		end
		
		-- input connections
		thumbpadFrame.InputBegan:connect(function(inputObject)
			if thumbpadTouchObject or inputObject.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			
			thumbpadTouchObject = inputObject
			padOrigin = Vector2.new(thumbpadFrame.AbsolutePosition.x + thumbpadFrame.AbsoluteSize.x/2,
				thumbpadFrame.AbsolutePosition.y + thumbpadFrame.AbsoluteSize.y/2)
			move(inputObject.Position)
		end)
		
		userInputService.InputChanged:connect(function(inputObject, isProcessed)
			if inputObject == thumbpadTouchObject then
				move(inputObject.Position)
			end
		end)
		
		userInputService.InputEnded:connect(function(inputObject, isProcessed)
			if inputObject == thumbpadTouchObject then
				localPlayer:Move(Vector3.new(), true)
				thumbpadTouchObject = nil
				
				isUp, isDown, isLeft, isRight = false, false, false, false
				doTween(dArrow, arrowSize, UDim2.new(0.5, -arrowSize.X.Offset/2, 1, largeOffset))
				doTween(uArrow, arrowSize, UDim2.new(0.5, -arrowSize.X.Offset/2, 0, smallOffset))
				doTween(lArrow, arrowSize, UDim2.new(0, smallOffset, 0.5, -arrowSize.Y.Offset/2))
				doTween(rArrow, arrowSize, UDim2.new(1, largeOffset, 0.5, -arrowSize.Y.Offset/2))
			end
		end)
		
		thumbpadFrame.Parent = parentFrame
	end

	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	--
	-- Touch Control
	--

	local touchControlFrame = nil
	local characterDPad = nil

	function setupTouchControls()
		touchControlFrame = Instance.new("Frame")
		touchControlFrame.Name = "TouchControlFrame"
		touchControlFrame.Size = UDim2.new(1,0,1,0)
		touchControlFrame.BackgroundTransparency = 1
		touchControlFrame.Parent = Game:GetService("CoreGui").RobloxGui

		userInputService.ProcessedEvent:connect(function(inputObject, processed)
			if not processed then return end

			-- kill camera pan if the touch is used by some user controls
			if inputObject == cameraTouch and inputObject.UserInputState == Enum.UserInputState.Begin then
				setCameraTouch(nil)
			end
		end)

		setupJumpButton(touchControlFrame)
		local refreshCharacterMoveFunc = setupCharacterMovement(touchControlFrame)
		setupCameraControl(touchControlFrame, refreshCharacterMoveFunc)

		characterDPad = createDPad()
		characterDPad.Name = "CharacterDPad"
		characterDPad.Parent = touchControlFrame
		setupDPadControls(characterDPad)
		
		setupThumbpad(touchControlFrame)
		
		userInputService.Changed:connect(function(prop)
			if prop == "ModalEnabled" then
				activateTouchControls()
			end
		end)

		activateTouchControls()

		GameSettings.Changed:connect(function(property)
			if (property == "TouchMovementMode") then
				activateTouchControls()
			end
		end)
	end

	function activateTouchControls()	
		-- set user controlled visibility
		if userInputService.ModalEnabled then
			characterThumbstick.Visible = false
			characterOuterThumbstick.Visible = false
			jumpButton.Visible = false
			characterDPad.Visible = false
			thumbpadFrame.Visible = false
			if currentJumpTouch then
				currentJumpTouch = nil
			end
		else
			local modeName = GameSettings.TouchMovementMode.Name
			local isThumbpadMode = false
			if (modeName == "Thumbstick" or modeName == "Default") then
				isInThumbstickMode = true
				isThumbpadMode = false
			elseif modeName == "Thumbpad" then
				isInThumbstickMode = false
				isThumbpadMode = true
			else 
				isInThumbstickMode = false
				isThumbpadMode = false
			end
			
			characterThumbstick.Visible = isInThumbstickMode
			characterOuterThumbstick.Visible = isInThumbstickMode
			thumbpadFrame.Visible = isThumbpadMode
			jumpButton.Visible = isInThumbstickMode or isThumbpadMode
			characterDPad.Visible = not isInThumbstickMode and not isThumbpadMode
		end
	end

	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	-- Start of Script

	if userInputService:IsLuaTouchControls() then
		if game:IsLoaded() then
			setupTouchControls()
		else
			game.Loaded:connect(function()
				setupTouchControls()
			end)
		end
	else
		script:Destroy()
	end
end
