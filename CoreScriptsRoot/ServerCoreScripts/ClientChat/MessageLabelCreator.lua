local source = [[
local module = {}
--////////////////////////////// Include
--//////////////////////////////////////
local modulesFolder = script.Parent
local moduleTransparencyTweener = require(modulesFolder:WaitForChild("TransparencyTweener"))

--////////////////////////////// Details
--//////////////////////////////////////
local metatable = {}
metatable.__ClassName = "MessageLabelCreator"

metatable.__tostring = function(tbl)
	return tbl.__ClassName .. ": " .. tbl.MemoryLocation
end

metatable.__metatable = "The metatable is locked"
metatable.__index = function(tbl, index, value)
	if rawget(tbl, index) then return rawget(tbl, index) end
	if rawget(metatable, index) then return rawget(metatable, index) end
	error(index .. " is not a valid member of " .. tbl.__ClassName)
end
metatable.__newindex = function(tbl, index, value)
	error(index .. " is not a valid member of " .. tbl.__ClassName)
end


--////////////////////////////// Methods
--//////////////////////////////////////
local testLabel = Instance.new("TextLabel")
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





local function WrapIntoMessageObject(BaseFrame, BaseMessage, Tweener, StrongReferences)
	local obj = {}

	obj.BaseFrame = BaseFrame
	obj.BaseMessage = BaseMessage
	obj.Tweener = Tweener
	obj.StrongReferences = StrongReferences

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



function metatable:Dump()
	return tostring(self)
end

function metatable:RegisterSpeakerDatabase(SpeakerDatabase)
	rawset(self, "SpeakerDatabase", SpeakerDatabase)
end

function metatable:CreateMessageLabel(fromSpeaker, message)
	if (string.sub(message, 1, 4) == "/me ") then
		return self:CreateSystemMessageLabel(fromSpeaker .. " " .. string.sub(message, 5))
	end

	local useFont = Enum.Font.SourceSansBold
	local useFontSize = Enum.FontSize.Size18

	local BaseFrame = Instance.new("Frame")
	BaseFrame.Size = UDim2.new(1, 0, 0, 18)
	BaseFrame.BackgroundTransparency = 1

	local messageBorder = 8

	local BaseMessage = Instance.new("TextLabel", BaseFrame)
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
	NameButton.Size = UDim2.new(1, 0, 1, 0)
	NameButton.Position = UDim2.new(0, 0, 0, 0)
	NameButton.BackgroundTransparency = 1
	NameButton.Font = BaseMessage.Font
	NameButton.FontSize = BaseMessage.FontSize
	NameButton.TextXAlignment = BaseMessage.TextXAlignment
	NameButton.TextYAlignment = BaseMessage.TextYAlignment
	NameButton.TextStrokeTransparency = BaseMessage.TextStrokeTransparency

	local buttonClickLock = false
	NameButton.MouseButton1Click:connect(function()
		if (buttonClickLock) then return end
		buttonClickLock = true

		local t = NameButton.Text
		local len = string.len(t)

		for i = 1, len do
			NameButton.Text = string.sub(t, 1, i)
			wait(0.1)
		end

		buttonClickLock = false
	end)

	local speakerPlayer = self.SpeakerDatabase:GetSpeaker(fromSpeaker)

	local useNameColor = Color3.new(1, 1, 1)
	local useChatColor = Color3.new(1, 1, 1)

	if (speakerPlayer) then
		useNameColor = speakerPlayer.NameColor
		useChatColor = speakerPlayer.ChatColor
	end
	
	local formatUseName = string.format("[%s]:", fromSpeaker)

	local speakerNameSize = GetStringTextBounds(formatUseName, useFont, useFontSize)
	local singleSpaceSize = GetStringTextBounds(" ", useFont, useFontSize)
	local numNeededSpaces = math.ceil(speakerNameSize.X / singleSpaceSize.X) + 1

	NameButton.Size = UDim2.new(0, speakerNameSize.X, 0, speakerNameSize.Y)

	BaseMessage.TextColor3 = useChatColor
	NameButton.TextColor3 = useNameColor

	NameButton.Text = formatUseName
	BaseMessage.Text = string.rep(" ", numNeededSpaces) .. message

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

	return WrapIntoMessageObject(BaseFrame, BaseMessage, Tweener, StrongReferences)
end

function metatable:CreateSystemMessageLabel(message)
	local useFont = Enum.Font.SourceSansBold
	local useFontSize = Enum.FontSize.Size18

	local BaseFrame = Instance.new("Frame")
	BaseFrame.Size = UDim2.new(1, 0, 0, 18)
	BaseFrame.BackgroundTransparency = 1

	local messageBorder = 8

	local BaseMessage = Instance.new("TextLabel", BaseFrame)
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

	return WrapIntoMessageObject(BaseFrame, BaseMessage, Tweener, {})
end

function metatable:CreateWelcomeMessageLabel(message)
	return self:CreateSystemMessageLabel(message)
end

--///////////////////////// Constructors
--//////////////////////////////////////
function module.new()
	local obj = {}
	obj.MemoryLocation = tostring(obj):match("[0123456789ABCDEF]+")
	
	obj.SpeakerDatabase = nil
	
	obj = setmetatable(obj, metatable)
	
	return obj
end

function module:RegisterGuiRoot(root)
	testLabel.Parent = root
end

return module
]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script