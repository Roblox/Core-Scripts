--	// FileName: Util.lua
--	// Written by: TheGamer101
--	// Description: Module for shared code between CommandModules.

--[[
Creating a command module:
1) Create a new module inside the CommandModules folder.
2) Create a function that takes a message, the ChatWindow object and the ChatSettings and returns
a bool command processed.
3) Return this function from the module.
--]]

local COMMAND_MODULES_VERSION = 1

local module = {}
local methods = {}
methods.__index = methods

function methods:RegisterGuiRoot(root)
	testLabel.Parent = root
end

function methods:SendSystemMessageToSelf(message, channelObj, extraData)
	local messageData =
	{
		ID = -1,
		FromSpeaker = nil,
		OriginalChannel = channelName,
		IsFiltered = false,
		Message = message,
		Time = os.time(),
		ExtraData = extraData,
	}

	channelObj:AddMessageToChannel(messageData, "SystemMessage")
end

function module.new()
	local obj = setmetatable({}, methods)

	obj.COMMAND_MODULES_VERSION = COMMAND_MODULES_VERSION

	return obj
end

return module.new()
