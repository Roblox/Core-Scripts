
--[[
		Filename: PerformanceStatsManagerScript.lua
		Written by: dbanks
		Description: Handles performance stats gui.
--]]

--[[ Services ]]--
local PlayersService = game:GetService("Players")
local Settings = UserSettings()
local GameSettings = Settings.GameSettings
local CoreGuiService = game:GetService('CoreGui')

--[[ Modules ]]--
local RobloxGui = CoreGuiService:WaitForChild('RobloxGui')
local AllStatsAggregatorsClass = require(RobloxGui.Modules.Stats.AllStatsAggregators)
local StatsButtonClass = require(RobloxGui.Modules.Stats.StatsButton)
local StatsViewerClass = require(RobloxGui.Modules.Stats.StatsViewer)

--[[ Fast Flags ]]--
local getShowPerformanceStatsInGuiSuccess, showPerformanceStatsInGuiValue = 
	pcall(function() return settings():GetFFlag("ShowPerformanceStatsInGui") end)
local showPerformanceStatsInGui = getShowPerformanceStatsInGuiSuccess and showPerformanceStatsInGuiValue


--[[ Script Variables ]]--
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PS_Gui"
local masterFrame = Instance.new("Frame")
masterFrame.Name = "PS_MasterFrame"
local localPlayer = PlayersService.LocalPlayer

local allStatsAggregators = AllStatsAggregatorsClass.new()
local statsViewer = StatsViewerClass.new()
local statsButtonsByType ={}
local currentlySelectedStatButtonType = nil

for i, buttonType in ipairs(StatsButtonClass.AllStatButtonTypes) do
  local button = StatsButtonClass.new(buttonType)
  statsButtonsByType[buttonType] = button
end

--[[ Functions ]]--

-- Set localPlayer to value of Players.localPlayer
-- Update our screenGui parent accordingly.
function UpdateLocalPlayer()
  localPlayer = PlayersService.LocalPlayer
  if localPlayer then
    screenGui.Parent = localPlayer.PlayerGui
  else
    screenGui.Parent = nil
  end
end

function ConfigureMasterFrame()
  -- Set up the main frame that contains the whole PS GUI.  
	masterFrame.Position = UDim2.new(0, 0, 0, 0)
	masterFrame.Size = UDim2.new(1, 0, 1, 0)
  masterFrame.Draggable = false
  masterFrame.Selectable = false
  masterFrame.BackgroundTransparency = 0.8
  -- FIXME(dbanks)
  -- Make it on top of all other GUIS.
  -- FIXME(dbanks)
  -- I can click through frame to elements below, but I should still 
  -- be able to click on active elements in the frame.  Does this
  -- work as expected?
  masterFrame.Active = false  
  
  -- FIXME(dbanks)
  -- Debug, can see the whole frame.
	-- masterFrame.BackgroundColor3 = Color3.new(0, 0.5, 0.5)
	-- masterFrame.BackgroundTransparency = 0.8
  
	masterFrame.Parent = screenGui
end

function ConfigureStatButtonsInMasterFrame()
  -- Set up the row of buttons across the top and handler for button press.
  for i, buttonType in ipairs(StatsButtonClass.AllStatButtonTypes) do
    AddButton(buttonType, i)
  end
end

function OnButtonToggled(toggledButtonType) 
  local toggledButton = statsButtonsByType[toggledButtonType]
  local selectedState = toggledButton._isSelected
  selectedState = not selectedState
  
  if (selectedState) then 
    currentlySelectedStatButtonType = toggledButtonType
  else
    currentlySelectedStatButtonType = nil
  end
  
  UpdateButtonSelectedStates()
  UpdateViewerVisibility()
end

function UpdateButtonSelectedStates()
  for i, buttonType in ipairs(StatsButtonClass.AllStatButtonTypes) do
      local button = statsButtonsByType[buttonType]
      button:SetIsSelected(buttonType == currentlySelectedStatButtonType)
  end  
end

function UpdateViewerVisibility()
  -- If someone is on, show the Viewer.
  -- FIXME(dbanks)
  -- Configure with details of the dude currently selected.
  statsViewer:SetVisible(currentlySelectedStatButtonType ~= nil)
end

function AddButton(buttonType, index) 
  -- Configure size and position of button.
  -- Configure callback behavior to toggle
  --    button on or off and show/hide viewer.
  -- Parent button in main screen.
  local button = statsButtonsByType[buttonType]
  
  button:SetGUIParent(masterFrame)
  
  local fraction = 1.0/StatsButtonClass.NumButtonTypes
  print ("fraction = ", fraction)
  local size = UDim2.new(fraction, 0, 0.1666, 0)
  local position = UDim2.new(fraction * (index - 1), 0, 0, 0)
  print ("size = ", size)
  print ("position = ", position)
  button:SetSizeAndPosition(size, position)
  
  button:SetToggleCallbackFunction(OnButtonToggled)
end

function ConfigureStatViewerInMasterFrame()
  -- Set up the widget that shows currently selected button.
  statsViewer:SetGUIParent(masterFrame)
  
  local size = UDim2.new(0.5, 0, 0.5, 0)
  local position = UDim2.new(0.5, 0, 0.25, 0)
  print ("size = ", size)
  print ("position = ", position)
  statsViewer:SetSizeAndPosition(size, position)
end

function UpdatePerformanceStatsVisibility() 
  masterFrame.Visible = GameSettings.PerformanceStatsVisible
end


--[[ Top Level Code ]]--
-- If flag is not enabled, bounce.
if not showPerformanceStatsInGui then 
    print("ShowPerformanceStatsInGui flag not found or enabled.")
	return
end
 
 
-- Set up our GUI.
ConfigureMasterFrame()
ConfigureStatButtonsInMasterFrame()
ConfigureStatViewerInMasterFrame()

-- Watch for changes in local player.
PlayersService.PlayerAdded:connect(UpdateLocalPlayer)
PlayersService.PlayerRemoving:connect(UpdateLocalPlayer)

-- Watch for changes in performance stats visibility.
GameSettings.PerformanceStatsVisibleChanged:connect(UpdatePerformanceStatsVisibility)

-- Start listening for updates in stats.
print ("allStatsAggregators: ", allStatsAggregators)
allStatsAggregators:StartListening()

-- Make sure we're showing buttons and viewer based on current selection.
UpdateButtonSelectedStates()
UpdateViewerVisibility()

-- Make sure stats are visible or not, as specified by current setting.
UpdateLocalPlayer()
UpdatePerformanceStatsVisibility()

