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

function methods:Destroy()
	for i, speaker in pairs(self.Speakers) do
		speaker:LeaveChannel(self.Name)
	end
	
	self.eDestroyed:Fire()
end

function methods:DoMessageFilter(speakerName, message, channel)
	for funcId, func in pairs(self.FilterMessageFunctions) do
		local s, m = pcall(function()
			local ret = func(speakerName, message, channel)
			assert(type(ret) == "string")
			message = ret
		end)

		if (not s) then
			warn("DoMessageFilter Function '" .. funcId .. "'' failed for reason: " .. m)
		end
	end
	
	return message
end

function methods:DoProcessCommands(speakerName, message, channel)
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
			warn("DoProcessCommands Function '" .. funcId .. "'' failed for reason: " .. m)
		end
		
		if (processed) then break end
	end
	
	return processed
end

function methods:PostMessage(fromSpeaker, message)
	message = self:DoMessageFilter(fromSpeaker.Name, message, self.Name)
	message = self.ChatService:DoMessageFilter(fromSpeaker.Name, message, self.Name)

	if (self:DoProcessCommands(fromSpeaker.Name, message, self.Name)) then return false end

	if (self.Mutes[fromSpeaker.Name:lower()] ~= nil) then
		local t = self.Mutes[fromSpeaker.Name:lower()]
		if (t > 0 and os.time() > t) then
			self:UnmuteSpeaker(fromSpeaker.Name)
		else
			fromSpeaker:SendSystemMessage("You are muted and cannot talk in this channel", self.Name)
			return false
		end
		
	end
	
	--message = self:DoMessageFilter(fromSpeaker.Name, message, self.Name)
	--message = self.ChatService:DoMessageFilter(fromSpeaker.Name, message, self.Name)

	self:AddMessageToHistoryLog(message, fromSpeaker)


	spawn(function() self.eMessagePosted:Fire(fromSpeaker.Name, message) end)
	
	for i, speaker in pairs(self.Speakers) do
		if (true or speaker ~= fromSpeaker) then
			speaker:SendMessage(fromSpeaker.Name, self.Name, message)
		end
	end
	
	return message
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
		warn("Speaker \"" .. speaker.name .. "\" is already in the channel!")
		return
	end
	
	self.Speakers[speaker.Name] = nil
	spawn(function() self.eSpeakerLeft:Fire(speaker.Name) end)
end

function methods:KickSpeaker(speakerName, reason)
	local speaker = self.ChatService:GetSpeaker(speakerName)
	if (not speaker) then
		error("Speaker \"" .. speakerName .. "\" does not exist!")
	end
	
	speaker:LeaveChannel(self.Name)

	if (reason) then
		speaker:SendSystemMessage("You were kicked from '" .. self.Name .. "' for the following reason(s): " .. reason, nil)
		self:SendSystemMessage(speakerName .. " was kicked for the following reason(s): " .. reason)
	else
		speaker:SendSystemMessage("You were kicked from '" .. self.Name .. "'", nil)
		self:SendSystemMessage(speakerName .. " was kicked")
	end
	
end

function methods:MuteSpeaker(speakerName, reason, length)
	local speaker = self.ChatService:GetSpeaker(speakerName)
	if (not speaker) then
		error("Speaker \"" .. speakerName .. "\" does not exist!")
	end
	
	self.Mutes[speakerName:lower()] = (length == 0 or length == nil) and 0 or (os.time() + length)

	if (reason) then
		self:SendSystemMessage(speakerName .. " was muted for the following reason(s): " .. reason)
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

function methods:SendSystemMessage(message)
	self:AddMessageToHistoryLog(message, nil)

	for i , speaker in pairs(self.Speakers) do
		speaker:SendSystemMessage(message, self.Name)
	end
end

function methods:RemoveExcessMessagesFromLog()
	while (#self.ChatHistory > self.MaxHistory) do
		table.remove(self.ChatHistory, 1)
	end
end

function methods:AddMessageToHistoryLog(message, fromSpeaker)
	local logObject = {}
	logObject.Message = message
	logObject.Speaker = fromSpeaker and fromSpeaker.Name
	table.insert(self.ChatHistory, logObject)

	self:RemoveExcessMessagesFromLog()
end

function methods:GetHistoryLog()
	--// Really easy way to write a deep copy
	return HttpService:JSONDecode(HttpService:JSONEncode(self.ChatHistory))
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("ChatChannel", methods)

function module.new(vChatService, name, welcomeMessage)
	local obj = {}

	obj.ChatService = newproxy(true)
	getmetatable(obj.ChatService).__index = vChatService
	
	obj.Name = name
	obj.WelcomeMessage = welcomeMessage or ""
	
	obj.Joinable = true
	obj.Leavable = true
	obj.AutoJoin = false
	obj.Private = false
	
	obj.Speakers = {}
	obj.Mutes = {}

	obj.MaxHistory = 50
	obj.ChatHistory = {}

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