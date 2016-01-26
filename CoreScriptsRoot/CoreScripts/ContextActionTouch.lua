-- ContextActionTouch.lua
-- Copyright ROBLOX 2014, created by Ben Tkacheff
-- this script controls ui and firing of lua functions that are bound in ContextActionService for touch inputs
-- Essentially a user can bind a lua function to a key code, input type (mousebutton1 etc.) and this

-- Variables
local contextActionService = Game:GetService("ContextActionService")
local userInputService = Game:GetService("UserInputService")
local isTouchDevice = userInputService.TouchEnabled
local functionTable = {}
local buttonVector = {}
local buttonScreenGui = nil
local buttonFrame = nil

local isSmallScreen = Game:GetService("GuiService"):GetScreenResolution().y <= 500

local ContextDownImage = "http://www.roblox.com/asset/?id=97166756"
local ContextUpImage = "http://www.roblox.com/asset/?id=97166444"

local oldTouches = {}

local buttonPositionTable = isSmallScreen and {
								[1] = {80, 1},
								[2] = {135, 1},
								[3] = {190, 1}
							} or {	
--								[index] = {degrees, distanceScale}
--								degrees starts at right and goes counter clockwise
--								buttons after this will be auto positioned
								[1] = {60, 1},
								[2] = {0, 1},
								[3] = {120, 1},
								[4] = {180, 1},
								[5] = {-60, 1},
								[6] = {-120, 1},
								[7] = {90, 1.7},
								[8] = {120, 2},
								[9] = {150, 1.7},
								[10] = {180, 2},
								[11] = {210, 1.7}
							}
local maxButtons = #buttonPositionTable

local firstArcDistance = isSmallScreen and 2 or 3
local buttonArcs = {
	[1] = 6,
	[2] = 8,
	[3] = 9,
	[4] = 11,
	[5] = 13,
	[6] = 15,
	[7] = 17,
	[8] = 19,
	[9] = 21
}
if isSmallScreen then
	table.insert(buttonArcs, 1, 4)
end


local buttonPositionsOccupied = {}

 -- following block is mirrored from ControlScript.MasterControl.TouchJump
local jumpButtonSize = isSmallScreen and 56 or 72
local thumbstickSize = isSmallScreen and 70 or 120
local thumbstickPosition = isSmallScreen and UDim2.new(0, thumbstickSize/2 - 10, 1, -thumbstickSize - 20) or
	UDim2.new(0, thumbstickSize/2, 1, -thumbstickSize * 1.75)
local jumpButtonPosition = UDim2.new(
	1 - thumbstickPosition.X.Scale,
	-thumbstickPosition.X.Offset - thumbstickSize + thumbstickSize/2 - jumpButtonSize/2,
	thumbstickPosition.Y.Scale,
	thumbstickPosition.Y.Offset + thumbstickSize/2 - jumpButtonSize/2
)

-- Preload images
Game:GetService("ContentProvider"):Preload(ContextDownImage)
Game:GetService("ContentProvider"):Preload(ContextUpImage)

while not Game:GetService("Players") do
	wait()
end

while not Game:GetService("Players").LocalPlayer do
	wait()
end

function createContextActionGui()
	if not buttonScreenGui and isTouchDevice then
		buttonScreenGui = Instance.new("ScreenGui")
		buttonScreenGui.Name = "ContextActionGui"

		buttonFrame = Instance.new("Frame")
		buttonFrame.BackgroundTransparency = 1
		buttonFrame.Size = UDim2.new(0.3,0,0.5,0)
		buttonFrame.Position = UDim2.new(0.7,0,0.5,0)
		buttonFrame.Name = "ContextButtonFrame"
		buttonFrame.Parent = buttonScreenGui

		buttonFrame.Visible = not userInputService.ModalEnabled
		userInputService.Changed:connect(function(property)
			if property == "ModalEnabled" then
				buttonFrame.Visible = not userInputService.ModalEnabled
			end
		end)
	end
end

-- functions
function setButtonSizeAndPosition(object)
	local buttonSize = 55
	local xOffset = 10
	local yOffset = 95

	-- todo: better way to determine mobile sized screens
	local onSmallScreen = (game:GetService("CoreGui").RobloxGui.AbsoluteSize.X < 600)
	if not onSmallScreen then
		buttonSize = 85
		xOffset = 40
	end

	object.Size = UDim2.new(0,buttonSize,0,buttonSize)
end

function contextButtonDown(button, inputObject, actionName)
	if inputObject.UserInputType == Enum.UserInputType.Touch then
		button.Image = ContextDownImage
		contextActionService:CallFunction(actionName, Enum.UserInputState.Begin, inputObject)
	end
end

function contextButtonMoved(button, inputObject, actionName)
	if inputObject.UserInputType == Enum.UserInputType.Touch then
		button.Image = ContextDownImage
		contextActionService:CallFunction(actionName, Enum.UserInputState.Change, inputObject)
	end
end

function contextButtonUp(button, inputObject, actionName)
	button.Image = ContextUpImage
	if inputObject.UserInputType == Enum.UserInputType.Touch and inputObject.UserInputState == Enum.UserInputState.End then
		contextActionService:CallFunction(actionName, Enum.UserInputState.End, inputObject)
	end
end


function createNewButton(actionName, functionInfoTable)
	local contextButton = Instance.new("ImageButton")
	contextButton.Name = "ContextActionButton"
	contextButton.BackgroundTransparency = 1
	contextButton.Size = UDim2.new(0,jumpButtonSize,0,jumpButtonSize)
	contextButton.Active = true
	contextButton.Image = ContextUpImage
	contextButton.Parent = buttonFrame

	local currentButtonTouch = nil

	userInputService.InputEnded:connect(function ( inputObject )
		oldTouches[inputObject] = nil
	end)
	contextButton.InputBegan:connect(function(inputObject)
		if oldTouches[inputObject] then return end

		if inputObject.UserInputState == Enum.UserInputState.Begin and currentButtonTouch == nil then
			currentButtonTouch = inputObject
			contextButtonDown(contextButton, inputObject, actionName)
		end
	end)
	contextButton.InputChanged:connect(function(inputObject)
		if oldTouches[inputObject] then return end
		if currentButtonTouch ~= inputObject then return end

		contextButtonMoved(contextButton, inputObject, actionName)
	end)
	contextButton.InputEnded:connect(function(inputObject)
		if oldTouches[inputObject] then return end
		if currentButtonTouch ~= inputObject then return end

		currentButtonTouch = nil
		oldTouches[inputObject] = true
		contextButtonUp(contextButton, inputObject, actionName)
	end)

	local actionIcon = Instance.new("ImageLabel")
	actionIcon.Name = "ActionIcon"
	actionIcon.Position = UDim2.new(0.175, 0, 0.175, 0)
	actionIcon.Size = UDim2.new(0.65, 0, 0.65, 0)
	actionIcon.BackgroundTransparency = 1
	if functionInfoTable["image"] and type(functionInfoTable["image"]) == "string" then
		actionIcon.Image = functionInfoTable["image"]
	end
	actionIcon.Parent = contextButton

	local actionTitle = Instance.new("TextLabel")
	actionTitle.Name = "ActionTitle"
	actionTitle.Size = UDim2.new(1,0,1,0)
	actionTitle.BackgroundTransparency = 1
	actionTitle.Font = Enum.Font.SourceSansBold
	actionTitle.TextColor3 = Color3.new(1,1,1)
	actionTitle.TextStrokeTransparency = 0
	actionTitle.FontSize = Enum.FontSize.Size18
	actionTitle.TextWrapped = true
	actionTitle.Text = ""
	if functionInfoTable["title"] and type(functionInfoTable["title"]) == "string" then
		actionTitle.Text = functionInfoTable["title"]
	end
	actionTitle.Parent = contextButton

	return contextButton
end

function getButtonPosition(index, buttonSize)
	local complete = false
	local position, occupyingPosition

	while not complete do
		if buttonPositionsOccupied[index] then
			index = index + 1
		else
			local info = buttonPositionTable[index]

			-- Find the rotation and distance relative to jump button
			local rotation, distance

			if info ~= nil then
				-- Use preset position
				rotation, distance = unpack(info)
			else
				-- Auto generate position based on preset arcs
				local arc = 0
				local positionOnArc = 0
				local totalInArc = 0
				local indexOnArcs = index - #buttonPositionTable - 1
				
				local total = 0
				for arcIndex=1, #buttonArcs do
					local numInArc = buttonArcs[arcIndex]
					local prevTotal = total
					total = total + numInArc

					if total > indexOnArcs then
						arc = arcIndex
						positionOnArc = indexOnArcs - prevTotal
						totalInArc = numInArc
						break
					end
				end

				rotation = 90 + 90 * ((positionOnArc)/(totalInArc-1))
				distance = firstArcDistance + arc-1
			end

			-- Calculate position
			local buttonBuffer = jumpButtonSize * 1.2

			local pos = jumpButtonPosition + UDim2.new(
				0,
				jumpButtonSize/2 + math.cos(math.rad(-rotation)) * buttonBuffer * distance - buttonSize.X.Offset/2,
				0,
				jumpButtonSize/2 + math.sin(math.rad(-rotation)) * buttonBuffer * distance - buttonSize.Y.Offset/2
			)

			position, occupyingPosition = pos, index
			complete = true
		end
	end

	return position, occupyingPosition
end

function createButton( actionName, functionInfoTable )
	local button = createNewButton(actionName, functionInfoTable)

	local position = nil
	for i = 1,#buttonVector do
		if buttonVector[i] == "empty" then
			position = i
			break
		end
	end

	if not position then
		position = #buttonVector + 1
	end

	local buttonPosition, occupyingPosition = getButtonPosition(position, button.Size)

	buttonPositionsOccupied[occupyingPosition] = button
	buttonVector[position] = button
	functionTable[actionName]["button"] = button

	button.Position = buttonPosition
	button.Parent = buttonFrame

	if buttonScreenGui and buttonScreenGui.Parent == nil then
		buttonScreenGui.Parent = Game:GetService("Players").LocalPlayer.PlayerGui
	end
end

function removeAction(actionName)
	if not functionTable[actionName] then return end

	local actionButton = functionTable[actionName]["button"]
	
	if actionButton then
		actionButton.Parent = nil

		for i = 1,#buttonVector do
			if buttonVector[i] == actionButton then
				buttonVector[i] = "empty"
				break
			end
		end

		for index, otherButton in pairs(buttonPositionsOccupied) do
			if otherButton == actionButton then
				buttonPositionsOccupied[index] = nil
			end
		end

		actionButton:Destroy()
	end

	functionTable[actionName] = nil
end

function addAction(actionName,createTouchButton,functionInfoTable)
	if functionTable[actionName] then
		removeAction(actionName)
	end
	functionTable[actionName] = {functionInfoTable}
	if createTouchButton and isTouchDevice then
		createContextActionGui()
		createButton(actionName, functionInfoTable)
	end
end

-- Connections
contextActionService.BoundActionChanged:connect( function(actionName, changeName, changeTable)
	if functionTable[actionName] and changeTable then
		local button = functionTable[actionName]["button"]
		if button then
			if changeName == "image" then
				button.ActionIcon.Image = changeTable[changeName]
			elseif changeName == "title" then
				button.ActionTitle.Text = changeTable[changeName]
			elseif changeName == "description" then
				-- todo: add description to menu
			elseif changeName == "position" then
				button.Position = changeTable[changeName]
			end
		end
	end
end)

contextActionService.BoundActionAdded:connect( function(actionName, createTouchButton, functionInfoTable)
	addAction(actionName, createTouchButton, functionInfoTable)
end)

contextActionService.BoundActionRemoved:connect( function(actionName, functionInfoTable)
	removeAction(actionName)
end)

contextActionService.GetActionButtonEvent:connect( function(actionName)
	if functionTable[actionName] then
		contextActionService:FireActionButtonFoundSignal(actionName, functionTable[actionName]["button"])
	end
end)

-- make sure any bound data before we setup connections is handled
local boundActions = contextActionService:GetAllBoundActionInfo()
for actionName, actionData in pairs(boundActions) do
	addAction(actionName,actionData["createTouchButton"],actionData)
end
