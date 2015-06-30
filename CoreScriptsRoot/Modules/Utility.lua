--[[
		Filename: SettingsPage.lua
		Written by: jeditkacheff
		Version 1.0
		Description: Base Page Functionality for all Settings Pages
--]]

------------------ CONSTANTS --------------------
local SELECTED_COLOR = Color3.new(0,162/255,1)
local NON_SELECTED_COLOR = Color3.new(78/255,84/255,96/255)

local SELECTED_LEFT_IMAGE = "rbxasset://textures/ui/Settings/Slider/SelectedBarLeft.png"
local NON_SELECTED_LEFT_IMAGE = "rbxasset://textures/ui/Settings/Slider/BarLeft.png"
local SELECTED_RIGHT_IMAGE = "rbxasset://textures/ui/Settings/Slider/SelectedBarRight.png"
local NON_SELECTED_RIGHT_IMAGE= "rbxasset://textures/ui/Settings/Slider/BarRight.png"

local CONTROLLER_SCROLL_DELTA = 0.2
local CONTROLLER_THUMBSTICK_DEADZONE = 0.8

------------- SERVICES ----------------
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ContextActionService = game:GetService("ContextActionService")

----------- UTILITIES --------------
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
end


-- MATH --
function clamp(low, high, input)
	return math.max(low, math.min(high, input))
end

function ClampVector2(low, high, input)
	return Vector2.new(clamp(low.x, high.x, input.x), clamp(low.y, high.y, input.y))
end

---- TWEENZ ----
local Linear = function(t, b, c, d)
	if t >= d then return b + c end

	return c*t/d + b
end

local EaseOutQuad = function(t, b, c, d)
	if t >= d then return b + c end

	t = t/d;
	return -c * t*(t-2) + b
end

local EaseInOutQuad = function(t, b, c, d)
	if t >= d then return b + c end

	t = t / (d/2);
	if (t < 1) then return c/2*t*t + b end;
	t = t - 1;
	return -c/2 * (t*(t-2) - 1) + b;
end

function PropertyTweener(instance, prop, start, final, duration, easingFunc, cbFunc)
	local this = {}
	this.StartTime = tick()
	this.EndTime = this.StartTime + duration
	this.Cancelled = false

	local finished = false
	local percentComplete = 0

	local function finalize()
		if instance then
			instance[prop] = easingFunc(1, start, final - start, 1)
		end
		finished = true
		percentComplete = 1
		if cbFunc then
			cbFunc()
		end
	end

	-- Initial set
	instance[prop] = easingFunc(0, start, final - start, duration)
	spawn(function()
		local now = tick()
		while now < this.EndTime and instance do
			if this.Cancelled then
				return
			end
			instance[prop] = easingFunc(now - this.StartTime, start, final - start, duration)
			percentComplete = clamp(0, 1, (now - this.StartTime) / duration)
			RunService.RenderStepped:wait()
			now = tick()
		end
		if this.Cancelled == false and instance then
			finalize()
		end
	end)

	function this:GetFinal()
		return final
	end

	function this:GetPercentComplete()
		return percentComplete
	end

	function this:IsFinished()
		return finished
	end

	function this:Finish()
		if not finished then
			self:Cancel()
			finalize()
		end
	end

	function this:Cancel()
		this.Cancelled = true
	end

	return this
end

----------- CLASS DECLARATION --------------

local function CreateSignal()
	local sig = {}

	local mSignaler = Instance.new('BindableEvent')

	local mArgData = nil
	local mArgDataCount = nil

	function sig:fire(...)
		mArgData = {...}
		mArgDataCount = select('#', ...)
		mSignaler:Fire()
	end

	function sig:connect(f)
		if not f then error("connect(nil)", 2) end
		return mSignaler.Event:connect(function()
			f(unpack(mArgData, 1, mArgDataCount))
		end)
	end

	function sig:wait()
		mSignaler.Event:wait()
		assert(mArgData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
		return unpack(mArgData, 1, mArgDataCount)
	end

	return sig
end

local function getViewportSize()
	while not game.Workspace.CurrentCamera do
		game.Workspace.Changed:wait()
	end

	while game.Workspace.CurrentCamera.ViewportSize == Vector2.new(0,0) do
		game.Workspace.CurrentCamera.Changed:wait()
	end

	return game.Workspace.CurrentCamera.ViewportSize
end

local function isSmallTouchScreen()
	return UserInputService.TouchEnabled and getViewportSize().Y <= 500
end

local function usesSelectedObject()
	if UserInputService.TouchEnabled and not UserInputService.GamepadEnabled then return false end

	return true
end

local function MakeButton(name, text, size, clickFunc)
	local SelectionOverrideObject = Util.Create'ImageLabel'
	{
		Image = "",
		BackgroundTransparency = 1,
	};

	local button = Util.Create'ImageButton'
	{
		Name = name .. "Button",
		Image = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButton.png",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(8,6,46,44),
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = size,
		ZIndex = 2,
		SelectionImageObject = SelectionOverrideObject
	};
	button.NextSelectionLeft = button
	button.NextSelectionRight = button	
	if clickFunc then button.MouseButton1Click:connect(clickFunc) end

	local function isPointerInput(inputObject)
		return (inputObject.UserInputType == Enum.UserInputType.MouseMovement or inputObject.UserInputType == Enum.UserInputType.Touch)
	end

	button.InputBegan:connect(function(inputObject)
		if button.Selectable and isPointerInput(inputObject) then
			button.Image = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButtonSelected.png"
		end
	end)
	button.InputEnded:connect(function(inputObject)
		if button.Selectable and GuiService.SelectedCoreObject ~= button and isPointerInput(inputObject) then
			button.Image = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButton.png"
		end
	end)

	local textLabel = Util.Create'TextLabel'
	{
		Name = name .. "TextLabel",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -8),
		Position = UDim2.new(0,0,0,0),
		TextColor3 = Color3.new(1,1,1),
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = Enum.Font.SourceSansBold,
		FontSize = Enum.FontSize.Size24,
		Text = text,
		TextWrapped = true,
		ZIndex = 2,
		Parent = button
	};

	if isSmallTouchScreen() then
		textLabel.FontSize = Enum.FontSize.Size18
	end

	local guiServiceCon = GuiService.Changed:connect(function(prop)
		if prop ~= "SelectedCoreObject" then return end
		if not usesSelectedObject() then return end

		if GuiService.SelectedCoreObject == nil or GuiService.SelectedCoreObject ~= button then 
			button.Image = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButton.png"
			return 
		end

		if button.Selectable then
			button.Image = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButtonSelected.png"
		end
	end)

	return button, textLabel
end

local function CreateDropDown(dropDownStringTable, startPosition, settingsHub)
	-------------------- CONSTANTS ------------------------
	local DEFAULT_DROPDOWN_TEXT = "Choose One"
	local SCROLLING_FRAME_PIXEL_OFFSET = 25

	-------------------- VARIABLES ------------------------
	local lastSelectedCoreObject= nil

	-------------------- SETUP ------------------------
	local this = {}
	this.CurrentIndex = nil

	local indexChangedEvent = Instance.new("BindableEvent")
	indexChangedEvent.Name = "IndexChanged"

	if type(dropDownStringTable) ~= "table" then
		error("CreateDropDown dropDownStringTable (first arg) is not a table")
		return this
	end

	local indexChangedEvent = Instance.new("BindableEvent")
	indexChangedEvent.Name = "IndexChanged"

	local interactable = true
	local guid = HttpService:GenerateGUID(false)

	this.CurrentIndex = 0

	----------------- GUI SETUP ------------------------
	local DropDownFullscreenFrame = Util.Create'ImageButton'
	{
		Name = "DropDownFullscreenFrame",
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0,0,0),
		ZIndex = 10,
		Active = true,
		Visible = false,
		Selectable = false,
		AutoButtonColor = false,
		Parent = CoreGui.RobloxGui
	};

	local DropDownSelectionFrame = Util.Create'ImageLabel'
	{
		Name = "DropDownSelectionFrame",
		Image = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButton.png",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(8,6,46,44),
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 400, 0.9, 0),
		Position = UDim2.new(0.5, -200, 0.05, 0),
		ZIndex = 10,
		Parent = DropDownFullscreenFrame
	};

	local DropDownScrollingFrame = Util.Create'ScrollingFrame'
	{
		Name = "DropDownScrollingFrame",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -20, 1, -SCROLLING_FRAME_PIXEL_OFFSET),
		Position = UDim2.new(0, 10, 0, 10),
		ZIndex = 10,
		Parent = DropDownSelectionFrame
	};

	local hideDropDownSelection = function(name, inputState)
		if name ~= nil and inputState ~= Enum.UserInputState.Begin then return end
		this.DropDownFrame.Selectable = interactable

		if DropDownFullscreenFrame.Visible and usesSelectedObject() then
			GuiService.SelectedCoreObject = lastSelectedCoreObject
		end
		DropDownFullscreenFrame.Visible = false
		ContextActionService:UnbindCoreAction(guid .. "Action")
		ContextActionService:UnbindCoreAction(guid .. "FreezeAction")
	end
	local noOpFunc = function() end

	local DropDownFrameClicked = function()
		if not interactable then return end

		this.DropDownFrame.Selectable = false

		DropDownFullscreenFrame.Visible = true
		if not this.CurrentIndex then this.CurrentIndex = 1 end
		if this.CurrentIndex <= 0 then this.CurrentIndex = 1 end

		lastSelectedCoreObject = this.DropDownFrame
		GuiService.SelectedCoreObject = this.Selections[this.CurrentIndex]

		settingsHub:AddToMenuStack(DropDownFullscreenFrame)

		ContextActionService:BindCoreAction(guid .. "FreezeAction", noOpFunc, false, Enum.UserInputType.Keyboard, Enum.UserInputType.Gamepad1)
		ContextActionService:BindCoreAction(guid .. "Action", hideDropDownSelection, false, Enum.KeyCode.ButtonB, Enum.KeyCode.Escape)
	end

	local dropDownFrameSize = UDim2.new(0,400,0,44)
	if isSmallTouchScreen() then
		dropDownFrameSize = UDim2.new(0,300,0,44)
	end
	this.DropDownFrame = MakeButton("DropDownFrame", DEFAULT_DROPDOWN_TEXT, dropDownFrameSize, DropDownFrameClicked)
	local selectedTextLabel = this.DropDownFrame.DropDownFrameTextLabel
	local dropDownImage = Util.Create'ImageLabel'
	{
		Name = "DropDownImage",
		Image = "rbxasset://textures/ui/Settings/DropDown/DropDown.png",
		BackgroundTransparency = 1,
		Size = UDim2.new(0,15,0,10),
		Position = UDim2.new(1, -45,0.5,-7),
		ZIndex = 2,
		Parent = this.DropDownFrame
	};

	---------------------- FUNCTIONS -----------------------------------
	local function setSelection(index)
		local shouldFireChanged = false
		for i, selectionLabel in pairs(this.Selections) do
			if i == index then
				selectedTextLabel.Text = selectionLabel.Text
				this.CurrentIndex = i

				shouldFireChanged = true
			end
		end

		indexChangedEvent:Fire(index)
	end


	--------------------- PUBLIC FACING FUNCTIONS -----------------------
	this.IndexChanged = indexChangedEvent.Event

	function this:SetSelectionIndex(newIndex)
		setSelection(newIndex)
	end

	function this:ResetSelectionIndex()
		this.CurrentIndex = nil
		selectedTextLabel.Text = DEFAULT_DROPDOWN_TEXT
		hideDropDownSelection()
	end

	function this:GetSelectedIndex()
		return this.CurrentIndex
	end

	function this:SetZIndex(newZIndex)
		this.DropDownFrame.ZIndex = newZIndex
		dropDownImage.ZIndex = newZIndex
		selectedTextLabel.ZIndex = newZIndex
	end

	function this:SetInteractable(value)
		interactable = value
		this.DropDownFrame.Selectable = interactable
		
		if not interactable then
			hideDropDownSelection()
			this:SetZIndex(1)
		else
			this:SetZIndex(2)
		end
	end


	function this:UpdateDropDownList(dropDownStringTable)
		if this.Selections then
			for i = 1, #this.Selections do
				this.Selections[i]:Destroy()
			end
		end

		this.Selections = {}

		local SelectionOverrideObject = Util.Create'Frame'
		{
			Size = UDim2.new(1,0,1,0),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0
		};

		local SELECTION_TEXT_COLOR_NORMAL = Color3.new(0.9,0.9,0.9)
		local SELECTION_TEXT_COLOR_HIGHLIGHTED = Color3.new(1,1,1)
		for i,v in pairs(dropDownStringTable) do
			local nextSelection = Util.Create'TextButton'
			{
				Name = "Selection" .. tostring(i),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Size = UDim2.new(1, 0, 0, 50),
				Position = UDim2.new(0,0,0, (i - 1) * 51),
				TextColor3 = SELECTION_TEXT_COLOR_NORMAL,
				Font = Enum.Font.SourceSans,
				FontSize = Enum.FontSize.Size24,
				Text = v,
				ZIndex = 10,
				SelectionImageObject = SelectionOverrideObject,
				Parent = DropDownScrollingFrame
			};

			if i == startPosition then
				this.CurrentIndex = i
				selectedTextLabel.Text = v
			end

			nextSelection.MouseButton1Click:connect(function()
				selectedTextLabel.Text = nextSelection.Text
				nextSelection.TextColor3 = SELECTION_TEXT_COLOR_NORMAL
				hideDropDownSelection()
				this.CurrentIndex = i
				indexChangedEvent:Fire(i)
			end)

			nextSelection.MouseEnter:connect(function()
				if usesSelectedObject() then
					GuiService.SelectedCoreObject = nextSelection
				end
				if nextSelection.Selectable and UserInputService.MouseEnabled then
					nextSelection.TextColor3 = SELECTION_TEXT_COLOR_HIGHLIGHTED
				end
			end)

			nextSelection.MouseLeave:connect(function()
				if nextSelection.Selectable and UserInputService.MouseEnabled then
					nextSelection.TextColor3 = SELECTION_TEXT_COLOR_NORMAL
				end
			end)

			this.Selections[i] = nextSelection
		end

		GuiService:RemoveSelectionGroup(guid)
		GuiService:AddSelectionTuple(guid, unpack(this.Selections))

		DropDownScrollingFrame.CanvasSize = UDim2.new(1,-20,0,#dropDownStringTable * 51)

		local function updateDropDownSize()
			if DropDownScrollingFrame.CanvasSize.Y.Offset < (DropDownFullscreenFrame.AbsoluteSize.Y - 10) then
				DropDownSelectionFrame.Size = UDim2.new(DropDownSelectionFrame.Size.X.Scale, DropDownSelectionFrame.Size.X.Offset,
														0,DropDownScrollingFrame.CanvasSize.Y.Offset + SCROLLING_FRAME_PIXEL_OFFSET)
				DropDownSelectionFrame.Position = UDim2.new(DropDownSelectionFrame.Position.X.Scale, DropDownSelectionFrame.Position.X.Offset,
															0.5, -DropDownSelectionFrame.Size.Y.Offset/2)
			else
				DropDownSelectionFrame.Size = UDim2.new(0, 400, 0.9, 0)
				DropDownSelectionFrame.Position = UDim2.new(0.5, -200, 0.05, 0)
			end
		end

		DropDownFullscreenFrame.Changed:connect(function(prop)
			if prop ~= "AbsoluteSize" then return end
			updateDropDownSize()
		end)

		updateDropDownSize()
	end

	----------------------- CONNECTIONS/SETUP --------------------------------
	this:UpdateDropDownList(dropDownStringTable)

	DropDownFullscreenFrame.MouseButton1Click:connect(hideDropDownSelection)

	settingsHub.PoppedMenu:connect(function(poppedMenu)
		if poppedMenu == DropDownFullscreenFrame then
			hideDropDownSelection()
		end
	end)

	return this
end


local function CreateSelector(selectionStringTable, startPosition)

	-------------------- VARIABLES ------------------------
	local lastInputDirection = 0
	local TweenTime = 0.15

	-------------------- SETUP ------------------------
	local this = {}

	if type(selectionStringTable) ~= "table" then
		error("CreateSelector selectionStringTable (first arg) is not a table")
		return this
	end

	local indexChangedEvent = Instance.new("BindableEvent")
	indexChangedEvent.Name = "IndexChanged"

	local interactable = true

	this.CurrentIndex = 0

	----------------- GUI SETUP ------------------------

	local noSelectionObject = Util.Create'ImageLabel'
	{
		Image = "",
		BackgroundTransparency = 1
	};

	this.SelectorFrame = Util.Create'ImageButton'
	{
		Name = "Selector",
		Image = "",
		AutoButtonColor = false,
		NextSelectionLeft = this.SelectorFrame,
		NextSelectionRight = this.SelectorFrame,
		BackgroundTransparency = 1,
		Size = UDim2.new(0,502,0,30),
		ZIndex = 2,
		SelectionImageObject = noSelectionObject
	};
	this.SelectorFrame.NextSelectionLeft = this.SelectorFrame
	this.SelectorFrame.NextSelectionRight = this.SelectorFrame
	if isSmallTouchScreen() then
		this.SelectorFrame.Size = UDim2.new(0,400,0,30)
	end

	local leftButton = Util.Create'ImageButton'
	{
		Name = "LeftButton",
		BackgroundTransparency = 1,
		Position = UDim2.new(0,0,0.5,-25),
		Size =  UDim2.new(0,50,0,50),
		Image =  "",
		ZIndex = 2,
		Selectable = false,
		Active = true,
		Parent = this.SelectorFrame
	};
	local rightButton = Util.Create'ImageButton'
	{
		Name = "RightButton",
		BackgroundTransparency = 1,
		Position = UDim2.new(1,-50,0.5,-25),
		Size =  UDim2.new(0,50,0,50),
		Image =  "",
		ZIndex = 2,
		Selectable = false,
		Parent = this.SelectorFrame
	};

	local leftButtonImage = Util.Create'ImageLabel'
	{
		Name = "LeftButton",
		BackgroundTransparency = 1,
		Position = UDim2.new(1,-24,0.5,-15),
		Size =  UDim2.new(0,18,0,30),
		Image =  "rbxasset://textures/ui/Settings/Slider/Left.png",
		ZIndex = 2,
		Active = true,
		Parent = leftButton
	};
	local rightButtonImage = Util.Create'ImageLabel'
	{
		Name = "RightButton",
		BackgroundTransparency = 1,
		Position = UDim2.new(0,6,0.5,-15),
		Size =  UDim2.new(0,18,0,30),
		Image =  "rbxasset://textures/ui/Settings/Slider/Right.png",
		ZIndex = 2,
		Parent = rightButton
	};


	this.Selections = {}

	for i,v in pairs(selectionStringTable) do
		local nextSelection = Util.Create'TextLabel'
		{
			Name = "Selection" .. tostring(i),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1,leftButton.Size.X.Offset * -2, 1, 0),
			Position = UDim2.new(1,0,0,0),
			TextColor3 = Color3.new(1,1,1),
			TextYAlignment = Enum.TextYAlignment.Center,
			Font = Enum.Font.SourceSans,
			FontSize = Enum.FontSize.Size24,
			Text = v,
			ZIndex = 2,
			Visible = false,
			Parent = this.SelectorFrame
		};

		if i == startPosition then
			this.CurrentIndex = i
			nextSelection.Position = UDim2.new(0,leftButton.Size.X.Offset,0,0)
			nextSelection.Visible = true
		end

		this.Selections[i] = nextSelection
	end


	---------------------- FUNCTIONS -----------------------------------
	local function setSelection(index, direction)
		for i, selectionLabel in pairs(this.Selections) do
			local isSelected = (i == index)

			if not selectionLabel:IsDescendantOf(game) then
				this.CurrentIndex = i
				indexChangedEvent:Fire(index)
				return
			end

			local tweenPos = UDim2.new(0,leftButton.Size.X.Offset * direction * 3,0,0)
			if selectionLabel.Visible then
				tweenPos = UDim2.new(0,leftButton.Size.X.Offset * -direction * 3,0,0)
			end

			if tweenPos.X.Offset < 0 then
				tweenPos = UDim2.new(0,tweenPos.X.Offset + (selectionLabel.AbsoluteSize.X/4),0,0)
			end

			if isSelected then
				selectionLabel:TweenPosition(tweenPos, Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0, false, function()
					selectionLabel.Position = tweenPos
					selectionLabel.Visible = true
					PropertyTweener(selectionLabel, "TextTransparency", 1, 0, TweenTime * 1.1, EaseOutQuad)
					selectionLabel:TweenPosition(UDim2.new(0,leftButton.Size.X.Offset,0,0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, TweenTime, false, function(completed)
						if completed then
							selectionLabel.Visible = true
							this.CurrentIndex = i
							indexChangedEvent:Fire(index)
						end
					end)
				end)
			else
				if selectionLabel.Visible then
					PropertyTweener(selectionLabel, "TextTransparency", 0, 1, TweenTime * 1.1, EaseOutQuad)
					selectionLabel:TweenPosition(tweenPos, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, TweenTime * 0.9, false, function(completed)
						if completed then
							selectionLabel.Visible = false
						end
					end)
				end
			end
		end
	end

	local function stepFunc(inputObject, step)
		if not interactable then return end

		if inputObject ~= nil and inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 and inputObject.UserInputType ~= Enum.UserInputType.Gamepad1 
			and inputObject.UserInputType ~= Enum.UserInputType.Keyboard then return end

		if usesSelectedObject() then
			GuiService.SelectedCoreObject = this.SelectorFrame
		end

		local newIndex = step + this.CurrentIndex

		local direction = 0
		if newIndex > this.CurrentIndex then
			direction = 1
		else
			direction = -1
		end

		if newIndex > #this.Selections then
			newIndex = 1
		elseif newIndex < 1 then
			newIndex = #this.Selections
		end


		setSelection(newIndex, direction)
	end

	--------------------- PUBLIC FACING FUNCTIONS -----------------------
	this.IndexChanged = indexChangedEvent.Event

	function this:SetSelectionIndex(newIndex)
		setSelection(newIndex, 1)
	end

	function this:GetSelectedIndex()
		return this.CurrentIndex
	end

	function this:SetZIndex(newZIndex)
		leftButton.ZIndex = newZIndex
		rightButton.ZIndex = newZIndex
		leftButtonImage.ZIndex = newZIndex
		rightButtonImage.ZIndex = newZIndex

		for i = 1, #this.Selections do
			this.Selections[i].ZIndex = newZIndex
		end
	end

	function this:SetInteractable(value)
		interactable = value
		this.SelectorFrame.Selectable = interactable
	end

	--------------------- SETUP -----------------------

	leftButton.InputBegan:connect(function(inputObject) 
		if inputObject.UserInputType == Enum.UserInputType.Gamepad1 then return end
		stepFunc(inputObject, -1) 
	end)
	leftButton.MouseButton1Click:connect(function()
		if UserInputService.TouchEnabled and not UserInputService.GamepadEnabled then
			stepFunc(nil, -1) 
		end
	end)
	rightButton.InputBegan:connect(function(inputObject) 
		if inputObject.UserInputType == Enum.UserInputType.Gamepad1 then return end
		stepFunc(inputObject, 1)
	end)
	rightButton.MouseButton1Click:connect(function()
		if UserInputService.TouchEnabled and not UserInputService.GamepadEnabled then
			stepFunc(nil, 1) 
		end
	end)

	local isInTree = true
	UserInputService.InputBegan:connect(function(inputObject)
		if not interactable then return end
		if not isInTree then return end

		if inputObject.UserInputType ~= Enum.UserInputType.Gamepad1 and inputObject.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if GuiService.SelectedCoreObject ~= this.SelectorFrame then return end

		if inputObject.KeyCode == Enum.KeyCode.DPadLeft or inputObject.KeyCode == Enum.KeyCode.Left or inputObject.KeyCode == Enum.KeyCode.A then
			stepFunc(inputObject, -1)
		elseif inputObject.KeyCode == Enum.KeyCode.DPadRight or inputObject.KeyCode == Enum.KeyCode.Right or inputObject.KeyCode == Enum.KeyCode.D then
			stepFunc(inputObject, 1)
		end
	end)

	UserInputService.InputChanged:connect(function(inputObject)
		if not interactable then return end
		if not isInTree then lastInputDirection = 0 return end

		if inputObject.UserInputType ~= Enum.UserInputType.Gamepad1 then return end
		if GuiService.SelectedCoreObject ~= this.SelectorFrame then return end
		if inputObject.KeyCode ~= Enum.KeyCode.Thumbstick1 then return end


		if inputObject.Position.X > CONTROLLER_THUMBSTICK_DEADZONE and inputObject.Delta.X > 0 and lastInputDirection ~= 1 then
			lastInputDirection = 1
			stepFunc(inputObject, lastInputDirection)
		elseif inputObject.Position.X < -CONTROLLER_THUMBSTICK_DEADZONE and inputObject.Delta.X < 0 and lastInputDirection ~= -1 then
			lastInputDirection = -1
			stepFunc(inputObject, lastInputDirection)
		elseif math.abs(inputObject.Position.X) < CONTROLLER_THUMBSTICK_DEADZONE then
			lastInputDirection = 0
		end
	end)

	this.SelectorFrame.AncestryChanged:connect(function(child, parent)
		isInTree = parent
	end)

	return this
end

local function ShowAlert(alertMessage, okButtonText, okPressedFunc)
	if CoreGui.RobloxGui:FindFirstChild("AlertViewFullScreen") then return end

	local NON_SELECTED_TEXT_COLOR = Color3.new(59/255, 166/255, 241/255)
	local SELECTED_TEXT_COLOR = Color3.new(1,1,1)

	local AlertViewFullScreen = Util.Create'ImageButton'
	{
		Name = "AlertViewFullScreen",
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0,0,0),
		ZIndex = 10,
		Active = true,
		Selectable = false,
		AutoButtonColor = false,
		Parent = CoreGui.RobloxGui
	};

	local AlertViewBacking = Util.Create'ImageLabel'
	{
		Name = "AlertViewBacking",
		Image = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButton.png",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(8,6,46,44),
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 400, 0, 350),
		Position = UDim2.new(0.5, -200, 0.5, -175),
		ZIndex = 10,
		Parent = AlertViewFullScreen
	};
	if CoreGui.RobloxGui.AbsoluteSize.Y <= AlertViewBacking.Size.Y.Offset then
		AlertViewBacking.Size = UDim2.new(AlertViewBacking.Size.X.Scale, AlertViewBacking.Size.X.Offset, 
											AlertViewBacking.Size.Y.Scale, CoreGui.RobloxGui.AbsoluteSize.Y)
		AlertViewBacking.Position = UDim2.new(0.5, -AlertViewBacking.Size.X.Offset/2, 0.5, -AlertViewBacking.Size.Y.Offset/2)
	end

	local AlertViewText = Util.Create'TextLabel'
	{
		Name = "AlertViewText",
		BackgroundTransparency = 1,
		Size = UDim2.new(0.95, 0, 0.6, 0),
		Position = UDim2.new(0.025, 0, 0.05, 0),
		Font = Enum.Font.SourceSans,
		FontSize = Enum.FontSize.Size24,
		Text = alertMessage,
		TextWrapped = true,
		TextColor3 = Color3.new(1,1,1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 10,
		Parent = AlertViewBacking
	};

	local SelectionOverrideObject = Util.Create'ImageLabel'
	{
		Image = "",
		BackgroundTransparency = 1
	};

	local AlertViewButton = Util.Create'TextButton'
	{
		Name = "AlertViewButton",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0.35, 0),
		Position = UDim2.new(0, 0, 0.65, 0),
		Font = Enum.Font.SourceSans,
		FontSize = Enum.FontSize.Size36,
		Text = okButtonText,
		TextColor3 = NON_SELECTED_TEXT_COLOR,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 10,
		SelectionImageObject = SelectionOverrideObject,
		Parent = AlertViewBacking
	};
	AlertViewButton.NextSelectionLeft = AlertViewButton
	AlertViewButton.NextSelectionRight = AlertViewButton
	AlertViewButton.NextSelectionUp = AlertViewButton
	AlertViewButton.NextSelectionDown = AlertViewButton

	AlertViewButton.MouseEnter:connect(function()
		AlertViewButton.TextColor3 = SELECTED_TEXT_COLOR
	end)
	AlertViewButton.MouseLeave:connect(function()
		AlertViewButton.TextColor3 = NON_SELECTED_TEXT_COLOR
	end)

	if usesSelectedObject() then
		Game.GuiService.SelectedCoreObject = AlertViewButton
	end

	local removeId = HttpService:GenerateGUID(false)

	local destroyAlert = function()
		AlertViewFullScreen:Destroy()
		if okPressedFunc then okPressedFunc() end
		ContextActionService:UnbindCoreAction(removeId)
		GuiService.GuiNavigationEnabled = true
	end
	AlertViewFullScreen.MouseButton1Click:connect(destroyAlert)
	AlertViewButton.MouseButton1Click:connect(destroyAlert)
	GuiService.SelectedCoreObject = AlertViewButton

	ContextActionService:BindCoreAction(removeId, destroyAlert, false, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)
end

local function CreateNewSlider(numOfSteps, startStep)
	-------------------- SETUP ------------------------
	local this = {}

	local spacing = 4
	local initialSpacing = 8
	local steps = tonumber(numOfSteps)
	local currentStep = startStep

	local lastInputDirection = 0
	local timeAtLastInput = nil

	local interactable = true

	local renderStepBindName = HttpService:GenerateGUID(false)

	-- this is done to prevent using these values below (trying to keep the variables consistent)
	numOfSteps = ""
	startStep = ""

	if steps <= 0 then
		error("CreateNewSlider failed because numOfSteps (first arg) is 0 or negative, please supply a positive integer")
		return
	end

	local valueChangedEvent = Instance.new("BindableEvent")
	valueChangedEvent.Name = "ValueChanged"

	----------------- GUI SETUP ------------------------

	local noSelectionObject = Util.Create'ImageLabel'
	{
		Image = "",
		BackgroundTransparency = 1
	};

	this.SliderFrame = Util.Create'ImageButton'
	{
		Name = "Slider",
		Image = "",
		AutoButtonColor = false,
		NextSelectionLeft = this.SliderFrame,
		NextSelectionRight = this.SliderFrame,
		BackgroundTransparency = 1,
		Size = UDim2.new(0,502,0,30),
		SelectionImageObject = noSelectionObject
	};
	if isSmallTouchScreen() then
		this.SliderFrame.Size = UDim2.new(0,400,0,30)
	end

	local leftButton = Util.Create'ImageButton'
	{
		Name = "LeftButton",
		BackgroundTransparency = 1,
		Position = UDim2.new(0,0,0.5,-25),
		Size =  UDim2.new(0,50,0,50),
		Image =  "",
		ZIndex = 2,
		Selectable = false,
		Active = true,
		Parent = this.SliderFrame
	};
	local rightButton = Util.Create'ImageButton'
	{
		Name = "RightButton",
		BackgroundTransparency = 1,
		Position = UDim2.new(1,-50,0.5,-25),
		Size =  UDim2.new(0,50,0,50),
		Image =  "",
		ZIndex = 2,
		Selectable = false,
		Active = true,
		Parent = this.SliderFrame
	};

	local leftButtonImage = Util.Create'ImageLabel'
	{
		Name = "LeftButton",
		BackgroundTransparency = 1,
		Position = UDim2.new(1,-24,0.5,-15),
		Size =  UDim2.new(0,18,0,30),
		Image =  "rbxasset://textures/ui/Settings/Slider/Left.png",
		ZIndex = 2,
		Parent = leftButton
	};
	local rightButtonImage = Util.Create'ImageLabel'
	{
		Name = "RightButton",
		BackgroundTransparency = 1,
		Position = UDim2.new(0,6,0.5,-15),
		Size =  UDim2.new(0,18,0,30),
		Image =  "rbxasset://textures/ui/Settings/Slider/Right.png",
		ZIndex = 2,
		Parent = rightButton
	};


	this.Steps = {}
	local stepXSize = 35
	if isSmallTouchScreen() then
		stepXSize = 25
	end

	for i = 1, steps do
		local nextStep = Util.Create'ImageButton'
		{
			Name = "Step" .. tostring(i),
			BackgroundColor3 = SELECTED_COLOR,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Active = false,
			Position = UDim2.new(0,initialSpacing + leftButton.Size.X.Offset + ((stepXSize + spacing) * (i - 1)),0.5,-12),
			Size =  UDim2.new(0,stepXSize,0, 24),
			Image =  "",
			ZIndex = 2,
			Selectable = false,
			Parent = this.SliderFrame
		};

		if i > currentStep then
			nextStep.BackgroundColor3 = NON_SELECTED_COLOR
		end

		if i == 1 or i == steps then
			nextStep.BackgroundTransparency = 1
			nextStep.ScaleType = Enum.ScaleType.Slice
			nextStep.SliceCenter = Rect.new(3,3,32,21)

			if i <= currentStep then
				if i == 1 then
					nextStep.Image = SELECTED_LEFT_IMAGE
				else
					nextStep.Image = SELECTED_RIGHT_IMAGE
				end
			else
				if i == 1 then
					nextStep.Image = NON_SELECTED_LEFT_IMAGE
				else
					nextStep.Image = NON_SELECTED_RIGHT_IMAGE
				end
			end
		end

		this.Steps[#this.Steps + 1] = nextStep
	end

	local xSize = initialSpacing + (leftButton.Size.X.Offset) + this.Steps[#this.Steps].Size.X.Offset + 
					this.Steps[#this.Steps].Position.X.Offset
	this.SliderFrame.Size = UDim2.new(0, xSize, 0, this.SliderFrame.Size.Y.Offset)


	------------------- FUNCTIONS ---------------------
	local function setCurrentStep(newStepPosition)
		if newStepPosition < 0 then newStepPosition = 0 end
		if newStepPosition > steps then newStepPosition = steps end

		if currentStep == newStepPosition then return end

		currentStep = newStepPosition

		for i = 1, steps do
			if i <= currentStep then
				this.Steps[i].BackgroundColor3 = SELECTED_COLOR

				if i == 1 then
					this.Steps[i].Image = SELECTED_LEFT_IMAGE
				elseif i == steps then
					this.Steps[i].Image = SELECTED_RIGHT_IMAGE
				end
			else
				this.Steps[i].BackgroundColor3 = NON_SELECTED_COLOR

				if i == 1 then
					this.Steps[i].Image = NON_SELECTED_LEFT_IMAGE
				elseif i == steps then
					this.Steps[i].Image = NON_SELECTED_RIGHT_IMAGE
				end
			end
		end

		timeAtLastInput = tick()
		valueChangedEvent:Fire(currentStep)
	end

	local function mouseDownFunc(inputObject, newStepPos, repeatAction)
		if not interactable then return end

		if inputObject == nil then return end
		if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 and inputObject.UserInputType ~= Enum.UserInputType.Touch then return end

		if usesSelectedObject() then
			GuiService.SelectedCoreObject = this.SliderFrame
		end

		if repeatAction then
			lastInputDirection = newStepPos - currentStep
		else
			lastInputDirection = 0

			local mouseInputMovedCon = nil
			local mouseInputEndedCon = nil
			mouseInputMovedCon = UserInputService.InputChanged:connect(function( inputObject )
				if inputObject.UserInputType ~= Enum.UserInputType.MouseMovement and inputObject.UserInputType ~= Enum.UserInputType.Touch then return end

				local mousePos = inputObject.Position.X
				for i = 1, steps do
					local stepPosition = this.Steps[i].AbsolutePosition.X
					local stepSize = this.Steps[i].AbsoluteSize.X
					if mousePos >= stepPosition and mousePos <= stepPosition + stepSize then
						setCurrentStep(i)
						break
					elseif i == 1 and mousePos < stepPosition then
						setCurrentStep(0)
						break
					elseif i == steps and mousePos >= stepPosition then
						setCurrentStep(i)
						break
					end
				end
			end)
			mouseInputEndedCon = UserInputService.InputEnded:connect(function( inputObject )
				if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 and inputObject.UserInputType ~= Enum.UserInputType.Touch then return end

				lastInputDirection = 0
				mouseInputEndedCon:disconnect()
				mouseInputMovedCon:disconnect()
			end)
		end

		setCurrentStep(newStepPos)
	end

	local function mouseUpFunc(inputObject)
		if not interactable then return end
		if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

		lastInputDirection = 0
	end

	local function touchClickFunc(inputObject, newStepPos, repeatAction)
		mouseDownFunc(inputObject, newStepPos, repeatAction)
	end

	--------------------- PUBLIC FACING FUNCTIONS -----------------------
	this.ValueChanged = valueChangedEvent.Event

	function this:SetValue(newValue)
		setCurrentStep(newValue)
	end

	function this:GetValue()
		return currentStep
	end

	function this:SetInteractable(value)
		lastInputDirection = 0
		interactable = value
		this.SliderFrame.Selectable = value
	end

	function this:SetZIndex(newZIndex)
		leftButton.ZIndex = newZIndex
		rightButton.ZIndex = newZIndex
		leftButtonImage.ZIndex = newZIndex
		rightButtonImage.ZIndex = newZIndex

		for i = 1, #this.Steps do
			this.Steps[i].ZIndex = newZIndex
		end
	end

	--------------------- SETUP -----------------------

	leftButton.InputBegan:connect(function(inputObject) mouseDownFunc(inputObject, currentStep - 1, true) end)
	leftButton.InputEnded:connect(function(inputObject) mouseUpFunc(inputObject) end)
	leftButton.MouseButton1Click:connect(function()
		if UserInputService.TouchEnabled and not UserInputService.GamepadEnabled then
			touchClickFunc(inputObject, currentStep - 1, true)
		end
	end)
	rightButton.InputBegan:connect(function(inputObject) mouseDownFunc(inputObject, currentStep + 1, true) end)
	rightButton.InputEnded:connect(function(inputObject) mouseUpFunc(inputObject) end)
	rightButton.MouseButton1Click:connect(function()
		if UserInputService.TouchEnabled and not UserInputService.GamepadEnabled then
			touchClickFunc(inputObject, currentStep + 1, true)
		end
	end)
	
	for i = 1, steps do
		this.Steps[i].InputBegan:connect(function(inputObject) mouseDownFunc(inputObject, i) end)
		this.Steps[i].InputEnded:connect(function(inputObject) mouseUpFunc(inputObject) end)
	end

	this.SliderFrame.InputBegan:connect(function(inputObject) mouseDownFunc(inputObject, currentStep) end)
	this.SliderFrame.InputEnded:connect(function(inputObject) mouseUpFunc(inputObject) end)


	local stepSliderFunc = function()
		if timeAtLastInput == nil then return end

		local currentTime = tick()
		local timeSinceLastInput = currentTime - timeAtLastInput

		if timeSinceLastInput >= CONTROLLER_SCROLL_DELTA then
			setCurrentStep(currentStep + lastInputDirection)
		end
	end

	local isInTree = true
	UserInputService.InputBegan:connect(function(inputObject)
		if not interactable then return end
		if not isInTree then return end

		if inputObject.UserInputType ~= Enum.UserInputType.Gamepad1 and inputObject.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if GuiService.SelectedCoreObject ~= this.SliderFrame then return end

		if inputObject.KeyCode == Enum.KeyCode.DPadLeft or inputObject.KeyCode == Enum.KeyCode.Left or inputObject.KeyCode == Enum.KeyCode.A then
			lastInputDirection = -1
			setCurrentStep(currentStep - 1)
		elseif inputObject.KeyCode == Enum.KeyCode.DPadRight or inputObject.KeyCode == Enum.KeyCode.Right or inputObject.KeyCode == Enum.KeyCode.D then
			lastInputDirection = 1
			setCurrentStep(currentStep + 1)
		end
	end)

	UserInputService.InputEnded:connect(function(inputObject)
		if not interactable then return end

		if inputObject.UserInputType ~= Enum.UserInputType.Gamepad1 and inputObject.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if GuiService.SelectedCoreObject ~= this.SliderFrame then return end

		if inputObject.KeyCode == Enum.KeyCode.Thumbstick1 or inputObject.KeyCode == Enum.KeyCode.DPadLeft 
			or inputObject.KeyCode == Enum.KeyCode.DPadRight or inputObject.KeyCode == Enum.KeyCode.Left
			or inputObject.KeyCode == Enum.KeyCode.A or inputObject.KeyCode == Enum.KeyCode.Right or inputObject.KeyCode == Enum.KeyCode.D then
				lastInputDirection = 0
		end
	end)

	UserInputService.InputChanged:connect(function(inputObject)
		if not interactable then 
			lastInputDirection = 0
			return 
		end
		if not isInTree then
			lastInputDirection = 0
			return 
		end

		if inputObject.UserInputType ~= Enum.UserInputType.Gamepad1 then return end
		if GuiService.SelectedCoreObject ~= this.SliderFrame then return end
		if inputObject.KeyCode ~= Enum.KeyCode.Thumbstick1 then return end

		if inputObject.Position.X > CONTROLLER_THUMBSTICK_DEADZONE and inputObject.Delta.X > 0 and lastInputDirection ~= 1 then
			lastInputDirection = 1
			setCurrentStep(currentStep + 1)
		elseif inputObject.Position.X < -CONTROLLER_THUMBSTICK_DEADZONE and inputObject.Delta.X < 0 and lastInputDirection ~= -1 then
			lastInputDirection = -1
			setCurrentStep(currentStep - 1)
		elseif math.abs(inputObject.Position.X) < CONTROLLER_THUMBSTICK_DEADZONE then
			lastInputDirection = 0
		end
	end)

	GuiService.Changed:connect(function(prop)
		if prop ~= "SelectedCoreObject" then return end

		if GuiService.SelectedCoreObject == this.SliderFrame then
			RunService:BindToRenderStep(renderStepBindName, Enum.RenderPriority.Input.Value + 1, stepSliderFunc)
		else
			RunService:UnbindFromRenderStep(renderStepBindName)
		end
	end)

	this.SliderFrame.AncestryChanged:connect(function(child, parent)
		isInTree = parent
	end)

	return this
end

local ROW_HEIGHT = 50
local nextPosTable = {}
local function AddNewRow(pageToAddTo, rowDisplayName, selectionType, rowValues, rowDefault, extraSpacing)
	local nextRowPositionY = 0

	if nextPosTable[pageToAddTo] then
		nextRowPositionY = nextPosTable[pageToAddTo]
	end

	local RowFrame = nil
	if selectionType ~= "TextBox" then
		RowFrame = Util.Create'ImageButton'
		{
			Name = rowDisplayName .. "Frame",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = "",
			Active = false,
			AutoButtonColor = false,
			Size = UDim2.new(1,0,0,ROW_HEIGHT),
			Position = UDim2.new(0,0,0.025,nextRowPositionY),
			ZIndex = 2,
			Selectable = false,
			Parent = pageToAddTo.Page
		};
	end

	if RowFrame and extraSpacing then
		RowFrame.Position = UDim2.new(RowFrame.Position.X.Scale,RowFrame.Position.X.Offset,
										RowFrame.Position.Y.Scale,RowFrame.Position.Y.Offset + extraSpacing)
	end

	local RowLabel = nil
	if selectionType ~= "TextBox" then
		RowLabel = Util.Create'TextLabel'
		{
			Name = rowDisplayName .. "Label",
			Text = rowDisplayName,
			Font = Enum.Font.SourceSansBold,
			FontSize = Enum.FontSize.Size24,
			TextColor3 = Color3.new(1,1,1),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(0,200,1,0),
			Position = UDim2.new(0,10,0,0),
			ZIndex = 2,
			Parent = RowFrame
		};
	end

	local ValueChangerInstance = nil
	if selectionType == "Slider" then
		ValueChangerInstance = CreateNewSlider(rowValues, rowDefault)	
		ValueChangerInstance.SliderFrame.Position = UDim2.new(1,-ValueChangerInstance.SliderFrame.Size.X.Offset,
														0.5,-ValueChangerInstance.SliderFrame.Size.Y.Offset/2)
		ValueChangerInstance.SliderFrame.Parent = RowFrame
	elseif selectionType == "Selector" then
		ValueChangerInstance = CreateSelector(rowValues, rowDefault)
		ValueChangerInstance.SelectorFrame.Position = UDim2.new(1,-ValueChangerInstance.SelectorFrame.Size.X.Offset,
														0.5,-ValueChangerInstance.SelectorFrame.Size.Y.Offset/2)
		ValueChangerInstance.SelectorFrame.Parent = RowFrame
	elseif selectionType == "DropDown" then
		ValueChangerInstance = CreateDropDown(rowValues, rowDefault, pageToAddTo.HubRef)
		ValueChangerInstance.DropDownFrame.Position = UDim2.new(1,-ValueChangerInstance.DropDownFrame.Size.X.Offset - 50,
														0.5,-ValueChangerInstance.DropDownFrame.Size.Y.Offset/2)
		ValueChangerInstance.DropDownFrame.Parent = RowFrame
	elseif selectionType == "TextBox" then
		local SelectionOverrideObject = Util.Create'ImageLabel'
		{
			Image = "",
			BackgroundTransparency = 1,
		};

		ValueChangerInstance = Util.Create'TextBox'
		{
			Size = UDim2.new(1,-10,0,100),
			Position = UDim2.new(0,5,0.025,nextRowPositionY),
			Text = rowDisplayName,
			TextColor3 = Color3.new(49/255, 49/255, 49/255),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.SourceSans,
			FontSize = Enum.FontSize.Size24,
			ZIndex = 2,
			SelectionImageObject = SelectionOverrideObject,
			ClearTextOnFocus = false,
			Parent = pageToAddTo.Page
		};

		ValueChangerInstance.Focused:connect(function()
			if usesSelectedObject() then
				GuiService.SelectedCoreObject = ValueChangerInstance
			end

			if ValueChangerInstance.Text == rowDisplayName then
				ValueChangerInstance.Text = ""
			end
		end)
		if extraSpacing then
			ValueChangerInstance.Position = UDim2.new(ValueChangerInstance.Position.X.Scale,ValueChangerInstance.Position.X.Offset,
										ValueChangerInstance.Position.Y.Scale,ValueChangerInstance.Position.Y.Offset + extraSpacing)
		end
	end

	ValueChangerInstance.Name = rowDisplayName .. "ValueChanger"

	nextRowPositionY = nextRowPositionY + ROW_HEIGHT
	if extraSpacing then
		nextRowPositionY = nextRowPositionY + extraSpacing
	end

	nextPosTable[pageToAddTo] = nextRowPositionY

	if RowFrame then
		RowFrame.MouseButton1Click:connect(function()
			local valueFrame = ValueChangerInstance.SliderFrame 
			if not valueFrame then
				valueFrame = ValueChangerInstance.SliderFrame
			end
			if not valueFrame then
				valueFrame = ValueChangerInstance.DropDownFrame
			end
			if not valueFrame then
				valueFrame = ValueChangerInstance.SelectorFrame
			end

			if valueFrame and valueFrame.Visible and valueFrame.ZIndex > 1 and usesSelectedObject() then
				GuiService.SelectedCoreObject = valueFrame
			end
		end)
	end

	pageToAddTo:AddRow(RowFrame, RowLabel, ValueChangerInstance, extraSpacing)
	return RowFrame, RowLabel, ValueChangerInstance
end


-------- public facing API ----------------
local moduleApiTable = {}

function moduleApiTable:Create(instanceType)
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

function moduleApiTable:GetEaseLinear()
	return Linear
end
function moduleApiTable:GetEaseOutQuad()
	return EaseOutQuad
end
function moduleApiTable:GetEaseInOutQuad()
	return EaseInOutQuad
end

function moduleApiTable:CreateNewSlider(numOfSteps, startStep)
	return CreateNewSlider(numOfSteps, startStep)
end

function moduleApiTable:CreateNewSelector(selectionStringTable, startPosition)
	return CreateSelector(selectionStringTable, startPosition)
end

function moduleApiTable:CreateNewDropDown(dropDownStringTable, startPosition)
	return CreateDropDown(dropDownStringTable, startPosition, nil)
end

function moduleApiTable:AddNewRow(pageToAddTo, rowDisplayName, selectionType, rowValues, rowDefault, extraSpacing)
	return AddNewRow(pageToAddTo, rowDisplayName, selectionType, rowValues, rowDefault, extraSpacing)
end

function moduleApiTable:ShowAlert(alertMessage, okButtonText, okPressedFunc)
	ShowAlert(alertMessage, okButtonText, okPressedFunc)
end

function moduleApiTable:IsSmallTouchScreen()
	return isSmallTouchScreen()
end

function moduleApiTable:MakeStyledButton(name, text, size, clickFunc)
	return MakeButton(name, text, size, clickFunc)
end

function moduleApiTable:CreateSignal()
	return CreateSignal()
end

function  moduleApiTable:UsesSelectedObject()
	return usesSelectedObject();
end

function moduleApiTable:TweenProperty(instance, prop, start, final, duration, easingFunc, cbFunc)
	return PropertyTweener(instance, prop, start, final, duration, easingFunc, cbFunc)
end

return moduleApiTable