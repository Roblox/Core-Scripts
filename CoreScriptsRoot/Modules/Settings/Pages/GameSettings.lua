--[[
		Filename: GameSettings.lua
		Written by: jeditkacheff
		Version 1.0
		Description: Takes care of the Game Settings Tab in Settings Menu
--]]

-------------- SERVICES --------------
local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Settings = UserSettings()
local GameSettings = Settings.GameSettings

-------------- CONSTANTS --------------
local GRAPHICS_QUALITY_LEVELS = 10
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
local PC_CHANGED_PROPS = {
	DevComputerMovementMode = true,
	DevComputerCameraMode = true,
	DevEnableMouseLock = true,
}
local TOUCH_CHANGED_PROPS = {
	DevTouchMovementMode = true,
	DevTouchCameraMode = true,
}
local CAMERA_MODE_DEFAULT_STRING = UserInputService.TouchEnabled and "Default (Follow)" or "Default (Classic)"

local MOVEMENT_MODE_DEFAULT_STRING = UserInputService.TouchEnabled and "Default (Thumbstick)" or "Default (Keyboard)"
local MOVEMENT_MODE_KEYBOARDMOUSE_STRING = "Keyboard + Mouse"
local MOVEMENT_MODE_CLICKTOMOVE_STRING = UserInputService.TouchEnabled and "Tap to Move" or "Click to Move"

----------- UTILITIES --------------
local utility = require(RobloxGui.Modules.Utility)

------------ Variables -------------------
local PageInstance = nil
local LocalPlayer = game.Players.LocalPlayer
local platform = UserInputService:GetPlatform()
local nextRowPositionY = 0
local rowHeight = 50

----------- CLASS DECLARATION --------------

local function Initialize()	
	local settingsPageFactory = require(RobloxGui.Modules.Settings.SettingsPageFactory)
	local this = settingsPageFactory:CreateNewPage()

	----------- FUNCTIONS ---------------
	local function createGraphicsOptions()

		------------------ Fullscreen Selection GUI Setup ------------------
		local fullScreenInit = 1
		if not GameSettings:InFullScreen() then
			fullScreenInit = 2
		end

		this.FullscreenFrame, 
		this.FullscreenLabel,
		this.FullscreenEnabler = utility:AddNewRow(this, "Fullscreen", "Selector", {"On", "Off"}, fullScreenInit)

		local fullScreenSelectionFrame = this.FullscreenEnabler.SliderFrame and this.FullscreenEnabler.SliderFrame or this.FullscreenEnabler.SelectorFrame

		this.FullscreenEnabler.IndexChanged:connect(function(newIndex)
			GuiService:ToggleFullscreen()
		end)
		
		------------------ Gfx Enabler Selection GUI Setup ------------------
		this.GraphicsEnablerFrame, 
		this.GraphicsEnablerLabel,
		this.GraphicsQualityEnabler = utility:AddNewRow(this, "Graphics Mode", "Selector", {"Automatic", "Manual"}, 1)

		------------------ Gfx Slider GUI Setup  ------------------
		this.GraphicsQualityFrame, 
		this.GraphicsQualityLabel,
		this.GraphicsQualitySlider = utility:AddNewRow(this, "Graphics Quality", "Slider", GRAPHICS_QUALITY_LEVELS, 1)

		------------------------- Connection Setup ----------------------------
		settings().Rendering.EnableFRM = true

		function SetGraphicsQuality(newValue, automaticSettingAllowed)
			local percentage = newValue/GRAPHICS_QUALITY_LEVELS
			local newQualityLevel = math.floor((settings().Rendering:GetMaxQualityLevel() - 1) * percentage)
			if newQualityLevel == 20 then
				newQualityLevel = 21
			elseif newValue == 1 then
				newQualityLevel = 1
			elseif newValue < 1 and not automaticSettingAllowed then
				newValue = 1
				newQualityLevel = 1
			elseif newQualityLevel > settings().Rendering:GetMaxQualityLevel() then
				newQualityLevel = settings().Rendering:GetMaxQualityLevel() - 1
			end

			GameSettings.SavedQualityLevel = newValue
			settings().Rendering.QualityLevel = newQualityLevel
		end

		local function setGraphicsToAuto()
			this.GraphicsQualitySlider:SetZIndex(1)
			this.GraphicsQualityLabel.ZIndex = 1
			this.GraphicsQualitySlider:SetInteractable(false)

			SetGraphicsQuality(Enum.QualityLevel.Automatic.Value, true)
		end
		local function setGraphicsToManual(level)
			this.GraphicsQualitySlider:SetZIndex(2)
			this.GraphicsQualityLabel.ZIndex = 2
			this.GraphicsQualitySlider:SetInteractable(true)

			-- need to force the quality change if slider is already at this position
			if this.GraphicsQualitySlider:GetValue() == level then
				SetGraphicsQuality(level)
			else
				this.GraphicsQualitySlider:SetValue(level)
			end
		end

		game.GraphicsQualityChangeRequest:connect(function(isIncrease)
			if settings().Rendering.QualityLevel == Enum.QualityLevel.Automatic then return end
			--
			local currentGraphicsSliderValue = this.GraphicsQualitySlider:GetValue()
			if isIncrease then
				currentGraphicsSliderValue = currentGraphicsSliderValue + 1
			else
				currentGraphicsSliderValue = currentGraphicsSliderValue - 1
			end

			this.GraphicsQualitySlider:SetValue(currentGraphicsSliderValue)
		end)
		
		this.GraphicsQualitySlider.ValueChanged:connect(function(newValue)
			SetGraphicsQuality(newValue)
		end)

		this.GraphicsQualityEnabler.IndexChanged:connect(function(newIndex)
			if newIndex == 1 then
				setGraphicsToAuto()
			elseif newIndex == 2 then
				setGraphicsToManual( this.GraphicsQualitySlider:GetValue() )
			end
		end)

		-- initialize the slider position
		if GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic then
			this.GraphicsQualitySlider:SetValue(5)
			this.GraphicsQualityEnabler:SetSelectionIndex(1)
		else
			local graphicsLevel = tostring(GameSettings.SavedQualityLevel)
			if GRAPHICS_QUALITY_TO_INT[graphicsLevel] then
				graphicsLevel = GRAPHICS_QUALITY_TO_INT[graphicsLevel]
			else
				graphicsLevel = GRAPHICS_QUALITY_LEVELS
			end

			spawn(function()
				this.GraphicsQualitySlider:SetValue(graphicsLevel)
				this.GraphicsQualityEnabler:SetSelectionIndex(2)
			end)
		end
	end

	local function createCameraModeOptions()
		------------------------------------------------------
		------------------
		------------------ Shift Lock Switch -----------------
		if UserInputService.MouseEnabled then
			this.ShiftLockFrame, 
			this.ShiftLockLabel,
			this.ShiftLockMode,
			this.ShiftLockOverrideText = nil

			if UserInputService.MouseEnabled and UserInputService.KeyboardEnabled then
				local startIndex = 2
				if GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch then
					startIndex = 1
				end

				this.ShiftLockFrame, 
				this.ShiftLockLabel,
				this.ShiftLockMode = utility:AddNewRow(this, "Shift Lock Switch", "Selector", {"On", "Off"}, startIndex)

				this.ShiftLockOverrideText = utility:Create'TextLabel'
				{
					Name = "ShiftLockOverrideLabel",
					Text = "Set by Developer",
					TextColor3 = Color3.new(1,1,1),
					Font = Enum.Font.SourceSans,
					FontSize = Enum.FontSize.Size24,
					BackgroundTransparency = 1,
					Size = UDim2.new(0,200,1,0),
					Position = UDim2.new(1,-350,0,0),
					Visible = false,
					ZIndex = 2,
					Parent = this.ShiftLockFrame
				};

				this.ShiftLockMode.IndexChanged:connect(function(newIndex)
					if newIndex == 1 then
						GameSettings.ControlMode = Enum.ControlMode.MouseLockSwitch
					else
						GameSettings.ControlMode = Enum.ControlMode.Classic
					end
				end)
			end
		end


		------------------------------------------------------
		------------------
		------------------ Camera Mode -----------------------
		do
			local enumItems = nil
			local startingCameraEnumItem = 1
			if UserInputService.TouchEnabled then
				enumItems = Enum.TouchCameraMovementMode:GetEnumItems()
			else
				enumItems = Enum.ComputerCameraMovementMode:GetEnumItems()
			end

			local cameraEnumNames = {}
			local cameraEnumNameToItem = {}
			for i = 1, #enumItems do
				local displayName = enumItems[i].Name
				if displayName == 'Default' then
					displayName = CAMERA_MODE_DEFAULT_STRING
				end

				if UserInputService.TouchEnabled then
					if GameSettings.TouchCameraMovementMode == enumItems[i] then
						startingCameraEnumItem = i
					end
				else
					if GameSettings.ComputerCameraMovementMode == enumItems[i] then
						startingCameraEnumItem = i
					end
				end

				cameraEnumNames[i] = displayName
				cameraEnumNameToItem[displayName] = enumItems[i].Value
			end

			this.CameraModeFrame, 
			this.CameraModeLabel,
			this.CameraMode = utility:AddNewRow(this, "Camera Mode", "Selector", cameraEnumNames, startingCameraEnumItem)

			this.CameraModeOverrideText = utility:Create'TextLabel'
			{
				Name = "CameraDevOverrideLabel",
				Text = "Set by Developer",
				TextColor3 = Color3.new(1,1,1),
				Font = Enum.Font.SourceSans,
				FontSize = Enum.FontSize.Size24,
				BackgroundTransparency = 1,
				Size = UDim2.new(0,200,1,0),
				Position = UDim2.new(1,-350,0,0),
				Visible = false,
				ZIndex = 2,
				Parent = this.CameraModeFrame
			};

			this.CameraMode.IndexChanged:connect(function(newIndex)
				local newEnumSetting = cameraEnumNameToItem[cameraEnumNames[newIndex]]

				if UserInputService.TouchEnabled then
					GameSettings.TouchCameraMovementMode = newEnumSetting
				else
					GameSettings.ComputerCameraMovementMode = newEnumSetting
				end
			end)
		end

		------------------------------------------------------
		------------------
		------------------ Movement Mode ---------------------
		do
			local movementEnumItems = nil
			local startingMovementEnumItem = 1
			if UserInputService.TouchEnabled then
				movementEnumItems = Enum.TouchMovementMode:GetEnumItems()
			else
				movementEnumItems = Enum.ComputerMovementMode:GetEnumItems()
			end

			local movementEnumNames = {}
			local movementEnumNameToItem = {}
			for i = 1, #movementEnumItems do
				local displayName = movementEnumItems[i].Name
				if displayName == "Default" then
					displayName = MOVEMENT_MODE_DEFAULT_STRING
				elseif displayName == "KeyboardMouse" then
					displayName = MOVEMENT_MODE_KEYBOARDMOUSE_STRING
				elseif displayName == "ClickToMove" then
					displayName = MOVEMENT_MODE_CLICKTOMOVE_STRING
				end

				if UserInputService.TouchEnabled then
					if GameSettings.TouchMovementMode == movementEnumItems[i] then
						startingMovementEnumItem = i
					end
				else
					if GameSettings.ComputerMovementMode == movementEnumItems[i] then
						startingMovementEnumItem = i
					end
				end

				movementEnumNames[i] = displayName
				movementEnumNameToItem[displayName] = movementEnumItems[i]
			end

			this.MovementModeFrame, 
			this.MovementModeLabel,
			this.MovementMode = utility:AddNewRow(this, "Movement Mode", "Selector", movementEnumNames, startingMovementEnumItem)

			this.MovementModeOverrideText = utility:Create'TextLabel'
			{
				Name = "MovementDevOverrideLabel",
				Text = "Set by Developer",
				TextColor3 = Color3.new(1,1,1),
				Font = Enum.Font.SourceSans,
				FontSize = Enum.FontSize.Size24,
				BackgroundTransparency = 1,
				Size = UDim2.new(0,200,1,0),
				Position = UDim2.new(1,-350,0,0),
				Visible = false,
				ZIndex = 2,
				Parent = this.MovementModeFrame
			};

			this.MovementMode.IndexChanged:connect(function(newIndex)
				local newEnumSetting = movementEnumNameToItem[movementEnumNames[newIndex]]
				
				if UserInputService.TouchEnabled then
					GameSettings.TouchMovementMode = newEnumSetting
				else
					GameSettings.ComputerMovementMode = newEnumSetting
				end
			end)
		end


		------------------------------------------------------
		------------------
		------------------------- Connection Setup -----------
		function setCameraModeVisible(visible)
			this.CameraMode.SelectorFrame.Visible = visible
			this.CameraMode:SetInteractable(visible)
		end

		function setMovementModeVisible(visible)
			this.MovementMode.SelectorFrame.Visible = visible
			this.MovementMode:SetInteractable(visible)
		end

		function setShiftLockVisible(visible)
			this.ShiftLockMode.SelectorFrame.Visible = visible
			this.ShiftLockMode:SetInteractable(visible)
		end

		do -- initial set of dev vs user choice for guis
			local isUserChoiceCamera = false
			if UserInputService.TouchEnabled then
				isUserChoiceCamera = LocalPlayer.DevTouchCameraMode == Enum.DevTouchCameraMovementMode.UserChoice
			else
				isUserChoiceCamera = LocalPlayer.DevComputerCameraMode == Enum.DevComputerCameraMovementMode.UserChoice
			end

			if not isUserChoiceCamera then
				this.CameraModeOverrideText.Visible = true
				setCameraModeVisible(false)
			else
				this.CameraModeOverrideText.Visible = false
				setCameraModeVisible(true)
			end


			local isUserChoiceMovement = false
			if UserInputService.TouchEnabled then
				isUserChoiceMovement = LocalPlayer.DevTouchMovementMode == Enum.DevTouchMovementMode.UserChoice
			else
				isUserChoiceMovement = LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.UserChoice
			end

			if not isUserChoiceMovement then
				this.MovementModeOverrideText.Visible = true
				setMovementModeVisible(false)
			else
				this.MovementModeOverrideText.Visible = false
				setMovementModeVisible(true)
			end

			if this.ShiftLockOverrideText then
				this.ShiftLockOverrideText.Visible = not LocalPlayer.DevEnableMouseLock
				setShiftLockVisible(LocalPlayer.DevEnableMouseLock)
			end
		end

		local function updateUserSettingsMenu(property)
			if this.ShiftLockOverrideText and property == "DevEnableMouseLock" then
				this.ShiftLockOverrideText.Visible = not LocalPlayer.DevEnableMouseLock
				setShiftLockVisible(LocalPlayer.DevEnableMouseLock)
			elseif property == "DevComputerCameraMode" then
				local isUserChoice = LocalPlayer.DevComputerCameraMode == Enum.DevComputerCameraMovementMode.UserChoice
				setCameraModeVisible(isUserChoice)
				this.CameraModeOverrideText.Visible = not isUserChoice
			elseif property == "DevComputerMovementMode" then
				local isUserChoice = LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.UserChoice
				setMovementModeVisible(isUserChoice)
				this.MovementModeOverrideText.Visible = not isUserChoice
			-- TOUCH
			elseif property == "DevTouchMovementMode" then
				local isUserChoice = LocalPlayer.DevTouchMovementMode == Enum.DevTouchMovementMode.UserChoice
				setMovementModeVisible(isUserChoice)
				this.MovementModeOverrideText.Visible = not isUserChoice
			elseif property == "DevTouchCameraMode" then
				local isUserChoice = LocalPlayer.DevTouchCameraMode == Enum.DevTouchCameraMovementMode.UserChoice
				setCameraModeVisible(isUserChoice)
				this.CameraModeOverrideText.Visible = not isUserChoice
			end
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
	end

	local function createVolumeOptions()
		local startVolumeLevel = math.floor(GameSettings.MasterVolume * 10)
		this.VolumeFrame, 
		this.VolumeLabel,
		this.VolumeSlider = utility:AddNewRow(this, "Volume", "Slider", 10, startVolumeLevel)

		this.VolumeSlider.ValueChanged:connect(function(newValue)
			GameSettings.MasterVolume = newValue/10
		end)
	end

	local function createMouseOptions()
		local MouseSteps = 10
		local MinMouseSensitivity = 0.2

		-- equations below map a function to include points (0, 0.2) (5, 1) (10, 4)
		-- where x is the slider position, y is the mouse sensitivity
		local function translateEngineMouseSensitivityToGui(engineSensitivity)
			return math.floor((2.0/3.0) * (math.sqrt(75.0 * engineSensitivity - 11.0) - 2))
		end

		local function translateGuiMouseSensitivityToEngine(guiSensitivity)
			return 0.03 * math.pow(guiSensitivity,2) + (0.08 * guiSensitivity) + MinMouseSensitivity
		end

		local startMouseLevel = translateEngineMouseSensitivityToGui(GameSettings.MouseSensitivity)

		this.MouseSensitivityFrame, 
		this.MouseSensitivityLabel,
		this.MouseSensitivitySlider = utility:AddNewRow(this, "Mouse Sensitivity", "Slider", MouseSteps, startMouseLevel)

		this.MouseSensitivitySlider.ValueChanged:connect(function(newValue)
			GameSettings.MouseSensitivity = translateGuiMouseSensitivityToEngine(newValue)
		end)
	end

	createCameraModeOptions()

	if UserInputService.MouseEnabled then
		local mouseSensSuccess, mouseSensFlagValue = pcall(function() return settings():GetFFlag("MouseSensitivity") end)
		if mouseSensSuccess and mouseSensFlagValue then
			createMouseOptions()
		end
	end

	createVolumeOptions()

	if platform == Enum.Platform.Windows or platform == Enum.Platform.OSX then
		createGraphicsOptions()
	end

	------ TAB CUSTOMIZATION -------
	this.TabHeader.Name = "GameSettingsTab"

	this.TabHeader.Icon.Image = "rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab.png"
	if utility:IsSmallTouchScreen() then
		this.TabHeader.Icon.Size = UDim2.new(0,34,0,34)
		this.TabHeader.Icon.Position = UDim2.new(this.TabHeader.Icon.Position.X.Scale,this.TabHeader.Icon.Position.X.Offset,0.5,-17)
		this.TabHeader.Size = UDim2.new(0,125,1,0)
	else
		this.TabHeader.Icon.Size = UDim2.new(0,45,0,45)
		this.TabHeader.Icon.Position = UDim2.new(0,15,0.5,-22)
	end


	this.TabHeader.Icon.Title.Text = "Settings"

	------ PAGE CUSTOMIZATION -------
	this.Page.ZIndex = 5

	return this
end


----------- Page Instantiation --------------

PageInstance = Initialize()

return PageInstance