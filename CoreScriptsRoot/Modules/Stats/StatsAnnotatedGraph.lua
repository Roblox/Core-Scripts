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
local StatsUtils = require(CoreGuiService.RobloxGui.Modules.Stats.StatsUtils)

--[[ Classes ]]--
local StatsAnnotatedGraphClass = {}
StatsAnnotatedGraphClass.__index = StatsAnnotatedGraphClass

function StatsAnnotatedGraphClass.new() 
  local self = {}
  setmetatable(self, StatsAnnotatedGraphClass)

  self._frame = Instance.new("Frame")
  self._frame.Name = "PS_AnnotatedGraph"

  StatsUtils.StyleFrame(self._frame)

  return self
end

function StatsAnnotatedGraphClass:PlaceInParent(parent, size, position) 
  self._frame.Position = position
  self._frame.Size = size
  self._frame.Parent = parent
end

function StatsAnnotatedGraphClass:SetValues(values)
  -- FIXME(dbanks)
  -- Fill this in.
end

return StatsAnnotatedGraphClass
