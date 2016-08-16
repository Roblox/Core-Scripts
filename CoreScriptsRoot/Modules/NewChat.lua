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

		local function FindInCollectionByKeyAndType(collection, indexName, type)
			if (collection and collection[indexName] and collection[indexName]:IsA(type)) then
				return collection[indexName]
			end
			return nil
		end

		function moduleApiTable:ToggleVisibility()
			ChatWindowState.Visible = not ChatWindowState.Visible
			local event = FindInCollectionByKeyAndType(communicationsConnections.ChatWindow, "ToggleVisibility", "BindableEvent")
			if (event) then
				event:Fire()
			else
				moduleApiTable.VisibilityStateChanged:fire(ChatWindowState.Visible)
			end
		end

		function moduleApiTable:SetVisible(visible)
			ChatWindowState.Visible = visible
			local event = FindInCollectionByKeyAndType(communicationsConnections.ChatWindow, "SetVisible", "BindableEvent")
			if (event) then
				event:Fire(ChatWindowState.Visible)
			else
				moduleApiTable.VisibilityStateChanged:fire(ChatWindowState.Visible)
			end
		end

		function moduleApiTable:FocusChatBar()
			local event = FindInCollectionByKeyAndType(communicationsConnections.ChatWindow, "FocusChatBar", "BindableEvent")
			if (event) then
				event:Fire()
			end
		end

		function moduleApiTable:GetVisibility()
			local func = FindInCollectionByKeyAndType(communicationsConnections.ChatWindow, "GetVisibility", "BindableFunction")
			if (func) then
				return func:Invoke()
			end
			return ChatWindowState.Visible
		end

		function moduleApiTable:GetMessageCount()
			local func = FindInCollectionByKeyAndType(communicationsConnections.ChatWindow, "GetMessageCount", "BindableFunction")
			if (func) then
				return func:Invoke()
			end
			return ChatWindowState.MessageCount
		end

		function moduleApiTable:TopbarEnabledChanged(enabled)
			ChatWindowState.TopbarEnabled = enabled
			local event = FindInCollectionByKeyAndType(communicationsConnections.ChatWindow, "TopbarEnabledChanged", "BindableEvent")
			if (event) then
				event:Fire(ChatWindowState.TopbarEnabled)
			end
		end

		function moduleApiTable:IsFocused(useWasFocused)
			local func = FindInCollectionByKeyAndType(communicationsConnections.ChatWindow, "IsFocused", "BindableFunction")
			if (func) then
				return func:Invoke(useWasFocused)
			end
			return false
		end
		
		moduleApiTable.ChatBarFocusChanged = Util.Signal()
		moduleApiTable.VisibilityStateChanged = Util.Signal()
		moduleApiTable.MessagesChanged = Util.Signal()

		local function DispatchEvent(eventName, ...)
			local event = FindInCollectionByKeyAndType(communicationsConnections.ChatWindow, eventName, "BindableEvent")
			if (event) then
				event:Fire(...)
			end
		end

		local function DoConnectGetCore(connectionName)
			StarterGui:RegisterGetCore(connectionName, function(data)
				local func = FindInCollectionByKeyAndType(communicationsConnections.GetCore, connectionName, "BindableFunction")
				local rVal = nil
				if (func) then rVal = func:Invoke(data) end
				return rVal
			end)
		end

		StarterGui.CoreGuiChangedSignal:connect(function(coreGuiType, enabled)
			if (coreGuiType == Enum.CoreGuiType.All or coreGuiType == Enum.CoreGuiType.Chat) then
				ChatWindowState.CoreGuiEnabled = enabled
				DispatchEvent("CoroeGuiEnabled", ChatWindowState.CoreGuiEnabled)
			end
		end)

		GuiService:AddSpecialKey(Enum.SpecialKey.ChatHotkey)
		GuiService.SpecialKeyPressed:connect(function(key, modifiers)
			DispatchEvent("SpecialKeyPressed", key, modifiers)
		end)

		StarterGui:RegisterSetCore("ChatMakeSystemMessage", function(data)
			local event = FindInCollectionByKeyAndType(communicationsConnections.SetCore, "ChatMakeSystemMessage", "BindableEvent")
			if (event) then
				event:Fire(data)
			else
				table.insert(MakeSystemMessageCache, data)
			end
		end)

		DoConnectGetCore("ChatWindowPosition")
		DoConnectGetCore("ChatWindowSize")
		DoConnectGetCore("ChatBarDisabled")

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

					communicationsConnections.ChatWindow.ToggleVisibility = FindInCollectionByKeyAndType(chatWindowCollection, "ToggleVisibility", "BindableEvent")
					communicationsConnections.ChatWindow.SetVisible = FindInCollectionByKeyAndType(chatWindowCollection, "SetVisible", "BindableEvent")
					communicationsConnections.ChatWindow.FocusChatBar = FindInCollectionByKeyAndType(chatWindowCollection, "FocusChatBar", "BindableEvent")
					communicationsConnections.ChatWindow.TopbarEnabledChanged = FindInCollectionByKeyAndType(chatWindowCollection, "TopbarEnabledChanged", "BindableEvent")
					communicationsConnections.ChatWindow.IsFocused = FindInCollectionByKeyAndType(chatWindowCollection, "IsFocused", "BindableFunction")
					communicationsConnections.ChatWindow.SpecialKeyPressed = FindInCollectionByKeyAndType(chatWindowCollection, "SpecialKeyPressed", "BindableEvent")


					local function DoConnect(index)
						communicationsConnections.ChatWindow[index] = FindInCollectionByKeyAndType(chatWindowCollection, index, "BindableEvent")
						if (communicationsConnections.ChatWindow[index]) then
							local con = communicationsConnections.ChatWindow[index].Event:connect(function(...) moduleApiTable[index]:fire(...) end)
							table.insert(eventConnections, con)
						end
					end

					DoConnect("ChatBarFocusChanged")
					DoConnect("VisibilityStateChanged")

					local index = "MessagePosted"
					communicationsConnections.ChatWindow[index] = FindInCollectionByKeyAndType(chatWindowCollection, index, "BindableEvent")
					if (communicationsConnections.ChatWindow[index]) then
						local con = communicationsConnections.ChatWindow[index].Event:connect(function(message) game:GetService("Players"):Chat(message) end)
						table.insert(eventConnections, con)
					end

					moduleApiTable:SetVisible(ChatWindowState.Visible)
					moduleApiTable:TopbarEnabledChanged(ChatWindowState.TopbarEnabled)

					local event = FindInCollectionByKeyAndType(chatWindowCollection, "CoreGuiEnabled", "BindableEvent")
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

					local event = FindInCollectionByKeyAndType(setCoreCollection, "ChatMakeSystemMessage", "BindableEvent")
					if (event) then
						communicationsConnections.SetCore.ChatMakeSystemMessage = event
						for i, messageData in pairs(MakeSystemMessageCache) do
							pcall(function() StarterGui:SetCore("ChatMakeSystemMessage", messageData) end)
						end
						MakeSystemMessageCache = {}
					end

					communicationsConnections.GetCore.ChatWindowPosition = FindInCollectionByKeyAndType(getCoreCollection, "ChatWindowPosition", "BindableFunction")
					communicationsConnections.GetCore.ChatWindowSize = FindInCollectionByKeyAndType(getCoreCollection, "ChatWindowSize", "BindableFunction")
					communicationsConnections.GetCore.ChatBarDisabled = FindInCollectionByKeyAndType(getCoreCollection, "ChatBarDisabled", "BindableFunction")

				elseif (type(setCoreCollection) ~= nil or type(getCoreCollection) ~= nil) then
					error("Both 'SetCore' and 'GetCore' must be tables if provided!")

				end

			end			
		end

		StarterGui:RegisterSetCore("CoreGuiChatConnections", RegisterCoreGuiConnections)

end

return moduleApiTable