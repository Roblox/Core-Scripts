local runnerScriptName = "ChatScript"
local installDirectory = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function LoadLocalScript(name, parent)
	local originalModule = script.Parent:WaitForChild(name)
	local script = Instance.new("LocalScript")
	script.Name = name
	script.Source = originalModule.Source
	script.Parent = parent
	return script
end

local function LoadModule(location, name, parent)
	local originalModule = location:WaitForChild(name)
	local module = Instance.new("ModuleScript")
	module.Name = name
	module.Source = originalModule.Source
	module.Parent = parent
	return module
end

local function Install()
	if (not installDirectory or installDirectory:FindFirstChild(runnerScriptName)) then
		return
	end

	local ChatScript = LoadLocalScript(runnerScriptName, installDirectory)
	local ChatMain = LoadModule(script.Parent, "ChatMain", ChatScript)

	LoadModule(script.Parent, "ChannelsBar", ChatMain)
	LoadModule(script.Parent, "ChatBar", ChatMain)
	LoadModule(script.Parent, "ChatChannel", ChatMain)
	LoadModule(script.Parent, "MessageLogDisplay", ChatMain)
	LoadModule(script.Parent, "ChatWindow", ChatMain)
	--LoadModule("SpeakerDatabase", ChatMain)
	LoadModule(script.Parent, "MessageLabelCreator", ChatMain)
	LoadModule(script.Parent, "CommandProcessor", ChatMain)
	LoadModule(script.Parent, "ChannelsTab", ChatMain)
	LoadModule(script.Parent, "TransparencyTweener", ChatMain)
	LoadModule(script.Parent.Parent.Parent.Common, "ClassMaker", ChatMain)
	LoadModule(script.Parent.Parent.Parent.Common, "ObjectPool", ChatMain)
	LoadModule(script.Parent, "MessageSender", ChatMain)

	if (not ReplicatedStorage:FindFirstChild("ClientChatModules")) then
		local ModulesFolder = Instance.new("Folder")
		ModulesFolder.Name = "ClientChatModules"

		LoadModule(script.Parent.DefaultClientChatModules, "ChatSettings", ModulesFolder)

		ModulesFolder.Parent = ReplicatedStorage
		ModulesFolder.Archivable = false
	end

	local clientChatModules = ReplicatedStorage.ClientChatModules
	if (not clientChatModules:FindFirstChild("MessageCreatorModules")) then
		local ModulesFolder = Instance.new("Folder")
		ModulesFolder.Name = "MessageCreatorModules"

		local creatorModules = script.Parent.DefaultClientChatModules.MessageCreatorModules:GetChildren()

		for i = 1, #creatorModules do
			LoadModule(script.Parent.DefaultClientChatModules.MessageCreatorModules, creatorModules[i].Name, ModulesFolder)
		end

		ModulesFolder.Parent = clientChatModules
		ModulesFolder.Archivable = false
	end

	if (not clientChatModules:FindFirstChild("CommandModules")) then
		local ModulesFolder = Instance.new("Folder")
		ModulesFolder.Name = "CommandModules"

		local commandModules = script.Parent.DefaultClientChatModules.CommandModules:GetChildren()

		for i = 1, #commandModules do
			LoadModule(script.Parent.DefaultClientChatModules.CommandModules, commandModules[i].Name, ModulesFolder)
		end

		ModulesFolder.Parent = clientChatModules
		ModulesFolder.Archivable = false
	end

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

return Install
