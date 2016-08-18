local source = [[
local module = {}

local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

--////////////////////////////// Include
--//////////////////////////////////////
local modulesFolder = script.Parent
local moduleChannelsTab = require(modulesFolder:WaitForChild("ChannelsTab"))
local moduleTransparencyTweener = require(modulesFolder:WaitForChild("TransparencyTweener"))
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))
local MessageSender = require(modulesFolder:WaitForChild("MessageSender"))
local ChatSettings = require(modulesFolder:WaitForChild("ChatSettings"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

local function CreateGuiObjects()
	local BaseFrame = Instance.new("Frame")
	BaseFrame.Size = UDim2.new(1, 0, 1, 0)
	BaseFrame.BackgroundTransparency = 1

	local ScrollingBase = Instance.new("Frame", BaseFrame)
	ScrollingBase.Name = "ScrollingBase"
	ScrollingBase.BackgroundTransparency = 1
	ScrollingBase.ClipsDescendants = true
	ScrollingBase.Size = UDim2.new(1, 0, 1, 0)
	ScrollingBase.Position = UDim2.new(0, 0, 0, 0)

	local ScrollerSizer = Instance.new("Frame", ScrollingBase)
	ScrollerSizer.Name = "ScrollerSizer"
	ScrollerSizer.BackgroundTransparency = 1
	ScrollerSizer.Size = UDim2.new(1, 0, 1, 0)
	ScrollerSizer.Position = UDim2.new(0, 0, 0, 0)

	local ScrollerFrame = Instance.new("Frame", ScrollerSizer)
	ScrollerFrame.Name = "ScrollerFrame"
	ScrollerFrame.BackgroundTransparency = 1
	ScrollerFrame.Size = UDim2.new(1, 0, 1, 0)
	ScrollerFrame.Position = UDim2.new(0, 0, 0, 0)



	local LeaveConfirmationFrameBase = Instance.new("Frame", BaseFrame)
	LeaveConfirmationFrameBase.Size = UDim2.new(1, 0, 1, 0)
	LeaveConfirmationFrameBase.Position = UDim2.new(0, 0, 0, 0)
	LeaveConfirmationFrameBase.ClipsDescendants = true
	LeaveConfirmationFrameBase.BackgroundTransparency = 1

	local LeaveConfirmationFrame = Instance.new("Frame", LeaveConfirmationFrameBase)
	LeaveConfirmationFrame.Name = "LeaveConfirmationFrame"
	LeaveConfirmationFrame.Size = UDim2.new(1, 0, 1, 0)
	LeaveConfirmationFrame.Position = UDim2.new(0, 0, 1, 0)
	LeaveConfirmationFrame.BackgroundTransparency = 0.6
	LeaveConfirmationFrame.BorderSizePixel = 0
	LeaveConfirmationFrame.BackgroundColor3 = Color3.new(0, 0, 0)

	local InputBlocker = Instance.new("TextButton", LeaveConfirmationFrame)
	InputBlocker.Size = UDim2.new(1, 0, 1, 0)
	InputBlocker.BackgroundTransparency = 1
	InputBlocker.Text = ""

	local LeaveConfirmationButtonYes = Instance.new("TextButton", LeaveConfirmationFrame)
	LeaveConfirmationButtonYes.Size = UDim2.new(0.25, 0, 1, 0)
	LeaveConfirmationButtonYes.BackgroundTransparency = 1
	LeaveConfirmationButtonYes.Font = Enum.Font.SourceSansBold
	LeaveConfirmationButtonYes.FontSize = Enum.FontSize.Size18
	LeaveConfirmationButtonYes.TextStrokeTransparency = 0.75
	LeaveConfirmationButtonYes.Position = UDim2.new(0, 0, 0, 0)
	LeaveConfirmationButtonYes.TextColor3 = Color3.new(0, 1, 0)
	LeaveConfirmationButtonYes.Text = "Confirm"
	
	local LeaveConfirmationButtonNo = LeaveConfirmationButtonYes:Clone()
	LeaveConfirmationButtonNo.Parent = LeaveConfirmationFrame
	LeaveConfirmationButtonNo.Position = UDim2.new(0.75, 0, 0, 0)
	LeaveConfirmationButtonNo.TextColor3 = Color3.new(1, 0, 0)
	LeaveConfirmationButtonNo.Text = "Cancel"

	local LeaveConfirmationNotice = Instance.new("TextLabel", LeaveConfirmationFrame)
	LeaveConfirmationNotice.Size = UDim2.new(0.5, 0, 1, 0)
	LeaveConfirmationNotice.Position = UDim2.new(0.25, 0, 0, 0)
	LeaveConfirmationNotice.BackgroundTransparency = 1
	LeaveConfirmationNotice.TextColor3 = Color3.new(1, 1, 1)
	LeaveConfirmationNotice.TextStrokeTransparency = 0.75
	LeaveConfirmationNotice.Text = "Leave channel <XX>?"
	LeaveConfirmationNotice.Font = Enum.Font.SourceSansBold
	LeaveConfirmationNotice.FontSize = Enum.FontSize.Size18

	local LeaveTarget = Instance.new("StringValue", LeaveConfirmationFrame)
	LeaveTarget.Name = "LeaveTarget"

	local outPos = LeaveConfirmationFrame.Position
	LeaveConfirmationButtonYes.MouseButton1Click:connect(function()
		MessageSender:SendMessage(string.format("/leave %s", LeaveTarget.Value), nil)
		LeaveConfirmationFrame:TweenPosition(outPos, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
	end)
	LeaveConfirmationButtonNo.MouseButton1Click:connect(function()
		LeaveConfirmationFrame:TweenPosition(outPos, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
	end)



	local scale = 0.7
	local scaleOther = (1 - scale) / 2

	local PageLeftButton = Instance.new("ImageButton", BaseFrame)
	PageLeftButton.Name = "PageLeftButton"
	PageLeftButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
	PageLeftButton.Size = UDim2.new(scale, 0, scale, 0)
	PageLeftButton.BackgroundTransparency = 1
	PageLeftButton.Position = UDim2.new(0, 4, scaleOther, 0)
	PageLeftButton.Visible = false
	PageLeftButton.Image = "rbxasset://textures/ui/Chat/TabArrowBackground.png"
	local ArrowLabel = Instance.new("ImageLabel", PageLeftButton)
	ArrowLabel.Name = "ArrowLabel"
	ArrowLabel.BackgroundTransparency = 1
	ArrowLabel.Size = UDim2.new(0.4, 0, 0.4, 0)
	ArrowLabel.Image = "rbxasset://textures/ui/Chat/TabArrow.png"

	local PageRightButtonPositionalHelper = Instance.new("Frame", BaseFrame)
	PageRightButtonPositionalHelper.BackgroundTransparency = 1
	PageRightButtonPositionalHelper.Name = "PositionalHelper"
	PageRightButtonPositionalHelper.Size = PageLeftButton.Size
	PageRightButtonPositionalHelper.SizeConstraint = PageLeftButton.SizeConstraint
	PageRightButtonPositionalHelper.Position = UDim2.new(1, 0, scaleOther, 0)

	local PageRightButton = PageLeftButton:Clone()
	PageRightButton.Parent = PageRightButtonPositionalHelper
	PageRightButton.Name = "PageRightButton"
	PageRightButton.Size = UDim2.new(1, 0, 1, 0)
	PageRightButton.SizeConstraint = Enum.SizeConstraint.RelativeXY
	PageRightButton.Position = UDim2.new(-1, -4, 0, 0)

	local positionOffset = UDim2.new(0.05, 0, 0, 0)

	PageRightButton.ArrowLabel.Position = UDim2.new(0.3, 0, 0.3, 0) + positionOffset
	PageLeftButton.ArrowLabel.Position = UDim2.new(0.3, 0, 0.3, 0) - positionOffset
	PageLeftButton.ArrowLabel.Rotation = 180


	return BaseFrame, ScrollerSizer, ScrollerFrame, PageLeftButton, PageRightButton, LeaveConfirmationFrame, LeaveConfirmationNotice
end


function methods:UpdateMessagePostedInChannel(channelName)
	local tab = self:GetChannelTab(channelName)
	if (tab) then
		tab:UpdateMessagePostedInChannel()
	else
		warn("ChannelsTab '" .. channelName .. "' does not exist!")
	end
end
		
function methods:AddChannelTab(channelName)
	if (self:GetChannelTab(channelName)) then
		error("Channel tab '" .. channelName .. "'already exists!")
	end

	local tab = moduleChannelsTab.new(channelName)
	tab.GuiObject.Parent = self.ScrollerFrame
	self.ChannelTabs[channelName:lower()] = tab

	self.NumTabs = self.NumTabs + 1
	self:OrganizeChannelTabs()

	self.BackgroundTweener:RegisterTweenObjectProperty(tab.BackgroundTweener, "Transparency")
	self.TextTweener:RegisterTweenObjectProperty(tab.TextTweener, "Transparency")

	--// Although this feature is pretty much ready, it needs some UI design still.
	local enableRightClickToLeaveChannel = false

	if (enableRightClickToLeaveChannel) then
		tab.NameTag.MouseButton2Click:connect(function()
			self.LeaveConfirmationNotice.Text = string.format("Leave channel %s?", tab.ChannelName)
			self.LeaveConfirmationFrame.LeaveTarget.Value = tab.ChannelName
			self.LeaveConfirmationFrame:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.2, true)
		end)
	end

	return tab
end

function methods:RemoveChannelTab(channelName)
	if (not self:GetChannelTab(channelName)) then
		error("Channel tab '" .. channelName .. "'does not exist!")
	end

	local indexName = channelName:lower() 
	self.ChannelTabs[indexName]:Destroy()
	self.ChannelTabs[indexName] = nil

	self.NumTabs = self.NumTabs - 1
	self:OrganizeChannelTabs()
end

function methods:GetChannelTab(channelName)
	return self.ChannelTabs[channelName:lower()]
end

function methods:OrganizeChannelTabs()
	local order = {}

	table.insert(order, self:GetChannelTab(ChatSettings.GeneralChannelName))
	table.insert(order, self:GetChannelTab("System"))

	for tabIndexName, tab in pairs(self.ChannelTabs) do
		if (tab.ChannelName ~= ChatSettings.GeneralChannelName and tab.ChannelName ~= "System") then
			table.insert(order, tab)
		end
	end

	for index, tab in pairs(order) do
		tab.GuiObject.Position = UDim2.new(index - 1, 0, 0, 0)
	end

	--// Dynamic tab resizing
	self.ScrollerSizer.Size = UDim2.new(1 / math.max(1, math.min(ChatSettings.ChannelsBarFullTabSize, self.NumTabs)), 0, 1, 0)

	self:ScrollChannelsFrame(0)
end

function methods:ScrollChannelsFrame(dir)
	if (self.ScrollChannelsFrameLock) then return end
	self.ScrollChannelsFrameLock = true

	local tabNumber = ChatSettings.ChannelsBarFullTabSize

	local newPageNum = self.CurPageNum + dir
	if (newPageNum < 0) then
		newPageNum = 0
	elseif (newPageNum > 0 and newPageNum + tabNumber > self.NumTabs) then
		newPageNum = self.NumTabs - tabNumber
	end

	self.CurPageNum = newPageNum

	local tweenTime = 0.15
	local endPos = UDim2.new(-self.CurPageNum, 0, 0, 0)

	self.PageLeftButton.Visible = (self.CurPageNum > 0)
	self.PageRightButton.Visible = (self.CurPageNum + tabNumber < self.NumTabs)

	local function UnlockFunc()
		self.ScrollChannelsFrameLock = false
	end
	
	self.ScrollerFrame:TweenPosition(endPos, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, tweenTime, true, UnlockFunc)
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
	self.BackgroundTweener:RegisterTweenObjectProperty(self.PageLeftButton, "ImageTransparency")
	self.BackgroundTweener:RegisterTweenObjectProperty(self.PageRightButton, "ImageTransparency")
	self.BackgroundTweener:RegisterTweenObjectProperty(self.PageLeftButtonArrow, "ImageTransparency")
	self.BackgroundTweener:RegisterTweenObjectProperty(self.PageRightButtonArrow, "ImageTransparency")

	--// Register TextTweener objects and properties
	
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("ChannelsBar", methods)

function module.new()
	local obj = {}

	local BaseFrame, ScrollerSizer, ScrollerFrame, PageLeftButton, PageRightButton, LeaveConfirmationFrame, LeaveConfirmationNotice = CreateGuiObjects()
	obj.GuiObject = BaseFrame
	obj.ScrollerSizer = ScrollerSizer
	obj.ScrollerFrame = ScrollerFrame
	obj.PageLeftButton = PageLeftButton
	obj.PageRightButton = PageRightButton
	obj.LeaveConfirmationFrame = LeaveConfirmationFrame
	obj.LeaveConfirmationNotice = LeaveConfirmationNotice

	obj.PageLeftButtonArrow = obj.PageLeftButton.ArrowLabel
	obj.PageRightButtonArrow = obj.PageRightButton.ArrowLabel

	obj.ChannelTabs = {}
	obj.NumTabs = 0
	obj.CurPageNum = 0

	obj.BackgroundTweener = moduleTransparencyTweener.new()
	obj.TextTweener = moduleTransparencyTweener.new()

	obj.ScrollChannelsFrameLock = false

	ClassMaker.MakeClass("ChannelsBar", obj)

	obj:CreateTweeners()

	PageLeftButton.MouseButton1Click:connect(function() obj:ScrollChannelsFrame(-1) end)
	PageRightButton.MouseButton1Click:connect(function() obj:ScrollChannelsFrame(1) end)

	--// Have to wait to tween until it's properly parented to PlayerGui
	spawn(function()
		while (not obj.GuiObject:IsDescendantOf(PlayerGui)) do
			obj.GuiObject.AncenstryChanged:wait()
		end
		obj:ScrollChannelsFrame(0)
	end)

	return obj
end

return module
]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script