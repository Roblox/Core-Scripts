local MESSAGE_TYPE = "MeCommandMessage"

local clientChatModules = script.Parent.Parent
local ChatSettings = require(clientChatModules:WaitForChild("ChatSettings"))
local util = require(script.Parent:WaitForChild("Util"))

function CreateMeCommandMessageLabel(messageData)
  local message = messageData.Message
	local extraData = messageData.ExtraData or {}
	local useFont = extraData.Font or Enum.Font.SourceSansBold
	local useFontSize = extraData.FontSize or ChatSettings.ChatWindowTextSize
  local useChatColor = extraData.ChatColor or Color3.new(1, 1, 1)

	local tempMessage = messageData.FromSpeaker .. " " .. string.sub(message, 5)

	if not messageData.IsFiltered then
		local numNeededUnderscore = util:GetNumberOfUnderscores(tempMessage, useFont, useFontSize)
		tempMessage = string.rep("_", numNeededUnderscore)
	end

	local BaseFrame, BaseMessage = util:CreateBaseMessage(tempMessage, useFont, useFontSize, useChatColor)

	local function UpdateTextFunction(newMessageObject)
		BaseMessage.Text = newMessageObject.FromSpeaker .. " " .. string.sub(newMessageObject.Message, 5)
	end

	return BaseFrame, BaseMessage, UpdateTextFunction
end

return {
	MessageType = MESSAGE_TYPE,
	CreateMessageFunc = CreateMeCommandMessageLabel
}
