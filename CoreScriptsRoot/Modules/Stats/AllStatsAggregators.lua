
--[[
		Filename: AllStatsAggregators.lua
		Written by: dbanks
		Description: Indexed array of stats aggregators, one for each stat.
--]]

--[[ Services ]]--
local CoreGuiService = game:GetService('CoreGui')

--[[ Modules ]]--
local RobloxGui = CoreGuiService:WaitForChild('RobloxGui')
local StatsUtils = require(RobloxGui.Modules.Stats.StatsUtils)
local StatsAggregatorClass = require(RobloxGui.Modules.Stats.StatsAggregator)

--[[ Classes ]]--
local AllStatsAggregatorsClass = {}
AllStatsAggregatorsClass.__index = AllStatsAggregatorsClass

AllStatsAggregatorsClass.SecondsBetweenUpdate = 1.0
AllStatsAggregatorsClass.NumSamplesToKeep = 20



function AllStatsAggregatorsClass.new() 
  local self = {}
  setmetatable(self, AllStatsAggregatorsClass)
  
  self._statsAggregators = {}
  
  for i, statType in ipairs(StatsUtils.AllStatTypes) do
    local statsAggregator = StatsAggregatorClass.new(statType, 
      AllStatsAggregatorsClass.NumSamplesToKeep, 
      AllStatsAggregatorsClass.SecondsBetweenUpdate)
    self._statsAggregators[statType] = statsAggregator
  end
  
  return self
end


function AllStatsAggregatorsClass:StartListening()
  for i, statsAggregator in pairs(self._statsAggregators) do
    statsAggregator:StartListening()
  end
end

function AllStatsAggregatorsClass:GetAggregator(statsType)
  return self._statsAggregators[statsType]
end

return AllStatsAggregatorsClass