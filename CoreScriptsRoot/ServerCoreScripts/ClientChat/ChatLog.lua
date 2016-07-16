local source = [[
local logs = {}

local module = {}

module.ClearLogOnleftChannel = false
module.MaxChatLogLength = 100

function module:GetChannelLog(channelName)
	local indexName = channelName:lower()
	if (not logs[indexName]) then
		logs[indexName] = {}
	end
	return logs[indexName]
end

function module:LogMessage(speakerName, channelName, message)
	local log = self:GetChannelLog(channelName)
	
	local logObject = {
		["SpeakerName"] = speakerName,
		["Message"] = message,
	}
	
	table.insert(log, logObject)
	
	while (#logObject > self.MaxChatLogLength) do
		table.remov(log, 1)
	end
end

function module:JoinedChannel(channelName)
	self:GetChannelLog(channelName)
end

function module:LeftChannel(channelName)
	if (ClearLogOnleftChannel) then
		logs[channelName:lower()] = nil
	end
end

return module

]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script