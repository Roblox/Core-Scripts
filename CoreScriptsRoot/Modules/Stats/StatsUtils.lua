--[[
		Filename: StatsUtils.lua
		Written by: dbanks
		Description: Common work in the performance stats world.
--]]
--[[ Classes ]]--
local StatsUtils = {}

StatsUtils.NormalColor = Color3.new(0.3, 0.3, 0.1)
StatsUtils.SelectedColor = Color3.new(0.5, 0.5, 0.3)
StatsUtils.Transparency = 0.6

StatsUtils.FontColor = Color3.new(1, 1, 1)

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
end

function StatsUtils.StyleButtonSelected(frame, isSelected)
  StatsUtils.StyleButton(frame)
  if (isSelected) then 
    frame.BackgroundColor3 = StatsUtils.SelectedColor
  end
end


return StatsUtils