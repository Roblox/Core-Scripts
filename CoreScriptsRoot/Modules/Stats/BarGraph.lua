--[[
		Filename: BarGraph.lua
		Written by: dbanks
		Description: A simple bar graph.
--]]

--[[ Services ]]--
local CoreGuiService = game:GetService('CoreGui')

--[[ Globals ]]--
local BarZIndex = 1
local LineZIndex = 2


--[[ Modules ]]--
local StatsUtils = require(CoreGuiService.RobloxGui.Modules.Stats.StatsUtils)

--[[ Classes ]]--
local BarGraphClass = {}
BarGraphClass.__index = BarGraphClass

function BarGraphClass.new(showAverage) 
  local self = {}
  setmetatable(self, BarGraphClass)

  self._frame = Instance.new("Frame")
  self._frame.Name = "PS_BarGraph"
  self._frame.BackgroundTransparency = 1.0
  
  self._showAverage = showAverage
  
  
  self._values = {}
  self._average = 0
  
  return self
end

function BarGraphClass:SetZIndex(zIndex)
  self._frame.ZIndex = zIndex
end

function BarGraphClass:PlaceInParent(parent, size, position) 
  self._frame.Position = position
  self._frame.Size = size
  self._frame.Parent = parent
end

function BarGraphClass:SetAxisMax(axisMax) 
  self._axisMax = axisMax
end

function BarGraphClass:SetValues(values) 
  self._values = values
end

function BarGraphClass:SetAverage(average) 
  self._average = average
end

function BarGraphClass:Render()  
  self._frame:ClearAllChildren()
    
  local numValues = table.getn(self._values)
  for i, value in ipairs(self._values) do
    self:_addBar(i, value, numValues)
  end  
  
  if self._showAverage then
    self:_addGraphAverage()
  end
end

function BarGraphClass:_addGraphAverage() 
  local line = Instance.new("Frame")
  line.Name = "AverageLine"
  line.Position = UDim2.new(0, 0, (self._axisMax - self._average)/self._axisMax,
    -StatsUtils.GraphAverageLineTotalThickness/2)
  line.Size = UDim2.new(1, 0, 0, StatsUtils.GraphAverageLineInnerThickness)
  
  line.Parent = self._frame
  line.ZIndex = self._frame.ZIndex + 1
  
  StatsUtils.StyleAverageLine(line)

end

function BarGraphClass:_addBar(i, value, numValues) 
  local realIndex = i-1
  local bar = Instance.new("Frame")
  bar.Name = string.format("Bar_%d", realIndex)
  bar.Position = UDim2.new(realIndex/numValues, 0, (self._axisMax - value)/self._axisMax, 0)
  bar.Size = UDim2.new(1/numValues, 0, value/self._axisMax, 0)
  bar.Parent = self._frame  
  bar.ZIndex = self._frame.ZIndex
  StatsUtils.StyleBarGraph(bar)
end

return BarGraphClass