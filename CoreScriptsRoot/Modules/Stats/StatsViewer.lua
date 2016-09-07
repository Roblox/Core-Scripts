--[[
		Filename: StatsButtonViewer.lua
		Written by: dbanks
		Description: Widget that displays one or more stats in closeup view:
      text and graphics.
--]]

--[[ Services ]]--
local CoreGuiService = game:GetService('CoreGui')

--[[ Modules ]]--
local folder = CoreGuiService:WaitForChild("RobloxGui")
folder = folder:WaitForChild("Modules")
folder = folder:WaitForChild("Stats")

local StatsUtils = require(folder:WaitForChild( 
    "StatsUtils"))
local StatsAggregatorClass = require(folder:WaitForChild( 
    "StatsAggregator"))
local StatsButtonClass = require(folder:WaitForChild( 
    "StatsButton"))
local StatsTextPanelClass = require(folder:WaitForChild( 
    "StatsTextPanel"))

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
  
  self._graph = StatsAnnotatedGraphClass.new()
  self._graph.PlaceInParent(self._button, 
    GraphSize, 
    GraphPosition)
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
  local values
  if self._aggregator ~= nil then 
    value = self._aggregator:GetLatestValue()
    values = self._aggregator:GetValues()
  else
    value = 0
    values = {}
  end
  
  if self._textPanel then
    self._textPanel:SetValue(value)
  end
  if self._graph then 
    self._graph:SetValues(value)
  end  
end

return StatsViewerClass