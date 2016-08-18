local source = [[
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
				speaker:SendSystemMessage("You cannot whisper to yourself.", nil)
			else
				if (not speaker:IsInChannel(channelObj.Name)) then
					speaker:JoinChannel(channelObj.Name)
				end

				if (sendMessage and (string.len(sendMessage) > 0) ) then
					speaker:SayMessage(sendMessage, channelObj.Name)
				else
					speaker:SetMainChannel(channelObj.Name)
				end

			end

		else
			speaker:SendSystemMessage("Speaker '" .. tostring(otherSpeakerName) .. "' does not exist.", nil)

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
	
	local function PrivateMessageReplicationFunction(fromSpeaker, message, channel)
		ChatService:GetSpeaker(fromSpeaker):SendMessage(fromSpeaker, channel, message)

		local toSpeaker = ChatService:GetSpeaker(string.sub(channel, 4))
		if (toSpeaker) then
			if (not toSpeaker:IsInChannel("To " .. fromSpeaker)) then
				toSpeaker:JoinChannel("To " .. fromSpeaker)
			end
			toSpeaker:SendMessage(fromSpeaker, "To " .. fromSpeaker, message)
		end
		
		return true
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
	end)
	
	ChatService.SpeakerRemoved:connect(function(speakerName)
		if (ChatService:GetChannel("To " .. speakerName)) then
			ChatService:RemoveChannel("To " .. speakerName)
		end
	end)
end

return Run
]]


local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script