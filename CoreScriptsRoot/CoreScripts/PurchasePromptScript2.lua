--[[
		// Filename: PurchasePromptScript2.lua
		// Version 1.0
		// Release 186
		// Written by: jeditkacheff/jmargh
		// Description: Handles in game purchases
]]--
--[[ Services ]]--
local GuiService = game:GetService('GuiService')
local HttpService = game:GetService('HttpService')
local HttpRbxApiService = game:GetService('HttpRbxApiService')
local InsertService = game:GetService('InsertService')
local MarketplaceService = game:GetService('MarketplaceService')
local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')

--[[ Script Variables ]]--
local RobloxGui = script.Parent
local ThirdPartyProductName = nil

--[[ Flags ]]--
local IsNativePurchasing = UserInputService.TouchEnabled
local IsCurrentlyPrompting = false
local IsCurrentlyPurchasing = false
local IsPurchasingConsumable = false
local IsCheckingPlayerFunds = false

--[[ Purchase Data ]]--
local PurchaseData = {
	AssetId = nil,
	ProductId = nil,
	CurrencyType = nil,
	EquipOnPurchase = nil,
	ProductInfo = nil,
	ItemDescription = nil,
}

--[[ Constants ]]--
local BASE_URL = game:GetService('ContentProvider').BaseUrl:lower()
BASE_URL = string.gsub(BASE_URL, "/m.", "/www.")
local THUMBNAIL_URL = BASE_URL.."thumbs/asset.ashx?assetid="
-- Images
local BG_IMAGE = 'rbxasset://textures/ui/Modal.png'
local PURCHASE_BG = 'rbxasset://textures/ui/LoadingBKG.png'
local BUTTON_LEFT = 'rbxasset://textures/ui/ButtonLeft.png'
local BUTTON_LEFT_DOWN = 'rbxasset://textures/ui/ButtonLeftDown.png'
local BUTTON_RIGHT = 'rbxasset://textures/ui/ButtonRight.png'
local BUTTON_RIGHT_DOWN = 'rbxasset://textures/ui/ButtonRightDown.png'
local BUTTON = 'rbxasset://textures/ui/SingleButton.png'
local BUTTON_DOWN = 'rbxasset://textures/ui/SingleButtonDown.png'
local ROBUX_ICON = 'rbxasset://textures/ui/RobuxIcon.png'
local TIX_ICON = 'rbxasset://textures/ui/TixIcon.png'
local ERROR_ICON = 'rbxasset://textures/ui/ErrorIcon.png'

local ERROR_MSG = {
	PURCHASE_DISABLED = "In-game purchases are temporarily disabled",
	INVALID_FUNDS = "your account does not have enought Robux",
	UNKNOWN = "Roblox is performing maintenance",
	UNKNWON_FAILURE = "something went wrong"
}
local PURCHASE_MSG = {
	SUCCEEDED = "Your purchase of itemName succeeded!",
	FAILED = "Your purchase of itemName failed because errorReason. Your account has not been charged. Please try again later.",
	PURCHASE = "Want to buy the assetType\nitemName for",
	PURCHASE_TIX = "Want to buy the assetType\nitemName for",
	FREE = "Would you like to take the assetType itemName for FREE?",
	FREE_BALANCE = "Your account balance will not be affected by this transaction.",
	BALANCE_FUTURE = "Your balance after this transaction will be ",
	BALANCE_NOW = "Your balance is now ",
	ALREADY_OWN = "You already own this item. Your account has not been charged."
}
local PURCHASE_FAILED = {
	DEFAULT_ERROR = 0,
	IN_GAME_PURCHASE_DISABLED = 1,
	CANNOT_GET_BALANCE = 2,
	CANNOT_GET_ITEM_PRICE = 3,
	NOT_FOR_SALE = 4,
	NOT_ENOUGH_TIX = 5,
	UNDER_13 = 6,
	LIMITED = 7,
	DID_NOT_BUY_ROBUX = 8,
}
local BC_LVL_TO_STRING = {
	"Builders Club",
	"Turbo Builders Club",
	"Outrageous Builders Club",
}
local ASSET_TO_STRING = {
	[1]  = "Image";
	[2]  = "T-Shirt";
	[3]  = "Audio";
	[4]  = "Mesh";
	[5]  = "Lua";
	[6]  = "HTML";
	[7]  = "Text";
	[8]  = "Hat";
	[9]  = "Place";
	[10] = "Model";
	[11] = "Shirt";
	[12] = "Pants";
	[13] = "Decal";
	[16] = "Avatar";
	[17] = "Head";
	[18] = "Face";
	[19] = "Gear";
	[21] = "Badge";
	[22] = "Group Emblem";
	[24] = "Animation";
	[25] = "Arms";
	[26] = "Legs";
	[27] = "Torso";
	[28] = "Right Arm";
	[29] = "Left Arm";
	[30] = "Left Leg";
	[31] = "Right Leg";
	[32] = "Package";
	[33] = "YouTube Video";
	[34] = "Game Pass";
	[38] = "Plugin";
	[0]  = "Product";
}
local BC_ROBUX_PRODUCTS = { 90, 180, 270, 360, 450, 1000, 2750 }
local NON_BC_ROBUX_PRODUCTS = { 80, 160, 240, 320, 400, 800, 2000 }

local DIALOG_SIZE = UDim2.new(0, 324, 0, 180)
local SHOW_POSITION = UDim2.new(0.5, -162, 0.5, -90)
local HIDE_POSITION = UDim2.new(0.5, -162, 0, -181)
local BTN_SIZE = UDim2.new(0, 162, 0, 44)
local BODY_SIZE = UDim2.new(0, 324, 0, 136)
local TWEEN_TIME = 0.3

local BTN_L_POS = UDim2.new(0, 0, 0, 136)
local BTN_R_POS = UDim2.new(0.5, 0, 0, 136)

--[[ Utility Functions ]]--
local function lerp( start, finish, t)
	return (1 - t) * start + t * finish
end

local function formatNumber(value)
	return tostring(value):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

--[[ Gui Creation Functions ]]--
local function createFrame(name, size, position, bgTransparency, bgColor)
	local frame = Instance.new('Frame')
	frame.Name = name
	frame.Size = size
	frame.Position = position or UDim2.new(0, 0, 0, 0)
	frame.BackgroundTransparency = bgTransparency
	frame.BackgroundColor3 = bgColor or Color3.new()
	frame.BorderSizePixel = 0
	frame.ZIndex = 8

	return frame
end

local function createTextLabel(name, size, position, font, fontSize, text)
	local textLabel = Instance.new('TextLabel')
	textLabel.Name = name
	textLabel.Size = size or UDim2.new(0, 0, 0, 0)
	textLabel.Position = position
	textLabel.BackgroundTransparency = 1
	textLabel.Font = font
	textLabel.FontSize = fontSize
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.Text = text
	textLabel.ZIndex = 8

	return textLabel
end

local function createImageLabel(name, size, position, image)
	local imageLabel = Instance.new('ImageLabel')
	imageLabel.Name = name
	imageLabel.Size = size
	imageLabel.BackgroundTransparency = 1
	imageLabel.Position = position
	imageLabel.Image = image

	return imageLabel
end

local function createImageButtonWithText(name, position, image, imageDown, text, font)
	local imageButton = Instance.new('ImageButton')
	imageButton.Name = name
	imageButton.Size = BTN_SIZE
	imageButton.Position = position
	imageButton.Image = image
	imageButton.BackgroundTransparency = 1
	imageButton.AutoButtonColor = false
	imageButton.ZIndex = 8

	local textLabel = createTextLabel(name.."Text", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), font, Enum.FontSize.Size24, text)
	textLabel.ZIndex = 9
	textLabel.Parent = imageButton

	imageButton.MouseEnter:connect(function()
		imageButton.Image = imageDown
	end)
	imageButton.MouseLeave:connect(function()
		imageButton.Image = image
	end)
	imageButton.MouseButton1Click:connect(function()
		imageButton.Image = image
	end)

	return imageButton
end

--[[ Begin Gui Creation ]]--
local PurchaseDialog = createFrame("PurchaseDialog", DIALOG_SIZE, HIDE_POSITION, 1, nil)
PurchaseDialog.Visible = false
PurchaseDialog.Parent = RobloxGui

	local ContainerFrame = createFrame("ContainerFrame", UDim2.new(1, 0, 1, 0), nil, 1, nil)
	ContainerFrame.Parent = PurchaseDialog

		local ContainerImage = createImageLabel("ContainerImage", BODY_SIZE, UDim2.new(0, 0, 0, 0), BG_IMAGE)
		ContainerImage.ZIndex = 8
		ContainerImage.Parent = ContainerFrame

		local ItemPreviewImage = createImageLabel("ItemPreviewImage", UDim2.new(0, 64, 0, 64), UDim2.new(0, 27, 0, 20), "")
		ItemPreviewImage.ZIndex = 9
		ItemPreviewImage.Parent = ContainerFrame

		local ItemDescriptionText = createTextLabel("ItemDescriptionText", UDim2.new(0, 210, 0, 96), UDim2.new(0, 110, 0, 18),
			Enum.Font.SourceSans, Enum.FontSize.Size18, PURCHASE_MSG.PURCHASE)
		ItemDescriptionText.TextXAlignment = Enum.TextXAlignment.Left
		ItemDescriptionText.TextYAlignment = Enum.TextYAlignment.Top
		ItemDescriptionText.TextWrapped = true
		ItemDescriptionText.Parent = ContainerFrame

		local RobuxIcon = createImageLabel("RobuxIcon", UDim2.new(0, 20, 0, 20), UDim2.new(0, 0, 0, 0), ROBUX_ICON)
		RobuxIcon.ZIndex = 9
		RobuxIcon.Visible = false
		RobuxIcon.Parent = ContainerFrame

		local TixIcon = createImageLabel("TixIcon", UDim2.new(0, 20, 0, 20), UDim2.new(0, 0, 0, 0), TIX_ICON)
		TixIcon.ZIndex = 9
		TixIcon.Visible = false
		TixIcon.Parent = ContainerFrame

		local CostText = createTextLabel("CostText", UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 0, 0),
			Enum.Font.SourceSansBold, Enum.FontSize.Size18, "")
		CostText.TextXAlignment = Enum.TextXAlignment.Left
		CostText.Visible = false
		CostText.Parent = ContainerFrame

		local PostBalanceText = createTextLabel("PostBalanceText", UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, 100), Enum.Font.SourceSans,
			Enum.FontSize.Size14, "")
		PostBalanceText.TextWrapped = true
		PostBalanceText.Parent = ContainerFrame

		local BuyButton = createImageButtonWithText("BuyButton", BTN_L_POS, BUTTON_LEFT, BUTTON_LEFT_DOWN, "Buy Now", Enum.Font.SourceSansBold)
		BuyButton.Parent = ContainerFrame

		local CancelButton = createImageButtonWithText("CancelButton", BTN_R_POS, BUTTON_RIGHT, BUTTON_RIGHT_DOWN, "Cancel", Enum.Font.SourceSans)
		CancelButton.Parent = ContainerFrame

		local BuyRobuxButton = createImageButtonWithText("BuyRobuxButton", BTN_L_POS, BUTTON_LEFT, BUTTON_LEFT_DOWN, IsNativePurchasing and "Buy" or "Buy R$",
			Enum.Font.SourceSansBold)
		BuyRobuxButton.Visible = false
		BuyRobuxButton.Parent = ContainerFrame

		local BuyBCButton = createImageButtonWithText("BuyBCButton", BTN_L_POS, BUTTON_LEFT, BUTTON_LEFT_DOWN, "Upgrade", Enum.Font.SourceSansBold)
		BuyBCButton.Visible = false
		BuyBCButton.Parent = ContainerFrame

		local FreeButton = createImageButtonWithText("FreeButton", BTN_L_POS, BUTTON_LEFT, BUTTON_LEFT_DOWN, "Take Free", Enum.Font.SourceSansBold)
		FreeButton.Visible = false
		FreeButton.Parent = ContainerFrame

		local OkButton = createImageButtonWithText("OkButton", UDim2.new(0, 2, 0, 136), BUTTON, BUTTON_DOWN, "OK", Enum.Font.SourceSans)
		OkButton.Size = UDim2.new(0, 320, 0, 44)
		OkButton.Visible = false
		OkButton.Parent = ContainerFrame

		local OkPurchasedButton = createImageButtonWithText("OkPurchasedButton", UDim2.new(0, 2, 0, 136), BUTTON, BUTTON_DOWN, "OK", Enum.Font.SourceSans)
		OkPurchasedButton.Size = UDim2.new(0, 320, 0, 44)
		OkPurchasedButton.Visible = false
		OkPurchasedButton.Parent = ContainerFrame

	local PurchaseFrame = createImageLabel("PurchaseFrame", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), PURCHASE_BG)
	PurchaseFrame.ZIndex = 8
	PurchaseFrame.Visible = false
	PurchaseFrame.Parent = PurchaseDialog

		local PurchaseText = createTextLabel("PurchaseText", nil, UDim2.new(0.5, 0, 0.5, -36), Enum.Font.SourceSans,
			Enum.FontSize.Size36, "Purchasing")
		PurchaseText.Parent = PurchaseFrame

		local LoadingFrames = {}
		local xOffset = -40
		for i = 1, 3 do
			local frame = createFrame("Loading", UDim2.new(0, 16, 0, 16), UDim2.new(0.5, xOffset, 0.5, 0), 0, Color3.new(132/255, 132/255, 132/255))
			table.insert(LoadingFrames, frame)
			frame.Parent = PurchaseFrame
			xOffset = xOffset + 32
		end

--[[ Purchase Data Functions ]]--
local function getCurrencyString(currencyType)
	return currencyType == Enum.CurrencyType.Tix and "Tix" or "R$"
end

local function setInitialPurchaseData(assetId, productId, currencyType, equipOnPurchase)
	PurchaseData.AssetId = assetId
	PurchaseData.ProductId = productId
	PurchaseData.CurrencyType = currencyType
	PurchaseData.EquipOnPurchase = equipOnPurchase

	IsPurchasingConsumable = productId ~= nil
end

local function setCurrencyData(playerBalance)
	local priceInRobux = tonumber(PurchaseData.ProductInfo['PriceInRobux'])
	local priceInTickets = tonumber(PurchaseData.ProductInfo['PriceInTickets'])
	--
	if PurchaseData.CurrencyType == Enum.CurrencyType.Default or PurchaseData.CurrencyType == Enum.CurrencyType.Robux then
		if priceInRobux and priceInRobux ~= 0 then
			PurchaseData.CurrencyAmount = priceInRobux
			PurchaseData.CurrencyType = Enum.CurrencyType.Robux
		else
			PurchaseData.CurrencyAmount = priceInTickets
			PurchaseData.CurrencyType = Enum.CurrencyType.Tix
		end
	elseif PurchaseData.CurrencyType == Enum.CurrencyType.Tix then
		if priceInTickets and priceInTickets ~= 0 then
			PurchaseData.CurrencyAmount = priceInTickets
		else
			PurchaseData.CurrencyAmount = priceInRobux
			PurchaseData.CurrencyType = Enum.CurrencyType.Robux
		end
	end
end

local function setPreviewImage(productInfo, assetId)
	if IsPurchasingConsumable then
		if productInfo then
			ItemPreviewImage.Image = THUMBNAIL_URL..tostring(productInfo["IconImageAssetId"].."&x=100&y=100&format=png")
		end
	else
		if assetId then
			ItemPreviewImage.Image = THUMBNAIL_URL..tostring(assetId).."&x=100&y=100&format=png"
		end
	end
end

local function clearPurchaseData()
	for k,v in pairs(PurchaseData) do
		PurchaseData[k] = nil
	end
	RobuxIcon.Visible = false
	TixIcon.Visible = false
	CostText.Visible = false
end

--[[ Show Functions ]]--
local function setButtonsVisible(...)
	local args = {...}
	local argCount = select('#', ...)

	for _,child in pairs(ContainerFrame:GetChildren()) do
		if child:IsA('ImageButton') then
			child.Visible = false
			for i = 1, argCount do
				if child == args[i] then
					child.Visible = true
				end
			end
		end
	end
end

local function tweenBackgroundColor(frame, endColor, duration)
	local t = 0
	local prevTime = tick()
	local startColor = frame.BackgroundColor3
	while t < duration do
		local s = t / duration
		local r = lerp(startColor.r, endColor.r, s)
		local g = lerp(startColor.g, endColor.g, s)
		local b = lerp(startColor.b, endColor.b, s)
		frame.BackgroundColor3 = Color3.new(r, g, b)
		--
		t = t + (tick() - prevTime)
		prevTime = tick()
		wait()
	end
	frame.BackgroundColor3 = endColor
end

local isPurchaseAnimating = false
local function startPurchaseAnimation()
	if PurchaseFrame.Visible then return end
	--
	ContainerFrame.Visible = false
	PurchaseFrame.Visible = true
	--
	spawn(function()
		isPurchaseAnimating = true
		local i = 1
		while isPurchaseAnimating do
			local frame = LoadingFrames[i]
			local prevPosition = frame.Position
			local newPosition = UDim2.new(prevPosition.X.Scale, prevPosition.X.Offset, prevPosition.Y.Scale, prevPosition.Y.Offset - 2)
			spawn(function()
				tweenBackgroundColor(frame, Color3.new(0, 162/255, 1), 0.25)
			end)
			frame:TweenSizeAndPosition(UDim2.new(0, 16, 0, 20), newPosition, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.25, true, function()
				spawn(function()
					tweenBackgroundColor(frame, Color3.new(132/255, 132/255, 132/255), 0.25)
				end)
				frame:TweenSizeAndPosition(UDim2.new(0, 16, 0, 16), prevPosition, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.25, true)
			end)
			i = i + 1
			if i > 3 then
				i = 1
				wait(0.25)	-- small pause when starting from 1
			end
			wait(0.5)
		end
	end)
end

local function stopPurchaseAnimation()
	isPurchaseAnimating = false
	PurchaseFrame.Visible = false
	ContainerFrame.Visible = true
end

local function setPurchaseDataInGui(isFree, invalidBC)
	local  descriptionText = PurchaseData.CurrencyType == Enum.CurrencyType.Tix and PURCHASE_MSG.PURCHASE_TIX or PURCHASE_MSG.PURCHASE
	if isFree then
		descriptionText = PURCHASE_MSG.FREE
		PostBalanceText.Text = PURCHASE_MSG.FREE_BALANCE
	end

	local productInfo = PurchaseData.ProductInfo
	if not productInfo then
		return false
	end
	local itemDescription = string.gsub(descriptionText, "itemName", string.sub(productInfo["Name"], 1, 20))
	itemDescription = string.gsub(itemDescription, "assetType", ASSET_TO_STRING[productInfo["AssetTypeId"]] or "Unknown")
	ItemDescriptionText.Text = itemDescription

	if not isFree then
		if PurchaseData.CurrencyType == Enum.CurrencyType.Tix then
			TixIcon.Visible = true
			TixIcon.Position = UDim2.new(0, 110, 0, ItemDescriptionText.Position.Y.Offset + ItemDescriptionText.TextBounds.y + 6)
			CostText.TextColor3 = Color3.new(204/255, 158/255, 113/255)
		else
			RobuxIcon.Visible = true
			RobuxIcon.Position = UDim2.new(0, 110, 0, ItemDescriptionText.Position.Y.Offset + ItemDescriptionText.TextBounds.y + 6)
			CostText.TextColor3 = Color3.new(2/255, 183/255, 87/255)
		end
		CostText.Text = formatNumber(PurchaseData.CurrencyAmount)
		CostText.Position = UDim2.new(0, 134, 0, ItemDescriptionText.Position.Y.Offset + ItemDescriptionText.TextBounds.y + 15)
		CostText.Visible = true
	end

	setPreviewImage(productInfo, PurchaseData.AssetId)
	setButtonsVisible(isFree and FreeButton or BuyButton, CancelButton)
	PostBalanceText.Visible = true

	if invalidBC then
		local neededBcLevel = PurchaseData.ProductInfo["MinimumMembershipLevel"]
		PostBalanceText.Text = "This item requires "..BC_LVL_TO_STRING[neededBcLevel]..".\nClick 'Upgrade' to upgrade your Builders Club!"
		setButtonsVisible(BuyBCButton, CancelButton)
	end
	return true
end

local function getRobuxProduct(amountNeeded, isBCMember)
	local productArray = isBCMember and BC_ROBUX_PRODUCTS or NON_BC_ROBUX_PRODUCTS
	local closestProduct = productArray[1]
	local closestIndex = 1

	for i = 1, #productArray do
		if (math.abs(productArray[i] - amountNeeded) < math.abs(closestProduct - amountNeeded)) then
			closestProduct = productArray[i]
			closestIndex = i
		end
	end
	if closestProduct < amountNeeded then
		closestProduct = productArray[1 + closestIndex]
	end
	return closestProduct
end

local function getRobuxProductToBuyItem(amountNeeded)
	local isBCMember = Players.LocalPlayer.MembershipType ~= Enum.MembershipType.None

	local productCost = getRobuxProduct(amountNeeded, isBCMember)
	if not productCost then
		return nil
	end
	local success, isAndroid = pcall(function()
		return UserInputService:GetPlatform() == Enum.Platform.Android
	end)
	if not success then
		print("PurchasePromptScript: getRobuxProductToBuyItem() failed because", isAndroid)
	end

	local prependStr, appendStr, appPrefix = "", "", ""
	if isAndroid then
		prependStr = "robux"
		if isBCMember then
			appendStr = "bc"
		end
		appPrefix = "com.roblox.client."
	else
		appendStr = isBCMember and "RobuxBC" or "RobuxNonBC"
		appPrefix = "com.roblox.robloxmobile."
	end

	local productStr = appPrefix..prependStr..tostring(productCost)..appendStr
	return productStr, productCost
end

local function setBuyMoreRobuxDialog(playerBalance)
	local playerBalanceInt = tonumber(playerBalance["robux"])
	local neededRobux = PurchaseData.CurrencyAmount - playerBalanceInt
	local productInfo = PurchaseData.ProductInfo

	local descriptionText = "You need "..formatNumber(neededRobux).." more ROBUX to buy the "..productInfo["Name"].." "..
		ASSET_TO_STRING[productInfo["AssetTypeId"]]
	setButtonsVisible(BuyRobuxButton, CancelButton)

	if IsNativePurchasing then
		local productCost = nil
		ThirdPartyProductName, productCost = getRobuxProductToBuyItem(neededRobux)
		--
		if not ThirdPartyProductName then
			descriptionText = "This item cost more ROBUX than you can purchase. Please visit www.roblox.com to purchase more ROBUX."
			setButtonsVisible(OkButton)
		else
			local remainder = playerBalanceInt + productCost - PurchaseData.CurrencyAmount
			descriptionText = descriptionText..". Would you like to buy "..formatNumber(productCost).." ROBUX?"
			PostBalanceText.Text = "The remaining "..formatNumber(remainder).." ROBUX will be credited to your balance."
			PostBalanceText.Visible = true
		end
	else
		descriptionText = descriptionText..". Would you like to buy more ROBUX?"
	end
	ItemDescriptionText.Text = descriptionText
	setPreviewImage(productInfo, PurchaseData.AssetId)
end

local function showPurchasePrompt()
	stopPurchaseAnimation()
	PurchaseDialog.Visible = true
	PurchaseDialog:TweenPosition(SHOW_POSITION, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, TWEEN_TIME, true)
	UserInputService.ModalEnabled = true
end

--[[ Close and Cancel Functions ]]--
local function onPurchaseFailed(failType)
	setButtonsVisible(OkButton)
	ItemPreviewImage.Image = ERROR_ICON
	PostBalanceText.Text = ""

	local itemName = PurchaseData.ProductInfo and PurchaseData.ProductInfo["Name"] or ""
	local failedText = string.gsub(PURCHASE_MSG.FAILED, "itemName", string.sub(itemName, 1, 20))
	if failType == PURCHASE_FAILED.DEFAULT_ERROR then
		failedText = string.gsub(failedText, "errorReason", ERROR_MSG.UNKNWON_FAILURE)
	elseif failType == PURCHASE_FAILED.IN_GAME_PURCHASE_DISABLED then
		if itemName == "" then
			failedText = string.gsub(failedText, " of ", "")
		end
		failedText = string.gsub(failedText, "errorReason", ERROR_MSG.PURCHASE_DISABLED)
	elseif failType == PURCHASE_FAILED.CANNOT_GET_BALANCE then
		failedText = "Cannot retrieve your balance at this time. Your account has not been charged. Please try again later."
	elseif failType == PURCHASE_FAILED.CANNOT_GET_ITEM_PRICE then
		failedText = "We couldn't retrieve the price of the item at this time. Your account has not been charged. Please try again later."
	elseif failType == PURCHASE_FAILED.NOT_FOR_SALE then
		failedText = "This item is not currently for sale. Your account has not been charged."
		setPreviewImage(PurchaseData.ProductInfo, PurchaseData.AssetId)
	elseif failType == PURCHASE_FAILED.NOT_ENOUGH_TIX then
		failedText = "This item cost more tickets than you currently have. Try trading currency on www.roblox.com to get more tickets."
		setPreviewImage(PurchaseData.ProductInfo, PurchaseData.AssetId)
	elseif failType == PURCHASE_FAILED.UNDER_13 then
		failedText = "Your account is under 13. Purchase of this item is not allowed. Your account has not been charged."
	elseif failType == PURCHASE_FAILED.LIMITED then
		failedText = "This limited item has no more copies. Try buying from another user on www.roblox.com. Your account has not been charged."
		setPreviewImage(PurchaseData.ProductInfo, PurchaseData.AssetId)
	elseif failType == PURCHASE_FAILED.DID_NOT_BUY_ROBUX then
		failedText = string.gsub(failedText, "errorReason", ERROR_MSG.INVALID_FUNDS)
	end

	ItemDescriptionText.Text = failedText
	showPurchasePrompt()
end

local function closePurchaseDialog()
	PurchaseDialog:TweenPosition(HIDE_POSITION, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, TWEEN_TIME, true, function()
			PurchaseDialog.Visible = false
			IsCurrentlyPrompting = false
			IsCurrentlyPurchasing = false
			IsCheckingPlayerFunds = false
			UserInputService.ModalEnabled = false
		end)
end

-- Main exit point
local function onPromptEnded(isSuccess)
	closePurchaseDialog()
	if IsPurchasingConsumable then
		MarketplaceService:SignalPromptProductPurchaseFinished(Players.LocalPlayer.userId, PurchaseData.ProductId, isSuccess)
	else
		MarketplaceService:SignalPromptPurchaseFinished(Players.LocalPlayer, PurchaseData.AssetId, isSuccess)
	end
	clearPurchaseData()
end

--[[ Purchase Validation ]]--
local function isMarketplaceDown() 		-- FFlag
	local success, result = pcall(function() return settings():GetFFlag('Order66') end)
	if not success then
		print("PurchasePromptScript: isMarketplaceDown failed because", result)
		return false
	end
	
	return result
end

local function checkMarketplaceAvailable() 	-- FFlag
	local success, result = pcall(function() return settings():GetFFlag("CheckMarketplaceAvailable") end)
	if not success then
		print("PurchasePromptScript: checkMarketplaceAvailable failed because", result)
		return false
	end

	return result
end

-- return success and isAvailable
local function isMarketplaceAvailable()
	local success, result = pcall(function()
		return HttpRbxApiService:GetAsync("my/economy-status", false,
			Enum.ThrottlingPriority.Extreme)
	end)
	if not success then
		print("PurchasePromptScript: isMarketplaceUnavailable() failed because", result)
		return false
	end
	result = HttpService:JSONDecode(result)
	if result["isMarketplaceEnabled"] ~= nil then
		if result["isMarketplaceEnabled"] == false then
			return true, false
		end
	end
	return true, true
end

local function getProductInfo()
	local success, result = nil, nil
	if IsPurchasingConsumable then
		success, result = pcall(function()
			return MarketplaceService:GetProductInfo(PurchaseData.ProductId, Enum.InfoType.Product)
		end)
	else
		success, result = pcall(function()
			return MarketplaceService:GetProductInfo(PurchaseData.AssetId)
		end)
	end

	if not success or not result then
		print("PurchasePromptScript: getProductInfo failed because", result)
		return nil
	end

	if type(result) ~= 'table' then
		result = HttpService:JSONDecode(result)
	end

	return result
end

-- returns success, doesOwnItem
local function doesPlayerOwnItem()
	if not PurchaseData.AssetId or PurchaseData.AssetId <= 0 then
		return false, nil
	end

	local success, result = pcall(function()
		local apiPath = "ownership/hasAsset"
		local params = "?userId="..tostring(Players.LocalPlayer.userId).."&assetId="..tostring(PurchaseData.AssetId)
		return HttpRbxApiService:GetAsync(apiPath..params, true)
	end)

	if not success then
		print("PurchasePromptScript: doesPlayerOwnItem() failed because", result)
		return false, nil
	end

	if result == true or result == "true" then
		return true, true
	end

	return true, false
end

local function isFreeItem()
	return PurchaseData.ProductInfo and PurchaseData.ProductInfo["IsPublicDomain"] == true
end

local function getPlayerBalance()
	local success, result = pcall(function()
		local apiPath = "currency/balance"
		return HttpRbxApiService:GetAsync(apiPath, true)
	end)

	if not success then
		print("PurchasePromptScript: getPlayerBalance() failed because", result)
		return nil
	end

	if result == '' then return end

	return HttpService:JSONDecode(result)
end

local function isNotForSale()
	return PurchaseData.ProductInfo['IsForSale'] == false and PurchaseData.ProductInfo["IsPublicDomain"] == false
end

local function playerHasFundsForPurchase(playerBalance)
	local currencyTypeStr = nil
	if PurchaseData.CurrencyType == Enum.CurrencyType.Robux then
		currencyTypeStr = "robux"
	elseif PurchaseData.CurrencyType == Enum.CurrencyType.Tix then
		currencyTypeStr = "tickets"
	else
		return false
	end

	local playerBalanceInt = tonumber(playerBalance[currencyTypeStr])
	if not playerBalanceInt then
		return false
	end

	local afterBalanceAmount = playerBalanceInt - PurchaseData.CurrencyAmount
	local currencyStr = getCurrencyString(PurchaseData.CurrencyType)
	if afterBalanceAmount < 0 and PurchaseData.CurrencyType == Enum.CurrencyType.Robux then
		PostBalanceText.Visible = false
		return true, false
	elseif afterBalanceAmount < 0 and PurchaseData.CurrencyType == Enum.CurrencyType.Tix then
		PostBalanceText.Visible = true
		PostBalanceText.Text = "You need "..formatNumber(-afterBalanceAmount).." more "..currencyStr.." to buy this item."
		return true, false
	end

	if PurchaseData.CurrencyType == Enum.CurrencyType.Tix then
		PostBalanceText.Text = PURCHASE_MSG.BALANCE_FUTURE..formatNumber(afterBalanceAmount).." "..currencyStr.."."
	else
		PostBalanceText.Text = PURCHASE_MSG.BALANCE_FUTURE..currencyStr..formatNumber(afterBalanceAmount).."."
	end
	return true, true
end

local function isUnder13()
	if PurchaseData.ProductInfo["ContentRatingTypeId"] == 1 then
		if Players.LocalPlayer:GetUnder13() then
			return true
		end
	end
	return false
end

local function isLimitedUnique()
	local productInfo = PurchaseData.ProductInfo
	if productInfo then
		if (productInfo["IsLimited"] or productInfo["IsLimitedUnique"]) and
			(productInfo["Remaining"] == "" or productInfo["Remaining"] == 0 or productInfo["Remaining"] == nil or productInfo["Remaining"] == "null") then
			return true
		end
	end
	return false
end

-- main validation function
local function canPurchase()
	if isMarketplaceDown() then 	-- FFlag
		onPurchaseFailed(PURCHASE_FAILED.IN_GAME_PURCHASE_DISABLED)
		return false
	end

	if checkMarketplaceAvailable() then 	-- FFlag
		local success, isAvailable = isMarketplaceAvailable()
		if success then
			if not isAvailable then
				onPurchaseFailed(PURCHASE_FAILED.IN_GAME_PURCHASE_DISABLED)
				return false
			end
		else
			onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
			return false
		end
	end

	PurchaseData.ProductInfo = getProductInfo()
	if not PurchaseData.ProductInfo then
		onPurchaseFailed(PURCHASE_FAILED.IN_GAME_PURCHASE_DISABLED)
		return false
	end

	if isNotForSale() then
		onPurchaseFailed(PURCHASE_FAILED.NOT_FOR_SALE)
		return false
	end

	-- check if owned by player; dev products are not owned
	if not IsPurchasingConsumable then
		local success, doesOwnItem = doesPlayerOwnItem()
		if not success then
			onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
			return false
		elseif doesOwnItem then
			if not PurchaseData.ProductInfo then
				onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
				return false
			end
			setPreviewImage(PurchaseData.ProductInfo, PurchaseData.AssetId)
			ItemDescriptionText.Text = PURCHASE_MSG.ALREADY_OWN
			PostBalanceText.Visible = false
			setButtonsVisible(OkButton)
			return true
		end
	end

	local isFree = isFreeItem()

	local playerBalance = getPlayerBalance()
	if not playerBalance then
		onPurchaseFailed(PURCHASE_FAILED.CANNOT_GET_BALANCE)
		return false
	end

	-- validate item price
	setCurrencyData(playerBalance)
	if not PurchaseData.CurrencyAmount and not isFree then
		onPurchaseFailed(PURCHASE_FAILED.CANNOT_GET_ITEM_PRICE)
		return false
	end

	-- check player funds
	local hasFunds = nil
	if not isFree then
		local success = nil
		success, hasFunds = playerHasFundsForPurchase(playerBalance)
		if success then
			if not hasFunds then
				if PurchaseData.CurrencyType == Enum.CurrencyType.Tix then
					onPurchaseFailed(PURCHASE_FAILED.NOT_ENOUGH_TIX)
					return false
				else
					setBuyMoreRobuxDialog(playerBalance)
				end
			end
		else
			onPurchaseFailed(PURCHASE_FAILED.CANNOT_GET_BALANCE)
			return false
		end
	end

	-- check membership type
	local invalidBCLevel = PurchaseData.ProductInfo["MinimumMembershipLevel"] > Players.LocalPlayer.MembershipType.Value

	-- check under 13
	if isUnder13() then
		onPurchaseFailed(PURCHASE_FAILED.UNDER_13)
		return false
	end

	if isLimitedUnique() then
		onPurchaseFailed(PURCHASE_FAILED.LIMITED)
		return false
	end

	if (hasFunds or isFree or invalidBCLevel) then
		if not setPurchaseDataInGui(isFree, invalidBCLevel) then
			onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
			return false
		end
	end

	return true
end

--[[ Purchase Functions ]]--
local function getToolAsset(assetId)
	local tool = InsertService:LoadAsset(assetId)
	if not tool then return nil end
	--
	if tool:IsA("Tool") then
		return tool
	end

	local children = tool:GetChildren()
	for i = 1, #children do
		if children[i]:IsA("Tool") then
			return children[i]
		end
	end
end

local function onPurchaseSuccess()
	IsCheckingPlayerFunds = false
	local descriptionText = PURCHASE_MSG.SUCCEEDED

	descriptionText = string.gsub(descriptionText, "itemName", string.sub(PurchaseData.ProductInfo["Name"], 1, 20))
	ItemDescriptionText.Text = descriptionText

	local playerBalance = getPlayerBalance()
	local currencyType = PurchaseData.CurrencyType == Enum.CurrencyType.Tix and "tickets" or "robux"
	local newBalance = playerBalance[currencyType]

	if currencyType == "robux" then
		PostBalanceText.Text = PURCHASE_MSG.BALANCE_NOW..getCurrencyString(PurchaseData.CurrencyType)..formatNumber(newBalance).."."
	else
		PostBalanceText.Text = PURCHASE_MSG.BALANCE_NOW..formatNumber(newBalance).." "..getCurrencyString(PurchaseData.CurrencyType).."."
	end

	if isFreeItem() then PostBalanceText.Visible = false end

	setButtonsVisible(OkPurchasedButton)
	stopPurchaseAnimation()
end

local function onAcceptPurchase()
	if IsCurrentlyPurchasing then return end
	--
	IsCurrentlyPurchasing = true
	startPurchaseAnimation()
	local startTime = tick()
	local apiPath = nil
	local params = nil
	local currencyTypeInt = nil
	if PurchaseData.CurrencyType == Enum.CurrencyType.Robux or PurchaseData.CurrencyType == Enum.CurrencyType.Default then
		currencyTypeInt = 1
	elseif PurchaseData.CurrencyType == Enum.CurrencyType.Tix then
		currencyTypeInt = 2
	end

	local productId = PurchaseData.ProductInfo["ProductId"]
	if IsPurchasingConsumable then
		apiPath = "marketplace/submitpurchase"
		params = "productId="..tostring(productId).."&currencyTypeId="..tostring(currencyTypeInt)..
			"&expectedUnitPrice="..tostring(PurchaseData.CurrencyAmount).."&placeId="..tostring(game.PlaceId)
		params = params.."&requestId="..HttpService:UrlEncode(HttpService:GenerateGUID(false))
	else
		apiPath = "marketplace/purchase"
		params = "productId="..tostring(productId).."&currencyTypeId="..tostring(currencyTypeInt)..
			"&purchasePrice="..tostring(PurchaseData.CurrencyAmount or 0).."&locationType=Game&locationId="..tostring(game.PlaceId)
	end

	local success, result = pcall(function()
		return HttpRbxApiService:PostAsync(apiPath, params, true, Enum.ThrottlingPriority.Default, Enum.HttpContentType.ApplicationUrlEncoded)
	end)

	-- retry
	if IsPurchasingConsumable then
		local retries = 3
		local wasSuccess = success and result and result ~= ''
		while retries > 0 and not wasSuccess do
			wait(1)
			retries = retries - 1
			success, result = pcall(function()
				return HttpRbxApiService:PostAsync(apiPath, params, true, Enum.ThrottlingPriority.Default, Enum.HttpContentType.ApplicationUrlEncoded)
			end)
			wasSuccess = success and result and result ~= ''
		end
		--
		game:ReportInGoogleAnalytics("Developer Product", "Purchase",
			wasSuccess and ("success. Retries = "..(3 - retries)) or ("failure: " .. tostring(result)), 1)
	end

	if tick() - startTime < 1 then wait(1) end 		-- artifical delay to show spinner for at least 1 second

	if not success then
		print("PurchasePromptScript: onAcceptPurchase() failed because", result)
		onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
		return
	end

	result = HttpService:JSONDecode(result)
	if result then
		if result["success"] == false then
			if result["status"] ~= "AlreadyOwned" then
				print("PurchasePromptScript: onAcceptPurchase() response failed because", tostring(result["status"]))
				if result["status"] == "EconomyDisabled" then
					onPurchaseFailed(PURCHASE_FAILED.IN_GAME_PURCHASE_DISABLED)
				else
					onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
				end
				return
			end
		end
	else
		print("PurchasePromptScript: onAcceptPurchase() failed to parse JSON of", productId)
		onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
		return
	end

	if PurchaseData.EquipOnPurchase and PurchaseData.AssetId and tonumber(PurchaseData.ProductInfo["AssetTypeId"]) == 19 then
		local tool = getToolAsset(tonumber(PurchaseData.AssetId))
		if tool then
			tool.Parent = Players.LocalPlayer.Backpack
		end
	end

	if IsPurchasingConsumable then
		if not result["receipt"] then
			print("PurchasePromptScript: onAcceptPurchase() failed because no dev product receipt was returned for", tostring(productId))
			onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
			return
		end
		MarketplaceService:SignalClientPurchaseSuccess(tostring(result["receipt"]), Players.LocalPlayer.userId, productId)
	else
		onPurchaseSuccess()
	end
end

-- main entry point
local function onPurchasePrompt(player, assetId, equipIfPurchased, currencyType, productId)
	if player == Players.LocalPlayer and not IsCurrentlyPrompting then
		IsCurrentlyPrompting = true
		setInitialPurchaseData(assetId, productId, currencyType, equipIfPurchased)
		if canPurchase() then
			showPurchasePrompt()
		end
	end
end

local function onBuyRobuxPrompt()
	startPurchaseAnimation()
	if IsNativePurchasing then
		MarketplaceService:PromptNativePurchase(Players.LocalPlayer, ThirdPartyProductName)
	else
		IsCheckingPlayerFunds = true
		GuiService:OpenBrowserWindow(BASE_URL.."Upgrades/Robux.aspx")
	end
end

local function onUpgradeBCPrompt()
	IsCheckingPlayerFunds = true
	GuiService:OpenBrowserWindow(BASE_URL.."Upgrades/BuildersClubMemberships.aspx")
end

--[[ Event Connections ]]--
CancelButton.MouseButton1Click:connect(function()
	if IsCurrentlyPurchasing then return end
	onPromptEnded(false)
end)
BuyButton.MouseButton1Click:connect(onAcceptPurchase)
FreeButton.MouseButton1Click:connect(onAcceptPurchase)
OkButton.MouseButton1Click:connect(function()
	onPromptEnded(false)
end)
OkPurchasedButton.MouseButton1Click:connect(function()
	onPromptEnded(true)
end)
BuyRobuxButton.MouseButton1Click:connect(onBuyRobuxPrompt)
BuyBCButton.MouseButton1Click:connect(onUpgradeBCPrompt)

MarketplaceService.PromptProductPurchaseRequested:connect(function(player, productId, equipIfPurchased, currencyType)
	onPurchasePrompt(player, nil, equipIfPurchased, currencyType, productId)
end)
MarketplaceService.PromptPurchaseRequested:connect(function(player, assetId, equipIfPurchased, currencyType)
	onPurchasePrompt(player, assetId, equipIfPurchased, currencyType, nil)
end)
MarketplaceService.ServerPurchaseVerification:connect(function(serverResponseTable)
	if not serverResponseTable then
		onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
		return
	end

	if serverResponseTable["playerId"] and tonumber(serverResponseTable["playerId"]) == Players.LocalPlayer.userId then
		onPurchaseSuccess()
	end
end)

local function retryPurchase()
	local canMakePurchase = canPurchase()
	if not canMakePurchase then
		local retries = 20
		while retries > 0 and not canMakePurchase do
			wait(0.5)
			canMakePurchase = canPurchase()
			retries = retries - 1
		end
	end
end

GuiService.BrowserWindowClosed:connect(function()
	if IsCheckingPlayerFunds then
		retryPurchase()
	end
	stopPurchaseAnimation()
end)

if IsNativePurchasing then
	MarketplaceService.NativePurchaseFinished:connect(function(player, productId, wasPurchased)
		if wasPurchased then
			retryPurchase()
		else
			onPurchaseFailed(PURCHASE_FAILED.DID_NOT_BUY_ROBUX)
		end
		stopPurchaseAnimation()
	end)
end
