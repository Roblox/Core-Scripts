--	// FileName: ChatConstants.lua
--	// Written by: TheGamer101
--	// Description: Module for creating chat constants shared between server and client.

local module = {}

---[[ Message Types ]]
module.MessageTypeDefault = "Message"
module.MessageTypeSystem = "System"
module.MessageTypeMeCommand = "MeCommand"
module.MessageTypeWelcome = "Welcome"
module.MessageTypeSetCore = "SetCore"
module.MessageTypeWhisper = "Whisper"

module.MajorVersion = 0
module.MinorVersion = 2

return module
