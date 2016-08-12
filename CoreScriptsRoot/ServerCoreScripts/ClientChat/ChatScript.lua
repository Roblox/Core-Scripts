local source = [[
--	// FileName: ChatScript.lua
--	// Written by: Xsitsu
--	// Description: Hooks main chat module up to Topbar in corescripts.


--// To ALWAYS run this system, you will need the server side force installed 
--// as well. You can't wait for the server to create it at runtime, because 
--// that will only happen if the correct fastflags are set and at that point
--// this new chat system will just run anyways.

--// The first forces a run if after waiting it turns out it shouldn't run.
--// The second skips the waiting and forces a run anyways.
--// The second bool overrides the first if the second is set to true.
--// Using the first bool allows it the potential of integrating with the 
--// topbar while the second one does not.
local FORCE_NEW_CHAT_SYSTEM = false
local FORCE_RUN_WITHOUT_TOPBAR = false

local StarterGui = game:GetService("StarterGui")

local function DoEverything()
	local Chat = require(script:WaitForChild("ChatMain"))

	if (FORCE_RUN_WITHOUT_TOPBAR) then return end

	local containerTable = {}
	containerTable.ChatWindow = {}
	containerTable.SetCore = {}
	containerTable.GetCore = {}


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

	ConnectEvent("SpecialKeyPressed")

	pcall(function() StarterGui:SetCore("CoreGuiChatConnections", containerTable) end)
end

local success, ret = pcall(function() return StarterGui:GetCore("UseNewLuaChat") end)
while (not FORCE_RUN_WITHOUT_TOPBAR and not success) do
	success, ret = pcall(function() return StarterGui:GetCore("UseNewLuaChat") end)
	wait()
end

if (success and ret) then
	DoEverything()
elseif (FORCE_RUN_WITHOUT_TOPBAR or FORCE_NEW_CHAT_SYSTEM) then
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
	DoEverything()
end
]]

local generated = Instance.new("LocalScript")
generated.Disabled = true
generated.Name = "Generated"
generated.Source = source
generated.Parent = script