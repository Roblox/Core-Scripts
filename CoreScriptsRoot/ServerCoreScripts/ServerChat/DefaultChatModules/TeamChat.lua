local source = [[
local function Run(ChatService)
	
	local Players = game:GetService("Players")
	
	local channel = ChatService:AddChannel("Team")
	channel.WelcomeMessage = "This is a private channel between you and your team members."
	channel.Joinable = false
	channel.Leavable = false
	channel.AutoJoin = false
	channel.Private = true

	local function TeamChatReplicationFunction(fromSpeaker, message, channel)
		local speakerObj = ChatService:GetSpeaker(fromSpeaker)
		local channelObj = ChatService:GetChannel(channel)
		if (speakerObj and channelObj) then
			local player = speakerObj:GetPlayer()
			if (player) then
				
				for i, speakerName in pairs(channelObj:GetSpeakerList()) do
					local otherSpeaker = ChatService:GetSpeaker(speakerName)
					if (otherSpeaker) then
						local otherPlayer = otherSpeaker:GetPlayer()
						if (otherPlayer) then
							
							if (player.Team == otherPlayer.Team) then
								otherSpeaker:SendMessage(fromSpeaker, channel, message)
							else
								--// Could use this line to obfuscate message for cool effects
								--otherSpeaker:SendMessage(fromSpeaker, channel, message)
							end
							
						end
					end
				end
				
			end
		end
		
		return true
	end
	
	channel:RegisterProcessCommandsFunction("replication_function", TeamChatReplicationFunction)
	
	local function PutSpeakerInCorrectTeamChatState(speakerObj, playerObj)
		if (playerObj.Neutral and speakerObj:IsInChannel(channel.Name)) then
			speakerObj:LeaveChannel(channel.Name)
			
		elseif (not playerObj.Neutral and not speakerObj:IsInChannel(channel.Name)) then
			speakerObj:JoinChannel(channel.Name)
			
		end
	end
	
	ChatService.SpeakerAdded:connect(function(speakerName)
		local speakerObj = ChatService:GetSpeaker(speakerName)
		if (speakerObj) then
			local player = speakerObj:GetPlayer()
			if (player) then
				player.Changed:connect(function(property)
					if (property == "Neutral") then
						PutSpeakerInCorrectTeamChatState(speakerObj, player)
						
					elseif (property == "Team") then
						PutSpeakerInCorrectTeamChatState(speakerObj, player)
						if (speakerObj:IsInChannel(channel.Name)) then
							speakerObj:SendSystemMessage(string.format("You are now on the '%s' team.", player.Team.Name), channel.Name)
						end
						
					end
				end)
				
				PutSpeakerInCorrectTeamChatState(speakerObj, player)
			end
		end
	end)
	
end

return Run
]]


local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script