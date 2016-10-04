--	// FileName: DeveloperConsole.lua
--	// Written by: TheGamer101
--	// Description: Command to open or close the developer console.

local StarterGui = game:GetService("StarterGui")

function ProcessMessage(message, ChatWindow, ChatSettings)
  if string.sub(message, 1, 8) == "/console" then
    local success, developerConsoleVisible = pcall(function() return StarterGui:GetCore("DeveloperConsoleVisible") end)
    if success then
      pcall(function() StarterGui:SetCore("DeveloperConsoleVisible", not developerConsoleVisible) end)
    end
    return true
  end
  return false
end

return ProcessMessage
