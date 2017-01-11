--	// FileName: Whisper.lua
--	// Written by: TheGamer101
--	// Description: Whisper chat bar manipulation.

local util = require(script.Parent:WaitForChild("Util"))
local playerService = game:GetService("Players")

local whisperStateMethods = {}
whisperStateMethods.__index = whisperStateMethods

local WhisperCustomState = {}

function whisperStateMethods:PlayerExists(possiblePlayerName)
	local players = playerService:GetPlayers()
	for i = 1, #players do
		if players[i].Name:lower() == possiblePlayerName:lower() then
			return true
		end
	end
	return false
end

function whisperStateMethods:TextUpdated()
	local newText = self.TextBox.Text
	if not self.PlayerNameEntered then
		local possiblePlayerName = string.sub(newText, 4)
		local player = nil
		if self:PlayerExists(possiblePlayerName) then
			player = possiblePlayerName
			self.OriginalText = string.sub(newText, 1, 3)
		end
		possiblePlayerName = string.sub(newText, 10)
		if player == nil and self:PlayerExists(possiblePlayerName) then
			player = possiblePlayerName
			self.OriginalText = string.sub(newText, 1, 9)
		end
		if player then
			self.PlayerNameEntered = true
			self.PlayerName = player

			self.MessageModeLabel.Size = UDim2.new(0, 1000, 1, 0)
			self.MessageModeLabel.Text = string.format("[%s]", player)
			local xSize = self.MessageModeLabel.TextBounds.X
			self.MessageModeLabel.Size = UDim2.new(0, xSize, 1, 0)
			self.TextBox.Size = UDim2.new(1, -xSize, 1, 0)
			self.TextBox.Position = UDim2.new(0, xSize, 0, 0)
			self.TextBox.Text = " "
		end
	else
		if newText == "" then
			self.MessageModeLabel.Text = ""
			self.MessageModeLabel.Size = UDim2.new(0, 0, 0, 0)
			self.TextBox.Size = UDim2.new(1, 0, 1, 0)
			self.TextBox.Position = UDim2.new(0, 0, 0, 0)
			self.TextBox.Text = ""
			---Implement this when setting cursor positon is a thing.
			---self.TextBox.Text = self.OriginalText .. " " .. self.PlayerName
			self.PlayerNameEntered = false
			---Temporary until setting cursor position...
			self.ChatBar:ResetCustomState()
			self.ChatBar:CaptureFocus()
		end
	end
end

function whisperStateMethods:GetMessage()
	if self.PlayerNameEntered then
		return "/w " ..self.PlayerName.. " " ..self.TextBox.Text
	end
	return self.TextBox.Text
end

function whisperStateMethods:ProcessCompletedMessage()
	return false
end

function whisperStateMethods:Destroy()
	self.Destroyed = true
end

function WhisperCustomState.new(ChatWindow, ChatBar, ChatSettings)
	local obj = setmetatable({}, whisperStateMethods)
	obj.Destroyed = false
	obj.ChatWindow = ChatWindow
	obj.ChatBar = ChatBar
	obj.ChatSettings = ChatSettings
	obj.TextBox = ChatBar:GetTextBox()
	obj.MessageModeLabel = ChatBar:GetMessageModeTextLabel()
	obj.OriginalWhisperText = ""
	obj.PlayerNameEntered = false

	obj:TextUpdated()

	return obj
end

function ProcessMessage(message, ChatWindow, ChatBar, ChatSettings)
	if string.sub(message, 1, 3):lower() == "/w " or	string.sub(message, 1, 9):lower() == "/whisper " then
		return WhisperCustomState.new(ChatWindow, ChatBar, ChatSettings)
	end
	return nil
end

return {
	[util.KEY_COMMAND_PROCESSOR_TYPE] = util.IN_PROGRESS_MESSAGE_PROCESSOR,
	[util.KEY_PROCESSOR_FUNCTION] = ProcessMessage
}
