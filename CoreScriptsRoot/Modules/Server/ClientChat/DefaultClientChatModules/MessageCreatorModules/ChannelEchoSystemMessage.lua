--	// FileName: ChannelEchoSystemMessage.lua
--	// Written by: TheGamer101
--	// Description: Create a message label for a system message being echoed into another channel.

local MESSAGE_TYPE = "ChannelEchoSystemMessage"

local clientChatModules = script.Parent.Parent
local ChatSettings = require(clientChatModules:WaitForChild("ChatSettings"))
local util = require(script.Parent:WaitForChild("Util"))

function CreateChannelEchoSystemMessageLabel(messageData)
	local message = messageData.Message
	local echoChannel = messageData.OriginalChannel

	local extraData = messageData.ExtraData or {}
	local useFont = extraData.Font or Enum.Font.SourceSansBold
	local useFontSize = extraData.FontSize or ChatSettings.ChatWindowTextSize
	local useChatColor = extraData.ChatColor or Color3.new(1, 1, 1)

	local formatChannelName = string.format("{%s}", echoChannel)
	local numNeededSpaces2 = util:GetNumberOfSpaces(formatChannelName, useFont, useFontSize) + 1
	local modifiedMessage = string.rep(" ", numNeededSpaces2) .. message

	local BaseFrame, BaseMessage = util:CreateBaseMessage(modifiedMessage, useFont, useFontSize, useChatColor)
	local ChannelButton = util:AddChannelButtonToBaseMessage(BaseMessage, formatChannelName, BaseMessage.TextColor3)

	return {
		[util.KEY_BASE_FRAME] = BaseFrame,
		[util.KEY_BASE_MESSAGE] = BaseMessage,
		[util.KEY_UPDATE_TEXT_FUNC] = nil
	}
end

return {
	[util.KEY_MESSAGE_TYPE] = MESSAGE_TYPE,
	[util.KEY_CREATOR_FUNCTION] = CreateChannelEchoSystemMessageLabel
}
