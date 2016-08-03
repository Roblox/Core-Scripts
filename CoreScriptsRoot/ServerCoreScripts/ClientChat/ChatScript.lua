local source = [[
local Chat = require(script:WaitForChild("NewChat"))

local containerTable = {}
local chatWindowConnections = {}
local setCoreConnections = {}
local getCoreConnections = {}

containerTable.ChatWindow = chatWindowConnections
containerTable.SetCore = setCoreConnections
containerTable.GetCore = getCoreConnections


--// Connection functions
local function ConnectEvent(name)
	local event = Instance.new("BindableEvent")
	event.Name = name
	containerTable.ChatWindow[name] = event

	event.Event:connect(function(...) Chat[name](Chat, ...) end)
end

local function ConnectFunction(name)
	local func = Instance.new("BindableFunction")
	func.Name = name
	containerTable.ChatWindow[name] = func

	func.OnInvoke = function(...) return Chat[name](Chat, ...) end
end

local function ReverseConnectEvent(name)
	local event = Instance.new("BindableEvent")
	event.Name = name
	containerTable.ChatWindow[name] = event

	Chat[name]:connect(function(...) event:Fire(...) end)
end

local function ConnectSignal(name)
	local event = Instance.new("BindableEvent")
	event.Name = name
	containerTable.ChatWindow[name] = event

	event.Event:connect(function(...) Chat[name]:fire(...) end)
end

local function ConnectSetCore(name)
	local event = Instance.new("BindableEvent")
	event.Name = name
	containerTable.SetCore[name] = event

	event.Event:connect(function(...) Chat[name.."Event"]:fire(...) end)
end

local function ConnectGetCore(name)
	local func = Instance.new("BindableFunction")
	func.Name = name
	containerTable.GetCore[name] = func

	func.OnInvoke = function(...) return Chat["f"..name](...) end
end

--// Do connections
ConnectEvent("ToggleVisibility")
ConnectEvent("SetVisible")
ConnectEvent("FocusChatBar")
ConnectFunction("GetVisibility")
ConnectFunction("GetMessageCount")
ConnectEvent("TopbarEnabledChanged")
ConnectFunction("IsFocused")

ReverseConnectEvent("ChatBarFocusChanged")
ReverseConnectEvent("VisibilityStateChanged")
ReverseConnectEvent("MessagesChanged")
ReverseConnectEvent("MessagePosted")

ConnectSignal("CoreGuiEnabled")

ConnectSetCore("ChatMakeSystemMessage")
ConnectSetCore("ChatWindowPosition")
ConnectSetCore("ChatWindowSize")
ConnectGetCore("ChatWindowPosition")
ConnectGetCore("ChatWindowSize")
ConnectSetCore("ChatBarDisabled")
ConnectGetCore("ChatBarDisabled")



wait()
pcall(function()
	game:GetService("StarterGui"):SetCore("CoreGuiChatConnections", containerTable)
end)
]]

local generated = Instance.new("LocalScript")
generated.Disabled = true
generated.Name = "Generated"
generated.Source = source
generated.Parent = script