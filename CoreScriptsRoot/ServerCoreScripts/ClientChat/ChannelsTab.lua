local source = [[
--	// FileName: ChannelsTab.lua
--	// Written by: Xsitsu
--	// Description: Channel tab button for selecting current channel and also displaying if currently selected.

local module = {}
--////////////////////////////// Include
--//////////////////////////////////////
local modulesFolder = script.Parent
local moduleTransparencyTweener = require(modulesFolder:WaitForChild("TransparencyTweener"))
local ChatSettings = require(modulesFolder:WaitForChild("ChatSettings"))
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

local function CreateGuiObjects()
	local BaseFrame = Instance.new("Frame")
	BaseFrame.Selectable = false
	BaseFrame.Size = UDim2.new(1, 0, 1, 0)
	BaseFrame.BackgroundTransparency = 1

	local gapOffsetX = 1
	local gapOffsetY = 1

	local BackgroundFrame = Instance.new("Frame", BaseFrame)
	BackgroundFrame.Selectable = false
	BackgroundFrame.Name = "BackgroundFrame"
	BackgroundFrame.Size = UDim2.new(1, -gapOffsetX * 2, 1, -gapOffsetY * 2)
	BackgroundFrame.Position = UDim2.new(0, gapOffsetX, 0, gapOffsetY)
	BackgroundFrame.BackgroundTransparency = 1

	local UnselectedFrame = Instance.new("Frame", BackgroundFrame)
	UnselectedFrame.Selectable = false
	UnselectedFrame.Name = "UnselectedFrame"
	UnselectedFrame.Size = UDim2.new(1, 0, 1, 0)
	UnselectedFrame.Position = UDim2.new(0, 0, 0, 0)
	UnselectedFrame.BorderSizePixel = 0
	UnselectedFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	UnselectedFrame.BackgroundTransparency = 0.6	

	local SelectedFrame = Instance.new("Frame", BackgroundFrame)
	SelectedFrame.Selectable = false
	SelectedFrame.Name = "SelectedFrame"
	SelectedFrame.Size = UDim2.new(1, 0, 1, 0)
	SelectedFrame.Position = UDim2.new(0, 0, 0, 0)
	SelectedFrame.BorderSizePixel = 0
	SelectedFrame.BackgroundColor3 = Color3.new(30/255, 30/255, 30/255)
	SelectedFrame.BackgroundTransparency = 1

	local SelectedFrameBackgroundImage = Instance.new("ImageLabel", SelectedFrame)
	SelectedFrameBackgroundImage.Selectable = false
	SelectedFrameBackgroundImage.Name = "BackgroundImage"
	SelectedFrameBackgroundImage.BackgroundTransparency = 1
	SelectedFrameBackgroundImage.BorderSizePixel = 0
	SelectedFrameBackgroundImage.Size = UDim2.new(1, 0, 1, 0)
	SelectedFrameBackgroundImage.Position = UDim2.new(0, 0, 0, 0)
	SelectedFrameBackgroundImage.ScaleType = Enum.ScaleType.Slice

	SelectedFrameBackgroundImage.BackgroundTransparency = 0.6 - 1
	local rate = 1.2 * 1
	SelectedFrameBackgroundImage.BackgroundColor3 = Color3.fromRGB(78 * rate, 84 * rate, 96 * rate)

	local borderXOffset = 2
	local blueBarYSize = 4 
	local BlueBarLeft = Instance.new("ImageLabel", SelectedFrame)
	BlueBarLeft.Selectable = false
	BlueBarLeft.Size = UDim2.new(0.5, -borderXOffset, 0, blueBarYSize)
	BlueBarLeft.BackgroundTransparency = 1
	BlueBarLeft.ScaleType = Enum.ScaleType.Slice
	BlueBarLeft.SliceCenter = Rect.new(3,3,32,21)

	local BlueBarRight = BlueBarLeft:Clone()
	BlueBarRight.Parent = SelectedFrame

	BlueBarLeft.Position = UDim2.new(0, borderXOffset, 1, -blueBarYSize)
	BlueBarRight.Position = UDim2.new(0.5, 0, 1, -blueBarYSize)
	BlueBarLeft.Image = "rbxasset://textures/ui/Settings/Slider/SelectedBarLeft.png"
	BlueBarRight.Image = "rbxasset://textures/ui/Settings/Slider/SelectedBarRight.png"

	BlueBarLeft.Name = "BlueBarLeft"
	BlueBarRight.Name = "BlueBarRight"

	local NameTag = Instance.new("TextButton", BackgroundFrame)
	NameTag.Selectable = ChatSettings.GamepadNavigationEnabled
	NameTag.Size = UDim2.new(1, 0, 1, 0)
	NameTag.Position = UDim2.new(0, 0, 0, 0)
	NameTag.BackgroundTransparency = 1
	NameTag.Font = Enum.Font.SourceSansBold
	NameTag.FontSize = Enum.FontSize.Size18

	NameTag.FontSize = ChatSettings.ChatChannelsTabTextSize



	NameTag.TextColor3 = Color3.new(1, 1, 1)
	NameTag.TextStrokeTransparency = 0.75

	local NewMessageIconFrame = Instance.new("Frame", BackgroundFrame)
	NewMessageIconFrame.Selectable = false
	NewMessageIconFrame.Size = UDim2.new(0, 18, 0, 18)
	NewMessageIconFrame.Position = UDim2.new(0.8, -9, 0.5, -9)
	NewMessageIconFrame.BackgroundTransparency = 1

	local NewMessageIcon = Instance.new("ImageLabel", NewMessageIconFrame)
	NewMessageIcon.Selectable = false
	NewMessageIcon.Size = UDim2.new(1, 0, 1, 0)
	NewMessageIcon.BackgroundTransparency = 1
	NewMessageIcon.Image = "rbxasset://textures/ui/Chat/MessageCounter.png"
	NewMessageIcon.Visible = false

	local NewMessageIconText = Instance.new("TextLabel", NewMessageIcon)
	NewMessageIconText.Selectable = false
	NewMessageIconText.BackgroundTransparency = 1
	NewMessageIconText.Size = UDim2.new(0, 13, 0, 9)
	NewMessageIconText.Position = UDim2.new(0.5, -7, 0.5, -7)
	NewMessageIconText.Font = Enum.Font.SourceSansBold
	NewMessageIconText.FontSize = Enum.FontSize.Size14
	NewMessageIconText.TextColor3 = Color3.new(1, 1, 1)
	NewMessageIconText.Text = ""

	return BaseFrame, NameTag, NewMessageIcon, UnselectedFrame, SelectedFrame
end

function methods:Destroy()
	self.GuiObject:Destroy()
end

function methods:UpdateMessagePostedInChannel(ignoreActive)
	if (self.Active and (ignoreActive ~= true)) then return end

	local count = self.UnreadMessageCount + 1
	self.UnreadMessageCount = count

	local label = self.NewMessageIcon
	label.Visible = true
	label.TextLabel.Text = (count < 100) and tostring(count) or "!"

	local tweenTime = 0.15
	local tweenPosOffset = UDim2.new(0, 0, -0.1, 0)

	local curPos = label.Position
	local outPos = curPos + tweenPosOffset
	local easingDirection = Enum.EasingDirection.Out
	local easingStyle = Enum.EasingStyle.Quad

	label.Position = UDim2.new(0, 0, -0.15, 0)
	label:TweenPosition(UDim2.new(0, 0, 0, 0), easingDirection, easingStyle, tweenTime, true)

end

function methods:SetActive(active)
	self.Active = active
	self.UnselectedFrame.Visible = not active
	self.SelectedFrame.Visible = active

	if (active) then
		self.UnreadMessageCount = 0
		self.NewMessageIcon.Visible = false

		self.NameTag.Font = Enum.Font.SourceSansBold
	else
		self.NameTag.Font = Enum.Font.SourceSans

	end
end

function methods:RenderDisplayText()
	
end

function methods:SetFontSize(fontSize)
	self.NameTag.FontSize = fontSize
end


function methods:FadeOutBackground(duration)
	self.BackgroundTweener:Tween(duration, 1)
end

function methods:FadeInBackground(duration)
	self.BackgroundTweener:Tween(duration, 0)
end

function methods:FadeOutText(duration)
	self.TextTweener:Tween(duration, 1)
end

function methods:FadeInText(duration)
	self.TextTweener:Tween(duration, 0)
end

function methods:CreateTweeners()
	self.BackgroundTweener:CancelTween()
	self.TextTweener:CancelTween()

	self.BackgroundTweener = moduleTransparencyTweener.new()
	self.TextTweener = moduleTransparencyTweener.new()

	--// Register BackgroundTweener objects and properties
	self.BackgroundTweener:RegisterTweenObjectProperty(self.UnselectedFrame, "BackgroundTransparency")
	self.BackgroundTweener:RegisterTweenObjectProperty(self.SelectedFrame.BackgroundImage, "BackgroundTransparency")
	self.BackgroundTweener:RegisterTweenObjectProperty(self.SelectedFrame.BlueBarLeft, "ImageTransparency")
	self.BackgroundTweener:RegisterTweenObjectProperty(self.SelectedFrame.BlueBarRight, "ImageTransparency")

	--// Register TextTweener objects and properties
	self.TextTweener:RegisterTweenObjectProperty(self.NameTag, "TextTransparency")
	self.TextTweener:RegisterTweenObjectProperty(self.NameTag, "TextStrokeTransparency")
	self.TextTweener:RegisterTweenObjectProperty(self.NewMessageIcon, "ImageTransparency")
	self.TextTweener:RegisterTweenObjectProperty(self.WhiteTextNewMessageNotification, "TextTransparency")
	self.TextTweener:RegisterTweenObjectProperty(self.WhiteTextNewMessageNotification, "TextStrokeTransparency")

	--print("Dumping:", self:Dump(), "||", self.BackgroundTweener:Dump())
	--print("Dumping:", self:Dump(), "||", self.TextTweener:Dump())
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("ChannelsTab", methods)

function module.new(channelName)
	local obj = {}

	local BaseFrame, NameTag, NewMessageIcon, UnselectedFrame, SelectedFrame = CreateGuiObjects()
	obj.GuiObject = BaseFrame
	obj.NameTag = NameTag
	obj.NewMessageIcon = NewMessageIcon
	obj.UnselectedFrame = UnselectedFrame
	obj.SelectedFrame = SelectedFrame

	--// These four aren't used, but need to be kept as 
	--// references so they wont be garbage collected in 
	--// the tweener objects until this Tab object is 
	--// garbage collected when it is no longer in use.
	obj.BlueBarLeft = SelectedFrame.BlueBarLeft
	obj.BlueBarRight = SelectedFrame.BlueBarRight
	obj.BackgroundImage = SelectedFrame.BackgroundImage
	obj.WhiteTextNewMessageNotification = obj.NewMessageIcon.TextLabel

	obj.ChannelName = channelName
	obj.UnreadMessageCount = 0
	obj.Active = false

	obj.BackgroundTweener = moduleTransparencyTweener.new()
	obj.TextTweener = moduleTransparencyTweener.new()

	obj.GuiObject.Name = "Frame_" .. obj.ChannelName

	local maxNameLength = 12
	if (string.len(channelName) > maxNameLength) then
		channelName = string.sub(channelName, 1, maxNameLength - 3) .. "..."
	end
	obj.NameTag.Text = channelName

	ClassMaker.MakeClass("ChannelsTab", obj)

	obj:CreateTweeners()
	obj:SetActive(false)	

	return obj
end

return module
]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script