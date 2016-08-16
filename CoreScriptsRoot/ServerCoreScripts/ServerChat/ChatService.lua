local source = [[
local module = {}

local modulesFolder = script.Parent
local RunService = game:GetService("RunService")

--////////////////////////////// Include
--//////////////////////////////////////
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))
local ChatChannel = require(modulesFolder:WaitForChild("ChatChannel"))
local Speaker = require(modulesFolder:WaitForChild("Speaker"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

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
	
	message = self.FilterMessageFunctions["default_filter"](speakerName, message, channel)
	
	if (RunService:IsServer() and not RunService:IsStudio()) then
		local fromSpeaker = self:GetSpeaker(speakerName)
		if (fromSpeaker) then
			local playerObj = fromSpeaker:GetPlayerObject()
			if (playerObj) then
				message = game:GetService("Chat"):FilterStringAsync(message, playerObj, playerObj)
			end
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
			warn("DoProcessCommands Function '" .. funcId .. "' failed for reason: " .. m)
		end
		
		if (processed) then break end
	end
	
	return processed
end

function methods:AddChannel(channelName)
	if (self.ChatChannels[channelName:lower()]) then
		error(string.format("Channel %q alrady exists.", channelName))
	end
	
	local channel = ChatChannel.new(self, channelName)
	self.ChatChannels[channelName:lower()] = channel
	
	channel:RegisterFilterMessageFunction("default_filter", function(fromSpeaker, message)
		for filter, v in pairs(channel.WordFilters) do
			message = message:gsub(filter, string.rep("*", string.len(filter)))
		end
		for alias, replacement in pairs(channel.WordAliases) do
			message = message:gsub(alias, replacement)
		end
		return message
	end)
	
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
	
	spawn(function() self.eChannelAdded:Fire(channelName) end)

	return channel
end

function methods:RemoveChannel(channelName)
	if (self.ChatChannels[channelName:lower()]) then
		local n = self.ChatChannels[channelName:lower()].Name
		
		self.ChatChannels[channelName:lower()]:Destroy()
		self.ChatChannels[channelName:lower()] = nil

		spawn(function() self.eChannelRemoved:Fire(n) end)
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
	
	spawn(function() self.eSpeakerAdded:Fire(speakerName) end)

	return speaker
end

function methods:RemoveSpeaker(speakerName)
	if (self.Speakers[speakerName:lower()]) then
		local n = self.Speakers[speakerName:lower()].Name

		self.Speakers[speakerName:lower()]:Destroy()
		self.Speakers[speakerName:lower()] = nil
		
		spawn(function() self.eSpeakerRemoved:Fire(n) end)
		
	else
		warn("Speaker \"" .. speakerName .. "\" does not exist!")
	end
end

function methods:GetSpeaker(speakerName)
	return self.Speakers[speakerName:lower()]
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

function methods:AddWordFilter(expression)
	self.WordFilters[expression] = true
end

function methods:RemoveWordFilter(expression)
	self.WordFilters[expression] = nil
end

function methods:AddWordAlias(expression, replacement)
	self.WordAliases[expression] = replacement
end

function methods:RemoveWordAlias(expression)
	self.WordAliases[expression] = nil
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
	if self.ProcessCommandsFunctions[funcId] then
		error(funcId .. " is already in use!")
	end
	
	self.ProcessCommandsFunctions[funcId] = func
end

function methods:UnregisterProcessCommandsFunction(funcId)
	self.ProcessCommandsFunctions[funcId] = nil
end

function methods:SendGlobalSystemMessage(message)
	for i, speaker in pairs(self.Speakers) do
		speaker:SendSystemMessage(message, nil)
	end
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("ChatService", methods)

function module.new()
	local obj = {}
	
	obj.ChatChannels = {}
	obj.Speakers = {}
	
	obj.WordFilters = {}
	obj.WordAliases = {}
	
	obj.FilterMessageFunctions = {}
	obj.ProcessCommandsFunctions = {}
	
	obj.eChannelAdded  = Instance.new("BindableEvent")
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

]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script