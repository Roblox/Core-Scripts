local source = [[
local module = {}
--////////////////////////////// Include
--//////////////////////////////////////
local modulesFolder = script.Parent

--////////////////////////////// Details
--//////////////////////////////////////
local metatable = {}
metatable.__ClassName = "SpeakerDatabase"

metatable.__tostring = function(tbl)
	return tbl.__ClassName .. ": " .. tbl.MemoryLocation
end

metatable.__metatable = "The metatable is locked"
metatable.__index = function(tbl, index, value)
	if rawget(tbl, index) then return rawget(tbl, index) end
	if rawget(metatable, index) then return rawget(metatable, index) end
	error(index .. " is not a valid member of " .. tbl.__ClassName)
end
metatable.__newindex = function(tbl, index, value)
	error(index .. " is not a valid member of " .. tbl.__ClassName)
end


--////////////////////////////// Methods
--//////////////////////////////////////
function metatable:Dump()
	return tostring(self)
end

function metatable:AddSpeaker(speakerName)
	if (self:GetSpeaker(speakerName))  then
		error("Channel '" .. speakerName .. "' already exists!")
	end
	
	local speaker = {Name = speakerName}
	self.Speakers[speakerName:lower()] = speaker
	return speaker
end

function metatable:RemoveSpeaker(speakerName)
	if (not self:GetSpeaker(speakerName))  then
		error("Channel '" .. speakerName .. "' does not exist!")
	end
	
	self.Speakers[speakerName:lower()] = nil
end

function metatable:GetSpeaker(speakerName)
	return self.Speakers[speakerName:lower()]
end

--///////////////////////// Constructors
--//////////////////////////////////////
function module.new()
	local obj = {}
	obj.MemoryLocation = tostring(obj):match("[0123456789ABCDEF]+")
	
	obj.Speakers = {}
	
	obj = setmetatable(obj, metatable)
	
	return obj
end

return module
]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script