--Modules/VR/VRHub.lua
--Handles all global VR state that isn't built into a specific module.
--Written by 0xBAADF00D (Kyle) on 6/10/16
local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local Util = require(RobloxGui.Modules.Settings.Utility)

local VRHub = {}
VRHub.RegisteredModules = {}
VRHub.OpenModules = {}

function VRHub:RegisterModule(module)
	VRHub.RegisteredModules[module.ModuleName] = module
end

VRHub.ModuleOpened = Util:Create "BindableEvent" {
	Name = "VRModuleOpened"
}
--Wrapper function to document the arguments to the event
function VRHub:FireModuleOpened(moduleName, isExclusive, shouldCloseNonExclusive, shouldKeepTopbarOpen)
	if not VRHub.RegisteredModules[moduleName] then
		error("Tried to open module that is not registered: " .. moduleName)
	end

	VRHub.OpenModules[moduleName] = VRHub.RegisteredModules[moduleName]
	VRHub.ModuleOpened:Fire(moduleName, isExclusive, shouldCloseNonExclusive, shouldKeepTopbarOpen)
end

VRHub.ModuleClosed = Util:Create "BindableEvent" {
	Name = "VRModuleClosed"
}
--Wrapper function to document the arguments to the event
function VRHub:FireModuleClosed(moduleName)
	if not VRHub.RegisteredModules[moduleName] then
		error("Tried to close module that is not registered: " .. moduleName)
	end

	VRHub.OpenModules[moduleName] = nil
	VRHub.ModuleClosed:Fire(moduleName)
end

function VRHub:KeepVRTopbarOpen()
	for moduleName, module in pairs(VRHub.OpenModules) do
		if module.KeepVRTopbarOpen then
			return true
		end
	end
	return false
end

return VRHub