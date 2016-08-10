local FORCE_TRY_LOAD_NEW_CHAT = false
local FORCE_USE_NEW_CHAT = false


local CoreGuiService = game:GetService("CoreGui")
local RobloxGui = CoreGuiService:WaitForChild("RobloxGui")

local StarterGui = game:GetService("StarterGui")

local function GetUseLuaFlag()
	local loop_continue = true
	while loop_continue do
		local success, retVal = pcall(function()
			return game.IsSFFlagsLoaded
		end)
		if not success then
			loop_continue = false
		elseif retVal then
			loop_continue = false
		else
			wait(0.1)
		end
	end

	local success, retVal = pcall(function() return game:GetService("Chat"):GetShouldUseLuaChat() end)
	local useNewChat = success and retVal
	return useNewChat
end

local readFlagSuccess, flagEnabled = pcall(function() return settings():GetFFlag("CorescriptNewLoadChat") end)
local TryLoadNewChat = readFlagSuccess and flagEnabled

local Util = {}
do
	function Util.Signal()
		local sig = {}

		local mSignaler = Instance.new('BindableEvent')

		local mArgData = nil
		local mArgDataCount = nil

		function sig:fire(...)
			mArgData = {...}
			mArgDataCount = select('#', ...)
			mSignaler:Fire()
		end

		function sig:connect(f)
			if not f then error("connect(nil)", 2) end
			return mSignaler.Event:connect(function()
				f(unpack(mArgData, 1, mArgDataCount))
			end)
		end

		function sig:wait()
			mSignaler.Event:wait()
			assert(mArgData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
			return unpack(mArgData, 1, mArgDataCount)
		end

		return sig
	end
end



local useModule = nil

local state = {Visible = true}
local interface = {}
do
	function interface:ToggleVisibility()
		if (useModule) then
			useModule:ToggleVisibility()
		else
			state.Visible = not state.Visible
		end
	end

	function interface:SetVisible(visible)
		if (useModule) then
			useModule:SetVisible(visible)
		else
			state.Visible = visible
		end
	end

	function interface:FocusChatBar()
		if (useModule) then
			useModule:FocusChatBar()
		else
			--// do nothing
		end
	end

	function interface:GetVisibility()
		if (useModule) then
			return useModule:GetVisibility()
		else
			return state.Visible
		end
	end

	function interface:GetMessageCount()
		if (useModule) then
			return useModule:GetMessageCount()
		else
			return 0
		end
	end

	function interface:TopbarEnabledChanged(...)
		if (useModule) then
			return useModule:TopbarEnabledChanged(...)
		else
			
		end
	end

	function interface:IsFocused(useWasFocused)
		if (useModule) then
			return useModule:IsFocused(useWasFocused)
		else
			return false
		end
	end

	interface.ChatBarFocusChanged = Util.Signal()
	interface.VisibilityStateChanged = Util.Signal()
	interface.MessagesChanged = Util.Signal()
end

local stopCachingMakeSystemMessage = false
local MakeSystemMessageCache = {}
local function MakeSystemMessageCachingFunction(data)
	if (stopCachingMakeSystemMessage) then return end
	table.insert(MakeSystemMessageCache, data)
end

local function NonFunc() end
StarterGui:RegisterSetCore("ChatMakeSystemMessage", MakeSystemMessageCachingFunction)
StarterGui:RegisterSetCore("ChatWindowPosition", NonFunc)
StarterGui:RegisterSetCore("ChatWindowSize", NonFunc)
StarterGui:RegisterGetCore("ChatWindowPosition", NonFunc)
StarterGui:RegisterGetCore("ChatWindowSize", NonFunc)
StarterGui:RegisterSetCore("ChatBarDisabled", NonFunc)
StarterGui:RegisterGetCore("ChatBarDisabled", NonFunc)


local function ConnectSignals(useModule, interface, sigName)
	useModule[sigName]:connect(function(...) interface[sigName]:fire(...) end)
end

if (TryLoadNewChat or FORCE_TRY_LOAD_NEW_CHAT) then
	spawn(function()
		local useNewChat = GetUseLuaFlag()
		local useModuleScript = (useNewChat or FORCE_USE_NEW_CHAT) and RobloxGui.Modules.NewChat or RobloxGui.Modules.Chat
		useModule = require(useModuleScript)

		ConnectSignals(useModule, interface, "ChatBarFocusChanged")
		ConnectSignals(useModule, interface, "VisibilityStateChanged")
		ConnectSignals(useModule, interface, "MessagesChanged")

		StarterGui:RegisterGetCore("UseNewLuaChat", function() return useNewChat end)

		useModule:SetVisible(state.Visible)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat))

		stopCachingMakeSystemMessage = true
		for i, messageData in pairs(MakeSystemMessageCache) do
			pcall(function() StarterGui:SetCore("ChatMakeSystemMessage", messageData) end)
		end
	end)
else
	useModule = require(RobloxGui.Modules.Chat)

	ConnectSignals(useModule, interface, "ChatBarFocusChanged")
	ConnectSignals(useModule, interface, "VisibilityStateChanged")
	ConnectSignals(useModule, interface, "MessagesChanged")
	
end

return interface
