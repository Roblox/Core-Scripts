--[[
	// Filename: FriendPlayerPrompt.lua
	// Version 1.0
	// Written by: TheGamer101
	// Description: Can prompt a user to send a friend request or unfriend a player.
]]--

local StarterGui = game:GetService("StarterGui")
local PlayersService = game:GetService("Players")
local CoreGuiService = game:GetService("CoreGui")

local RobloxGui = CoreGuiService:WaitForChild("RobloxGui")
local LocalPlayer = PlayersService.LocalPlayer
while LocalPlayer == nil do
	PlayersService.ChildAdded:wait()
	LocalPlayer = PlayersService.LocalPlayer
end

local CoreGuiModules = RobloxGui:WaitForChild("Modules")
local PromptCreator = require(CoreGuiModules:WaitForChild("PromptCreator"))
local PlayerDropDownModule = require(CoreGuiModules:WaitForChild("PlayerDropDown"))

local readFlagSuccess, flagEnabled = pcall(function() return settings():GetFFlag("CorescriptPromptFriendEnabled") end)
local AllowPromptFriendPlayer = readFlagSuccess and flagEnabled

local THUMBNAIL_URL = "https://www.roblox.com/Thumbs/Avatar.ashx?x=200&y=200&userId="
local BUST_THUMBNAIL_URL = "https://www.roblox.com/bust-thumbnail/image?width=420&height=420&userId="

function SendFriendRequest(playerToFriend)

end

function AtFriendLimit()
	local friendCount = PlayerDropDownModule:GetFriendCountAsync(LocalPlayer)
	if friendCount >= PlayerDropDownModule:MaxFriendCount() then
		return true
	end
	return false
end

function DoPromptRequestFriendPlayer(playerToFriend)
	if LocalPlayer:IsFriendsWith(playerToFriend) then
		return
	end
	local function promptCompletedCallback(clickedConfirm)
		if clickedConfirm then
			local successfullySentFriendRequest = BlockingUtility:BlockPlayerAsync(playerToBlock)
			if not successfullyBlocked then
				while PromptCreator:IsCurrentlyPrompting() do
					wait()
				end
				PromptCreator:CreatePrompt({
					WindowTitle = "Error Blocking Player",
					MainText = string.format("An error occured while blocking %s. Please try again later.", playerToBlock.Name),
					ConfirmationText = "Okay",
					CancelActive = false,
				})
			end
		end
		return nil
	end
	PromptCreator:CreatePrompt({
		WindowTitle = "Send Friend Request?",
		MainText = string.format("Would you like to send %s a Friend Request?", playerToFriend.Name),
		ConfirmationText = "Send Request",
		CancelText = "Cancel",
		CancelActive = true,
		Image = BUST_THUMBNAIL_URL ..playerToFriend.UserId,
		ImageConsoleVR = THUMBNAIL_URL ..playerToFriend.UserId,
		PromptCompletedCallback = promptCompletedCallback,
	})
end

function PromptRequestFriendPlayer(player)
	if LocalPlayer.UserId < 0 then
		error("PromptSendFriendRequest can not be called for guests!")
	end
	if typeof(player) == "Instance" and player:IsA("Player") then
		if player.UserId < 0 then
			error("PromptSendFriendRequest can not be called on guests!")
		end
		if player == LocalPlayer then
			error("PromptSendFriendRequest: A user can not friend themselves!")
		end
		DoPromptRequestFriendPlayer(player)
	else
		error("Invalid argument to PromptSendFriendRequest")
	end
end

if AllowPromptBlockPlayer then
	StarterGui:RegisterSetCore("PromptSendFriendRequest", PromptRequestFriendPlayer)
	StarterGui:RegisterSetCore("PromptUnfriend", PromptUnfriendPlayer)
else
	StarterGui:RegisterSetCore("PromptSendFriendRequest", function()
		error("PromptSendFriendRequest is not yet enabled!")
	end)
	StarterGui:RegisterSetCore("PromptUnfriend", function()
		error("PromptUnfriend is not yet enabled!")
	end)
end
