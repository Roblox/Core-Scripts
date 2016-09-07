--[[
		Filename: StatsAnnotatedGraph.lua
		Written by: dbanks
		Description: A graph plus extra annotations like axis markings, 
      target lines, etc.
--]]

--[[ Services ]]--
local CoreGuiService = game:GetService('CoreGui')

--[[ Globals ]]--
local TextPanelXFraction = 0.5
local GraphXFraction = 1 - TextPanelXFraction

local TextPanelPosition = UDim2.new(0, 0, 0, 0)
local TextPanelSize = UDim2.new(TextPanelXFraction, 0, 1, 0)
local GraphPosition = UDim2.new(TextPanelXFraction, 0, 0, 0)
local GraphSize = UDim2.new(GraphXFraction, 0, 1, 0)

--[[ Modules ]]--
local folder = CoreGuiService:WaitForChild("RobloxGui")
folder = folder:WaitForChild("Modules")
folder = folder:WaitForChild("Stats")

local StatsUtils = require(folder:WaitForChild( 
    "StatsUtils"))
local BarChartClass = require(folder:WaitForChild( 
    "BarChart"))

--[[ Classes ]]--
local StatsAnnotatedGraph = {}
StatsAnnotatedGraph.__index = StatsAnnotatedGraph

function StatsAnnotatedGraph.new() 
  local self = {}
  setmetatable(self, StatsAnnotatedGraph)

  self._frame = Instance.new("Frame")
  self._frame.Name = "PS_AnnotatedGraph"

  StatsUtils.StyleFrame(self._frame)

  self._barChart = BarChartClass.new()
  self._

  return self
}

function StatsAnnotatedGraph:SetSizeAndPosition(size, position)
  self._frame.Size = size;
  self._frame.Position = position;
end

function StatsAnnotatedGraph:SetParent(parent)
  self._frame.Parent = parent
end
