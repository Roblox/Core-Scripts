--	// FileName: ChatService.lua
--	// Written by: Xsitsu
--	// Description: Manages creating and destroying ChatChannels and Speakers.

local module = {}

local modulesFolder = script.Parent
local RunService = game:GetService("RunService")
local Chat = game:GetService("Chat")

--////////////////////////////// Include
--//////////////////////////////////////
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))
local ChatChannel = require(modulesFolder:WaitForChild("ChatChannel"))
local Speaker = require(modulesFolder:WaitForChild("Speaker"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

function methods:AddChannel(channelName)
	if (self.ChatChannels[channelName:lower()]) then
		error(string.format("Channel %q alrady exists.", channelName))
	end

	local channel = ChatChannel.new(self, channelName)
	self.ChatChannels[channelName:lower()] = channel

	channel:RegisterProcessCommandsFunction("default_commands", function(fromSpeaker, message)
		if (message:lower() == "/leave") then
			local channel = self:GetChannel(channelName)
			local speaker = self:GetSpeaker(fromSpeaker)
			if (channel and speaker) then
				if (channel.Leavable) then
					speaker:LeaveChannel(channelName)
				else
					speaker:SendSystemMessage("You cannot leave this channel.", channelName)
				end
			end

			return true
		end

		return false
	end)

	local success, err = pcall(function() self.eChannelAdded:Fire(channelName) end)
	if not success and err then
		print("Error addding channel: " ..err)
	end

	return channel
end

function methods:RemoveChannel(channelName)
	if (self.ChatChannels[channelName:lower()]) then
		local n = self.ChatChannels[channelName:lower()].Name

		self.ChatChannels[channelName:lower()]:InternalDestroy()
		self.ChatChannels[channelName:lower()] = nil

		local success, err = pcall(function() self.eChannelRemoved:Fire(n) end)
		if not success and err then
			print("Error removing channel: " ..err)
		end
	else
		warn(string.format("Channel %q does not exist.", channelName))
	end
end

function methods:GetChannel(channelName)
	return self.ChatChannels[channelName:lower()]
end


function methods:AddSpeaker(speakerName)
	if (self.Speakers[speakerName:lower()]) then
		error("Speaker \"" .. speakerName .. "\" already exists!")
	end

	local speaker = Speaker.new(self, speakerName)
	self.Speakers[speakerName:lower()] = speaker

	local success, err = pcall(function() self.eSpeakerAdded:Fire(speakerName) end)
	if not success and err then
		print("Error adding speaker: " ..err)
	end

	return speaker
end

function methods:RemoveSpeaker(speakerName)
	if (self.Speakers[speakerName:lower()]) then
		local n = self.Speakers[speakerName:lower()].Name

		self.Speakers[speakerName:lower()]:InternalDestroy()
		self.Speakers[speakerName:lower()] = nil

		local success, err = pcall(function() self.eSpeakerRemoved:Fire(n) end)
		if not success and err then
			print("Error removing speaker: " ..err)
		end

	else
		warn("Speaker \"" .. speakerName .. "\" does not exist!")
	end
end

function methods:GetSpeaker(speakerName)
	return self.Speakers[speakerName:lower()]
end

function methods:GetChannelList()
	local list = {}
	for i, channel in pairs(self.ChatChannels) do
		if (not channel.Private) then
			table.insert(list, channel.Name)
		end
	end
	return list
end

function methods:GetAutoJoinChannelList()
	local list = {}
	for i, channel in pairs(self.ChatChannels) do
		if channel.AutoJoin then
			table.insert(list, channel)
		end
	end
	return list
end

function methods:GetSpeakerList()
	local list = {}
	for i, speaker in pairs(self.Speakers) do
		table.insert(list, speaker.Name)
	end
	return list
end

function methods:SendGlobalSystemMessage(message)
	for i, speaker in pairs(self.Speakers) do
		speaker:SendSystemMessage(message, nil)
	end
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
	if self.ProcessCommandsFunctions[funcId] then
		error(funcId .. " is already in use!")
	end

	self.ProcessCommandsFunctions[funcId] = func
end

function methods:UnregisterProcessCommandsFunction(funcId)
	self.ProcessCommandsFunctions[funcId] = nil
end

--///////////////// Internal-Use Methods
--//////////////////////////////////////
--DO NOT REMOVE THIS. Chat must be filtered or your game will face
--moderation.
function methods:InternalApplyRobloxFilter(speakerName, message, toSpeakerName)
	if (RunService:IsServer() and not RunService:IsStudio()) then
		local fromSpeaker = self:GetSpeaker(speakerName)
		local toSpeaker = self:GetSpeaker(toSpeakerName)
		if (fromSpeaker and toSpeaker) then
			local fromPlayerObj = fromSpeaker:GetPlayer()
			local toPlayerObj = toSpeaker:GetPlayer()
			if (fromPlayerObj and toPlayerObj) then
				message = Chat:FilterStringAsync(message, fromPlayerObj, toPlayerObj)
			end
		end
	else
		--// Simulate filtering latency.
		wait(0.2)
	end

	return message
end

function methods:InternalDoMessageFilter(speakerName, messageObj, channel)
	for funcId, func in pairs(self.FilterMessageFunctions) do
		local s, m = pcall(function()
			func(speakerName, messageObj, channel)
		end)

		if (not s) then
			warn(string.format("DoMessageFilter Function '%s' failed for reason: %s", funcId, m))
		end
	end
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

function methods:InternalGetUniqueMessageId()
	local id = self.MessageIdCounter
	self.MessageIdCounter = id + 1
	return id
end

function methods:InternalAddSpeakerWithPlayerObject(speakerName, playerObj)
	if (self.Speakers[speakerName:lower()]) then
		error("Speaker \"" .. speakerName .. "\" already exists!")
	end

	local speaker = Speaker.new(self, speakerName)
	speaker:InternalAssignPlayerObject(playerObj)
	self.Speakers[speakerName:lower()] = speaker

	local success, err = pcall(function() self.eSpeakerAdded:Fire(speakerName) end)
	if not success and err then
		print("Error adding speaker: " ..err)
	end

	return speaker
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("ChatService", methods)

function module.new()
	local obj = {}

	obj.MessageIdCounter = 0

	obj.ChatChannels = {}
	obj.Speakers = {}

	obj.FilterMessageFunctions = {}
	obj.ProcessCommandsFunctions = {}

	obj.eChannelAdded = Instance.new("BindableEvent")
	obj.eChannelRemoved = Instance.new("BindableEvent")
	obj.eSpeakerAdded = Instance.new("BindableEvent")
	obj.eSpeakerRemoved = Instance.new("BindableEvent")

	obj.ChannelAdded = obj.eChannelAdded.Event
	obj.ChannelRemoved = obj.eChannelRemoved.Event
	obj.SpeakerAdded = obj.eSpeakerAdded.Event
	obj.SpeakerRemoved = obj.eSpeakerRemoved.Event

	ClassMaker.MakeClass("ChatService", obj)

	return obj
end

return module.new()
