
--[[
		Filename: PerformanceStatsManagerScript.lua
		Written by: dbanks
		Description: Handles performance stats gui.
--]]

--[[ Services ]]--
local PlayersService = game:GetService("Players")
local Settings = UserSettings()
local GameSettings = Settings.GameSettings


--[[ Fast Flags ]]--
local getShowPerformanceStatsInGuiSuccess, showPerformanceStatsInGuiValue = 
	pcall(function() return settings():GetFFlag("ShowPerformanceStatsInGui") end)
local showPerformanceStatsInGui = getShowPerformanceStatsInGuiSuccess and showPerformanceStatsInGuiValue


--[[ Script Variables ]]--
local screenGui = Instance.new("ScreenGui")
local masterFrame = Instance.new("Frame")
local localPlayer = PlayersService.LocalPlayer


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
	masterFrame.Position = UDim2.new(0, 0, 0, 0)
	masterFrame.Size = UDim2.new(1, 0, 1, 0)
	masterFrame.BackgroundColor3 = Color3.new(0, 0.5, 0.5)
	masterFrame.BackgroundTransparency = 0.8
	masterFrame.Parent = screenGui
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

-- Watch for changes in local player.
PlayersService.PlayerAdded:connect(UpdateLocalPlayer)
PlayersService.PlayerRemoving:connect(UpdateLocalPlayer)

-- Watch for changes in performance stats visibility.
GameSettings.PerformanceStatsVisibleChanged:connect(UpdatePerformanceStatsVisibility)

-- Make sure stats are visible or not, as specified by current setting.
UpdateLocalPlayer()
UpdatePerformanceStatsVisibility()

