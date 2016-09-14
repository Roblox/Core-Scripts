--[[
		Filename: StatsTextPanel.lua
		Written by: dbanks
		Description: Panel that shows title, value, other data about a 
      particular stat.
--]]

--[[ Globals ]]--
local TitleHeightY = 55
local CurrentValueHeightY = 45
local AverageHeightY = 45

local LeftMarginPix = 10
local TopMarginPix = 10

local TitlePosition = UDim2.new(0, 
  LeftMarginPix, 
  0, 
  TopMarginPix)
local TitleSize = UDim2.new(1, 
  -LeftMarginPix * 2, 
  0, 
  TitleHeightY)

local CurrentValuePosition = UDim2.new(0,
  LeftMarginPix, 
  0, 
  TopMarginPix + TitleHeightY)
local CurrentValueSize = UDim2.new(1, 
  -LeftMarginPix * 2,
  0,
  CurrentValueHeightY)

local AverageValuePosition = UDim2.new(0,
  LeftMarginPix, 
  0, 
  TopMarginPix + TitleHeightY + CurrentValueHeightY)
local AverageValueSize = UDim2.new(1, 
  -LeftMarginPix * 2,
  0, 
  AverageHeightY)

--[[ Services ]]--
local CoreGuiService = game:GetService('CoreGui')

--[[ Modules ]]--
local StatsUtils = require(CoreGuiService.RobloxGui.Modules.Stats.StatsUtils)
local StatsAggregatorClass = require(CoreGuiService.RobloxGui.Modules.Stats.StatsAggregator)
local DecoratedValueLabelClass = require(CoreGuiService.RobloxGui.Modules.Stats.DecoratedValueLabel)

--[[ Classes ]]--
local StatsTextPanelClass = {}
StatsTextPanelClass.__index = StatsTextPanelClass

function StatsTextPanelClass.new(statType) 
  local self = {}
  setmetatable(self, StatsTextPanelClass)

  self._statType = statType
  
  self._frame = Instance.new("Frame")
  self._frame.BackgroundTransparency = 1.0
  self._frame.ZIndex = StatsUtils.TextPanelZIndex
  
  self._titleLabel = Instance.new("TextLabel")
  self._minimizedCurrentValueLabel = Instance.new("TextLabel")

  StatsUtils.StyleTextWidget(self._titleLabel)
  StatsUtils.StyleTextWidget(self._minimizedCurrentValueLabel)
  
  self._titleLabel.FontSize = StatsUtils.PanelTitleFontSize
  self._titleLabel.Text = self:_getTitle()
  
  self._titleLabel.Parent = self._frame
  self._titleLabel.Size = TitleSize
  self._titleLabel.Position = TitlePosition
  self._titleLabel.TextXAlignment = Enum.TextXAlignment.Left
  self._titleLabel.TextYAlignment = Enum.TextYAlignment.Top
  
  self:_addCurrentValueWidget()
  self:_addAverageValueWidget()
  
  return self
end

function StatsTextPanelClass:_addCurrentValueWidget()
  self._currentValueWidget = DecoratedValueLabelClass.new(self._statType, 
    "Current")
    
  self._currentValueWidget:PlaceInParent(self._frame, 
    CurrentValueSize, 
    CurrentValuePosition)

  local currentValueDecorationFrame = self._currentValueWidget:GetDecorationFrame()    
  local currentValueDecoration = Instance.new("Frame")
  currentValueDecoration.Position = UDim2.new(0.3333, 0, 0, 0)
  currentValueDecoration.Size = UDim2.new(0.33, 0, 1, 0)  
  currentValueDecoration.Parent = currentValueDecorationFrame
  
  StatsUtils.StyleBarGraph(currentValueDecoration)
end

function StatsTextPanelClass:_addAverageValueWidget()
  self._averageValueWidget = DecoratedValueLabelClass.new(self._statType, 
    "Average")
    
  self._averageValueWidget:PlaceInParent(self._frame, 
    AverageValueSize, 
    AverageValuePosition)

  local averageDecorationFrame = self._averageValueWidget:GetDecorationFrame()
  local averageValueDecoration = Instance.new("Frame")
  averageValueDecoration.Position = UDim2.new(0, 0, 0.5, -StatsUtils.GraphAverageLineTotalThickness/2)
  averageValueDecoration.Size = UDim2.new(1, 0, 0, StatsUtils.GraphAverageLineInnerThickness)  
  averageValueDecoration.Parent = averageDecorationFrame
  
  StatsUtils.StyleAverageLine(averageValueDecoration)
end

function StatsTextPanelClass:_getTitle()
  return StatsUtils.TypeToName[self._statType]
end

function StatsTextPanelClass:PlaceInParent(parent, size, position) 
  self._frame.Position = position
  self._frame.Size = size
  self._frame.Parent = parent  
end


function StatsTextPanelClass:SetStatsAggregator(aggregator)
  if (self._aggregator) then
    self._aggregator:RemoveListener(self._listenerId)
    self._listenerId = nil
    self._aggregator = nil
  end
  
  self._aggregator = aggregator
  
  if (self._aggregator ~= nil) then
    self._listenerId = aggregator:AddListener(function()
        self:_updateFromAggregator()
    end)
  end
  
  self:_updateFromAggregator()
end

function StatsTextPanelClass:_updateFromAggregator()
  local value
  local average
  if self._aggregator ~= nil then 
    value = self._aggregator:GetLatestValue()
    average = self._aggregator:GetAverage()
  else
    value = 0
    average = 0
  end
  
  self._currentValueWidget:SetValue(value)
  self._averageValueWidget:SetValue(average)
end

function StatsTextPanelClass:SetZIndex(zIndex)
  -- Pass through to all children.
  self._frame.ZIndex = zIndex
  self._titleLabel.ZIndex = zIndex
  self._currentValueWidget:SetZIndex(zIndex)
  self._averageValueWidget:SetZIndex(zIndex)
end

return StatsTextPanelClass