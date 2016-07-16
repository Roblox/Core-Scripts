local source = [[
local module = {}

module.ChannelTabNotificationColor = Color3.new(1, 1, 0)
module.ChannelTabFontSize = Enum.FontSize.Size18
module.ChatMessageFontSize = Enum.FontSize.Size18
module.MaximumMessageLog = 100

return module

]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script