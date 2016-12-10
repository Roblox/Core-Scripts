--	// FileName: ChatMessageValidator.lua
--	// Written by: TheGamer101
--	// Description: Validate things such as no disallowed whitespace and chat message length on the server.

local Chat = game:GetService("Chat")
local RunService = game:GetService("RunService")
local ReplicatedModules = Chat:WaitForChild("ClientChatModules")
local ChatSettings = require(ReplicatedModules:WaitForChild("ChatSettings"))

local DISALLOWED_WHITESPACE = {"\n", "\r", "\t", "\v", "\f"}

if ChatSettings.DisallowedWhiteSpace then
	DISALLOWED_WHITESPACE = ChatSettings.DisallowedWhiteSpace
end

local function Run(ChatService)
	local function ValidateChatFunction(speakerName, message, channel)
		local speakerObj = ChatService:GetSpeaker(speakerName)
		local playerObj = speakerObj:GetPlayer()
		if not speakerObj then return false end
		if not playerObj then return false end
		
		if not RunService:IsStudio() and playerObj.UserId < 1 then
			return true
		end
		
		if message:len() > ChatSettings.MaximumMessageLength + 1 then
			speakerObj:SendSystemMessage("Your message exceeds the maximum message length.", channel)
			return true
		end

		for i = 1, #DISALLOWED_WHITESPACE do
			if string.find(message, DISALLOWED_WHITESPACE[i]) then
				speakerObj:SendSystemMessage("Your message contains whitespace that is not allowed.", channel)
				return true
			end
		end
		return false
	end

	ChatService:RegisterProcessCommandsFunction("message_validation", ValidateChatFunction)
end

return Run
