local FORCE_USE_NEW_CHAT = false


local CoreGuiService = game:GetService("CoreGui")
local RobloxGui = CoreGuiService:WaitForChild("RobloxGui")

local StarterGui = game:GetService("StarterGui")

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


local moduleApiTable = {}
do
	local pcallSuccess, flagEnabled = pcall(function() return settings():GetFFlag("UseNewChat") end)
	local useNewChat = pcallSuccess and flagEnabled
	if (useNewChat or FORCE_USE_NEW_CHAT) then

		--// Need to cache data here since registration of the script that handles the real chat window could be slow
		local ChatWindowState = 
		{
			Visible = true,
			MessageCount = 0,
			TopbarEnabled = true,
			CoreGuiEnabled = true,
		}

		local communicationsConnections = {}
		local eventConnections = {}

		local function FindIndexInCollectionWithType(collection, indexName, type)
			if (collection and collection[indexName] and collection[indexName]:IsA(type)) then
				return collection[indexName]
			end
			return nil
		end

		function moduleApiTable:ToggleVisibility()
			ChatWindowState.Visible = not ChatWindowState.Visible
			local event = FindIndexInCollectionWithType(communicationsConnections.ChatWindow, "ToggleVisibility", "BindableEvent")
			if (event) then
				event:Fire()
			else
				moduleApiTable.VisibilityStateChanged:fire(ChatWindowState.Visible)
			end
		end

		function moduleApiTable:SetVisible(visible)
			ChatWindowState.Visible = visible
			local event = FindIndexInCollectionWithType(communicationsConnections.ChatWindow, "SetVisible", "BindableEvent")
			if (event) then
				event:Fire(ChatWindowState.Visible)
			else
				moduleApiTable.VisibilityStateChanged:fire(ChatWindowState.Visible)
			end
		end

		function moduleApiTable:FocusChatBar()
			local event = FindIndexInCollectionWithType(communicationsConnections.ChatWindow, "FocusChatBar", "BindableEvent")
			if (event) then
				event:Fire()
			end
		end

		function moduleApiTable:GetVisibility()
			local func = FindIndexInCollectionWithType(communicationsConnections.ChatWindow, "GetVisibility", "BindableFunction")
			if (func) then
				return func:Invoke()
			end
			return ChatWindowState.Visible
		end

		function moduleApiTable:GetMessageCount()
			local func = FindIndexInCollectionWithType(communicationsConnections.ChatWindow, "GetMessageCount", "BindableFunction")
			if (func) then
				return func:Invoke()
			end
			return ChatWindowState.MessageCount
		end

		function moduleApiTable:TopbarEnabledChanged(enabled)
			ChatWindowState.TopbarEnabled = enabled
			local event = FindIndexInCollectionWithType(communicationsConnections.ChatWindow, "TopbarEnabledChanged", "BindableEvent")
			if (event) then
				event:Fire(ChatWindowState.TopbarEnabled)
			end
		end

		function moduleApiTable:IsFocused(useWasFocused)
			local func = FindIndexInCollectionWithType(communicationsConnections.ChatWindow, "IsFocused", "BindableFunction")
			if (func) then
				return func:Invoke(useWasFocused)
			end
			return false
		end

		moduleApiTable.ChatBarFocusChanged = Util.Signal()
		moduleApiTable.VisibilityStateChanged = Util.Signal()
		moduleApiTable.MessagesChanged = Util.Signal()

		StarterGui.CoreGuiChangedSignal:connect(function(coreGuiType, enabled)
			local event = FindIndexInCollectionWithType(communicationsConnections.ChatWindow, "CoreGuiEnabled", "BindableEvent")
			if (event) then
				if (coreGuiType == Enum.CoreGuiType.All or coreGuiType == Enum.CoreGuiType.Chat) then
					ChatWindowState.CoreGuiEnabled = enabled
					event:Fire(enabled)
				end
			end
		end)

		local function RegisterCoreGuiConnections(containerTable)
			if (type(containerTable) == "table") then
				local chatWindowCollection = containerTable.ChatWindow
				local setCoreCollection = containerTable.SetCore
				local getCoreCollection = containerTable.GetCore

				if (type(chatWindowCollection) == "table") then
					for i, v in pairs(eventConnections) do
						v:disconnect()
					end

					eventConnections = {}
					communicationsConnections.ChatWindow = {}

					communicationsConnections.ChatWindow.ToggleVisibility = FindIndexInCollectionWithType(chatWindowCollection, "ToggleVisibility", "BindableEvent")
					communicationsConnections.ChatWindow.SetVisible = FindIndexInCollectionWithType(chatWindowCollection, "SetVisible", "BindableEvent")
					communicationsConnections.ChatWindow.FocusChatBar = FindIndexInCollectionWithType(chatWindowCollection, "FocusChatBar", "BindableEvent")
					communicationsConnections.ChatWindow.TopbarEnabledChanged = FindIndexInCollectionWithType(chatWindowCollection, "TopbarEnabledChanged", "BindableEvent")
					communicationsConnections.ChatWindow.IsFocused = FindIndexInCollectionWithType(chatWindowCollection, "IsFocused", "BindableFunction")


					local function DoConnect(index)
						communicationsConnections.ChatWindow[index] = FindIndexInCollectionWithType(chatWindowCollection, index, "BindableEvent")
						if (communicationsConnections.ChatWindow[index]) then
							local con = communicationsConnections.ChatWindow[index].Event:connect(function(...) moduleApiTable[index]:fire(...) end)
							table.insert(eventConnections, con)
						end
					end

					DoConnect("ChatBarFocusChanged")
					DoConnect("VisibilityStateChanged")

					local index = "MessagePosted"
					communicationsConnections.ChatWindow[index] = FindIndexInCollectionWithType(chatWindowCollection, index, "BindableEvent")
					if (communicationsConnections.ChatWindow[index]) then
						local con = communicationsConnections.ChatWindow[index].Event:connect(function(message) game:GetService("Players"):Chat(message) end)
						table.insert(eventConnections, con)
					end

					moduleApiTable:SetVisible(ChatWindowState.Visible)
					moduleApiTable:TopbarEnabledChanged(ChatWindowState.TopbarEnabled)

					local event = FindIndexInCollectionWithType(chatWindowCollection, "CoreGuiEnabled", "BindableEvent")
					if (event) then
						communicationsConnections.ChatWindow.CoreGuiEnabled = event
						event:Fire(ChatWindowState.CoreGuiEnabled)
					end

				end

				if not (type(chatWindowCollection) == "table" and type(setCoreCollection) == "table" and type(getCoreCollection) == "table") then
					error("chatWindowCollection, setCoreCollection, and getCoreCollection must be tables!")
				end

			end			
		end

		StarterGui:RegisterSetCore("CoreGuiChatConnections", RegisterCoreGuiConnections)

	else
		moduleApiTable = require(RobloxGui.Modules.Chat)

	end
end

return moduleApiTable
