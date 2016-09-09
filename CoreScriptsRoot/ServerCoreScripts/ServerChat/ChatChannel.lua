local source = [[
--	// FileName: ChatChannel.lua
--	// Written by: Xsitsu
--	// Description: A representation of one channel that speakers can chat in.

local module = {}

local modulesFolder = script.Parent
local HttpService = game:GetService("HttpService")

--////////////////////////////// Include
--//////////////////////////////////////
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

function methods:SendSystemMessage(message, extraData)
	local messageObj = self:InternalCreateMessageObject(message, nil, extraData)

	self:InternalAddMessageToHistoryLog(messageObj)

	for i, speaker in pairs(self.Speakers) do
		speaker:InternalSendSystemMessage(messageObj, self.Name)
	end
	
	return messageObj
end

function methods:SendSystemMessageToSpeaker(message, speakerName, extraData)
	local speaker = self.Speakers[speakerName]
	if (speaker) then
		local messageObj = self:InternalCreateMessageObject(message, nil, extraData)
		speaker:InternalSendSystemMessage(messageObj, self.Name)
	else
		warn(string.format("Speaker '%s' is not in channel '%s' and cannot be sent a system message", speakerName, self.Name))
	end
end

function methods:SendMessageToSpeaker(message, speakerName, fromSpeaker, extraData)
	local speaker = self.Speakers[speakerName]
	if (speaker) then
		local messageObj = self:InternalCreateMessageObject(message, fromSpeaker, extraData)
		speaker:InternalSendMessage(messageObj, self.Name)
	else
		warn(string.format("Speaker '%s' is not in channel '%s' and cannot be sent a message", speakerName, self.Name))
	end
end

function methods:KickSpeaker(speakerName, reason)
	local speaker = self.ChatService:GetSpeaker(speakerName)
	if (not speaker) then
		error("Speaker \"" .. speakerName .. "\" does not exist!")
	end

	local messageToSpeaker = ""
	local messageToChannel = ""

	if (reason) then
		messageToSpeaker = string.format("You were kicked from '%s' for the following reason(s): %s", self.Name, reason)
		messageToChannel = string.format("%s was kicked for the following reason(s): %s", speakerName, reason)
	else
		messageToSpeaker = string.format("You were kicked from '%s'", self.Name)
		messageToChannel = string.format("%s was kicked", speakerName)
	end

	self:SendSystemMessageToSpeaker(messageToSpeaker, speakerName)
	speaker:LeaveChannel(self.Name)
	self:SendSystemMessage(messageToChannel)
end

function methods:MuteSpeaker(speakerName, reason, length)
	local speaker = self.ChatService:GetSpeaker(speakerName)
	if (not speaker) then
		error("Speaker \"" .. speakerName .. "\" does not exist!")
	end
	
	self.Mutes[speakerName:lower()] = (length == 0 or length == nil) and 0 or (os.time() + length)

	if (reason) then
		self:SendSystemMessage(string.format("%s was muted for the following reason(s): %s", speakerName, self))
	end

	spawn(function() self.eSpeakerMuted:Fire(speakerName, reason, length) end)
	local spkr = self.ChatService:GetSpeaker(speakerName)
	if (spkr) then
		spawn(function() spkr.eMuted:Fire(self.Name, reason, length) end)
	end

end

function methods:UnmuteSpeaker(speakerName)
	local speaker = self.ChatService:GetSpeaker(speakerName)
	if (not speaker) then
		error("Speaker \"" .. speakerName .. "\" does not exist!")
	end
	
	self.Mutes[speakerName:lower()] = nil

	spawn(function() self.eSpeakerUnmuted:Fire(speakerName) end)
	local spkr = self.ChatService:GetSpeaker(speakerName)
	if (spkr) then
		spawn(function() spkr.eUnmuted:Fire(self.Name) end)
	end
end

function methods:IsSpeakerMuted(speakerName)
	return (self.Mutes[speakerName:lower()] ~= nil)
end

function methods:GetSpeakerList()
	local list = {}
	for i, speaker in pairs(self.Speakers) do
		table.insert(list, speaker.Name)
	end
	return list
end

function methods:RegisterFilterMessageFunction(funcId, func)
	if self.FilterMessageFunctions[funcId] then
		error(funcId .. " is already in use!")
	end
	
	self.FilterMessageFunctions[funcId] = func
end

function methods:UnregisterFilterMessageFunction(funcId)
	self.FilterMessageFunctions[funcId] = nil
end

function methods:RegisterProcessCommandsFunction(funcId, func)
	if (self.ProcessCommandsFunctions[funcId]) then
		error(funcId .. " is already in use!")
	end
	
	self.ProcessCommandsFunctions[funcId] = func
end

function methods:UnregisterProcessCommandsFunction(funcId)
	self.ProcessCommandsFunctions[funcId] = nil
end

local function DeepCopy(table)
	local copy =  {}
	for i, v in pairs(table) do
		if (type(v) == table) then
			copy[i] = DeepCopy(v)
		else
			copy[i] = v
		end
	end
	return copy
end

function methods:GetHistoryLog()
	return DeepCopy(self.ChatHistory)
end

--///////////////// Internal-Use Methods
--//////////////////////////////////////
function methods:InternalDestroy()
	for i, speaker in pairs(self.Speakers) do
		speaker:LeaveChannel(self.Name)
	end
	
	self.eDestroyed:Fire()
end

function methods:InternalDoMessageFilter(speakerName, message, channel)
	for funcId, func in pairs(self.FilterMessageFunctions) do
		local s, m = pcall(function()
			local ret = func(speakerName, message, channel)
			assert(type(ret) == "string")
			message = ret
		end)

		if (not s) then
			warn(string.format("DoMessageFilter Function '%s' failed for reason: %s", funcId, m))
		end
	end
	
	return message
end

function methods:InternalDoProcessCommands(speakerName, message, channel)
	local processed = false
	
	processed = self.ProcessCommandsFunctions["default_commands"](speakerName, message, channel)
	if (processed) then return processed end
	
	for funcId, func in pairs(self.ProcessCommandsFunctions) do
		local s, m = pcall(function()
			local ret = func(speakerName, message, channel)
			assert(type(ret) == "boolean")
			processed = ret
		end)
		
		if (not s) then
			warn(string.format("DoProcessCommands Function '%s' failed for reason: %s", funcId, m))
		end
		
		if (processed) then break end
	end
	
	return processed
end

function methods:InternalPostMessage(fromSpeaker, message, extraData)
	message = self:InternalDoMessageFilter(fromSpeaker.Name, message, self.Name)
	message = self.ChatService:InternalDoMessageFilter(fromSpeaker.Name, message, self.Name)

	if (self:InternalDoProcessCommands(fromSpeaker.Name, message, self.Name)) then return false end

	if (self.Mutes[fromSpeaker.Name:lower()] ~= nil) then
		local t = self.Mutes[fromSpeaker.Name:lower()]
		if (t > 0 and os.time() > t) then
			self:UnmuteSpeaker(fromSpeaker.Name)
		else
			self:SendSystemMessageToSpeaker("You are muted and cannot talk in this channel", fromSpeaker.Name)
			return false
		end
	end

	local messageObj = self:InternalCreateMessageObject(message, fromSpeaker.Name, extraData)

	self:InternalAddMessageToHistoryLog(messageObj)

	spawn(function() self.eMessagePosted:Fire(messageObj) end)
	
	for i, speaker in pairs(self.Speakers) do
		speaker:InternalSendMessage(messageObj, self.Name)
	end
	
	return messageObj
end

function methods:InternalAddSpeaker(speaker)
	if (self.Speakers[speaker.Name]) then
		warn("Speaker \"" .. speaker.name .. "\" is already in the channel!")
		return
	end
	
	self.Speakers[speaker.Name] = speaker
	spawn(function() self.eSpeakerJoined:Fire(speaker.Name) end)
end

function methods:InternalRemoveSpeaker(speaker)
	if (not self.Speakers[speaker.Name]) then
		warn("Speaker \"" .. speaker.name .. "\" is not in the channel!")
		return
	end
	
	self.Speakers[speaker.Name] = nil
	spawn(function() self.eSpeakerLeft:Fire(speaker.Name) end)
end

function methods:InternalRemoveExcessMessagesFromLog()
	local remove = table.remove
	while (#self.ChatHistory > self.MaxHistory) do
		remove(self.ChatHistory, 1)
	end
end

local function ChatHistorySortFunction(message1, message2)
	return (message1.Time < message2.Time)
end

function methods:InternalAddMessageToHistoryLog(messageObj)
	table.insert(self.ChatHistory, logObject)
	table.sort(self.ChatHistory, ChatHistorySortFunction)

	self:InternalRemoveExcessMessagesFromLog()
end

function methods:InternalCreateMessageObject(message, fromSpeaker, extraData)
	local messageObj =
	{
		ID = self.ChatService:InternalGetUniqueMessageId(),
		FromSpeaker = fromSpeaker,
		Message = message,
		Time = os.time(),
		ExtraData = {},
	}

	if (fromSpeaker) then
		local speaker = self.Speakers[fromSpeaker]
		if (speaker) then
			for k, v in pairs(speaker.ExtraData) do
				messageObj.ExtraData[k] = v
			end
		end
	end

	if (extraData) then
		for k, v in pairs(extraData) do
			messageObj.ExtraData[k] = v
		end
	end

	return messageObj
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("ChatChannel", methods)

function module.new(vChatService, name, welcomeMessage)
	local obj = {}

	obj.ChatService = vChatService
	
	obj.Name = name
	obj.WelcomeMessage = welcomeMessage or ""
	
	obj.Joinable = true
	obj.Leavable = true
	obj.AutoJoin = false
	obj.Private = false
	
	obj.Speakers = {}
	obj.Mutes = {}

	obj.MaxHistory = 200
	obj.HistoryIndex = 0
	obj.ChatHistory = {}
	obj.MessageQueue = {}
	obj.InternalMessageQueueChanged = Instance.new("BindableEvent")

	obj.FilterMessageFunctions = {}
	obj.ProcessCommandsFunctions = {}
	
	obj.eDestroyed = Instance.new("BindableEvent")
	obj.Destroyed = obj.eDestroyed.Event
	
	obj.eMessagePosted = Instance.new("BindableEvent")
	obj.eSpeakerJoined = Instance.new("BindableEvent")
	obj.eSpeakerLeft = Instance.new("BindableEvent")
	obj.eSpeakerMuted = Instance.new("BindableEvent")
	obj.eSpeakerUnmuted = Instance.new("BindableEvent")

	obj.MessagePosted = obj.eMessagePosted.Event
	obj.SpeakerJoined = obj.eSpeakerJoined.Event
	obj.SpeakerLeft = obj.eSpeakerLeft.Event
	obj.SpeakerMuted = obj.eSpeakerMuted.Event
	obj.SpeakerUnmuted = obj.eSpeakerUnmuted.Event
	
	ClassMaker.MakeClass("ChatChannel", obj)
	
	return obj
end

return module

]]


local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script