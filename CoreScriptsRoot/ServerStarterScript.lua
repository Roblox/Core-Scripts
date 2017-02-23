--[[
		// Filename: ServerStarterScript.lua
		// Version: 1.0
		// Description: Server core script that handles core script server side logic.
]]--

-- Prevent server script from running in Studio when not in run mode
local runService = nil
while runService == nil or not runService:IsRunning() do
	wait(0.1)
	runService = game:GetService('RunService')
end

--[[ Services ]]--
local RobloxReplicatedStorage = game:GetService('RobloxReplicatedStorage')
local ScriptContext = game:GetService('ScriptContext')

--[[ Add Server CoreScript ]]--
ScriptContext:AddCoreScriptLocal("ServerCoreScripts/ServerSocialScript", script.Parent)

--[[ Remote Events ]]--
local RemoteEvent_SetDialogInUse = Instance.new("RemoteEvent")
RemoteEvent_SetDialogInUse.Name = "SetDialogInUse"
RemoteEvent_SetDialogInUse.Parent = RobloxReplicatedStorage

--[[ Event Connections ]]--
local playerDialogMap = {}

local dialogInUseFixFlagSuccess, dialogInUseFixValue = pcall(function() return settings():GetFFlag("DialogInUseFix") end)
local dialogInUseFixFlag = (dialogInUseFixFlagSuccess and dialogInUseFixValue)

local function setDialogInUse(player, dialog, value, waitTime)
	if typeof(dialog) ~= "Instance" or not dialog:IsA("Dialog") then
		return
	end
	if type(value) ~= "boolean" then
		return
	end
	if type(waitTime) ~= "number" and type(waitTime) ~= "nil" then
		return
	end

	if waitTime and waitTime ~= 0 then
		wait(waitTime)
	end
	if dialog ~= nil then
		dialog.InUse = value

		if dialogInUseFixFlag then
			if value == true then
				playerDialogMap[player] = dialog
			else
				playerDialogMap[player] = nil
			end
		end
	end
end
RemoteEvent_SetDialogInUse.OnServerEvent:connect(setDialogInUse)

game:GetService("Players").PlayerRemoving:connect(function(player)
	if dialogInUseFixFlag then
		if player then
			local dialog = playerDialogMap[player]
			if dialog then
				dialog.InUse = false
				playerDialogMap[player] = nil
			end
		end
	end
end)

local success, retVal = pcall(function() return game:GetService("Chat"):GetShouldUseLuaChat() end)
local useNewChat = success and retVal
local FORCE_UseNewChat = require(game:GetService("CoreGui").RobloxGui.Modules.Common.ForceUseNewChat)
if (useNewChat or FORCE_UseNewChat) then
	require(game:GetService("CoreGui").RobloxGui.Modules.Server.ClientChat.ChatWindowInstaller)()
	require(game:GetService("CoreGui").RobloxGui.Modules.Server.ServerChat.ChatServiceInstaller)()
end
