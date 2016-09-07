local source = [[
--	// FileName: Speaker.lua
--	// Written by: Xsitsu
--	// Description: A representation of one entity that can chat in different ChatChannels.

local module = {}

local modulesFolder = script.Parent

--////////////////////////////// Include
--//////////////////////////////////////
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

function methods:SayMessage(message, channelName)
	if (self.ChatService:InternalDoProcessCommands(self.Name, message, channelName)) then return end
	if (not channelName) then return end

	local channel = self.Channels[channelName:lower()]
	if (not channel) then
		error("Speaker is not in channel \"" .. channelName .. "\"")
	end

	local messageObj = channel:InternalPostMessage(self, message)
	if (messageObj) then
		spawn(function() self.eSaidMessage:Fire(messageObj) end)
	end
	
	return messageObj
end

function methods:JoinChannel(channelName)
	if (self.Channels[channelName:lower()]) then
		warn("Speaker is already in channel \"" .. channelName .. "\"")
		return
	end
	
	local channel = self.ChatService:GetChannel(channelName)
	if (not channel) then
		error("Channel \"" .. channelName .. "\" does not exist!")
	end

	self.Channels[channelName:lower()] = channel
	channel:InternalAddSpeaker(self)
	spawn(function()
		self.eChannelJoined:Fire(channel.Name, channel.WelcomeMessage)
	end)
end

function methods:LeaveChannel(channelName)
	if (not self.Channels[channelName:lower()]) then
		warn("Speaker is not in channel \"" .. channelName .. "\"")
		return
	end
	
	local channel = self.Channels[channelName:lower()]
	
	self.Channels[channelName:lower()] = nil
	channel:InternalRemoveSpeaker(self)
	spawn(function()
		self.eChannelLeft:Fire(channel.Name)
	end)
end

function methods:IsInChannel(channelName)
	return (self.Channels[channelName:lower()] ~= nil)
end

function methods:GetChannelList()
	local list = {}
	for i, channel in pairs(self.Channels) do
		table.insert(list, channel.Name)
	end
	return list
end

function methods:SendMessage(message, channelName, fromSpeaker)
	local channel = self.Channels[channelName:lower()]
	if (channel) then
		channel:SendMessageToSpeaker(message, self.Name, fromSpeaker)

	else
		warn(string.format("Speaker '%s' is not in channel '%s' and cannot receive a message in it.", self.Name, channelName))

	end
end

function methods:SendSystemMessage(message, channelName)
	local channel = self.Channels[channelName:lower()]
	if (channel) then
		channel:SendSystemMessageToSpeaker(message, self.Name)

	else
		warn(string.format("Speaker '%s' is not in channel '%s' and cannot receive a system message in it.", self.Name, channelName))

	end
end

function methods:GetPlayer()
	return rawget(self, "PlayerObj")
end

function methods:SetExtraData(key, value)
	self.ExtraData[key] = value
	spawn(function() self.eExtraDataUpdated:Fire(key, value) end) 
end

function methods:GetExtraData(key)
	return self.ExtraData[key]
end

function methods:SetMainChannel(channel)
	spawn(function() self.eMainChannelSet:Fire(channel) end)
end

--///////////////// Internal-Use Methods
--//////////////////////////////////////
function methods:InternalDestroy()
	for i, channel in pairs(self.Channels) do
		channel:InternalRemoveSpeaker(self)
	end
	
	self.eDestroyed:Fire()
end

function methods:InternalAssignPlayerObject(playerObj)
	rawset(self, "PlayerObj", playerObj)
end

function methods:InternalSendMessage(messageObj, channel)
	spawn(function()
		self.eReceivedMessage:Fire(messageObj, channel)
	end)

	spawn(function()
		messageObj.Message = self.ChatService:InternalApplyRobloxFilter(messageObj.FromSpeaker, messageObj.Message)
		self.eMessageDoneFiltering:Fire(messageObj, channel)
	end)
end

function methods:InternalSendSystemMessage(messageObj, channel)
	spawn(function()
		self.eReceivedSystemMessage:Fire(messageObj, channel)
	end)
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("Speaker", methods)

function module.new(vChatService, name)
	local obj = {}

	obj.ChatService = vChatService

	obj.PlayerObj = nil
	
	obj.Name = name
	obj.ExtraData = {}
	
	obj.Channels = {}
	
	obj.eDestroyed = Instance.new("BindableEvent")
	obj.Destroyed = obj.eDestroyed.Event
	
	obj.eSaidMessage = Instance.new("BindableEvent")
	obj.eReceivedMessage = Instance.new("BindableEvent")
	obj.eMessageDoneFiltering = Instance.new("BindableEvent")
	obj.eReceivedSystemMessage = Instance.new("BindableEvent")
	obj.eChannelJoined = Instance.new("BindableEvent")
	obj.eChannelLeft = Instance.new("BindableEvent")
	obj.eMuted = Instance.new("BindableEvent")
	obj.eUnmuted = Instance.new("BindableEvent")
	obj.eExtraDataUpdated = Instance.new("BindableEvent")
	obj.eMainChannelSet = Instance.new("BindableEvent")
	
	obj.SaidMessage = obj.eSaidMessage.Event
	obj.ReceivedMessage = obj.eReceivedMessage.Event
	obj.MessageDoneFiltering = obj.eMessageDoneFiltering.Event
	obj.ReceivedSystemMessage = obj.eReceivedSystemMessage.Event
	obj.ChannelJoined = obj.eChannelJoined.Event
	obj.ChannelLeft = obj.eChannelLeft.Event
	obj.Muted = obj.eMuted.Event
	obj.Unmuted = obj.eUnmuted.Event
	obj.ExtraDataUpdated = obj.eExtraDataUpdated.Event
	obj.MainChannelSet = obj.eMainChannelSet.Event

	ClassMaker.MakeClass("Speaker", obj)
	
	return obj
end

return module

]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script