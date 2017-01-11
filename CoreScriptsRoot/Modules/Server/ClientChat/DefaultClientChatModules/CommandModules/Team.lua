--	// FileName: Team.lua
--	// Written by: Partixel/TheGamer101
--	// Description: Team chat bar manipulation.

local TEAM_COMMANDS = {"/team ", "/t ", "% "}

function IsTeamCommand(message)
	for i = 1, #TEAM_COMMANDS do
		local teamCommand = TEAM_COMMANDS[i]
		if string.sub(message, 1, teamCommand:len()):lower() == teamCommand then
			return true
		end
	end
	return false
end

local teamStateMethods = {}
teamStateMethods.__index = teamStateMethods

local util = require(script.Parent:WaitForChild("Util"))

local TeamCustomState = {}

function teamStateMethods:EnterTeamChat()
	self.TeamChatEntered = true
	self.MessageModeLabel.Size = UDim2.new(0, 1000, 1, 0)
	self.MessageModeLabel.Text = "[Team]"
	local xSize = self.MessageModeLabel.TextBounds.X
	self.MessageModeLabel.Size = UDim2.new(0, xSize, 1, 0)
	self.TextBox.Size = UDim2.new(1, -xSize, 1, 0)
	self.TextBox.Position = UDim2.new(0, xSize, 0, 0)
	self.OriginalTeamText = self.TextBox.Text
	self.TextBox.Text = " "
end

function teamStateMethods:TextUpdated()
	local newText = self.TextBox.Text
	if not self.TeamChatEntered then
		if IsTeamCommand(newText) then
			self:EnterTeamChat()
		end
	else
		if newText == "" then
			self.MessageModeLabel.Text = ""
			self.MessageModeLabel.Size = UDim2.new(0, 0, 0, 0)
			self.TextBox.Size = UDim2.new(1, 0, 1, 0)
			self.TextBox.Position = UDim2.new(0, 0, 0, 0)
			self.TextBox.Text = ""
			---Implement this when setting cursor positon is a thing.
			---self.TextBox.Text = self.OriginalTeamText
			self.TeamChatEntered = false
			---Temporary until setting cursor position...
			self.ChatBar:ResetCustomState()
			self.ChatBar:CaptureFocus()
		end
	end
end

function teamStateMethods:GetMessage()
	if self.TeamChatEntered then
		return "/t " ..self.TextBox.Text
	end
	return self.TextBox.Text
end

function teamStateMethods:ProcessCompletedMessage()
	return false
end

function teamStateMethods:Destroy()
	self.Destroyed = true
end

function TeamCustomState.new(ChatWindow, ChatBar, ChatSettings)
	local obj = setmetatable({}, teamStateMethods)
	obj.Destroyed = false
	obj.ChatWindow = ChatWindow
	obj.ChatBar = ChatBar
	obj.ChatSettings = ChatSettings
	obj.TextBox = ChatBar:GetTextBox()
	obj.MessageModeLabel = ChatBar:GetMessageModeTextLabel()
	obj.OriginalTeamText = ""
	obj.TeamChatEntered = false

	obj:EnterTeamChat()

	return obj
end

function ProcessMessage(message, ChatWindow, ChatBar, ChatSettings)
	if ChatBar.TargetChannel == "Team" then
		return
	end

	if IsTeamCommand(message) then
		return TeamCustomState.new(ChatWindow, ChatBar, ChatSettings)
	end
	return nil
end

return {
	[util.KEY_COMMAND_PROCESSOR_TYPE] = util.IN_PROGRESS_MESSAGE_PROCESSOR,
	[util.KEY_PROCESSOR_FUNCTION] = ProcessMessage
}
