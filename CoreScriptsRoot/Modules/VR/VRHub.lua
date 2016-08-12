--Modules/VR/VRHub.lua
--Handles all global VR state that isn't built into a specific module.
--Written by 0xBAADF00D (Kyle) on 6/10/16
local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local Util = require(RobloxGui.Modules.Settings.Utility)

local VRHub = {}
local RegisteredModules = {}
local OpenModules = {}

function VRHub:RegisterModule(module)
	RegisteredModules[module.ModuleName] = module
end

function VRHub:GetModule(moduleName)
	return RegisteredModules[moduleName]
end

function VRHub:IsModuleOpened(moduleName)
	return OpenModules[moduleName] ~= nil
end

function VRHub:GetOpenedModules()
	local result = {}

	for _, openModule in pairs(OpenModules) do
		table.insert(result, openModule)
	end

	return result
end

VRHub.ModuleOpened = Util:Create "BindableEvent" {
	Name = "VRModuleOpened"
}
--Wrapper function to document the arguments to the event
function VRHub:FireModuleOpened(moduleName)
	if not RegisteredModules[moduleName] then
		error("Tried to open module that is not registered: " .. moduleName)
	end

	if OpenModules[moduleName] ~= RegisteredModules[moduleName] then
		OpenModules[moduleName] = RegisteredModules[moduleName]
		VRHub.ModuleOpened:Fire(moduleName)
	end
end

VRHub.ModuleClosed = Util:Create "BindableEvent" {
	Name = "VRModuleClosed"
}
--Wrapper function to document the arguments to the event
function VRHub:FireModuleClosed(moduleName)
	if not RegisteredModules[moduleName] then
		error("Tried to close module that is not registered: " .. moduleName)
	end

	if OpenModules[moduleName] ~= nil then
		OpenModules[moduleName] = nil
		VRHub.ModuleClosed:Fire(moduleName)
	end
end

function VRHub:KeepVRTopbarOpen()
	for moduleName, openModule in pairs(OpenModules) do
		if openModule.KeepVRTopbarOpen then
			return true
		end
	end
	return false
end

return VRHub