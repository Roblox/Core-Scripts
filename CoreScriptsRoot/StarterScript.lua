-- Creates all neccessary scripts for the gui on initial load, everything except build tools
-- Created by Ben T. 10/29/10
-- Please note that these are loaded in a specific order to diminish errors/perceived load time by user

local scriptContext = game:GetService("ScriptContext")
local touchEnabled = game:GetService("UserInputService").TouchEnabled

local RobloxGui = game:GetService("CoreGui"):WaitForChild("RobloxGui")

local soundFolder = Instance.new("Folder")
soundFolder.Name = "Sounds"
soundFolder.Parent = RobloxGui

-- TopBar
scriptContext:AddCoreScriptLocal("CoreScripts/Topbar", RobloxGui)

-- SettingsScript
local luaControlsSuccess, luaControlsFlagValue = pcall(function() return settings():GetFFlag("UseLuaCameraAndControl") end)

local vrKeyboardSuccess, vrKeyboardFlagValue = pcall(function() return settings():GetFFlag("UseVRKeyboardInLua") end)
local useVRKeyboard = (vrKeyboardSuccess and vrKeyboardFlagValue == true)

-- MainBotChatScript (the Lua part of Dialogs)
scriptContext:AddCoreScriptLocal("CoreScripts/MainBotChatScript2", RobloxGui)

-- Developer Console Script
scriptContext:AddCoreScriptLocal("CoreScripts/DeveloperConsole", RobloxGui)

-- In-game notifications script
scriptContext:AddCoreScriptLocal("CoreScripts/NotificationScript2", RobloxGui)

-- Chat script
spawn(function() require(RobloxGui.Modules.Chat) end)
spawn(function() require(RobloxGui.Modules.PlayerlistModule) end)

scriptContext:AddCoreScriptLocal("CoreScripts/BubbleChat", RobloxGui)

-- Purchase Prompt Script
scriptContext:AddCoreScriptLocal("CoreScripts/PurchasePromptScript2", RobloxGui)

-- Backpack!
spawn(function() require(RobloxGui.Modules.BackpackScript) end)

scriptContext:AddCoreScriptLocal("CoreScripts/VehicleHud", RobloxGui)

scriptContext:AddCoreScriptLocal("CoreScripts/GamepadMenu", RobloxGui)

if touchEnabled then -- touch devices don't use same control frame
	-- only used for touch device button generation
	scriptContext:AddCoreScriptLocal("CoreScripts/ContextActionTouch", RobloxGui)

	RobloxGui:WaitForChild("ControlFrame")
	RobloxGui.ControlFrame:WaitForChild("BottomLeftControl")
	RobloxGui.ControlFrame.BottomLeftControl.Visible = false
end

if useVRKeyboard then
	require(RobloxGui.Modules.VR.VirtualKeyboard)
end

