--	// FileName: ChatMain.lua
--	// Written by: Xsitsu
--	// Description: Main module to handle initializing chat window UI and hooking up events to individual UI pieces.

local BACKGROUND_FADEOUT_TIME = 0

local moduleApiTable = {}

--// This section of code waits until all of the necessary RemoteEvents are found in EventFolder.
--// I have to do some weird stuff since people could potentially already have pre-existing
--// things in a folder with the same name, and they may have different class types.
--// I do the useEvents thing and set EventFolder to useEvents so I can have a pseudo folder that
--// the rest of the code can interface with and have the guarantee that the RemoteEvents they want
--// exist with their desired names.

local EventFolder = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents")

local numChildrenRemaining = 10 -- #waitChildren returns 0 because it's a dictionary
local waitChildren =
{
	OnNewMessage = "RemoteEvent",
	OnMessageDoneFiltering = "RemoteEvent",
	OnNewSystemMessage = "RemoteEvent",
	OnChannelJoined = "RemoteEvent",
	OnChannelLeft = "RemoteEvent",
	OnMuted = "RemoteEvent",
	OnUnmuted = "RemoteEvent",
	OnMainChannelSet = "RemoteEvent",

	SayMessageRequest = "RemoteEvent",
	GetInitDataRequest = "RemoteFunction",
}

local useEvents = {}

local FoundAllEventsEvent = Instance.new("BindableEvent")

local function TryRemoveChildWithVerifyingIsCorrectType(child)
	if (waitChildren[child.Name] and child:IsA(waitChildren[child.Name])) then
		waitChildren[child.Name] = nil
		useEvents[child.Name] = child
		numChildrenRemaining = numChildrenRemaining - 1
	end
end

for i, child in pairs(EventFolder:GetChildren()) do
	TryRemoveChildWithVerifyingIsCorrectType(child)
end

if (numChildrenRemaining > 0) then
	local con = EventFolder.ChildAdded:connect(function(child)
		TryRemoveChildWithVerifyingIsCorrectType(child)
		if (numChildrenRemaining < 1) then
			FoundAllEventsEvent:Fire()
		end
	end)

	FoundAllEventsEvent.Event:wait()
	con:disconnect()

	FoundAllEventsEvent:Destroy()
end

EventFolder = useEvents



--// Rest of code after waiting for correct events.

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local GuiParent = Instance.new("ScreenGui", PlayerGui)
GuiParent.Name = "Chat"

local modulesFolder = script

local moduleChatWindow = require(modulesFolder:WaitForChild("ChatWindow"))
local moduleChatBar = require(modulesFolder:WaitForChild("ChatBar"))
local moduleChannelsBar = require(modulesFolder:WaitForChild("ChannelsBar"))
local moduleMessageLabelCreator = require(modulesFolder:WaitForChild("MessageLabelCreator"))
local moduleMessageLogDisplay = require(modulesFolder:WaitForChild("MessageLogDisplay"))
local moduleChatChannel = require(modulesFolder:WaitForChild("ChatChannel"))

moduleMessageLabelCreator:RegisterGuiRoot(GuiParent)

local ChatWindow = moduleChatWindow.new()
local ChatBar = moduleChatBar.new()
local ChannelsBar = moduleChannelsBar.new()
local MessageLogDisplay = moduleMessageLogDisplay.new()

ChatWindow:CreateGuiObjects(GuiParent)

ChatWindow:RegisterChatBar(ChatBar)
ChatWindow:RegisterChannelsBar(ChannelsBar)
ChatWindow:RegisterMessageLogDisplay(MessageLogDisplay)

local ChatSettings = require(modulesFolder:WaitForChild("ChatSettings"))

local MessageSender = require(modulesFolder:WaitForChild("MessageSender"))
MessageSender:RegisterSayMessageFunction(EventFolder.SayMessageRequest)



if (UserInputService.TouchEnabled) then
	ChatBar:SetTextLabelText('Tap here to chat')
else
	ChatBar:SetTextLabelText('To chat click here or press "/" key')
end






--////////////////////////////////////////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////// Code to do chat window fading
--////////////////////////////////////////////////////////////////////////////////////////////
local function CheckIfPointIsInSquare(checkPos, topLeft, bottomRight)
	return (topLeft.X <= checkPos.X and checkPos.X <= bottomRight.X and
		topLeft.Y <= checkPos.Y and checkPos.Y <= bottomRight.Y)
end

local backgroundIsFaded = false
local textIsFaded = false
local lastFadeTime = 0

local fadedChanged = Instance.new("BindableEvent")
local mouseStateChanged = Instance.new("BindableEvent")
local chatBarFocusChanged = Instance.new("BindableEvent")

local function DoBackgroundFadeIn(setFadingTime)
	lastFadeTime = tick()
	backgroundIsFaded = false
	fadedChanged:Fire()
	ChatWindow:EnableResizable()
	ChatWindow:FadeInBackground((setFadingTime or ChatSettings.ChatDefaultFadeDuration))

	local currentChannelObject = ChatWindow:GetCurrentChannel()
	if (currentChannelObject) then
		ChatWindow.GuiObject.Active = true

		local Scroller = MessageLogDisplay.Scroller
		Scroller.ScrollingEnabled = true
		Scroller.ScrollBarThickness = moduleMessageLogDisplay.ScrollBarThickness
	end
end

local function DoBackgroundFadeOut(setFadingTime)
	lastFadeTime = tick()
	backgroundIsFaded = true
	fadedChanged:Fire()
	ChatWindow:DisableResizable()
	ChatWindow:FadeOutBackground((setFadingTime or ChatSettings.ChatDefaultFadeDuration))

	local currentChannelObject = ChatWindow:GetCurrentChannel()
	if (currentChannelObject) then
		ChatWindow.GuiObject.Active = false
		--ChatWindow:ResetResizerPosition()

		local Scroller = MessageLogDisplay.Scroller
		scrollBarThickness = Scroller.ScrollBarThickness
		Scroller.ScrollingEnabled = false
		Scroller.ScrollBarThickness = 0
	end
end

local function DoTextFadeIn(setFadingTime)
	lastFadeTime = tick()
	textIsFaded = false
	fadedChanged:Fire()
	ChatWindow:FadeInText((setFadingTime or ChatSettings.ChatDefaultFadeDuration) * 0)
end

local function DoTextFadeOut(setFadingTime)
	lastFadeTime = tick()
	textIsFaded = true
	fadedChanged:Fire()
	ChatWindow:FadeOutText((setFadingTime or ChatSettings.ChatDefaultFadeDuration))
end

local function DoFadeInFromNewInformation()
	DoTextFadeIn()
	if ChatSettings.ChatShouldFadeInFromNewInformation then
		DoBackgroundFadeIn()
	end
end

local function InstantFadeIn()
	DoBackgroundFadeIn(0)
	DoTextFadeIn(0)
end

local function InstantFadeOut()
	DoBackgroundFadeOut(0)
	DoTextFadeOut(0)
end

local function DealWithCoreGuiEnabledChanged(enabled)
	if (moduleApiTable.Visible) then
		if (enabled) then
			InstantFadeIn()
		else
			InstantFadeOut()
		end
	end
end

local mouseIsInWindow = nil
local function UpdateFadingForMouseState(mouseState)
	mouseIsInWindow = mouseState

	mouseStateChanged:Fire()

	if (ChatBar:IsFocused()) then return end

	if (mouseState) then
		DoBackgroundFadeIn()
		DoTextFadeIn()
	else
		DoBackgroundFadeIn()
	end
end


local last = 0
spawn(function()
	while true do
		RunService.RenderStepped:wait()

		while (mouseIsInWindow or ChatBar:IsFocused()) do
			if (mouseIsInWindow) then
				mouseStateChanged.Event:wait()
			end
			if (ChatBar:IsFocused()) then
				chatBarFocusChanged.Event:wait()
			end
		end

		local timeDiff = tick() - lastFadeTime

		-- debug timer printing
		--if (math.abs(last - timeDiff) > 0.5) then
		--	last = timeDiff
		--	print("Step", timeDiff, backgroundIsFaded, textIsFaded)
		--end

		if (not backgroundIsFaded) then
			if (timeDiff > ChatSettings.ChatWindowBackgroundFadeOutTime) then
				DoBackgroundFadeOut()
			end

		elseif (not textIsFaded) then
			if (timeDiff > ChatSettings.ChatWindowTextFadeOutTime) then
				DoTextFadeOut()
			end

		else
			fadedChanged.Event:wait()

		end

	end
end)


local function UpdateMousePosition(mousePos)
	if not (moduleApiTable.Visible and moduleApiTable.IsCoreGuiEnabled and moduleApiTable.TopbarEnabled) then return end

	local windowPos = ChatWindow.GuiObject.AbsolutePosition
	local windowSize = ChatWindow.GuiObject.AbsoluteSize

	local newMouseState = CheckIfPointIsInSquare(mousePos, windowPos, windowPos + windowSize)
	if (newMouseState ~= mouseIsInWindow) then
		UpdateFadingForMouseState(newMouseState)
	end
end

UserInputService.InputChanged:connect(function(inputObject)
	if (inputObject.UserInputType == Enum.UserInputType.MouseMovement) then
		local mousePos = Vector2.new(inputObject.Position.X, inputObject.Position.Y)
		UpdateMousePosition(mousePos)
	end
end)

UserInputService.TouchTap:connect(function(tapPos, gameProcessedEvent)
	local last = mouseIsInWindow

	UpdateMousePosition(tapPos[1])
	if (not mouseIsInWindow  and last ~= mouseIsInWindow)  then
		DoBackgroundFadeOut()
	end
end)

--// Start and stop fading sequences / timers
UpdateFadingForMouseState(true)
UpdateFadingForMouseState(false)

ChatBar:GetTextBox().Focused:connect(function()
	if (not mouseIsInWindow) then
		DoBackgroundFadeIn()
		if (textIsFaded) then
			DoTextFadeIn()
		end
	end

	chatBarFocusChanged:Fire()
end)

ChatBar:GetTextBox().FocusLost:connect(function()
	DoBackgroundFadeIn()
	chatBarFocusChanged:Fire()
end)










--////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////// Code to hook client UI up to server events
--////////////////////////////////////////////////////////////////////////////////////////////
local didFirstChannelsLoads = false

local function DoChatBarFocus()
	if (not ChatWindow:GetCoreGuiEnabled()) then return end
	if (not ChatBar:GetEnabled()) then return end

	if (not ChatBar:IsFocused() and ChatBar:GetVisible()) then
		moduleApiTable:SetVisible(true)
		ChatBar:CaptureFocus()
		moduleApiTable.ChatBarFocusChanged:fire(true)
	end
end

--// Event for focusing the chat bar when player presses "/".
local ChatBarUISConnection = UserInputService.InputBegan:connect(function(input)
	if (input.KeyCode == Enum.KeyCode.Slash) then
		DoChatBarFocus()
	end
end)

-- Comment out this line to allow pressing the "/" key to chat.
ChatBarUISConnection:disconnect()


local function DoSwitchCurrentChannel(targetChannel)
	if (ChatWindow:GetChannel(targetChannel)) then
		ChatWindow:SwitchCurrentChannel(targetChannel)
	end
end


local function SendMessageToSelfInTargetChannel(message, channelName, extraData)
	local channelObj = ChatWindow:GetChannel(channelName)
	if (channelObj) then
		local messageData =
		{
			ID = -1,
			FromSpeaker = nil,
			OriginalChannel = channelName,
			IsFiltered = false,
			Message = message,
			Time = os.time(),
			ExtraData = extraData,
		}

		channelObj:AddMessageToChannel(messageData, "SystemMessage")
	end
end

local function ProcessChatCommands(message)
	local processedCommand = false

	if (string.sub(message, 1, 3) == "/c ") then
		message = string.sub(message, 4)
		processedCommand = true

		DoSwitchCurrentChannel(message)

		if (not ChatSettings.ShowChannelsBar) then
			local currentChannel = ChatWindow:GetCurrentChannel()
			if (currentChannel) then
				local switchToChannel = ChatWindow:GetChannel(message)
				if (switchToChannel) then
					SendMessageToSelfInTargetChannel(string.format("You are now chatting in channel: '%s'", message), currentChannel.Name, {})
				else
					SendMessageToSelfInTargetChannel(string.format("You are not in channel: '%s'", message), currentChannel.Name, {ChatColor = Color3.fromRGB(245, 50, 50)})
				end
			end
		end

	elseif (string.sub(message, 1, 4) == "/cls" or string.sub(message, 1, 6) == "/clear") then
		processedCommand = true

		local currentChannel = ChatWindow:GetCurrentChannel()
		if (currentChannel) then
			currentChannel:ClearMessageLog()
		end
	end

	--// This is the code that prevents Guests from chatting.
	--// Guests are generally not allowed to chat, so please do not remove this.
	if (LocalPlayer.UserId < 0) then
		processedCommand = true

		local channelObj = ChatWindow:GetCurrentChannel()
		if (channelObj) then
			SendMessageToSelfInTargetChannel("Create a free account to get access to chat permissions!", channelObj.Name, {})
		end
	end

	return processedCommand
end

--// Event for making player say chat message.
ChatBar:GetTextBox().FocusLost:connect(function(enterPressed, inputObject)
	if (enterPressed) then
		local message = string.sub(ChatBar:GetTextBox().Text, 1, ChatSettings.MaximumMessageLength)
		ChatBar:GetTextBox().Text = ""

		if (message ~= "" and not ProcessChatCommands(message)) then
			message = string.gsub(message, "\n", "")
			message = string.gsub(message, "[ ]+", " ")

			local targetChannel = ChatWindow:GetTargetMessageChannel()
			if (targetChannel) then
				MessageSender:SendMessage(message, targetChannel)

				if (targetChannel == ChatSettings.GeneralChannelName) then
					--// Sends signal to eventually call Player:Chat() to handle C++ side legacy stuff.
					moduleApiTable.MessagePosted:fire(message)
				end
			else
				MessageSender:SendMessage(message, nil)

			end
		end

	end
end)

EventFolder.OnNewMessage.OnClientEvent:connect(function(messageData, channelName)
	local channelObj = ChatWindow:GetChannel(channelName)
	if (channelObj) then
		channelObj:AddMessageToChannel(messageData, "Message")

		if (messageData.FromSpeaker ~= LocalPlayer.Name) then
			ChannelsBar:UpdateMessagePostedInChannel(channelName)
		end

		local generalChannel = nil
		if (ChatSettings.GeneralChannelName and channelName ~= ChatSettings.GeneralChannelName) then
			generalChannel = ChatWindow:GetChannel(ChatSettings.GeneralChannelName)
			if (generalChannel) then
				generalChannel:AddMessageToChannel(messsageData, "ChannelEchoMessage")
			end
		end

		moduleApiTable.MessageCount = moduleApiTable.MessageCount + 1
		moduleApiTable.MessagesChanged:fire(moduleApiTable.MessageCount)

		DoFadeInFromNewInformation()

		local filterData = {}
		while (filterData.ID ~= messageData.ID) do
			filterData = EventFolder.OnMessageDoneFiltering.OnClientEvent:wait()
		end

		--// Speaker may leave these channels during the time it takes to filter.
		if (not channelObj.Destroyed) then
			channelObj:UpdateMessageFiltered(filterData)
		end

		if (generalChannel and not generalChannel.Destroyed) then
			generalChannel:UpdateMessageFiltered(filterData)
		end
	else
		warn(string.format("Just received chat message for channel I'm not in [%s]", channelName))
	end
end)

EventFolder.OnNewSystemMessage.OnClientEvent:connect(function(messageData, channelName)
	channelName = channelName or "System"

	local channelObj = ChatWindow:GetChannel(channelName)
	if (channelObj) then
		channelObj:AddMessageToChannel(messageData, "SystemMessage")

		ChannelsBar:UpdateMessagePostedInChannel(channelName)

		moduleApiTable.MessageCount = moduleApiTable.MessageCount + 1
		moduleApiTable.MessagesChanged:fire(moduleApiTable.MessageCount)

		DoFadeInFromNewInformation()

		if (ChatSettings.GeneralChannelName and channelName ~= ChatSettings.GeneralChannelName) then
			local generalChannel = ChatWindow:GetChannel(ChatSettings.GeneralChannelName)
			if (generalChannel) then
				generalChannel:AddMessageToChannel(messageData, "ChannelEchoSystemMessage")
			end
		end
	else
		warn(string.format("Just received system message for channel I'm not in [%s]", channelName))
	end
end)


local function HandleChannelJoined(channel, welcomeMessage, messageLog)
	if (channel == ChatSettings.GeneralChannelName) then
		didFirstChannelsLoads = true
	end

	local channelObj = ChatWindow:AddChannel(channel)

	if (channelObj) then
		if (channel == "All") then
			DoSwitchCurrentChannel(channel)
		end

		if (messageLog) then
			for i, messageLogData in pairs(messageLog) do

				if (messageLogData.FromSpeaker) then
					channelObj:AddMessageToChannel(messageLogData, "Message")
				else
					channelObj:AddMessageToChannel(messageLogData, "SystemMessage")
				end

				channelObj:UpdateMessageFiltered(messageLogData)
			end
		end

		if (welcomeMessage ~= "") then
			channelObj:AddMessageToChannel(welcomeMessage, "WelcomeMessage")
		end

		DoFadeInFromNewInformation()
	end

end

EventFolder.OnChannelJoined.OnClientEvent:connect(HandleChannelJoined)

EventFolder.OnChannelLeft.OnClientEvent:connect(function(channel)
	ChatWindow:RemoveChannel(channel)

	DoFadeInFromNewInformation()
end)

EventFolder.OnMuted.OnClientEvent:connect(function(channel)
	--// Do something eventually maybe?
	--// This used to take away the chat bar in channels the player was muted in.
	--// We found out this behavior was inconvenient for doing chat commands though.
end)

EventFolder.OnUnmuted.OnClientEvent:connect(function(channel)
	--// Same as above.
end)

EventFolder.OnMainChannelSet.OnClientEvent:connect(function(channel)
	DoSwitchCurrentChannel(channel)
end)



local reparentingLock = false
local function connectGuiParent(GuiParent)
	local DestroyGuardFrame = Instance.new("Frame")
	DestroyGuardFrame.Name = "DestroyGuardFrame"
	DestroyGuardFrame.BackgroundTransparency = 1
	DestroyGuardFrame.Size = UDim2.new(1, 0, 1, 0)
	DestroyGuardFrame.Parent = GuiParent

	for i, v in pairs(GuiParent:GetChildren()) do
		if (v ~= DestroyGuardFrame) then
			v.Parent = DestroyGuardFrame
		end
	end

end

connectGuiParent(GuiParent)

GuiParent.Changed:connect(function(prop)
	if (prop == "Parent" and not reparentingLock) then
		reparentingLock = true

		local children = GuiParent.DestroyGuardFrame:GetChildren()
		for i, v in pairs(children) do
			v.Parent = nil
		end

		LocalPlayer.CharacterAdded:wait()
		GuiParent.Parent = PlayerGui

		for i, v in pairs(children) do
			v.Parent = GuiParent
		end

		connectGuiParent(GuiParent)

		reparentingLock = false
	end
end)

--// Always on top behavior that relies on parenting order of ScreenGuis
--// This would end up really bad if something else tried to do the exact same thing however.
PlayerGui.ChildAdded:connect(function(child)
	if (child ~= GuiParent and not reparentingLock) then
		reparentingLock = true

		GuiParent.Parent = nil
		RunService.RenderStepped:wait()
		GuiParent.Parent = PlayerGui

		reparentingLock = false
	end
end)


local initData = EventFolder.GetInitDataRequest:InvokeServer()

for i, channelData in pairs(initData.Channels) do
	HandleChannelJoined(unpack(channelData))
end








--////////////////////////////////////////////////////////////////////////////////////////////
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
	ChatWindow:SetVisible(val)
	moduleApiTable.VisibilityStateChanged:fire(val)
	moduleApiTable.Visible = val

	if (moduleApiTable.IsCoreGuiEnabled) then
		if (val) then
			InstantFadeIn()
		else
			InstantFadeOut()
		end
	end
end

do
	moduleApiTable.TopbarEnabled = true
	moduleApiTable.MessageCount = 0
	moduleApiTable.Visible = true
	moduleApiTable.IsCoreGuiEnabled = true

	function moduleApiTable:ToggleVisibility()
		SetVisibility(not ChatWindow:GetVisible())
	end

	function moduleApiTable:SetVisible(visible)
		if (ChatWindow:GetVisible() ~= visible) then
			SetVisibility(visible)
		end
	end

	function moduleApiTable:FocusChatBar()
		ChatBar:CaptureFocus()
	end

	function moduleApiTable:GetVisibility()
		return ChatWindow:GetVisible()
	end

	function moduleApiTable:GetMessageCount()
		return self.MessageCount
	end

	function moduleApiTable:TopbarEnabledChanged(enabled)
		self.TopbarEnabled = enabled
		self.CoreGuiEnabled:fire(game:GetService("StarterGui"):GetCoreGuiEnabled(Enum.CoreGuiType.Chat))
	end

	function moduleApiTable:IsFocused(useWasFocused)
		return ChatBar:IsFocused()
	end

	moduleApiTable.ChatBarFocusChanged = Util.Signal()
	moduleApiTable.VisibilityStateChanged = Util.Signal()
	moduleApiTable.MessagesChanged = Util.Signal()


	moduleApiTable.MessagePosted = Util.Signal()
	moduleApiTable.CoreGuiEnabled = Util.Signal()

	moduleApiTable.ChatMakeSystemMessageEvent = Util.Signal()
	moduleApiTable.ChatWindowPositionEvent = Util.Signal()
	moduleApiTable.ChatWindowSizeEvent = Util.Signal()
	moduleApiTable.ChatBarDisabledEvent = Util.Signal()


	function moduleApiTable:fChatWindowPosition()
		return ChatWindow.GuiObject.Position
	end

	function moduleApiTable:fChatWindowSize()
		return ChatWindow.GuiObject.Size
	end

	function moduleApiTable:fChatBarDisabled()
		return not ChatBar:GetEnabled()
	end



	function moduleApiTable:SpecialKeyPressed(key, modifiers)
		if (key == Enum.SpecialKey.ChatHotkey) then
			DoChatBarFocus()
		end
	end
end

spawn(function() moduleApiTable:SetVisible(false) moduleApiTable:SetVisible(true) end)

moduleApiTable.CoreGuiEnabled:connect(function(enabled)
	moduleApiTable.IsCoreGuiEnabled = enabled
	DealWithCoreGuiEnabledChanged(moduleApiTable.IsCoreGuiEnabled)

	enabled = enabled and moduleApiTable.TopbarEnabled

	ChatWindow:SetCoreGuiEnabled(enabled)

	if (not enabled) then
		ChatBar:ReleaseFocus()
		InstantFadeOut()
	else
		InstantFadeIn()
	end
end)

moduleApiTable.ChatMakeSystemMessageEvent:connect(function(valueTable)
	if (valueTable["Text"] and type(valueTable["Text"]) == "string") then
		while (not didFirstChannelsLoads) do wait() end

		local channel = ChatSettings.GeneralChannelName
		local channelObj = ChatWindow:GetChannel(channel)

		if (channelObj) then
			channelObj:AddMessageToChannel(valueTable, "SetCoreMessage")
			ChannelsBar:UpdateMessagePostedInChannel(channel)

			moduleApiTable.MessageCount = moduleApiTable.MessageCount + 1
			moduleApiTable.MessagesChanged:fire(moduleApiTable.MessageCount)
		end
	end
end)

moduleApiTable.ChatBarDisabledEvent:connect(function(disabled)
	ChatBar:SetEnabled(not disabled)
	if (disabled) then
		ChatBar:ReleaseFocus()
	end
end)

return moduleApiTable
