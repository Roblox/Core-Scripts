local source = [[
local function CreateSpeakerDataObject(speakerName)
	local obj = {}
	obj.Name = speakerName
	
	return obj	
end


local module = {}

function module.new()
	local obj = {}
	obj.Speakers = {}

	function obj:AddSpeaker(speakerName)
		local speakerObj = CreateSpeakerDataObject(speakerName)
		self.Speakers[speakerName:lower()] = speakerObj
		return speakerObj
	end

	function obj:RemoveSpeaker(speakerName)
		self.Speakers[speakerName:lower()] = nil
	end

	function obj:GetSpeaker(speakerName)
		return self.Speakers[speakerName:lower()]
	end

	return obj
end


return module.new()
]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script