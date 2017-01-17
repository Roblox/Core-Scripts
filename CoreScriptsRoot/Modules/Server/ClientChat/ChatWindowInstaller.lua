local runnerScriptName = "ChatScript"
local bubbleChatScriptName = "BubbleChat"
local installDirectory = game:GetService("Chat")

local ChatService = game:GetService("Chat")
local StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

local function LoadLocalScript(location, name, parent)
	local originalModule = location:WaitForChild(name)
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

local function GetBoolValue(parent, name, defaultValue)
	local boolValue = parent:FindFirstChild("Name")
	if boolValue then
		if boolValue:IsA("BoolValue") then
			return boolValue.Value
		end
	end
	return defaultValue
end

local function loadDefaultChatDisabled()
	local readFlagSuccess, flagEnabled = pcall(function() return settings():GetFFlag("LoadDefaultChatEnabled") end)
	if readFlagSuccess and flagEnabled then
		return not ChatService.LoadDefaultChat
	end
	return false
end

local function Install()
	if loadDefaultChatDisabled() then
		return
	end

	local readFlagSuccess, flagEnabled = pcall(function() return settings():GetFFlag("CorescriptChatInsertDefaultBools") end)
	local UseInsertDefaultBools = readFlagSuccess and flagEnabled

	local useNewBubbleChatSuccess, useNewBubbleChatEnabled = pcall(function() return settings():GetFFlag("CorescriptNewBubbleChatEnabled") end)
	useNewBubbleChatEnabled = useNewBubbleChatEnabled and useNewBubbleChatSuccess

	local chatScriptArchivable = true
	local ChatScript = installDirectory:FindFirstChild(runnerScriptName)
	if not ChatScript then
		chatScriptArchivable = false
		ChatScript = LoadLocalScript(script.Parent, runnerScriptName, installDirectory)
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

	local bubbleChatScriptArchivable = true
	local BubbleChatScript = installDirectory:FindFirstChild(bubbleChatScriptName)
	if not BubbleChatScript and useNewBubbleChatEnabled then
		bubbleChatScriptArchivable = false
		BubbleChatScript = LoadLocalScript(script.Parent.BubbleChat, bubbleChatScriptName, installDirectory)
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

		if UseInsertDefaultBools then
			local InsertDefaults = Instance.new("BoolValue")
			InsertDefaults.Name = "InsertDefaultModules"
			InsertDefaults.Value = true
			InsertDefaults.Parent = MessageCreatorModules
		else
			local creatorModules = script.Parent.DefaultClientChatModules.MessageCreatorModules:GetChildren()
			for i = 1, #creatorModules do
				LoadModule(script.Parent.DefaultClientChatModules.MessageCreatorModules, creatorModules[i].Name, MessageCreatorModules)
			end
		end

		MessageCreatorModules.Parent = clientChatModules
	end

	if UseInsertDefaultBools then
		local insertDefaultMessageCreators = GetBoolValue(MessageCreatorModules, "InsertDefaultModules", false)

		if insertDefaultMessageCreators then
			local creatorModules = script.Parent.DefaultClientChatModules.MessageCreatorModules:GetChildren()
			for i = 1, #creatorModules do
				if not MessageCreatorModules:FindFirstChild(creatorModules[i].Name) then
					LoadModule(script.Parent.DefaultClientChatModules.MessageCreatorModules, creatorModules[i].Name, MessageCreatorModules)
				end
			end
		end
	end

	local CommandModules = clientChatModules:FindFirstChild("CommandModules")
	if not CommandModules then
		CommandModules = Instance.new("Folder")
		CommandModules.Name = "CommandModules"
		CommandModules.Archivable = false

		if UseInsertDefaultBools then
			local InsertDefaults = Instance.new("BoolValue")
			InsertDefaults.Name = "InsertDefaultModules"
			InsertDefaults.Value = true
			InsertDefaults.Parent = CommandModules
		else
			local commandModules = script.Parent.DefaultClientChatModules.CommandModules:GetChildren()
			for i = 1, #commandModules do
				LoadModule(script.Parent.DefaultClientChatModules.CommandModules, commandModules[i].Name, CommandModules)
			end
		end

		CommandModules.Parent = clientChatModules
	end

	if UseInsertDefaultBools then
		local insertDefaultCommands = GetBoolValue(CommandModules, "InsertDefaultModules", false)

		if insertDefaultCommands then
			local commandModules = script.Parent.DefaultClientChatModules.CommandModules:GetChildren()
			for i = 1, #commandModules do
				if not CommandModules:FindFirstChild(commandModules[i].Name) then
					LoadModule(script.Parent.DefaultClientChatModules.CommandModules, commandModules[i].Name, CommandModules)
				end
			end
		end
	end

	if not StarterPlayerScripts:FindFirstChild(runnerScriptName) then
		local ChatScriptCopy = ChatScript:Clone()
		ChatScriptCopy.Parent = StarterPlayerScripts
		ChatScriptCopy.Archivable = false

		local currentPlayers = game:GetService("Players"):GetChildren()
		for i, player in pairs(currentPlayers) do
			if (player:IsA("Player") and player:FindFirstChild("PlayerScripts") and not player.PlayerScripts:FindFirstChild(runnerScriptName)) then
				ChatScriptCopy = ChatScript:Clone()
				ChatScriptCopy.Parent = player.PlayerScripts
				ChatScriptCopy.Archivable = false
			end
		end
	end

	ChatScript.Archivable = chatScriptArchivable

	if useNewBubbleChatEnabled then
		if not StarterPlayerScripts:FindFirstChild(bubbleChatScriptName) then
			local BubbleChatScriptCopy = BubbleChatScript:Clone()
			BubbleChatScriptCopy.Parent = StarterPlayerScripts
			BubbleChatScriptCopy.Archivable = false

			local currentPlayers = game:GetService("Players"):GetChildren()
			for i, player in pairs(currentPlayers) do
				if (player:IsA("Player") and player:FindFirstChild("PlayerScripts") and not player.PlayerScripts:FindFirstChild(bubbleChatScriptName)) then
					BubbleChatScriptCopy = BubbleChatScript:Clone()
					BubbleChatScriptCopy.Parent = player.PlayerScripts
					BubbleChatScriptCopy.Archivable = false
				end
			end
		end

		BubbleChatScript.Archivable = bubbleChatScriptArchivable
	end
end

return Install
