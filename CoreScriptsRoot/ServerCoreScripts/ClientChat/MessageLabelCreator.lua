local source = [[
--	// FileName: MessageLabelCreator.lua
--	// Written by: Xsitsu
--	// Description: Module to handle taking text and creating stylized GUI objects for display in ChatWindow.

local module = {}
--////////////////////////////// Include
--//////////////////////////////////////
local modulesFolder = script.Parent
local moduleTransparencyTweener = require(modulesFolder:WaitForChild("TransparencyTweener"))
local ChatSettings = require(modulesFolder:WaitForChild("ChatSettings"))
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))
local MessageSender = require(modulesFolder:WaitForChild("MessageSender"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

local testLabel = Instance.new("TextLabel")
testLabel.Selectable = false
testLabel.TextWrapped  = true
testLabel.Position = UDim2.new(1, 0, 1, 0)
local TextSizeCache = {}
local function GetStringTextBounds(text, font, fontSize, sizeBounds)
	sizeBounds = sizeBounds or false
	if not TextSizeCache[text] then
		TextSizeCache[text] = {}
	end
	if not TextSizeCache[text][font] then
		TextSizeCache[text][font] = {}
	end
	if not TextSizeCache[text][font][sizeBounds] then
		TextSizeCache[text][font][sizeBounds] = {}
	end
	if not TextSizeCache[text][font][sizeBounds][fontSize] then
		testLabel.Text = text
		testLabel.Font = font
		testLabel.FontSize = fontSize
		if sizeBounds then
			testLabel.TextWrapped = true;
			testLabel.Size = sizeBounds
		else
			testLabel.TextWrapped = false;
		end
		TextSizeCache[text][font][sizeBounds][fontSize] = testLabel.TextBounds
	end
	return TextSizeCache[text][font][sizeBounds][fontSize]
end
--// Above was taken directly from Util.GetStringTextBounds() in the old chat corescripts.




function WaitUntilParentedCorrectly()
	while (not testLabel:IsDescendantOf(game:GetService("Players").LocalPlayer)) do
		testLabel.AncestryChanged:wait()
	end
end


local function WrapIntoMessageObject(id, BaseFrame, BaseMessage, Tweener, StrongReferences, UpdateTextFunction)
	local obj = {}

	obj.ID = id
	obj.BaseFrame = BaseFrame
	obj.BaseMessage = BaseMessage
	obj.Tweener = Tweener
	obj.StrongReferences = StrongReferences
	obj.UpdateTextFunction = UpdateTextFunction or function() warn("NO MESSAGE RESIZE FUNCTION") end

	function obj:TweenOut(duration)
		self.Tweener:Tween(duration, 1)
	end

	function obj:TweenIn(duration)
		self.Tweener:Tween(duration, 0)
	end

	function obj:Destroy()
		self.BaseFrame:Destroy()
		self.BaseMessage:Destroy()
	end

	return obj
end





function methods:CreateMessageLabel(messageData)
	local fromSpeaker = messageData.FromSpeaker
	local message = messageData.Message

	WaitUntilParentedCorrectly()

	if (string.sub(message, 1, 4) == "/me ") then
		--// Cannot be destructive with messageData
		local oldMessage = messageData.Message
		local oldSpeaker = messageData.FromSpeaker
		local oldChatColor = messageData.ExtraData.ChatColor

		messageData.Message = messageData.FromSpeaker .. " " .. string.sub(message, 5)
		messageData.FromSpeaker = nil
		messageData.ExtraData.ChatColor = nil

		local toReturn = self:CreateSystemMessageLabel(messageData)

		messageData.Message = oldMessage
		messageData.FromSpeaker = oldSpeaker
		messageData.ExtraData.ChatColor = oldChatColor
		return toReturn
	end

	local extraData = messageData.ExtraData or {}
	local useFont = extraData.Font or Enum.Font.SourceSansBold
	local useFontSize = extraData.FontSize or ChatSettings.ChatWindowTextSize
	local useNameColor = extraData.NameColor or Color3.new(1, 1, 1)
	local useChatColor = extraData.ChatColor or Color3.new(1, 1, 1)


	local BaseFrame = Instance.new("Frame")
	BaseFrame.Selectable = false
	BaseFrame.Size = UDim2.new(1, 0, 0, 18)
	BaseFrame.BackgroundTransparency = 1

	local messageBorder = 8

	local BaseMessage = Instance.new("TextLabel", BaseFrame)
	BaseMessage.Selectable = false
	BaseMessage.Size = UDim2.new(1, -(messageBorder + 6), 1, 0)
	BaseMessage.Position = UDim2.new(0, messageBorder, 0, 0)
	BaseMessage.BackgroundTransparency = 1
	BaseMessage.Font = useFont
	BaseMessage.FontSize = useFontSize
	BaseMessage.TextXAlignment = Enum.TextXAlignment.Left
	BaseMessage.TextYAlignment = Enum.TextYAlignment.Top
	BaseMessage.TextStrokeTransparency = 0.75
	BaseMessage.TextWrapped = true

	local NameButton = Instance.new("TextButton", BaseMessage)
	NameButton.Selectable = false
	NameButton.Size = UDim2.new(1, 0, 1, 0)
	NameButton.Position = UDim2.new(0, 0, 0, 0)
	NameButton.BackgroundTransparency = 1
	NameButton.Font = BaseMessage.Font
	NameButton.FontSize = BaseMessage.FontSize
	NameButton.TextXAlignment = BaseMessage.TextXAlignment
	NameButton.TextYAlignment = BaseMessage.TextYAlignment
	NameButton.TextStrokeTransparency = BaseMessage.TextStrokeTransparency

	NameButton.MouseButton1Click:connect(function()
		-- Click to whisper is currently disabled
		-- ToDo: Re-enable later when things are sorted out
		--MessageSender:SendMessage(string.format("/w %s", fromSpeaker), nil)
	end)

	
	local formatUseName = string.format("[%s]:", fromSpeaker)

	local speakerNameSize = GetStringTextBounds(formatUseName, useFont, useFontSize)
	local singleSpaceSize = GetStringTextBounds(" ", useFont, useFontSize)
	local numNeededSpaces = math.ceil(speakerNameSize.X / singleSpaceSize.X) + 1

	local messageSize = GetStringTextBounds(message, useFont, useFontSize)
	local singleUnderscoreSize = GetStringTextBounds("_", useFont, useFontSize)
	local numNeededUnderscore = math.ceil(messageSize.X / singleUnderscoreSize.X)

	NameButton.Size = UDim2.new(0, speakerNameSize.X, 0, speakerNameSize.Y)

	BaseMessage.TextColor3 = useChatColor
	NameButton.TextColor3 = useNameColor

	NameButton.Text = formatUseName
	BaseMessage.Text = string.rep(" ", numNeededSpaces) .. string.rep("_", numNeededUnderscore)

	local Tweener = moduleTransparencyTweener.new()
	Tweener:RegisterTweenObjectProperty(BaseMessage, "TextTransparency")
	Tweener:RegisterTweenObjectProperty(BaseMessage, "TextStrokeTransparency")

	local StrongReferences = {}
	local function ProcessChild(child)
		if (child:IsA("TextLabel") or child:IsA("TextButton")) then
			Tweener:RegisterTweenObjectProperty(child, "TextTransparency")
			Tweener:RegisterTweenObjectProperty(child, "TextStrokeTransparency")
			table.insert(StrongReferences, child)

		elseif (child:IsA("ImageLabel") or child:Is("ImageButton")) then
			Tweener:RegisterTweenObjectProperty(child, "ImageTransparency")
			table.insert(StrongReferences, child)

		end
	end

	for i, v in pairs(BaseMessage:GetChildren()) do
		ProcessChild(v)
	end

	BaseMessage.ChildAdded:connect(ProcessChild)

	local function UpdateTextFunction(newMessageObject)
		BaseMessage.Text = string.rep(" ", numNeededSpaces) .. newMessageObject.Message
	end

	return WrapIntoMessageObject(messageData.ID, BaseFrame, BaseMessage, Tweener, StrongReferences, UpdateTextFunction)
end

function methods:CreateSystemMessageLabel(messageData)
	message = messageData.Message

	WaitUntilParentedCorrectly()

	local extraData = messageData.ExtraData or {}
	local useFont = extraData.Font or Enum.Font.SourceSansBold
	local useFontSize = extraData.FontSize or ChatSettings.ChatWindowTextSize
	local useChatColor = extraData.ChatColor or Color3.new(1, 1, 1)


	local BaseFrame = Instance.new("Frame")
	BaseFrame.Selectable = false
	BaseFrame.Size = UDim2.new(1, 0, 0, 18)
	BaseFrame.BackgroundTransparency = 1

	local messageBorder = 8

	local BaseMessage = Instance.new("TextLabel", BaseFrame)
	BaseMessage.Selectable = false
	BaseMessage.Size = UDim2.new(1, -(messageBorder + 6), 1, 0)
	BaseMessage.Position = UDim2.new(0, messageBorder, 0, 0)
	BaseMessage.BackgroundTransparency = 1
	BaseMessage.Font = useFont
	BaseMessage.FontSize = useFontSize
	BaseMessage.TextXAlignment = Enum.TextXAlignment.Left
	BaseMessage.TextYAlignment = Enum.TextYAlignment.Top
	BaseMessage.TextStrokeTransparency = 0.75
	BaseMessage.TextColor3 = useChatColor
	BaseMessage.TextWrapped = true

	BaseMessage.Text = message


	local Tweener = moduleTransparencyTweener.new()
	Tweener:RegisterTweenObjectProperty(BaseMessage, "TextTransparency")
	Tweener:RegisterTweenObjectProperty(BaseMessage, "TextStrokeTransparency")

	return WrapIntoMessageObject(-1, BaseFrame, BaseMessage, Tweener, {})
end

function methods:CreateWelcomeMessageLabel(message)
	WaitUntilParentedCorrectly()

	WaitUntilParentedCorrectly()

	local useFont = Enum.Font.SourceSansBold
	local useFontSize = ChatSettings.ChatWindowTextSize

	local BaseFrame = Instance.new("Frame")
	BaseFrame.Selectable = false
	BaseFrame.Size = UDim2.new(1, 0, 0, 18)
	BaseFrame.BackgroundTransparency = 1

	local messageBorder = 8

	local BaseMessage = Instance.new("TextLabel", BaseFrame)
	BaseMessage.Selectable = false
	BaseMessage.Size = UDim2.new(1, -(messageBorder + 6), 1, 0)
	BaseMessage.Position = UDim2.new(0, messageBorder, 0, 0)
	BaseMessage.BackgroundTransparency = 1
	BaseMessage.Font = useFont
	BaseMessage.FontSize = useFontSize
	BaseMessage.TextXAlignment = Enum.TextXAlignment.Left
	BaseMessage.TextYAlignment = Enum.TextYAlignment.Top
	BaseMessage.TextStrokeTransparency = 0.75
	BaseMessage.TextColor3 = Color3.new(1, 1, 1)
	BaseMessage.TextWrapped = true

	BaseMessage.Text = message


	local Tweener = moduleTransparencyTweener.new()
	Tweener:RegisterTweenObjectProperty(BaseMessage, "TextTransparency")
	Tweener:RegisterTweenObjectProperty(BaseMessage, "TextStrokeTransparency")

	return WrapIntoMessageObject(-1, BaseFrame, BaseMessage, Tweener, {})
end

function methods:CreateSetCoreMessageLabel(valueTable)
	WaitUntilParentedCorrectly()

	local useFont = valueTable.Font or Enum.Font.SourceSansBold
	local useFontSize = valueTable.FontSize or ChatSettings.ChatWindowTextSize
	local useColor = valueTable.Color or Color3.new(1, 1, 1)

	local message = valueTable.Text

	local BaseFrame = Instance.new("Frame")
	BaseFrame.Selectable = false
	BaseFrame.Size = UDim2.new(1, 0, 0, 18)
	BaseFrame.BackgroundTransparency = 1

	local messageBorder = 8

	local BaseMessage = Instance.new("TextLabel", BaseFrame)
	BaseMessage.Selectable = false
	BaseMessage.Size = UDim2.new(1, -(messageBorder + 6), 1, 0)
	BaseMessage.Position = UDim2.new(0, messageBorder, 0, 0)
	BaseMessage.BackgroundTransparency = 1
	BaseMessage.Font = useFont
	BaseMessage.FontSize = useFontSize
	BaseMessage.TextXAlignment = Enum.TextXAlignment.Left
	BaseMessage.TextYAlignment = Enum.TextYAlignment.Top
	BaseMessage.TextStrokeTransparency = 0.75
	BaseMessage.TextColor3 = useColor
	BaseMessage.TextWrapped = true

	BaseMessage.Text = message


	local Tweener = moduleTransparencyTweener.new()
	Tweener:RegisterTweenObjectProperty(BaseMessage, "TextTransparency")
	Tweener:RegisterTweenObjectProperty(BaseMessage, "TextStrokeTransparency")

	return WrapIntoMessageObject(-1, BaseFrame, BaseMessage, Tweener, {})
end

function methods:CreateChannelEchoMessageLabel(messageData, echoChannel)
	local fromSpeaker = messageData.FromSpeaker
	local message = messageData.Message

	WaitUntilParentedCorrectly()

	if (string.sub(message, 1, 4) == "/me ") then
		--// Cannot be destructive with messageData
		local oldMessage = messageData.Message
		local oldSpeaker = messageData.FromSpeaker
		local oldChatColor = messageData.ExtraData.ChatColor

		messageData.Message = messageData.FromSpeaker .. " " .. string.sub(message, 5)
		messageData.FromSpeaker = nil
		messageData.ExtraData.ChatColor = nil

		local toReturn = self:CreateChannelEchoSystemMessageLabel(messageData, echoChannel)

		messageData.Message = oldMessage
		messageData.FromSpeaker = oldSpeaker
		messageData.ExtraData.ChatColor = oldChatColor
		return toReturn
	end

	local extraData = messageData.ExtraData or {}
	local useFont = extraData.Font or Enum.Font.SourceSansBold
	local useFontSize = extraData.FontSize or ChatSettings.ChatWindowTextSize
	local useNameColor = extraData.NameColor or Color3.new(1, 1, 1)
	local useChatColor = extraData.ChatColor or Color3.new(1, 1, 1)


	local BaseFrame = Instance.new("Frame")
	BaseFrame.Selectable = false
	BaseFrame.Size = UDim2.new(1, 0, 0, 18)
	BaseFrame.BackgroundTransparency = 1

	local messageBorder = 8

	local BaseMessage = Instance.new("TextLabel", BaseFrame)
	BaseMessage.Selectable = false
	BaseMessage.Size = UDim2.new(1, -(messageBorder + 6), 1, 0)
	BaseMessage.Position = UDim2.new(0, messageBorder, 0, 0)
	BaseMessage.BackgroundTransparency = 1
	BaseMessage.Font = useFont
	BaseMessage.FontSize = useFontSize
	BaseMessage.TextXAlignment = Enum.TextXAlignment.Left
	BaseMessage.TextYAlignment = Enum.TextYAlignment.Top
	BaseMessage.TextStrokeTransparency = 0.75
	BaseMessage.TextWrapped = true

	local NameButton = Instance.new("TextButton", BaseMessage)
	NameButton.Selectable = false
	NameButton.Size = UDim2.new(1, 0, 1, 0)
	NameButton.Position = UDim2.new(0, 0, 0, 0)
	NameButton.BackgroundTransparency = 1
	NameButton.Font = BaseMessage.Font
	NameButton.FontSize = BaseMessage.FontSize
	NameButton.TextXAlignment = BaseMessage.TextXAlignment
	NameButton.TextYAlignment = BaseMessage.TextYAlignment
	NameButton.TextStrokeTransparency = BaseMessage.TextStrokeTransparency

	local ChannelButton = NameButton:Clone()
	ChannelButton.Selectable = false
	ChannelButton.Parent = BaseMessage

	NameButton.MouseButton1Click:connect(function()
		-- Click to whisper is currently disabled
		-- ToDo: Re-enable later when things are sorted out
		--MessageSender:SendMessage(string.format("/w %s", fromSpeaker), nil)
	end)

	
	local formatUseName = string.format("[%s]:", fromSpeaker)
	local formatChannelName = string.format("{%s}", echoChannel)

	local speakerNameSize = GetStringTextBounds(formatUseName, useFont, useFontSize)
	local singleSpaceSize = GetStringTextBounds(" ", useFont, useFontSize)
	local numNeededSpaces = math.ceil(speakerNameSize.X / singleSpaceSize.X) + 1

	local channelNameSize = GetStringTextBounds(formatChannelName, useFont, useFontSize)
	local numNeededSpaces2 = math.ceil(channelNameSize.X / singleSpaceSize.X) + 1

	NameButton.Size = UDim2.new(0, speakerNameSize.X, 0, speakerNameSize.Y)
	ChannelButton.Size = UDim2.new(0, channelNameSize.X, 0, channelNameSize.Y)

	NameButton.Position = UDim2.new(0, channelNameSize.X + singleSpaceSize.X, 0, 0)

	BaseMessage.TextColor3 = useChatColor
	NameButton.TextColor3 = useNameColor
	ChannelButton.TextColor3 = useNameColor

	ChannelButton.Text = formatChannelName
	NameButton.Text = formatUseName
	BaseMessage.Text = string.rep(" ", numNeededSpaces2 + numNeededSpaces) .. message

	local Tweener = moduleTransparencyTweener.new()
	Tweener:RegisterTweenObjectProperty(BaseMessage, "TextTransparency")
	Tweener:RegisterTweenObjectProperty(BaseMessage, "TextStrokeTransparency")

	local StrongReferences = {}
	local function ProcessChild(child)
		if (child:IsA("TextLabel") or child:IsA("TextButton")) then
			Tweener:RegisterTweenObjectProperty(child, "TextTransparency")
			Tweener:RegisterTweenObjectProperty(child, "TextStrokeTransparency")
			table.insert(StrongReferences, child)

		elseif (child:IsA("ImageLabel") or child:Is("ImageButton")) then
			Tweener:RegisterTweenObjectProperty(child, "ImageTransparency")
			table.insert(StrongReferences, child)

		end
	end

	for i, v in pairs(BaseMessage:GetChildren()) do
		ProcessChild(v)
	end

	BaseMessage.ChildAdded:connect(ProcessChild)

	local function UpdateTextFunction(newMessageObject)
		BaseMessage.Text = string.rep(" ", numNeededSpaces) .. newMessageObject.Message
	end

	return WrapIntoMessageObject(-1, BaseFrame, BaseMessage, Tweener, StrongReferences, UpdateTextFunction)
end

function methods:CreateChannelEchoSystemMessageLabel(messageData, echoChannel)
	local message = messageData.Message

	WaitUntilParentedCorrectly()
	
	local extraData = messageData.ExtraData or {}
	local useFont = extraData.Font or Enum.Font.SourceSansBold
	local useFontSize = extraData.FontSize or ChatSettings.ChatWindowTextSize
	local useChatColor = extraData.ChatColor or Color3.new(1, 1, 1)


	local BaseFrame = Instance.new("Frame")
	BaseFrame.Selectable = false
	BaseFrame.Size = UDim2.new(1, 0, 0, 18)
	BaseFrame.BackgroundTransparency = 1

	local messageBorder = 8

	local BaseMessage = Instance.new("TextLabel", BaseFrame)
	BaseMessage.Selectable = false
	BaseMessage.Size = UDim2.new(1, -(messageBorder + 6), 1, 0)
	BaseMessage.Position = UDim2.new(0, messageBorder, 0, 0)
	BaseMessage.BackgroundTransparency = 1
	BaseMessage.Font = useFont
	BaseMessage.FontSize = useFontSize
	BaseMessage.TextXAlignment = Enum.TextXAlignment.Left
	BaseMessage.TextYAlignment = Enum.TextYAlignment.Top
	BaseMessage.TextStrokeTransparency = 0.75
	BaseMessage.TextColor3 = useChatColor
	BaseMessage.TextWrapped = true

	local ChannelButton = Instance.new("TextButton", BaseMessage)
	ChannelButton.Selectable = false
	ChannelButton.Size = UDim2.new(1, 0, 1, 0)
	ChannelButton.Position = UDim2.new(0, 0, 0, 0)
	ChannelButton.BackgroundTransparency = 1
	ChannelButton.Font = BaseMessage.Font
	ChannelButton.FontSize = BaseMessage.FontSize
	ChannelButton.TextXAlignment = BaseMessage.TextXAlignment
	ChannelButton.TextYAlignment = BaseMessage.TextYAlignment
	ChannelButton.TextStrokeTransparency = BaseMessage.TextStrokeTransparency



	local formatChannelName = string.format("{%s}", echoChannel)

	local singleSpaceSize = GetStringTextBounds(" ", useFont, useFontSize)

	local channelNameSize = GetStringTextBounds(formatChannelName, useFont, useFontSize)
	local numNeededSpaces2 = math.ceil(channelNameSize.X / singleSpaceSize.X) + 1

	ChannelButton.Size = UDim2.new(0, channelNameSize.X, 0, channelNameSize.Y)

	ChannelButton.TextColor3 = BaseMessage.TextColor3

	ChannelButton.Text = formatChannelName
	BaseMessage.Text = string.rep(" ", numNeededSpaces2) .. message


	local Tweener = moduleTransparencyTweener.new()
	Tweener:RegisterTweenObjectProperty(BaseMessage, "TextTransparency")
	Tweener:RegisterTweenObjectProperty(BaseMessage, "TextStrokeTransparency")

	Tweener:RegisterTweenObjectProperty(ChannelButton, "TextTransparency")
	Tweener:RegisterTweenObjectProperty(ChannelButton, "TextStrokeTransparency")

	return WrapIntoMessageObject(-1, BaseFrame, BaseMessage, Tweener, {ChannelButton})
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("MessageLabelCreator", methods)

function module.new()
	local obj = {}

	ClassMaker.MakeClass("MessageLabelCreator", obj)

	return obj
end

function module:RegisterGuiRoot(root)
	testLabel.Parent = root
end

function module:GetStringTextBounds(text, font, fontSize, sizeBounds)
	return GetStringTextBounds(text, font, fontSize, sizeBounds)
end

return module
]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script