local source = [[
local moduleApiTable = {}

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local EventFolder = game:GetService("ReplicatedStorage"):WaitForChild("ChatEvents")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local GuiParent = Instance.new("ScreenGui", PlayerGui)
GuiParent.Name = "Chat"

local modulesFolder = script

local moduleChatWindow = require(modulesFolder:WaitForChild("ChatWindow"))
local moduleChatBar = require(modulesFolder:WaitForChild("ChatBar"))
local moduleChannelsBar = require(modulesFolder:WaitForChild("ChannelsBar"))
local moduleSpeakerDatabase = require(modulesFolder:WaitForChild("SpeakerDatabase"))
local moduleMessageLabelCreator = require(modulesFolder:WaitForChild("MessageLabelCreator"))
local moduleChatChannel = require(modulesFolder:WaitForChild("ChatChannel"))

moduleMessageLabelCreator:RegisterGuiRoot(GuiParent)

local ChatWindow = moduleChatWindow.new()
local ChatBar = moduleChatBar.new()
local ChannelsBar = moduleChannelsBar.new()

ChatWindow:RegisterChatBar(ChatBar)
ChatWindow:RegisterChannelsBar(ChannelsBar)
ChatWindow.GuiObject.Parent = GuiParent

local SpeakerDatabase = moduleSpeakerDatabase.new()
local MessageLabelCreator = moduleMessageLabelCreator.new()
MessageLabelCreator:RegisterSpeakerDatabase(SpeakerDatabase)










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
local backgroundFadeTimer = 1
local textFadeTimer = 10

local fadedChanged = Instance.new("BindableEvent")
local mouseStateChanged = Instance.new("BindableEvent")
local chatBarFocusChanged = Instance.new("BindableEvent")

local defaultFadingTime = 0.5

local function DoBackgroundFadeIn(setFadingTime)
	lastFadeTime = tick()
	backgroundIsFaded = false
	fadedChanged:Fire()
	ChatWindow:FadeInBackground((setFadingTime or defaultFadingTime))

	if (ChatWindow:GetCurrentChannel()) then
		local Scroller = ChatWindow:GetCurrentChannel().Scroller
		Scroller.ScrollingEnabled = true
		Scroller.ScrollBarThickness = moduleChatChannel.ScrollBarThickness
	end
end

local function DoBackgroundFadeOut(setFadingTime)
	lastFadeTime = tick()
	backgroundIsFaded = true
	fadedChanged:Fire()
	ChatWindow:FadeOutBackground((setFadingTime or defaultFadingTime))

	if (ChatWindow:GetCurrentChannel()) then
		local Scroller = ChatWindow:GetCurrentChannel().Scroller
		scrollBarThickness = Scroller.ScrollBarThickness
		Scroller.ScrollingEnabled = false
		Scroller.ScrollBarThickness = 0
	end
end

local function DoTextFadeIn(setFadingTime)
	lastFadeTime = tick()
	textIsFaded = false
	fadedChanged:Fire()
	ChatWindow:FadeInText((setFadingTime or defaultFadingTime) * 0)
end

local function DoTextFadeOut(setFadingTime)
	lastFadeTime = tick()
	textIsFaded = true
	fadedChanged:Fire()
	ChatWindow:FadeOutText((setFadingTime or defaultFadingTime))
end

local function DoFadeInFromNewInformation()
	DoTextFadeIn()
	DoBackgroundFadeIn()
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
			if (timeDiff > backgroundFadeTimer) then
				DoBackgroundFadeOut()
			end

		elseif (not textIsFaded) then
			if (timeDiff > textFadeTimer) then
				DoTextFadeOut()
			end

		else
			fadedChanged.Event:wait()

		end

	end
end)


local function UpdateMousePosition(mousePos)
	if (not moduleApiTable.Visible or not moduleApiTable.IsCoreGuiEnabled) then return end

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
local function ProcessChatCommands(message)
	local processedCommand = false

	if (string.sub(message, 1, 3) == "/c ") then
		message = string.sub(message, 4)
		processedCommand = true

		if (ChatWindow:GetChannel(message)) then
			ChatWindow:SwitchCurrentChannel(message)
		end
	end 

	return processedCommand
end

--// Event for making player say chat message.
ChatBar:GetTextBox().FocusLost:connect(function(enterPressed, inputObject)
	if (enterPressed) then
		local message = string.sub(ChatBar:GetTextBox().Text, 1, 300) -- max of something whenever
		ChatBar:GetTextBox().Text = ""
		
		if (message ~= "" and not ProcessChatCommands(message)) then
			--// Sends signal to eventually call Player:Chat() to handle C++ side legacy stuff.
			moduleApiTable.MessagePosted:fire(message) 
			
			local currentChannel = ChatWindow:GetCurrentChannel()
			if (currentChannel) then
				EventFolder.SayMessageRequest:FireServer(message, currentChannel.Name)
			else
				EventFolder.SayMessageRequest:FireServer(message, nil)
			end
		end
		
	end
end)

--// Event for focusing the chat bar when player presses "/".
UserInputService.InputBegan:connect(function(input)
	if (not ChatWindow:GetCoreGuiEnabled()) then return end
	if (not ChatBar:GetEnabled()) then return end
	
	if (input.KeyCode == Enum.KeyCode.Slash and not ChatBar:IsFocused() and ChatBar:GetVisible()) then
		moduleApiTable:SetVisible(true)
		ChatBar:CaptureFocus()
		moduleApiTable.ChatBarFocusChanged:fire(true)
	end
end)

EventFolder.OnNewMessage.OnClientEvent:connect(function(fromSpeaker, channel, message)
	local channelObj = ChatWindow:GetChannel(channel)
	if (channelObj) then
		local baseFrame, baseMessage = MessageLabelCreator:CreateMessageLabel(fromSpeaker, message)
		channelObj:AddMessageLabelToLog(baseFrame, baseMessage)
		
		ChannelsBar:UpdateMessagePostedInChannel(channel)
		
		moduleApiTable.MessageCount = moduleApiTable.MessageCount + 1
		moduleApiTable.MessagesChanged:fire(moduleApiTable.MessageCount)

		DoFadeInFromNewInformation()

	else
		warn("Just received chat message for channel I'm not in [" .. channel .. "]")
		
	end
end)

EventFolder.OnNewSystemMessage.OnClientEvent:connect(function(message, channel)
	channel = channel or "System"
	
	local channelObj = ChatWindow:GetChannel(channel)
	if (channelObj) then
		local baseFrame, baseMessage = MessageLabelCreator:CreateSystemMessageLabel(message)
		channelObj:AddMessageLabelToLog(baseFrame, baseMessage)
		
		ChannelsBar:UpdateMessagePostedInChannel(channel)
		
		moduleApiTable.MessageCount = moduleApiTable.MessageCount + 1
		moduleApiTable.MessagesChanged:fire(moduleApiTable.MessageCount)

		DoFadeInFromNewInformation()

	else
		warn("Just received system message for channel I'm not in [" .. channel .. "]")
		
	end
end)

EventFolder.OnChannelJoined.OnClientEvent:connect(function(channel, welcomeMessage)
	local channelObj = ChatWindow:AddChannel(channel)
	
	if (channel == "All") then
		ChatWindow:SwitchCurrentChannel(channel)
	end
	
	if (welcomeMessage ~= "") then
		local baseFrame, baseMessage = MessageLabelCreator:CreateWelcomeMessageLabel(welcomeMessage)
		channelObj:AddMessageLabelToLog(baseFrame, baseMessage)
	end

	DoFadeInFromNewInformation()
end)

EventFolder.OnChannelLeft.OnClientEvent:connect(function(channel)
	ChatWindow:RemoveChannel(channel)

	DoFadeInFromNewInformation()
end)

EventFolder.OnMuted.OnClientEvent:connect(function(channel)
	-- handle
end)

EventFolder.OnUnmuted.OnClientEvent:connect(function(channel)
	-- handle
end)

EventFolder.OnSpeakerExtraDataUpdated.OnClientEvent:connect(function(speakerName, data)
	local speaker = SpeakerDatabase:GetSpeaker(speakerName)
	if (not speaker) then
		speaker = SpeakerDatabase:AddSpeaker(speakerName)
	end
	
	for k, v in pairs(data) do
		speaker[k] = v
	end
end)


local reparentingLock = false

--// Do not remove on death behavior
LocalPlayer.CharacterRemoving:connect(function()
	if (reparentingLock) then return end

	GuiParent.Parent = nil
	LocalPlayer.CharacterAdded:wait()
	GuiParent.Parent = PlayerGui
end)

--// Always on top behavior that relies on parenting order of ScreenGuis
--// This would end up really bad if something else tried to do the 
--// exact same thing however.
GuiParent.Parent.ChildAdded:connect(function(child)
	if (child ~= GuiParent) then
		reparentingLock = true

		GuiParent.Parent = nil
		RunService.RenderStepped:wait()
		GuiParent.Parent = PlayerGui

		reparentingLock = false
	end
end)


EventFolder.GetInitDataRequest:FireServer()










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
		return UDim2.new(0, 0, 0, 0) --ChatWindow.Frame.Dragger.Position
	end
	
	function moduleApiTable:fChatWindowSize()
		return UDim2.new(0, 0, 0, 0) --ChatWindow.Frame.Dragger.Size
	end
	
	function moduleApiTable:fChatBarDisabled()
		return not ChatBar:GetEnabled()
	end
end

spawn(function() wait() moduleApiTable:SetVisible(false) moduleApiTable:SetVisible(true) end)

moduleApiTable.CoreGuiEnabled:connect(function(enabled)
	moduleApiTable.IsCoreGuiEnabled = enabled
	DealWithCoreGuiEnabledChanged(moduleApiTable.IsCoreGuiEnabled)

	enabled = enabled and moduleApiTable.TopbarEnabled

	ChatWindow:SetCoreGuiEnabled(enabled)
	if (not enabled) then
		ChatBar:ReleaseFocus()
	end
end)

moduleApiTable.ChatMakeSystemMessageEvent:connect(function(valueTable)
	if (valueTable["Text"] and type(valueTable["Text"]) == "string") then
		local channel = "All"
		local channelObj = ChatWindow:GetChatChannel(channel)
		if (channelObj) then
			local message = valueTable["Text"]
			
			local messageLabel = MessageLabelCreator:CreateSystemMessageLabel(message)
			channelObj:AddMessageLabelToLog(messageLabel)
			
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
]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script