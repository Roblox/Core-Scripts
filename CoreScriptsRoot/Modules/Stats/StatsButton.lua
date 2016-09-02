--[[
		Filename: StatsButton.lua
		Written by: dbanks
		Description: Button that displays latest deets of one or two 
    particular stats.
--]]

--[[ Services ]]--
local CoreGuiService = game:GetService('CoreGui')

--[[ Modules ]]--
local RobloxGui = CoreGuiService:WaitForChild('RobloxGui')
local StatsAggregatorClass = require(RobloxGui.Modules.Stats.StatsAggregator)
local StatsUtils = require(RobloxGui.Modules.Stats.StatsUtils)


--[[ Classes ]]--
local StatsButtonClass = {}
StatsButtonClass.__index = StatsButtonClass

StatsButtonClass.StatButtonType_Memory =            "sbt_Memory"
StatsButtonClass.StatButtonType_CPU =               "sbt_CPU"
StatsButtonClass.StatButtonType_GPU =               "sbt_GPU"
StatsButtonClass.StatButtonType_Network =           "sbt_Network"
StatsButtonClass.StatButtonType_Physics =           "sbt_Physics"

StatsButtonClass.AllStatButtonTypes = {
  StatsButtonClass.StatButtonType_Memory,
  StatsButtonClass.StatButtonType_CPU,
  StatsButtonClass.StatButtonType_GPU,
  StatsButtonClass.StatButtonType_Network,
  StatsButtonClass.StatButtonType_Physics,
}

StatsButtonClass.NumButtonTypes = table.getn(StatsButtonClass.AllStatButtonTypes)

StatsButtonClass.ButtonTypeToStatsTypes = {
  [StatsButtonClass.StatButtonType_Memory] = {StatsAggregatorClass.StatType_Memory},
  [StatsButtonClass.StatButtonType_CPU] = {StatsAggregatorClass.StatType_CPU},
  [StatsButtonClass.StatButtonType_GPU] = {StatsAggregatorClass.StatButtonType_GPU},
  [StatsButtonClass.StatButtonType_Network] = {StatsAggregatorClass.StatType_NetworkSent, 
    StatsAggregatorClass.StatType_NetworkReceived},
  [StatsButtonClass.StatButtonType_Physics] = {StatsAggregatorClass.StatType_Physics},
}

StatsButtonClass.ButtonTypeToName = {
  [StatsButtonClass.StatButtonType_Memory] = "Memory",
  [StatsButtonClass.StatButtonType_CPU] = "CPU",
  [StatsButtonClass.StatButtonType_GPU] = "GPU",
  [StatsButtonClass.StatButtonType_Network] = "Network",
  [StatsButtonClass.StatButtonType_Physics] = "Physics",
}

function StatsButtonClass.new(statsButtonType) 
  local self = {}
  setmetatable(self, StatsButtonClass)

  self._type = statsButtonType
  self._button = Instance.new("TextButton")
  self._button.Name = "PS_Button"
  self._button.Text = ""
  
  StatsUtils.StyleButton(self._button)

  self._label = Instance.new("TextLabel")
  self._label.Position = UDim2.new(0, 0, 0, 0)
  self._label.Size = UDim2.new(1, 0, 1, 0)
  self._label.Parent = self._button
  StatsUtils.StyleTextWidget(self._label)
  
  self._label.Text = StatsButtonClass.ButtonTypeToName[statsButtonType]
  
  
  self._isSelected = false
  
  self:_updateColor();
  
  return self
end

function StatsButtonClass:SetToggleCallbackFunction(callbackFunction) 
    self._button.MouseButton1Down:connect(function() 
          callbackFunction(self._type)
        end)
end

function StatsButtonClass:SetSizeAndPosition(size, position)
  self._button.Size = size;
  self._button.Position = position;
end

function StatsButtonClass:SetIsSelected(isSelected)
  print (self._type, " isSelected: ", isSelected)
  self._isSelected = isSelected
  self:_updateColor();
end

function StatsButtonClass:_updateColor()
  StatsUtils.StyleButtonSelected(self._button, self._isSelected)  
end

function StatsButtonClass:SetGUIParent(parent)
  self._button.Parent = parent
end
  
return StatsButtonClass