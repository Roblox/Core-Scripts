local runnerScriptName = "ChatScript"
local installDirectory = game:GetService("Chat")
local StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
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
	local chatScriptArchivable = true
	local ChatScript = installDirectory:FindFirstChild(runnerScriptName)
	if not ChatScript then
		chatScriptArchivable = false
		ChatScript = LoadLocalScript(runnerScriptName, installDirectory)
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
		LoadModule(script.Parent.Parent.Parent.Common, "ClassMaker", ChatMain)
		LoadModule(script.Parent.Parent.Parent.Common, "ObjectPool", ChatMain)
		LoadModule(script.Parent, "MessageSender", ChatMain)
		LoadModule(script.Parent, "CurveUtil", ChatMain)
	end

	local ClientChatModules = installDirectory:FindFirstChild("ClientChatModules")
	if not ClientChatModules then
		ClientChatModules = Instance.new("Folder")
		ClientChatModules.Name = "ClientChatModules"

		LoadModule(script.Parent.DefaultClientChatModules, "ChatSettings", ClientChatModules)

		ClientChatModules.Parent = installDirectory
	end

	local messageCreatorModulesArchivable = true
	local MessageCreatorModules = ClientChatModules:FindFirstChild("MessageCreatorModules")
	if not MessageCreatorModules then
		messageCreatorModulesArchivable = false
		MessageCreatorModules = Instance.new("Folder")
		MessageCreatorModules.Name = "MessageCreatorModules"

		local creatorModules = script.Parent.DefaultClientChatModules.MessageCreatorModules:GetChildren()

		for i = 1, #creatorModules do
			LoadModule(script.Parent.DefaultClientChatModules.MessageCreatorModules, creatorModules[i].Name, MessageCreatorModules)
		end

		MessageCreatorModules.Parent = ClientChatModules
	end

	local commandModulesArchivable = true
	local CommandModules = ClientChatModules:FindFirstChild("CommandModules")
	if not CommandModules then
		commandModulesArchivable = false
		CommandModules = Instance.new("Folder")
		CommandModules.Name = "CommandModules"

		local commandModules = script.Parent.DefaultClientChatModules.CommandModules:GetChildren()

		for i = 1, #commandModules do
			LoadModule(script.Parent.DefaultClientChatModules.CommandModules, commandModules[i].Name, CommandModules)
		end

		CommandModules.Parent = ClientChatModules
	end

	if not ReplicatedStorage:FindFirstChild(ClientChatModules) then
		local ClientChatModulesCopy = ClientChatModules:Clone()
		ClientChatModulesCopy.Parent = ReplicatedStorage
		ClientChatModulesCopy.Archivable = false
	end

	if not StarterPlayerScripts:FindFirstChild(runnerScriptName) then
		local ChatScriptCopy = ChatScript:Clone()
		ChatScriptCopy.Parent = StarterPlayerScripts
		ChatScriptCopy.Archivable = false

		local currentPlayers = game:GetService("Players"):GetChildren()
		for i, player in pairs(currentPlayers) do
			if (player:IsA("Player") and player:FindFirstChild("PlayerScripts") and not player.PlayerScripts:FindFirstChild(runnerScriptName)) then
				ChatScript:Clone().Parent = player.PlayerScripts
				ChatScript.Archivable = false
			end
		end
	end

	ChatScript.Archivable = chatScriptArchivable
	ClientChatModules.Archivable = clientChatModulesArchivable
	MessageCreatorModules.Archivable = messageCreatorModulesArchivable
	CommandModules.Archivable = commandModulesArchivable
end

return Install
