local source = [[
--	// FileName: ExtraDataInitializer.lua
--	// Written by: Xsitsu
--	// Description: Module that sets some basic ExtraData such as name color, and chat color.

local function MakeIsInGroup(groupId, requiredRank)
	assert(type(requiredRank) == "nil" or type(requiredRank) == "number", "requiredRank must be a number or nil")
	
	local inGroupCache = {}
	return function(player)
		if player and player.userId then
			local userId = player.userId

			if inGroupCache[userId] == nil then
				local inGroup = false
				pcall(function() -- Many things can error is the IsInGroup check
					if requiredRank then
						inGroup = player:GetRankInGroup(groupId) > requiredRank
					else
						inGroup = player:IsInGroup(groupId)
					end
				end)
				inGroupCache[userId] = inGroup
			end

			return inGroupCache[userId]
		end

		return false
	end
end

local IsInGroupAdmins = MakeIsInGroup(1200769)
local IsInGroupInterns = MakeIsInGroup(2868472, 100) 

local Players = game:GetService("Players")
local function SpeakerNameIsAdmin(speakerName)
	return IsInGroupAdmins(Players:FindFirstChild(speakerName))
end

local function SpeakerNameIsIntern(speakerName)
	return IsInGroupInterns(Players:FindFirstChild(speakerName))
end

local function Run(ChatService)
	local NAME_COLORS =
	{
		Color3.new(253/255, 41/255, 67/255), -- BrickColor.new("Bright red").Color,
		Color3.new(1/255, 162/255, 255/255), -- BrickColor.new("Bright blue").Color,
		Color3.new(2/255, 184/255, 87/255), -- BrickColor.new("Earth green").Color,
		BrickColor.new("Bright violet").Color,
		BrickColor.new("Bright orange").Color,
		BrickColor.new("Bright yellow").Color,
		BrickColor.new("Light reddish violet").Color,
		BrickColor.new("Brick yellow").Color,
	}
	
	local function GetNameValue(pName)
		local value = 0
		for index = 1, #pName do
			local cValue = string.byte(string.sub(pName, index, index))
			local reverseIndex = #pName - index + 1
			if #pName%2 == 1 then
				reverseIndex = reverseIndex - 1
			end
			if reverseIndex%4 >= 2 then
				cValue = -cValue
			end
			value = value + cValue
		end
		return value
	end
	
	local color_offset = 0
	local function ComputeNameColor(pName)
		return NAME_COLORS[((GetNameValue(pName) + color_offset) % #NAME_COLORS) + 1]
	end
	
	ChatService.SpeakerAdded:connect(function(speakerName)
		local speaker = ChatService:GetSpeaker(speakerName)

		if (not speaker:GetExtraData("NameColor")) then
			speaker:SetExtraData("NameColor", ComputeNameColor(speaker.Name))
		end
		if (not speaker:GetExtraData("ChatColor")) then
			if (SpeakerNameIsAdmin(speakerName)) then
				speaker:SetExtraData("ChatColor", Color3.new(1, 215/255, 0))
			elseif (SpeakerNameIsIntern(speakerName)) then
				speaker:SetExtraData("ChatColor", Color3.new(175/255, 221/255, 1))
			else
				speaker:SetExtraData("ChatColor", Color3.new(255/255, 255/255, 243/255))
			end
		end
		if (not speaker:GetExtraData("Tags")) then
			speaker:SetExtraData("Tags", {})
		end

		
	end)
end

return Run
]]


local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script