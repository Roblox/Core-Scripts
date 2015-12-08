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

--[[ Fast Flags ]]--
local serverFollowersSuccess, serverFollowersEnabled = pcall(function() return settings():GetFFlag("UserServerFollowers") end)
local IsServerFollowers = serverFollowersSuccess and serverFollowersEnabled

local RemoteEvent_NewFollower = nil

--[[ Add Server CoreScript ]]--
-- TODO: FFlag check
if IsServerFollowers then
	ScriptContext:AddCoreScriptLocal("ServerCoreScripts/ServerSocialScript", script.Parent)
else
	-- above script will create this now
	RemoteEvent_NewFollower = Instance.new('RemoteEvent')
	RemoteEvent_NewFollower.Name = "NewFollower"
	RemoteEvent_NewFollower.Parent = RobloxReplicatedStorage
end

--[[ Remote Events ]]--
local RemoteEvent_SetDialogInUse = Instance.new("RemoteEvent")
RemoteEvent_SetDialogInUse.Name = "SetDialogInUse"
RemoteEvent_SetDialogInUse.Parent = RobloxReplicatedStorage 

--[[ Event Connections ]]--
-- Params:
	-- followerRbxPlayer: player object of the new follower, this is the client who wants to follow another
	-- followedRbxPlayer: player object of the person being followed
local function onNewFollower(followerRbxPlayer, followedRbxPlayer)
	RemoteEvent_NewFollower:FireClient(followedRbxPlayer, followerRbxPlayer)
end
if RemoteEvent_NewFollower then
	RemoteEvent_NewFollower.OnServerEvent:connect(onNewFollower)
end

local function setDialogInUse(player, dialog, value)
	if dialog ~= nil then
		dialog.InUse = value
	end
end
RemoteEvent_SetDialogInUse.OnServerEvent:connect(setDialogInUse)
