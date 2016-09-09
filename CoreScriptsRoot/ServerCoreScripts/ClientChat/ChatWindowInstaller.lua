local runnerScriptName = "ChatScript"

local scriptPath = "ServerCoreScripts/ClientChat/"

local installDirectory = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
local ScriptContext = game:GetService("ScriptContext")

local function LoadScriptData(name, path)
	path = path or scriptPath

	ScriptContext:AddCoreScriptLocal(path .. name, script.Parent) -- this was changed and doing script without script.Parent ruins everything!
	
	local generated = script.Parent:WaitForChild(path .. name):WaitForChild("Generated")
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

	local ChatMain = LoadModuleData("ChatMain", ChatScript)

	LoadModuleData("ChannelsBar", ChatMain)
	LoadModuleData("ChatBar", ChatMain)
	LoadModuleData("ChatChannel", ChatMain)
	LoadModuleData("ChatWindow", ChatMain)
	--LoadModuleData("SpeakerDatabase", ChatMain)
	LoadModuleData("MessageLabelCreator", ChatMain)
	LoadModuleData("ChannelsTab", ChatMain)
	LoadModuleData("TransparencyTweener", ChatMain)
	LoadModuleData("ChatSettings", ChatMain)
	LoadModuleData("ClassMaker", ChatMain)
	LoadModuleData("MessageSender", ChatMain)

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
