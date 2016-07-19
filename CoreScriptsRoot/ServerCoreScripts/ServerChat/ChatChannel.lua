local source = [[
local module = {}

--////////////////////////////// Details
--//////////////////////////////////////
local metatable = {}
metatable.__ClassName = "ChatChannel"

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
	for i, speaker in pairs(self.Speakers) do
		speaker:LeaveChannel(self.Name)
	end
	
	self.eOnDestroyed:Fire()
end

function metatable:DoMessageFilter(speakerName, message)
	for i, func in pairs(self.FilterMessageFunctions) do
		local s, m = pcall(function()
			local ret = func(speakerName, message)
			assert(type(ret) == "string")
			message = ret
		end)

		if (not s) then
			warn("DoMessageFilter Function '" .. funcId .. "'' failed for reason: " .. m)
		end
	end
	
	message = self.FilterMessageFunctions["default_filter"](speakerName, message)
	
	return message
end

function metatable:DoProcessCommands(speakerName, message)
	local processed = false
	
	processed = self.ProcessCommandsFunctions["default_commands"](speakerName, message, self.Name)
	if (processed) then return processed end
	
	for i, func in pairs(self.ProcessCommandsFunctions) do
		local s, m = pcall(function()
			local ret = func(speakerName, message, self.Name)
			if type(ret) == "boolean" then
				processed = ret
			end
		end)
		
		if (not s) then
			warn("DoProcessCommands Function '" .. funcId .. "'' failed for reason: " .. m)
		end
		
		if (processed) then break end
	end
	
	return processed
end

function metatable:PostMessage(fromSpeaker, message)
	if (self:DoProcessCommands(fromSpeaker.Name, message)) then return false end

	if (self.Mutes[fromSpeaker.Name:lower()] ~= nil) then
		local t = self.Mutes[fromSpeaker.Name:lower()]
		if (t > 0 and os.time() > t) then
			self:UnmuteSpeaker(fromSpeaker.Name)
		else
			fromSpeaker:SendSystemMessage("You are muted and cannot talk in this channel", self.Name)
			return false
		end
		
	end
	
	message = self:DoMessageFilter(fromSpeaker.Name, message)
	message = self.ChatService:DoMessageFilter(fromSpeaker.Name, message)
	
	spawn(function() self.eOnNewMessage:Fire(fromSpeaker.Name, message) end)
	
	for i, speaker in pairs(self.Speakers) do
		if (true or speaker ~= fromSpeaker) then
			speaker:SendMessage(fromSpeaker.Name, self.Name, message)
		end
	end
	
end

function metatable:InternalAddSpeaker(speaker)
	if (self.Speakers[speaker.Name]) then
		warn("Speaker \"" .. speaker.name .. "\" is already in the channel!")
		return
	end
	
	self.Speakers[speaker.Name] = speaker
	spawn(function() self.eOnSpeakerJoined:Fire(speaker.Name) end)
end

function metatable:InternalRemoveSpeaker(speaker)
	if (not self.Speakers[speaker.Name]) then
		warn("Speaker \"" .. speaker.name .. "\" is already in the channel!")
		return
	end
	
	self.Speakers[speaker.Name] = nil
	spawn(function() self.eOnSpeakerLeft:Fire(speaker.Name) end)
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

function metatable:KickSpeaker(speakerName, reason)
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

function metatable:MuteSpeaker(speakerName, reason, length)
	local speaker = self.ChatService:GetSpeaker(speakerName)
	if (not speaker) then
		error("Speaker \"" .. speakerName .. "\" does not exist!")
	end
	
	self.Mutes[speakerName:lower()] = (length == 0 or length == nil) and 0 or (os.time() + length)

	if (reason) then
		self:SendSystemMessage(speakerName .. " was muted for the following reason(s): " .. reason)
	end

	spawn(function() self.eOnSpeakerMuted:Fire(speakerName, reason, length) end)
	local spkr = self.ChatService:GetSpeaker(speakerName)
	if (spkr) then
		spawn(function() spkr.eOnMuted:Fire(self.Name, reason, length) end)
	end

end

function metatable:UnmuteSpeaker(speakerName)
	local speaker = self.ChatService:GetSpeaker(speakerName)
	if (not speaker) then
		error("Speaker \"" .. speakerName .. "\" does not exist!")
	end
	
	self.Mutes[speakerName:lower()] = nil

	spawn(function() self.eOnSpeakerUnmuted:Fire(speakerName) end)
	local spkr = self.ChatService:GetSpeaker(speakerName)
	if (spkr) then
		spawn(function() spkr.eOnUnmuted:Fire(self.Name) end)
	end
end

function metatable:IsSpeakerMuted(speakerName)
	return (self.Mutes[speakerName:lower()] ~= nil)
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
	if (self.ProcessCommandsFunctions[funcId]) then
		error(funcId .. " is already in use!")
	end
	
	self.ProcessCommandsFunctions[funcId] = func
end

function metatable:UnregisterProcessCommandsFunction(funcId)
	self.ProcessCommandsFunctions[funcId] = nil
end

function metatable:SendSystemMessage(message)
	for i , speaker in pairs(self.Speakers) do
		speaker:SendSystemMessage(message, self.Name)
	end
end

--///////////////////////// Constructors
--//////////////////////////////////////
function module.new(vChatService, name, welcomeMessage)
	local obj = {}
	obj.MemoryLocation = tostring(obj):match("[0123456789ABCDEF]+")
	
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
	
	obj.WordFilters = {}
	obj.WordAliases = {}
	
	obj.FilterMessageFunctions = {}
	obj.ProcessCommandsFunctions = {}
	
	obj.eOnDestroyed = Instance.new("BindableEvent")
	obj.OnDestroyed = obj.eOnDestroyed.Event
	
	obj.eOnNewMessage = Instance.new("BindableEvent")
	obj.eOnSpeakerJoined = Instance.new("BindableEvent")
	obj.eOnSpeakerLeft = Instance.new("BindableEvent")
	obj.eOnSpeakerMuted = Instance.new("BindableEvent")
	obj.eOnSpeakerUnmuted = Instance.new("BindableEvent")

	obj.OnNewMessage = obj.eOnNewMessage.Event
	obj.OnSpeakerJoined = obj.eOnSpeakerJoined.Event
	obj.OnSpeakerLeft = obj.eOnSpeakerLeft.Event
	obj.OnSpeakerMuted = obj.eOnSpeakerMuted.Event
	obj.OnSpeakerUnmuted = obj.eOnSpeakerUnmuted.Event
	
	obj = setmetatable(obj, metatable)
	
	return obj
end

return module

]]


local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script