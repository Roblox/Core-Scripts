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

local THUMBNAIL_URL = "https://www.roblox.com/Thumbs/Avatar.ashx?x=200&y=200&format=png&userId="
local BUST_THUMBNAIL_URL = "https://www.roblox.com/bust-thumbnail/image?width=420&height=420&format=png&userId="

function SendFriendRequest(playerToFriend)
	local success = pcall(function()
		LocalPlayer:RequestFriendship(playerToFriend)
	end)
	return success
end

function AtFriendLimit(player)
	local friendCount = PlayerDropDownModule:GetFriendCountAsync(player)
	if friendCount == nil then
		return false
	end
	if friendCount >= PlayerDropDownModule:MaxFriendCount() then
		return true
	end
	return false
end

function DoPromptRequestFriendPlayer(playerToFriend)
	if LocalPlayer:IsFriendsWith(playerToFriend.UserId) then
		return
	end
	local function promptCompletedCallback(clickedConfirm)
		if clickedConfirm then
			if AtFriendLimit(LocalPlayer) then
				while PromptCreator:IsCurrentlyPrompting() do
					wait()
				end
				PromptCreator:CreatePrompt({
					WindowTitle = "Friend Limit Reached",
					MainText = "You can not send a friend request because you are at the max friend limit.",
					ConfirmationText = "Okay",
					CancelActive = false,
					Image = BUST_THUMBNAIL_URL ..playerToFriend.UserId,
					ImageConsoleVR = THUMBNAIL_URL ..playerToFriend.UserId,
					StripeColor = Color3.fromRGB(183, 34, 54),
				})
			else
				if AtFriendLimit(playerToFriend) then
					PromptCreator:CreatePrompt({
						WindowTitle = "Error Sending Friend Request",
						MainText = string.format("You can not send a friend request to %s because they are at the max friend limit.",  playerToFriend.Name),
						ConfirmationText = "Okay",
						CancelActive = false,
						Image = BUST_THUMBNAIL_URL ..playerToFriend.UserId,
						ImageConsoleVR = THUMBNAIL_URL ..playerToFriend.UserId,
						StripeColor = Color3.fromRGB(183, 34, 54),
					})
				else
					local successfullySentFriendRequest = SendFriendRequest(playerToFriend)
					if not successfullySentFriendRequest then
						while PromptCreator:IsCurrentlyPrompting() do
							wait()
						end
						PromptCreator:CreatePrompt({
							WindowTitle = "Error Sending Friend Request",
							MainText = string.format("An error occurred while sending %s a friend request. Please try again later.", playerToFriend.Name),
							ConfirmationText = "Okay",
							CancelActive = false,
							Image = BUST_THUMBNAIL_URL ..playerToFriend.UserId,
							ImageConsoleVR = THUMBNAIL_URL ..playerToFriend.UserId,
							StripeColor = Color3.fromRGB(183, 34, 54),
						})
					end
				end
			end
		end
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

function UnFriendPlayer(playerToUnfriend)
	local success = pcall(function()
		LocalPlayer:RevokeFriendship(playerToUnfriend)
	end)
	return success
end

function DoPromptUnfriendPlayer(playerToUnfriend)
	if not LocalPlayer:IsFriendsWith(playerToUnfriend.UserId) then
		return
	end
	local function promptCompletedCallback(clickedConfirm)
		if clickedConfirm then
			local successfullyUnfriended = UnFriendPlayer(playerToUnfriend)
			if not successfullyUnfriended then
				while PromptCreator:IsCurrentlyPrompting() do
					wait()
				end
				PromptCreator:CreatePrompt({
					WindowTitle = "Error Unfriending Player",
					MainText = string.format("An error occurred while unfriending %s. Please try again later.", playerToUnfriend.Name),
					ConfirmationText = "Okay",
					CancelActive = false,
					Image = BUST_THUMBNAIL_URL ..playerToUnfriend.UserId,
					ImageConsoleVR = THUMBNAIL_URL ..playerToUnfriend.UserId,
					StripeColor = Color3.fromRGB(183, 34, 54),
				})
			end
		end
	end
	PromptCreator:CreatePrompt({
		WindowTitle = "Unfriend Player?",
		MainText = string.format("Would you like to remove %s from your friends list?", playerToUnfriend.Name),
		ConfirmationText = "Unfriend",
		CancelText = "Cancel",
		CancelActive = true,
		Image = BUST_THUMBNAIL_URL ..playerToUnfriend.UserId,
		ImageConsoleVR = THUMBNAIL_URL ..playerToUnfriend.UserId,
		PromptCompletedCallback = promptCompletedCallback,
	})
end

function PromptUnfriendPlayer(player)
	if LocalPlayer.UserId < 0 then
		error("PromptUnfriend can not be called for guests!")
	end
	if typeof(player) == "Instance" and player:IsA("Player") then
		if player.UserId < 0 then
			error("PromptUnfriend can not be called on guests!")
		end
		if player == LocalPlayer then
			error("PromptUnfriend: A user can not unfriend themselves!")
		end
		DoPromptUnfriendPlayer(player)
	else
		error("Invalid argument to PromptUnfriend")
	end
end

StarterGui:RegisterSetCore("PromptSendFriendRequest", PromptRequestFriendPlayer)
StarterGui:RegisterSetCore("PromptUnfriend", PromptUnfriendPlayer)
