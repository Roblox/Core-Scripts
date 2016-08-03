local source = [[
local module = {}
--////////////////////////////// Include
--//////////////////////////////////////
local modulesFolder = script.Parent
local moduleChatChannel = require(modulesFolder:WaitForChild("ChatChannel"))
local moduleTransparencyTweener = require(modulesFolder:WaitForChild("TransparencyTweener"))

--////////////////////////////// Details
--//////////////////////////////////////
local metatable = {}
metatable.__ClassName = "ChatWindow"

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
local function CreateGuiObject()
	local BaseFrame = Instance.new("Frame")
	BaseFrame.BackgroundTransparency = 1
	BaseFrame.Size = UDim2.new(0.35, 0, 0.35, 0)

	--// This spawns a new thread that waits approximately long enough 
	--// until the BaseFrame has been parented to PlayerGui so it can 
	--// actually check the size of it.
	spawn(function()
		wait()
		if (BaseFrame.AbsoluteSize.X < 1600/3.75) then
			BaseFrame.Size = UDim2.new(0, 1600/3.75, 0, 900/3.75)
		end
	end)

	--// Chat Size18, 8 pixels on each end for white box in center, 
	--// 8 pixels on each end for actual chatbot object
	local chatBarYSize = 18 + 16 + 16

	--// 32 pixels of button height + offset pixels
	local chatChannelYSize = 32 + 2

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

	return BaseFrame, ChatBarParentFrame, ChannelsBarParentFrame, ChatChannelParentFrame
end

function metatable:Dump()
	return tostring(self)
end

function metatable:RegisterChatBar(ChatBar)
	rawset(self, "ChatBar", ChatBar)
	self.ChatBar.GuiObject.Parent = self.ChatBarParentFrame

	self.BackgroundTweener:RegisterTweenObjectProperty(ChatBar.BackgroundTweener, "Transparency")
	self.TextTweener:RegisterTweenObjectProperty(ChatBar.TextTweener, "Transparency")
end

function metatable:RegisterChannelsBar(ChannelsBar)
	rawset(self, "ChannelsBar", ChannelsBar)
	self.ChannelsBar.GuiObject.Parent = self.ChannelsBarParentFrame

	self.BackgroundTweener:RegisterTweenObjectProperty(ChannelsBar.BackgroundTweener, "Transparency")
	self.TextTweener:RegisterTweenObjectProperty(ChannelsBar.TextTweener, "Transparency")
end

function metatable:AddChannel(channelName)
	if (self:GetChannel(channelName))  then
		error("Channel '" .. channelName .. "' already exists!")
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

function metatable:RemoveChannel(channelName)
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

function metatable:GetChannel(channelName)
	return channelName and self.Channels[channelName:lower()] or nil
end

function metatable:GetCurrentChannel()
	return rawget(self, "CurrentChannel")
end

function metatable:SwitchCurrentChannel(channelName)
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

function metatable:UpdateFrameVisibility()
	self.GuiObject.Visible = (self.Visible and self.CoreGuiEnabled)
end

function metatable:GetVisible()
	return self.Visible
end

function metatable:SetVisible(visible)
	self.Visible = visible
	self:UpdateFrameVisibility()
end

function metatable:GetCoreGuiEnabled()
	return self.CoreGuiEnabled
end

function metatable:SetCoreGuiEnabled(enabled)
	self.CoreGuiEnabled = enabled
	self:UpdateFrameVisibility()
end

function metatable:FadeOutBackground(duration)
	--self.ChannelsBar:FadeOutBackground(duration)
	--self.ChatBar:FadeOutBackground(duration)

	if (self:GetCurrentChannel()) then
		self:GetCurrentChannel():FadeOutBackground(duration)
	end

	self.BackgroundTweener:Tween(duration, 1)
end

function metatable:FadeInBackground(duration)
	--self.ChannelsBar:FadeInBackground(duration)
	--self.ChatBar:FadeInBackground(duration)

	if (self:GetCurrentChannel()) then
		self:GetCurrentChannel():FadeInBackground(duration)
	end

	self.BackgroundTweener:Tween(duration, 0)
end

function metatable:FadeOutText(duration)
	--self.ChannelsBar:FadeOutText(duration)
	--self.ChatBar:FadeOutText(duration)

	if (self:GetCurrentChannel()) then
		self:GetCurrentChannel():FadeOutText(duration)
	end

	self.TextTweener:Tween(duration, 1)
end

function metatable:FadeInText(duration)
	--self.ChannelsBar:FadeInText(duration)
	--self.ChatBar:FadeInText(duration)

	if (self:GetCurrentChannel()) then
		self:GetCurrentChannel():FadeInText(duration)
	end

	self.TextTweener:Tween(duration, 0)
end

function metatable:CreateTweeners()
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
function module.new()
	local obj = {}
	obj.MemoryLocation = tostring(obj):match("[0123456789ABCDEF]+")

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

	obj = setmetatable(obj, metatable)

	obj:CreateTweeners()

	return obj
end

return module
]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script