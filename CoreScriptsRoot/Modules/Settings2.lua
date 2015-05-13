--[[
		Filename: Settings2.lua
		Written by: jmargh
		Version 1.4
		Description: Implements the in game settings menu with the new control schemes
--]]

--[[ Services ]]--
local CoreGui = game:GetService('CoreGui')
local GuiService = game:GetService('GuiService')
local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local ContextActionService = game:GetService('ContextActionService')
local CoreGuiService = game:GetService('CoreGui')
--
local Settings = UserSettings()
local GameSettings = Settings.GameSettings
local RbxGuiLibaray = nil
if LoadLibrary then
	RbxGuiLibaray = LoadLibrary("RbxGui")
end

--[[ Script Variables ]]--
while not Players.LocalPlayer do
	wait()
end
local LocalPlayer = Players.LocalPlayer
local RobloxGui = CoreGuiService:WaitForChild('RobloxGui')

--[[ Client Settings ]]--
local IsMacClient = false
local isMacSuccess, isMac = pcall(function() return not GuiService.IsWindows end)
IsMacClient = isMacSuccess and isMac

local IsTouchClient = false
local isTouchSuccess, isTouch = pcall(function() return UserInputService.TouchEnabled end)
IsTouchClient = isTouchSuccess and isTouch

--[[ Fast Flags ]]--
local topbarSuccess, topbarFlagValue = pcall(function() return settings():GetFFlag("UseInGameTopBar") end)
local isTopBar = topbarSuccess and topbarFlagValue == true
local luaControlsSuccess, luaControlsFlagValue = pcall(function() return settings():GetFFlag("UseLuaCameraAndControl") end)
local isLuaControls = luaControlsSuccess and luaControlsFlagValue == true

local gamepadSupportSuccess, gamepadSupportFlagValue = pcall(function() return settings():GetFFlag("TopbarGamepadSupport") end)
local isGamepadSupport = gamepadSupportSuccess and gamepadSupportFlagValue == true

--[[ Parent Frames ]]--
-- TODO: Remove all references to engine created gui
local ControlFrame = RobloxGui:WaitForChild('ControlFrame')
local TopLeftControl = ControlFrame:WaitForChild('TopLeftControl')
local BottomLeftControl = ControlFrame:WaitForChild('BottomLeftControl')

--[[ Control Variables ]]--
local CurrentYOffset = 24
local IsShiftLockEnabled = false
if isLuaControls then
	IsShiftLockEnabled = LocalPlayer.DevEnableMouseLock and GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch
else
	IsShiftLockEnabled = GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch
end
local IsResumingGame = false
-- TODO: Change dev console script to parent this to somewhere other than an engine created gui
local BindableFunc_ToggleDevConsole = ControlFrame:WaitForChild('ToggleDevConsole')
local MenuStack = {}
local IsHelpMenuOpen = false
local CurrentOpenedDropDownMenu = nil
local IsMenuClosing = false
local IsRecordingVideo = false
local IsSmallScreen = GuiService:GetScreenResolution().y <= 500

--[[ Debug Variables - PLEASE RESET BEFORE COMMIT ]]--
local isTestingReportAbuse = false

--[[ Constants ]]--
local GRAPHICS_QUALITY_LEVELS = 10
local BASE_Z_INDEX = 4
local BG_TRANSPARENCY = 0.5
local TWEEN_TIME = 0.2
local SHOW_MENU_POS = IsSmallScreen and UDim2.new(0, 0, 0, 0) or UDim2.new(0.5, -262, 0.5, -215)
local CLOSE_MENU_POS = IsSmallScreen and UDim2.new(0, 0, -1, 0) or UDim2.new(0.5, -262, -0.5, -215)
local CAMERA_MODE_DEFAULT_STRING = IsTouchClient and "Default (Follow)" or "Default (Classic)"
local MOVEMENT_MODE_DEFAULT_STRING = IsTouchClient and "Default (Thumbstick)" or "Default (Keyboard)"
local MENU_BTN_LRG = UDim2.new(0, 340, 0, 50)
local MENU_BTN_SML = UDim2.new(0, 168, 0, 50)
local STOP_RECORD_IMG = 'rbxasset://textures/ui/RecordStop.png'
local HELP_IMG = {
	CLASSIC_MOVE = 'http://www.roblox.com/Asset?id=45915798',
	SHIFT_LOCK = 'http://www.roblox.com/asset?id=54071825',
	MOVEMENT = 'http://www.roblox.com/Asset?id=45915811',
	GEAR = 'http://www.roblox.com/Asset?id=45917596',
	ZOOM = 'http://www.roblox.com/Asset?id=45915825'
}

local PC_CHANGED_PROPS = {
	DevComputerMovementMode = true,
	DevComputerCameraMode = true,
	DevEnableMouseLock = true,
}
local TOUCH_CHANGED_PROPS = {
	DevTouchMovementMode = true,
	DevTouchCameraMode = true,
}

local GRAPHICS_QUALITY_TO_INT = {
	["Enum.SavedQualitySetting.Automatic"] = 0,
	["Enum.SavedQualitySetting.QualityLevel1"] = 1,
	["Enum.SavedQualitySetting.QualityLevel2"] = 2,
	["Enum.SavedQualitySetting.QualityLevel3"] = 3,
	["Enum.SavedQualitySetting.QualityLevel4"] = 4,
	["Enum.SavedQualitySetting.QualityLevel5"] = 5,
	["Enum.SavedQualitySetting.QualityLevel6"] = 6,
	["Enum.SavedQualitySetting.QualityLevel7"] = 7,
	["Enum.SavedQualitySetting.QualityLevel8"] = 8,
	["Enum.SavedQualitySetting.QualityLevel9"] = 9,
	["Enum.SavedQualitySetting.QualityLevel10"] = 10,
}

local ABUSE_TYPES_PLAYER = {
	"Swearing",
	"Inappropriate Username",
	"Bullying",
	"Scamming",
	"Dating",
	"Cheating/Exploiting",
	"Personal Question",
	"Offsite Links",
}

local ABUSE_TYPES_GAME = {
	"Inappropriate Content",
	"Bad Model or Script",
	"Offsite Link",
}


--[[ Gui Creation Helper Functions ]]--

local function Signal()
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

local function createTextButton(size, position, text, fontSize, style)
	local textButton = Instance.new('TextButton')
	textButton.Size = size
	textButton.Position = position
	textButton.Font = Enum.Font.SourceSansBold
	textButton.FontSize = fontSize
	textButton.Style = style
	textButton.TextColor3 = Color3.new(1, 1, 1)
	textButton.Text = text
	textButton.ZIndex = BASE_Z_INDEX + 4

	return textButton
end

local function createTextLabel(position, text, name)
	local textLabel = Instance.new('TextLabel')
	textLabel.Name = name
	textLabel.Size = UDim2.new(0, 0, 0, 0)
	textLabel.Position = position
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.FontSize = Enum.FontSize.Size18
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextXAlignment = Enum.TextXAlignment.Right
	textLabel.ZIndex = BASE_Z_INDEX + 4
	textLabel.Text = text

	return textLabel
end

local function createMenuFrame(name, position)
	local frame = Instance.new('Frame')
	frame.Name = name
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.Position = position
	frame.BackgroundTransparency = 1
	frame.ZIndex = BASE_Z_INDEX + 4

	pcall(function() GuiService:AddSelectionParent(name .. "Group", frame) end)

	return frame
end

local function createMenuTitleLabel(name, text, yOffset)
	local label = Instance.new('TextLabel')
	label.Name = name
	label.Size = UDim2.new(0, 0, 0, 0)
	label.Position = UDim2.new(0.5, 0, 0, yOffset)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SourceSansBold
	label.FontSize = Enum.FontSize.Size36
	label.TextColor3 = Color3.new(1, 1, 1)
	label.ZIndex = BASE_Z_INDEX + 4
	label.Text = text

	return label
end

local function closeCurrentDropDownMenu()
	if CurrentOpenedDropDownMenu and CurrentOpenedDropDownMenu.IsOpen() then
		CurrentOpenedDropDownMenu.Close()
	end
	CurrentOpenedDropDownMenu = nil
end

--[[ Gui Creation ]]--
-- Main Container for everything in the settings menu

local SettingsShowSignal = Signal()

local SettingsMenuFrame = Instance.new('Frame')
SettingsMenuFrame.Name = "SettingsMenu"
SettingsMenuFrame.Size = UDim2.new(1, 0, 1, 0)
SettingsMenuFrame.BackgroundTransparency = 1

local SettingsButton = Instance.new('ImageButton')
SettingsButton.Name = "SettingsButton"
SettingsButton.Size = UDim2.new(0, 36, 0, 28)
SettingsButton.Position = IsTouchClient and UDim2.new(0, 2, 0, 5) or UDim2.new(0, 15, 1, -42)
SettingsButton.BackgroundTransparency = 1
SettingsButton.Image = 'rbxasset://textures/ui/homeButton.png'
if not isTopBar then
	SettingsButton.Parent = SettingsMenuFrame
end

local SettingsShield = Instance.new('TextButton')
SettingsShield.Name = "SettingsShield"
SettingsShield.Size = UDim2.new(1, 0, 1, 36)
SettingsShield.Position = UDim2.new(0,0,0,-36)
SettingsShield.BackgroundTransparency = BG_TRANSPARENCY
SettingsShield.BackgroundColor3 = Color3.new(31/255, 31/255, 31/255)
SettingsShield.BorderColor3 = Color3.new(27/255, 42/255, 53/255)
SettingsShield.BorderSizePixel = 0
SettingsShield.Visible = false
SettingsShield.AutoButtonColor = false
SettingsShield.Text = ""
SettingsShield.ZIndex = BASE_Z_INDEX + 2

	local SettingClipFrame = Instance.new('Frame')
	SettingClipFrame.Name = "SettingClipFrame"
	SettingClipFrame.Size = IsSmallScreen and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 525, 0, 430)--IsTouchClient and UDim2.new(0, 500, 0, 340) or UDim2.new(0, 500, 0, 430)
	SettingClipFrame.Position = CLOSE_MENU_POS
	SettingClipFrame.Active = true
	SettingClipFrame.BackgroundTransparency = BG_TRANSPARENCY
	SettingClipFrame.BackgroundColor3 = Color3.new(31/255, 31/255, 31/255)
	SettingClipFrame.BorderSizePixel = 0
	SettingClipFrame.ZIndex = BASE_Z_INDEX + 3
	SettingClipFrame.ClipsDescendants = true
	SettingClipFrame.Parent = SettingsShield

--[[ Root Settings Menu ]]--
	CurrentYOffset = 24
	local RootMenuFrame = createMenuFrame("RootMenuFrame", UDim2.new(0, 0, 0, 0))
	RootMenuFrame.Parent = SettingClipFrame

		local RootMenuTitle = createMenuTitleLabel("RootMenuTitle", "Game Menu", CurrentYOffset)
		RootMenuTitle.Parent = RootMenuFrame
		CurrentYOffset = CurrentYOffset + 32

		local ResumeGameButton = createTextButton(MENU_BTN_LRG, UDim2.new(0.5, -170, 0, CurrentYOffset),
			"Resume Game", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
		ResumeGameButton.Name = "ResumeGameButton"
		ResumeGameButton.Modal = true
		ResumeGameButton.Parent = RootMenuFrame
		CurrentYOffset = CurrentYOffset + 51

		local ResetCharacterButton = createTextButton(MENU_BTN_LRG, UDim2.new(0.5, -170, 0, CurrentYOffset),
			"Reset Character", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
		ResetCharacterButton.Name = "ResetCharacterButton"
		ResetCharacterButton.Parent = RootMenuFrame
		CurrentYOffset = CurrentYOffset + 51

		local GameSettingsButton = createTextButton(MENU_BTN_LRG, UDim2.new(0.5, -170, 0, CurrentYOffset),
			"Game Settings", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
		GameSettingsButton.Name = "GameSettingsButton"
		GameSettingsButton.Parent = RootMenuFrame
		CurrentYOffset = CurrentYOffset + 51

		local HelpButton = nil
		if not IsTouchClient then
			HelpButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -170, 0, CurrentYOffset),
				"Help", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
			HelpButton.Name = "HelpButton"
			if IsMacClient then HelpButton.Size = MENU_BTN_LRG end
			HelpButton.Parent = RootMenuFrame
		end

		local ScreenshotButton = nil
		if not IsMacClient and not IsTouchClient then
			ScreenshotButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, 2, 0, CurrentYOffset),
				"Screenshot", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
			ScreenshotButton.Name = "ScreenshotButton"
			ScreenshotButton.Parent = RootMenuFrame
			ScreenshotButton:SetVerb("Screenshot")
		end
		if not IsTouchClient then CurrentYOffset = CurrentYOffset + 51 end

		local ReportAbuseButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -170, 0, CurrentYOffset),
			"Report Abuse", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
		ReportAbuseButton.Name = "ReportAbuseButton"
		ReportAbuseButton.Parent = RootMenuFrame
		if IsMacClient or IsTouchClient then
			ReportAbuseButton.Size = MENU_BTN_LRG
		end
		ReportAbuseButton.Visible = game:FindService('NetworkClient')
		if isTestingReportAbuse then
			ReportAbuseButton.Visible = true
		end
		if not ReportAbuseButton.Visible then
			game.ChildAdded:connect(function(child)
				if child:IsA('NetworkClient') then
					ReportAbuseButton.Visible = game:FindService('NetworkClient')
				end
			end)
		end

		local RecordVideoButton = nil
		local StopRecordingVideoButton = nil
		if not IsMacClient and not IsTouchClient then
			RecordVideoButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, 2, 0, CurrentYOffset),
				"Record Video", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
			RecordVideoButton.Name = "RecordVideoButton"
			RecordVideoButton.Parent = RootMenuFrame
			RecordVideoButton:SetVerb("RecordToggle")

			StopRecordingVideoButton = Instance.new('ImageButton')
			StopRecordingVideoButton.Name = "StopRecordingVideoButton"
			StopRecordingVideoButton.Size = UDim2.new(0, 59, 0, 27)
			StopRecordingVideoButton.BackgroundTransparency = 1
			StopRecordingVideoButton.Image = STOP_RECORD_IMG
			StopRecordingVideoButton:SetVerb("RecordToggle")
			StopRecordingVideoButton.Visible = false
			StopRecordingVideoButton.Parent = SettingsMenuFrame
		end
		CurrentYOffset = CurrentYOffset + 51

		local LeaveGameButton = createTextButton(MENU_BTN_LRG, UDim2.new(0.5, -170, 0, CurrentYOffset),
			"Leave Game", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
		LeaveGameButton.Name = "LeaveGameButton"
		LeaveGameButton.Parent = RootMenuFrame

--[[ Reset Character Confirmation Menu ]]--
	CurrentYOffset = IsSmallScreen and 70 or 140
	local ResetCharacterFrame = createMenuFrame("ResetCharacterFrame", UDim2.new(1, 0, 0, 0))
	ResetCharacterFrame.Parent = SettingClipFrame

		local ResetCharacterText = Instance.new('TextLabel')
		ResetCharacterText.Name = "ResetCharacterText"
		ResetCharacterText.Size = UDim2.new(1, 0, 0, 80)
		ResetCharacterText.Position = UDim2.new(0, 0, 0, CurrentYOffset)
		ResetCharacterText.BackgroundTransparency = 1
		ResetCharacterText.Font = Enum.Font.SourceSansBold
		ResetCharacterText.FontSize = Enum.FontSize.Size36
		ResetCharacterText.TextColor3 = Color3.new(1, 1, 1)
		ResetCharacterText.TextWrap = true
		ResetCharacterText.ZIndex = BASE_Z_INDEX + 4
		ResetCharacterText.Text = "Are you sure you want to reset\nyour character?"
		ResetCharacterText.Parent = ResetCharacterFrame
		CurrentYOffset = CurrentYOffset + 90

		local ResetCharacterToolTipText = createTextLabel(UDim2.new(0.5, 0, 0, CurrentYOffset), "You will return to the spawn point", "ResetCharacterToolTipText")
		ResetCharacterToolTipText.TextXAlignment = Enum.TextXAlignment.Center
		ResetCharacterToolTipText.Parent = ResetCharacterFrame
		CurrentYOffset = CurrentYOffset + 32

		local ConfirmResetButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, 2, 0, CurrentYOffset),
			"Confirm", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
		ConfirmResetButton.Name = "ConfirmResetButton"
		ConfirmResetButton.Modal = true
		ConfirmResetButton.Parent = ResetCharacterFrame

		local CancelResetButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -170, 0, CurrentYOffset),
			"Cancel", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
		CancelResetButton.Name = "CancelResetButton"
		CancelResetButton.Parent = ResetCharacterFrame

--[[ Game Settings Menu ]]--
	CurrentYOffset = 24
	local GameSettingsMenuFrame = createMenuFrame("GameSettingsMenuFrame", UDim2.new(1, 0, 0, 0))
	GameSettingsMenuFrame.Parent = SettingClipFrame

		local GameSettingsMenuTitle = createMenuTitleLabel("GameSettingsMenuTitle", "Settings", CurrentYOffset)
		GameSettingsMenuTitle.Parent = GameSettingsMenuFrame
		CurrentYOffset = CurrentYOffset + 36
		if IsTouchClient then CurrentYOffset = CurrentYOffset + 10 end

		-- Shift Lock Controls
		local shiftLockImageLabel = nil
		if not isLuaControls then 	-- FFlag, remove when new controls are live
			shiftLockImageLabel = not isLuaControls and RobloxGui:FindFirstChild('MouseLockLabel', true) or nil
			if shiftLockImageLabel then
				shiftLockImageLabel.Visible = GameSettings.ControlMode == Enum.ControlMode["Mouse Lock Switch"]
			end
		end
		local ShiftLockText, ShiftLockCheckBox, ShiftLockOverrideText = nil, nil, nil
		if not IsTouchClient then
			ShiftLockText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Enable Shift Lock Switch:", "ShiftLockText")
			ShiftLockText.Parent = GameSettingsMenuFrame

			ShiftLockCheckBox = createTextButton(UDim2.new(0, 32, 0, 32), UDim2.new(0.5, 6, 0, CurrentYOffset - 18),
				IsShiftLockEnabled and "X" or "", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
			ShiftLockCheckBox.Name = "ShiftLockCheckBox"
			ShiftLockCheckBox.ZIndex = BASE_Z_INDEX + 4
			if isLuaControls then
				ShiftLockCheckBox.Visible = LocalPlayer.DevEnableMouseLock
			end
			ShiftLockCheckBox.Parent = GameSettingsMenuFrame

			ShiftLockOverrideText = createTextLabel(UDim2.new(0.5, 6, 0, CurrentYOffset), "Set By Developer", "ShiftLockOverrideText")
			ShiftLockOverrideText.TextXAlignment = Enum.TextXAlignment.Left
			ShiftLockOverrideText.TextColor3 = Color3.new(180/255, 180/255, 180/255)
			ShiftLockOverrideText.Visible = false
			if isLuaControls then
				ShiftLockOverrideText.Visible = not LocalPlayer.DevEnableMouseLock
			end
			ShiftLockOverrideText.Parent = GameSettingsMenuFrame

			CurrentYOffset = CurrentYOffset + 36
		end

		-- Camera Mode Controls
		local CameraModeText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Camera Mode:", "CameraModeText")
		CameraModeText.Parent = GameSettingsMenuFrame

		local CameraModeDropDown = nil
		do
			local enumItems = nil
			if not isLuaControls then
				enumItems = Enum.CustomCameraMode:GetEnumItems()
			elseif IsTouchClient then
				enumItems = Enum.TouchCameraMovementMode:GetEnumItems()
			else
				enumItems = Enum.ComputerCameraMovementMode:GetEnumItems()
			end

			local enumNames = {}
			local enumNameToItem = {}
			for i = 1, #enumItems do
				local displayName = enumItems[i].Name
				if displayName == 'Default' then
					displayName = CAMERA_MODE_DEFAULT_STRING
				end
				enumNames[i] = displayName
				enumNameToItem[displayName] = enumItems[i].Value
			end
			CameraModeDropDown = RbxGuiLibaray.CreateScrollingDropDownMenu(
				function(text)
					if not isLuaControls then
						GameSettings.CameraMode = enumNameToItem[text]
					elseif IsTouchClient then
						GameSettings.TouchCameraMovementMode = enumNameToItem[text]
					else
						GameSettings.ComputerCameraMovementMode = enumNameToItem[text]
					end
				end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, CurrentYOffset - 16), BASE_Z_INDEX + 4)
			CameraModeDropDown.CreateList(enumNames)
			local displayName = ""
			if not isLuaControls then
				displayName = GameSettings.CameraMode.Name
			else
				displayName = IsTouchClient and GameSettings.TouchCameraMovementMode.Name or GameSettings.ComputerCameraMovementMode.Name
			end
			if displayName == 'Default' then displayName = CAMERA_MODE_DEFAULT_STRING end
			CameraModeDropDown.SetSelectionText(displayName)
			CameraModeDropDown.Frame.Parent = GameSettingsMenuFrame
		end

		local CameraModeOverrideText = createTextLabel(UDim2.new(0.5, 6, 0, CurrentYOffset), "Set By Developer", "CameraModeOverrideText")
		CameraModeOverrideText.TextColor3 = Color3.new(180/255, 180/255, 180/255)
		CameraModeOverrideText.TextXAlignment = Enum.TextXAlignment.Left
		CameraModeOverrideText.Parent = GameSettingsMenuFrame

		do
			local isUserChoice = false
			if not isLuaControls then
				isUserChoice = true
			elseif IsTouchClient then
				isUserChoice = LocalPlayer.DevTouchCameraMode == Enum.DevTouchCameraMovementMode.UserChoice
			else
				isUserChoice = LocalPlayer.DevComputerCameraMode == Enum.DevComputerCameraMovementMode.UserChoice
			end
			if CameraModeDropDown then
				CameraModeDropDown.SetVisible(isUserChoice)
			end
			CameraModeOverrideText.Visible = not isUserChoice
		end
		CurrentYOffset = CurrentYOffset + 36

		-- Movement Mode Controls
		local MovementModeDropDown = nil
		local MovementModeOverrideText = nil
		if isLuaControls or IsTouchClient then
			local MovementModeText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Movement Mode:", "MovementModeText")
			MovementModeText.Parent = GameSettingsMenuFrame

			do
				local enumItems = IsTouchClient and Enum.TouchMovementMode:GetEnumItems() or Enum.ComputerMovementMode:GetEnumItems()
				local enumNames = {}
				local enumNameToItem = {}
				for i = 1, #enumItems do
					if not isLuaControls and enumItems[i].Name == "ClickToMove" then
						-- lets skip click to move until new controls are live
					else
						local displayName = enumItems[i].Name
						if displayName == "Default" then
							displayName = MOVEMENT_MODE_DEFAULT_STRING
						end
						enumNames[i] = displayName
						enumNameToItem[displayName] = enumItems[i]
					end
				end
				--
				MovementModeDropDown = RbxGuiLibaray.CreateScrollingDropDownMenu(
					function(text)
						if IsTouchClient then
							GameSettings.TouchMovementMode = enumNameToItem[text]
						else
							GameSettings.ComputerMovementMode = enumNameToItem[text]
						end
					end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, CurrentYOffset - 16), BASE_Z_INDEX + 4)
				MovementModeDropDown.CreateList(enumNames)
				local displayName = IsTouchClient and GameSettings.TouchMovementMode.Name or GameSettings.ComputerMovementMode.Name
				if displayName == 'Default' then displayName = MOVEMENT_MODE_DEFAULT_STRING end
				MovementModeDropDown.SetSelectionText(displayName)
				MovementModeDropDown.Frame.Parent = GameSettingsMenuFrame
			end

			MovementModeOverrideText = createTextLabel(UDim2.new(0.5, 6, 0, CurrentYOffset), "Set By Developer", "MovementModeOverrideText")
			MovementModeOverrideText.TextColor3 = Color3.new(180/255, 180/255, 180/255)
			MovementModeOverrideText.TextXAlignment = Enum.TextXAlignment.Left
			MovementModeOverrideText.Parent = GameSettingsMenuFrame

			do
				local isUserChoice = false
				if not isLuaControls then
					isUserChoice = true
				elseif IsTouchClient then
					isUserChoice = LocalPlayer.DevTouchMovementMode == Enum.DevTouchMovementMode.UserChoice
				else
					isUserChoice = LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.UserChoice
				end
				if MovementModeDropDown then
					MovementModeDropDown.SetVisible(isUserChoice)
				end
				MovementModeOverrideText.Visible = not isUserChoice
			end
			CurrentYOffset = CurrentYOffset + 36
		end

		-- Video Capture Settings
		local VideoCaptureDropDown = nil
		if not IsMacClient and not IsTouchClient then
			local videoCaptureText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "After Capturing Video:", "VideoCaptureText")
			videoCaptureText.Parent = GameSettingsMenuFrame

			local enumNames = {}
			local enumNamesToItem = {}
			enumNames[1] = "Save To Disk"
			enumNamesToItem[enumNames[1]] = Enum.UploadSetting["Never"]
			enumNames[2] = "Upload to YouTube"
			enumNamesToItem[enumNames[2]] = Enum.UploadSetting["Ask me first"]

			VideoCaptureDropDown = RbxGuiLibaray.CreateScrollingDropDownMenu(
				function(text)
					GameSettings.VideoUploadPromptBehavior = enumNamesToItem[text]
				end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, CurrentYOffset - 16), BASE_Z_INDEX + 4)
			VideoCaptureDropDown.CreateList(enumNames)
			VideoCaptureDropDown.Frame.Parent = GameSettingsMenuFrame

			local displayName = ""
			if GameSettings.VideoUploadPromptBehavior == Enum.UploadSetting["Never"] then
				displayName = enumNames[1]
			elseif GameSettings.VideoUploadPromptBehavior == Enum.UploadSetting["Ask me first"] then
				displayName = enumNames[2]
			else
				GameSettings.VideoUploadPromptBehavior = Enum.UploadSetting["Ask me first"]
				displayName = enumNames[2]
			end
			VideoCaptureDropDown.SetSelectionText(displayName)

			CurrentYOffset = CurrentYOffset + 36
		end

		--[[ Fullscreen Mode ]]--
		if not IsTouchClient then
			local fullScreenText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Fullscreen:", "FullScreenText")
			fullScreenText.Parent = GameSettingsMenuFrame

			local fullScreenTextCheckBox = createTextButton(UDim2.new(0, 32, 0, 32), UDim2.new(0.5, 6, 0, CurrentYOffset - 18),
			GameSettings:InFullScreen() and "X" or "", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
			fullScreenTextCheckBox.Name = "FullScreenTextCheckBox"
			fullScreenTextCheckBox.ZIndex = BASE_Z_INDEX + 4
			fullScreenTextCheckBox.Parent = GameSettingsMenuFrame
			fullScreenTextCheckBox.Modal = true
			fullScreenTextCheckBox:SetVerb("ToggleFullScreen")

			GameSettings.FullscreenChanged:connect(function(isFullscreen)
				fullScreenTextCheckBox.Text = isFullscreen and "X" or ""
			end)
			CurrentYOffset = CurrentYOffset + 36
		end

		--[[ Graphics Slider ]]--
		if not IsTouchClient then
			local qualityText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Graphics Quality:", "QualityText")
			qualityText.Parent = GameSettingsMenuFrame

			local qualityAutoCheckBox = createTextButton(UDim2.new(0, 32, 0, 32), UDim2.new(0.5, 6, 0, CurrentYOffset - 18),
				GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic and "X" or "", Enum.FontSize.Size18, Enum.ButtonStyle.RobloxRoundButton)
			qualityAutoCheckBox.Name = "QualityAutoCheckBox"
			qualityAutoCheckBox.ZIndex = BASE_Z_INDEX + 4
			qualityAutoCheckBox.Parent = GameSettingsMenuFrame

			local qualityAutoText = createTextLabel(UDim2.new(0.5, 44, 0, CurrentYOffset), "Auto", "QualityAutoText")
			qualityAutoText.TextXAlignment = Enum.TextXAlignment.Left
			qualityAutoText.TextColor3 = GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic and Color3.new(1, 1, 1) or Color3.new(128/255,128/255,128/255)
			qualityAutoText.Parent = GameSettingsMenuFrame

			local graphicsSlider, graphicsLevel = RbxGuiLibaray.CreateSliderNew(GRAPHICS_QUALITY_LEVELS, 300, UDim2.new(0.5, -150, 0, CurrentYOffset + 36))
			graphicsSlider.Bar.ZIndex = BASE_Z_INDEX + 4
			graphicsSlider.Bar.Slider.ZIndex = BASE_Z_INDEX + 6
			graphicsSlider.BarLeft.ZIndex = BASE_Z_INDEX + 4
			graphicsSlider.BarRight.ZIndex = BASE_Z_INDEX + 4
			graphicsSlider.Bar.Fill.ZIndex = BASE_Z_INDEX + 5
			graphicsSlider.FillLeft.ZIndex = BASE_Z_INDEX + 5
			graphicsSlider.Parent = GameSettingsMenuFrame
			-- TODO: We don't save the previous non-auto setting. So what should this default to?
			graphicsLevel.Value = math.floor((settings().Rendering:GetMaxQualityLevel() - 1)/2)

			local graphicsMinText = createTextLabel(UDim2.new(0.5, -164, 0, CurrentYOffset + 37), "Min", "GraphicsMinText")
			graphicsMinText.Parent = GameSettingsMenuFrame

			local graphicsMaxText = createTextLabel(UDim2.new(0.5, 158, 0, CurrentYOffset + 37), "Max", "GraphicsMaxText")
			graphicsMaxText.TextXAlignment = Enum.TextXAlignment.Left
			graphicsMaxText.Parent = GameSettingsMenuFrame

			local isAutoGraphics = true
			isAutoGraphics = GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic

			local function setGraphicsQualityLevel(newLevel)
				local percentage = newLevel/GRAPHICS_QUALITY_LEVELS
				local newQualityLevel = math.floor((settings().Rendering:GetMaxQualityLevel() - 1) * percentage)
				if newQualityLevel == 20 then
					newQualityLevel = 21
				elseif newLevel == 1 then
					newQualityLevel = 1
				elseif newQualityLevel > settings().Rendering:GetMaxQualityLevel() then
					newQualityLevel = settings().Rendering:GetMaxQualityLevel() - 1
				end

				GameSettings.SavedQualityLevel = newLevel
				settings().Rendering.QualityLevel = newQualityLevel
			end

			local function setGraphicsGuiZIndex()
				qualityAutoCheckBox.Text = isAutoGraphics and "X" or ""
				if isAutoGraphics then
					graphicsSlider.Bar.ZIndex = 1
					graphicsSlider.BarLeft.ZIndex = 1
					graphicsSlider.BarRight.ZIndex = 1
					graphicsSlider.Bar.Fill.ZIndex = 1
					graphicsSlider.Bar.Slider.ZIndex = 2
					graphicsSlider.Bar.Slider.Active = false
					graphicsSlider.FillLeft.ZIndex = 1
					graphicsMinText.ZIndex = 1
					graphicsMaxText.ZIndex = 1
				else
					graphicsSlider.Bar.ZIndex = BASE_Z_INDEX + 4
					graphicsSlider.BarLeft.ZIndex = BASE_Z_INDEX + 4
					graphicsSlider.BarRight.ZIndex = BASE_Z_INDEX + 4
					graphicsSlider.Bar.Fill.ZIndex = BASE_Z_INDEX + 5
					graphicsSlider.Bar.Slider.ZIndex = BASE_Z_INDEX + 6
					graphicsSlider.Bar.Slider.Active = true
					graphicsSlider.FillLeft.ZIndex = BASE_Z_INDEX + 5
					graphicsMinText.ZIndex = BASE_Z_INDEX + 4
					graphicsMaxText.ZIndex = BASE_Z_INDEX + 4
				end
			end

			local function setGraphicsToAtuo()
				GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.Automatic
				settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
			end

			local function setGraphicsToManual(level)
				graphicsLevel.Value = level
				setGraphicsQualityLevel(level)
			end

			local function onGraphicsCheckBoxPressed()
				isAutoGraphics = not isAutoGraphics
				setGraphicsGuiZIndex()
				if isAutoGraphics then
					setGraphicsToAtuo()
				else
					setGraphicsToManual(graphicsLevel.Value)
				end
			end

			graphicsLevel.Changed:connect(function(newValue)
				if isAutoGraphics then return end
				--
				setGraphicsQualityLevel(graphicsLevel.Value)
			end)

			qualityAutoCheckBox.MouseButton1Click:connect(onGraphicsCheckBoxPressed)

			-- graphics can be changed with F10 and Shift+F10
			game.GraphicsQualityChangeRequest:connect(function(isIncrease)
				if isAutoGraphics then return end
				--
				if isIncrease then
					if graphicsLevel.Value + 1 > GRAPHICS_QUALITY_LEVELS then return end
					graphicsLevel.Value = graphicsLevel.Value + 1
					setGraphicsQualityLevel(graphicsLevel.Value)
				else
					if graphicsLevel.Value - 1 <= 0 then return end
					graphicsLevel.Value = graphicsLevel.Value - 1
					setGraphicsQualityLevel(graphicsLevel.Value)
				end
			end)

			-- initial load setup
			setGraphicsGuiZIndex()
			if GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic then
				settings().Rendering.EnableFRM = true
				setGraphicsToAtuo()
			else
				settings().Rendering.EnableFRM = true
				local level = tostring(GameSettings.SavedQualityLevel)
				if GRAPHICS_QUALITY_TO_INT[level] then
					setGraphicsToManual(GRAPHICS_QUALITY_TO_INT[level])
				end
			end
			CurrentYOffset = CurrentYOffset + 72
		end

		--[[ Volume Slider ]]--
		local maxVolumeLevel = 256

		local volumeText = createTextLabel(UDim2.new(0.5, 0, 0, CurrentYOffset), "Volume", "VolumeText")
		volumeText.TextXAlignment = Enum.TextXAlignment.Center
		volumeText.Parent = GameSettingsMenuFrame

		local volumeSlider, volumeLevel = RbxGuiLibaray.CreateSliderNew(maxVolumeLevel, 300, UDim2.new(0.5, -150, 0, CurrentYOffset + 20))
		volumeSlider.Bar.ZIndex = BASE_Z_INDEX + 2
		volumeSlider.Bar.Slider.ZIndex = BASE_Z_INDEX + 4
		volumeSlider.BarLeft.ZIndex = BASE_Z_INDEX + 2
		volumeSlider.BarRight.ZIndex = BASE_Z_INDEX + 2
		volumeSlider.Bar.Fill.ZIndex = BASE_Z_INDEX + 3
		volumeSlider.FillLeft.ZIndex = BASE_Z_INDEX + 3
		volumeSlider.Parent = GameSettingsMenuFrame
		volumeLevel.Value = math.min(math.max(GameSettings.MasterVolume * maxVolumeLevel, 1), maxVolumeLevel)

		local volumeMinText = createTextLabel(UDim2.new(0.5, -164, 0, CurrentYOffset + 21), "Min", "VolumeMinText")
		volumeMinText.Parent = GameSettingsMenuFrame

		local volumeMaxText = createTextLabel(UDim2.new(0.5, 158, 0, CurrentYOffset + 21), "Max", "VolumeMaxText")
		volumeMaxText.TextXAlignment = Enum.TextXAlignment.Left
		volumeMaxText.Parent = GameSettingsMenuFrame

		volumeLevel.Changed:connect(function(newValue)
			local volume = volumeLevel.Value - 1
			GameSettings.MasterVolume = volume/maxVolumeLevel
		end)

		CurrentYOffset = CurrentYOffset + 42
		if not isLuaControls and not IsTouchClient then
			CurrentYOffset = CurrentYOffset + 36
		end

		--[[ OK/Return button ]]--
		if IsTouchClient then
			if IsSmallScreen then
				CurrentYOffset = CurrentYOffset + 64
			else
				CurrentYOffset = CurrentYOffset + 134
			end
		end
		local GameSettingsBackButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -84, 0, CurrentYOffset),
			"Back", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
		GameSettingsBackButton.Name = "GameSettingsBackButton"
		GameSettingsBackButton.Parent = GameSettingsMenuFrame
		GameSettingsBackButton.Modal = true

		--[[ Game Settings Menu Drop Down Connections ]]--
		if CameraModeDropDown then
			CameraModeDropDown.CurrentSelectionButton.MouseButton1Click:connect(function()
				if CurrentOpenedDropDownMenu ~= CameraModeDropDown then
					closeCurrentDropDownMenu()
					CurrentOpenedDropDownMenu = CameraModeDropDown
				end
			end)
		end
		if MovementModeDropDown then
			MovementModeDropDown.CurrentSelectionButton.MouseButton1Click:connect(function()
				if CurrentOpenedDropDownMenu ~= MovementModeDropDown then
					closeCurrentDropDownMenu()
					CurrentOpenedDropDownMenu = MovementModeDropDown
				end
			end)
		end
		if VideoCaptureDropDown then
			VideoCaptureDropDown.CurrentSelectionButton.MouseButton1Click:connect(function()
				if CurrentOpenedDropDownMenu ~= VideoCaptureDropDown then
					closeCurrentDropDownMenu()
					CurrentOpenedDropDownMenu = VideoCaptureDropDown
				end
			end)
		end

--[[ Help Menu ]]--
	CurrentYOffset = 24
	local HelpMenuFrame = createMenuFrame("HelpMenuFrame", UDim2.new(1, 0, 0, 0))
	HelpMenuFrame.Parent = SettingClipFrame

		local HelpMenuTitle = createMenuTitleLabel("HelpMenuTitle", "Keyboard & Mouse Controls", CurrentYOffset)
		HelpMenuTitle.Parent = HelpMenuFrame
		CurrentYOffset = CurrentYOffset + 32

		local HelpMenuButtonFrame = Instance.new('Frame')
		HelpMenuButtonFrame.Name = "HelpMenuButtonFrame"
		HelpMenuButtonFrame.Size = UDim2.new(0.9, 0, 0, 45)
		HelpMenuButtonFrame.Position = UDim2.new(0.05, 0, 0, CurrentYOffset)
		HelpMenuButtonFrame.BackgroundTransparency = 1
		HelpMenuButtonFrame.ZIndex = BASE_Z_INDEX + 4
		HelpMenuButtonFrame.Parent = HelpMenuFrame
		CurrentYOffset = CurrentYOffset + 60

			local CurrentHelpDialogButton = nil
			local HelpLookButton = createTextButton(UDim2.new(0.25, 0, 1, 0), UDim2.new(0, 0, 0, 0),
				"Look", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
			HelpLookButton.Name = "HelpLookButton"
			HelpLookButton.Parent = HelpMenuButtonFrame

			local HelpMoveButton = createTextButton(UDim2.new(0.25, 0, 1, 0), UDim2.new(0.25, 0, 0, 0),
				"Movement", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
			HelpMoveButton.Name = "HelpMoveButton"
			HelpMoveButton.Parent = HelpMenuButtonFrame

			local HelpGearButton = createTextButton(UDim2.new(0.25, 0, 1, 0), UDim2.new(0.5, 0, 0, 0),
				"Gear", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
			HelpGearButton.Name = "HelpGearButton"
			HelpGearButton.Parent = HelpMenuButtonFrame

			local HelpZoomButton = createTextButton(UDim2.new(0.25, 0, 1, 0), UDim2.new(0.75, 0, 0, 0),
				"Zoom", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
			HelpZoomButton.Name = "HelpZoomButton"
			HelpZoomButton.Parent = HelpMenuButtonFrame

			CurrentHelpDialogButton = HelpLookButton

		local HelpMenuImage = Instance.new('ImageLabel')
		HelpMenuImage.Name = "HelpMenuImage"
		HelpMenuImage.Size = UDim2.new(0.9, 0, 0.5, 0)
		HelpMenuImage.Position = UDim2.new(0.05, 0, 0, CurrentYOffset)
		HelpMenuImage.BackgroundTransparency = 1
		HelpMenuImage.Image = GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch and HELP_IMG.SHIFT_LOCK or HELP_IMG.CLASSIC_MOVE
		HelpMenuImage.ZIndex = BASE_Z_INDEX + 4
		HelpMenuImage.Parent = HelpMenuFrame
		CurrentYOffset = CurrentYOffset + 234

		local HelpConsoleButton = createTextButton(UDim2.new(0, 70, 0, 30), UDim2.new(1, -75, 0, CurrentYOffset + 20),
			"Log:", Enum.FontSize.Size18, Enum.ButtonStyle.RobloxRoundButton)
		HelpConsoleButton.Name = "HelpConsoleButton"
		HelpConsoleButton.TextXAlignment = Enum.TextXAlignment.Left
		HelpConsoleButton.Parent = HelpMenuFrame

			local HelpConsoleText = Instance.new('TextLabel')
			HelpConsoleText.Name = "HelpConsoleText"
			HelpConsoleText.Size = UDim2.new(0, 16, 0, 30)
			HelpConsoleText.Position = UDim2.new(1, -14, 0, -12)
			HelpConsoleText.BackgroundTransparency = 1
			HelpConsoleText.Font = Enum.Font.SourceSansBold
			HelpConsoleText.FontSize = Enum.FontSize.Size18
			HelpConsoleText.TextColor3 = Color3.new(0, 1, 0)
			HelpConsoleText.ZIndex = BASE_Z_INDEX + 4
			HelpConsoleText.Text = "F9"
			HelpConsoleText.Parent = HelpConsoleButton

		local HelpMenuBackButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -84, 0, CurrentYOffset),
			"Back", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
		HelpMenuBackButton.Name = "HelpMenuBackButton"
		HelpMenuBackButton.Modal = true
		HelpMenuBackButton.Parent = HelpMenuFrame

--[[ Report Abuse Menu ]]--
	CurrentYOffset = 24
	local IsReportingPlayer = false
	local CurrentAbusingPlayer = nil
	local AbuseReason = nil

	local ReportAbuseFrame = createMenuFrame("ReportAbuseFrame", UDim2.new(1, 0, 0, 0))
	ReportAbuseFrame.Parent = SettingClipFrame

		local ReportAbuseTitle = createMenuTitleLabel("ReportAbuseTitle", "Report Abuse", CurrentYOffset)
		ReportAbuseTitle.Parent = ReportAbuseFrame
		CurrentYOffset = IsSmallScreen and (CurrentYOffset + 20) or (CurrentYOffset + 32)

		local ReportAbuseDescription = Instance.new('TextLabel')
		ReportAbuseDescription.Name = "ReportAbuseDescription"
		ReportAbuseDescription.Size = UDim2.new(1, -40, 0, 40)
		ReportAbuseDescription.Position = UDim2.new(0, 35, 0, CurrentYOffset)
		ReportAbuseDescription.BackgroundTransparency = 1
		ReportAbuseDescription.Font = Enum.Font.SourceSans
		ReportAbuseDescription.FontSize = Enum.FontSize.Size18
		ReportAbuseDescription.TextColor3 = Color3.new(1, 1, 1)
		ReportAbuseDescription.TextWrap = true
		ReportAbuseDescription.TextXAlignment = Enum.TextXAlignment.Left
		ReportAbuseDescription.TextYAlignment = Enum.TextYAlignment.Top
		ReportAbuseDescription.ZIndex = BASE_Z_INDEX + 4
		ReportAbuseDescription.Text = "This will send a complete report to a moderator. The moderator will review the chat log and take appropriate action."
		ReportAbuseDescription.Parent = ReportAbuseFrame
		CurrentYOffset = IsSmallScreen and (CurrentYOffset + 48) or (CurrentYOffset + 70)

		local ReportGameOrPlayerText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Game or Player:", "ReportGameOrPlayerText")
		ReportGameOrPlayerText.Parent = ReportAbuseFrame
		CurrentYOffset = CurrentYOffset + 40

		local ReportPlayerText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Which Player:", "ReportPlayerText")
		ReportPlayerText.Parent = ReportAbuseFrame
		CurrentYOffset = CurrentYOffset + 40

		local ReportTypeOfAbuseText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Type of Abuse:", "ReportTypeOfAbuseText")
		ReportTypeOfAbuseText.Parent = ReportAbuseFrame
		CurrentYOffset = IsSmallScreen and (CurrentYOffset + 10) or (CurrentYOffset + 40)

		local ReportDescriptionText = ReportAbuseDescription:Clone()
		ReportDescriptionText.Name = "ReportDescriptionText"
		ReportDescriptionText.Text = "Short Description: (optional)"
		ReportDescriptionText.Position = UDim2.new(0, 35, 0, CurrentYOffset)
		ReportDescriptionText.Parent = ReportAbuseFrame
		CurrentYOffset = CurrentYOffset + 28

		local ReportDescriptionTextBox = Instance.new('TextBox')
		ReportDescriptionTextBox.Name = "ReportDescriptionTextBox"
		ReportDescriptionTextBox.Size = UDim2.new(1, -70, 1, IsSmallScreen and (-CurrentYOffset - 60) or (-CurrentYOffset - 100))
		ReportDescriptionTextBox.Position = UDim2.new(0, 35, 0, CurrentYOffset)
		ReportDescriptionTextBox.BackgroundTransparency = 1
		ReportDescriptionTextBox.Font = Enum.Font.SourceSans
		ReportDescriptionTextBox.FontSize = Enum.FontSize.Size18
		ReportDescriptionTextBox.ClearTextOnFocus = false
		ReportDescriptionTextBox.TextColor3 = Color3.new(0, 0, 0)
		ReportDescriptionTextBox.TextXAlignment = Enum.TextXAlignment.Left
		ReportDescriptionTextBox.TextYAlignment = Enum.TextYAlignment.Top
		ReportDescriptionTextBox.Text = ""
		ReportDescriptionTextBox.TextWrap = true
		ReportDescriptionTextBox.ZIndex = BASE_Z_INDEX + 4
		ReportDescriptionTextBox.Visible = false
		ReportDescriptionTextBox.Parent = ReportAbuseFrame

		local ReportDescriptionTextBoxBg = Instance.new('TextButton')
		ReportDescriptionTextBoxBg.Name = "ReportDescriptionTextBoxBg"
		ReportDescriptionTextBoxBg.Size = UDim2.new(1, 16, 1, 16)
		ReportDescriptionTextBoxBg.Position = UDim2.new(0, -8, 0, -8)
		ReportDescriptionTextBoxBg.Text = ""
		ReportDescriptionTextBoxBg.Active = false
		ReportDescriptionTextBoxBg.AutoButtonColor = false
		ReportDescriptionTextBoxBg.Style = Enum.ButtonStyle.RobloxRoundDropdownButton
		ReportDescriptionTextBoxBg.ZIndex = BASE_Z_INDEX + 4
		ReportDescriptionTextBoxBg.Parent = ReportDescriptionTextBox
		CurrentYOffset = CurrentYOffset + ReportDescriptionTextBox.AbsoluteSize.y + 20

		local buttonPosition = IsSmallScreen and UDim2.new(0.5, 2, 1, -MENU_BTN_SML.Y.Offset - 4) or
			UDim2.new(0.5, 2, 0, CurrentYOffset)

		local ReportSubmitButton = createTextButton(MENU_BTN_SML, buttonPosition,
			"Submit", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
		ReportSubmitButton.Name = "ReportSubmitButton"
		ReportSubmitButton.ZIndex = BASE_Z_INDEX
		ReportSubmitButton.Active = false
		ReportSubmitButton.Parent = ReportAbuseFrame

		buttonPosition = IsSmallScreen and UDim2.new(0.5, -170, 1, -MENU_BTN_SML.Y.Offset - 4) or
			UDim2.new(0.5, -170, 0, CurrentYOffset)

		local ReportCancelButton = createTextButton(MENU_BTN_SML, buttonPosition,
			"Cancel", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
		ReportCancelButton.Name = "ReportSubmitButton"
		ReportCancelButton.Parent = ReportAbuseFrame
		ReportCancelButton.Modal = true

		local ReportPlayerDropDown = nil
		local ReportTypeOfAbuseDropDown = nil
		local ReportPlayerOrGameDropDown = nil

		local function cleanupReportAbuseMenu()
			ReportDescriptionTextBox.Visible = false
			ReportDescriptionTextBox.Text = ""
			ReportSubmitButton.ZIndex = BASE_Z_INDEX
			ReportSubmitButton.Active = false
			if ReportPlayerDropDown then
				ReportPlayerDropDown.Frame:Destroy()
				ReportPlayerDropDown = nil
			end
			if ReportTypeOfAbuseDropDown then
				ReportTypeOfAbuseDropDown.Frame:Destroy()
				ReportTypeOfAbuseDropDown = nil
			end
			if ReportPlayerOrGameDropDown then
				ReportPlayerOrGameDropDown.Frame:Destroy()
				ReportPlayerOrGameDropDown = nil
			end
		end

		local function createReportAbuseMenu()
			local playerNames = {}
			local nameToRbxPlayer = {}
			local players = Players:GetChildren()
			local index = 1
			for i = 1, #players do
				local player = players[i]
				if player:IsA('Player') and player ~= LocalPlayer then
					playerNames[index] = player.Name
					nameToRbxPlayer[player.Name] = player
					index = index + 1
				end
			end

			ReportTypeOfAbuseDropDown = RbxGuiLibaray.CreateScrollingDropDownMenu(
				function(text)
					AbuseReason = text
					ReportSubmitButton.ZIndex = BASE_Z_INDEX + 4
					ReportSubmitButton.Active = true
				end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, ReportTypeOfAbuseText.Position.Y.Offset - 16), BASE_Z_INDEX)
			ReportTypeOfAbuseDropDown.SetActive(false)
			ReportTypeOfAbuseDropDown.Frame.Parent = ReportAbuseFrame
			-- list will be set depending on which type of report it is (game or player)

			ReportPlayerDropDown = RbxGuiLibaray.CreateScrollingDropDownMenu(
				function(text)
					CurrentAbusingPlayer = nameToRbxPlayer[text] or LocalPlayer
					ReportTypeOfAbuseText.ZIndex = BASE_Z_INDEX + 4
					ReportTypeOfAbuseDropDown.CreateList(ABUSE_TYPES_PLAYER)
					ReportTypeOfAbuseDropDown.UpdateZIndex(BASE_Z_INDEX + 4)
					ReportTypeOfAbuseDropDown.SetActive(true)
				end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, ReportPlayerText.Position.Y.Offset - 16), BASE_Z_INDEX)
			ReportPlayerDropDown.SetActive(false)
			ReportPlayerDropDown.CreateList(playerNames)
			ReportPlayerDropDown.Frame.Parent = ReportAbuseFrame

			ReportPlayerOrGameDropDown = RbxGuiLibaray.CreateScrollingDropDownMenu(
				function(text)
					if text == "Player" then
						IsReportingPlayer = true
						ReportPlayerText.ZIndex = BASE_Z_INDEX + 4
						ReportPlayerDropDown.UpdateZIndex(BASE_Z_INDEX + 4)
						ReportPlayerDropDown.SetActive(true)
						--
						ReportTypeOfAbuseText.ZIndex = BASE_Z_INDEX
						ReportTypeOfAbuseDropDown.CreateList(ABUSE_TYPES_PLAYER)
						ReportTypeOfAbuseDropDown.UpdateZIndex(BASE_Z_INDEX)
						ReportTypeOfAbuseDropDown.SetActive(false)
					elseif text == "Game" then
						IsReportingPlayer = false
						if CurrentAbusingPlayer then
							CurrentAbusingPlayer = nil
						end
						ReportPlayerDropDown.SetSelectionText("Choose One")
						ReportPlayerText.ZIndex = BASE_Z_INDEX
						ReportPlayerDropDown.SetActive(false)
						ReportPlayerDropDown.UpdateZIndex(BASE_Z_INDEX)
						--
						ReportTypeOfAbuseText.ZIndex = BASE_Z_INDEX + 4
						ReportTypeOfAbuseDropDown.CreateList(ABUSE_TYPES_GAME)
						ReportTypeOfAbuseDropDown.UpdateZIndex(BASE_Z_INDEX + 4)
						ReportTypeOfAbuseDropDown.SetActive(true)
					else
						IsReportingPlayer = false
						ReportPlayerText.ZIndex = BASE_Z_INDEX
						ReportPlayerDropDown.SetActive(false)
						ReportPlayerDropDown.UpdateZIndex(BASE_Z_INDEX)
					end
					ReportSubmitButton.ZIndex = BASE_Z_INDEX
					ReportSubmitButton.Active = false
				end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, ReportGameOrPlayerText.Position.Y.Offset - 16), BASE_Z_INDEX + 4)
			ReportPlayerOrGameDropDown.Frame.Parent = ReportAbuseFrame
			ReportPlayerOrGameDropDown.CreateList({ "Game", "Player", })

			-- drop down menu connections
			ReportPlayerDropDown.CurrentSelectionButton.MouseButton1Click:connect(function()
				if CurrentOpenedDropDownMenu ~= ReportPlayerDropDown then
					closeCurrentDropDownMenu()
					CurrentOpenedDropDownMenu = ReportPlayerDropDown
				end
			end)
			ReportTypeOfAbuseDropDown.CurrentSelectionButton.MouseButton1Click:connect(function()
				if CurrentOpenedDropDownMenu ~= ReportTypeOfAbuseDropDown then
					closeCurrentDropDownMenu()
					CurrentOpenedDropDownMenu = ReportTypeOfAbuseDropDown
				end
			end)
			ReportPlayerOrGameDropDown.CurrentSelectionButton.MouseButton1Click:connect(function()
				if CurrentOpenedDropDownMenu ~= ReportPlayerOrGameDropDown then
					closeCurrentDropDownMenu()
					CurrentOpenedDropDownMenu = ReportPlayerOrGameDropDown
				end
			end)
			ReportDescriptionTextBox.Visible = true
		end

	CurrentYOffset = IsSmallScreen and 70 or 140
	local ReportAbuseConfirmationFrame = createMenuFrame("ReportAbuseConfirmationFrame", UDim2.new(1, 0, 0, 0))
	ReportAbuseConfirmationFrame.Parent = SettingClipFrame

		local ReportAbuseConfirmationText = Instance.new('TextLabel')
		ReportAbuseConfirmationText.Name = "ReportAbuseConfirmationText"
		ReportAbuseConfirmationText.Size = UDim2.new(1, -20, 0, 80)
		ReportAbuseConfirmationText.Position = UDim2.new(0, 10, 0, CurrentYOffset)
		ReportAbuseConfirmationText.BackgroundTransparency = 1
		ReportAbuseConfirmationText.Font = Enum.Font.SourceSans
		ReportAbuseConfirmationText.FontSize = Enum.FontSize.Size24
		ReportAbuseConfirmationText.TextColor3 = Color3.new(1, 1, 1)
		ReportAbuseConfirmationText.TextWrap = true
		ReportAbuseConfirmationText.TextScaled = true
		ReportAbuseConfirmationText.ZIndex = BASE_Z_INDEX + 4
		ReportAbuseConfirmationText.Text = ""
		ReportAbuseConfirmationText.Parent = ReportAbuseConfirmationFrame
		CurrentYOffset = CurrentYOffset + 122

		local ReportAbuseConfirmationButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -MENU_BTN_SML.X.Offset/2, 0, CurrentYOffset),
			"OK", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
		ReportAbuseConfirmationButton.Name = "ReportAbuseConfirmationButton"
		ReportAbuseConfirmationButton.Parent = ReportAbuseConfirmationFrame

--[[ Leave Game Confirmation Menu ]]--
	CurrentYOffset = IsSmallScreen and 70 or 140
	local LeaveGameMenuFrame = createMenuFrame("LeaveGameMenuFrame", UDim2.new(1, 0, 0, 0))
	LeaveGameMenuFrame.Parent = SettingClipFrame

		local LeaveGameText = Instance.new('TextLabel')
		LeaveGameText.Name = "LeaveGameText"
		LeaveGameText.Size = UDim2.new(1, 0, 0, 80)
		LeaveGameText.Position = UDim2.new(0, 0, 0, CurrentYOffset)
		LeaveGameText.BackgroundTransparency = 1
		LeaveGameText.Font = Enum.Font.SourceSansBold
		LeaveGameText.FontSize = Enum.FontSize.Size36
		LeaveGameText.TextColor3 = Color3.new(1, 1, 1)
		LeaveGameText.TextWrap = true
		LeaveGameText.ZIndex = BASE_Z_INDEX + 4
		LeaveGameText.Text = "Are you sure you want to leave this game?"
		LeaveGameText.Parent = LeaveGameMenuFrame
		CurrentYOffset = CurrentYOffset + 122

		local LeaveConfirmButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, 2, 0, CurrentYOffset),
			"Confirm", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
		LeaveConfirmButton.Name = "LeaveConfirmButton"
		LeaveConfirmButton.Parent = LeaveGameMenuFrame
		LeaveConfirmButton.Modal = true
		LeaveConfirmButton:SetVerb("Exit")

		local LeaveCancelButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -170, 0, CurrentYOffset),
			"Cancel", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
		LeaveCancelButton.Name = "LeaveCancelButton"
		LeaveCancelButton.Parent = LeaveGameMenuFrame

--[[ Menu Functions ]]--
local function setGamepadButton(currentMenu)
	if not isGamepadSupport then return end
 	if not UserInputService.GamepadEnabled then return end 
 	
 	if currentMenu == LeaveGameMenuFrame then 
 		pcall(function() GuiService.SelectedCoreObject = LeaveGameMenuFrame.LeaveConfirmButton end)
	elseif currentMenu == RootMenuFrame then 
		pcall(function() GuiService.SelectedCoreObject = ResumeGameButton end)
	elseif currentMenu == ResetCharacterFrame then 
		pcall(function() GuiService.SelectedCoreObject = ConfirmResetButton end)
	elseif currentMenu == GameSettingsMenuFrame then 
		if GameSettingsMenuFrame.ShiftLockCheckBox and GameSettingsMenuFrame.ShiftLockCheckBox.Visible then 
			pcall(function() GuiService.SelectedCoreObject = GameSettingsMenuFrame.ShiftLockCheckBox end)
		else 
			pcall(function() GuiService.SelectedCoreObject = CameraModeDropDown.CurrentSelectionButton end)
		end 
	end 
 end 

local function pushMenu(nextMenu)
	if IsMenuClosing then return end
	local prevMenu = MenuStack[#MenuStack]
	MenuStack[#MenuStack + 1] = nextMenu
	--
	if prevMenu then
		prevMenu:TweenPosition(UDim2.new(-1, 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
	end
	if #MenuStack > 1 then
		nextMenu:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
	end

	setGamepadButton(nextMenu)
end

local function popMenu()
	if #MenuStack == 0 then return end
	--
	local currentMenu = MenuStack[#MenuStack]
	MenuStack[#MenuStack] = nil
	local prevMenu = MenuStack[#MenuStack]
	--
	if #MenuStack > 0 then
		currentMenu:TweenPosition(UDim2.new(1, 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
		-- special case to close drop down menus on game settings menu when it goes out of focus
		closeCurrentDropDownMenu()
	end
	if prevMenu then
		prevMenu:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
		setGamepadButton(prevMenu)
	end
end

local function emptyMenuStack()
	for k,v in pairs(MenuStack) do
		if k ~= 1 then
			v.Position = UDim2.new(1, 0, 0, 0)
		else
			v.Position = UDim2.new(0, 0, 0, 0)
		end
		MenuStack[k] = nil
	end
end


local function turnOffSettingsMenu()
	SettingsShield.Active = false
	SettingsShield.Visible = false
	SettingsButton.Active = true
	SettingClipFrame.Position = CLOSE_MENU_POS
	--
	emptyMenuStack()
	IsMenuClosing = false
	pcall(function() game:GetService("UserInputService").OverrideMouseIconEnabled = false end)
end

local function closeSettingsMenu(forceClose)
	IsMenuClosing = true
	if forceClose then
		turnOffSettingsMenu()
	else
		SettingClipFrame:TweenPosition(CLOSE_MENU_POS, Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true, turnOffSettingsMenu)
	end

	if UserInputService.GamepadEnabled and isGamepadSupport then
		pcall(function() GuiService.SelectedCoreObject = nil
		ContextActionService:UnbindCoreAction("backbutton")
		ContextActionService:UnbindCoreAction("DontMove") end)
	end

	SettingsShowSignal:fire(false)
end

local backButtonFunc = function(actionName, state, input)
	if state ~= Enum.UserInputState.Begin then return end

	if #MenuStack == 1 then
		closeSettingsMenu(true)
	else
		popMenu()
	end
end

local noOptFunc = function() end

local function showSettingsRootMenu()
	SettingsButton.Active = false
	pushMenu(RootMenuFrame)
	pcall(function() UserInputService.OverrideMouseIconEnabled = true end)
	--
	SettingsShield.Visible = true
	SettingsShield.Active = true
	--
	SettingClipFrame:TweenPosition(SHOW_MENU_POS, Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
	SettingsShowSignal:fire(true)

	if not isGamepadSupport then return end
	if UserInputService.GamepadEnabled then
		pcall(function() game.ContextActionService:BindCoreAction("DontMove", noOptFunc, false, Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2, 
				Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY, Enum.KeyCode.ButtonSelect,
				Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonL2, Enum.KeyCode.ButtonL3, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonR3,
				Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown)

		ContextActionService:BindCoreAction("backbutton", backButtonFunc, false, Enum.KeyCode.ButtonB) end)
	end
end

local function showHelpMenu()
	SettingClipFrame:TweenPosition(CLOSE_MENU_POS, Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true,
	function()
		SettingClipFrame.Visible = false
	end)
	HelpMenuFrame.Visible = true
	HelpMenuFrame:TweenPosition(UDim2.new(0.2, 0, 0.2, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
end

local function hideHelpMenu()
	HelpMenuFrame:TweenPosition(UDim2.new(0.2, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true,
	function()
		HelpMenuFrame.Visible = false
	end)
	SettingClipFrame.Visible = true
	SettingClipFrame:TweenPosition(SHOW_MENU_POS, Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
end

local function changeHelpDialog(button, img)
	if CurrentHelpDialogButton == button then return end
	--
	CurrentHelpDialogButton.Style = Enum.ButtonStyle.RobloxRoundButton
	CurrentHelpDialogButton = button
	CurrentHelpDialogButton.Style = Enum.ButtonStyle.RobloxRoundDefaultButton
	HelpMenuImage.Image = img
end

local function resetLocalCharacter()
	-- NOTE: This should be fixed at some point to not find humanoid by name.
	-- Devs can rename the players humanoid and bypass this. I am leaving it this way
	-- as to not break any games that currently do this. We need to come up with
	-- a better solution to allow devs to disable character reset
	local player = Players.LocalPlayer
	if player then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild('Humanoid')
			if humanoid then
				humanoid.Health = 0
			end
		end
	end
end

local function onRecordVideoToggle()
	if not StopRecordingVideoButton then return end
	IsRecordingVideo = not IsRecordingVideo
	if IsRecordingVideo then
		StopRecordingVideoButton.Visible = true
		RecordVideoButton.Text = "Stop Recording"
	else
		StopRecordingVideoButton.Visible = false
		RecordVideoButton.Text = "Record Video"
	end
end

local function onReportSubmitted()
	if not ReportSubmitButton.Active then return end
	--
	if IsReportingPlayer then
		if CurrentAbusingPlayer and AbuseReason then
			Players:ReportAbuse(CurrentAbusingPlayer, AbuseReason, ReportDescriptionTextBox.Text)
		end
	else
		if AbuseReason then
			Players:ReportAbuse(nil, AbuseReason, ReportDescriptionTextBox.Text)
		end
	end
	if AbuseReason == 'Cheating/Exploiting' then
		ReportAbuseConfirmationText.Text = "Thanks for your report!\n We've recorded your report for evaluation."
	elseif AbuseReason == 'Bullying' or AbuseReason == 'Swearing' then
		ReportAbuseConfirmationText.Text = "Thanks for your report! Our moderators will review the chat logs and determine what happened. The other user is probably just trying to make you mad. If anyone used swear words, inappropriate language, or threatened you in real life, please report them for Bad Words or Threats"
	else
		ReportAbuseConfirmationText.Text = "Thanks for your report! Our moderators will review the chat logs and determine what happened."
	end
	pushMenu(ReportAbuseConfirmationFrame)
	cleanupReportAbuseMenu()
end

local function toggleDevConsole(actionName, inputState, inputObject)
	if actionName == "Open Dev Console" then 	-- ContextActionService->F9
		if inputState and inputState == Enum.UserInputState.Begin and BindableFunc_ToggleDevConsole then
			BindableFunc_ToggleDevConsole:Invoke()
		end
	elseif BindableFunc_ToggleDevConsole then 	-- Button Press from help menu
		BindableFunc_ToggleDevConsole:Invoke()
	end
end

local function updateUserSettingsMenu(property)
	if not isLuaControls then return end
	if property == "DevEnableMouseLock" then
		ShiftLockCheckBox.Visible = LocalPlayer.DevEnableMouseLock
		ShiftLockOverrideText.Visible = not LocalPlayer.DevEnableMouseLock
		IsShiftLockEnabled = LocalPlayer.DevEnableMouseLock and GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch
		ShiftLockCheckBox.Text = IsShiftLockEnabled and "X" or ""
	elseif property == "DevComputerCameraMode" then
		local isUserChoice = LocalPlayer.DevComputerCameraMode == Enum.DevComputerCameraMovementMode.UserChoice
		CameraModeDropDown.SetVisible(isUserChoice)
		CameraModeOverrideText.Visible = not isUserChoice
	elseif property == "DevComputerMovementMode" then
		local isUserChoice = LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.UserChoice
		if MovementModeDropDown then MovementModeDropDown.SetVisible(isUserChoice) end
		if MovementModeOverrideText then MovementModeOverrideText.Visible = not isUserChoice end
	-- TOUCH
	elseif property == "DevTouchMovementMode" then
		local isUserChoice = LocalPlayer.DevTouchMovementMode == Enum.DevTouchMovementMode.UserChoice
		if MovementModeDropDown then MovementModeDropDown.SetVisible(isUserChoice) end
		if MovementModeOverrideText then MovementModeOverrideText.Visible = not isUserChoice end
	elseif property == "DevTouchCameraMode" then
		local isUserChoice = LocalPlayer.DevTouchCameraMode == Enum.DevTouchCameraMovementMode.UserChoice
		CameraModeDropDown.SetVisible(isUserChoice)
		CameraModeOverrideText.Visible = not isUserChoice
	end
end

--[[ Input Actions ]]--
do
	SettingsShield.InputBegan:connect(function(inputObject)
		local inputType = inputObject.UserInputType
		if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
			closeCurrentDropDownMenu()
		end
	end)
	--
	local escapePressedCn = nil
	SettingsShield.Parent = SettingsMenuFrame
	--

	escapePressedCn = GuiService.EscapeKeyPressed:connect(function()
		if #MenuStack == 0 then
			showSettingsRootMenu()
		elseif #MenuStack == 1 then
			closeSettingsMenu()
		else
			local currentMenu = MenuStack[#MenuStack]
			popMenu()
			if currentMenu == ReportAbuseFrame then
				cleanupReportAbuseMenu()
			end
		end
	end)
	SettingsButton.MouseButton1Click:connect(showSettingsRootMenu)
	-- Root Menu Connections
	ResumeGameButton.MouseButton1Click:connect(closeSettingsMenu)
	ResetCharacterButton.MouseButton1Click:connect(function() pushMenu(ResetCharacterFrame) end)
	GameSettingsButton.MouseButton1Click:connect(function() pushMenu(GameSettingsMenuFrame) end)
	ReportAbuseButton.MouseButton1Click:connect(function()
		createReportAbuseMenu()
		pushMenu(ReportAbuseFrame)
	end)
	LeaveGameButton.MouseButton1Click:connect(function() pushMenu(LeaveGameMenuFrame) end)
	if ScreenshotButton then
		ScreenshotButton.MouseButton1Click:connect(function()
			closeSettingsMenu(true)
		end)
	end
	if HelpButton then
		HelpButton.MouseButton1Click:connect(function() pushMenu(HelpMenuFrame) end)
	end

	--[[ Video Recording ]]--
	if RecordVideoButton then
		RecordVideoButton.MouseButton1Click:connect(function()
			closeSettingsMenu(true)
		end)
	end
	local gameOptions = settings():FindFirstChild("Game Options")
	if gameOptions then
		local success, result = pcall(function()
			gameOptions.VideoRecordingChangeRequest:connect(function(recording)
				if isTopBar then
					IsRecordingVideo = not IsRecordingVideo
					RecordVideoButton.Text = IsRecordingVideo and "Stop Recording" or "Record Video"
				else
					onRecordVideoToggle()
				end
			end)
		end)
		if not success then
			print("Settings2.lua: VideoRecordingChangeRequest connection failed because", result)
		end
	end

	-- Reset Character Menu Connections
	ConfirmResetButton.MouseButton1Click:connect(function()
		resetLocalCharacter()
		closeSettingsMenu()
	end)
	CancelResetButton.MouseButton1Click:connect(popMenu)

	if ShiftLockCheckBox then
		ShiftLockCheckBox.MouseButton1Click:connect(function()
			IsShiftLockEnabled = not IsShiftLockEnabled
			ShiftLockCheckBox.Text = IsShiftLockEnabled and "X" or ""
			GameSettings.ControlMode = IsShiftLockEnabled and "MouseLockSwitch" or "Classic"
			if shiftLockImageLabel then
				shiftLockImageLabel.Visible = IsShiftLockEnabled
			end
		end)
	end
	-- Game Settings Menu Connections

	GameSettingsBackButton.MouseButton1Click:connect(popMenu)

	-- Help Menu Connections
	HelpMenuBackButton.MouseButton1Click:connect(popMenu)
	HelpLookButton.MouseButton1Click:connect(function()
		changeHelpDialog(HelpLookButton, GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch and HELP_IMG.SHIFT_LOCK or HELP_IMG.CLASSIC_MOVE)
	end)
	HelpMoveButton.MouseButton1Click:connect(function()
		changeHelpDialog(HelpMoveButton, HELP_IMG.MOVEMENT)
	end)
	HelpGearButton.MouseButton1Click:connect(function()
		changeHelpDialog(HelpGearButton, HELP_IMG.GEAR)
	end)
	HelpZoomButton.MouseButton1Click:connect(function()
		changeHelpDialog(HelpZoomButton, HELP_IMG.ZOOM)
	end)

	-- Report Abuse Connections
	ReportCancelButton.MouseButton1Click:connect(function()
		popMenu()
		cleanupReportAbuseMenu()
	end)
	ReportSubmitButton.MouseButton1Click:connect(onReportSubmitted)
	ReportAbuseConfirmationButton.MouseButton1Click:connect(closeSettingsMenu)

	-- Leave Game Menu
	LeaveCancelButton.MouseButton1Click:connect(popMenu)

	-- Dev Console Connections
	HelpConsoleButton.MouseButton1Click:connect(toggleDevConsole)
	local success = pcall(function() ContextActionService:BindCoreAction("Open Dev Console", toggleDevConsole, false, Enum.KeyCode.F9) end)
	if not success then
		UserInputService.InputBegan:connect(function(inputObject)
			if inputObject.KeyCode == Enum.KeyCode.F9 then
				toggleDevConsole("Open Dev Console", Enum.UserInputState.Begin, inputObject)
			end
		end)
		UserInputService.InputEnded:connect(function(inputObject)
			if inputObject.KeyCode == Enum.KeyCode.F9 then
				toggleDevConsole("Open Dev Console", Enum.UserInputState.End, inputObject)
			end
		end)
	end

	LocalPlayer.Changed:connect(function(property)
		if IsTouchClient then
			if TOUCH_CHANGED_PROPS[property] then
				updateUserSettingsMenu(property)
			end
		else
			if PC_CHANGED_PROPS[property] then
				updateUserSettingsMenu(property)
			end
		end
	end)

	-- connect back button on android
	local showLeaveEvent = nil
	pcall(function() showLeaveEvent = GuiService.ShowLeaveConfirmation end)
	if showLeaveEvent then
		GuiService.ShowLeaveConfirmation:connect(function()
			if #MenuStack == 0 then
				showSettingsRootMenu()
				RootMenuFrame.Position = UDim2.new(-1, 0, 0, 0)
				LeaveGameMenuFrame.Position = UDim2.new(0, 0, 0, 0)
				pushMenu(LeaveGameMenuFrame)
			else
				closeSettingsMenu()
			end
		end)
	end

	-- Remove old gui buttons
	-- TODO: Gut this from the engine code
	local oldLeaveGameButton = TopLeftControl:FindFirstChild('Exit')
	if oldLeaveGameButton then
		oldLeaveGameButton:Destroy()
	else
		oldLeaveGameButton = BottomLeftControl:FindFirstChild('Exit')
		if oldLeaveGameButton then oldLeaveGameButton:Destroy() end
	end

	SettingsMenuFrame.Parent = RobloxGui
end

local moduleApiTable = {}

function moduleApiTable:ToggleVisibility(visible)
	if visible then
		showSettingsRootMenu()
	else
		closeSettingsMenu()
	end
end

 moduleApiTable.SettingsShowSignal = SettingsShowSignal

return moduleApiTable
