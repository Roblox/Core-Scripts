local MESSAGE_TYPE = "UnknownMessage"

local clientChatModules = script.Parent.Parent
local ChatSettings = require(clientChatModules:WaitForChild("ChatSettings"))
local util = require(script.Parent:WaitForChild("Util"))

function CreateUknownMessageLabel(messageData)
  print("No message creator for message: " ..messageData.Message)
end

return {
	[util.KEY_MESSAGE_TYPE] = MESSAGE_TYPE,
  [util.KEY_CREATOR_FUNCTION] = CreateWelcomeMessageLabel
}
