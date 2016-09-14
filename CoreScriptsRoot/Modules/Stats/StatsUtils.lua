--[[
		Filename: StatsUtils.lua
		Written by: dbanks
		Description: Common work in the performance stats world.
--]]

--[[ Services ]]--
local CoreGuiService = game:GetService('CoreGui')


--[[ Modules ]]--
local TopbarConstants = require(CoreGuiService.RobloxGui.Modules.TopbarConstants)

--[[ Classes ]]--
local StatsUtils = {}

StatsUtils.ButtonHeight = 55

StatsUtils.ViewerTopMargin = 10
StatsUtils.ViewerHeight = 220
StatsUtils.ViewerWidth = 440

StatsUtils.NormalColor = TopbarConstants.TOPBAR_BACKGROUND_COLOR
StatsUtils.SelectedColor = Color3.new(0.4, 0.4, 0.4)
StatsUtils.Transparency = TopbarConstants.TOPBAR_TRANSLUCENT_TRANSPARENCY;

StatsUtils.FontColor = Color3.new(1, 1, 1)

StatsUtils.MiniPanelTitleFontSize = Enum.FontSize.Size18
StatsUtils.MiniPanelValueFontSize = Enum.FontSize.Size14
StatsUtils.PanelTitleFontSize = Enum.FontSize.Size24
StatsUtils.PanelValueFontSize = Enum.FontSize.Size18
StatsUtils.PanelGraphFontSize = Enum.FontSize.Size14

StatsUtils.StatType_Memory =            "st_Memory"
StatsUtils.StatType_CPU =               "st_CPU"
StatsUtils.StatType_GPU =               "st_GPU"
StatsUtils.StatType_NetworkSent =       "st_NetworkSent"
StatsUtils.StatType_NetworkReceived =   "st_NetworkReceived"
StatsUtils.StatType_Physics =           "st_Physics"

StatsUtils.TextZIndex =  5
StatsUtils.GraphZIndex = 2

StatsUtils.GraphBarColor = Color3.new(0.1, 0.7, 0.1)
StatsUtils.GraphAverageLineColor = Color3.new(1, 0, 0)
StatsUtils.GraphAverageLineBorderColor = Color3.new(1, 1, 1)
StatsUtils.GraphAverageLineInnerThickness = 2
StatsUtils.GraphAverageLineBorderThickness = 1
StatsUtils.GraphAverageLineTotalThickness = (StatsUtils.GraphAverageLineInnerThickness + 
  2 * StatsUtils.GraphAverageLineBorderThickness)
      
StatsUtils.DecorationSize = 24
StatsUtils.DecorationMargin = 10
      
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



StatsUtils.NumButtonTypes = table.getn(StatsUtils.AllStatTypes)

StatsUtils.TypeToName = {
  [StatsUtils.StatType_Memory] = "Memory",
  [StatsUtils.StatType_CPU] = "CPU",
  [StatsUtils.StatType_GPU] = "GPU",
  [StatsUtils.StatType_NetworkSent] = "Sent\n(Network)",
  [StatsUtils.StatType_NetworkReceived] = "Received\n(Network)",
  [StatsUtils.StatType_Physics] = "Physics",
}

StatsUtils.TypeToShortName = {
  [StatsUtils.StatType_Memory] = "Mem",
  [StatsUtils.StatType_CPU] = "CPU",
  [StatsUtils.StatType_GPU] = "GPU",
  [StatsUtils.StatType_NetworkSent] = "Sent",
  [StatsUtils.StatType_NetworkReceived] = "Recv",
  [StatsUtils.StatType_Physics] = "Phys",
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
  textLabel.Font = Enum.Font.SourceSansBold
end

function StatsUtils.StyleButtonSelected(frame, isSelected)
  StatsUtils.StyleButton(frame)
  if (isSelected) then 
    frame.BackgroundColor3 = StatsUtils.SelectedColor
  end
end

function StatsUtils.ConvertTypedValue(value, statType) 
  -- Convert raw number from stats service to the right 
  -- units.
  if statType == StatsUtils.StatType_Memory then 
    -- from B to MB
    return value/1000000.0
  elseif statType == StatsUtils.StatType_CPU then
    -- No conversion: msec -> msec.
    return value
  elseif statType == StatsUtils.StatType_GPU then
    -- No conversion: msec -> msec.
    return value
  elseif statType == StatsUtils.StatType_NetworkSent then
    -- No conversion: KB/sec -> KS/sec.
    return value
  elseif statType == StatsUtils.StatType_NetworkReceived then
    -- No conversion: KB/sec -> KS/sec.
    return value
  elseif statType == StatsUtils.StatType_Physics then
    -- No conversion: msec -> msec.
    return value
  end
end

function StatsUtils.FormatTypedValue(value, statType) 
  -- Convert raw number from stats service to string 
  -- in the right units with proper label.
  local convertedValue = StatsUtils.ConvertTypedValue(value, statType)
  
  if statType == StatsUtils.StatType_Memory then 
    return string.format("%.2f MB", convertedValue)
  elseif statType == StatsUtils.StatType_CPU then
    return string.format("%.2f ms", convertedValue)
  elseif statType == StatsUtils.StatType_GPU then
    return string.format("%.2f ms", convertedValue)
  elseif statType == StatsUtils.StatType_NetworkSent then
    return string.format("%.2f KB/s", convertedValue)
  elseif statType == StatsUtils.StatType_NetworkReceived then
    return string.format("%.2f KB/s", convertedValue)
  elseif statType == StatsUtils.StatType_Physics then
    return string.format("%.2f ms", convertedValue)
  end
end

function StatsUtils.StyleBarGraph(frame)  
  frame.BackgroundColor3 = StatsUtils.GraphBarColor
  frame.BorderSizePixel = 0
end

function StatsUtils.StyleAverageLine(frame)
  frame.BackgroundColor3 = StatsUtils.GraphAverageLineColor
  frame.BorderSizePixel = StatsUtils.GraphAverageLineBorderThickness
  frame.BorderColor3 = StatsUtils.GraphAverageLineBorderColor
end
  
return StatsUtils