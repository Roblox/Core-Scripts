local FORCE_USE_NEW_CHAT = false


local CoreGuiService = game:GetService("CoreGui")
local RobloxGui = CoreGuiService:WaitForChild("RobloxGui")

local StarterGui = game:GetService("StarterGui")

local Util = {}
do
	function Util.Signal()
		local sig = {}

		local mSignaler = Instance.new('BindableEvent')

		local mArgData = nil
		local mArgDataCount = nil

		function sig:fire(...)
			mArgData = {...}
			mArgDataCount = select('#', ...)
			mSignaler:Fire()
		end

		function sig:connect(f)
			if not f then error("connect(nil)", 2) end
			return mSignaler.Event:connect(function()
				f(unpack(mArgData, 1, mArgDataCount))
			end)
		end

		function sig:wait()
			mSignaler.Event:wait()
			assert(mArgData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
			return unpack(mArgData, 1, mArgDataCount)
		end

		return sig
	end
end


local moduleApiTable = {}
do
	local pcallSuccess, flagEnabled = pcall(function() return settings():GetFFlag("UseNewChat") end)
	local useNewChat = pcallSuccess and flagEnabled
	if (useNewChat or FORCE_USE_NEW_CHAT) then
		local CommunicationsFolderParent = game:GetService("ReplicatedStorage")

		local CoreGuiCommunicationsFolder = Instance.new("Folder")
		local SetCoreFolder = Instance.new("Folder", CoreGuiCommunicationsFolder)
		local GetCoreFolder = Instance.new("Folder", CoreGuiCommunicationsFolder)
		local ChatWindowFolder = Instance.new("Folder", CoreGuiCommunicationsFolder)

		CoreGuiCommunicationsFolder.Name = "CoreGuiCommunications"
		SetCoreFolder.Name = "SetCore"
		GetCoreFolder.Name = "GetCore"
		ChatWindowFolder.Name = "ChatWindow"

		CoreGuiCommunicationsFolder.Archivable = false


		local function RegisterSetCoreEvent(name)
			Instance.new("BindableEvent", SetCoreFolder).Name = name
			StarterGui:RegisterSetCore(name,
				function(...)

					if (SetCoreFolder) then
						local find = SetCoreFolder:FindFirstChild(name)
						if (find and find:IsA("BindableEvent")) then
							find:Fire(...)
						end
					end

				end)
		end

		local function RegisterGetCoreFunction(name)
			Instance.new("BindableFunction", GetCoreFolder).Name = name
			StarterGui:RegisterGetCore(name,
				function(...)
					local ret = nil

					if (GetCoreFolder) then
						local find = GetCoreFolder:FindFirstChild(name)
						if (find and find:IsA("BindableFunction")) then
							ret = find:Invoke(...)
						end
					end


					return ret
				end)
		end

		RegisterSetCoreEvent("ChatMakeSystemMessage")
		RegisterSetCoreEvent("ChatWindowPosition")
		RegisterSetCoreEvent("ChatWindowSize")

		RegisterGetCoreFunction("ChatWindowPosition")
		RegisterGetCoreFunction("ChatWindowSize")

		RegisterSetCoreEvent("ChatBarDisabled")
		RegisterGetCoreFunction("ChatBarDisabled")


		Instance.new("BindableEvent", ChatWindowFolder).Name = "ToggleVisibility"
		Instance.new("BindableEvent", ChatWindowFolder).Name = "SetVisible"
		Instance.new("BindableEvent", ChatWindowFolder).Name = "FocusChatBar"
		Instance.new("BindableFunction", ChatWindowFolder).Name = "GetVisibility"
		Instance.new("BindableFunction", ChatWindowFolder).Name = "GetMessageCount"
		Instance.new("BindableEvent", ChatWindowFolder).Name = "TopbarEnabledChanged"
		Instance.new("BindableFunction", ChatWindowFolder).Name = "IsFocused"

		Instance.new("BindableEvent", ChatWindowFolder).Name = "ChatBarFocusChanged"
		Instance.new("BindableEvent", ChatWindowFolder).Name = "VisibilityStateChanged"
		Instance.new("BindableEvent", ChatWindowFolder).Name = "MessagesChanged"

		Instance.new("BindableEvent", ChatWindowFolder).Name = "MessagePosted"
		Instance.new("BindableEvent", ChatWindowFolder).Name = "CoreGuiChanged"


		ChatWindowFolder.GetVisibility.OnInvoke = function() return false end
		ChatWindowFolder.GetMessageCount.OnInvoke = function() return 0 end
		ChatWindowFolder.IsFocused.OnInvoke = function() return false end



		local Players = game:GetService("Players")
		Players.PlayerAdded:connect(function(player)
			if (player == Players.LocalPlayer) then
				CoreGuiCommunicationsFolder.Parent =  Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("ChatScript")
			end
		end)

		if (Players.LocalPlayer) then
			CoreGuiCommunicationsFolder.Parent =  Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("ChatScript")
		end

		function moduleApiTable:ToggleVisibility()
			pcall(function()
				ChatWindowFolder.ToggleVisibility:Fire()
			end)
		end

		function moduleApiTable:SetVisible(visible)
			pcall(function()
				ChatWindowFolder.SetVisible:Fire(visible)
			end)
		end

		function moduleApiTable:FocusChatBar()
			pcall(function()
				ChatWindowFolder.FocusChatBar:Fire()
			end)
		end

		function moduleApiTable:GetVisibility()
			local ret = false

			pcall(function()
				ret = ChatWindowFolder.GetVisibility:Invoke()
			end)

			return ret
		end

		function moduleApiTable:GetMessageCount()
			local ret = 0

			pcall(function()
				ret = ChatWindowFolder.GetMessageCount:Invoke()
			end)

			return ret
		end

		function moduleApiTable:TopbarEnabledChanged(enabled)
			pcall(function()
				ChatWindowFolder.TopbarEnabledChanged:Fire(enabled)
			end)
		end

		function moduleApiTable:IsFocused(useWasFocused)
			local ret = false

			pcall(function()
				ret = ChatWindowFolder.IsFocused:Invoke(useWasFocused)
			end)

			return ret
		end

		moduleApiTable.ChatBarFocusChanged = Util.Signal()
		moduleApiTable.VisibilityStateChanged = Util.Signal()
		moduleApiTable.MessagesChanged = Util.Signal()


		ChatWindowFolder.ChatBarFocusChanged.Event:connect(function(...) moduleApiTable.ChatBarFocusChanged:fire(...) end)
		ChatWindowFolder.VisibilityStateChanged.Event:connect(function(...) moduleApiTable.VisibilityStateChanged:fire(...) end)
		ChatWindowFolder.MessagesChanged.Event:connect(function(...) moduleApiTable.MessagesChanged:fire(...) end)


		ChatWindowFolder.MessagePosted.Event:connect(function(message) Players:Chat(message) end)
		StarterGui.CoreGuiChangedSignal:connect(function(coreGuiType, enabled)
			pcall(function() ChatWindowFolder.CoreGuiChanged:Fire(coreGuiType, enabled) end)
		end)

	else
		moduleApiTable = require(RobloxGui.Modules.Chat)

	end
end

return moduleApiTable
