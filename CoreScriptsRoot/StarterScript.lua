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

-- SettingsScript
local luaControlsSuccess, luaControlsFlagValue = pcall(function() return settings():GetFFlag("UseLuaCameraAndControl") end)
local newSettingsSuccess, newSettingsFlagValue = pcall(function() return settings():GetFFlag("NewMenuSettingsScript") end)
local useNewSettings = newSettingsSuccess and newSettingsFlagValue
if useNewSettings then
	spawn(function() require(RobloxGui.Modules.Settings2) end)
else
	scriptContext:AddCoreScriptLocal("CoreScripts/Settings", screenGui)
end

-- Set up touch controls. TODO: Remove when new lua controls are stable.
if touchEnabled then
	if not luaControlsSuccess or luaControlsFlagValue == false then
		scriptContext:AddCoreScriptLocal("CoreScripts/TouchControls", screenGui)
	end
end

-- MainBotChatScript (the Lua part of Dialogs)
local useNewDialogLook = false
pcall(function() useNewDialogLook = settings():GetFFlag("UseNewBubbleSkin") end)
if useNewDialogLook then
	scriptContext:AddCoreScriptLocal("CoreScripts/MainBotChatScript2", screenGui)
else
	scriptContext:AddCoreScriptLocal("CoreScripts/MainBotChatScript", screenGui)
end

-- Developer Console Script
scriptContext:AddCoreScriptLocal("CoreScripts/DeveloperConsole", screenGui)

-- In-game notifications script
scriptContext:AddCoreScriptLocal("CoreScripts/NotificationScript2", screenGui)

-- Chat script
if useTopBar then
	spawn(function() require(RobloxGui.Modules.Chat) end)
else
	scriptContext:AddCoreScriptLocal("CoreScripts/ChatScript2", screenGui)
end

-- Purchase Prompt Script
local newPurchaseSuccess, newPurchaseEnabled = pcall(function() return settings():GetFFlag("NewPurchaseScript") end)
local isNewPurchaseScript = newPurchaseSuccess and newPurchaseEnabled
if isNewPurchaseScript then
	scriptContext:AddCoreScriptLocal("CoreScripts/PurchasePromptScript2", screenGui)
else
	scriptContext:AddCoreScriptLocal("CoreScripts/PurchasePromptScript", screenGui)
end
-- Health Script
if not useTopBar then
	scriptContext:AddCoreScriptLocal("CoreScripts/HealthScript", screenGui)
end

local playerListSuccess, playerListFlagValue = pcall(function() return settings():GetFFlag("NewPlayerListScript") end)
local isNotSmallTouchDevice = not touchEnabled or Game:GetService("GuiService"):GetScreenResolution().Y >= 500
-- New Player List
if playerListSuccess and playerListFlagValue == true then
	if useTopBar then
		spawn(function() require(RobloxGui.Modules.PlayerlistModule) end)
	elseif isNotSmallTouchDevice then
		scriptContext:AddCoreScriptLocal("CoreScripts/PlayerListScript2", screenGui)
	end
elseif isNotSmallTouchDevice then
	scriptContext:AddCoreScriptLocal("CoreScripts/PlayerListScript", screenGui)
end

do -- Backpack!
	spawn(function() require(RobloxGui.Modules.BackpackScript) end)
end

local luaVehicleHudSuccess, luaVehicleHudEnabled = pcall(function() return settings():GetFFlag('NewVehicleHud') end)
if useTopBar and (luaVehicleHudSuccess and luaVehicleHudEnabled == true) then
	scriptContext:AddCoreScriptLocal("CoreScripts/VehicleHud", screenGui)
end

local gamepadSupportSuccess, gamepadSupportFlagValue = pcall(function() return settings():GetFFlag("TopbarGamepadSupport") end)
if gamepadSupportSuccess and gamepadSupportFlagValue then
	scriptContext:AddCoreScriptLocal("CoreScripts/GamepadMenu", screenGui)
end

if touchEnabled then -- touch devices don't use same control frame
	-- only used for touch device button generation
	scriptContext:AddCoreScriptLocal("CoreScripts/ContextActionTouch", screenGui)

	screenGui:WaitForChild("ControlFrame")
	screenGui.ControlFrame:WaitForChild("BottomLeftControl")
	screenGui.ControlFrame.BottomLeftControl.Visible = false
end
