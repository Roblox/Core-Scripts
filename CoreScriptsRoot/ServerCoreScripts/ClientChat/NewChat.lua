local source = [[
local moduleApiTable = {}

local UserInputService = game:GetService("UserInputService")

local EventFolder = game:GetService("ReplicatedStorage"):WaitForChild("ChatEvents")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local GuiParent = Instance.new("ScreenGui", PlayerGui)
GuiParent.Name = "Chat"
local modulesFolder = script


local moduleChatWindow = require(modulesFolder:WaitForChild("ChatWindow"))
local moduleMessageLabelCreator = require(modulesFolder:WaitForChild("MessageLabelCreator"))

local ChatWindow = moduleChatWindow.new()
ChatWindow.Parent = GuiParent
ChatWindow.Visible = false

local ChatBar = ChatWindow.ChatBar
local ChannelsBar = ChatWindow.ChannelsBar

ChatBar:ResetText()

local SpeakerDatabase = require(modulesFolder:WaitForChild("SpeakerDatabase"))
local ChatLog = require(modulesFolder:WaitForChild("ChatLog"))

moduleMessageLabelCreator:RegisterSpeakerDatabase(SpeakerDatabase)


local connections = {}
local con = nil

con = ChannelsBar.OnChannelTabChanged:connect(function(channelName)
	ChatWindow:SetCurrentChatChannel(channelName)

	local channelObj = channelName and ChatWindow:GetChatChannel(channelName) or nil
	if (channelObj) then
		ChatBar.Visible = not ChatWindow:GetChatChannel(channelName).Muted or true
	else
		ChatBar.Visible = false or true
	end
end)
table.insert(connections, con)

game:GetService("Players").LocalPlayer.Chatted:connect(function(message)
				
end)

con = ChatBar.FocusLost:connect(function(enterPressed)
	if (enterPressed or ChatBar.Text == "") then
		if (ChatBar.Text ~= "") then
			ChatBar.Text = string.sub(ChatBar.Text, 1, 140)--moduleChatChannel.MaximumMessageLength)

			if (ChatBar.Text:sub(1, 3) == "/c ") then
				local channelName = ChatBar.Text:sub(4)
				if (ChatWindow:GetChatChannel(channelName)) then
					ChannelsBar:SetActiveChannelTab(channelName)
				end

			else
				moduleApiTable.MessagePosted:fire(ChatBar.Text) -- sends signal to eventually call Player:Chat() to handle C++ side stuff
				
				if (ChatWindow.CurrentChatChannel) then
					EventFolder.SayMessageRequest:FireServer(ChatBar.Text, ChatWindow.CurrentChatChannel.Name)
				else
					EventFolder.SayMessageRequest:FireServer(ChatBar.Text, "__none__") -- this channel name means nothing
				end
			end
			
			ChatBar.Text = ""
		end
				
		--ChatBar.ClearTextOnFocus = true
	else
		ChatBar.ClearTextOnFocus = false
	end

	moduleApiTable.ChatBarFocusChanged:fire(false)
end)
table.insert(connections, con)

con = UserInputService.InputBegan:connect(function(input)
	if (not ChatWindow.CoreGuiEnabled) then return end
	if (not ChatBar.Enabled) then return end
	
	if (input.KeyCode == Enum.KeyCode.Slash and not ChatBar:IsFocused() and ChatBar.Visible) then
		moduleApiTable:SetVisible(true)
		ChatBar:CaptureFocus()
		moduleApiTable.ChatBarFocusChanged:fire(true)

	elseif (input.KeyCode == Enum.KeyCode.Tab and ChatBar:IsFocused() and ChatBar.Visible) then
		-- do autocomplete stuff... maybe someday...
		
	end
end)
table.insert(connections, con)

con = EventFolder.OnNewMessage.OnClientEvent:connect(function(fromSpeaker, channel, message)
	local channelObj = ChatWindow:GetChatChannel(channel)
	if (channelObj) then
		local messageLabel = moduleMessageLabelCreator:CreateMessageLabel(fromSpeaker, message)
		channelObj:AddLabelToLog(messageLabel)
		
		ChannelsBar:OnMessagePostedInChannel(channelObj.Name)
		
		ChatLog:LogMessage(fromSpeaker, channel, message)
		
		moduleApiTable.MessageCount = moduleApiTable.MessageCount + 1
		moduleApiTable.MessagesChanged:fire(moduleApiTable.MessageCount)
	end
end)
table.insert(connections, con)

con = EventFolder.OnNewSystemMessage.OnClientEvent:connect(function(message, channel)
	channel = channel or "System"
	
	local channelObj = ChatWindow:GetChatChannel(channel)
	if (channelObj) then
		local messageLabel = moduleMessageLabelCreator:CreateSystemMessageLabel(message)
		channelObj:AddLabelToLog(messageLabel)
		
		ChannelsBar:OnMessagePostedInChannel(channel)
		
		ChatLog:LogMessage(nil, channel, message)

		moduleApiTable.MessageCount = moduleApiTable.MessageCount + 1
		moduleApiTable.MessagesChanged:fire(moduleApiTable.MessageCount)
	end
end)
table.insert(connections, con)

con = EventFolder.OnChannelJoined.OnClientEvent:connect(function(channel, welcomeMessage)
	local channelObj = ChatWindow:AddChatChannel(channel)
	ChannelsBar:AddChannelTab(channel)
	if (channel == "All") then
		ChannelsBar:SetActiveChannelTab(channel)
	end
	
	local chatLog = ChatLog:GetChannelLog(channel)
	for i, logData in pairs(chatLog) do
		local messageLabel
		if (logData.SpeakerName) then
			messageLabel = moduleMessageLabelCreator:CreateMessageLabel(logData.SpeakerName, logData.Message)
		else
			messageLabel = moduleMessageLabelCreator:CreateSystemMessageLabel(logData.Message)
		end
		channelObj:AddLabelToLog(messageLabel)
	end
	
	if (welcomeMessage ~= "") then
		local messageLabel = moduleMessageLabelCreator:CreateWelcomeMessageLabel(welcomeMessage)
		channelObj:AddLabelToLog(messageLabel)
	end
	
	ChatLog:JoinedChannel(channel)
	
end)
table.insert(connections, con)

con = EventFolder.OnChannelLeft.OnClientEvent:connect(function(channel)
	if (ChatWindow.CurrentChatChannel and ChatWindow.CurrentChatChannel.Name:lower() == channel:lower()) then
		ChatWindow:SetCurrentChatChannel("")
		ChannelsBar:SetActiveChannelTab("")
	end

	ChatWindow:RemoveChatChannel(channel)
	ChannelsBar:RemoveChannelTab(channel)
	
	ChatLog:LeftChannel(channel)
end)
table.insert(connections, con)

con = EventFolder.OnMuted.OnClientEvent:connect(function(channel)
	local channelObj = ChatWindow:GetChatChannel(channel)
	if (channelObj) then
		channelObj.Muted = true
	end
end)
table.insert(connections, con)

con = EventFolder.OnUnmuted.OnClientEvent:connect(function(channel)
	local channelObj = ChatWindow:GetChatChannel(channel)
	if (channelObj) then
		channelObj.Muted = false
	end
end)
table.insert(connections, con)

con = EventFolder.OnSpeakerExtraDataUpdated.OnClientEvent:connect(function(speakerName, data)
	local speaker = SpeakerDatabase:GetSpeaker(speakerName)
	if (not speaker) then
		speaker = SpeakerDatabase:AddSpeaker(speakerName)
	end

	for k, v in pairs(data) do
		speaker[k] = v
	end
end)
table.insert(connections, con)


ChatWindow.Frame.Resizer.DragStopped:connect(function(x, y)
	if (ChatWindow.CurrentChatChannel) then
		ChatWindow.CurrentChatChannel:ReorderChatMessages()
	end
end)


LocalPlayer.CharacterRemoving:connect(function()
	GuiParent.Parent = nil
	LocalPlayer.CharacterAdded:wait()
	GuiParent.Parent = LocalPlayer:WaitForChild("PlayerGui")
end)

EventFolder.GetInitDataRequest:FireServer()









































--///////////// Code to talk to topbar and maintain set/get core backwards compatibility stuff
--////////////////////////////////////////////////////////////////////////////////////////////
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




local function SetVisibility(val)
	ChatWindow.Visible = val
	moduleApiTable.VisibilityStateChanged:fire(val)
end

do
	moduleApiTable.TopbarEnabled = true
	moduleApiTable.MessageCount = 0
	
	function moduleApiTable:ToggleVisibility()
		SetVisibility(not ChatWindow.Visible)
	end

	function moduleApiTable:SetVisible(visible)
		if (ChatWindow.Visible ~= visible) then
			SetVisibility(visible)
		end
	end

	function moduleApiTable:FocusChatBar()
		ChatBar:CaptureFocus()
	end

	function moduleApiTable:GetVisibility()
		return ChatWindow.Visible
	end

	function moduleApiTable:GetMessageCount()
		return self.MessageCount
	end

	function moduleApiTable:TopbarEnabledChanged(enabled)
		self.TopbarEnabled = enabled
		self.CoreGuiChanged:fire(Enum.CoreGuiType.Chat, game:GetService("StarterGui"):GetCoreGuiEnabled(Enum.CoreGuiType.Chat))
	end

	function moduleApiTable:IsFocused(useWasFocused)
		return ChatBar:IsFocused()
	end

	moduleApiTable.ChatBarFocusChanged = Util.Signal()
	moduleApiTable.VisibilityStateChanged = Util.Signal()
	moduleApiTable.MessagesChanged = Util.Signal()


	moduleApiTable.MessagePosted = Util.Signal()
	moduleApiTable.CoreGuiChanged = Util.Signal()
	
	
	moduleApiTable.eChatMakeSystemMessage = Util.Signal()
	moduleApiTable.eChatWindowPosition = Util.Signal()
	moduleApiTable.eChatWindowSize = Util.Signal()
	moduleApiTable.eChatBarDisabled = Util.Signal()
	
	function moduleApiTable:fChatWindowPosition()
		return ChatWindow.Frame.Dragger.Position
	end
	
	function moduleApiTable:fChatWindowSize()
		return ChatWindow.Frame.Dragger.Size
	end
	
	function moduleApiTable:fChatBarDisabled()
		return not ChatBar.Enabled
	end
end

--spawn(function() wait() moduleApiTable:SetVisible(true) end)

moduleApiTable.CoreGuiChanged:connect(function(coreGuiType, enabled)
	enabled = enabled and moduleApiTable.TopbarEnabled
	
	if (coreGuiType == Enum.CoreGuiType.All or coreGuiType == Enum.CoreGuiType.Chat) then
		ChatWindow:SetCoreGuiEnabled(enabled)
		if (not enabled) then
			ChatBar:ReleaseFocus()
		end
	end
end)


moduleApiTable.eChatMakeSystemMessage:connect(function(valueTable)
	if (valueTable["Text"] and type(valueTable["Text"]) == "string") then
		local channel = "system"
		local channelObj = ChatWindow:GetChatChannel(channel)
		if (channelObj) then
			local message = valueTable["Text"]
			
			local messageLabel = moduleMessageLabelCreator:CreateSystemMessageLabel(message)
			channelObj:AddLabelToLog(messageLabel)
			
			ChannelsBar:OnMessagePostedInChannel(channel)
			
			ChatLog:LogMessage(nil, channel, message)
	
			moduleApiTable.MessageCount = moduleApiTable.MessageCount + 1
			moduleApiTable.MessagesChanged:fire(moduleApiTable.MessageCount)
		end
	end
end)

moduleApiTable.eChatBarDisabled:connect(function(disabled)
	ChatBar.Enabled = not disabled
	if (disabled) then
		ChatBar:ReleaseFocus()
	end
end)

return moduleApiTable

]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script