--[[
		Filename: GameSettings.lua
		Written by: jeditkacheff
		Version 1.1
		Description: Takes care of the Game Settings Tab in Settings Menu
--]]

-------------- SERVICES --------------
local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PlatformService = nil
pcall(function() PlatformService = game:GetService("PlatformService") end)
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
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
local utility = require(RobloxGui.Modules.Settings.Utility)

------------ Variables -------------------
RobloxGui:WaitForChild("Modules"):WaitForChild("TenFootInterface")
RobloxGui:WaitForChild("Modules"):WaitForChild("Settings"):WaitForChild("SettingsHub")
local isTenFootInterface = require(RobloxGui.Modules.TenFootInterface):IsEnabled()
local HasVRAPI = false
pcall(function() HasVRAPI = UserInputService.GetUserCFrame ~= nil end)
local PageInstance = nil
local LocalPlayer = Players.LocalPlayer
local platform = UserInputService:GetPlatform()
local overscanScreen = nil

----------- CLASS DECLARATION --------------

local function Initialize()
  local settingsPageFactory = require(RobloxGui.Modules.Settings.SettingsPageFactory)
  local this = settingsPageFactory:CreateNewPage()

  local allSettingsCreated = false
  local settingsDisabledInVR = {}
  local function onVRSettingsReady()
    local vrEnabled = UserInputService.VREnabled
    for settingFrame, _ in pairs(settingsDisabledInVR) do
      settingFrame:SetInteractable(not vrEnabled)
    end
  end

  local function onVREnabled(prop)
    if prop ~= "VREnabled" then return end
    if UserInputService.VREnabled and allSettingsCreated then
      --Only call this if all settings have been created.
      --If they aren't ready by the time VR is enabled, this
      --will be called later when they are.
      onVRSettingsReady()
    end
  end
  UserInputService.Changed:connect(onVREnabled)
  onVREnabled("VREnabled")

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

    settingsDisabledInVR[this.FullscreenEnabler] = true

    this.FullscreenEnabler.IndexChanged:connect(function(newIndex)
        if newIndex == 1 then
          if not GameSettings:InFullScreen() then
            GuiService:ToggleFullscreen()
            this.FullscreenEnabler:SetSelectionIndex(1)
          end
        elseif newIndex == 2 then
          if GameSettings:InFullScreen() then
            GuiService:ToggleFullscreen()
            this.FullscreenEnabler:SetSelectionIndex(2)
          end
        end
      end)

    GameSettings.FullscreenChanged:connect(function(isFullScreen)
        if isFullScreen then
          if this.FullscreenEnabler:GetSelectedIndex() ~= 1 then
            this.FullscreenEnabler:SetSelectionIndex(1)
          end
        else
          if this.FullscreenEnabler:GetSelectedIndex() ~= 2 then
            this.FullscreenEnabler:SetSelectionIndex(2)
          end
        end
      end)

    ------------------ Gfx Enabler Selection GUI Setup ------------------
    local graphicsEnablerStart = 1
    if GameSettings.SavedQualityLevel ~= Enum.SavedQualitySetting.Automatic then
      graphicsEnablerStart = 2
    end

    this.GraphicsEnablerFrame,
    this.GraphicsEnablerLabel,
    this.GraphicsQualityEnabler = utility:AddNewRow(this, "Graphics Mode", "Selector", {"Automatic", "Manual"}, graphicsEnablerStart)

    ------------------ Gfx Slider GUI Setup  ------------------
    this.GraphicsQualityFrame,
    this.GraphicsQualityLabel,
    this.GraphicsQualitySlider = utility:AddNewRow(this, "Graphics Quality", "Slider", GRAPHICS_QUALITY_LEVELS, 1)
    this.GraphicsQualitySlider:SetMinStep(1)

    ------------------------------------------------------
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
        --  was using settings().Rendering.Quality level, which was wrongly saying it was automatic.
        if GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic then return end
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
      setGraphicsToAuto()
    else
      local graphicsLevel = tostring(GameSettings.SavedQualityLevel)
      if GRAPHICS_QUALITY_TO_INT[graphicsLevel] then
        graphicsLevel = GRAPHICS_QUALITY_TO_INT[graphicsLevel]
      else
        graphicsLevel = GRAPHICS_QUALITY_LEVELS
      end

      spawn(function()
          this.GraphicsQualitySlider:SetValue(graphicsLevel)
        end)
    end
  end  -- of createGraphicsOptions

  local function createPerformanceStatsOptions()
    ------------------
    ------------------ Performance Stats -----------------
    this.PerformanceStatsFrame,
    this.PerformanceStatsLabel,
    this.PerformanceStatsMode,
    this.PerformanceStatsOverrideText = nil

    function GetDesiredPerformanceStatsIndex()
      if GameSettings.PerformanceStatsVisible then
        return 1
      else
        return 2
      end
    end

    local startIndex = GetDesiredPerformanceStatsIndex()

    this.PerformanceStatsFrame,
    this.PerformanceStatsLabel,
    this.PerformanceStatsMode = utility:AddNewRow(this,
      "Performance Stats",
      "Selector",
      {"On", "Off"},
      startIndex)

    this.PerformanceStatsOverrideText = utility:Create'TextLabel'
    {
      Name = "PerformanceStatsLabel",
      Text = "Set by Developer",
      TextColor3 = Color3.new(1,1,1),
      Font = Enum.Font.SourceSans,
      FontSize = Enum.FontSize.Size24,
      BackgroundTransparency = 1,
      Size = UDim2.new(0,200,1,0),
      Position = UDim2.new(1,-350,0,0),
      Visible = false,
      ZIndex = 2,
      Parent = this.PerformanceStatsFrame
    };

    this.PerformanceStatsMode.IndexChanged:connect(function(newIndex)
        if newIndex == 1 then
          GameSettings.PerformanceStatsVisible = true
        else
          GameSettings.PerformanceStatsVisible = false
        end
      end)

    GameSettings.PerformanceStatsVisibleChanged:connect(function()
        local desiredIndex = GetDesiredPerformanceStatsIndex()
        if desiredIndex ~= this.PerformanceStatsMode.CurrentIndex then
          this.PerformanceStatsMode:SetSelectionIndex(desiredIndex)
        end
      end)
  end  -- of createPerformanceStats

  local function createCameraModeOptions(movementModeEnabled)
    ------------------------------------------------------
    ------------------
    ------------------ Shift Lock Switch -----------------
    if UserInputService.MouseEnabled and not isTenFootInterface then
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
        this.ShiftLockMode = utility:AddNewRow(this,
          "Shift Lock Switch",
          "Selector",
          {"On", "Off"},
          startIndex)

        settingsDisabledInVR[this.ShiftLockMode] = true

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

      settingsDisabledInVR[this.CameraMode] = true

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
    ------------------ VR Camera Mode -----------------------

    if HasVRAPI and UserInputService.VREnabled then
      local VR_ROTATION_INTENSITY_OPTIONS = {"Low", "High", "Smooth"}

      if utility:IsSmallTouchScreen() then
        this.VRRotationFrame,
        this.VRRotationLabel,
        this.VRRotationMode = utility:AddNewRow(this, "VR Camera Rotation", "Selector", VR_ROTATION_INTENSITY_OPTIONS, GameSettings.VRRotationIntensity)
      else
        this.VRRotationFrame,
        this.VRRotationLabel,
        this.VRRotationMode = utility:AddNewRow(this, "VR Camera Rotation", "Selector", VR_ROTATION_INTENSITY_OPTIONS, GameSettings.VRRotationIntensity, 3)
      end

      StarterGui:RegisterGetCore("VRRotationIntensity",
        function()
          return VR_ROTATION_INTENSITY_OPTIONS[GameSettings.VRRotationIntensity] or VR_ROTATION_INTENSITY_OPTIONS[1]
        end)
      this.VRRotationMode.IndexChanged:connect(function(newIndex)
          GameSettings.VRRotationIntensity = newIndex
        end)
    end

    ------------------------------------------------------
    ------------------
    ------------------ Movement Mode ---------------------
    if movementModeEnabled then
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

      settingsDisabledInVR[this.MovementMode] = true

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
      if this.CameraMode then
        this.CameraMode.SelectorFrame.Visible = visible
        this.CameraMode:SetInteractable(visible)
      end
    end

    function setMovementModeVisible(visible)
      if this.MovementMode then
        this.MovementMode.SelectorFrame.Visible = visible
        this.MovementMode:SetInteractable(visible)
      end
    end

    function setShiftLockVisible(visible)
      if this.ShiftLockMode then
        this.ShiftLockMode.SelectorFrame.Visible = visible
        this.ShiftLockMode:SetInteractable(visible)
      end
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

      if this.MovementModeOverrideText then
        if not isUserChoiceMovement then
          this.MovementModeOverrideText.Visible = true
          setMovementModeVisible(false)
        else
          this.MovementModeOverrideText.Visible = false
          setMovementModeVisible(true)
        end
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
        if this.MovementModeOverrideText then
          this.MovementModeOverrideText.Visible = not isUserChoice
        end
        -- TOUCH
      elseif property == "DevTouchMovementMode" then
        local isUserChoice = LocalPlayer.DevTouchMovementMode == Enum.DevTouchMovementMode.UserChoice
        setMovementModeVisible(isUserChoice)
        if this.MovementModeOverrideText then
          this.MovementModeOverrideText.Visible = not isUserChoice
        end
      elseif property == "DevTouchCameraMode" then
        local isUserChoice = LocalPlayer.DevTouchCameraMode == Enum.DevTouchCameraMovementMode.UserChoice
        setCameraModeVisible(isUserChoice)
        this.CameraModeOverrideText.Visible = not isUserChoice
      end
    end

    LocalPlayer.Changed:connect(function(property)
        if UserInputService.TouchEnabled then
          if TOUCH_CHANGED_PROPS[property] then
            updateUserSettingsMenu(property)
          end
        end
        if UserInputService.KeyboardEnabled then
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

    local volumeSound = Instance.new("Sound", game:GetService("CoreGui").RobloxGui.Sounds)
    volumeSound.Name = "VolumeChangeSound"
    volumeSound.SoundId = "rbxasset://sounds/uuhhh.mp3"

    this.VolumeSlider.ValueChanged:connect(function(newValue)
        local soundPercent = newValue/10
        volumeSound.Volume = soundPercent
        volumeSound:Play()
        GameSettings.MasterVolume = soundPercent
      end)
  end

  local function createMouseOptions()
    local MouseSteps = 10
    local MinMouseSensitivity = 0.2
    local AdvancedSuccess, AdvancedValue = pcall(function() return settings():GetFFlag("AdvancedMouseSensitivityEnabled") end)
    local AdvancedEnabled = AdvancedSuccess and AdvancedValue

    -- equations below map a function to include points (0, 0.2) (5, 1) (10, 4)
    -- where x is the slider position, y is the mouse sensitivity
    local function translateEngineMouseSensitivityToGui(engineSensitivity)
      return math.floor((2.0/3.0) * (math.sqrt(75.0 * engineSensitivity - 11.0) - 2))
    end

    local function translateGuiMouseSensitivityToEngine(guiSensitivity)
      return 0.03 * math.pow(guiSensitivity,2) + (0.08 * guiSensitivity) + MinMouseSensitivity
    end

    local startMouseLevel = translateEngineMouseSensitivityToGui(GameSettings.MouseSensitivity)

    ------------------ Mouse Selection GUI Setup ------------------
    -- switch between basic mode and advanced mode.
    local MouseModeEnablerStart = 2
    if GameSettings.UseBasicMouseSensitivity or not AdvancedEnabled then
      MouseModeEnablerStart = 1
    end

    -- auto-detect mouse invert
    local MouseInvertStart = 1
    if GameSettings.MouseSensitivityFirstPerson.y < 0 then
      MouseInvertStart = 2
    end

    if AdvancedEnabled then
      this.MouseModeFrame,
      this.MouseModeLabel,
      this.MouseModeEnabler = utility:AddNewRow(this, "Mouse Sensitivity Mode", "Selector", {"Basic", "Advanced"}, MouseModeEnablerStart)
    end

    ------------------ Basic Mouse Sensitivity Slider ------------------
    -- basic quantized sensitivity with a weird number of settings.
    local SliderLabel = "Basic Mouse Sensitivity"
    if not AdvancedEnabled then
      SliderLabel = "Mouse Sensitivity"
    end
    this.MouseSensitivityFrame,
    this.MouseSensitivityLabel,
    this.MouseSensitivitySlider = utility:AddNewRow(this, SliderLabel, "Slider", MouseSteps, startMouseLevel)
    this.MouseSensitivitySlider:SetMinStep(1)

    this.MouseSensitivitySlider.ValueChanged:connect(function(newValue)
        GameSettings.MouseSensitivity = translateGuiMouseSensitivityToEngine(newValue)
      end)

    ------------------ 3D Sensitivity ------------------
    -- affects both first and third person.
    if AdvancedEnabled then
      local MouseAdvancedStart = tostring(GameSettings.MouseSensitivityFirstPerson.y)
      this.MouseAdvancedFrame,
      this.MouseAdvancedLabel,
      this.MouseAdvancedEntry = utility:AddNewRow(this, "Advanced Mouse Sensitivity", "TextEntry", 1.0, 1.0, MouseAdvancedStart)

      this.MouseAdvancedEntry.ValueChanged:connect(function(newValueText)
          local currentFirstSensitivity = GameSettings.MouseSensitivityFirstPerson
          local currentThirdSensitivity = GameSettings.MouseSensitivityThirdPerson

          local newValue = tonumber(newValueText)
          if not newValue then
            this.MouseAdvancedEntry:SetValue(string.format("%.3f",currentFirstSensitivity.x))
            return
          end

          -- inverted mouse will be handled later
          if newValue < 0.0 then
            newValue = -newValue
          end

          -- * assume a minimum that allows a 16000 dpi mouse a full 800mm travel for 360deg
          --   ~0.0029: min of 0.001 seems ok.
          -- * assume a max that allows a 400 dpi mouse a 360deg travel in 10mm
          --   ~9.2: max of 10 seems ok, but users will want to have a bit of fun with crazy settings.
          if newValue > 100.0 then
            newValue = 100.0
          elseif newValue < 0.001 then
            newValue = 0.001
          end

          -- try to keep ratios the same, even though they aren't exposed to the GUI
          local firstPersonX = newValue
          local firstPersonY = newValue * (currentFirstSensitivity.y / currentFirstSensitivity.x)
          local thirdPersonX = newValue * (currentFirstSensitivity.x / currentThirdSensitivity.x)
          local thirdPersonY = thirdPersonX * (currentThirdSensitivity.y / currentThirdSensitivity.x)

          GameSettings.MouseSensitivityFirstPerson = Vector2.new(firstPersonX, firstPersonY)
          GameSettings.MouseSensitivityThirdPerson = Vector2.new(thirdPersonX, thirdPersonY)
          this.MouseAdvancedEntry:SetValue(string.format("%.3f",firstPersonX))

        end)
    end

    ------------------ Mouse Invert ------------------
    -- This is a common setting in games, even if it is rare
    if AdvancedEnabled then
      this.MouseInvertFrame,
      this.MouseInvertLabel,
      this.MouseInvertEnabler = utility:AddNewRow(this, "Advanced Mouse Invert", "Selector", {"Normal", "Inverted"}, MouseInvertStart)

      this.MouseInvertEnabler.IndexChanged:connect(function(newIndex)
          local currentFirstSensitivity = GameSettings.MouseSensitivityFirstPerson
          local currentThirdSensitivity = GameSettings.MouseSensitivityThirdPerson

          if newIndex == 1 then
            if currentFirstSensitivity.y < 0.0 then
              currentFirstSensitivity = Vector2.new(currentFirstSensitivity.x, -currentFirstSensitivity.y)
              currentThirdSensitivity = Vector2.new(currentThirdSensitivity.x, -currentThirdSensitivity.y)
            end
          elseif newIndex == 2 then
            if currentFirstSensitivity.y > 0.0 then
              currentFirstSensitivity = Vector2.new(currentFirstSensitivity.x, -currentFirstSensitivity.y)
              currentThirdSensitivity = Vector2.new(currentThirdSensitivity.x, -currentThirdSensitivity.y)
            end
          end
          GameSettings.MouseSensitivityFirstPerson = currentFirstSensitivity
          GameSettings.MouseSensitivityThirdPerson = currentThirdSensitivity
        end)
    end

    ------------------ Init ------------------
    if AdvancedEnabled then
      local function setMouseModeToBasic()
        this.MouseSensitivitySlider:SetZIndex(2)
        this.MouseSensitivityLabel.ZIndex = 2
        this.MouseSensitivitySlider:SetInteractable(true)
        this.MouseSensitivitySlider:SetValue(translateEngineMouseSensitivityToGui(GameSettings.MouseSensitivity))

        this.MouseAdvancedLabel.ZIndex = 1
        this.MouseAdvancedEntry:SetInteractable(false)

        this.MouseInvertLabel.ZIndex = 1
        this.MouseInvertEnabler:SetInteractable(false)

      end
      local function setMouseModeToAdvanced()
        this.MouseSensitivitySlider:SetZIndex(1)
        this.MouseSensitivityLabel.ZIndex = 1
        this.MouseSensitivitySlider:SetInteractable(false)

        this.MouseAdvancedLabel.ZIndex = 2
        this.MouseAdvancedEntry:SetInteractable(true)
        local MouseSensitivity3d = GameSettings.MouseSensitivityFirstPerson
        this.MouseAdvancedEntry:SetValue(tostring(MouseSensitivity3d.x));

        this.MouseInvertLabel.ZIndex = 2
        this.MouseInvertEnabler:SetInteractable(true)

      end

      this.MouseModeEnabler.IndexChanged:connect(function(newIndex)
          if newIndex == 1 then
            GameSettings.UseBasicMouseSensitivity = true
            setMouseModeToBasic()
          elseif newIndex == 2 then
            GameSettings.UseBasicMouseSensitivity = false
            setMouseModeToAdvanced()
          end
        end)

      if GameSettings.UseBasicMouseSensitivity then
        local MouseAdvancedStart = tostring(GameSettings.MouseSensitivityFirstPerson.x)
        setMouseModeToBasic()
        this.MouseAdvancedEntry:SetValue(MouseAdvancedStart)
      else
        setMouseModeToAdvanced()
      end
    end

  end

  local function createOverscanOption()
      local showOverscanScreen = function()
      if RunService:IsStudio() then
        return
      end

      if not overscanScreen then
        local overscanModule = RobloxGui.Modules:FindFirstChild('OverscanScreen')
        if not overscanModule then
          overscanModule = RobloxGui.Modules.Shell.OverscanScreen
        end
        local createOverscanFunc = require(overscanModule)
        overscanScreen = createOverscanFunc(RobloxGui)
        overscanScreen:SetStyleForInGame()
      end

      local MenuModule = require(RobloxGui.Modules.Settings.SettingsHub)
      MenuModule:SetVisibility(false, true)

      local closedCon = nil
      closedCon = overscanScreen.Closed:connect(function()
          closedCon:disconnect()
          pcall(function() PlatformService.BlurIntensity = 0 end)
          ContextActionService:UnbindCoreAction("RbxStopOverscanMovement")
          MenuModule:SetVisibility(true, true)
        end)

      pcall(function() PlatformService.BlurIntensity = 10 end)

      local noOpFunc = function() end
      ContextActionService:BindCoreAction("RbxStopOverscanMovement", noOpFunc, false,
        Enum.UserInputType.Gamepad1, Enum.UserInputType.Gamepad2,
        Enum.UserInputType.Gamepad3, Enum.UserInputType.Gamepad4)

      local screenManagerModule = RobloxGui.Modules:FindFirstChild('ScreenManager')
      if not screenManagerModule then
        screenManagerModule = RobloxGui.Modules.Shell.ScreenManager
      end
      local ScreenManager = require(screenManagerModule)
      ScreenManager:OpenScreen(overscanScreen)

    end

    local adjustButton, adjustText, setButtonRowRef = utility:MakeStyledButton("AdjustButton", "Adjust", UDim2.new(0,300,1,-20), showOverscanScreen, this)
    adjustText.Font = Enum.Font.SourceSans
    adjustButton.Position = UDim2.new(1,-400,0,12)

    if RunService:IsStudio() then
      adjustButton.Selectable = value
      adjustButton.Active = value
      adjustButton.Enabled.Value = value
      adjustText.TextColor3 = Color3.fromRGB(100, 100, 100)
    end

    local row = utility:AddNewRowObject(this, "Safe Zone", adjustButton)
    setButtonRowRef(row)
  end

  local function createDeveloperConsoleOption()
    -- makes button in settings menu to open dev console
    local function makeDevConsoleOption()
      local devConsoleModule = require(RobloxGui.Modules.DeveloperConsoleModule)
      local function onOpenDevConsole()
        if devConsoleModule then
          devConsoleModule:SetVisibility(true)
        end
      end

      local devConsoleButton, devConsoleText, setButtonRowRef = utility:MakeStyledButton("DevConsoleButton", "Open", UDim2.new(0, 300, 1, -20), onOpenDevConsole, this)
      devConsoleText.Font = Enum.Font.SourceSans
      devConsoleButton.Position = UDim2.new(1, -400, 0, 12)
      local row = utility:AddNewRowObject(this, "Developer Console", devConsoleButton)
      setButtonRowRef(row)
    end

    -- Only show option if we are place/group owner
    if game.CreatorType == Enum.CreatorType.Group then
      spawn(function()
          -- spawn since GetRankInGroup is async
          local success, result = pcall(function()
              return LocalPlayer:GetRankInGroup(game.CreatorId) == 255
            end)
          if success then
            if result == true then
              makeDevConsoleOption()
            end
          else
            print("DeveloperConsoleModule: GetRankInGroup failed because", result)
          end
        end)
    elseif LocalPlayer.UserId == game.CreatorId and game.CreatorType == Enum.CreatorType.User then
      makeDevConsoleOption()
    end
  end

  createCameraModeOptions(not isTenFootInterface and
    (UserInputService.TouchEnabled or UserInputService.MouseEnabled or UserInputService.KeyboardEnabled))

  if UserInputService.MouseEnabled and not isTenFootInterface then
    createMouseOptions()
  end

  createVolumeOptions()

  if platform == Enum.Platform.Windows or platform == Enum.Platform.UWP or platform == Enum.Platform.OSX then
    createGraphicsOptions()
  end

  createPerformanceStatsOptions()

  if isTenFootInterface then
    createOverscanOption()

    -- enable dev console for xbox
    local success, result = pcall(function()
        return settings():GetFFlag("EnableDevConsoleOnXbox")
      end)
    if success and result == true then
      createDeveloperConsoleOption()
    end
  end

  allSettingsCreated = true
  if UserInputService.VREnabled then
    onVRSettingsReady()
  end

  ------ TAB CUSTOMIZATION -------
  this.TabHeader.Name = "GameSettingsTab"
  this.TabHeader.Icon.Image = isTenFootInterface and "rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab@2x.png" or "rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab.png"

  this.TabHeader.Icon.Title.Text = "Settings"

  ------ PAGE CUSTOMIZATION -------
  this.Page.ZIndex = 5

  if this.PageListLayout then
    this.PageListLayout.Padding = UDim.new(0, 0)
  end
  
  return this
end


----------- Page Instantiation --------------

PageInstance = Initialize()

return PageInstance
