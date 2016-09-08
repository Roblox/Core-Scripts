--[[
		Filename: StatsTextPanel.lua
		Written by: dbanks
		Description: Panel that shows title, value, other data about a 
      particular stat.
--]]

--[[ Globals ]]--
local TitleHeightYFraction = 0.4
local ValueHeightYFraction = 0.3
local TitleTopYFraction = (1 - TitleHeightYFraction - 
  ValueHeightYFraction)/2
local LeftMarginPix = 10

local TitlePosition = UDim2.new(0, 
  LeftMarginPix, 
  TitleTopYFraction, 
  0)
local TitleSize = UDim2.new(1, 
  -LeftMarginPix * 2, 
  TitleHeightYFraction, 
  0)
local ValuePosition = UDim2.new(0,
  LeftMarginPix, 
  TitleTopYFraction + TitleHeightYFraction, 
  0)
local ValueSize = UDim2.new(1, 
  -LeftMarginPix * 2,
  ValueHeightYFraction, 
  0)

--[[ Services ]]--
local CoreGuiService = game:GetService('CoreGui')

--[[ Modules ]]--
local StatsUtils = require(CoreGuiService.RobloxGui.Modules.Stats.StatsUtils)
local StatsAggregatorClass = require(CoreGuiService.RobloxGui.Modules.Stats.StatsAggregator)

--[[ Classes ]]--
local StatsTextPanelClass = {}
StatsTextPanelClass.__index = StatsTextPanelClass

function StatsTextPanelClass.new(statsDisplayType, isMaximized) 
  local self = {}
  setmetatable(self, StatsTextPanelClass)

  self._statsDisplayType = statsDisplayType
  self._isMaximized = isMaximized
  
  self._frame = Instance.new("Frame")
  self._frame.BackgroundTransparency = 1.0
  
  self._titleLabel = Instance.new("TextLabel")
  self._valueLabel = Instance.new("TextLabel")

  StatsUtils.StyleTextWidget(self._titleLabel)
  StatsUtils.StyleTextWidget(self._valueLabel)
  
  self._titleLabel.FontSize = self:_getTitleSize();
  self._titleLabel.Font = "ArialBold"
  self._titleLabel.Text = self:_getTitle()
  
  self._titleLabel.Parent = self._frame
  self._titleLabel.Size = TitleSize
  self._titleLabel.Position = TitlePosition
  self._titleLabel.TextXAlignment = Enum.TextXAlignment.Left
  
  self._valueLabel.FontSize = self:_getValueSize();
  self._valueLabel.Text = "0"
  
  self._valueLabel.Parent = self._frame
  self._valueLabel.Size = ValueSize
  self._valueLabel.Position = ValuePosition
  self._valueLabel.TextXAlignment = Enum.TextXAlignment.Left
  
  return self
end

function StatsTextPanelClass:_getValueSize()
  if self._isMaximized then 
    return Enum.FontSize.Size18
  else 
    return Enum.FontSize.Size14
  end
end

function StatsTextPanelClass:_getTitleSize()
  if self._isMaximized then 
    return Enum.FontSize.Size24
  else 
    return Enum.FontSize.Size18
  end
end

function StatsTextPanelClass:_getTitle()
  if self._isMaximized then 
    return StatsUtils.DisplayTypeToName[self._statsDisplayType]
  else 
    return StatsUtils.DisplayTypeToShortName[self._statsDisplayType]
  end
end

function StatsTextPanelClass:PlaceInParent(parent, size, position) 
  self._frame.Position = position
  self._frame.Size = size
  self._frame.Parent = parent
end

function StatsTextPanelClass:SetValue(value) 
  -- FIXME(dbanks)
  -- Transform to appropriate units and format
  self._valueLabel.Text = string.format("%.4f", value)
end

return StatsTextPanelClass