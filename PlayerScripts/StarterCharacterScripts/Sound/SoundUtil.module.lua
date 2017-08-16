--[[
	Filename: SoundUtil.module.lua
	Author: boynedmaster/Kampfkarren
	Description: Used by the character sound system.
]]

local SoundService = game:GetService("SoundService")
local SoundConstants = require(script.Parent.SoundConstants)

local SoundUtil = {}

local function createNewSound(parent, name, id, looped, playbackSpeed)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Name = name
	sound.Archivable = false
	sound.PlaybackSpeed = playbackSpeed
	sound.Looped = looped
	sound.MinDistance = SoundConstants.MIN_DISTANCE
	sound.MaxDistance = SoundConstants.MAX_DISTANCE
	sound.Volume = SoundConstants.VOLUME
	sound.Parent = parent
	
	return sound
end

SoundUtil.UseNewSystem = function()
	return SoundService:FindFirstChild("UseNewSoundSystem") and workspace.FilteringEnabled --TODO: This should be replaced by a property. FilteringEnabled is checked because the security serves no purpose with it off.
end

SoundUtil.CreateNewSound = createNewSound

SoundUtil.CreateSounds = function(head)
	for _,SoundData in pairs(SoundConstants.SOUND_DATA) do
		createNewSound(head, unpack(SoundData))
	end
end

--All of the below was written by @spotco.

--Define linear relationship between (pt1x,pt2x) and (pt2x,pt2y). Evaluate this at x.
SoundUtil.YForLineGivenXAndTwoPts = function(x, pt1x, pt1y, pt2x, pt2y)
	local m = (pt1y - pt2y) / (pt1x - pt2x)
	local b = (pt1y - m * pt1x)
	return m * x + b
end

--Clamps the value of "val" between the "min" and "max".
--Note that this is used instead of math.clamp as math.clamp errors is min is greater than max.
SoundUtil.Clamp = function(val, min, max)
	return math.min(max, math.max(min, val))
end

--Gets the horizontal (x,z) velocity magnitude of the given part.
SoundUtil.HorizontalSpeed = function(Head)
	local hVel = Head.Velocity + Vector3.new(0, -Head.Velocity.Y, 0)
	return hVel.magnitude
end

--Gets the vertical (y) velocity magnitude of the given part.
SoundUtil.VerticalSpeed = function(Head)
	return math.abs(Head.Velocity.Y)
end

--The following are sound control functions with backwards compatibility with the old sound system.
SoundUtil.Play = function(sound)
	if sound.TimePosition ~= 0 then
		sound.TimePosition = 0
	end

	if not sound.IsPlaying then
		sound.Playing = true
	end
end

SoundUtil.Pause = function(sound)
	if sound.IsPlaying then
		sound.Playing = false
	end
end

SoundUtil.Resume = function(sound)
	if not sound.IsPlaying then
		sound.Playing = true
	end
end

SoundUtil.Stop = function(sound)
	if sound.IsPlaying then
		sound.Playing = false
	end

	if sound.TimePosition ~= 0 then
		sound.TimePosition = 0
	end
end

return SoundUtil
