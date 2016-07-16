local source = [[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Chat = require(script:WaitForChild("NewChat"))

local CoreGuiCommunicationsFolder = ReplicatedStorage:WaitForChild("CoreGuiCommunications")
local ChatWindowFolder = CoreGuiCommunicationsFolder:WaitForChild("ChatWindow")
local SetCoreFolder = CoreGuiCommunicationsFolder:WaitForChild("SetCore")
local GetCoreFolder = CoreGuiCommunicationsFolder:WaitForChild("GetCore")

--// Connection functions
local function ConnectEvent(name)
	if (ChatWindowFolder) then
		local find = ChatWindowFolder:FindFirstChild(name)
		if (find and find:IsA("BindableEvent")) then
			find.Event:connect(function(...)
				Chat[name](Chat, ...)
			end)
		end
	end
end

local function ConnectFunction(name)
	if (ChatWindowFolder) then
		local find = ChatWindowFolder:FindFirstChild(name)
		if (find and find:IsA("BindableFunction")) then
			find.OnInvoke = (function(...)
				return Chat[name](Chat, ...)
			end)
		end
	end
end

local function ReverseConnectEvent(name)
	if (Chat[name]) then
		Chat[name]:connect(function(...)
			if (ChatWindowFolder) then
				local find = ChatWindowFolder:FindFirstChild(name)
				if (find and find:IsA("BindableEvent")) then
					find:Fire(...)
				end
			end
		end)
	end
end

local function ConnectSignal(name)
	if (ChatWindowFolder) then
		local find = ChatWindowFolder:FindFirstChild(name)
		if (find and find:IsA("BindableEvent")) then
			find.Event:connect(function(...)
				Chat[name]:fire(...)
			end)
		end
	end
end

local function ConnectSetCore(name)
	if (SetCoreFolder) then
		local find = SetCoreFolder:FindFirstChild(name)
		if (find and find:IsA("BindableEvent")) then
			find.Event:connect(function(...)
				Chat["e"..name]:fire(...)
			end)
		end
	end
end

local function ConnectGetCore(name)
	if (GetCoreFolder) then
		local find = GetCoreFolder:FindFirstChild(name)
		if (find and find:IsA("BindableFunction")) then
			find.OnInvoke = (function(...)
				return Chat["f"..name](...)
			end)
		end
	end
end

--// Do connections
ConnectEvent("ToggleVisibility")
ConnectEvent("SetVisible")
ConnectEvent("FocusChatBar")
ConnectFunction("GetVisibility")
ConnectFunction("GetMessageCount")
ConnectEvent("TopbarEnabledChanged")
ConnectFunction("IsFocused")

ReverseConnectEvent("ChatBarFocusChanged")
ReverseConnectEvent("VisibilityStateChanged")
ReverseConnectEvent("MessagesChanged")
ReverseConnectEvent("MessagePosted")

ConnectSignal("CoreGuiChanged")

ConnectSetCore("ChatMakeSystemMessage")
ConnectSetCore("ChatWindowPosition")
ConnectSetCore("ChatWindowSize")
ConnectGetCore("ChatWindowPosition")
ConnectGetCore("ChatWindowSize")
ConnectSetCore("ChatBarDisabled")
ConnectGetCore("ChatBarDisabled")

]]

local generated = Instance.new("LocalScript")
generated.Disabled = true
generated.Name = "Generated"
generated.Source = source
generated.Parent = script