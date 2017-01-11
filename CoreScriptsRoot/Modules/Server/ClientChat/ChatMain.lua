--	// FileName: ChatMain.lua
--	// Written by: Xsitsu
--	// Description: Main module to handle initializing chat window UI and hooking up events to individual UI pieces.

local moduleApiTable = {}

--// This section of code waits until all of the necessary RemoteEvents are found in EventFolder.
--// I have to do some weird stuff since people could potentially already have pre-existing
--// things in a folder with the same name, and they may have different class types.
--// I do the useEvents thing and set EventFolder to useEvents so I can have a pseudo folder that
--// the rest of the code can interface with and have the guarantee that the RemoteEvents they want
--// exist with their desired names.

local FILTER_MESSAGE_TIMEOUT = 60

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Chat = game:GetService("Chat")

local EventFolder = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents")
local clientChatModules = Chat:WaitForChild("ClientChatModules")
local ChatConstants = require(clientChatModules:WaitForChild("ChatConstants"))
local messageCreatorModules = clientChatModules:WaitForChild("MessageCreatorModules")
local MessageCreatorUtil = require(messageCreatorModules:WaitForChild("Util"))

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

function TryRemoveChildWithVerifyingIsCorrectType(child)
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

while not LocalPlayer do
	Players.ChildAdded:wait()
	LocalPlayer = Players.LocalPlayer
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local GuiParent = Instance.new("ScreenGui")
GuiParent.Name = "Chat"
GuiParent.Parent = PlayerGui

local DidFirstChannelsLoads = false

local modulesFolder = script

local moduleChatWindow = require(modulesFolder:WaitForChild("ChatWindow"))
local moduleChatBar = require(modulesFolder:WaitForChild("ChatBar"))
local moduleChannelsBar = require(modulesFolder:WaitForChild("ChannelsBar"))
local moduleMessageLabelCreator = require(modulesFolder:WaitForChild("MessageLabelCreator"))
local moduleMessageLogDisplay = require(modulesFolder:WaitForChild("MessageLogDisplay"))
local moduleChatChannel = require(modulesFolder:WaitForChild("ChatChannel"))
local moduleCommandProcessor = require(modulesFolder:WaitForChild("CommandProcessor"))

moduleMessageLabelCreator:RegisterGuiRoot(GuiParent)

local ChatWindow = moduleChatWindow.new()
local ChannelsBar = moduleChannelsBar.new()
local MessageLogDisplay = moduleMessageLogDisplay.new()
local CommandProcessor = moduleCommandProcessor.new()
local ChatBar = moduleChatBar.new(CommandProcessor, ChatWindow)

ChatWindow:CreateGuiObjects(GuiParent)

ChatWindow:RegisterChatBar(ChatBar)
ChatWindow:RegisterChannelsBar(ChannelsBar)
ChatWindow:RegisterMessageLogDisplay(MessageLogDisplay)

MessageCreatorUtil:RegisterChatWindow(ChatWindow)

local Chat = game:GetService("Chat")
local clientChatModules = Chat:WaitForChild("ClientChatModules")
local ChatSettings = require(clientChatModules:WaitForChild("ChatSettings"))

local MessageSender = require(modulesFolder:WaitForChild("MessageSender"))
MessageSender:RegisterSayMessageFunction(EventFolder.SayMessageRequest)



if (UserInputService.TouchEnabled) then
	ChatBar:SetTextLabelText('Tap here to chat')
else
	ChatBar:SetTextLabelText('To chat click here or press "/" key')
end

spawn(function()
	local CurveUtil = require(modulesFolder:WaitForChild("CurveUtil"))
	local animationFps = ChatSettings.ChatAnimationFPS or 20.0

	local updateWaitTime = 1.0 / animationFps
	local lastTick = tick()
	while true do
		local currentTick = tick()
		local tickDelta = currentTick - lastTick
		local dtScale = CurveUtil:DeltaTimeToTimescale(tickDelta)

		if dtScale ~= 0 then
			ChatWindow:Update(dtScale)
		end

		lastTick = currentTick
		wait(updateWaitTime)
	end
end)




--////////////////////////////////////////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////// Code to do chat window fading
--////////////////////////////////////////////////////////////////////////////////////////////
function CheckIfPointIsInSquare(checkPos, topLeft, bottomRight)
	return (topLeft.X <= checkPos.X and checkPos.X <= bottomRight.X and
		topLeft.Y <= checkPos.Y and checkPos.Y <= bottomRight.Y)
end

local backgroundIsFaded = false
local textIsFaded = false
local lastTextFadeTime = 0
local lastBackgroundFadeTime = 0

local fadedChanged = Instance.new("BindableEvent")
local mouseStateChanged = Instance.new("BindableEvent")
local chatBarFocusChanged = Instance.new("BindableEvent")

function DoBackgroundFadeIn(setFadingTime)
	lastBackgroundFadeTime = tick()
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

function DoBackgroundFadeOut(setFadingTime)
	lastBackgroundFadeTime = tick()
	backgroundIsFaded = true
	fadedChanged:Fire()
	ChatWindow:DisableResizable()
	ChatWindow:FadeOutBackground((setFadingTime or ChatSettings.ChatDefaultFadeDuration))

	local currentChannelObject = ChatWindow:GetCurrentChannel()
	if (currentChannelObject) then
		ChatWindow.GuiObject.Active = false
		--ChatWindow:ResetResizerPosition()

		local Scroller = MessageLogDisplay.Scroller
		Scroller.ScrollingEnabled = false
		Scroller.ScrollBarThickness = 0
	end
end

function DoTextFadeIn(setFadingTime)
	lastTextFadeTime = tick()
	textIsFaded = false
	fadedChanged:Fire()
	ChatWindow:FadeInText((setFadingTime or ChatSettings.ChatDefaultFadeDuration) * 0)
end

function DoTextFadeOut(setFadingTime)
	lastTextFadeTime = tick()
	textIsFaded = true
	fadedChanged:Fire()
	ChatWindow:FadeOutText((setFadingTime or ChatSettings.ChatDefaultFadeDuration))
end

function DoFadeInFromNewInformation()
	DoTextFadeIn()
	if ChatSettings.ChatShouldFadeInFromNewInformation then
		DoBackgroundFadeIn()
	end
end

function InstantFadeIn()
	DoBackgroundFadeIn(0)
	DoTextFadeIn(0)
end

function InstantFadeOut()
	DoBackgroundFadeOut(0)
	DoTextFadeOut(0)
end

local mouseIsInWindow = nil
function UpdateFadingForMouseState(mouseState)
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

		if (not backgroundIsFaded) then
			local timeDiff = tick() - lastBackgroundFadeTime
			if (timeDiff > ChatSettings.ChatWindowBackgroundFadeOutTime) then
				DoBackgroundFadeOut()
			end

		elseif (not textIsFaded) then
			local timeDiff = tick() - lastTextFadeTime
			if (timeDiff > ChatSettings.ChatWindowTextFadeOutTime) then
				DoTextFadeOut()
			end

		else
			fadedChanged.Event:wait()

		end

	end
end)

function bubbleChatOnly()
 	return not Players.ClassicChat and Players.BubbleChat
end

function UpdateMousePosition(mousePos)
	if not (moduleApiTable.Visible and moduleApiTable.IsCoreGuiEnabled and (moduleApiTable.TopbarEnabled or ChatSettings.ChatOnWithTopBarOff)) then return end

	if bubbleChatOnly() then
		return
	end

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
	if (not mouseIsInWindow and last ~= mouseIsInWindow) then
		DoBackgroundFadeOut()
	end
end)

--// Start and stop fading sequences / timers
UpdateFadingForMouseState(true)
UpdateFadingForMouseState(false)


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


function SetVisibility(val)
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

	enabled = enabled and (moduleApiTable.TopbarEnabled or ChatSettings.ChatOnWithTopBarOff)

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
		while (not DidFirstChannelsLoads) do wait() end

		local channel = ChatSettings.GeneralChannelName
		local channelObj = ChatWindow:GetChannel(channel)

		if (channelObj) then
			local messageObject = {
				ID = -1,
				FromSpeaker = nil,
				OriginalChannel = channel,
				IsFiltered = true,
				MessageLength = string.len(valueTable.Text),
				Message = valueTable.Text,
				MessageType = ChatConstants.MessageTypeSetCore,
				Time = os.time(),
				ExtraData = valueTable,
			}
			channelObj:AddMessageToChannel(messageObject)
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

moduleApiTable.ChatWindowSizeEvent:connect(function(size)
	ChatWindow.GuiObject.Size = size
end)

moduleApiTable.ChatWindowPositionEvent:connect(function(position)
	ChatWindow.GuiObject.Position = position
end)

--////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////// Code to hook client UI up to server events
--////////////////////////////////////////////////////////////////////////////////////////////

function DoChatBarFocus()
	if (not ChatWindow:GetCoreGuiEnabled()) then return end
	if (not ChatBar:GetEnabled()) then return end

	if (not ChatBar:IsFocused() and ChatBar:GetVisible()) then
		moduleApiTable:SetVisible(true)
		ChatBar:CaptureFocus()
		moduleApiTable.ChatBarFocusChanged:fire(true)
	end
end

chatBarFocusChanged.Event:connect(function(focused)
	moduleApiTable.ChatBarFocusChanged:fire(focused)
end)

function DoSwitchCurrentChannel(targetChannel)
	if (ChatWindow:GetChannel(targetChannel)) then
		ChatWindow:SwitchCurrentChannel(targetChannel)
	end
end

function SendMessageToSelfInTargetChannel(message, channelName, extraData)
	local channelObj = ChatWindow:GetChannel(channelName)
	if (channelObj) then
		local messageData =
		{
			ID = -1,
			FromSpeaker = nil,
			OriginalChannel = channelName,
			IsFiltered = true,
			MessageLength = string.len(message),
			Message = message,
			MessageType = ChatConstants.MessageTypeSystem,
			Time = os.time(),
			ExtraData = extraData,
		}

		channelObj:AddMessageToChannel(messageData)
	end
end

function chatBarFocused()
	if (not mouseIsInWindow) then
		DoBackgroundFadeIn()
		if (textIsFaded) then
			DoTextFadeIn()
		end
	end

	chatBarFocusChanged:Fire(true)
end

--// Event for making player say chat message.
function chatBarFocusLost(enterPressed, inputObject)
	DoBackgroundFadeIn()
	chatBarFocusChanged:Fire(false)

	if (enterPressed) then
		local message = ChatBar:GetTextBox().Text

		if ChatBar:IsInCustomState() then
			local customMessage = ChatBar:GetCustomMessage()
			if customMessage then
				message = customMessage
			end
			local messageSunk = ChatBar:CustomStateProcessCompletedMessage(message)
			ChatBar:ResetCustomState()
			if messageSunk then
				return
			end
		end

		message = string.sub(message, 1, ChatSettings.MaximumMessageLength)

		ChatBar:GetTextBox().Text = ""

		if message ~= "" then
			--// Sends signal to eventually call Player:Chat() to handle C++ side legacy stuff.
			moduleApiTable.MessagePosted:fire(message)

			if not CommandProcessor:ProcessCompletedChatMessage(message, ChatWindow) then
				if ChatSettings.DisallowedWhiteSpace then
					for i = 1, #ChatSettings.DisallowedWhiteSpace do
						message = string.gsub(message, ChatSettings.DisallowedWhiteSpace[i], "")
					end
				end
				message = string.gsub(message, "\n", "")
				message = string.gsub(message, "[ ]+", " ")

				local targetChannel = ChatWindow:GetTargetMessageChannel()
				if targetChannel then
					MessageSender:SendMessage(message, targetChannel)
				else
					MessageSender:SendMessage(message, nil)
				end
			end
		end

	end
end

local ChatBarConnections = {}
function setupChatBarConnections()
	for i = 1, #ChatBarConnections do
		ChatBarConnections[i]:Disconnect()
	end
	ChatBarConnections = {}

	local focusLostConnection = ChatBar:GetTextBox().FocusLost:connect(chatBarFocusLost)
	table.insert(ChatBarConnections, focusLostConnection)

	local focusGainedConnection = ChatBar:GetTextBox().Focused:connect(chatBarFocused)
	table.insert(ChatBarConnections, focusGainedConnection)
end

setupChatBarConnections()
ChatBar.GuiObjectsChanged:connect(setupChatBarConnections)

-- Wrap the OnMessageDoneFiltering event so that we do not back up the remote event invocation queue.
-- This is in cases where we are sent OnMessageDoneFiltering events but we have stopped listening/timed out.
-- BindableEvents do not queue, while RemoteEvents do.
local FilteredMessageReceived = Instance.new("BindableEvent")
EventFolder.OnMessageDoneFiltering.OnClientEvent:connect(function(messageData)
	FilteredMessageReceived:Fire(messageData)
end)

EventFolder.OnNewMessage.OnClientEvent:connect(function(messageData, channelName)
	local channelObj = ChatWindow:GetChannel(channelName)
	if (channelObj) then
		channelObj:AddMessageToChannel(messageData)

		if (messageData.FromSpeaker ~= LocalPlayer.Name) then
			ChannelsBar:UpdateMessagePostedInChannel(channelName)
		end

		local generalChannel = nil
		if (ChatSettings.GeneralChannelName and channelName ~= ChatSettings.GeneralChannelName) then
			generalChannel = ChatWindow:GetChannel(ChatSettings.GeneralChannelName)
			if (generalChannel) then
				generalChannel:AddMessageToChannel(messageData)
			end
		end

		moduleApiTable.MessageCount = moduleApiTable.MessageCount + 1
		moduleApiTable.MessagesChanged:fire(moduleApiTable.MessageCount)

		DoFadeInFromNewInformation()

		if messageData.IsFiltered and not (messageData.FromSpeaker == LocalPlayer.Name) then
			return
		end

		if not ChatSettings.ShowUserOwnFilteredMessage then
			if (messageData.FromSpeaker == LocalPlayer.Name) then
				return
			end
		end

		local filterData = {}
		local filterWaitStartTime = tick()
		while (filterData.ID ~= messageData.ID) do
			if tick() - filterWaitStartTime > FILTER_MESSAGE_TIMEOUT then
				return
			end
			filterData = FilteredMessageReceived.Event:wait()
		end

		--// Speaker may leave these channels during the time it takes to filter.
		if (not channelObj.Destroyed) then
			channelObj:UpdateMessageFiltered(filterData)
		end

		if (generalChannel and not generalChannel.Destroyed) then
			generalChannel:UpdateMessageFiltered(filterData)
		end
	end
end)

EventFolder.OnNewSystemMessage.OnClientEvent:connect(function(messageData, channelName)
	channelName = channelName or "System"

	local channelObj = ChatWindow:GetChannel(channelName)
	if (channelObj) then
		channelObj:AddMessageToChannel(messageData)

		ChannelsBar:UpdateMessagePostedInChannel(channelName)

		moduleApiTable.MessageCount = moduleApiTable.MessageCount + 1
		moduleApiTable.MessagesChanged:fire(moduleApiTable.MessageCount)

		DoFadeInFromNewInformation()

		if (ChatSettings.GeneralChannelName and channelName ~= ChatSettings.GeneralChannelName) then
			local generalChannel = ChatWindow:GetChannel(ChatSettings.GeneralChannelName)
			if (generalChannel) then
				generalChannel:AddMessageToChannel(messageData)
			end
		end
	else
		warn(string.format("Just received system message for channel I'm not in [%s]", channelName))
	end
end)


function HandleChannelJoined(channel, welcomeMessage, messageLog)
	if (channel == ChatSettings.GeneralChannelName) then
		DidFirstChannelsLoads = true
	end

	local channelObj = ChatWindow:AddChannel(channel)

	if (channelObj) then
		if (channel == "All") then
			DoSwitchCurrentChannel(channel)
		end

		if (messageLog) then
			local startIndex = 1
			if #messageLog > ChatSettings.MessageHistoryLengthPerChannel then
				startIndex = #messageLog - ChatSettings.MessageHistoryLengthPerChannel
			end
			for i = startIndex, #messageLog do
				channelObj:AddMessageToChannel(messageLog[i])
			end
		end

		if (welcomeMessage ~= "") then
			local welcomeMessageObject = {
				ID = -1,
				FromSpeaker = nil,
				OriginalChannel = channel,
				IsFiltered = true,
				MessageLength = string.len(welcomeMessage),
				Message = welcomeMessage,
				MessageType = ChatConstants.MessageTypeWelcome,
				Time = os.time(),
				ExtraData = nil,
			}
			channelObj:AddMessageToChannel(welcomeMessageObject)
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
function connectGuiParent(GuiParent)
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

local ChatBarFocusedState = nil

--// Always on top behavior that relies on parenting order of ScreenGuis
--// This would end up really bad if something else tried to do the exact same thing however.
PlayerGui.ChildAdded:connect(function(child)
	if (child ~= GuiParent and not reparentingLock) then
		reparentingLock = true

		GuiParent.Parent = nil
		RunService.RenderStepped:wait()
		GuiParent.Parent = PlayerGui

		reparentingLock = false
	elseif child == GuiParent then
		if ChatBarFocusedState then
			RunService.RenderStepped:wait()
			ChatBar:RestoreFocusedState(ChatBarFocusedState)
		end
	end
end)

PlayerGui.DescendantRemoving:connect(function(descendant)
	if descendant == GuiParent then
		ChatBarFocusedState = ChatBar:GetFocusedState()
	end
end)


local initData = EventFolder.GetInitDataRequest:InvokeServer()

for i, channelData in pairs(initData.Channels) do
	HandleChannelJoined(unpack(channelData))
end

return moduleApiTable
