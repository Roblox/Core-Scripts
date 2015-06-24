

local DeveloperConsoleModule;
local function RequireDeveloperConsoleModule()
	if not DeveloperConsoleModule then
		DeveloperConsoleModule = require(game:GetService("CoreGui"):WaitForChild('RobloxGui').Modules.DeveloperConsoleModule)
	end
end

local screenGui = script.Parent:FindFirstChild("ControlFrame") or script.Parent

local ToggleConsole = Instance.new('BindableFunction')
ToggleConsole.Name = 'ToggleDevConsole'
ToggleConsole.Parent = screenGui

local developerConsole;
function ToggleConsole.OnInvoke(duplicate)
	RequireDeveloperConsoleModule()
	if not developerConsole or duplicate == true then
		local permissions = DeveloperConsoleModule.GetPermissions()
		local messagesAndStats = DeveloperConsoleModule.GetMessagesAndStats(permissions)
		developerConsole = DeveloperConsoleModule.new(screenGui, permissions, messagesAndStats)
		developerConsole:SetVisible(true)
	else
		developerConsole:SetVisible(not developerConsole.Visible)
	end
end

