local source = [[
--	// FileName: ChatWindow.lua
--	// Written by: Xsitsu
--	// Description: Main GUI window piece. Manages ChatBar, ChannelsBar, and ChatChannels.

local module = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--////////////////////////////// Include
--//////////////////////////////////////
local modulesFolder = script.Parent
local moduleChatChannel = require(modulesFolder:WaitForChild("ChatChannel"))
local moduleTransparencyTweener = require(modulesFolder:WaitForChild("TransparencyTweener"))
local ChatSettings = require(modulesFolder:WaitForChild("ChatSettings"))
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

local function CreateGuiObjects()
	local BaseFrame = Instance.new("Frame")
	BaseFrame.BackgroundTransparency = 1
	BaseFrame.Active = true
	
	local FirstParentedEvent = Instance.new("BindableEvent", BaseFrame)
	FirstParentedEvent.Name = "FirstParented"

	local function doCheckMinimumResize()
		if (not BaseFrame:IsDescendantOf(PlayerGui)) then return end

		if (BaseFrame.AbsoluteSize.X < ChatSettings.MinimumWindowSizeX) then
			local offset = UDim2.new(0, ChatSettings.MinimumWindowSizeX - BaseFrame.AbsoluteSize.X, 0, 0)
			BaseFrame.Size = BaseFrame.Size + offset
		end

		if (BaseFrame.AbsoluteSize.Y < ChatSettings.MinimumWindowSizeY) then
			local offset = UDim2.new(0, 0, 0, ChatSettings.MinimumWindowSizeY - BaseFrame.AbsoluteSize.Y)
			BaseFrame.Size = BaseFrame.Size + offset
		end
	end

	BaseFrame.Changed:connect(function(prop)
		if (prop == "AbsoluteSize") then
			doCheckMinimumResize()
		end
	end)



	local ChatBarParentFrame = Instance.new("Frame", BaseFrame)
	ChatBarParentFrame.Selectable = false
	ChatBarParentFrame.Name = "ChatBarParentFrame"
	ChatBarParentFrame.BackgroundTransparency = 1

	local ChannelsBarParentFrame = Instance.new("Frame", BaseFrame)
	ChannelsBarParentFrame.Selectable = false
	ChannelsBarParentFrame.Name = "ChannelsBarParentFrame"
	ChannelsBarParentFrame.BackgroundTransparency = 1
	ChannelsBarParentFrame.Position = UDim2.new(0, 0, 0, 0)

	local ChatChannelParentFrame = Instance.new("Frame", BaseFrame)
	ChatChannelParentFrame.Selectable = false
	ChatChannelParentFrame.Name = "ChatChannelParentFrame"
	ChatChannelParentFrame.BackgroundTransparency = 1

	ChatChannelParentFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	ChatChannelParentFrame.BackgroundTransparency = 0.6
	ChatChannelParentFrame.BorderSizePixel = 0

	local ChatResizerFrame = Instance.new("ImageButton", BaseFrame)
	ChatResizerFrame.Selectable = false
	ChatResizerFrame.Image = ""
	ChatResizerFrame.BackgroundTransparency = 0.6
	ChatResizerFrame.BorderSizePixel = 0
	ChatResizerFrame.Visible = false
	ChatResizerFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	ChatResizerFrame.Active = true

	local ResizeIcon = Instance.new("ImageLabel", ChatResizerFrame)
	ResizeIcon.Selectable = false
	ResizeIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
	ResizeIcon.Position = UDim2.new(0.2, 0, 0.2, 0)
	ResizeIcon.BackgroundTransparency = 1
	ResizeIcon.Image = "rbxassetid://261880743"


	ChatResizerFrame.DragBegin:connect(function(startUdim)
		BaseFrame.Active = false
	end)

	local function UpdatePositionFromDrag(atPos)
		local newSize = atPos - BaseFrame.AbsolutePosition + ChatResizerFrame.AbsoluteSize
		BaseFrame.Size = UDim2.new(0, newSize.X, 0, newSize.Y)
		ChatResizerFrame.Position = UDim2.new(1, -ChatResizerFrame.AbsoluteSize.X, 1, -ChatResizerFrame.AbsoluteSize.Y)
	end

	ChatResizerFrame.DragStopped:connect(function(endX, endY)
		BaseFrame.Active = true
		--UpdatePositionFromDrag(Vector2.new(endX, endY))
	end)

	local resizeLock = false
	ChatResizerFrame.Changed:connect(function(prop)
		if (prop == "AbsolutePosition" and not BaseFrame.Active) then
			if (resizeLock) then return end
			resizeLock = true

			UpdatePositionFromDrag(ChatResizerFrame.AbsolutePosition)

			resizeLock = false
		end
	end)

	if (not Players.ClassicChat and Players.BubbleChat) then
		ChatBarParentFrame.Position = UDim2.new(0, 0, 0, 0)
		ChannelsBarParentFrame.Visible = false
		ChatChannelParentFrame.Visible = false

		FirstParentedEvent.Event:connect(function()
			BaseFrame.Size = UDim2.new(ChatSettings.DefaultWindowSize.X.Scale, ChatSettings.DefaultWindowSize.X.Offset, 0, chatBarYSize)    
			BaseFrame.Position = ChatSettings.DefaultWindowPosition
			FirstParentedEvent:Destroy()
		end)
	else
		FirstParentedEvent.Event:connect(function()
			BaseFrame.Size = ChatSettings.DefaultWindowSize
			BaseFrame.Position = ChatSettings.DefaultWindowPosition
			FirstParentedEvent:Destroy()
		end)

	end

	local function CalculateChannelsBarPixelSize(size)
		size = size or ChatSettings.ChatChannelsTabTextSize
		local channelsBarTextYSize = string.match(size.Name, "%d+")
		local chatChannelYSize = math.max(32, channelsBarTextYSize + 8) + 2

		return chatChannelYSize
	end

	local function CalculateChatBarPixelSize(size)
		size = size or ChatSettings.ChatBarTextSize
		local chatBarTextSizeY = string.match(size.Name, "%d+")
		local chatBarYSize = chatBarTextSizeY + 16 + 16

		return chatBarYSize
	end

	local function UpdateDraggable(enabled)
		BaseFrame.Draggable = enabled
	end

	local function UpdateResizable(enabled)
		ChatResizerFrame.Visible = enabled
		ChatResizerFrame.Draggable = enabled

		local frameSizeY = ChatBarParentFrame.Size.Y.Offset

		if (enabled) then
			ChatBarParentFrame.Size = UDim2.new(1, -frameSizeY - 2, 0, frameSizeY)
			ChatBarParentFrame.Position = UDim2.new(0, 0, 1, -frameSizeY)
		else
			ChatBarParentFrame.Size = UDim2.new(1, 0, 0, frameSizeY)
			ChatBarParentFrame.Position = UDim2.new(0, 0, 1, -frameSizeY)
		end
	end

	local function UpdateChatChannelParentFrameSize()
		local channelsBarSize = CalculateChannelsBarPixelSize()
		local chatBarSize = CalculateChatBarPixelSize()

		ChatChannelParentFrame.Size = UDim2.new(1, 0, 1, -channelsBarSize - chatBarSize - 2 - 2)
		ChatChannelParentFrame.Position = UDim2.new(0, 0, 0, channelsBarSize + 2)

	end

	local function UpdateChatChannelsTabTextSize(size)
		local channelsBarSize = CalculateChannelsBarPixelSize(size)
		ChannelsBarParentFrame.Size = UDim2.new(1, 0, 0, channelsBarSize)

		UpdateChatChannelParentFrameSize()
	end

	local function UpdateChatBarTextSize(size)
		local chatBarSize = CalculateChatBarPixelSize(size)

		ChatBarParentFrame.Size = UDim2.new(1, 0, 0, chatBarSize)
		ChatBarParentFrame.Position = UDim2.new(0, 0, 1, -chatBarSize)

		ChatResizerFrame.Size = UDim2.new(0, chatBarSize, 0, chatBarSize)
		ChatResizerFrame.Position = UDim2.new(1, -chatBarSize, 1, -chatBarSize)

		UpdateChatChannelParentFrameSize()
		UpdateResizable(ChatSettings.WindowResizable)
	end

	UpdateChatChannelsTabTextSize(ChatSettings.ChatChannelsTabTextSize)
	UpdateChatBarTextSize(ChatSettings.ChatBarTextSize)
	UpdateDraggable(ChatSettings.WindowDraggable)
	UpdateResizable(ChatSettings.WindowResizable)

	ChatSettings.SettingsChanged:connect(function(setting, value)
		if (setting == "WindowDraggable") then
			UpdateDraggable(value)

		elseif (setting == "WindowResizable") then
			UpdateResizable(value)

		elseif (setting == "ChatChannelsTabTextSize") then
			UpdateChatChannelsTabTextSize(value)

		elseif (setting == "ChatBarTextSize") then
			UpdateChatBarTextSize(value)

		end
	end)

	return BaseFrame, ChatBarParentFrame, ChannelsBarParentFrame, ChatChannelParentFrame, ChatResizerFrame, ResizeIcon
end

function methods:RegisterChatBar(ChatBar)
	rawset(self, "ChatBar", ChatBar)
	self.ChatBar.GuiObject.Parent = self.ChatBarParentFrame

	self.BackgroundTweener:RegisterTweenObjectProperty(ChatBar.BackgroundTweener, "Transparency")
	self.TextTweener:RegisterTweenObjectProperty(ChatBar.TextTweener, "Transparency")
end

function methods:RegisterChannelsBar(ChannelsBar)
	rawset(self, "ChannelsBar", ChannelsBar)
	self.ChannelsBar.GuiObject.Parent = self.ChannelsBarParentFrame

	self.BackgroundTweener:RegisterTweenObjectProperty(ChannelsBar.BackgroundTweener, "Transparency")
	self.TextTweener:RegisterTweenObjectProperty(ChannelsBar.TextTweener, "Transparency")
end

function methods:AddChannel(channelName)
	if (self:GetChannel(channelName))  then
		--error("Channel '" .. channelName .. "' already exists!")
		return
	end
	
	local channel = moduleChatChannel.new(channelName)
	self.Channels[channelName:lower()] = channel

	channel.GuiObject.Parent = self.ChatChannelParentFrame
	channel:SetActive(false)

	local tab = self.ChannelsBar:AddChannelTab(channelName)
	tab.NameTag.MouseButton1Click:connect(function()
		self:SwitchCurrentChannel(channelName)
	end)

	--self.BackgroundTweener:RegisterTweenObjectProperty(channel.BackgroundTweener, "Transparency")
	self.TextTweener:RegisterTweenObjectProperty(channel.TextTweener, "Transparency")

	channel:RegisterChannelTab(tab)

	return channel
end

function methods:GetFirstChannel()
	--// Channels are not indexed numerically, so this function is necessary.
	--// Grabs and returns the first channel it happens to, or nil if none exist.
	for i, v in pairs(self.Channels) do
		return v
	end
	return nil
end

function methods:RemoveChannel(channelName)
	if (not self:GetChannel(channelName))  then
		error("Channel '" .. channelName .. "' does not exist!")
	end
	
	local indexName = channelName:lower()

	local needsChannelSwitch = false
	if (self.Channels[indexName] == self:GetCurrentChannel()) then
		needsChannelSwitch = true

		self:SwitchCurrentChannel(nil)
	end
	
	self.Channels[indexName]:Destroy()
	self.Channels[indexName] = nil

	self.ChannelsBar:RemoveChannelTab(channelName)

	if (needsChannelSwitch) then
		local generalChannelExists = (self:GetChannel(ChatSettings.GeneralChannelName) ~= nil)
		local removingGeneralChannel = (indexName == ChatSettings.GeneralChannelName:lower())

		if (generalChannelExists and not removingGeneralChannel) then
			self:SwitchCurrentChannel(ChatSettings.GeneralChannelName)
		else
			local firstChannel = self:GetFirstChannel()
			self:SwitchCurrentChannel(firstChannel and firstChannel.Name or nil)
		end
	end
end

function methods:GetChannel(channelName)
	return channelName and self.Channels[channelName:lower()] or nil
end

function methods:GetCurrentChannel()
	return rawget(self, "CurrentChannel")
end

function methods:SwitchCurrentChannel(channelName)
	local cur = self:GetCurrentChannel()

	if (cur) then
		cur:SetActive(false)
		local tab = self.ChannelsBar:GetChannelTab(cur.Name)
		tab:SetActive(false)
	end

	local new = self:GetChannel(channelName)

	if (new) then
		new:SetActive(true)
		local tab = self.ChannelsBar:GetChannelTab(new.Name)
		tab:SetActive(true)
	end

	rawset(self, "CurrentChannel", new)
end

function methods:UpdateFrameVisibility()
	self.GuiObject.Visible = (self.Visible and self.CoreGuiEnabled)
end

function methods:GetVisible()
	return self.Visible
end

function methods:SetVisible(visible)
	self.Visible = visible
	self:UpdateFrameVisibility()
end

function methods:GetCoreGuiEnabled()
	return self.CoreGuiEnabled
end

function methods:SetCoreGuiEnabled(enabled)
	self.CoreGuiEnabled = enabled
	self:UpdateFrameVisibility()
end

function methods:FadeOutBackground(duration)
	--self.ChannelsBar:FadeOutBackground(duration)
	--self.ChatBar:FadeOutBackground(duration)

	if (self:GetCurrentChannel()) then
		self:GetCurrentChannel():FadeOutBackground(duration)
	end

	self.BackgroundTweener:Tween(duration, 1)
end

function methods:FadeInBackground(duration)
	--self.ChannelsBar:FadeInBackground(duration)
	--self.ChatBar:FadeInBackground(duration)

	if (self:GetCurrentChannel()) then
		self:GetCurrentChannel():FadeInBackground(duration)
	end

	self.BackgroundTweener:Tween(duration, 0)
end

function methods:FadeOutText(duration)
	--self.ChannelsBar:FadeOutText(duration)
	--self.ChatBar:FadeOutText(duration)

	if (self:GetCurrentChannel()) then
		self:GetCurrentChannel():FadeOutText(duration)
	end

	self.TextTweener:Tween(duration, 1)
end

function methods:FadeInText(duration)
	--self.ChannelsBar:FadeInText(duration)
	--self.ChatBar:FadeInText(duration)

	if (self:GetCurrentChannel()) then
		self:GetCurrentChannel():FadeInText(duration)
	end

	self.TextTweener:Tween(duration, 0)
end

function methods:CreateTweeners()
	self.BackgroundTweener:CancelTween()
	self.TextTweener:CancelTween()

	self.BackgroundTweener = moduleTransparencyTweener.new()
	self.TextTweener = moduleTransparencyTweener.new()

	--// Register BackgroundTweener objects and properties
	self.BackgroundTweener:RegisterTweenObjectProperty(self.ChatChannelParentFrame, "BackgroundTransparency")
	self.BackgroundTweener:RegisterTweenObjectProperty(self.ChatResizerFrame, "BackgroundTransparency")
	self.BackgroundTweener:RegisterTweenObjectProperty(self.ResizeIcon, "ImageTransparency")

	--// Register TextTweener objects and properties
		-- there are none...
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("ChatWindow", methods)

function module.new()
	local obj = {}

	local BaseFrame, ChatBarParentFrame, ChannelsBarParentFrame, ChatChannelParentFrame, ChatResizerFrame, ResizeIcon = CreateGuiObjects()
	obj.GuiObject = BaseFrame
	obj.ChatBarParentFrame = ChatBarParentFrame
	obj.ChannelsBarParentFrame = ChannelsBarParentFrame
	obj.ChatChannelParentFrame = ChatChannelParentFrame
	obj.ChatResizerFrame = ChatResizerFrame
	obj.ResizeIcon = ResizeIcon

	obj.ChatBar = nil
	obj.ChannelsBar = nil
	
	obj.Channels = {}
	obj.CurrentChannel = nil

	obj.Visible = true
	obj.CoreGuiEnabled = true

	obj.BackgroundTweener = moduleTransparencyTweener.new()
	obj.TextTweener = moduleTransparencyTweener.new()

	ClassMaker.MakeClass("ChatWindow", obj)

	obj:CreateTweeners()

	return obj
end

return module
]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script