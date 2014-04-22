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
	return screenResolution.y <= 320
end

local localPlayer = Game.Players.LocalPlayer
local thumbstickInactiveAlpha = 0.3
local thumbstickSize = 120
if isSmallScreenDevice() then 
	thumbstickSize = 70
end

local touchControlsSheet = "rbxasset://textures/ui/TouchControlsSheet.png"
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


-- make sure all of our images are good to go
Game:GetService("ContentProvider"):Preload(touchControlsSheet)

----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Functions

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

	userInputService.Changed:connect(function(prop)
		if prop == "ModalEnabled" then
			thumbstickFrame.Visible = not userInputService.ModalEnabled
			outerThumbstick.Visible = not userInputService.ModalEnabled
		end
	end)

	thumbstickFrame.InputBegan:connect(startInputTracking)
	return thumbstickFrame
end

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
	local characterThumbstick = constructThumbstick(thumbstickPos, moveCharacterFunction, false)
	characterThumbstick.Name = "CharacterThumbstick"
	characterThumbstick.Parent = parentFrame

	local refreshCharacterMovement = function()
		if localPlayer and moveCharacterFunc and lastMovementVector and lastMaxMovement then
			moveCharacterFunc(localPlayer, lastMovementVector, lastMaxMovement)
		end
	end
	return refreshCharacterMovement
end


function setupJumpButton( parentFrame )
	local jumpButton = Instance.new("ImageButton")
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

	userInputService.Changed:connect(function(prop)
		if prop == "ModalEnabled" then
			jumpButton.Visible = not userInputService.ModalEnabled
		end
	end)

	jumpButton.Parent = parentFrame
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

	local resetCameraRotateState = function()
		cameraTouch = nil
		hasRotatedCamera = false
		lastPos = nil
	end

	local resetPinchState = function ()
		pinchTouches = {}
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
    		if not shouldPinch then 
    			resetPinchState()
    			return
    		end
			resetCameraRotateState()

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
	        else -- shouldn't ever get here, but just in case
	        	pinchTouches = {}
	        end
	    end
	end

	parentFrame.InputBegan:connect(function (inputObject)
		if inputObject.UserInputType ~= Enum.UserInputType.Touch then return end
		if isTouchUsedByJumpButton(inputObject) then return end

		local usedByThumbstick = isTouchUsedByThumbstick(inputObject)
		if not usedByThumbstick then
			pinchGestureReceivedTouch(inputObject)
		end

		if cameraTouch == nil and not usedByThumbstick then
			cameraTouch = inputObject
			lastPos = Vector2.new(cameraTouch.Position.x,cameraTouch.Position.y)
			lastTick = tick()
		end
	end)
	userInputService.InputChanged:connect(function (inputObject)
		if inputObject.UserInputType ~= Enum.UserInputType.Touch then return end
		if cameraTouch ~= inputObject then return end

		local newPos = Vector2.new(cameraTouch.Position.x,cameraTouch.Position.y)
		local touchDiff = (lastPos - newPos) * CameraRotateSensitivity

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

function setupTouchControls()
	local touchControlFrame = Instance.new("Frame")
	touchControlFrame.Name = "TouchControlFrame"
	touchControlFrame.Size = UDim2.new(1,0,1,0)
	touchControlFrame.BackgroundTransparency = 1
	touchControlFrame.Parent = Game.CoreGui.RobloxGui

	local refreshCharacterMoveFunc = setupCharacterMovement(touchControlFrame)
	setupJumpButton(touchControlFrame)
	setupCameraControl(touchControlFrame, refreshCharacterMoveFunc)

	userInputService.ProcessedEvent:connect(function(inputObject, processed)
		if not processed then return end

		-- kill camera pan if the touch is used by some user controls
		if inputObject == cameraTouch and inputObject.UserInputState == Enum.UserInputState.Begin then
			cameraTouch = nil
		end
	end)
end


----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Start of Script

if userInputService:IsLuaTouchControls() then
	setupTouchControls()
else
	script:Destroy()
end