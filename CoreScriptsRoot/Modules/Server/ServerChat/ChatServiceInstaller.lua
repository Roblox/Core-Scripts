local runnerScriptName = "ChatServiceRunner"

local installDirectory = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

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

local function Install()

	local ChatServiceRunner = installDirectory:FindFirstChild(runnerScriptName)
	if not ChatServiceRunner then
		ChatServiceRunner = LoadScript(runnerScriptName, installDirectory)

		LoadModule(script.Parent, "ChatService", ChatServiceRunner)
		LoadModule(script.Parent, "ChatChannel", ChatServiceRunner)
		LoadModule(script.Parent, "Speaker", ChatServiceRunner)
		LoadModule(script.Parent.Parent.Parent.Common, "ClassMaker", ChatServiceRunner)
	end

	if (not ServerStorage:FindFirstChild("ChatModules")) then
		local ModulesFolder = Instance.new("Folder")
		ModulesFolder.Name = "ChatModules"

		LoadModule(script.Parent.DefaultChatModules, "ExtraDataInitializer", ModulesFolder)
		LoadModule(script.Parent.DefaultChatModules, "ChatCommandsTeller", ModulesFolder)
		LoadModule(script.Parent.DefaultChatModules, "ChatFloodDetector", ModulesFolder)
		LoadModule(script.Parent.DefaultChatModules, "PrivateMessaging", ModulesFolder)
		LoadModule(script.Parent.DefaultChatModules, "TeamChat", ModulesFolder)


		ModulesFolder.Parent = ServerStorage
		ModulesFolder.Archivable = false
	end

	ChatServiceRunner.Parent = installDirectory
	ChatServiceRunner.Archivable = false
	ChatServiceRunner.Disabled = false
end

return Install
