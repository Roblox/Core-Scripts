-- a couple neccessary functions
local function waitForChild(instance, name)
	while not instance:FindFirstChild(name) do
		instance.ChildAdded:wait()
	end
end
local function waitForProperty(instance, prop)
	while not instance[prop] do
		instance.Changed:wait()
	end
end




function securityCheck()
	local allowedUserIds = {--[[game.CreatorId,]]7210880}

	local canUsePanel = false
	local localUserId = game.Players.LocalPlayer.userId
	for i = 1, #allowedUserIds do
		if localUserId == allowedUserIds[i] then
			canUsePanel = true
			break
		end
	end

	if not canUsePanel then
		script:remove()
	end
end



function createGui()
	local adminStatsFrame = Instance.new("Frame")
	adminStatsFrame.RobloxLocked = true
	adminStatsFrame.Name = "AdminStatsFrame"
	adminStatsFrame.Active = true
	adminStatsFrame.Draggable = true
	adminStatsFrame.Position = UDim2.new(0.2,20,0,0)
	adminStatsFrame.Size = UDim2.new(0.6,-40,1,0)
	adminStatsFrame.Style = Enum.FrameStyle.RobloxRound
	adminStatsFrame.Parent = script.Parent

		-- AdminStatsFrame Children
		local adminStatsTextLabel = Instance.new("TextLabel")
		adminStatsTextLabel.RobloxLocked = true
		adminStatsTextLabel.Name = "AdminStatsTextLabel"
		adminStatsTextLabel.BackgroundTransparency = 1
		adminStatsTextLabel.Font = Enum.Font.ArialBold
		adminStatsTextLabel.FontSize = Enum.FontSize.Size24
		adminStatsTextLabel.Size = UDim2.new(1,0,0,24)
		adminStatsTextLabel.Text = "Place Console"
		adminStatsTextLabel.TextColor3 = Color3.new(1,1,1)
		adminStatsTextLabel.TextYAlignment = Enum.TextYAlignment.Center
		adminStatsTextLabel.Parent = adminStatsFrame

		local errorPanel = Instance.new("Frame")
		errorPanel.RobloxLocked = true
		errorPanel.Name = "ErrorPanel"
		errorPanel.Position = UDim2.new(0,0,0.5,0)
		errorPanel.Size = UDim2.new(1,0,0.5,0)
		errorPanel.Style = Enum.FrameStyle.RobloxRound
		errorPanel.Parent = adminStatsFrame

			-- ErrorPanel Children
			local textPanel = Instance.new("Frame")
			textPanel.RobloxLocked = true
			textPanel.Name = "TextPanel"
			textPanel.Position = UDim2.new(0,0,0,18)
			textPanel.Size = UDim2.new(1,0,1,-18)
			textPanel.BackgroundTransparency = 1
			textPanel.Parent = errorPanel

			local errorPanelTextLabel = Instance.new("TextLabel")
			errorPanelTextLabel.RobloxLocked = true
			errorPanelTextLabel.Name = "ErrorPanelTextLabel"
			errorPanelTextLabel.Font = Enum.Font.ArialBold
			errorPanelTextLabel.FontSize = Enum.FontSize.Size18
			errorPanelTextLabel.Size = UDim2.new(1,0,0,18)
			errorPanelTextLabel.BackgroundTransparency = 1
			errorPanelTextLabel.TextColor3 = Color3.new(1,1,1)
			errorPanelTextLabel.Text = "Lua Errors"
			errorPanelTextLabel.Parent = errorPanel

			local sampleError = Instance.new("TextLabel")
			sampleError.RobloxLocked = true
			sampleError.Name = "SampleError"
			sampleError.Font = Enum.Font.Arial
			sampleError.FontSize = Enum.FontSize.Size12
			sampleError.Size = UDim2.new(1,0,0,12)
			sampleError.BackgroundTransparency = 0.5
			sampleError.TextColor3 = Color3.new(1,1,1)
			sampleError.Text = "Thu May 19 12:37:09 2011 - Players.Player.Backpack.StamperTool.GuiScript:1199: attempt to index field '?' (a nil value)"
			sampleError.TextWrap = true
			sampleError.TextXAlignment = Enum.TextXAlignment.Left
			sampleError.TextYAlignment = Enum.TextYAlignment.Top
			sampleError.Visible = false
			sampleError.Parent = errorPanel

		local playerStatsFrame = Instance.new("Frame")
		playerStatsFrame.RobloxLocked = true
		playerStatsFrame.Name = "PlayerStatsFrame"
		playerStatsFrame.BackgroundTransparency = 1
		playerStatsFrame.Position = UDim2.new(0,0,0,24)
		playerStatsFrame.Size = UDim2.new(0,200,0,100)
		playerStatsFrame.Style = Enum.FrameStyle.RobloxRound
		playerStatsFrame.Parent = adminStatsFrame

		local playerStatsTextInfo = Instance.new("TextLabel")
		playerStatsTextInfo.Name = "PlayerStatsTextInfo"
		playerStatsTextInfo.BackgroundTransparency = 1
		playerStatsTextInfo.Font = Enum.Font.ArialBold
		playerStatsTextInfo.FontSize = Enum.FontSize.Size14
		playerStatsTextInfo.Size = UDim2.new(1,0,1,0)
		playerStatsTextInfo.Text = ""
		playerStatsTextInfo.TextColor3 = Color3.new(1,1,1)
		playerStatsTextInfo.TextYAlignment = Enum.TextYAlignment.Top

		local smallFrame = Instance.new("Frame")
		smallFrame.BackgroundTransparency = 1
		smallFrame.Size = UDim2.new(1,0,0,14)

			-- PlayerStatsFrame Children
			local avgPlayerTimeFrame = smallFrame:clone()
			avgPlayerTimeFrame.RobloxLocked = true
			avgPlayerTimeFrame.Name = "AvgPlayerTimeFrame"
			avgPlayerTimeFrame.Position = UDim2.new(0,0,0,46)
			local newTextInfo = playerStatsTextInfo:clone()
			newTextInfo.RobloxLocked = true
			newTextInfo.Text = "Avg. Play Time: 0"
			newTextInfo.Parent = avgPlayerTimeFrame
			avgPlayerTimeFrame.Parent = playerStatsFrame

			local joinFrame = smallFrame:clone()
			joinFrame.RobloxLocked = true
			joinFrame.Name = "JoinFrame"
			joinFrame.Position = UDim2.new(0,0,0,18)
			local newTextInfo = playerStatsTextInfo:clone()
			newTextInfo.RobloxLocked = true
			newTextInfo.Text = "# of Joins: 0"
			newTextInfo.Parent = joinFrame
			joinFrame.Parent = playerStatsFrame

			local leaveFrame = smallFrame:clone()
			leaveFrame.RobloxLocked = true
			leaveFrame.Name = "LeaveFrame"
			leaveFrame.Position = UDim2.new(0,0,0,32)
			local newTextInfo = playerStatsTextInfo:clone()
			newTextInfo.RobloxLocked = true
			newTextInfo.Text = "# of Leaves: 0"
			newTextInfo.Parent = leaveFrame
			leaveFrame.Parent = playerStatsFrame
			
			local uniqueVisitorsFrame = smallFrame:clone()
			uniqueVisitorsFrame.RobloxLocked = true
			uniqueVisitorsFrame.Name = "UniqueVisitorsFrame"
			uniqueVisitorsFrame.Position = UDim2.new(0,0,0,60)
			local newTextInfo = playerStatsTextInfo:clone()
			newTextInfo.RobloxLocked = true
			newTextInfo.Text = "# of Unique Visits: 0"
			newTextInfo.Parent = uniqueVisitorsFrame
			uniqueVisitorsFrame.Parent = playerStatsFrame
			
			local textHeader = playerStatsTextInfo:clone()
			textHeader.Name = "PlayerStatsTextLabel"
			textHeader.RobloxLocked = true
			textHeader.FontSize = Enum.FontSize.Size18
			textHeader.Size = UDim2.new(1,0,0,18)
			textHeader.Text = "Player Stats"
			textHeader.TextYAlignment = Enum.TextYAlignment.Center
			textHeader.Parent = playerStatsFrame

		-- Script Stats Frame
		local scriptStatsFrame = playerStatsFrame:clone()
		scriptStatsFrame.RobloxLocked = true
		scriptStatsFrame.Name = "ScriptStatsFrame"
		scriptStatsFrame.Position = UDim2.new(0,0,0,126)
		scriptStatsFrame.PlayerStatsTextLabel.Name = "ScriptStatsTextLabel"
		scriptStatsFrame.ScriptStatsTextLabel.Text = "Lua Stats"
		scriptStatsFrame.JoinFrame.Name = "ScriptErrorsFrame"
		scriptStatsFrame.ScriptErrorsFrame.PlayerStatsTextInfo.Name = "ScriptErrorsTextInfo"
		scriptStatsFrame.ScriptErrorsFrame.ScriptErrorsTextInfo.Text = "# of Lua Errors: 0"
		scriptStatsFrame.LeaveFrame.Name = "ScriptWarningFrame"
		scriptStatsFrame.ScriptWarningFrame.PlayerStatsTextInfo.Name = "ScriptWarningTextInfo"
		scriptStatsFrame.ScriptWarningFrame.ScriptWarningTextInfo.Text = "# of Lua Warnings: 0"
		scriptStatsFrame.AvgPlayerTimeFrame.Name = "ScriptsRunningFrame"
		scriptStatsFrame.ScriptsRunningFrame.PlayerStatsTextInfo.Name  = "ScriptsRunningInfo"
		scriptStatsFrame.ScriptsRunningFrame.ScriptsRunningInfo.Text = "# Scripts Running: 0"
		scriptStatsFrame.UniqueVisitorsFrame:remove()
		scriptStatsFrame.Parent = adminStatsFrame


		-- UptimeFrame
		local upTimeFrame = Instance.new("Frame")
		upTimeFrame.RobloxLocked = true
		upTimeFrame.Name = "UptimeFrame"
		upTimeFrame.BackgroundTransparency = 1
		upTimeFrame.Position = UDim2.new(1,-200,0,24)
		upTimeFrame.Size = UDim2.new(0,200,0,100)	
		upTimeFrame.Style = Enum.FrameStyle.RobloxRound
		upTimeFrame.Parent = adminStatsFrame

			-- UptimeFrame Children
			local secondsUpTimeTextInfo = Instance.new("TextLabel")
			secondsUpTimeTextInfo.RobloxLocked = true
			secondsUpTimeTextInfo.Name = "SecondsUptimeTextInfo"
			secondsUpTimeTextInfo.Font = Enum.Font.ArialBold
			secondsUpTimeTextInfo.FontSize = Enum.FontSize.Size14
			secondsUpTimeTextInfo.Position = UDim2.new(0,0,0.5,18)
			secondsUpTimeTextInfo.Size = UDim2.new(1,0,0.5,-18)
			secondsUpTimeTextInfo.Text = "0 Total Seconds"
			secondsUpTimeTextInfo.BackgroundTransparency = 1
			secondsUpTimeTextInfo.TextColor3 = Color3.new(1,1,1)
			secondsUpTimeTextInfo.TextYAlignment = Enum.TextYAlignment.Top
			secondsUpTimeTextInfo.Parent = upTimeFrame

			local uptimeTextInfo = secondsUpTimeTextInfo:clone()
			uptimeTextInfo.RobloxLocked = true
			uptimeTextInfo.Name = "UptimeTextInfo"
			uptimeTextInfo.Position = UDim2.new(0,0,0,18)
			uptimeTextInfo.Size = UDim2.new(1,0,0.5,0)
			uptimeTextInfo.TextWrap = true
			uptimeTextInfo.Text = "0 Days, 0 Hours, 0 Minutes, 0 Seconds"
			uptimeTextInfo.Parent = upTimeFrame

			local upTimeTextLabel = uptimeTextInfo:clone()
			upTimeTextLabel.RobloxLocked = true
			upTimeTextLabel.Name = "UptimeTextLabel"
			upTimeTextLabel.FontSize = Enum.FontSize.Size18
			upTimeTextLabel.Size = UDim2.new(1,0,0,18)
			upTimeTextLabel.Position = UDim2.new(0,0,0,0)
			upTimeTextLabel.Text = "Instance Uptime"
			upTimeTextLabel.TextYAlignment = Enum.TextYAlignment.Center
			upTimeTextLabel.Parent = upTimeFrame
end



-- functions
function initLocals()
	-- Top Gui Layer
	adminGui = script.Parent
	adminFrame = adminGui.AdminStatsFrame

	-- Second Gui Layer
	upTimeFrame = adminFrame.UptimeFrame
	errorFrame = adminFrame.ErrorPanel
	playerStatsFrame = adminFrame.PlayerStatsFrame
	scriptStatsFrame = adminFrame.ScriptStatsFrame

	-- UptimeFrame Children
	upTimeFormattedText = upTimeFrame.UptimeTextInfo
	upTimeSecondsText = upTimeFrame.SecondsUptimeTextInfo

	-- PlayerStatsFrame Children
	avgPlayTimeText = playerStatsFrame.AvgPlayerTimeFrame.PlayerStatsTextInfo
	joinText = playerStatsFrame.JoinFrame.PlayerStatsTextInfo
	leaveText = playerStatsFrame.LeaveFrame.PlayerStatsTextInfo
	uniqueVisitorText = playerStatsFrame.UniqueVisitorsFrame.PlayerStatsTextInfo


	uniqueUserIds = {}
	playTimes = {}

	avgPlayTime = 0
	placeVisits = 0
	placeLeaves = 0
end

function updateUptime()
	local currentTime = game.Workspace.DistributedGameTime
	
	upTimeSecondsText.Text = tostring(math.floor(currentTime)) .. " Total Seconds"
	
	local days = math.floor(currentTime/86400)
	currentTime = currentTime - (days * 86400)

	local hours = math.floor(currentTime/3600)
	currentTime = currentTime - (hours * 3600)
	
	local minutes = math.floor(currentTime/60)
	currentTime = currentTime - (minutes * 60)
	
	currentTime = math.floor(currentTime)

	upTimeFormattedText.Text = tostring(days) .. " Days, " .. tostring(hours) .. " Hours, " .. tostring(minutes) .. " Minutes, " .. tostring(currentTime) .. (" Seconds") 
end


function playerJoined(addedPlayer)
	placeVisits = placeVisits + 1
	joinText.Text = "# of Joins: " .. tostring(placeVisits)
	if uniqueUserIds[addedPlayer] == nil then
		uniqueUserIds[addedPlayer] = addedPlayer.userId
		uniqueVisitorText.Text = "#of Unique Visits: " .. tostring(#uniqueUserIds)
	end

	playTimes[addedPlayer] = game.Workspace.DistributedGameTime
end

function recalculateAvgPlayTime(removedPlayer)
	if playTimes[removedPlayer] then
		local playerPlayTime = game.Workspace.DistributedGameTime - playTimes[removedPlayer]
		avgPlayTime = ( ((placesLeaves - 1)/placeLeaves) * avgPlayTime ) + ( (1/placeLeaves) * playerPlayTime )
		avgPlayTimeText.Text = "Avg. Play Time: " .. tostring(math.floor(avgPlayTime))
	end
end

function playerLeft(removedPlayer)
	placeLeaves = placeLeaves + 1
	leaveText.Text = "# of Leaves: " .. tostring(placeLeaves)

	recalculateAvgPlayTime(removedPlayer)
end


function uptimeLoop()
	while true do
		updateUptime()
		wait(1)
	end
end

function playerAddedFunction(player)
	if player == game.Players.LocalPlayer then
		securityCheck()
		createGui()
		initLocals()
		adminFrame.Visible = true
		uptimeLoop()
	end	
	playerJoined(addedPlayer)
end

-- Script Start

-- Check to see if we already have players
local playersChildren = game.Players:GetChildren()
for i = 1, #playersChildren do
	if playersChildren[i]:IsA("Player") then
		playerAddedFunction(playersChildren[i])
	end
end

-- Listen for players now
game.Players.PlayerAdded:connect(function(addedPlayer) playerAddedFunction(addedPlayer) end)
game.Players.PlayerRemoving:connect(function(removedPlayer) playerLeft(removedPlayer) end)