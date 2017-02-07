--	// FileName: SinkCommands.lua
--	// Written by: TheGamer101
--	// Description: Sink commands begining with '/', as this is commonly used with admin commands.
-- This was also the behaviour of the old chat. (This is does not apply to commands using the offical chat API)

local Chat = game:GetService("Chat")
local ReplicatedModules = Chat:WaitForChild("ClientChatModules")
local ChatSettings = require(ReplicatedModules:WaitForChild("ChatSettings"))
local ChatConstants = require(ReplicatedModules:WaitForChild("ChatConstants"))

local COMMAND_STARTERS = {'/'}

if ChatSettings.ChatCommandStarters then
	COMMAND_STARTERS = ChatSettings.ChatCommandStarters
end

local function Run(ChatService)

	local function SinkCommandsFunction(speakerName, message, channel)
		for i = 1, #COMMAND_STARTERS do
			local starter = COMMAND_STARTERS[i]
			if string.sub(message, 1, string.len(starter)) == starter then
				return true
			end
		end
		return false
	end

	if ChatConstants.VeryLowPriority then
		ChatService:RegisterProcessCommandsFunction("sink_commands", SinkCommandsFunction, ChatSettings.VeryLowPriority)
	end
end

return Run
