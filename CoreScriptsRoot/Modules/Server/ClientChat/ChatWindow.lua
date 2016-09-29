--	// FileName: ChatWindow.lua
--	// Written by: Xsitsu
--	// Description: Main GUI window piece. Manages ChatBar, ChannelsBar, and ChatChannels.

local module = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local PHONE_SCREEN_WIDTH = 640
local TABLET_SCREEN_WIDTH = 1024

local DEVICE_PHONE = 1
local DEVICE_TABLET = 2
local DEVICE_DESKTOP = 3

--////////////////////////////// Include
--//////////////////////////////////////
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local clientChatModules = ReplicatedStorage:WaitForChild("ClientChatModules")
local modulesFolder = script.Parent
local moduleChatChannel = require(modulesFolder:WaitForChild("ChatChannel"))
local moduleTransparencyTweener = require(modulesFolder:WaitForChild("TransparencyTweener"))
local ChatSettings = require(clientChatModules:WaitForChild("ChatSettings"))
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))
local CurveUtil = require(modulesFolder:WaitForChild("CurveUtil"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

function methods:CreateGuiObjects(targetParent)
	local BaseFrame = Instance.new("Frame", targetParent)
	BaseFrame.BackgroundTransparency = 1
	BaseFrame.Active = true

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

	local function GetScreenGuiParent()
		--// Travel up parent list until you find the ScreenGui that the chat window is parented to
		local screenGuiParent = BaseFrame
		while (screenGuiParent and not screenGuiParent:IsA("ScreenGui")) do
			screenGuiParent = screenGuiParent.Parent
		end

		return screenGuiParent
	end


	local deviceType = DEVICE_DESKTOP

	local screenGuiParent = GetScreenGuiParent()
	if (screenGuiParent.AbsoluteSize.X <= PHONE_SCREEN_WIDTH) then
		deviceType = DEVICE_PHONE

	elseif (screenGuiParent.AbsoluteSize.X <= TABLET_SCREEN_WIDTH) then
		deviceType = DEVICE_TABLET

	end

	local checkSizeLock = false
	local function doCheckSizeBounds()
		if (checkSizeLock) then return end
		checkSizeLock = true

		if (not BaseFrame:IsDescendantOf(PlayerGui)) then return end

		local screenGuiParent = GetScreenGuiParent()

		local minWinSize = ChatSettings.MinimumWindowSize
		local maxWinSize = ChatSettings.MaximumWindowSize

		local forceMinY = ChannelsBarParentFrame.AbsoluteSize.Y + ChatBarParentFrame.AbsoluteSize.Y

		local minSizePixelX = (minWinSize.X.Scale * screenGuiParent.AbsoluteSize.X) + minWinSize.X.Offset
		local minSizePixelY = math.max((minWinSize.Y.Scale * screenGuiParent.AbsoluteSize.Y) + minWinSize.Y.Offset, forceMinY)

		local maxSizePixelX = (maxWinSize.X.Scale * screenGuiParent.AbsoluteSize.X) + maxWinSize.X.Offset
		local maxSizePixelY = (maxWinSize.Y.Scale * screenGuiParent.AbsoluteSize.Y) + maxWinSize.Y.Offset

		local absSizeX = BaseFrame.AbsoluteSize.X
		local absSizeY = BaseFrame.AbsoluteSize.Y

		if (absSizeX < minSizePixelX) then
			local offset = UDim2.new(0, minSizePixelX - absSizeX, 0, 0)
			BaseFrame.Size = BaseFrame.Size + offset

		elseif (absSizeX > maxSizePixelX) then
			local offset = UDim2.new(0, maxSizePixelX - absSizeX, 0, 0)
			BaseFrame.Size = BaseFrame.Size + offset

		end

		if (absSizeY < minSizePixelY) then
			local offset = UDim2.new(0, 0, 0, minSizePixelY - absSizeY)
			BaseFrame.Size = BaseFrame.Size + offset

		elseif (absSizeY > maxSizePixelY) then
			local offset = UDim2.new(0, 0, 0, maxSizePixelY - absSizeY)
			BaseFrame.Size = BaseFrame.Size + offset

		end

		local xScale = BaseFrame.AbsoluteSize.X / screenGuiParent.AbsoluteSize.X
		local yScale = BaseFrame.AbsoluteSize.Y / screenGuiParent.AbsoluteSize.Y
		BaseFrame.Size = UDim2.new(xScale, 0, yScale, 0)

		checkSizeLock = false
	end


	BaseFrame.Changed:connect(function(prop)
		if (prop == "AbsoluteSize") then
			doCheckSizeBounds()
		end
	end)



	ChatResizerFrame.DragBegin:connect(function(startUdim)
		BaseFrame.Draggable = false
	end)

	local function UpdatePositionFromDrag(atPos)
		local newSize = atPos - BaseFrame.AbsolutePosition + ChatResizerFrame.AbsoluteSize
		BaseFrame.Size = UDim2.new(0, newSize.X, 0, newSize.Y)
		ChatResizerFrame.Position = UDim2.new(1, -ChatResizerFrame.AbsoluteSize.X, 1, -ChatResizerFrame.AbsoluteSize.Y)
	end

	ChatResizerFrame.DragStopped:connect(function(endX, endY)
		BaseFrame.Draggable = ChatSettings.WindowDraggable
		--UpdatePositionFromDrag(Vector2.new(endX, endY))
	end)

	local resizeLock = false
	ChatResizerFrame.Changed:connect(function(prop)
		if (prop == "AbsolutePosition" and not BaseFrame.Draggable) then
			if (resizeLock) then return end
			resizeLock = true

			UpdatePositionFromDrag(ChatResizerFrame.AbsolutePosition)

			resizeLock = false
		end
	end)

	local bubbleChatOnly = not Players.ClassicChat and Players.BubbleChat
	if (bubbleChatOnly) then
		ChatBarParentFrame.Position = UDim2.new(0, 0, 0, 0)
		ChannelsBarParentFrame.Visible = false
		ChatChannelParentFrame.Visible = false

		local useXScale = 0
		local useXOffset = 0

		local screenGuiParent = GetScreenGuiParent()

		if (deviceType == DEVICE_PHONE) then
			useXScale = ChatSettings.DefaultWindowSizePhone.X.Scale
			useXOffset = ChatSettings.DefaultWindowSizePhone.X.Offset

		elseif (deviceType == DEVICE_TABLET) then
			useXScale = ChatSettings.DefaultWindowSizeTablet.X.Scale
			useXOffset = ChatSettings.DefaultWindowSizeTablet.X.Offset

		else
			useXScale = ChatSettings.DefaultWindowSizeTablet.X.Scale
			useXOffset = ChatSettings.DefaultWindowSizeTablet.X.Offset

		end

		BaseFrame.Size = UDim2.new(useXScale, useXOffset, 0, chatBarYSize)
		BaseFrame.Position = ChatSettings.DefaultWindowPosition

	else

		local screenGuiParent = GetScreenGuiParent()

		if (deviceType == DEVICE_PHONE) then
			BaseFrame.Size = ChatSettings.DefaultWindowSizePhone

		elseif (deviceType == DEVICE_TABLET) then
			BaseFrame.Size = ChatSettings.DefaultWindowSizeTablet

		else
			BaseFrame.Size = ChatSettings.DefaultWindowSizeDesktop

		end

		BaseFrame.Position = ChatSettings.DefaultWindowPosition

	end

	local function CalculateChannelsBarPixelSize(size)
		if (deviceType == DEVICE_PHONE) then
			size = size or ChatSettings.ChatChannelsTabTextSizePhone
		else
			size = size or ChatSettings.ChatChannelsTabTextSize
		end

		local channelsBarTextYSize = string.match(size.Name, "%d+")
		local chatChannelYSize = math.max(32, channelsBarTextYSize + 8) + 2

		return chatChannelYSize
	end

	local function CalculateChatBarPixelSize(size)
		if (deviceType == DEVICE_PHONE) then
			size = size or ChatSettings.ChatBarTextSizePhone
		else
			size = size or ChatSettings.ChatBarTextSize
		end

		local chatBarTextSizeY = string.match(size.Name, "%d+")
		local chatBarYSize = chatBarTextSizeY + (7 * 2) + (5 * 2)

		return chatBarYSize
	end

	if (deviceType == DEVICE_PHONE) then
		ChatSettings.ChatWindowTextSize = ChatSettings.ChatWindowTextSizePhone
		ChatSettings.ChatChannelsTabTextSize = ChatSettings.ChatChannelsTabTextSizePhone
		ChatSettings.ChatBarTextSize = ChatSettings.ChatBarTextSizePhone
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

		if (ChatSettings.ShowChannelsBar) then
			ChatChannelParentFrame.Size = UDim2.new(1, 0, 1, -(channelsBarSize + chatBarSize + 2 + 2))
			ChatChannelParentFrame.Position = UDim2.new(0, 0, 0, channelsBarSize + 2)

		else
			ChatChannelParentFrame.Size = UDim2.new(1, 0, 1, -(chatBarSize + 2 + 2))
			ChatChannelParentFrame.Position = UDim2.new(0, 0, 0, 2)

		end
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

	local function UpdateShowChannelsBar(enabled)
		ChannelsBarParentFrame.Visible = ChatSettings.ShowChannelsBar
		UpdateChatChannelParentFrameSize()
	end

	UpdateChatChannelsTabTextSize(ChatSettings.ChatChannelsTabTextSize)
	UpdateChatBarTextSize(ChatSettings.ChatBarTextSize)
	UpdateDraggable(ChatSettings.WindowDraggable)
	UpdateResizable(ChatSettings.WindowResizable)
	UpdateShowChannelsBar(ChatSettings.ShowTopChannelsBar)

	ChatSettings.SettingsChanged:connect(function(setting, value)
		if (setting == "WindowDraggable") then
			UpdateDraggable(value)

		elseif (setting == "WindowResizable") then
			UpdateResizable(value)

		elseif (setting == "ChatChannelsTabTextSize") then
			UpdateChatChannelsTabTextSize(value)

		elseif (setting == "ChatBarTextSize") then
			UpdateChatBarTextSize(value)

		elseif (setting == "ShowChannelsBar") then
			UpdateShowChannelsBar(value)

		end
	end)

	rawset(self, "GuiObject", BaseFrame)

	self.GuiObjects.BaseFrame = BaseFrame
	self.GuiObjects.ChatBarParentFrame = ChatBarParentFrame
	self.GuiObjects.ChannelsBarParentFrame = ChannelsBarParentFrame
	self.GuiObjects.ChatChannelParentFrame = ChatChannelParentFrame
	self.GuiObjects.ChatResizerFrame = ChatResizerFrame
	self.GuiObjects.ResizeIcon = ResizeIcon
end

function methods:RegisterChatBar(ChatBar)
	rawset(self, "ChatBar", ChatBar)
	self.ChatBar:CreateGuiObjects(self.GuiObjects.ChatBarParentFrame)
end

function methods:RegisterChannelsBar(ChannelsBar)
	rawset(self, "ChannelsBar", ChannelsBar)
	self.ChannelsBar:CreateGuiObjects(self.GuiObjects.ChannelsBarParentFrame)
end

function methods:RegisterMessageLogDisplay(MessageLogDisplay)
	rawset(self, "MessageLogDisplay", MessageLogDisplay)
	self.MessageLogDisplay.GuiObject.Parent = self.GuiObjects.ChatChannelParentFrame
end

function methods:AddChannel(channelName)
	if (self:GetChannel(channelName))  then
		error("Channel '" .. channelName .. "' already exists!")
		return
	end

	local channel = moduleChatChannel.new(channelName, self.MessageLogDisplay)
	self.Channels[channelName:lower()] = channel

	channel:SetActive(false)

	local tab = self.ChannelsBar:AddChannelTab(channelName)
	tab.NameTag.MouseButton1Click:connect(function()
		self:SwitchCurrentChannel(channelName)
	end)

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

		local targetSwitchChannel = nil

		if (generalChannelExists and not removingGeneralChannel) then
			targetSwitchChannel = ChatSettings.GeneralChannelName
		else
			local firstChannel = self:GetFirstChannel()
			targetSwitchChannel = (firstChannel and firstChannel.Name or nil)
		end

		self:SwitchCurrentChannel(targetSwitchChannel)
	end

	if (not ChatSettings.ShowChannelsBar) then
		if (rawget(self.ChatBar, "TargetChannel") == channelName) then
			self.ChatBar:SetChannelTarget(ChatSettings.GeneralChannelName)
		end
	end
end

function methods:GetChannel(channelName)
	return channelName and self.Channels[channelName:lower()] or nil
end

function methods:GetTargetMessageChannel()
	if (not ChatSettings.ShowChannelsBar) then
		return rawget(self.ChatBar, "TargetChannel")
	else
		local curChannel = self:GetCurrentChannel()
		return curChannel and curChannel.Name
	end
end

function methods:GetCurrentChannel()
	return rawget(self, "CurrentChannel")
end

function methods:SwitchCurrentChannel(channelName)
	if (not ChatSettings.ShowChannelsBar) then
		local targ = self:GetChannel(channelName)
		if (targ) then
			self.ChatBar:SetChannelTarget(targ.Name)
		end

		channelName = ChatSettings.GeneralChannelName
	end

	local cur = self:GetCurrentChannel()
	local new = self:GetChannel(channelName)

	if (new ~= cur) then
		if (cur) then
			cur:SetActive(false)
			local tab = self.ChannelsBar:GetChannelTab(cur.Name)
			tab:SetActive(false)
		end

		if (new) then
			new:SetActive(true)
			local tab = self.ChannelsBar:GetChannelTab(new.Name)
			tab:SetActive(true)
		end

		rawset(self, "CurrentChannel", new)
	end

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

function methods:EnableResizable()
	self.GuiObjects.ChatResizerFrame.Active = true
end

function methods:DisableResizable()
	self.GuiObjects.ChatResizerFrame.Active = false
end

function methods:ResetResizerPosition()
	local ChatResizerFrame = self.GuiObjects.ChatResizerFrame
	ChatResizerFrame.Position = UDim2.new(1, -ChatResizerFrame.AbsoluteSize.X, 1, -ChatResizerFrame.AbsoluteSize.Y)
end

function methods:FadeOutBackground(duration)
	--self.ChannelsBar:FadeOutBackground(duration)
	--self.ChatBar:FadeOutBackground(duration)

	self.MessageLogDisplay:FadeOutBackground(duration)
	
	self.AnimParams.Frame_TargetAlpha = 1
	--self.BackgroundTweener:Tween(duration, 1)
end

function methods:FadeInBackground(duration)
	--self.ChannelsBar:FadeInBackground(duration)
	--self.ChatBar:FadeInBackground(duration)
	self.MessageLogDisplay:FadeInBackground(duration)
	
	self.AnimParams.Frame_TargetAlpha = 0.8
end

function methods:FadeOutText(duration)
	--self.ChannelsBar:FadeOutText(duration)
	--self.ChatBar:FadeOutText(duration)

	self.MessageLogDisplay:FadeOutText(duration)

	self.AnimParams.Text_TargetAlpha = 1
end

function methods:FadeInText(duration)
	--self.ChannelsBar:FadeInText(duration)
	--self.ChatBar:FadeInText(duration)

	self.MessageLogDisplay:FadeInText(duration)

	self.AnimParams.Text_TargetAlpha = 0
end

function methods:InitializeAnimParams()
	self.AnimParams.Frame_TargetAlpha = 0
	self.AnimParams.Frame_CurrentAlpha = 0
	
	self.AnimParams.Text_TargetAlpha = 0
	self.AnimParams.Text_CurrentAlpha = 0
end

function methods:Update(dtScale)
	
	self.AnimParams.Frame_CurrentAlpha = CurveUtil:Expt(self.AnimParams.Frame_CurrentAlpha , self.AnimParams.Frame_TargetAlpha, 0.1, dtScale)
	self.AnimParams.Text_CurrentAlpha = CurveUtil:Expt(self.AnimParams.Text_CurrentAlpha, self.AnimParams.Text_TargetAlpha, 0.1, dtScale)
	
	self.GuiObjects.ChatChannelParentFrame.BackgroundTransparency = self.AnimParams.Frame_CurrentAlpha
	self.GuiObjects.ChatResizerFrame.BackgroundTransparency = self.AnimParams.Frame_CurrentAlpha 
	self.GuiObjects.ResizeIcon.ImageTransparency = self.AnimParams.Frame_CurrentAlpha 
	
	--[[
		update self.ChatBar from self.AnimParams.Text_CurrentAlpha
		update self.ChannelsBar from self.AnimParams.Text_CurrentAlpha
		update self.MessageLogDisplay from self.AnimParams.Text_CurrentAlpha
	]]	
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("ChatWindow", methods)

function module.new()
	local obj = {}

	obj.GuiObject = nil
	obj.GuiObjects = {}

	obj.ChatBar = nil
	obj.ChannelsBar = nil
	obj.MessageLogDisplay = nil

	obj.Channels = {}
	obj.CurrentChannel = nil

	obj.Visible = true
	obj.CoreGuiEnabled = true
	
	obj.AnimParams = {}
	
	ClassMaker.MakeClass("ChatWindow", obj)
	
	obj:InitializeAnimParams()
	
	return obj
end

return module
