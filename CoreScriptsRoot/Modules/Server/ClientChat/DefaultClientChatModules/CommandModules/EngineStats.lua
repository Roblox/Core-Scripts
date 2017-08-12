--	// FileName: EngineStats.lua
--	// Written by: CloneTrooper1019
--	// Description: Command to toggle engine stats.

local StarterGui = game:GetService("StarterGui")
local util = require(script.Parent:WaitForChild("Util"))

local statsMap =
{
	general = "Genstats";
	rendering = "Renstats";
	network = "Netstats";
	physics = "Phystats";
	summary = "Sumstats";
	custom = "Cusstats";
}

function ProcessMessage(message, ChatWindow, ChatSettings)
	if string.sub(message, 1, 12):lower() == "/togglestats" then
		local currentChannel = ChatWindow:GetCurrentChannel()
		local stat = message:sub(14):lower()
		if stat == "" then
			stat = "general"
		end
		if statsMap[stat] then
			local success = pcall(function () StarterGui:SetCore("ShowStatsBasedOnInputString",statsMap[stat]) end)
			if not success then
				util:SendSystemMessageToSelf("/togglestats is currently not available.",currentChannel,{})
			end
		else
			util:SendSystemMessageToSelf(string.format("%q is not a valid /togglestats category",stat),currentChannel,{})
		end
		return true
	end
	return false
end

return {
	[util.KEY_COMMAND_PROCESSOR_TYPE] = util.COMPLETED_MESSAGE_PROCESSOR,
	[util.KEY_PROCESSOR_FUNCTION] = ProcessMessage
}
