local source = [[
--	// FileName: SpeakerDatabase.lua
--	// Written by: Xsitsu
--	// Description: Module for storing ExtraData set on different Speakers.

local module = {}
--////////////////////////////// Include
--//////////////////////////////////////
local modulesFolder = script.Parent
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

function methods:AddSpeaker(speakerName)
	if (self:GetSpeaker(speakerName))  then
		error("Speaker '" .. speakerName .. "' already exists!")
	end
	
	local speaker = {Name = speakerName}
	self.Speakers[speakerName:lower()] = speaker
	return speaker
end

function methods:RemoveSpeaker(speakerName)
	if (not self:GetSpeaker(speakerName))  then
		error("Speaker '" .. speakerName .. "' does not exist!")
	end
	
	self.Speakers[speakerName:lower()] = nil
end

function methods:GetSpeaker(speakerName)
	return self.Speakers[speakerName:lower()]
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("SpeakerDatabase", methods)

function module.new()
	local obj = {}
	
	obj.Speakers = {}
	
	ClassMaker.MakeClass("SpeakerDatabase", obj)
	
	return obj
end

return module
]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script