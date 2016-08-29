local source = [[
--	// FileName: ChatSettings.lua
--	// Written by: Xsitsu
--	// Description: Settings module for configuring different aspects of the chat window.

local module = {}

module.WindowDraggable = false
module.WindowResizable = false

module.ChatWindowTextSize = Enum.FontSize.Size18
module.ChatChannelsTabTextSize = Enum.FontSize.Size18
module.ChatBarTextSize = Enum.FontSize.Size18

module.ChatWindowTextSizePhone = Enum.FontSize.Size14
module.ChatChannelsTabTextSizePhone = Enum.FontSize.Size18
module.ChatBarTextSizePhone = Enum.FontSize.Size14

module.MinimumWindowSize = UDim2.new(0.3, 0, 0.25, 0)
module.MaximumWindowSize = UDim2.new(1, 0, 1, 0) -- if you change this to be greater than full screen size, weird things start to happen with size/position bounds checking.

module.DefaultWindowPosition = UDim2.new(0, 0, 0, 0)

module.DefaultWindowSizePhone = UDim2.new(0.5, 0, 0.5, 18 + 18)
module.DefaultWindowSizeTablet = UDim2.new(0.4, 0, 0.3, 18 + 18)
module.DefaultWindowSizeDesktop = UDim2.new(0.3, 0, 0.25, 18 + 18)

module.GeneralChannelName = "All" -- You can set to 'nil' to turn off echoing to a general channel.

module.ChannelsBarFullTabSize = 4 -- number of tabs in bar before it starts to scroll

local ChangedEvent = Instance.new("BindableEvent")

local proxyTable = setmetatable({},
{
	__index = function(tbl, index)
		return module[index]
	end,
	__newindex = function(tbl, index, value)
		module[index] = value
		ChangedEvent:Fire(index, value)
	end,
})

rawset(proxyTable, "SettingsChanged", ChangedEvent.Event)

return proxyTable
]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script