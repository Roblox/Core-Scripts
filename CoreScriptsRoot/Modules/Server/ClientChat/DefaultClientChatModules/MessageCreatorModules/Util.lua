--	// FileName: Util.lua
--	// Written by: Xsitsu, TheGamer101
--	// Description: Module for shared code between MessageCreatorModules.

local DEFAULT_MESSAGE_CREATOR = "UnknownMessage"
local KEY_MESSAGE_TYPE = "MessageType"
local KEY_CREATOR_FUNCTION = "MessageCreatorFunc"
local MESSAGE_CREATOR_MODULES_VERSION = 1

local module = {}
local methods = {}
methods.__index = methods

local testLabel = Instance.new("TextLabel")
testLabel.Selectable = false
testLabel.TextWrapped  = true
testLabel.Position = UDim2.new(1, 0, 1, 0)

function WaitUntilParentedCorrectly()
	while (not testLabel:IsDescendantOf(game:GetService("Players").LocalPlayer)) do
		testLabel.AncestryChanged:wait()
	end
end

local TextSizeCache = {}
function methods:GetStringTextBounds(text, font, fontSize, sizeBounds)
  WaitUntilParentedCorrectly()
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

function methods:GetNumberOfSpaces(str, font, fontSize)
	local strSize = self:GetStringTextBounds(str, font, fontSize)
	local singleSpaceSize = self:GetStringTextBounds(" ", font, fontSize)
	return math.ceil(strSize.X / singleSpaceSize.X)
end

function methods:GetNumberOfUnderscores(str, font, fontSize)
	local strSize = self:GetStringTextBounds(str, font, fontSize)
	local singleUnderscoreSize = self:GetStringTextBounds("_", font, fontSize)
	return math.ceil(strSize.X / singleUnderscoreSize.X)
end

function methods:CreateBaseMessage(message, font, fontSize, chatColor)
	local BaseFrame = self:GetFromObjectPool("Frame")
	BaseFrame.Selectable = false
	BaseFrame.Size = UDim2.new(1, 0, 0, 18)
	BaseFrame.BackgroundTransparency = 1

	local messageBorder = 8

	local BaseMessage = self:GetFromObjectPool("TextLabel")
	BaseMessage.Parent = BaseFrame
	BaseMessage.Selectable = false
	BaseMessage.Size = UDim2.new(1, -(messageBorder + 6), 1, 0)
	BaseMessage.Position = UDim2.new(0, messageBorder, 0, 0)
	BaseMessage.BackgroundTransparency = 1
	BaseMessage.Font = font
	BaseMessage.FontSize = fontSize
	BaseMessage.TextXAlignment = Enum.TextXAlignment.Left
	BaseMessage.TextYAlignment = Enum.TextYAlignment.Top
	BaseMessage.TextTransparency = 0
	BaseMessage.TextStrokeTransparency = 0.75
	BaseMessage.TextColor3 = chatColor
	BaseMessage.TextWrapped = true
	BaseMessage.Text = message

	return BaseFrame, BaseMessage
end

function methods:AddNameButtonToBaseMessage(BaseMessage, nameColor, formatName)
	local speakerNameSize = self:GetStringTextBounds(formatName, BaseMessage.Font, BaseMessage.FontSize)
	local NameButton = self:GetFromObjectPool("TextButton")
	NameButton.Parent = BaseMessage
	NameButton.Selectable = false
	NameButton.Size = UDim2.new(0, speakerNameSize.X, 0, speakerNameSize.Y)
	NameButton.Position = UDim2.new(0, 0, 0, 0)
	NameButton.BackgroundTransparency = 1
	NameButton.Font = BaseMessage.Font
	NameButton.FontSize = BaseMessage.FontSize
	NameButton.TextXAlignment = BaseMessage.TextXAlignment
	NameButton.TextYAlignment = BaseMessage.TextYAlignment
	NameButton.TextTransparency = BaseMessage.TextTransparency
	NameButton.TextStrokeTransparency = BaseMessage.TextStrokeTransparency
	NameButton.TextColor3 = nameColor
	NameButton.Text = formatName
	return NameButton
end

function methods:AddChannelButtonToBaseMessage(BaseMessage, formatChannelName)
	local channelNameSize = self:GetStringTextBounds(formatChannelName, BaseMessage.Font, BaseMessage.FontSize)
	local ChannelButton = self:GetFromObjectPool("TextButton")
	ChannelButton.Parent = BaseMessage
	ChannelButton.Selectable = false
	ChannelButton.Size = UDim2.new(0, channelNameSize.X, 0, channelNameSize.Y)
	ChannelButton.Position = UDim2.new(0, 0, 0, 0)
	ChannelButton.BackgroundTransparency = 1
	ChannelButton.Font = BaseMessage.Font
	ChannelButton.FontSize = BaseMessage.FontSize
	ChannelButton.TextXAlignment = BaseMessage.TextXAlignment
	ChannelButton.TextYAlignment = BaseMessage.TextYAlignment
	ChannelButton.TextTransparency = BaseMessage.TextTransparency
	ChannelButton.TextStrokeTransparency = BaseMessage.TextStrokeTransparency
	ChannelButton.TextColor3 = BaseMessage.TextColor3
	ChannelButton.Text = formatChannelName
	return ChannelButton
end

function methods:GetFromObjectPool(className)
	if self.ObjectPool == nil then
		return Instance.new(className)
	end
	return self.ObjectPool:GetInstance(className)
end

function methods:RegisterObjectPool(objectPool)
	self.ObjectPool = objectPool
end

function methods:RegisterGuiRoot(root)
	testLabel.Parent = root
end

function module.new()
	local obj = setmetatable({}, methods)

	obj.ObjectPool = nil
	obj.DEFAULT_MESSAGE_CREATOR = DEFAULT_MESSAGE_CREATOR
	obj.KEY_MESSAGE_TYPE = KEY_MESSAGE_TYPE
	obj.KEY_CREATOR_FUNCTION = KEY_CREATOR_FUNCTION
	obj.MESSAGE_CREATOR_MODULES_VERSION = MESSAGE_CREATOR_MODULES_VERSION

	return obj
end

return module.new()
