--	// FileName: PrivateMessaging.lua
--	// Written by: Xsitsu
--	// Description: Module that handles all private messaging.

local Chat = game:GetService("Chat")
local ReplicatedModules = Chat:WaitForChild("ClientChatModules")
local ChatConstants = require(ReplicatedModules:WaitForChild("ChatConstants"))

local errorExtraData = {ChatColor = Color3.fromRGB(245, 50, 50)}

local function Run(ChatService)

	local function DoWhisperCommand(fromSpeaker, message, channel)
		local otherSpeakerName = message
		local sendMessage = nil

		if (string.sub(message, 1, 1) == "\"") then
			local pos = string.find(message, "\"", 2)
			if (pos) then
				otherSpeakerName = string.sub(message, 2, pos - 1)
				sendMessage = string.sub(message, pos + 1)
			end
		else
			local first = string.match(message, "^[^%s]+")
			if (first) then
				otherSpeakerName = first
				sendMessage = string.sub(message, string.len(otherSpeakerName) + 1)
			end
		end

		local speaker = ChatService:GetSpeaker(fromSpeaker)
		local channelObj = ChatService:GetChannel("To " .. otherSpeakerName)
		if (channelObj and ChatService:GetSpeaker(otherSpeakerName)) then

			if (channelObj.Name == "To " .. speaker.Name) then
				speaker:SendSystemMessage("You cannot whisper to yourself.", channel, errorExtraData)
			else
				if (not speaker:IsInChannel(channelObj.Name)) then
					speaker:JoinChannel(channelObj.Name)
				end

				if (sendMessage and (string.len(sendMessage) > 0) ) then
					speaker:SayMessage(sendMessage, channelObj.Name)
				end

				speaker:SetMainChannel(channelObj.Name)

			end

		else
			speaker:SendSystemMessage(string.format("Speaker '%s' does not exist.", tostring(otherSpeakerName)), channel, errorExtraData)

		end
	end

	local function WhisperCommandsFunction(fromSpeaker, message, channel)
		local processedCommand = false

		if (string.sub(message, 1, 3):lower() == "/w ") then
			DoWhisperCommand(fromSpeaker, string.sub(message, 4), channel)
			processedCommand = true

		elseif (string.sub(message, 1, 9):lower() == "/whisper ") then
			DoWhisperCommand(fromSpeaker, string.sub(message, 10), channel)
			processedCommand = true

		end

		return processedCommand
	end

	local function PrivateMessageReplicationFunction(fromSpeaker, message, channelName)
		local sendingSpeaker = ChatService:GetSpeaker(fromSpeaker)
		local extraData = sendingSpeaker.ExtraData
		sendingSpeaker:SendMessage(message, channelName, fromSpeaker, extraData)

		local toSpeaker = ChatService:GetSpeaker(string.sub(channelName, 4))
		if (toSpeaker) then
			if (not toSpeaker:IsInChannel("To " .. fromSpeaker)) then
				toSpeaker:JoinChannel("To " .. fromSpeaker)
			end
			toSpeaker:SendMessage(message, "To " .. fromSpeaker, fromSpeaker, extraData)
		end

		return true
	end

	local function PrivateMessageAddTypeFunction(speakerName, messageObj, channelName)
		if ChatConstants.MessageTypeWhisper then
			messageObj.MessageType = ChatConstants.MessageTypeWhisper
		end
	end

	ChatService:RegisterProcessCommandsFunction("whisper_commands", WhisperCommandsFunction)

	ChatService.SpeakerAdded:connect(function(speakerName)
		if (ChatService:GetChannel("To " .. speakerName)) then
			ChatService:RemoveChannel("To " .. speakerName)
		end

		local channel = ChatService:AddChannel("To " .. speakerName)
		channel.Joinable = false
		channel.Leavable = true
		channel.AutoJoin = false
		channel.Private = true

		channel.WelcomeMessage = "You are now privately chatting with " .. speakerName .. "."

		channel:RegisterProcessCommandsFunction("replication_function", PrivateMessageReplicationFunction)
		channel:RegisterFilterMessageFunction("message_type_function", PrivateMessageAddTypeFunction)
	end)

	ChatService.SpeakerRemoved:connect(function(speakerName)
		if (ChatService:GetChannel("To " .. speakerName)) then
			ChatService:RemoveChannel("To " .. speakerName)
		end
	end)
end

return Run
