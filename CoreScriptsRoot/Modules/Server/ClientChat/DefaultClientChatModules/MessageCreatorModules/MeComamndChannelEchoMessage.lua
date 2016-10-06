--	// FileName: MeCommandChannelEchoMessage.lua
--	// Written by: TheGamer101
--	// Description: Create a message label for a me command message echoed into another channel.

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
  local useChatColor = Color3.new(1, 1, 1)

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

  local AnimParams = {}
  AnimParams.Text_TargetTransparency = 0
  AnimParams.Text_CurrentTransparency = 0
  AnimParams.TextStroke_TargetTransparency = 0.75
  AnimParams.TextStroke_CurrentTransparency = 0.75

  local function FadeInFunction(duration)
    AnimParams.Text_TargetTransparency = 0
    AnimParams.TextStroke_TargetTransparency = 0.75
  end

  local function FadeOutFunction(duration)
    AnimParams.Text_TargetTransparency = 1
    AnimParams.TextStroke_TargetTransparency = 1
  end

  local function AnimGuiObjects()
    BaseMessage.TextTransparency = AnimParams.Text_CurrentTransparency
    BaseMessage.TextStrokeTransparency = AnimParams.TextStroke_CurrentTransparency
  end

  local function UpdateAnimFunction(dtScale, CurveUtil)
    AnimParams.Text_CurrentTransparency = CurveUtil:Expt(AnimParams.Text_CurrentTransparency, AnimParams.Text_TargetTransparency, 0.1, dtScale)
    AnimParams.TextStroke_CurrentTransparency = CurveUtil:Expt(AnimParams.TextStroke_CurrentTransparency, AnimParams.TextStroke_TargetTransparency, 0.1, dtScale)

    AnimGuiObjects()
  end

  return {
    [util.KEY_BASE_FRAME] = BaseFrame,
    [util.KEY_BASE_MESSAGE] = BaseMessage,
    [util.KEY_UPDATE_TEXT_FUNC] = UpdateTextFunction,
    [util.KEY_FADE_IN] = FadeInFunction,
    [util.KEY_FADE_OUT] = FadeOutFunction,
    [util.KEY_UPDATE_ANIMATION] = UpdateAnimFunction
  }
end

return {
  [util.KEY_MESSAGE_TYPE] = MESSAGE_TYPE,
  [util.KEY_CREATOR_FUNCTION] = CreateMeCommandChannelEchoMessageLabel
}
