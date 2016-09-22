
--[[
  Filename: StatsAggregatorManager.lua
  Written by: dbanks
  Description: Indexed array of stats aggregators, one for each stat.
--]]

--[[ Services ]]--
local CoreGuiService = game:GetService('CoreGui')

--[[ Modules ]]--
local StatsUtils = require(CoreGuiService.RobloxGui.Modules.Stats.StatsUtils)
local StatsAggregatorClass = require(CoreGuiService.RobloxGui.Modules.Stats.StatsAggregator)


--[[ Classes ]]--
local StatsAggregatorManagerClass = {}
StatsAggregatorManagerClass.__index = StatsAggregatorManagerClass

StatsAggregatorManagerClass.SecondsBetweenUpdate = 1.0
StatsAggregatorManagerClass.NumSamplesToKeep = 20



function StatsAggregatorManagerClass.new() 
  local self = {}
  setmetatable(self, StatsAggregatorManagerClass)
  
  self._statsAggregators = {}
  
  for i, statType in ipairs(StatsUtils.AllStatTypes) do
    local statsAggregator = StatsAggregatorClass.new(statType, 
      StatsAggregatorManagerClass.NumSamplesToKeep, 
      StatsAggregatorManagerClass.SecondsBetweenUpdate)
    self._statsAggregators[statType] = statsAggregator
  end
  
  return self
end


function StatsAggregatorManagerClass:StartListening()
  for i, statsAggregator in pairs(self._statsAggregators) do
    statsAggregator:StartListening()
  end
end

function StatsAggregatorManagerClass:GetAggregator(statsType)
  return self._statsAggregators[statsType]
end

return StatsAggregatorManagerClass