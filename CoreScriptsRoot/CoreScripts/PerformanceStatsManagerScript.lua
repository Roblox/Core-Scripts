
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

--[[ Convenience function]]--
function WaitForRequire(pathPieces, parent)
    print("pathPieces = ", pathPieces)
  if parent == nil then
    parent = CoreGuiService
  end
  
  if (table.getn(pathPieces) == 0) then 
    print("parent = ", parent)
    return require(parent)
  else 
    local first = table.remove(pathPieces, 1)
    print("first = ", first)
    local newParent = parent:WaitForChild(first)
    return WaitForRequire(pathPieces, newParent)
  end
  
end

--[[ Modules ]]--
local AllStatsAggregatorsClass = WaitForRequire({"RobloxGui",
    "Modules", 
    "Stats", 
    "AllStatsAggregators"})
local StatsButtonClass = WaitForRequire({"RobloxGui",
    "Modules", 
    "Stats", 
    "StatsButton"})
local StatsViewerClass = WaitForRequire({"RobloxGui",
    "Modules", 
    "Stats", 
    "StatsViewer"})
local StatsUtils = WaitForRequire({"RobloxGui",
    "Modules", 
    "Stats", 
    "StatsUtils"})

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
local currentDisplayType = nil

for i, displayType in ipairs(StatsUtils.AllStatDisplayTypes) do
  local button = StatsButtonClass.new(displayType)
  statsButtonsByType[displayType] = button
end

--[[ Functions ]]--

-- Set localPlayer to value of Players.localPlayer
-- Update our screenGui parent accordingly.
function UpdateLocalPlayer()
  localPlayer = PlayersService.LocalPlayer
  if localPlayer then
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
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
  for i, displayType in ipairs(StatsUtils.AllStatDisplayTypes) do
    AddButton(displayType, i)
  end
end

function OnButtonToggled(toggledDisplayType) 
  local toggledButton = statsButtonsByType[toggledDisplayType]
  local selectedState = toggledButton._isSelected
  selectedState = not selectedState
  
  print("OnButtonToggled type=", toggledDisplayType, "  selected=", selectedState)
  
  if (selectedState) then 
    currentDisplayType = toggledDisplayType
  else
    currentDisplayType = nil
  end
  
  UpdateButtonSelectedStates()
  UpdateViewerVisibility()
end

function UpdateButtonSelectedStates()
  print("UpdateButtonSelectedStates ", currentDisplayType)
  for i, buttonType in ipairs(StatsUtils.AllStatDisplayTypes) do
      local button = statsButtonsByType[buttonType]
      button:SetIsSelected(buttonType == currentDisplayType)
  end  
end

function UpdateViewerVisibility()
  -- If someone is on, show the Viewer.
  -- FIXME(dbanks)
  -- Configure with details of the dude currently selected.
  print("UpdateViewerVisibility")
  print("currentDisplayType = ", currentDisplayType)
  
  if (currentDisplayType == nil) then 
    statsViewer:SetVisible(false)
    statsViewer:SetStatsAggregator(nil)
  else
    statsViewer:SetStatsDisplayType(currentDisplayType)
    local aggregatorType = StatsUtils.DisplayTypeToAggregatorType[currentDisplayType]
    statsViewer:SetStatsAggregator(allStatsAggregators:GetAggregator(aggregatorType))
    
    statsViewer:SetVisible(true)
  end
end

function AddButton(displayType, index) 
  -- Configure size and position of button.
  -- Configure callback behavior to toggle
  --    button on or off and show/hide viewer.
  -- Parent button in main screen.
  local button = statsButtonsByType[displayType]
  
  button:SetGUIParent(masterFrame)
  local aggregatorType = StatsUtils.DisplayTypeToAggregatorType[displayType]
  button:SetStatsAggregator(
    allStatsAggregators:GetAggregator(aggregatorType))
  
  local fraction = 1.0/StatsUtils.NumButtonTypes
  local size = UDim2.new(fraction, 0, 0.1666, 0)
  local position = UDim2.new(fraction * (index - 1), 0, 0, 0)
  button:SetSizeAndPosition(size, position)
  
  button:SetToggleCallbackFunction(OnButtonToggled)
end

function ConfigureStatViewerInMasterFrame()
  -- Set up the widget that shows currently selected button.
  statsViewer:SetGUIParent(masterFrame)
  
  local size = UDim2.new(0.5, 0, 0.5, 0)
  local position = UDim2.new(0.5, 0, 0.25, 0)
  statsViewer:SetSizeAndPosition(size, position)
end

function UpdatePerformanceStatsVisibility() 
  masterFrame.Visible = GameSettings.PerformanceStatsVisible
end


--[[ Top Level Code ]]--
-- If flag is not enabled, bounce.
if not showPerformanceStatsInGui then 
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
GameSettings.PerformanceStatsVisibleChanged:connect(
  UpdatePerformanceStatsVisibility)

-- Start listening for updates in stats.
print ("allStatsAggregators: ", allStatsAggregators)
allStatsAggregators:StartListening()

-- Make sure we're showing buttons and viewer based on current selection.
UpdateButtonSelectedStates()
UpdateViewerVisibility()

-- Make sure stats are visible or not, as specified by current setting.
UpdateLocalPlayer()
UpdatePerformanceStatsVisibility()

