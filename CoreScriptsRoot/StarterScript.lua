-- Creates all neccessary scripts for the gui on initial load, everything except build tools
-- Created by Ben T. 10/29/10
-- Please note that these are loaded in a specific order to diminish errors/perceived load time by user
local scriptContext = game:GetService("ScriptContext")
local touchEnabled = game:GetService("UserInputService").TouchEnabled

Game:GetService("CoreGui"):WaitForChild("RobloxGui")
local screenGui = Game:GetService("CoreGui"):FindFirstChild("RobloxGui")

-- SettingsScript
local luaControlsSuccess, luaControlsFlagValue = pcall(function() return settings():GetFFlag("UsePlayerScripts") end)
local newSettingsSuccess, newSettingsFlagValue = pcall(function() return settings():GetFFlag("NewMenuSettingsScript") end)
local useNewSettings = (luaControlsSuccess and luaControlsFlagValue) and (newSettingsSuccess and newSettingsFlagValue)
if useNewSettings then
	scriptContext:AddCoreScriptLocal("CoreScripts/Settings2", screenGui)
else
	scriptContext:AddCoreScriptLocal("CoreScripts/Settings", screenGui)
end

if not touchEnabled then
	-- ToolTipper  (creates tool tips for gui)
	scriptContext:AddCoreScriptLocal("CoreScripts/ToolTip", screenGui)
else
	if not luaControlsSuccess or luaControlsFlagValue == false then
		scriptContext:AddCoreScriptLocal("CoreScripts/TouchControls", screenGui)
	end
end

-- MainBotChatScript
scriptContext:AddCoreScriptLocal("CoreScripts/MainBotChatScript", screenGui)

-- Developer Console Script
scriptContext:AddCoreScriptLocal("CoreScripts/DeveloperConsole", screenGui)

-- Popup Script
scriptContext:AddCoreScriptLocal("CoreScripts/PopupScript", screenGui)
-- Friend Notification Script (probably can use this script to expand out to other notifications)
scriptContext:AddCoreScriptLocal("CoreScripts/NotificationScript", screenGui)
-- Chat script
local success, chatFlagValue = pcall(function() return settings():GetFFlag("NewLuaChatScript") end)
if success and chatFlagValue == true then
	scriptContext:AddCoreScriptLocal("CoreScripts/ChatScript2", screenGui)
else
	scriptContext:AddCoreScriptLocal("CoreScripts/ChatScript", screenGui)
end
-- Purchase Prompt Script
scriptContext:AddCoreScriptLocal("CoreScripts/PurchasePromptScript", screenGui)
-- Health Script
scriptContext:AddCoreScriptLocal("CoreScripts/HealthScript", screenGui)

local playerListSuccess, playerListFlagValue = pcall(function() return settings():GetFFlag("NewPlayerListScript") end)
if not touchEnabled then
	-- New Player List
	if playerListSuccess and playerListFlagValue == true then
		scriptContext:AddCoreScriptLocal("CoreScripts/PlayerListScript2", screenGui)
	else
		scriptContext:AddCoreScriptLocal("CoreScripts/PlayerListScript", screenGui)
	end
elseif Game:GetService("GuiService"):GetScreenResolution().Y >= 500 then
	-- New Player List
	if playerListSuccess and playerListFlagValue == true then
		scriptContext:AddCoreScriptLocal("CoreScripts/PlayerListScript2", screenGui)
	else
		scriptContext:AddCoreScriptLocal("CoreScripts/PlayerListScript", screenGui)
	end
end

do -- Backpack!
	local useNewBackpack = false
	
	local success, errorMsg = pcall(function()
		useNewBackpack = settings():GetFFlag("NewBackpackScript")
	end)
	
	if useNewBackpack then
		scriptContext:AddCoreScriptLocal("CoreScripts/BackpackScript", screenGui)
	else
		-- Backpack Builder, creates most of the backpack gui
		scriptContext:AddCoreScriptLocal("CoreScripts/BackpackScripts/BackpackBuilder", screenGui)
		
		screenGui:WaitForChild("CurrentLoadout")
		screenGui:WaitForChild("Backpack")
		local Backpack = screenGui.Backpack
		
		-- Manager handles all big backpack state changes, other scripts subscribe to this and do things accordingly
		scriptContext:AddCoreScriptLocal("CoreScripts/BackpackScripts/BackpackManager", Backpack)
		
		-- Backpack Gear (handles all backpack gear tab stuff)
		scriptContext:AddCoreScriptLocal("CoreScripts/BackpackScripts/BackpackGear", Backpack)
		-- Loadout Script, used for gear hotkeys
		scriptContext:AddCoreScriptLocal("CoreScripts/BackpackScripts/LoadoutScript", screenGui.CurrentLoadout)
	end
end

if touchEnabled then -- touch devices don't use same control frame
	-- only used for touch device button generation
	scriptContext:AddCoreScriptLocal("CoreScripts/ContextActionTouch", screenGui)

	screenGui:WaitForChild("ControlFrame")
	screenGui.ControlFrame:WaitForChild("BottomLeftControl")
	screenGui.ControlFrame.BottomLeftControl.Visible = false
end