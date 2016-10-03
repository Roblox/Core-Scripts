--	// FileName: SetCoreMessage.lua
--	// Written by: TheGamer101
--	// Description: Create a message label for a message created with SetCore(ChatMakeSystemMessage).

local MESSAGE_TYPE = "SetCoreMessage"

local clientChatModules = script.Parent.Parent
local ChatSettings = require(clientChatModules:WaitForChild("ChatSettings"))
local util = require(script.Parent:WaitForChild("Util"))

function CreateSetCoreMessageLabel(messageData)
	local message = messageData.Message
  local extraData = messageData.ExtraData or {}
	local useFont = extraData.Font or Enum.Font.SourceSansBold
	local useFontSize = extraData.FontSize or ChatSettings.ChatWindowTextSize
	local useColor = extraData.Color or Color3.new(1, 1, 1)

	local BaseFrame, BaseMessage = util:CreateBaseMessage(message, useFont, useFontSize, useColor)

	return {
		[util.KEY_BASE_FRAME] = BaseFrame,
		[util.KEY_BASE_MESSAGE] = BaseMessage,
		[util.KEY_UPDATE_TEXT_FUNC] = nil
	}
end

return {
	[util.KEY_MESSAGE_TYPE] = MESSAGE_TYPE,
	[util.KEY_CREATOR_FUNCTION] = CreateSetCoreMessageLabel
}
