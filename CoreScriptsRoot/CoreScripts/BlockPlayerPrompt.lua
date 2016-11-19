--[[
	// Filename: BlockPlayerPrompt.lua
	// Version 1.0
	// Written by: TheGamer101
	// Description: Handles prompting the blocking and unblocking of Players.
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
local BlockingUtility = PlayerDropDownModule:CreateBlockingUtility()

-- Check flag here in future.
local AllowPromptBlockPlayer = true

function DoPromptBlockPlayer(playerToBlock)
	if BlockingUtility:IsPlayerBlockedByUserId(playerToBlock.UserId) then
		return
	end
	local function promptCompletedCallback(clickedConfirm)
		if clickedConfirm then
			local successfullyBlocked = BlockingUtility:BlockPlayerAsync(playerToBlock)
			if successfullyBlocked then
				return {
					WindowTitle = "Successfully Blocked",
					MainText = string.format("%s has been blocked.", playerToBlock.Name),
					AdditonalText = nil,
					ConfirmationText = "Okay",
					Image = "https://www.roblox.com/Thumbs/Avatar.ashx?x=200&y=200&userId=" ..playerToBlock.UserId,
				}
			else
				return {
					WindowTitle = "Error Blocking Player",
					MainText = string.format("An error occured while blocking %s.", playerToBlock.Name),
					AdditonalText = "Please try again later",
					ConfirmationText = "Okay",
				}
			end
		end
		return nil
	end
	PromptCreator:CreatePrompt({
		WindowTitle = "Confirm Block",
		MainText = string.format("Are you sure you want to block %s?", playerToBlock.Name),
		ConfirmationText = "Block",
		CancelText = "Cancel",
		CancelActive = true,
		AdditonalText = nil,
		Image = "https://www.roblox.com/Thumbs/Avatar.ashx?x=200&y=200&userId=" ..playerToBlock.UserId,
		CallbackWaitingText = "Blocking...",
		PromptCompletedCallback = promptCompletedCallback,
	})
end

function PromptBlockPlayer(player)
	-- TESTING, DO NOT SUBMIT
	if true then
		DoPromptBlockPlayer(player)
		return
	end

	if LocalPlayer.UserId < 0 then
		error("PromptBlockPlayer can not be called for guests!")
	end
	if typeof(player) == "Instance" and player:IsA("Player") then
		if player.UserId < 0 then
			error("PromptBlockPlayer can not be called on guests!")
		end
		if player == LocalPlayer then
			error("PromptBlockPlayer: A user can not block themselves!")
		end
		DoPromptBlockPlayer(player)
	else
		error("Invalid argument to PromptBlockPlayer")
	end
end

function DoPromptUnblockPlayer(playerToUnblock)
	if not BlockingUtility:IsPlayerBlockedByUserId(playerToUnblock.UserId) and false then
		return
	end
	local function promptCompletedCallback(clickedConfirm)
		if clickedConfirm then
			wait(5)
			local successfullyUnblocked = BlockingUtility:UnblockPlayerAsync(playerToUnblock)
			if successfullyUnblocked then
				return {
					WindowTitle = "Successfully Unblocked",
					MainText = string.format("%s has been unblocked.", playerToUnblock.Name),
					AdditonalText = nil,
					ConfirmationText = "Okay",
					Image = "https://www.roblox.com/Thumbs/Avatar.ashx?x=200&y=200&userId=" ..playerToUnblock.UserId,
				}
			else
				return {
					WindowTitle = "Error Unblocking Player",
					MainText = string.format("An error occured while unblocking %s.", playerToUnblock.Name),
					AdditonalText = "Please try again later",
					ConfirmationText = "Okay",
					Image = "https://www.roblox.com/Thumbs/Avatar.ashx?x=200&y=200&userId=" ..playerToUnblock.UserId,
				}
			end
		end
		return nil
	end
	PromptCreator:CreatePrompt({
		WindowTitle = "Confirm Unblock",
		MainText = string.format("Would you like to unblock %s?", playerToUnblock.Name),
		ConfirmationText = "Unblock",
		CancelText = "Cancel",
		CancelActive = true,
		AdditonalText = nil,
		Image = "https://www.roblox.com/Thumbs/Avatar.ashx?x=200&y=200&userId=" ..playerToUnblock.UserId,
		CallbackWaitingText = "Unblocking...",
		PromptCompletedCallback = promptCompletedCallback,
	})
end

function PromptUnblockPlayer(player)
	-- TESTING, DO NOT SUBMIT
	if true then
		DoPromptUnblockPlayer(player)
		return
	end

	if LocalPlayer.UserId < 0 then
		error("PromptUnblockPlayer can not be called for guests!")
	end
	if typeof(player) == "Instance" and player:IsA("Player") then
		if player.UserId < 0 then
			error("PromptUnblockPlayer can not be called on guests!")
		end
		if player == LocalPlayer then
			error("PromptUnblockPlayer: A user can not block themselves!")
		end
		DoPromptUnblockPlayer(player)
	else
		error("Invalid argument to PromptUnblockPlayer")
	end
end

function GetBlockedUserIds()
	if LocalPlayer.UserId < 0 then
		error("GetBlockedUserIds can not be called for guests!")
	end
	return BlockingUtility:GetBlockedUserIdsAsync()
end

if AllowPromptBlockPlayer then
	StarterGui:RegisterSetCore("PromptBlockPlayer", PromptBlockPlayer)
	StarterGui:RegisterSetCore("PromptUnblockPlayer", PromptUnblockPlayer)
	StarterGui:RegisterGetCore("GetBlockedUserIds", GetBlockedUserIds)
else
	StarterGui:RegisterSetCore("PromptBlockPlayer", function()
		error("PromptBlockPlayer is not yet enabled!")
	end)
	StarterGui:RegisterSetCore("PromptUnblockPlayer", function()
		error("PromptUnblockPlayer is not yet enabled!")
	end)
	StarterGui:RegisterGetCore("GetBlockedUserIds", function()
		error("GetBlockedUserIds is not yet enabled!")
	end)
end
