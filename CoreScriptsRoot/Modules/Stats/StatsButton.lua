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
local StatsTextPanelClass = require(RobloxGui.Modules.Stats.StatsTextPanel)
local StatsAnnotatedGraphClass = require(RobloxGui.Modules.Stats.StatsAnnotatedGraph)


--[[ Classes ]]--
local StatsButtonClass = {}
StatsButtonClass.__index = StatsButtonClass

function StatsButtonClass.new(statsDisplayType) 
  local self = {}
  setmetatable(self, StatsButtonClass)

  self._type = statsDisplayType
  self._button = Instance.new("TextButton")
  self._button.Name = "PS_Button"
  self._button.Text = ""
  
  StatsUtils.StyleButton(self._button)

  self._textPanel = StatsTextPanelClass.new(statsDisplayType, false)
  self._textPanel:PlaceInParent(self._button,
    UDim2.new(0.5, 0, 1, 0), 
    UDim2.new(0, 0, 0, 0))
  
  self._isSelected = false
  
  self:_updateColor();
  
  return self
end

function StatsButtonClass:SetToggleCallbackFunction(callbackFunction) 
    self._button.MouseButton1Click:connect(function() 
          print("Button clicked!!!")
          callbackFunction(self._type)
        end)
end

function StatsButtonClass:SetSizeAndPosition(size, position)
  self._button.Size = size;
  self._button.Position = position;
end

function StatsButtonClass:SetIsSelected(isSelected)
  print ("SetIsSelected ", self._type)
  self._isSelected = isSelected
  self:_updateColor();
end

function StatsButtonClass:_updateColor()
  StatsUtils.StyleButtonSelected(self._button, self._isSelected)  
end

function StatsButtonClass:SetGUIParent(parent)
  self._button.Parent = parent
end
  
function StatsButtonClass:SetStatsAggregator(aggregator) 
  if (self._aggregator) then
    self._aggregator:RemoveListener(self._listenerId)
    self._listenerId = nil
    self._aggregator = nil
  end
  
  self._aggregator = aggregator
  
  if (self._aggregator ~= nil) then
    self._listenerId = aggregator:AddListener(function()
        self:_updateValue()
    end)
  end
  
  self:_updateValue()
end
  
function StatsButtonClass:_updateValue()
  local value
  if self._aggregator ~= nil then 
    value = self._aggregator:GetLatestValue()
  else
    value = 0
  end
  self._textPanel:SetValue(value)
end

return StatsButtonClass