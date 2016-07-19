local source = [[
local module = {}

local modulesFolder = script.Parent

--////////////////////////////// Include
--//////////////////////////////////////
local ChatChannel = require(modulesFolder:WaitForChild("ChatChannel"))
local Speaker = require(modulesFolder:WaitForChild("Speaker"))

--////////////////////////////// Details
--//////////////////////////////////////
local metatable = {}
metatable.__ClassName = "ChatService"

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

function metatable:DoMessageFilter(speakerName, message)
	for _, func in pairs(self.FilterMessageFunctions) do
		pcall(function()
			local ret = func(speakerName, message)
			assert(type(ret) == "string")
			message = ret
		end)
	end
	
	message = self.FilterMessageFunctions["default_filter"](speakerName, message)
	
	if (game:GetService("RunService"):IsServer() and not game:GetService("RunService"):IsStudio()) then
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

function metatable:DoProcessCommands(speakerName, message, channel)
	local processed = false
	
	processed = self.ProcessCommandsFunctions["default_commands"](speakerName, message)
	if (processed) then return processed end
	
	for _, func in pairs(self.ProcessCommandsFunctions) do
		processed = pcall(function()
			local ret = func(speakerName, message, channel)
			if (type(ret) ~= "boolean" or ret ~= true) then
				error("break")
			end
		end)
		
		if (processed) then break end
	end
	
	return processed
end

function metatable:AddChannel(channelName)
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
	
	spawn(function() self.eOnChannelAdded:Fire(channelName) end)

	return channel
end

function metatable:RemoveChannel(channelName)
	if (self.ChatChannels[channelName:lower()]) then
		local n = self.ChatChannels[channelName:lower()].Name
		
		self.ChatChannels[channelName:lower()]:Destroy()
		self.ChatChannels[channelName:lower()] = nil

		spawn(function() self.eOnChannelRemoved:Fire(n) end)
	else
		warn(string.format("Channel %q does not exist.", channelName))
	end
end

function metatable:GetChannel(channelName)
	return self.ChatChannels[channelName:lower()]
end


function metatable:AddSpeaker(speakerName)
	if (self.Speakers[speakerName:lower()]) then
		error("Speaker \"" .. speakerName .. "\" already exists!")
	end
	
	local speaker = Speaker.new(self, speakerName)
	self.Speakers[speakerName:lower()] = speaker
	
	spawn(function() self.eOnSpeakerAdded:Fire(speakerName) end)

	return speaker
end

function metatable:RemoveSpeaker(speakerName)
	if (self.Speakers[speakerName:lower()]) then
		local n = self.Speakers[speakerName:lower()].Name

		self.Speakers[speakerName:lower()]:Destroy()
		self.Speakers[speakerName:lower()] = nil
		
		spawn(function() self.eOnSpeakerRemoved:Fire(n) end)
		
	else
		warn("Speaker \"" .. speakerName .. "\" does not exist!")
	end
end

function metatable:GetSpeaker(speakerName)
	return self.Speakers[speakerName:lower()]
end

function metatable:GetAutoJoinChannelList()
	local list = {}
	for i, channel in pairs(self.ChatChannels) do
		if channel.AutoJoin then
			table.insert(list, channel)
		end
	end
	return list
end

function metatable:AddWordFilter(expression)
	self.WordFilters[expression] = true
end

function metatable:RemoveWordFilter(expression)
	self.WordFilters[expression] = nil
end

function metatable:AddWordAlias(expression, replacement)
	self.WordAliases[expression] = replacement
end

function metatable:RemoveWordAlias(expression)
	self.WordAliases[expression] = nil
end

function metatable:GetChannelList()
	local list = {}
	for i, channel in pairs(self.ChatChannels) do
		if (not channel.Private) then
			table.insert(list, channel.Name)
		end
	end
	return list
end

function metatable:GetSpeakerList()
	local list = {}
	for i, speaker in pairs(self.Speakers) do
		table.insert(list, speaker.Name)
	end
	return list
end

function metatable:RegisterFilterMessageFunction(funcId, func)
	if self.FilterMessageFunctions[funcId] then
		error(funcId .. " is already in use!")
	end
	
	self.FilterMessageFunctions[funcId] = func
end

function metatable:UnregisterFilterMessageFunction(funcId)
	self.FilterMessageFunctions[funcId] = nil
end

function metatable:RegisterProcessCommandsFunction(funcId, func)
	if self.ProcessCommandsFunctions[funcId] then
		error(funcId .. " is already in use!")
	end
	
	self.ProcessCommandsFunctions[funcId] = func
end

function metatable:UnregisterProcessCommandsFunction(funcId)
	self.ProcessCommandsFunctions[funcId] = nil
end

function metatable:SendGlobalSystemMessage(message)
	for i, speaker in pairs(self.Speakers) do
		speaker:SendSystemMessage(message, nil)
	end
end

--///////////////////////// Constructors
--//////////////////////////////////////
function module.new()
	local obj = {}
	obj.MemoryLocation = tostring(obj):match("[0123456789ABCDEF]+")
	
	obj.ChatLogLength = 30
	
	obj.ChatChannels = {}
	obj.Speakers = {}
	
	obj.WordFilters = {}
	obj.WordAliases = {}
	
	obj.FilterMessageFunctions = {}
	obj.ProcessCommandsFunctions = {}
	
	obj.eOnChannelAdded  = Instance.new("BindableEvent")
	obj.eOnChannelRemoved = Instance.new("BindableEvent")
	obj.eOnSpeakerAdded = Instance.new("BindableEvent")
	obj.eOnSpeakerRemoved = Instance.new("BindableEvent")

	obj.OnChannelAdded = obj.eOnChannelAdded.Event
	obj.OnChannelRemoved = obj.eOnChannelRemoved.Event
	obj.OnSpeakerAdded = obj.eOnSpeakerAdded.Event
	obj.OnSpeakerRemoved = obj.eOnSpeakerRemoved.Event


	obj = setmetatable(obj, metatable)
	
	return obj
end

return module.new()

]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script