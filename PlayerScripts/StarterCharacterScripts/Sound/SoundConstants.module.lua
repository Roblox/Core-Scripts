--[[
	Filename: SoundConstants.module.lua
	Author: boynedmaster/Kampfkarren
	Description: Declares constants for sounds played by characters.
]]

local SoundConstants = {}

SoundConstants.MIN_DISTANCE = 5
SoundConstants.MAX_DISTANCE = 150
SoundConstants.VOLUME = 0.65

--Data on every specific sound, formatted in {Name, SoundID, Looped, PlaybackSpeed}
SoundConstants.SOUND_DATA = {
	{"GettingUp",  "rbxasset://sounds/action_get_up.mp3", false, 1},
	{"Died",  "rbxasset://sounds/uuhhh.mp3", false, 1},
	{"FreeFalling",  "rbxasset://sounds/action_falling.mp3", true, 1},
	{"Jumping",  "rbxasset://sounds/action_jump.mp3", false, 1},
	{"Landing",  "rbxasset://sounds/action_jump_land.mp3", false, 1},
	{"Splash",  "rbxasset://sounds/impact_water.mp3", false, 1},
	{"Running",  "rbxasset://sounds/action_footsteps_plastic.mp3", true, 1.85},
	{"Swimming",  "rbxasset://sounds/action_swim.mp3", true, 1.6},
	{"Climbing",  "rbxasset://sounds/action_footsteps_plastic.mp3", true, 1},
}

return SoundConstants