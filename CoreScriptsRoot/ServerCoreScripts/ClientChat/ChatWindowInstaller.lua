local runnerScriptName = "ChatScript"

local scriptPath = "ServerCoreScripts/ClientChat/"

local installDirectory = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
local ScriptContext = game:GetService("ScriptContext")

local function LoadScriptData(name, path)
	path = path or scriptPath

	ScriptContext:AddCoreScriptLocal(path .. name, script)

	local generated = script:WaitForChild(path .. name):WaitForChild("Generated")
	return generated
end

local function LoadModuleData(name, parent, path)
	local module = LoadScriptData(name, path)
	module.Name = name
	module.Parent = parent
	return module
end

local function Install()
	local ChatScript = LoadScriptData(runnerScriptName)
	ChatScript.Name = runnerScriptName

	local NewChat = LoadModuleData("NewChat", ChatScript)

	LoadModuleData("ChannelsBar", NewChat)
	LoadModuleData("ChatBar", NewChat)
	LoadModuleData("ChatChannel", NewChat)
	LoadModuleData("ChatLog", NewChat)
	LoadModuleData("ChatSettings", NewChat)
	LoadModuleData("ChatWindow", NewChat)
	LoadModuleData("SpeakerDatabase", NewChat)
	LoadModuleData("MessageLabelCreator", NewChat)

	ChatScript.Parent = installDirectory
	--ChatScript.Archivable = false
	ChatScript.Disabled = false

	local currentPlayers = game:GetService("Players"):GetChildren()
	for i, player in pairs(currentPlayers) do
		if (player:IsA("Player") and player:FindFirstChild("PlayerScripts") and not player.PlayerScripts:FindFirstChild(runnerScriptName)) then
			ChatScript:Clone().Parent = player.PlayerScripts
			ChatScript.Archivable = false
		end
	end

	ChatScript.Archivable = false
end

if (installDirectory and not installDirectory:FindFirstChild(runnerScriptName)) then
	Install()
end
