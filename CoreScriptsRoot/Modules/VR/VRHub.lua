--Modules/VR/VRHub.lua
--Handles all global VR state that isn't built into a specific module.
--Written by 0xBAADF00D (Kyle) on 6/10/16
local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local Util = require(RobloxGui.Modules.Settings.Utility)

local VRHub = {}

VRHub.ModuleOpened = Util:Create "BindableEvent" {
	Name = "VRModuleOpened"
}
--Wrapper function to document the arguments to the event
function VRHub:FireModuleOpened(moduleName, isExclusive, shouldCloseNonExclusive, shouldKeepTopbarOpen)
	VRHub.ModuleOpened:Fire(moduleName, isExclusive, shouldCloseNonExclusive, shouldKeepTopbarOpen)
end

VRHub.ModuleClosed = Util:Create "BindableEvent" {
	Name = "VRModuleClosed"
}
--Wrapper function to document the arguments to the event
function VRHub:FireModuleClosed(moduleName)
	VRHub.ModuleClosed:Fire(moduleName)
end

return VRHub