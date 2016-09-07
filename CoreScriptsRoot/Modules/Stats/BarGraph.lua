--[[
		Filename: BarGraph.lua
		Written by: dbanks
		Description: A simple bar graph.
--]]

--[[ Services ]]--
local CoreGuiService = game:GetService('CoreGui')

--[[ Globals ]]--
local BarColor = Color3.new(0.1, 0.7, 0.1)

--[[ Modules ]]--
local folder = CoreGuiService:WaitForChild("RobloxGui")
folder = folder:WaitForChild("Modules")
folder = folder:WaitForChild("Stats")

local StatsUtils = require(folder:WaitForChild( 
    "StatsUtils"))

--[[ Classes ]]--
local BarGraphClass = {}
BarGraphClass.__index = BarGraphClass

function BarGraphClass.new() 
  local self = {}
  setmetatable(self, BarGraphClass)

  self._frame = Instance.new("Frame")
  self._frame.Name = "PS_BarGraph"
  self._frame.BackgroundTransparency = 1.0
  
  return self
end

function BarGraphClass:PlaceInParent(parent, size, position) 
  self._frame.Position = position
  self._frame.Size = size
  self._frame.Parent = parent
end

function BarGraphClass:Render(values, axisMax) 
  self._frame:ClearAllChildren()
  
  local numValues = table.getn(values)
  for i, value in ipairs(values) do
    self:_addBar(i, value, numValues, axisMax)
  end
end

function BarGraphClass:_addBar(i, value, numValues, axisMax) 
  local realIndex = i-1
  local bar = Instance.new("Frame")
  bar.Name = string.format("Bar_%d", realIndex)
  bar.Position = UDim2.new(realIndex/numValues, 0, (axisMax - value)/axisMax, 0)
  bar.Size = UDim2.new(1/numValues, 0, value/axisMax, 0)
  bar.Parent = self._frame
  bar.BackgroundColor3 = BarColor
  bar.BorderSizePixel = 0
end

return BarGraphClass