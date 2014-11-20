-- Personal Server Script

-----------------
--| Constants |--
-----------------

local CHANGES_PER_PLAYER = 100 -- Saving also occurs every time the number of edits reaches this number times the number of players
local SAVE_CHECK_INTERVAL = 1800 -- should be set in seconds, this is how long we wait to force a save, as long as at least one change has been made
local MIN_SAVE_TIME = 900 -- At least this many seconds will pass before saving again

-----------------
--| Variables |--
-----------------

local ContentProviderService = Game:GetService('ContentProvider')
local PlayersService = Game:GetService('Players')
local RunService = Game:GetService("RunService")

local StartingPlayerRanks = {}
local RbxUtil = nil

local LastSaveTime = 0
local ChangeCount = 0
local TryingToSave = false
local NumberOfChangesBeforeSaveAbsolute = CHANGES_PER_PLAYER
local GameRunning = true
local WaitingToSave = false

local PlaceId = Game.PlaceId
local Url = ContentProviderService.BaseUrl
local UrlBase = Url:match('^http://www\.(.-)/?$') -- Turns "http://www.gametest1.robloxlabs.com/" into "gametest1.robloxlabs.com"
local ApiProxyUrl = 'https://api.' ..  UrlBase

-----------------
--| Functions |--
-----------------

function GetRbxUtil()
	if not RbxUtil then
		RbxUtil = LoadLibrary("RbxUtility")
	end
	return RbxUtil
end

-- Checks the full hierarchy of an instance for archivability
local function IsArchivable(instance)
	if instance == Workspace then
		return true
	elseif not instance.Archivable then
		return false
	else
		return IsArchivable(instance.Parent)
	end
end

local function UpdateSaveOnChangeAmount()
	local players = PlayersService:GetPlayers()
	NumberOfChangesBeforeSaveAbsolute = #players * CHANGES_PER_PLAYER
end

local function OnPlayerAdded(player)
	if player:IsA('Player') then

		local getRankUrl = ApiProxyUrl .. '/RoleSets/GetRoleSetForUser?placeId=' .. tostring(PlaceId) .. '&userId=' .. tostring(player.userId)
		local serverRankTable = nil
		pcall(function()
			serverRankTable = GetRbxUtil().DecodeJSON(Game:HttpGetAsync(getRankUrl))
		end)

		local playerRank = 0
		if serverRankTable and type(serverRankTable) == 'table' then
			for k, v in pairs(serverRankTable) do
				if k == "data" then
					if v["Rank"] then
						playerRank = v["Rank"]
					end
				end
			end
		end

		player.PersonalServerRank = playerRank
		StartingPlayerRanks[player] = playerRank

		UpdateSaveOnChangeAmount()
	end
end

local function OnPlayerRemoved(player)
	if player:IsA('Player') then
		UpdateSaveOnChangeAmount()

		if StartingPlayerRanks[player] then
			local playerRank = player.PersonalServerRank
			if StartingPlayerRanks[player] ~= playerRank then -- Don't need to make web call if rank is the same
				local setRankUrl = ApiProxyUrl .. '/RoleSets/PrivilegedSetUserRoleSetRank?placeId=' .. tostring(PlaceId) .. '&userId=' .. tostring(player.userId) .. '&newRank=' .. tostring(playerRank)
				ypcall(function() Game:HttpPostAsync(setRankUrl, 'SetPersonalServerRank') end)
			end
			StartingPlayerRanks[player] = nil
		end
	end
end

local function DoSave()
	if GameRunning then
		ChangeCount = 0
		LastSaveTime = tick()
		Game:ServerSave()
	end
end

local function TrySave()
	if not TryingToSave then
		TryingToSave = true

		local now = tick()

		if now - LastSaveTime >= MIN_SAVE_TIME then
			DoSave()
		elseif not WaitingToSave then -- Save after cooldown
			WaitingToSave = true
			Delay(LastSaveTime + MIN_SAVE_TIME - now, function()
				DoSave()
				WaitingToSave = false
			end)
		end

		TryingToSave = false
	end
end

-- Save based on number of edits to workspace
local function OnEdit(descendant)
	if IsArchivable(descendant) then
		ChangeCount = ChangeCount + 1
		if ChangeCount >= NumberOfChangesBeforeSaveAbsolute then
			TrySave()
		end
	end
end

-- Make sure we save every interval regardless of number of edits, so long as there is one
local function CheckForSaveOnInterval()
	while true do
		wait(SAVE_CHECK_INTERVAL)

		if tick() - LastSaveTime >= SAVE_CHECK_INTERVAL and ChangeCount > 0 then
			TrySave()
		end
	end
end

--------------------
--| Script Logic |--
--------------------

Game:WaitForChild('Workspace')

pcall(function()
	Game.IsPersonalServer = true

	if not Workspace:FindFirstChild("PSVariable") then
		local psVar = Instance.new("BoolValue")
		psVar.Name = "PSVariable"
		psVar.Archivable = false
		psVar.Parent = Workspace
	end
end)

PlayersService.PlayerAdded:connect(OnPlayerAdded)
PlayersService.ChildRemoved:connect(OnPlayerRemoved)
for _, player in pairs(PlayersService:GetPlayers()) do
	OnPlayerAdded(player)
end

if Url~=nil then
	Game:SetServerSaveUrl(Url .. "Data/AutoSave.ashx?assetId=" .. PlaceId)
end

if pcall(function()
	Game.Close:connect(
		function()
			GameRunning = false
			Game:ServerSave()
		end)
	end) == false then
	print("!Error in Game.Close:connect")
end

RunService:Run()

Game:GetService("Workspace").DescendantAdded:connect(OnEdit)
Game:GetService("Workspace").DescendantRemoving:connect(OnEdit)

Spawn(CheckForSaveOnInterval)