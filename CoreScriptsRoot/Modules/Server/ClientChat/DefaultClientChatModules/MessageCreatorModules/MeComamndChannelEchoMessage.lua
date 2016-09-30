local MESSAGE_TYPE = "MeCommandChannelEchoMessage"

local clientChatModules = script.Parent.Parent
local ChatSettings = require(clientChatModules:WaitForChild("ChatSettings"))
local util = require(script.Parent:WaitForChild("Util"))

function CreateMeCommandChannelEchoMessageLabel(messageData)
  local message = messageData.Message
  local echoChannel = messageData.OriginalChannel
	local extraData = messageData.ExtraData or {}
	local useFont = extraData.Font or Enum.Font.SourceSansBold
	local useFontSize = extraData.FontSize or ChatSettings.ChatWindowTextSize
  local useChatColor = extraData.ChatColor or Color3.new(1, 1, 1)

  local tempMessage = messageData.FromSpeaker .. " " .. string.sub(message, 5)
	if not messageData.IsFiltered then
		local numNeededUnderscore = util:GetNumberOfUnderscores(tempMessage, useFont, useFontSize)
		tempMessage = string.rep("_", numNeededUnderscore)
	end

  local formatChannelName = string.format("{%s}", echoChannel)
  local numNeededSpaces2 = util:GetNumberOfSpaces(formatChannelName, useFont, useFontSize) + 1
  local modifiedMessage = string.rep(" ", numNeededSpaces2) .. message

  local BaseFrame, BaseMessage = util:CreateBaseMessage(modifiedMessage, useFont, useFontSize, useChatColor)
  local ChannelButton = util:AddChannelButtonToBaseMessage(BaseMessage, formatChannelName, BaseMessage.TextColor3)

	local function UpdateTextFunction(newMessageObject)
		BaseMessage.Text = string.rep(" ", numNeededSpaces2) .. newMessageObject.FromSpeaker .. " " .. string.sub(newMessageObject.Message, 5)
	end

	return BaseFrame, BaseMessage, UpdateTextFunction
end

return {
	MessageType = MESSAGE_TYPE,
	CreateMessageFunc = CreateMeCommandChannelEchoMessageLabel
}
