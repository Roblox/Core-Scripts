local MESSAGE_TYPE = "Message"

local clientChatModules = script.Parent.Parent
local ChatSettings = require(clientChatModules:WaitForChild("ChatSettings"))
local util = require(script.Parent:WaitForChild("Util"))

function CreateMessageLabel(messageData)

	local fromSpeaker = messageData.FromSpeaker
	local message = messageData.Message

	local extraData = messageData.ExtraData or {}
	local useFont = extraData.Font or Enum.Font.SourceSansBold
	local useFontSize = extraData.FontSize or ChatSettings.ChatWindowTextSize
	local useNameColor = extraData.NameColor or Color3.new(1, 1, 1)
	local useChatColor = extraData.ChatColor or Color3.new(1, 1, 1)

	local formatUseName = string.format("[%s]:", fromSpeaker)
	local speakerNameSize = util:GetStringTextBounds(formatUseName, useFont, useFontSize)
	local numNeededSpaces = util:GetNumberOfSpaces(formatUseName, useFont, useFontSize) + 1
	local numNeededUnderscore = util:GetNumberOfUnderscores(message, useFont, useFontSize)

	local tempMessage = string.rep(" ", numNeededSpaces) .. string.rep("_", numNeededUnderscore)
	if messageData.IsFiltered then
		tempMessage = string.rep(" ", numNeededSpaces) .. messageData.Message
	end
	local BaseFrame, BaseMessage = util:CreateBaseMessage(tempMessage, useFont, useFontSize, useChatColor)
	local NameButton = util:AddNameButtonToBaseMessage(BaseMessage, useNameColor, formatUseName)

	local function UpdateTextFunction(newMessageObject)
		BaseMessage.Text = string.rep(" ", numNeededSpaces) .. newMessageObject.Message
	end

  return BaseFrame, BaseMessage, UpdateTextFunction
end

return {
	[util.KEY_MESSAGE_TYPE] = MESSAGE_TYPE,
	[util.KEY_CREATOR_FUNCTION] = CreateMessageLabel
}
