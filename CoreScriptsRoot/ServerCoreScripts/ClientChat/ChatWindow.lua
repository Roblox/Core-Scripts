local source = [[
local module = {}

local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

--////////////////////////////// Include
--//////////////////////////////////////
local modulesFolder = script.Parent
local moduleChatChannel = require(modulesFolder:WaitForChild("ChatChannel"))
local moduleTransparencyTweener = require(modulesFolder:WaitForChild("TransparencyTweener"))
local moduleChatSettings = require(modulesFolder:WaitForChild("ChatSettings"))
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

local function CreateGuiObject()
	local BaseFrame = Instance.new("Frame")
	BaseFrame.BackgroundTransparency = 1
	
	local FirstParentedEvent = Instance.new("BindableEvent", BaseFrame)
	FirstParentedEvent.Name = "FirstParented"

	if (moduleChatSettings.WindowDraggable) then
		BaseFrame.Active = true
		BaseFrame.Draggable = true
	end

	local function doCheckMinimumResize()
		if (not BaseFrame:IsDescendantOf(PlayerGui)) then return end

		if (BaseFrame.AbsoluteSize.X < moduleChatSettings.MinimumWindowSizeX) then
			BaseFrame.Size = UDim2.new(0, moduleChatSettings.MinimumWindowSizeX, 0, moduleChatSettings.MinimumWindowSizeY)
		end
	end

	BaseFrame.Changed:connect(function(prop)
		if (prop == "AbsoluteSize") then
			doCheckMinimumResize()
		end
	end)

	local chatBarTextSizeY = string.match(moduleChatSettings.ChatBarTextSize.Name, "%d+")
	local channelsBarTextYSize = string.match(moduleChatSettings.ChatChannelsTabTextSize.Name, "%d+")

	--// Chat font size pixel height, 8 pixels on each end for white box in center, 
	--// 8 pixels on each end for actual chatbot object
	local chatBarYSize = chatBarTextSizeY + 16 + 16

	--// 32 pixels of button height + offset pixels
	local chatChannelYSize = math.max(32, channelsBarTextYSize + 8) + 2

	local ChatBarParentFrame = Instance.new("Frame", BaseFrame)
	ChatBarParentFrame.Name = "ChatBarParentFrame"
	ChatBarParentFrame.BackgroundTransparency = 1
	ChatBarParentFrame.Size = UDim2.new(1, 0, 0, chatBarYSize)
	ChatBarParentFrame.Position = UDim2.new(0, 0, 1, -chatBarYSize)

	local ChannelsBarParentFrame = Instance.new("Frame", BaseFrame)
	ChannelsBarParentFrame.Name = "ChannelsBarParentFrame"
	ChannelsBarParentFrame.BackgroundTransparency = 1
	ChannelsBarParentFrame.Size = UDim2.new(1, 0, 0, chatChannelYSize)
	ChannelsBarParentFrame.Position = UDim2.new(0, 0, 0, 0)

	local ChatChannelParentFrame = Instance.new("Frame", BaseFrame)
	ChatChannelParentFrame.Name = "ChatChannelParentFrame"
	ChatChannelParentFrame.BackgroundTransparency = 1
	ChatChannelParentFrame.Position = UDim2.new(0, 0, 0, chatChannelYSize)
	ChatChannelParentFrame.Size = UDim2.new(1, 0, 1, -(chatChannelYSize + 2 + chatBarYSize))

	ChatChannelParentFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	ChatChannelParentFrame.BackgroundTransparency = 0.6
	ChatChannelParentFrame.BorderSizePixel = 0

	local Players = game:GetService("Players")
	if (not Players.ClassicChat and Players.BubbleChat) then
		ChatBarParentFrame.Position = UDim2.new(0, 0, 0, 0)
		ChannelsBarParentFrame.Visible = false
		ChatChannelParentFrame.Visible = false

		FirstParentedEvent.Event:connect(function()
			BaseFrame.Size = UDim2.new(moduleChatSettings.DefaultWindowSize.X.Scale, moduleChatSettings.DefaultWindowSize.X.Offset, 0, chatBarYSize)    
			BaseFrame.Position = moduleChatSettings.DefaultWindowPosition
			FirstParentedEvent:Destroy()
		end)
	else
		FirstParentedEvent.Event:connect(function()
			BaseFrame.Size = moduleChatSettings.DefaultWindowSize
			BaseFrame.Position = moduleChatSettings.DefaultWindowPosition
			FirstParentedEvent:Destroy()
		end)

	end



	return BaseFrame, ChatBarParentFrame, ChannelsBarParentFrame, ChatChannelParentFrame
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

function methods:RemoveChannel(channelName)
	if (not self:GetChannel(channelName))  then
		error("Channel '" .. channelName .. "' does not exist!")
	end
	
	local indexName = channelName:lower()
	
	if (self.Channels[indexName] == self:GetCurrentChannel()) then
		if (indexName == "all") then
			self:SwitchCurrentChannel(nil)
		else
			self:SwitchCurrentChannel("All")
		end
	end
	
	self.Channels[indexName]:Destroy()
	self.Channels[indexName] = nil

	self.ChannelsBar:RemoveChannelTab(channelName)
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

	--// Register TextTweener objects and properties
		-- there are none...
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("ChatWindow", methods)

function module.new()
	local obj = {}

	local BaseFrame, ChatBarParentFrame, ChannelsBarParentFrame, ChatChannelParentFrame= CreateGuiObject()
	obj.GuiObject = BaseFrame
	obj.ChatBarParentFrame = ChatBarParentFrame
	obj.ChannelsBarParentFrame = ChannelsBarParentFrame
	obj.ChatChannelParentFrame = ChatChannelParentFrame

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