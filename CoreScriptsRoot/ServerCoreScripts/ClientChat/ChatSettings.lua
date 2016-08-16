local source = [[
-- This module is for initial settings that are not intended to be changed during runtime.

local module = {}

module.WindowDraggable = false
module.WindowResizable = false -- soon (tee emm)

module.ChatWindowTextSize = Enum.FontSize.Size18
module.ChatChannelsTabTextSize = Enum.FontSize.Size18
module.ChatBarTextSize = Enum.FontSize.Size18

-- these two are in pixels
module.MinimumWindowSizeX = 1600/3.75
module.MinimumWindowSizeY = 900/3.75

module.DefaultWindowSize = UDim2.new(0.35, 0, 0.35, 0)

return module
]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script