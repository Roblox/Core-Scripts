--	// FileName: ChatCommandsTeller.lua
--	// Written by: Xsitsu
--	// Description: Module that provides information on default chat commands to players.

local function Run(ChatService)

	local function ProcessCommandsFunction(fromSpeaker, message, channel)
		if (message == "/?" or message == "/help") then
			local speaker = ChatService:GetSpeaker(fromSpeaker)
			speaker:SendSystemMessage("These are the basic chat commands.", channel)
			speaker:SendSystemMessage("/me <text> : roleplaying command for doing actions.", channel)
			speaker:SendSystemMessage("/c <channel> : switch channel menu tabs.", channel)
			speaker:SendSystemMessage("/join <channel> or /j <channel> : join channel.", channel)
			speaker:SendSystemMessage("/leave <channel> or /l <channel> : leave channel. (leaves current if none specified)", channel)
			speaker:SendSystemMessage("/whisper <speaker> or /w <speaker> : open private message channel with speaker.", channel)
			speaker:SendSystemMessage("/mute <speaker> : mute a speaker.", channel)
			speaker:SendSystemMessage("/unmute <speaker> : unmute a speaker.", channel)

			local player = speaker:GetPlayer()
			if player and player.Team then
				speaker:SendSystemMessage("/team <message> or /t <message> : send a team chat to players on your team.", channel)
			end

			return true
		end

		return false
	end

	ChatService:RegisterProcessCommandsFunction("chat_commands_inquiry", ProcessCommandsFunction)

	local allChannel = ChatService:GetChannel("All")
	if (allChannel) then
		allChannel.WelcomeMessage = "Chat '/?' or '/help' for a list of chat commands."
	end
end

return Run
