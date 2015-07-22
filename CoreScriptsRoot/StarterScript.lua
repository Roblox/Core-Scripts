-- Creates all neccessary scripts for the gui on initial load, everything except build tools
-- Created by Ben T. 10/29/10
-- Please note that these are loaded in a specific order to diminish errors/perceived load time by user
local scriptContext = game:GetService("ScriptContext")
local touchEnabled = game:GetService("UserInputService").TouchEnabled

local RobloxGui = Game:GetService("CoreGui"):WaitForChild("RobloxGui")
local screenGui = Game:GetService("CoreGui"):FindFirstChild("RobloxGui")

-- TopBar
local topbarSuccess, topbarFlagValue = pcall(function() return settings():GetFFlag("UseInGameTopBar") end)
local useTopBar = (topbarSuccess and topbarFlagValue == true)
if useTopBar then
	scriptContext:AddCoreScriptLocal("CoreScripts/Topbar", screenGui)
end

local controllerMenuSuccess,controllerMenuFlagValue = pcall(function() return settings():GetFFlag("ControllerMenu") end)
local useNewControllerMenu = (controllerMenuSuccess and controllerMenuFlagValue)

-- SettingsScript
local luaControlsSuccess, luaControlsFlagValue = pcall(function() return settings():GetFFlag("UseLuaCameraAndControl") end)

if not useNewControllerMenu then
	spawn(function() require(RobloxGui.Modules.Settings2) end)
end

-- MainBotChatScript (the Lua part of Dialogs)
scriptContext:AddCoreScriptLocal("CoreScripts/MainBotChatScript2", screenGui)

-- Developer Console Script
scriptContext:AddCoreScriptLocal("CoreScripts/DeveloperConsole", screenGui)

-- In-game notifications script
scriptContext:AddCoreScriptLocal("CoreScripts/NotificationScript2", screenGui)

-- Chat script
if useTopBar then
	spawn(function() require(RobloxGui.Modules.Chat) end)
	spawn(function() require(RobloxGui.Modules.PlayerlistModule) end)
end

-- Purchase Prompt Script
scriptContext:AddCoreScriptLocal("CoreScripts/PurchasePromptScript2", screenGui)

-- Health Script
if not useTopBar then
	scriptContext:AddCoreScriptLocal("CoreScripts/HealthScript", screenGui)
end

do -- Backpack!
	spawn(function() require(RobloxGui.Modules.BackpackScript) end)
end

if useTopBar then
	scriptContext:AddCoreScriptLocal("CoreScripts/VehicleHud", screenGui)
end

if useNewControllerMenu then
	scriptContext:AddCoreScriptLocal("CoreScripts/GamepadMenu", screenGui)
end

if touchEnabled then -- touch devices don't use same control frame
	-- only used for touch device button generation
	scriptContext:AddCoreScriptLocal("CoreScripts/ContextActionTouch", screenGui)

	screenGui:WaitForChild("ControlFrame")
	screenGui.ControlFrame:WaitForChild("BottomLeftControl")
	screenGui.ControlFrame.BottomLeftControl.Visible = false
end
