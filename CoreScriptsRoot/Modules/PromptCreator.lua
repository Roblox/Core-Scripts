--[[
	// Filename: PromptCreator.lua
	// Version 1.0
	// Written by: TheGamer101
	// Description: General module for prompting players to confirm or reject something.
	// For usage example see the BlockPlayerPrompt module.
]]--

local moduleApiTable = {}

local CoreGuiService = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local RobloxGui = CoreGuiService:WaitForChild("RobloxGui")
local CoreGuiModules = RobloxGui:WaitForChild("Modules")
local TenFootInterface = require(CoreGuiModules:WaitForChild("TenFootInterface"))
local VRModules = CoreGuiModules:WaitForChild("VR")
local VRDialogModule = require(VRModules:WaitForChild("Dialog"))

local IsTenFootInterface = TenFootInterface:IsEnabled()
local IsVRMode = false

local IsCurrentlyPrompting = false
local IsPromptWaiting = false  -- Are we waiting for the prompt callback to execute.

local ScaleFactor = IsTenFootInterface and 2 or 1
local LastInputWasGamepad = false

-- Inital prompt options. These are passed to CreatePrompt.
local DefaultPromptOptions = {
	WindowTitle = "Confirm",
	MainText = "Is this okay?",
	AdditonalText = nil,
	ConfirmationText = "Confirm",
	CancelText = "Cancel",
	CancelActive = true,
	Image = nil,
	PromptCompletedCallback = nil,
	CallbackWaitingText = "Waiting...",
}

-- Can be optionally returned from the PromptCompletedCallback.
-- Creates an extra confirmation dialog after
local DefaultPromptFinishedOptions = {
	WindowTitle = "Done",
	MainText = "Successfully completed action",
	AdditonalText = nil,
	ConfirmationText = "Okay",
	Image = nil,
	PromptFinishedCallback = nil,
}

local GamePadButtons = {}
local ButtonTextObjects = {}

local PromptCallback = nil
local LastPromptOptions = nil

--[[ Constants ]]--
-- Images
local BUTTON = 'rbxasset://textures/ui/VR/button.png'
local BUTTON_DOWN = 'rbxasset://textures/ui/VR/buttonSelected.png'
local A_BUTTON = "rbxasset://textures/ui/Settings/Help/AButtonDark.png"
local B_BUTTON = "rbxasset://textures/ui/Settings/Help/BButtonDark.png"

-- Context Actions
local CONTROLLER_CONFIRM_ACTION_NAME = "CoreScriptPromptCreatorConfirm"
local CONTROLLER_CANCEL_ACTION_NAME = "CoreScriptPromptCreatorCancel"
local FREEZE_CONTROLLER_ACTION_NAME = "doNothingActionPromptCreator"
local FREEZE_THUMBSTICK1_ACTION_NAME = "doNothingThumbstick1PromptCreator"
local FREEZE_THUMBSTICK2_ACTION_NAME = "doNothingThumbstick2PromptCreator"

-- GUI constants
local TWEEN_TIME = 0.3

local DIALOG_SIZE = UDim2.new(0, 324, 0, 240)
local DIALOG_SIZE_TENFOOT = UDim2.new(0, 324*ScaleFactor, 0, 240*ScaleFactor)
local SHOW_POSITION = UDim2.new(0.5, -162, 0.5, -120)
local SHOW_POSITION_TENFOOT = UDim2.new(0.5, -162*ScaleFactor, 0.5, -120*ScaleFactor)
local HIDE_POSITION = UDim2.new(0.5, -162, 0, -181)
local HIDE_POSITION_TENFOOT = UDim2.new(0.5, -162*ScaleFactor, 0, -180*ScaleFactor - 1)

local TITLE_HEIGHT = 40
local TITLE_TEXTSIZE = 24
local TITLE_HEIGHT_TENFOOT = 80
local TITLE_TEXTSIZE_TENFOOT = 48

local LARGE_TEXTSIZE = 42

local BTN_WIDTH = 0.5
local BTN_HEIGHT = 0.225
local BTN_MARGIN = 20
local BTN_SIZE = UDim2.new(BTN_WIDTH, -BTN_MARGIN * 1.25, BTN_HEIGHT, 0)

local BTN_1_POS = UDim2.new(0.25, 0, 1 - BTN_HEIGHT, -BTN_MARGIN)
local BTN_1_POS_TENFOOT = BTN_1_POS

local BTN_L_POS = UDim2.new(0, BTN_MARGIN, 1 - BTN_HEIGHT, -BTN_MARGIN)
local BTN_R_POS = UDim2.new(0.5, BTN_MARGIN * 0.25, 1 - BTN_HEIGHT, -BTN_MARGIN)

local BTN_MARGIN_TENFOOT = 20 * ScaleFactor
local BTN_SIZE_TENFOOT = UDim2.new(BTN_WIDTH, -BTN_MARGIN_TENFOOT * 1.25, BTN_HEIGHT, 0)
local BTN_L_POS_TENFOOT = UDim2.new(0, BTN_MARGIN_TENFOOT, 1 - BTN_HEIGHT, -BTN_MARGIN_TENFOOT)
local BTN_R_POS_TENFOOT = UDim2.new(0.5, BTN_MARGIN_TENFOOT * 0.25, 1 - BTN_HEIGHT, -BTN_MARGIN_TENFOOT)

--[[ Gui Creation Functions ]]--
local function createFrame(name, size, position, bgTransparency, bgColor)
	local frame = Instance.new('Frame')
	frame.Name = name
	frame.Size = size
	frame.Position = position or UDim2.new(0, 0, 0, 0)
	frame.BackgroundTransparency = bgTransparency
	frame.BackgroundColor3 = bgColor or Color3.new()
	frame.BorderSizePixel = 0
	frame.ZIndex = 8

	return frame
end

local function createTextLabel(name, size, position, font, textSize, text)
	local textLabel = Instance.new('TextLabel')
	textLabel.Name = name
	textLabel.Size = size or UDim2.new(0, 0, 0, 0)
	textLabel.Position = position
	textLabel.BackgroundTransparency = 1
	textLabel.Font = font
	textLabel.TextSize = textSize
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.Text = text
	textLabel.ZIndex = 8

	return textLabel
end

local function createImageLabel(name, size, position, image)
	local imageLabel = Instance.new('ImageLabel')
	imageLabel.Name = name
	imageLabel.Size = size
	imageLabel.BackgroundTransparency = 1
	imageLabel.Position = position
	imageLabel.Image = image

	return imageLabel
end

local function createImageButtonWithText(name, position, image, imageDown, text, font)
	local imageButton = Instance.new('ImageButton')
	imageButton.Name = name
	imageButton.Size = IsTenFootInterface and BTN_SIZE_TENFOOT or BTN_SIZE
	imageButton.Position = position
	imageButton.Image = image
	imageButton.BackgroundTransparency = 1
	imageButton.AutoButtonColor = false
	imageButton.ZIndex = 8
	imageButton.Modal = true
	imageButton.SelectionImageObject = Instance.new("ImageLabel")
	imageButton.SelectionImageObject.Name = "EmptySelectionImage"
	imageButton.SelectionImageObject.BackgroundTransparency = 1
	imageButton.SelectionImageObject.Image = ""

	local textLabel = createTextLabel(name.."Text", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), font, IsTenFootInterface and LARGE_TEXTSIZE or 24, text)
	textLabel.ZIndex = 9
	textLabel.Parent = imageButton
	table.insert(ButtonTextObjects, textLabel)

	imageButton.MouseEnter:connect(function()
		imageButton.Image = imageDown
	end)
	imageButton.MouseLeave:connect(function()
		imageButton.Image = image
	end)
	imageButton.MouseButton1Click:connect(function()
		imageButton.Image = image
	end)
	imageButton.SelectionGained:connect(function()
		imageButton.Image = imageDown
	end)
	imageButton.SelectionLost:connect(function()
		imageButton.Image = image
	end)

	return imageButton
end

--[[ Begin Gui Creation ]]--
local PromptDialog = IsTenFootInterface and createFrame("PromptDialog", DIALOG_SIZE_TENFOOT, HIDE_POSITION_TENFOOT, 1, nil) or
																						createFrame("PromptDialog", DIALOG_SIZE, HIDE_POSITION, 1, nil)
PromptDialog.Visible = false
PromptDialog.Parent = RobloxGui
PromptDialog.Active = true

local ContainerFrame = createFrame("ContainerFrame", UDim2.new(1, 0, 1, 0), nil, 0.5, Color3.new(31/255,31/255,31/255))
ContainerFrame.ZIndex = 8
ContainerFrame.Parent = PromptDialog

local WaitingFrame = createFrame("WaitingFrame", UDim2.new(1, 0, 1, 0), nil, 0.5, Color3.new(31/255,31/255,31/255))
WaitingFrame.ZIndex = 8
WaitingFrame.Visible = false
WaitingFrame.Parent = PromptDialog

local WaitingText = createTextLabel("WaitingText", nil, UDim2.new(0.5, 0, 0.5, -36), Enum.Font.SourceSans,
	IsTenFootInterface and LARGE_TEXTSIZE or 36, "")
WaitingText.Parent = WaitingFrame

local WaitingFrames = {}
local xOffset = -40
for i = 1, 3 do
	local frame = createFrame("Waiting", UDim2.new(0, 16, 0, 16), UDim2.new(0.5, xOffset, 0.5, 0), 0, Color3.new(132/255, 132/255, 132/255))
	table.insert(WaitingFrames, frame)
	frame.Parent = WaitingFrame
	xOffset = xOffset + 32
end


function AddDefaultsToPromptOptions(promptOptions, defaultPromptOptions)
	for key, value in pairs(defaultPromptOptions) do
		if promptOptions[key] == nil then
			promptOptions[key] = value
		end
	end
end

function CreatePromptFromOptions(promptOptions)
	ContainerFrame:ClearAllChildren()

	local windowTitle = createTextLabel("WindowTitle", UDim2.new(1, 0, 0, IsTenFootInterface and TITLE_HEIGHT_TENFOOT or TITLE_HEIGHT),
																			UDim2.new(0, 0, 0, 0), Enum.Font.SourceSansBold, IsTenFootInterface and TITLE_TEXTSIZE_TENFOOT or TITLE_TEXTSIZE,
																			promptOptions.WindowTitle)
	windowTitle.Parent = ContainerFrame
	windowTitle.ZIndex = 9

	local colorStripe = createFrame("ColorStripe", UDim2.new(1, 0, 0, 2), nil, 0, Color3.new(0.01, 0.72, 0.34))
	colorStripe.Position = UDim2.new(0, 0, 0, IsTenFootInterface and TITLE_HEIGHT_TENFOOT or TITLE_HEIGHT)
	colorStripe.ZIndex = 9
	colorStripe.Parent = ContainerFrame

	local mainText = nil
	local image = nil

	if promptOptions.Image then
		image = createImageLabel("Image", UDim2.new(0, 64*ScaleFactor, 0, 96*ScaleFactor), UDim2.new(0, 27*ScaleFactor, 0, 60*ScaleFactor), promptOptions.Image)
		image.ZIndex = 9
		image.Parent = ContainerFrame

		mainText = createTextLabel("MainText", UDim2.new(0, 210*ScaleFactor - 20, 0, 96*ScaleFactor), UDim2.new(0, 110*ScaleFactor, 0, 58*ScaleFactor),
			Enum.Font.SourceSansBold, IsTenFootInterface and 42 or 24, promptOptions.MainText)
	else
		mainText = createTextLabel("MainText", UDim2.new(1, -20*ScaleFactor, 0, 96*ScaleFactor), UDim2.new(0, 10*ScaleFactor, 0, 58*ScaleFactor),
			Enum.Font.SourceSansBold, IsTenFootInterface and 48 or 32, promptOptions.MainText)
	end

	mainText.TextXAlignment = Enum.TextXAlignment.Left
	mainText.TextYAlignment = Enum.TextYAlignment.Top
	mainText.TextWrapped = true
	mainText.Parent = ContainerFrame

	if promptOptions.AdditonalText then
		mainText.Size = UDim2.new(0, mainText.AbsoluteSize.X, 0, 76*ScaleFactor)
		mainText.TextSize = IsTenFootInterface and 42 or 26
		if image then
			image.Size = UDim2.new(0, 64*ScaleFactor, 0, 76*ScaleFactor)
			mainText.TextSize = IsTenFootInterface and 38 or 24
		end

		local additonalText = createTextLabel("AdditonalText", UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 140*ScaleFactor), Enum.Font.SourceSans,
			IsTenFootInterface and 32 or 18, promptOptions.AdditonalText)
		additonalText.TextYAlignment = Enum.TextYAlignment.Top
		additonalText.TextWrapped = true
		additonalText.ZIndex = 9
		additonalText.Parent = ContainerFrame
	end

	local buttonSliceCenter = Rect.new(8, 8, 64 - 8, 64 - 8)
	local buttonScaleType = Enum.ScaleType.Slice

	local confirmButton = nil

	if promptOptions.CancelActive then
		confirmButton = createImageButtonWithText("ConfirmButton",
	    IsTenFootInterface and BTN_L_POS_TENFOOT or BTN_L_POS, BUTTON, BUTTON_DOWN, promptOptions.ConfirmationText, Enum.Font.SourceSansBold)
	else
		confirmButton = createImageButtonWithText("ConfirmButton", IsTenFootInterface and BTN_1_POS_TENFOOT or BTN_1_POS, BUTTON,
		  BUTTON_DOWN, promptOptions.ConfirmationText, Enum.Font.SourceSans)
	end

	confirmButton.Parent = ContainerFrame
	confirmButton.ScaleType = buttonScaleType
	confirmButton.SliceCenter = buttonSliceCenter

	confirmButton.MouseButton1Click:connect(function()
		OnPromptEnded(true)
	end)

	local confirmButtonGamepadImage = Instance.new("ImageLabel")
	confirmButtonGamepadImage.BackgroundTransparency = 1
	confirmButtonGamepadImage.Image = A_BUTTON
	confirmButtonGamepadImage.Size = UDim2.new(1, -16, 1, -16)
	confirmButtonGamepadImage.SizeConstraint = Enum.SizeConstraint.RelativeYY
	confirmButtonGamepadImage.Parent = confirmButton
	confirmButtonGamepadImage.Position = UDim2.new(0, 8, 0, 8)
	confirmButtonGamepadImage.Visible = LastInputWasGamepad
	confirmButtonGamepadImage.ZIndex = confirmButton.ZIndex
	table.insert(GamePadButtons, confirmButtonGamepadImage)

	if promptOptions.CancelActive then
		local cancelButton = createImageButtonWithText("CancelButton", IsTenFootInterface and BTN_R_POS_TENFOOT or BTN_R_POS, BUTTON, BUTTON_DOWN,
			promptOptions.CancelText, Enum.Font.SourceSans)
		cancelButton.Parent = ContainerFrame
		cancelButton.ScaleType = buttonScaleType
		cancelButton.SliceCenter = buttonSliceCenter

		cancelButton.MouseButton1Click:connect(function()
			OnPromptEnded(false)
		end)

		local cancelButtonGamepadImage = confirmButtonGamepadImage:Clone()
		cancelButtonGamepadImage.Image = B_BUTTON
		cancelButtonGamepadImage.ZIndex = cancelButton.ZIndex
		cancelButtonGamepadImage.Parent = cancelButton
		table.insert(GamePadButtons, cancelButtonGamepadImage)
	end
end

function ShowPrompt()
	PromptDialog.Visible = true
	if IsTenFootInterface then
		UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.ForceHide
	end
	if IsVRMode then
		PromptDialog.Position = SHOW_POSITION
		PromptDialogVR:SetContent(PromptDialog)
		PromptDialogVR:Show(true)
		DisableControllerMovement()
	else
		PromptDialog:TweenPosition(IsTenFootInterface and SHOW_POSITION_TENFOOT or SHOW_POSITION, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, TWEEN_TIME, true)
		DisableControllerMovement()
		EnableControllerInput()
	end
end

function HidePrompt()
	local function onClosed()
		PromptDialog.Visible = false
		IsCurrentlyPrompting = false
		IsFinalPromptConfirmation = false
		if IsTenFootInterface then
			UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None
		end
	end
	if IsVRMode then
		PromptDialog.Position = HIDE_POSITION
		PromptDialogVR:Close()
		onClosed()
	else
		PromptDialog:TweenPosition(IsTenFootInterface and HIDE_POSITION_TENFOOT or HIDE_POSITION, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, TWEEN_TIME, true, onClosed)
	end
end

function DoCreatePrompt(promptOptions)
	PromptCallback = promptOptions.PromptCompletedCallback
	AddDefaultsToPromptOptions(promptOptions, DefaultPromptOptions)
	LastPromptOptions = promptOptions
	CreatePromptFromOptions(promptOptions)
	ShowPrompt()
end


local function TweenBackgroundColor(frame, endColor, duration)
	local t = 0
	local prevTime = tick()
	local startColor = frame.BackgroundColor3
	while t < duration do
		local s = t / duration
		frame.BackgroundColor3 = startColor:lerp(endColor, s)

		t = t + (tick() - prevTime)
		prevTime = tick()
		wait()
	end
	frame.BackgroundColor3 = endColor
end

function DoPromptWaiting()
	WaitingText.Text = LastPromptOptions.CallbackWaitingText
	ContainerFrame.Visible = false
	WaitingFrame.Visible = true
	spawn(function()
		local i = 1
		while IsPromptWaiting do
			local frame = WaitingFrames[i]
			local prevPosition = frame.Position
			local newPosition = UDim2.new(prevPosition.X.Scale, prevPosition.X.Offset, prevPosition.Y.Scale, prevPosition.Y.Offset - 2)
			spawn(function()
				TweenBackgroundColor(frame, Color3.new(0, 162/255, 1), 0.25)
			end)
			frame:TweenSizeAndPosition(UDim2.new(0, 16, 0, 20), newPosition, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.25, true, function()
				spawn(function()
					TweenBackgroundColor(frame, Color3.new(132/255, 132/255, 132/255), 0.25)
				end)
				frame:TweenSizeAndPosition(UDim2.new(0, 16, 0, 16), prevPosition, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.25, true)
			end)
			i = i + 1
			if i > 3 then
				i = 1
				wait(0.25)	-- small pause when starting from 1
			end
			wait(0.5)
		end
	end)
end

function StopPromptWaiting()
	WaitingFrame.Visible = false
	ContainerFrame.Visible = true
end

function DoFinalPromptConfirmation(promptFinishedOptions)
	AddDefaultsToPromptOptions(promptFinishedOptions, DefaultPromptFinishedOptions)
	promptFinishedOptions.CancelActive = false
	CreatePromptFromOptions(promptFinishedOptions)
end

function OnPromptEnded(okayButtonPressed)
	if IsPromptWaiting then
		return
	end
	if IsFinalPromptConfirmation then
		if PromptCallback then
			PromptCallback()
		end
		HidePrompt()
		EnableControllerMovement()
		DisableControllerInput()
	else
		if PromptCallback then
			local promptFinishedOptions = nil
			IsPromptWaiting = true
			DoPromptWaiting()
			if LastPromptOptions.CancelActive then
				promptFinishedOptions = PromptCallback(okayButtonPressed)
			else
				promptFinishedOptions = PromptCallback(true)
			end
			IsPromptWaiting = false
			StopPromptWaiting()
			if promptFinishedOptions then
				IsFinalPromptConfirmation = true
				DoFinalPromptConfirmation(promptFinishedOptions)
			else
				HidePrompt()
				EnableControllerMovement()
				DisableControllerInput()
			end
		else
			HidePrompt()
			EnableControllerMovement()
			DisableControllerInput()
		end
	end
end

--[[ Controller input handling ]]

function NoOpFunc() end

function EnableControllerMovement()
	ContextActionService:UnbindCoreAction(FREEZE_THUMBSTICK1_ACTION_NAME)
	ContextActionService:UnbindCoreAction(FREEZE_THUMBSTICK2_ACTION_NAME)
	ContextActionService:UnbindCoreAction(FREEZE_CONTROLLER_ACTION_NAME)
end

function DisableControllerMovement()
	ContextActionService:BindCoreAction(FREEZE_CONTROLLER_ACTION_NAME, NoOpFunc, false, Enum.UserInputType.Gamepad1)
	ContextActionService:BindCoreAction(FREEZE_THUMBSTICK1_ACTION_NAME, NoOpFunc, false, Enum.KeyCode.Thumbstick1)
	ContextActionService:BindCoreAction(FREEZE_THUMBSTICK2_ACTION_NAME, NoOpFunc, false, Enum.KeyCode.Thumbstick2)
end

function EnableControllerInput()
	--accept the prompt when the user presses the a button
	ContextActionService:BindCoreAction(
		CONTROLLER_CONFIRM_ACTION_NAME,
		function(actionName, inputState, inputObject)
			if inputState ~= Enum.UserInputState.Begin then return end

			OnPromptEnded(true)
		end,
		false,
		Enum.KeyCode.ButtonA
	)

	--cancel the prompt when the user pressed the b button.
	ContextActionService:BindCoreAction(
		CONTROLLER_CANCEL_ACTION_NAME,
		function(actionName, inputState, inputObject)
			if inputState ~= Enum.UserInputState.Begin then return end

			if LastPromptOptions.CancelActive then
				OnPromptEnded(false)
			end
		end,
		false,
		Enum.KeyCode.ButtonB
	)
end

function DisableControllerInput()
	ContextActionService:UnbindCoreAction(CONTROLLER_CONFIRM_ACTION_NAME)
	ContextActionService:UnbindCoreAction(CONTROLLER_CANCEL_ACTION_NAME)
end

function ShowGamepadButtons()
	for _, button in pairs(GamePadButtons) do
		button.Visible = true
	end

	for _, buttonText in pairs(ButtonTextObjects) do
		local inset = buttonText.AbsoluteSize.Y - 15
		buttonText.Position = UDim2.new(0, inset, 0, 0)
		buttonText.Size = UDim2.new(1, -inset, 1, 0)
	end
end

function HideGamepadButtons()
	for _, button in pairs(GamePadButtons) do
		button.Visible = false
	end
	for _, buttonText in pairs(ButtonTextObjects) do
		buttonText.Position = UDim2.new(0, 0, 0, 0)
		buttonText.Size = UDim2.new(1, 0, 1, 0)
	end
end

function valueInTable(val, tab)
	for _, v in pairs(tab) do
		if v == val then
			return true
		end
	end
	return false
end

function OnInputChanged(inputObject)
	local inputType = inputObject.UserInputType
	local inputTypes = Enum.UserInputType
	if not IsVRMode and valueInTable(inputType, {inputTypes.Gamepad1, inputTypes.Gamepad2, inputTypes.Gamepad3, inputTypes.Gamepad4}) then
		if inputObject.KeyCode == Enum.KeyCode.Thumbstick1 or inputObject.KeyCode == Enum.KeyCode.Thumbstick2 then
			if math.abs(inputObject.Position.X) > 0.1 or math.abs(inputObject.Position.Z) > 0.1 or math.abs(inputObject.Position.Y) > 0.1 then
				LastInputWasGamepad = true
				ShowGamepadButtons()
			end
		else
			LastInputWasGamepad = true
			ShowGamepadButtons()
		end
	else
		LastInputWasGamepad = false
		HideGamepadButtons()
	end
end
UserInputService.InputChanged:connect(OnInputChanged)
UserInputService.InputBegan:connect(OnInputChanged)
HideGamepadButtons()

--[[ VR changed handling ]]
function OnVREnabled(vrEnabled)
	if vrEnabled then
		if not PromptDialogVR then
			PromptDialogVR = VRDialogModule.new()
		end
		PromptDialogVR:SetContent(PromptDialog)
		IsVRMode = true
	else
		IsVRMode = false
		if PromptDialogVR then
			PromptDialogVR:SetContent(nil)
		end
		PromptDialog.Parent = RobloxGui
	end
end

spawn(function()
	OnVREnabled(UserInputService.VREnabled)
end)

UserInputService.Changed:connect(function(prop)
	if prop == "VREnabled" then
		OnVREnabled(UserInputService.VREnabled)
	end
end)

-- [[ Public Methods ]]
function moduleApiTable:CreatePrompt(promptOptions)
	if IsCurrentlyPrompting then
		return false
	end
	IsCurrentlyPrompting = true
	DoCreatePrompt(promptOptions)
	return true
end

return moduleApiTable
