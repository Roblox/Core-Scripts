local source = [[
local function Run(ChatService)
	
	local function DoWhisperCommand(fromSpeaker, message, channel)
		local speaker = ChatService:GetSpeaker(fromSpeaker)
		local channelObj = ChatService:GetChannel(message)
		if (channelObj and ChatService:GetSpeaker(channelObj.Name)) then
			
			if (channelObj.Name == speaker.Name) then
				speaker:SendSystemMessage("You cannot whisper to yourself.", nil)
			else
				if (not speaker:IsInChannel(message)) then
					speaker:JoinChannel(message)
				end
			end
			
			
		else
			speaker:SendSystemMessage("Speaker '" .. message .. "' does not exist.", nil)
		end
	end
	
	local function WhisperCommandsFunction(fromSpeaker, message, channel)
		if (string.sub(message, 1, 3):lower() == "/w ") then
			DoWhisperCommand(fromSpeaker, string.sub(message, 4), channel)
			return true
			
		elseif (string.sub(message, 1, 9):lower() == "/whisper ") then
			DoWhisperCommand(fromSpeaker, string.sub(message, 10), channel)
			return true
			
		end
		
		return false
	end
	
	local function PrivateMessageReplicationFunction(fromSpeaker, message, channel)
		ChatService:GetSpeaker(fromSpeaker):SendMessage(fromSpeaker, channel, message)

		local toSpeaker = ChatService:GetSpeaker(channel)
		if (toSpeaker) then
			if (not toSpeaker:IsInChannel(fromSpeaker)) then
				toSpeaker:JoinChannel(fromSpeaker)
			end
			toSpeaker:SendMessage(fromSpeaker, fromSpeaker, message)
		end
		
		return true
	end
	
	ChatService:RegisterProcessCommandsFunction("whisper_commands", WhisperCommandsFunction)
	
	ChatService.OnSpeakerAdded:connect(function(speakerName)
		if (ChatService:GetChannel(speakerName)) then
			ChatService:RemoveChannel(speakerName)
		end
		
		local channel = ChatService:AddChannel(speakerName)
		channel.Joinable = false
		channel.Private = true
		channel.Leavable = true
		channel.AutoJoin = false
		
		channel.WelcomeMessage = "You are now privately chatting with " .. speakerName .. "."
		
		channel:RegisterProcessCommandsFunction("replication_function", PrivateMessageReplicationFunction)
	end)
	
	ChatService.OnSpeakerRemoved:connect(function(speakerName)
		if (ChatService:GetChannel(speakerName)) then
			ChatService:RemoveChannel(speakerName)
		end
	end)
end

return Run
]]


local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script