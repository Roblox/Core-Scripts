--[[
		Filename: StatsButtonViewer.lua
		Written by: dbanks
		Description: Widget that displays one or more stats in closeup view:
      text and graphics.
--]]

--[[ Services ]]--
local CoreGuiService = game:GetService('CoreGui')

--[[ Modules ]]--
local RobloxGui = CoreGuiService:WaitForChild('RobloxGui')
local StatsAggregatorClass = require(RobloxGui.Modules.Stats.StatsAggregator)
local StatsButtonClass = require(RobloxGui.Modules.Stats.StatsButton)
local StatsUtils = require(RobloxGui.Modules.Stats.StatsUtils)
local StatsTextPanelClass = require(RobloxGui.Modules.Stats.StatsTextPanel)


--[[ Classes ]]--
local StatsViewerClass = {}
StatsViewerClass.__index = StatsViewerClass


function StatsViewerClass.new() 
  local self = {}
  setmetatable(self, StatsViewerClass)
  
  self._frame = Instance.new("Frame")
  self._frame.Name = "PS_Viewer"

  StatsUtils.StyleFrame(self._frame)
  
  self._textPanel = nil
  self._statsDisplayType = nil

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
  self._frame.Visible = visible;
end

function StatsViewerClass:SetStatsDisplayType(statsDisplayType) 
  self._statsDisplayType = statsDisplayType
  self._frame:ClearAllChildren()
  self._textPanel = nil  
  
  self._textPanel = StatsTextPanelClass.new(statsDisplayType, true)
  self._textPanel:PlaceInParent(self._frame,
    UDim2.new(0.5, 0, 1, 0), 
    UDim2.new(0, 0, 0, 0))
end

function StatsViewerClass:SetStatsAggregator(aggregator) 
  if (self._aggregator) then
    self._aggregator:RemoveListener(self._listenerId)
    self._listenerId = nil
    self._aggregator = nil
  end
  
  self._aggregator = aggregator
  
  if (self._aggregator ~= nil) then
    self._listenerId = aggregator:AddListener(function()
        self:_updateValue()
    end)
  end
  
  self:_updateValue()
end
  
function StatsViewerClass:_updateValue()
  local value
  if self._aggregator ~= nil then 
    value = self._aggregator:GetLatestValue()
  else
    value = 0
  end
  
  if self._textPanel then
    self._textPanel:SetValue(value)
  end
end

return StatsViewerClass