local runnerScriptName = "ChatServiceRunner"

local ChatService = game:GetService("Chat")
local installDirectory = game:GetService("Chat")
local ServerScriptService = game:GetService("ServerScriptService")

local function LoadScript(name, parent)
	local originalModule = script.Parent:WaitForChild(name)
	local script = Instance.new("Script")
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
	local boolValue = parent:FindFirstChild(name)
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

	local chatServiceRunnerArchivable = true
	local ChatServiceRunner = installDirectory:FindFirstChild(runnerScriptName)
	if not ChatServiceRunner then
		chatServiceRunnerArchivable = false
		ChatServiceRunner = LoadScript(runnerScriptName, installDirectory)

		LoadModule(script.Parent, "ChatService", ChatServiceRunner)
		LoadModule(script.Parent, "ChatChannel", ChatServiceRunner)
		LoadModule(script.Parent, "Speaker", ChatServiceRunner)
		LoadModule(script.Parent, "Util", ChatServiceRunner)
	end

	local ChatModules = installDirectory:FindFirstChild("ChatModules")
	if not ChatModules then
		ChatModules = Instance.new("Folder")
		ChatModules.Name = "ChatModules"
		ChatModules.Archivable = false

		if UseInsertDefaultBools then
			local InsertDefaults = Instance.new("BoolValue")
			InsertDefaults.Name = "InsertDefaultModules"
			InsertDefaults.Value = true
			InsertDefaults.Parent = ChatModules
		else
			local defaultChatModules = script.Parent.DefaultChatModules:GetChildren()		  		local defaultChatModules = script.Parent.DefaultChatModules:GetChildren()
  		for i = 1, #defaultChatModules do
				LoadModule(script.Parent.DefaultChatModules, defaultChatModules[i].Name, ChatModules)
			end
		end

		ChatModules.Parent = installDirectory
	end

	if UseInsertDefaultBools then
		local shouldInsertDefaultModules = GetBoolValue(ChatModules, "InsertDefaultModules", false)

		if shouldInsertDefaultModules then
			local defaultChatModules = script.Parent.DefaultChatModules:GetChildren()
			for i = 1, #defaultChatModules do
				if not ChatModules:FindFirstChild(defaultChatModules[i].Name) then
					LoadModule(script.Parent.DefaultChatModules, defaultChatModules[i].Name, ChatModules)
				end
			end
		end
	end

	if not ServerScriptService:FindFirstChild(runnerScriptName) then
		local ChatServiceRunnerCopy = ChatServiceRunner:Clone()
		ChatServiceRunnerCopy.Archivable = false
		ChatServiceRunnerCopy.Parent = ServerScriptService
	end

	ChatServiceRunner.Archivable = chatServiceRunnerArchivable
end

return Install
