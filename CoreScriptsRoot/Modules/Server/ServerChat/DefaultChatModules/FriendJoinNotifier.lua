--	// FileName: FriendJoinNotifer.lua
--	// Written by: TheGamer101
--	// Description: Module that adds a message to the chat whenever a friend joins the game.

local Chat = game:GetService("Chat")
local Players = game:GetService("Players")

local ReplicatedModules = Chat:WaitForChild("ClientChatModules")
local ChatSettings = require(ReplicatedModules:WaitForChild("ChatSettings"))
local ChatConstants = require(ReplicatedModules:WaitForChild("ChatConstants"))

local FriendMessageTextColor = Color3.fromRGB(255, 255, 255)
local FriendMessageExtraData = {ChatColor = FriendMessageTextColor}

local function Run(ChatService)

	local function ShowFriendJoinNotification()
		if ChatSettings.ShowFriendJoinNotification ~= nil then
			return ChatSettings.ShowFriendJoinNotification
		end
		return false
	end

	local function SendFriendJoinNotification(player, joinedFriend)
		local speakerObj = ChatService:GetSpeaker(player.Name)
		if speakerObj then
			speakerObj:SendSystemMessage(string.format("Your friend %s has joined the game.", joinedFriend.Name), "System", FriendMessageExtraData)
		end
	end

	if ShowFriendJoinNotification() then
		Players.PlayerAdded:connect(function(player)
			local possibleFriends = Players:GetPlayers()
			for i = 1, #possibleFriends do
				if player ~= possibleFriends[i] then
					coroutine.wrap(function()
						if possibleFriends[i]:IsFriendsWith(player.UserId) then
							SendFriendJoinNotification(possibleFriends[i], player)
						end
					end)()
				end
			end
		end)
	end
end

return Run
