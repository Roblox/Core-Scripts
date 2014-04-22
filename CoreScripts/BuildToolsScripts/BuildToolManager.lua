-- Responsible for giving out tools in personal servers

-- first, lets see if buildTools have already been created
-- create the object in lighting (TODO: move to some sort of "container" object when we have one)
local toolsArray = game.Lighting:FindFirstChild("BuildToolsModel")
local ownerArray = game.Lighting:FindFirstChild("OwnerToolsModel")
local hasBuildTools = false

function getIds(idTable, assetTable)
	for i = 1, #idTable do
		local model = game:GetService("InsertService"):LoadAsset(idTable[i])
		if model then
			local children = model:GetChildren()
			for i = 1, #children do
				if children[i]:IsA("Tool") then
					table.insert(assetTable,children[i])
				end
			end
		end
	end
end

function storeInLighting(modelName, assetTable)
	local model = Instance.new("Model")
	model.Archivable = false
	model.Name = modelName
	
	for i = 1, #assetTable do
		assetTable[i].Parent = model
	end
	
	if not game.Lighting:FindFirstChild(modelName) then -- no one beat us to it, we get to insert
		model.Parent = game.Lighting
	end
end

if not toolsArray then -- no one has made build tools yet, we get to!
	local buildToolIds = {}
	local ownerToolIds = {}

	table.insert(buildToolIds,73089166) -- PartSelectionTool
	table.insert(buildToolIds,73089190) -- DeleteTool
	table.insert(buildToolIds,73089204) -- CloneTool
	table.insert(buildToolIds,73089214) -- RotateTool
	table.insert(buildToolIds,73089229) -- RecentPartTool
	table.insert(buildToolIds,73089239) -- ConfigTool
	table.insert(buildToolIds,73089259) -- WiringTool
	table.insert(buildToolIds,58921588) -- ClassicTool
	
	table.insert(ownerToolIds, 65347268)

	-- next, create array of our tools
	local buildTools = {}
	local ownerTools = {}
	
	getIds(buildToolIds, buildTools)
	getIds(ownerToolIds, ownerTools)
	
	storeInLighting("BuildToolsModel",buildTools)
	storeInLighting("OwnerToolsModel",ownerTools)
	
	toolsArray = game.Lighting:FindFirstChild("BuildToolsModel")
	ownerArray = game.Lighting:FindFirstChild("OwnerToolsModel")
end

local localBuildTools = {}

function giveBuildTools()
	if not hasBuildTools then
		hasBuildTools = true
		local theTools = toolsArray:GetChildren()
		for i = 1, #theTools do
			local toolClone = theTools[i]:clone()
			if toolClone then
				toolClone.Parent = game.Players.LocalPlayer.Backpack
				table.insert(localBuildTools,toolClone)
			end
		end
	end
end

function giveOwnerTools()
	local theOwnerTools = ownerArray:GetChildren()
	for i = 1, #theOwnerTools do
		local ownerToolClone = theOwnerTools[i]:clone()
		if ownerToolClone then
			ownerToolClone.Parent = game.Players.LocalPlayer.Backpack
			table.insert(localBuildTools,ownerToolClone)
		end
	end
end

function removeBuildTools()
	if hasBuildTools then
		hasBuildTools = false
		for i = 1, #localBuildTools do
			localBuildTools[i].Parent = nil
		end
		localBuildTools = {}
	end
end

if game.Players.LocalPlayer.HasBuildTools then
	giveBuildTools()
end
if game.Players.LocalPlayer.PersonalServerRank >= 255 then
	giveOwnerTools()
end

local debounce = false
game.Players.LocalPlayer.Changed:connect(function(prop)
	if prop == "HasBuildTools" then
		while debounce do
			wait(0.5)
		end
		
		debounce = true
		
		if game.Players.LocalPlayer.HasBuildTools then
			giveBuildTools()
		else
			removeBuildTools()
		end
		
		if game.Players.LocalPlayer.PersonalServerRank >= 255 then
			giveOwnerTools()
		end
		
		debounce = false
	elseif prop == "PersonalServerRank" then
		if game.Players.LocalPlayer.PersonalServerRank >= 255 then
			giveOwnerTools()
		elseif game.Players.LocalPlayer.PersonalServerRank <= 0 then
			game.Players.LocalPlayer:Remove() -- you're banned, goodbye!
		end
	end
end)

game.Players.LocalPlayer.CharacterAdded:connect(function()
	hasBuildTools = false
	if game.Players.LocalPlayer.HasBuildTools then
		giveBuildTools()
	end
	if game.Players.LocalPlayer.PersonalServerRank >= 255 then
		giveOwnerTools()
	end
end)