--[[
		Filename: StatsButtonViewer.lua
		Written by: dbanks
		Description: Widget that displays one or more stats in closeup view. 
--]]

--[[ Services ]]--
local CoreGuiService = game:GetService('CoreGui')

--[[ Modules ]]--
local RobloxGui = CoreGuiService:WaitForChild('RobloxGui')
local StatsAggregatorClass = require(RobloxGui.Modules.Stats.StatsAggregator)
local StatsButtonClass = require(RobloxGui.Modules.Stats.StatsButton)
local StatsUtils = require(RobloxGui.Modules.Stats.StatsUtils)

-- [[ Variables ]]
local normalColor = Color3.new()
local selectedColor = Color3.new(0.3, 0.3, 0.3)


--[[ Classes ]]--
local StatsViewerClass = {}
StatsViewerClass.__index = StatsViewerClass



function StatsViewerClass.new() 
  local self = {}
  setmetatable(self, StatsViewerClass)
  
  self._frame = Instance.new("Frame")
  self._frame.Name = "PS_Viewer"

  StatsUtils.StyleFrame(self._frame)
  
  return self
end

function StatsViewerClass:SetSizeAndPosition(size, position)
  self._frame.Size = size;
  self._frame.Position = position;
end

function StatsViewerClass:SetGUIParent(parent)
  self._frame.Parent = parent
end
  
function StatsViewerClass:SetVisible(visible)
  print ("Viewer is visble: ", visible)
  self._frame.Visible = visible;
end

  
return StatsViewerClass