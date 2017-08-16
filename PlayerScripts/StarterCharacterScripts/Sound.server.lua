--[[
	Filename: Sound.lua
	Author: boynedmaster/Kampfkarren
	Description: Used for backwards compatibility with old character sound system.
]]

local SoundService = game:GetService("SoundService")
local SoundUtil = require(script.SoundUtil) --SoundUtil is in LocalSound because it wouldn't replicate to the client otherwise

if not SoundUtil.UseNewSystem() then
	--Because the user is not using the new sound system, it needs to be backwards compatible.
	local head = script.Parent:FindFirstChild("Head")

	if head == nil then
		error("Sound script parent has no child Head.")
		return
	end
	
	SoundUtil.CreateSounds(head)
end