--	// FileName: MeCommandMessage.lua
--	// Written by: TheGamer101
--	// Description: Create a message label for a me command message.

local MESSAGE_TYPE = "MeCommandMessage"

local clientChatModules = script.Parent.Parent
local ChatSettings = require(clientChatModules:WaitForChild("ChatSettings"))
local util = require(script.Parent:WaitForChild("Util"))

function CreateMeCommandMessageLabel(messageData)
  local message = messageData.Message
	local extraData = messageData.ExtraData or {}
	local useFont = extraData.Font or Enum.Font.SourceSansBold
	local useFontSize = extraData.FontSize or ChatSettings.ChatWindowTextSize
  local useChatColor = Color3.new(1, 1, 1)

	local tempMessage = messageData.FromSpeaker .. " " .. string.sub(message, 5)

	if not messageData.IsFiltered then
		local numNeededUnderscore = util:GetNumberOfUnderscores(tempMessage, useFont, useFontSize)
		tempMessage = string.rep("_", numNeededUnderscore)
	end

	local BaseFrame, BaseMessage = util:CreateBaseMessage(tempMessage, useFont, useFontSize, useChatColor)

	local function UpdateTextFunction(newMessageObject)
		BaseMessage.Text = newMessageObject.FromSpeaker .. " " .. string.sub(newMessageObject.Message, 5)
	end

  return {
    [util.KEY_BASE_FRAME] = BaseFrame,
    [util.KEY_BASE_MESSAGE] = BaseMessage,
    [util.KEY_UPDATE_TEXT_FUNC] = UpdateTextFunction
  }
end

return {
  [util.KEY_MESSAGE_TYPE] = MESSAGE_TYPE,
  [util.KEY_CREATOR_FUNCTION] = CreateMeCommandMessageLabel
}
