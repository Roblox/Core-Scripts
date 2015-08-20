-- Creates all neccessary scripts for the gui on initial load, everything except build tools
-- Created by Ben T. 10/29/10
-- Please note that these are loaded in a specific order to diminish errors/perceived load time by user

local scriptContext = game:GetService("ScriptContext")
local touchEnabled = game:GetService("UserInputService").TouchEnabled

local RobloxGui = Game:GetService("CoreGui"):WaitForChild("RobloxGui")

local soundFolder = Instance.new("Folder")
soundFolder.Name = "Sounds"
soundFolder.Parent = RobloxGui

-- TopBar
local topbarSuccess, topbarFlagValue = pcall(function() return settings():GetFFlag("UseInGameTopBar") end)
local useTopBar = (topbarSuccess and topbarFlagValue == true)
if useTopBar then
	scriptContext:AddCoreScriptLocal("CoreScripts/Topbar", RobloxGui)
end

local controllerMenuSuccess,controllerMenuFlagValue = pcall(function() return settings():GetFFlag("ControllerMenu") end)
local useNewControllerMenu = (controllerMenuSuccess and controllerMenuFlagValue)

-- SettingsScript
local luaControlsSuccess, luaControlsFlagValue = pcall(function() return settings():GetFFlag("UseLuaCameraAndControl") end)

if not useNewControllerMenu then
	spawn(function() require(RobloxGui.Modules.Settings2) end)
end

-- MainBotChatScript (the Lua part of Dialogs)
scriptContext:AddCoreScriptLocal("CoreScripts/MainBotChatScript2", RobloxGui)

-- Developer Console Script
scriptContext:AddCoreScriptLocal("CoreScripts/DeveloperConsole", RobloxGui)

-- In-game notifications script
scriptContext:AddCoreScriptLocal("CoreScripts/NotificationScript2", RobloxGui)

-- Chat script
if useTopBar then
	spawn(function() require(RobloxGui.Modules.Chat) end)
	spawn(function() require(RobloxGui.Modules.PlayerlistModule) end)
end

-- Purchase Prompt Script
scriptContext:AddCoreScriptLocal("CoreScripts/PurchasePromptScript2", RobloxGui)

-- Health Script
if not useTopBar then
	scriptContext:AddCoreScriptLocal("CoreScripts/HealthScript", RobloxGui)
end

do -- Backpack!
	spawn(function() require(RobloxGui.Modules.BackpackScript) end)
end

if useTopBar then
	scriptContext:AddCoreScriptLocal("CoreScripts/VehicleHud", RobloxGui)
end

if useNewControllerMenu then
	scriptContext:AddCoreScriptLocal("CoreScripts/GamepadMenu", RobloxGui)
end

if touchEnabled then -- touch devices don't use same control frame
	-- only used for touch device button generation
	scriptContext:AddCoreScriptLocal("CoreScripts/ContextActionTouch", RobloxGui)

	RobloxGui:WaitForChild("ControlFrame")
	RobloxGui.ControlFrame:WaitForChild("BottomLeftControl")
	RobloxGui.ControlFrame.BottomLeftControl.Visible = false
end
