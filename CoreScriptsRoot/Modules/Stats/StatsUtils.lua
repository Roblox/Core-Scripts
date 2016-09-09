--[[
		Filename: StatsUtils.lua
		Written by: dbanks
		Description: Common work in the performance stats world.
--]]
--[[ Classes ]]--
local StatsUtils = {}

StatsUtils.ButtonHeight = 64

StatsUtils.NormalColor = Color3.new(0.3, 0.3, 0.1)
StatsUtils.SelectedColor = Color3.new(0.5, 0.5, 0.3)
StatsUtils.Transparency = 0.6

StatsUtils.FontColor = Color3.new(1, 1, 1)

StatsUtils.StatType_Memory =            "st_Memory"
StatsUtils.StatType_CPU =               "st_CPU"
StatsUtils.StatType_GPU =               "st_GPU"
StatsUtils.StatType_NetworkSent =       "st_NetworkSent"
StatsUtils.StatType_NetworkReceived =   "st_NetworkReceived"
StatsUtils.StatType_Physics =           "st_Physics"

StatsUtils.AllStatTypes = {
  StatsUtils.StatType_Memory,
  StatsUtils.StatType_CPU,
  StatsUtils.StatType_GPU,
  StatsUtils.StatType_NetworkSent,
  StatsUtils.StatType_NetworkReceived,
  StatsUtils.StatType_Physics,
}

StatsUtils.StatNames = {
  [StatsUtils.StatType_Memory] = "Memory",
  [StatsUtils.StatType_CPU] = "CPU",
  [StatsUtils.StatType_GPU] = "GPU",
  [StatsUtils.StatType_NetworkSent] = "Network_Sent",
  [StatsUtils.StatType_NetworkReceived] = "Network_Received",
  [StatsUtils.StatType_Physics] = "Physics",
}



StatsUtils.StatDisplayType_Memory =            "sbt_Memory"
StatsUtils.StatDisplayType_CPU =               "sbt_CPU"
StatsUtils.StatDisplayType_GPU =               "sbt_GPU"
StatsUtils.StatDisplayType_NetworkSent =       "sbt_NetworkSent"
StatsUtils.StatDisplayType_NetworkReceived =   "sbt_NetworkReceived"
StatsUtils.StatDisplayType_Physics =           "sbt_Physics"

StatsUtils.AllStatDisplayTypes = {
  StatsUtils.StatDisplayType_Memory,
  StatsUtils.StatDisplayType_CPU,
  StatsUtils.StatDisplayType_GPU,
  StatsUtils.StatDisplayType_NetworkSent,
  StatsUtils.StatDisplayType_NetworkReceived,
  StatsUtils.StatDisplayType_Physics,
}

StatsUtils.NumButtonTypes = table.getn(StatsUtils.AllStatDisplayTypes)

StatsUtils.DisplayTypeToAggregatorType = {
  [StatsUtils.StatDisplayType_Memory] = StatsUtils.StatType_Memory,
  [StatsUtils.StatDisplayType_CPU] = StatsUtils.StatType_CPU,
  [StatsUtils.StatDisplayType_GPU] = StatsUtils.StatType_GPU,
  [StatsUtils.StatDisplayType_NetworkSent] = StatsUtils.StatType_NetworkSent,
  [StatsUtils.StatDisplayType_NetworkReceived] = StatsUtils.StatType_NetworkReceived,
  [StatsUtils.StatDisplayType_Physics] = StatsUtils.StatType_Physics,
}

StatsUtils.DisplayTypeToName = {
  [StatsUtils.StatDisplayType_Memory] = "Memory",
  [StatsUtils.StatDisplayType_CPU] = "CPU",
  [StatsUtils.StatDisplayType_GPU] = "GPU",
  [StatsUtils.StatDisplayType_NetworkSent] = "Sent\n(Network)",
  [StatsUtils.StatDisplayType_NetworkReceived] = "Received\n(Network)",
  [StatsUtils.StatDisplayType_Physics] = "Physics",
}

StatsUtils.DisplayTypeToShortName = {
  [StatsUtils.StatDisplayType_Memory] = "Mem",
  [StatsUtils.StatDisplayType_CPU] = "CPU",
  [StatsUtils.StatDisplayType_GPU] = "GPU",
  [StatsUtils.StatDisplayType_NetworkSent] = "Sent",
  [StatsUtils.StatDisplayType_NetworkReceived] = "Recv",
  [StatsUtils.StatDisplayType_Physics] = "Phys",
}

function StatsUtils.StyleFrame(frame)
  frame.BackgroundColor3 = StatsUtils.NormalColor
  frame.BackgroundTransparency = StatsUtils.Transparency
end

function StatsUtils.StyleButton(button)
  button.BackgroundColor3 = StatsUtils.NormalColor
  button.BackgroundTransparency = StatsUtils.Transparency
end

function StatsUtils.StyleTextWidget(textLabel)
  textLabel.BackgroundTransparency = 1.0
  textLabel.TextColor3 = StatsUtils.FontColor
  textLabel.Font = "Arial"
end

function StatsUtils.StyleButtonSelected(frame, isSelected)
  StatsUtils.StyleButton(frame)
  if (isSelected) then 
    frame.BackgroundColor3 = StatsUtils.SelectedColor
  end
end

function StatsUtils.ConvertTypedValue(value, statsAggregatorType) 
  -- Convert raw number from stats service to the right 
  -- units.
  if statsAggregatorType == StatsUtils.StatType_Memory then 
    -- from B to MB
    return value/1000000.0
  elseif statsAggregatorType == StatsUtils.StatType_CPU then
    -- No conversion: msec -> msec.
    return value
  elseif statsAggregatorType == StatsUtils.StatType_GPU then
    -- No conversion: msec -> msec.
    return value
  elseif statsAggregatorType == StatsUtils.StatType_NetworkSent then
    -- No conversion: KB/sec -> KS/sec.
    return value
  elseif statsAggregatorType == StatsUtils.StatType_NetworkReceived then
    -- No conversion: KB/sec -> KS/sec.
    return value
  elseif statsAggregatorType == StatsUtils.StatType_Physics then
    -- No conversion: msec -> msec.
    return value
  end
end

function StatsUtils.FormatTypedValue(value, statsAggregatorType) 
  -- Convert raw number from stats service to string 
  -- in the right units with proper label.
  local convertedValue = StatsUtils.ConvertTypedValue(value, statsAggregatorType)
  
  if statsAggregatorType == StatsUtils.StatType_Memory then 
    return string.format("%.2f MB", convertedValue)
  elseif statsAggregatorType == StatsUtils.StatType_CPU then
    return string.format("%.2f msec", convertedValue)
  elseif statsAggregatorType == StatsUtils.StatType_GPU then
    return string.format("%.2f msec", convertedValue)
  elseif statsAggregatorType == StatsUtils.StatType_NetworkSent then
    return string.format("%.2f KB/s", convertedValue)
  elseif statsAggregatorType == StatsUtils.StatType_NetworkReceived then
    return string.format("%.2f KB/s", convertedValue)
  elseif statsAggregatorType == StatsUtils.StatType_Physics then
    return string.format("%.2f msec", convertedValue)
  end
end


return StatsUtils