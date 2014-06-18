-- This is responsible for all touch controls we show (as of this writing, only on iOS)
-- this includes character move thumbsticks, and buttons for jump, use of items, camera, etc.
-- Written by Ben Tkacheff, Copyright Roblox 2013

-- obligatory stuff to make sure we don't access nil data
while not Game do
	wait()
end
while not Game:FindFirstChild("Players") do
	wait()
end
while not Game.Players.LocalPlayer do
	wait()
end
while not Game:FindFirstChild("CoreGui") do
	wait()
end
while not Game.CoreGui:FindFirstChild("RobloxGui") do
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

local localPlayer = Game.Players.LocalPlayer

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
	outerThumbstick.Parent = Game.CoreGui.RobloxGui

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
-- Touch Control
--

local touchControlFrame = nil
local characterDPad = nil

function setupTouchControls()
	touchControlFrame = Instance.new("Frame")
	touchControlFrame.Name = "TouchControlFrame"
	touchControlFrame.Size = UDim2.new(1,0,1,0)
	touchControlFrame.BackgroundTransparency = 1
	touchControlFrame.Parent = Game.CoreGui.RobloxGui

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
	
	userInputService.Changed:connect(function(prop)
		if prop == "ModalEnabled" then
			activateTouchControls()
		end
	end)

	activateTouchControls()
end

function activateTouchControls()	
	-- set user controlled visibility
	if userInputService.ModalEnabled then
		characterThumbstick.Visible = false
		characterOuterThumbstick.Visible = false
		jumpButton.Visible = false
		characterDPad.Visible = false
	else		
		if (GameSettings.TouchMovementMode.Name == "Thumbstick" or GameSettings.TouchMovementMode.Name == "Default") then
			isInThumbstickMode = true
		else 
			isInThumbstickMode = false
		end
		
		characterThumbstick.Visible = isInThumbstickMode
		characterOuterThumbstick.Visible = isInThumbstickMode
		jumpButton.Visible = isInThumbstickMode
		characterDPad.Visible = not isInThumbstickMode
	end
end

----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Start of Script

if userInputService:IsLuaTouchControls() then
	setupTouchControls()
else
	script:Destroy()
end

GameSettings.Changed:connect(function(property)
	if (property == "TouchMovementMode") then
		activateTouchControls()
	end
end)
