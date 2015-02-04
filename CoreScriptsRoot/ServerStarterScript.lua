-- Prevent server script from running in Studio when not in run mode
local runService = nil
while runService == nil or not runService:IsRunning() do
	wait(0.1)
	runService = game:GetService('RunService')
end
	
local rrs = game:GetService('RobloxReplicatedStorage')

local event = Instance.new("RemoteEvent", rrs)
event.Name = "ServerEvent"



