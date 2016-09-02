--[[
		Filename: StatsAggregator.lua
		Written by: dbanks
		Description: Gather and store stats on regular heartbeat.
--]]

--[[ Classes ]]--
local StatsAggregatorClass = {}
StatsAggregatorClass.__index = StatsAggregatorClass

StatsAggregatorClass.StatType_Memory =            "st_Memory"
StatsAggregatorClass.StatType_CPU =               "st_CPU"
StatsAggregatorClass.StatType_GPU =               "st_GPU"
StatsAggregatorClass.StatType_NetworkSent =       "st_NetworkSent"
StatsAggregatorClass.StatType_NetworkReceived =   "st_NetworkReceived"
StatsAggregatorClass.StatType_Physics =           "st_Physics"

StatsAggregatorClass.AllStatTypes = {
  StatsAggregatorClass.StatType_Memory,
  StatsAggregatorClass.StatType_CPU,
  StatsAggregatorClass.StatType_GPU,
  StatsAggregatorClass.StatType_NetworkSent,
  StatsAggregatorClass.StatType_NetworkReceived,
  StatsAggregatorClass.StatType_Physics,
}

StatsAggregatorClass.StatNames = {
  [StatsAggregatorClass.StatType_Memory] = "Memory",
  [StatsAggregatorClass.StatType_CPU] = "CPU",
  [StatsAggregatorClass.StatType_GPU] = "GPU",
  [StatsAggregatorClass.StatType_NetworkSent] = "Network_Sent",
  [StatsAggregatorClass.StatType_NetworkReceived] = "Network_Received",
  [StatsAggregatorClass.StatType_Physics] = "Physics",
}


function StatsAggregatorClass.new(statType, numSamples, pauseBetweenSamples) 
  local self = {}
  setmetatable(self, StatsAggregatorClass)
  
  self._statType = statType
  self._numSamples = numSamples
  self._pauseBetweenSamples = pauseBetweenSamples
  
  self._statName = self.StatNames[self._statType]
  -- init our circular buffer.
  self._samples = {}
  for i = 0, numSamples-1, 1 do 
    self._samples[i] = 0
  end
  self._oldestIndex = 0
  
  return self
end

function StatsAggregatorClass:StartListening()
  -- On a regular heartbeat, wake up and read the latest
  -- value into circular buffer.
  spawn(function()
        while(1) do          
          local statValue = self:_getStatValue()
          self:_storeStatValue(statValue)
          wait(self._pauseBetweenSamples)
        end
      end)
end

function StatsAggregatorClass:GetValues()
  -- Get the past N values, from oldest to newest.
  local retval = {}
  for i = 0, self._numSamples-1, 1 do
    actualIndex = (self._oldestIndex + i) % self._numSamples
    retval[i+1] = self._samples[actualIndex]
  end
  return retval
end

function StatsAggregatorClass:GetAverage()
  -- Get average of past N values.
  local retval = 0.0
  for i = 0, self._numSamples-1, 1 do
    retval = retval + self._samples[i]
  end
  return retval / self._numSamples
end

function StatsAggregatorClass:GetLatestValue()
  -- Get latest value.
  local index = (self._oldestIndex + self._numSamples -1) % self._numSamples
  return self._samples[index]
end

function StatsAggregatorClass:_storeStatValue(value)
  -- Store this as the latest value in our circular buffer.
  self._samples[self._oldestIndex] = value
  self._oldestIndex = (self._oldestIndex + 1) % self._numSamples
end

function StatsAggregatorClass:_getStatValue()
  -- Look up and return the statistic we care about.
  local statsService = game:GetService("Stats")
  if statsService == nil then
    return 0
  end
  
  local performanceStats = statsService:FindFirstChild("PerformanceStats")
  if performanceStats == nil then
    return 0
  end
  
  local itemStats = performanceStats:FindFirstChild(self._statName)
  if itemStats == nil then
    return 0
  end
  
  return itemStats:GetValue()
end


return StatsAggregatorClass
