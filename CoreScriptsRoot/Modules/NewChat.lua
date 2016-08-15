--[[
	// FileName: NewChat.lua
	// Written by: Xsitsu
	// Description: Bridges the topbar in corescripts to any chat system running in the non-corescripts environment.
]]
local CoreGuiService = game:GetService("CoreGui")
local RobloxGui = CoreGuiService:WaitForChild("RobloxGui")

local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")

local Util = require(RobloxGui.Modules.ChatUtil)


local moduleApiTable = {}
do
		local ChatWindowState = 
		{
			Visible = true,
			MessageCount = 0,
			TopbarEnabled = true,
			CoreGuiEnabled = true,
		}

		local communicationsConnections = {}
		local eventConnections = {}

		local MakeSystemMessageCache = {}

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
			if (coreGuiType == Enum.CoreGuiType.All or coreGuiType == Enum.CoreGuiType.Chat) then
				ChatWindowState.CoreGuiEnabled = enabled

				local event = FindIndexInCollectionWithType(communicationsConnections.ChatWindow, "CoreGuiEnabled", "BindableEvent")
				if (event) then
					event:Fire(ChatWindowState.CoreGuiEnabled)
				end
			end
		end)

		GuiService:AddSpecialKey(Enum.SpecialKey.ChatHotkey)
		GuiService.SpecialKeyPressed:connect(function(key, modifiers)
			local event = FindIndexInCollectionWithType(communicationsConnections.ChatWindow, "SpecialKeyPressed", "BindableEvent")
			if (event) then
				event:Fire(key, modifiers)
			end
		end)

		StarterGui:RegisterSetCore("ChatMakeSystemMessage", function(data)
			local event = FindIndexInCollectionWithType(communicationsConnections.SetCore, "ChatMakeSystemMessage", "BindableEvent")
			if (event) then
				event:Fire(data)
			else
				table.insert(MakeSystemMessageCache, data)
			end
		end)
		
		StarterGui:RegisterGetCore("ChatWindowPosition", function(data)
			local func = FindIndexInCollectionWithType(communicationsConnections.GetCore, "ChatWindowPosition", "BindableFunction")
			local rVal = nil
			if (func) then rVal = func:Invoke(data) end
			return rVal
		end)

		StarterGui:RegisterGetCore("ChatWindowSize", function(data)
			local func = FindIndexInCollectionWithType(communicationsConnections.GetCore, "ChatWindowSize", "BindableFunction")
			local rVal = nil
			if (func) then rVal = func:Invoke(data) end
			return rVal
		end)

		StarterGui:RegisterGetCore("ChatBarDisabled", function(data)
			local func = FindIndexInCollectionWithType(communicationsConnections.GetCore, "ChatBarDisabled", "BindableFunction")
			local rVal = nil
			if (func) then rVal = func:Invoke(data) end
			return rVal
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
					communicationsConnections.ChatWindow.SpecialKeyPressed = FindIndexInCollectionWithType(chatWindowCollection, "SpecialKeyPressed", "BindableEvent")


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

				else
					error("Table 'ChatWindow' must be provided!")

				end

				if (type(setCoreCollection) == "table" and type(getCoreCollection) == "table") then
					communicationsConnections.SetCore = {}
					communicationsConnections.GetCore = {}

					local event = FindIndexInCollectionWithType(setCoreCollection, "ChatMakeSystemMessage", "BindableEvent")
					if (event) then
						communicationsConnections.SetCore.ChatMakeSystemMessage = event
						for i, messageData in pairs(MakeSystemMessageCache) do
							pcall(function() StarterGui:SetCore("ChatMakeSystemMessage", messageData) end)
						end
						MakeSystemMessageCache = {}
					end

					communicationsConnections.GetCore.ChatWindowPosition = FindIndexInCollectionWithType(getCoreCollection, "ChatWindowPosition", "BindableFunction")
					communicationsConnections.GetCore.ChatWindowSize = FindIndexInCollectionWithType(getCoreCollection, "ChatWindowSize", "BindableFunction")
					communicationsConnections.GetCore.ChatBarDisabled = FindIndexInCollectionWithType(getCoreCollection, "ChatBarDisabled", "BindableFunction")

				elseif (type(setCoreCollection) ~= nil or type(getCoreCollection) ~= nil) then
					error("Both 'SetCore' and 'GetCore' must be tables if provided!")

				end

			end			
		end

		StarterGui:RegisterSetCore("CoreGuiChatConnections", RegisterCoreGuiConnections)

end

return moduleApiTable