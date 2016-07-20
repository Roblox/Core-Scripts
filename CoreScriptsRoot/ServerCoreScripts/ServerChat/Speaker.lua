local source = [[
local module = {}

--////////////////////////////// Details
--//////////////////////////////////////
local metatable = {}
metatable.__ClassName = "Speaker"

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
function metatable:Dump()
	return tostring(self)
end

function metatable:Destroy()
	for i, channel in pairs(self.Channels) do
		channel:InternalRemoveSpeaker(self)
	end
	
	self.eOnDestroyed:Fire()
end

function metatable:AssignPlayerObject(playerObj)
	rawset(self, "PlayerObj", playerObj)
end

function metatable:SayMessage(message, channelName)
	if (self.ChatService:DoProcessCommands(self.Name, message, channelName)) then return end
	if (not channelName) then return end

	local channel = self.Channels[channelName:lower()]
	if (not channel) then
		error("Speaker is not in channel \"" .. channelName .. "\"")
	end

	local msg = channel:PostMessage(self, message)
	if (msg) then
		self.eOnSaidMessage:Fire(msg, channelName)
	end
	
end

function metatable:JoinChannel(channelName)
	if (self.Channels[channelName:lower()]) then
		warn("Speaker is already in channel \"" .. channelName .. "\"")
		return
	end
	
	local channel = self.ChatService:GetChannel(channelName)
	if (not channel) then
		error("Channel \"" .. channelName .. "\" does not exist!")
	end

	-- this solves the "tables cannot be cyclic" problem 
	local proxy = newproxy(true)
	getmetatable(proxy).__index = channel
	
	self.Channels[channelName:lower()] = proxy
	channel:InternalAddSpeaker(self)
	spawn(function()
		self.eOnChannelJoined:Fire(channel.Name, channel.WelcomeMessage)
	end)
end

function metatable:LeaveChannel(channelName)
	if (not self.Channels[channelName:lower()]) then
		warn("Speaker is not in channel \"" .. channelName .. "\"")
		return
	end
	
	local channel = self.Channels[channelName:lower()]
	
	self.Channels[channelName:lower()] = nil
	channel:InternalRemoveSpeaker(self)
	spawn(function()
		self.eOnChannelLeft:Fire(channel.Name)
	end)
end

function metatable:GetChannelList()
	local list = {}
	for i, channel in pairs(self.Channels) do
		table.insert(list, channel.Name)
	end
	return list
end

function metatable:SendMessage(fromSpeaker, channel, message)
	spawn(function()
		self.eOnReceivedMessage:Fire(fromSpeaker, channel, message)
	end)
end

function metatable:SendSystemMessage(message, channel)
	spawn(function()
		self.eOnReceivedSystemMessage:Fire(message, channel)
	end)
end

function metatable:IsInChannel(channelName)
	return (self.Channels[channelName:lower()] ~= nil)
end

function metatable:GetPlayerObject()
	return rawget(self, "PlayerObj")
end

function metatable:SetExtraData(key, value)
	self.ExtraData[key] = value
	spawn(function() self.eOnExtraDataUpdated:Fire(key, value) end) 
end

function metatable:GetExtraData(key)
	return self.ExtraData[key]
end

--///////////////////////// Constructors
--//////////////////////////////////////
function module.new(vChatService, name)
	local obj = {}
	obj.MemoryLocation = tostring(obj):match("[0123456789ABCDEF]+")
	
	obj.ChatService = newproxy(true)
	getmetatable(obj.ChatService).__index = vChatService
	
	obj.PlayerObj = nil
	
	obj.Name = name
	obj.ExtraData = {}
	
	obj.Channels = {}
	
	obj.eOnDestroyed = Instance.new("BindableEvent")
	obj.OnDestroyed = obj.eOnDestroyed.Event
	
	obj.eOnSaidMessage = Instance.new("BindableEvent")
	obj.eOnReceivedMessage = Instance.new("BindableEvent")
	obj.eOnReceivedSystemMessage = Instance.new("BindableEvent")
	obj.eOnChannelJoined = Instance.new("BindableEvent")
	obj.eOnChannelLeft = Instance.new("BindableEvent")
	obj.eOnMuted = Instance.new("BindableEvent")
	obj.eOnUnmuted = Instance.new("BindableEvent")
	
	obj.eOnExtraDataUpdated = Instance.new("BindableEvent")
	
	obj.OnSaidMessage = obj.eOnSaidMessage.Event
	obj.OnReceivedMessage = obj.eOnReceivedMessage.Event
	obj.OnReceivedSystemMessage = obj.eOnReceivedSystemMessage.Event
	obj.OnChannelJoined = obj.eOnChannelJoined.Event
	obj.OnChannelLeft = obj.eOnChannelLeft.Event
	obj.OnMuted = obj.eOnMuted.Event
	obj.OnUnmuted = obj.eOnUnmuted.Event
	
	obj.OnExtraDataUpdated = obj.eOnExtraDataUpdated.Event

	obj = setmetatable(obj, metatable)
	
	return obj
end

return module

]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script