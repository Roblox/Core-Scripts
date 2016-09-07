local runnerScriptName = "ChatServiceRunner"

local scriptPath = "ServerCoreScripts/ServerChat/"

local installDirectory = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
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
	local ChatServiceRunner = LoadScriptData(runnerScriptName)
	ChatServiceRunner.Name = runnerScriptName

	LoadModuleData("ChatService", ChatServiceRunner)
	LoadModuleData("ChatChannel", ChatServiceRunner)
	LoadModuleData("Speaker", ChatServiceRunner)
	LoadModuleData("ClassMaker", ChatServiceRunner)

	if (not ServerStorage:FindFirstChild("ChatModules")) then
		local ModulesFolder = Instance.new("Folder")
		ModulesFolder.Name = "ChatModules"

		local newPath = scriptPath .. "DefaultChatModules/"
		LoadModuleData("ExtraDataInitializer", ModulesFolder, newPath)
		LoadModuleData("ChatCommandsTeller", ModulesFolder, newPath)
		LoadModuleData("ChatFloodDetector", ModulesFolder, newPath)
		LoadModuleData("PrivateMessaging", ModulesFolder, newPath)
		LoadModuleData("TeamChat", ModulesFolder, newPath)
		

		ModulesFolder.Parent = ServerStorage
		ModulesFolder.Archivable = false
	end

	ChatServiceRunner.Parent = installDirectory
	ChatServiceRunner.Archivable = false
	ChatServiceRunner.Disabled = false
end

if (not installDirectory:FindFirstChild(runnerScriptName)) then
	Install()
end
