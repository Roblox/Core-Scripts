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

--[[ Remote Events ]]--
local RemoteEvent_OnNewFollower = Instance.new('RemoteEvent')
RemoteEvent_OnNewFollower.Name = "OnNewFollower"
RemoteEvent_OnNewFollower.Parent = RobloxReplicatedStorage

local RemoteEvent_SetDialogInUse = Instance.new("RemoteEvent")
RemoteEvent_SetDialogInUse.Name = "SetDialogInUse"
RemoteEvent_SetDialogInUse.Parent = RobloxReplicatedStorage 

--[[ Event Connections ]]--
-- Params:
	-- followerRbxPlayer: player object of the new follower, this is the client who wants to follow another
	-- followedRbxPlayer: player object of the person being followed
local function onNewFollower(followerRbxPlayer, followedRbxPlayer)
	RemoteEvent_OnNewFollower:FireClient(followedRbxPlayer, followerRbxPlayer)
end
RemoteEvent_OnNewFollower.OnServerEvent:connect(onNewFollower)

local function setDialogInUse(player, dialog, value)
	if dialog ~= nil then
		dialog.InUse = value
	end
end
RemoteEvent_SetDialogInUse.OnServerEvent:connect(setDialogInUse)
