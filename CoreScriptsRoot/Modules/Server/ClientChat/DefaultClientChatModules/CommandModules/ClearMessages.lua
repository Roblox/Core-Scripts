--	// FileName: ClearMessages.lua
--	// Written by: TheGamer101
--	// Description: Command to clear the message log of the current channel.

function ProcessMessage(message, ChatWindow, ChatSettings)
  if string.sub(message, 1, 4) == "/cls" or string.sub(message, 1, 6) == "/clear" then
    local currentChannel = ChatWindow:GetCurrentChannel()
    if (currentChannel) then
      currentChannel:ClearMessageLog()
    end
    return true
  end
  return false
end

return ProcessMessage
