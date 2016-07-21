local source = [[
local modulesFolder = script.Parent

local ChatChannelProxy = require(modulesFolder:WaitForChild("ChatChannelProxy"))
local SpeakerProxy = require(modulesFolder:WaitForChild("SpeakerProxy"))

local module = {}

local function AssignmentError(index, expected, got)
	error("bad argument #3 to '" .. index .. "' (" .. expected .. " expected, got " .. got .. ")")
end

local function NotAValidMemberError(index, obj)
	error(index .. " is not a valid member of " .. obj.Target.__ClassName)
end

local function TypeCastError(from, to)
	error("Unable to cast " .. from .. " to " .. to)
end


local function AssertAssignmentTypeEquals(index, var, t)
	if (type(var) ~= t) then AssignmentError(index, t, type(var)) end
end

local function AssertParameterTypeEquals(var, t)
	if (type(var) ~= t) then TypeCastError(type(var), t) end
end

function module.CreateProxy(ChatService)
	local proxy = newproxy(true)
	local obj = {}
	obj.Target = ChatService
	
	
	function obj:AddChannel(channelName)
		AssertParameterTypeEquals(channelName, "string")
		return ChatChannelProxy.CreateProxy(obj.Target:AddChannel(channelName))
	end
	
	function obj:RemoveChannel(channelName)
		AssertParameterTypeEquals(channelName, "string")
		
		obj.Target:RemoveChannel(channelName)
	end
	
	function obj:GetChannel(channelName)
		AssertParameterTypeEquals(channelName, "string")
		
		local channel = obj.Target:GetChannel(channelName)
		return channel and ChatChannelProxy.CreateProxy(channel) or nil
	end
	
	function obj:AddSpeaker(speakerName)
		AssertParameterTypeEquals(speakerName, "string")
		return SpeakerProxy.CreateProxy(obj.Target:AddSpeaker(speakerName))
	end
	
	function obj:RemoveSpeaker(speakerName)
		AssertParameterTypeEquals(speakerName, "string")
		
		local spkr = obj.Target:GetSpeaker(speakerName)
		if (spkr and spkr:GetPlayerObject()) then
			error("Cannot remove Speaker object in use by Player!")
		end
		
		obj.Target:RemoveSpeaker(speakerName)
	end
	
	function obj:GetSpeaker(speakerName)
		AssertParameterTypeEquals(speakerName, "string")
		local speaker = obj.Target:GetSpeaker(speakerName)
		return speaker and SpeakerProxy.CreateProxy(speaker) or nil
	end
	
	function obj:GetAutoJoinChannelList()
		local list = obj.Target:GetAutoJoinChannelList()
		local proxyList = {}
		for i, channel in pairs(list) do
			table.insert(proxyList, channel.Name)
		end
		return proxyList
	end
	
	function obj:AddWordFilter(expression)
		AssertParameterTypeEquals(expression, "string")
		obj.Target:AddWordFilter(expression)
	end
	
	function obj:RemoveWordFilter(expression)
		AssertParameterTypeEquals(expression, "string")
		obj.Target:RemoveWordFilter(expression)
	end
	
	function obj:AddWordAlias(expression, replacement)
		AssertParameterTypeEquals(expression, "string")
		AssertParameterTypeEquals(replacement, "string")
		obj.Target:AddWordAlias(expression, replacement)
	end
	
	function obj:RemoveWordAlias(expression)
		AssertParameterTypeEquals(expression, "string")
		obj.Target:RemoveWordAlias(expression)
	end
	
	function obj:GetChannelList()
		return obj.Target:GetChannelList()
	end
	
	function obj:RegisterFilterMessageFunction(funcId, func)
		AssertParameterTypeEquals(funcId, "string")
		AssertParameterTypeEquals(func, "function")
		
		if (funcId == "default_filter") then
			error("You cannot register this filter!")
		end

		obj.Target:RegisterFilterMessageFunction(funcId, func)
	end

	function obj:UnregisterFilterMessageFunction(funcId, func)
		AssertParameterTypeEquals(funcId, "string")
		
		if (funcId == "default_filter") then
			error("You cannot unregister this filter!")
		end
		
		obj.Target:UnregisterFilterMessageFunction(funcId)
	end
	
	function obj:RegisterProcessCommandsFunction(funcId, func)
		AssertParameterTypeEquals(funcId, "string")
		AssertParameterTypeEquals(func, "function")
		
		if (funcId == "default_commands") then
			error("You cannot register this set of commands!")
		end
		
		obj.Target:RegisterProcessCommandsFunction(funcId, func)
	end
	
	function obj:UnregisterProcessCommandsFunction(funcId)
		AssertParameterTypeEquals(funcId, "string")
		
		if (funcId == "default_commands") then
			error("You cannot unregister this set of commands!")
		end
		
		obj.Target:UnregisterProcessCommandsFunction(funcId)
	end
	
	local metatable = getmetatable(proxy)
	metatable.__metatable = "The metatable is locked"
	metatable.__tostring = function () return tostring(obj.Target) end
	
	local readIndexTarget = {
		ChannelAdded = true, ChannelRemoved = true,
		SpeakerAdded = true, SpeakerRemoved = true
	}
	local readIndexProxy = {
		AddChannel = true, RemoveChannel = true, GetChannel = true,
		AddSpeaker = true, RemoveSpeaker = true, GetSpeaker = true,
		GetAutoJoinChannelList = true,
		AddWordFilter = true, RemoveWordFilter = true,
		AddWordAlias = true, RemoveWordAlias = true,
		GetChannelList = true,
		RegisterFilterMessageFunction = true, UnregisterFilterMessageFunction = true,
		RegisterProcessCommandsFunction = true, UnregisterProcessCommandsFunction = true,
	}

	metatable.__index = function(tbl, index)
		if (readIndexTarget[index]) then
			return obj.Target[index]
			
		elseif (readIndexProxy[index]) then
			return obj[index]
			
		else
			NotAValidMemberError(index, obj)
			
		end
	end
	
	metatable.__newindex = function(tbl, index, value)
		if (false) then
			--// Not really any properties to let users set, 
			--// but the same style of flow control should be kept
		else
			NotAValidMemberError(index, obj)
			
		end
	end	
	
	
	return proxy
end

return module

]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script