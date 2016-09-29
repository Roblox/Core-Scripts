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
local function setDialogInUse(player, dialog, value, waitTime)
	if waitTime and waitTime ~= 0 then
		wait(waitTime)
	end
	if dialog ~= nil then
		dialog.InUse = value
	end
end
RemoteEvent_SetDialogInUse.OnServerEvent:connect(setDialogInUse)

local success, retVal = pcall(function() return game:GetService("Chat"):GetShouldUseLuaChat() end)
local useNewChat = success and retVal
local FORCE_UseNewChat = require(game:GetService("CoreGui").RobloxGui.Modules.Common.ForceUseNewChat)
if (useNewChat or FORCE_UseNewChat) then
	require(game:GetService("CoreGui").RobloxGui.Modules.Server.ClientChat.ChatWindowInstaller)()
	require(game:GetService("CoreGui").RobloxGui.Modules.Server.ServerChat.ChatServiceInstaller)()
end
