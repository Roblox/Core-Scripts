local source = [[
local module = {}

local function AssignmentError(index, expected, got)
	error("bad argument #3 to '" .. index .. "' (" .. expected .. " expected, got " .. tostring(got) .. ")")
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

function module.CreateProxy(Speaker)
	local proxy = newproxy(true)
	local metatable = getmetatable(proxy)
	local obj = {}
	obj.Target = Speaker
	
	obj.Target.Destroyed:connect(function()
		obj.Target = nil
		
		metatable.__tostring = function() return "" end
		metatable.__index = function() error("Object is destroyed!") end
		metatable.__newindex = function() error("Object is destroyed!") end
	end)
	
	function obj:SayMessage(message, channelName)
		AssertParameterTypeEquals(message, "string")
		AssertParameterTypeEquals(channelName, "string")
		
		obj.Target:SayMessage(message, channelName)
	end
	
	function obj:JoinChannel(channelName)
		AssertParameterTypeEquals(channelName, "string")
		obj.Target:JoinChannel(channelName)
	end
	
	function obj:LeaveChannel(channelName)
		AssertParameterTypeEquals(channelName, "string")
		obj.Target:LeaveChannel(channelName)
	end
	
	function obj:GetChannelList()
		return obj.Target:GetChannelList()
	end
	
	function obj:IsInChannel(channelName)
		AssertParameterTypeEquals(channelName, "string")
		return obj.Target:IsInChannel(channelName)
	end
	
	function obj:SendMessage(fromSpeaker, channel, message)
		AssertParameterTypeEquals(fromSpeaker, "string")
		AssertParameterTypeEquals(channel, "string")
		AssertParameterTypeEquals(message, "string")
		
		if (not obj.Target:IsInChannel(channel)) then
			error("Speaker is not in channel '" .. channel .. "'.")
		end
		
		obj.Target:SendMessage(fromSpeaker, channel, message)
	end
	
	function obj:SendSystemMessage(message, channel)
		AssertParameterTypeEquals(message, "string")
		if (channel ~= nil) then
			AssertParameterTypeEquals(channel, "string")
			
			if (not obj.Target:IsInChannel(channel)) then
				error("Speaker is not in channel '" .. channel .. "'.")
			end
		end
		
		obj.Target:SendSystemMessage(message, channel)
	end
	
	function obj:GetPlayerObject()
		return obj.Target:GetPlayerObject()
	end
	
	function obj:SetExtraData(key, value)
		obj.Target:SetExtraData(key, value)
	end
	
	function obj:GetExtraData(key)
		return obj.Target:GetExtraData(key)
	end

	function obj:SetMainChannel(channel)
		AssertParameterTypeEquals(channel, "string")
		obj.Target:SetMainChannel(channel)
	end
	
	metatable.__metatable = "The metatable is locked"
	metatable.__tostring = obj.Target.__tostring
	
	local readIndexTarget = {
		Name = true,
		SaidMessage = true, ReceivedMessage = true, ReceivedSystemMessage = true, 
		ChannelJoined = true, ChannelLeft = true,
		Muted = true, Unmuted = true,
		ExtraDataUpdated = true,
	}
	local readIndexProxy = {
		SayMessage = true, 
		JoinChannel = true, LeaveChannel = true, IsInChannel = true, 
		SendMessage = true, SendSystemMessage = true, 
		GetPlayerObject = true, 
		SetExtraData = true, GetExtraData = true, 
		GetChannelList = true,
		SetMainChannel = true,
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