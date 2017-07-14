--	// FileName: SwallowGuestChat.lua
--	// Written by: TheGamer101
--	// Description: Stop Guests from chatting and give them a message telling them to sign up.
-- 	// Guests are generally not allowed to chat, so please do not remove this.

local util = require(script.Parent:WaitForChild("Util"))
local RunService = game:GetService("RunService")

function ProcessMessage(message, ChatWindow, ChatSettings)
	local LocalPlayer = game:GetService("Players").LocalPlayer
	if LocalPlayer and LocalPlayer.UserId < 0 and not RunService:IsStudio() then

		local channelObj = ChatWindow:GetCurrentChannel()
		if channelObj then
			util:SendSystemMessageToSelf("Create a free account to get access to chat permissions!", channelObj, {})
		end

		return true
	end
	return false
end

return {
	[util.KEY_COMMAND_PROCESSOR_TYPE] = util.COMPLETED_MESSAGE_PROCESSOR,
	[util.KEY_PROCESSOR_FUNCTION] = ProcessMessage
}
