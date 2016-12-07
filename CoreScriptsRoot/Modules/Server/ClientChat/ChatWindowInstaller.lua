local runnerScriptName = "ChatScript"
local installDirectory = game:GetService("Chat")
local StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

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
		LoadModule(script.Parent, "MessageLabelCreator", ChatMain)
		LoadModule(script.Parent, "CommandProcessor", ChatMain)
		LoadModule(script.Parent, "ChannelsTab", ChatMain)
		LoadModule(script.Parent.Parent.Parent.Common, "ClassMaker", ChatMain)
		LoadModule(script.Parent.Parent.Parent.Common, "ObjectPool", ChatMain)
		LoadModule(script.Parent, "MessageSender", ChatMain)
		LoadModule(script.Parent, "CurveUtil", ChatMain)
	end

	local clientChatModules = installDirectory:FindFirstChild("ClientChatModules")
	if not clientChatModules then
		clientChatModules = Instance.new("Folder")
		clientChatModules.Name = "ClientChatModules"
		clientChatModules.Archivable = false

		clientChatModules.Parent = installDirectory
	end

	local chatSettings = clientChatModules:FindFirstChild("ChatSettings")
	if not chatSettings then
		LoadModule(script.Parent.DefaultClientChatModules, "ChatSettings", clientChatModules)
	end

	local chatConstants = clientChatModules:FindFirstChild("ChatConstants")
	if not chatConstants then
		LoadModule(script.Parent.DefaultClientChatModules, "ChatConstants", clientChatModules)
	end

	local MessageCreatorModules = clientChatModules:FindFirstChild("MessageCreatorModules")
	if not MessageCreatorModules then
		MessageCreatorModules = Instance.new("Folder")
		MessageCreatorModules.Name = "MessageCreatorModules"
		MessageCreatorModules.Archivable = false

		local creatorModules = script.Parent.DefaultClientChatModules.MessageCreatorModules:GetChildren()

		for i = 1, #creatorModules do
			LoadModule(script.Parent.DefaultClientChatModules.MessageCreatorModules, creatorModules[i].Name, MessageCreatorModules)
		end

		MessageCreatorModules.Parent = clientChatModules
	end

	local CommandModules = clientChatModules:FindFirstChild("CommandModules")
	if not CommandModules then
		CommandModules = Instance.new("Folder")
		CommandModules.Name = "CommandModules"
		CommandModules.Archivable = false

		local commandModules = script.Parent.DefaultClientChatModules.CommandModules:GetChildren()

		for i = 1, #commandModules do
			LoadModule(script.Parent.DefaultClientChatModules.CommandModules, commandModules[i].Name, CommandModules)
		end

		CommandModules.Parent = clientChatModules
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
end

return Install
