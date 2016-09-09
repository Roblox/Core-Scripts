--[[
		Filename: StatsButtonViewer.lua
		Written by: dbanks
		Description: Widget that displays one or more stats in closeup view:
      text and graphics.
--]]

--[[ Services ]]--
local CoreGuiService = game:GetService('CoreGui')

--[[ Modules ]]--
local StatsUtils = require(CoreGuiService.RobloxGui.Modules.Stats.StatsUtils)
local StatsTextPanelClass = require(CoreGuiService.RobloxGui.Modules.Stats.StatsTextPanel)
local StatsAnnotatedGraphClass = require(CoreGuiService.RobloxGui.Modules.Stats.StatsAnnotatedGraph)

--[[ Globals ]]--
local TextPanelXFraction = 0.4
local GraphXFraction = 1 - TextPanelXFraction

local TextPanelPosition = UDim2.new(0, 0, 0, 0)
local TextPanelSize = UDim2.new(TextPanelXFraction, 0, 1, 0)
local GraphPosition = UDim2.new(TextPanelXFraction, 0, 0, 0)
local GraphSize = UDim2.new(GraphXFraction, 0, 1, 0)

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
  self._graph = nil

  return self
end

function StatsViewerClass:SetSizeAndPosition(size, position)
  self._frame.Size = size;
  self._frame.Position = position;
end

function StatsViewerClass:SetParent(parent)
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
    TextPanelSize, 
    TextPanelPosition)
  
  self._graph = StatsAnnotatedGraphClass.new(statsDisplayType, true)
  self._graph:PlaceInParent(self._frame, 
    GraphSize, 
    GraphPosition)
  
  self:_applyStatsAggregator();
end

function StatsViewerClass:_applyStatsAggregator()
  if (self._aggregator == nil) then 
    return
  end
  
  if (self._textPanel) then 
    self._textPanel:SetStatsAggregator(self._aggregator)
  end
  if (self._graph) then 
      self._graph:SetStatsAggregator(self._aggregator)
  end
end
  

function StatsViewerClass:SetStatsAggregator(aggregator) 
  self._aggregator = aggregator
  self:_applyStatsAggregator();
 end

return StatsViewerClass