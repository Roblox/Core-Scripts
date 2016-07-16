local source = [[
local function Run(ChatService)
	
	local Players = game:GetService("Players")
	
	local channel = ChatService:AddChannel("Team")
	channel.Private = true
	channel.Joinable = false
	channel.Leavable = false
	channel.AutoJoin = false
	channel.WelcomeMessage = "This is a private channel between you and your team members."
	
	local function TeamChatReplicationFunction(fromSpeaker, message, channel)
		local speakerObj = ChatService:GetSpeaker(fromSpeaker)
		local channelObj = ChatService:GetChannel(channel)
		if (speakerObj and channelObj) then
			local player = speakerObj:GetPlayerObject()
			if (player) then
				
				for i, speakerName in pairs(channelObj:GetSpeakerList()) do
					local otherSpeaker = ChatService:GetSpeaker(speakerName)
					if (otherSpeaker) then
						local otherPlayer = otherSpeaker:GetPlayerObject()
						if (otherPlayer) then
							
							if (player.TeamColor == otherPlayer.TeamColor) then
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
	
	ChatService.OnSpeakerAdded:connect(function(speakerName)
		local speakerObj = ChatService:GetSpeaker(speakerName)
		if (speakerObj) then
			local player = speakerObj:GetPlayerObject()
			if (player) then
				player.Changed:connect(function(property)
					if (property == "Neutral") then
						PutSpeakerInCorrectTeamChatState(speakerObj, player)
						
					elseif (property == "TeamColor") then
						PutSpeakerInCorrectTeamChatState(speakerObj, player)
						if (speakerObj:IsInChannel(channel.Name)) then
							speakerObj:SendSystemMessage("You are now on the '" .. player.TeamColor.Name .. "' team.", channel.Name)
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