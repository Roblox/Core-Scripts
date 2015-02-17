-- this script creates the gui and sends the web requests for in game purchase prompts

-- wait for important items to appear
while not Game do
	wait(0.1)
end
while not game:GetService("MarketplaceService") do
	wait(0.1)
end
while not game:FindFirstChild("CoreGui") do
	wait(0.1)
end
while not game:GetService("CoreGui"):FindFirstChild("RobloxGui") do
	wait(0.1)
end

-------------------------------- Global Variables ----------------------------------------
-- utility variables
local RbxUtility = nil
local baseUrl = game:GetService("ContentProvider").BaseUrl:lower()
baseUrl = string.gsub(baseUrl,"/m.","/www.") --mobile site does not work for this stuff!

local doNativePurchasing = true

-- data variables
local currentProductInfo, currentAssetId, currentCurrencyType, currentCurrencyAmount, currentEquipOnPurchase, currentProductId, currentServerResponseTable, thirdPartyProductName
local checkingPlayerFunds = false 
local purchasingConsumable = false
local isFailedNativePurchase = false

-- gui variables
local currentlyPrompting = false
local currentlyPurchasing = false
local purchaseDialog, errorDialog = nil
local tweenTime = 0.3
local showPosition = UDim2.new(0.5,-217,0.5,-146)
local hidePosition = UDim2.new(0.5,-217,1,25)
local isSmallScreen = nil
local spinning = false
local spinnerIcons = nil
local smallScreenThreshold = 450
local renderSteppedConnection = nil

-- user facing images
local assetUrls = {}
local assetUrl = "http://www.roblox.com/Asset/?id=" 
local errorImageUrl = assetUrl .. "42557901" table.insert(assetUrls, errorImageUrl)
local buyImageUrl = assetUrl .. "142494143" table.insert(assetUrls,buyImageUrl)
local cancelButtonImageUrl = assetUrl .. "142494219" table.insert(assetUrls, cancelButtonImageUrl)
local freeButtonImageDownUrl = assetUrl .. "104651761" table.insert(assetUrls, freeButtonImageDownUrl)
local loadingImage = assetUrl .. "143116791" table.insert(assetUrls,loadingImage)

-- user facing string
local buyHeaderText = "Buy Item"
local takeHeaderText = "Take Item"
local buyFailedHeaderText = "An Error Occurred"

local errorPurchasesDisabledText = "In-game purchases are disabled"
local errorPurchasesBuyRobuxText = "your account does not have enough Robux"
local errorPurchasesUnknownText = "Roblox is performing maintenance"

local purchaseSucceededText = "Your purchase of itemName succeeded!"
local purchaseFailedText = "Your purchase of itemName failed because errorReason. Your account has not been charged. Please try again soon."
local productPurchaseText = "Would you like to buy the itemName assetType for currencyTypecurrencyAmount?"
local productPurchaseTixOnlyText = "Would you like to buy the itemName assetType for currencyAmount currencyType?"
local freeItemPurchaseText = "Would you like to take the assetType itemName for FREE?"
local freeItemBalanceText = "Your balance of Robux or Tix will not be affected by this transaction."
local upgradeBCText = "You require an upgrade to your Builders Club membership to purchase this item. Click 'Buy Builders Club' to upgrade."
local productPurchaseWithMoreRobuxText = "Buy robuxToBuyAmount$R to get itemName assetType."
local productPurchaseWithMoreRobuxRemainderText = "The remaining purchaseRemainder$R will be credited to your ROBUX balance."
local balanceFutureTenseText = "Your balance after this transaction will be "
local balanceCurrentTenseText = "Your balance is now "

-- robux product arrays
local bcRobuxProducts 		= 	{90, 180, 270, 360, 450, 1000, 2750}
local nonBcRobuxProducts	= 	{80, 160, 240, 320, 400, 800,  2000}
-------------------------------- End Global Variables ----------------------------------------


----------------------------- Util Functions ---------------------------------------------
function getSecureApiBaseUrl()
	local secureApiUrl = baseUrl
	secureApiUrl = string.gsub(secureApiUrl,"http","https")
	secureApiUrl = string.gsub(secureApiUrl,"www","api")
	return secureApiUrl
end

function getRbxUtility()
	if not RbxUtility then
		RbxUtility = LoadLibrary("RbxUtility")
	end
	return RbxUtility
end

function preloadAssets()
	for i = 1, #assetUrls do
		game:GetService("ContentProvider"):Preload(assetUrls[i])
	end
end

function shouldCheckMarketplaceAvailable()
	local success, checkFlagValue = pcall(function() return settings():GetFFlag("CheckMarketplaceAvailable") end)
	if success and checkFlagValue == true then
		return true
	else
		return false
	end
end

function isMarketplaceDown()
	local success, downFlagValue = pcall(function() return settings():GetFFlag("Order66") end)
	if success and downFlagValue == true then
		return true
	else
		return false
	end
end
----------------------------- End Util Functions ---------------------------------------------


-------------------------------- Accept/Decline Functions --------------------------------------
function removeCurrentPurchaseInfo()
	currentAssetId = nil
	currentCurrencyType = nil
	currentCurrencyAmount = nil
	currentEquipOnPurchase = nil
	currentProductId = nil
	currentProductInfo = nil
	currentServerResponseTable = nil
	isFailedNativePurchase = false

	checkingPlayerFunds = false
end

function userPurchaseActionsEnded(isSuccess)
	checkingPlayerFunds = false

	purchaseDialog.BodyFrame.AfterBalanceText.Visible = false

	if isSuccess then -- show the user we bought the item successfully, when they close this dialog we will call signalPromptEnded
		local newPurchasedSucceededText = string.gsub( purchaseSucceededText,"itemName", tostring(currentProductInfo["Name"]))
		purchaseDialog.BodyFrame.ItemDescription.Text = newPurchasedSucceededText

		local playerBalance = getPlayerBalance()
		local keyWord = "robux"
		if currentCurrencyType == Enum.CurrencyType.Tix then
			keyWord = "tickets"
		end
		
		local afterBalanceNumber = playerBalance[keyWord]
		purchaseDialog.BodyFrame.AfterBalanceText.Text = tostring(balanceCurrentTenseText) .. currencyTypeToString(currentCurrencyType) .. tostring(afterBalanceNumber) .. "."
		purchaseDialog.BodyFrame.AfterBalanceText.Visible = true

		setButtonsVisible(purchaseDialog.BodyFrame.OkPurchasedButton)
		hidePurchasing()
	else -- otherwise we didn't purchase, no need to show anything, just signal and close dialog
		signalPromptEnded(isSuccess)
	end
end

function signalPromptEnded(isSuccess)
	closePurchasePrompt()
	if purchasingConsumable then
		game:GetService("MarketplaceService"):SignalPromptProductPurchaseFinished(game:GetService("Players").LocalPlayer.userId, currentProductId, isSuccess)
	else
		game:GetService("MarketplaceService"):SignalPromptPurchaseFinished(game:GetService("Players").LocalPlayer, currentAssetId, isSuccess)
	end
	removeCurrentPurchaseInfo()
end

function getClosestRobuxProduct(amountNeededToBuy, robuxProductArray)
	local closest = robuxProductArray[1];
	local closestIndex = 1

	for i = 1, #robuxProductArray do 
  		if ( math.abs(robuxProductArray[i] - amountNeededToBuy) < math.abs(closest - amountNeededToBuy) ) then
  			closest = robuxProductArray[i]
  			closestIndex = i
  		end
	end

	if closest < amountNeededToBuy then
		closest = robuxProductArray[1 + closestIndex]
	end

	return closest
end

--todo: get productIds from server instead of embedding values
function getMinimumProductNeededForPurchase(amountNeededToBuy)
	local isBcMember = (Game:GetService("Players").LocalPlayer.MembershipType ~= Enum.MembershipType.None)
	local productAmount = nil

	if isBcMember then
		productAmount = getClosestRobuxProduct(amountNeededToBuy, bcRobuxProducts)
	else
		productAmount = getClosestRobuxProduct(amountNeededToBuy, nonBcRobuxProducts)
	end

	local isAndroid = false
	pcall(function() isAndroid = (Game:GetService("UserInputService"):GetPlatform() == Enum.Platform.Android) end)

	local prependString = ""
	local appendString = ""
	local appPrefix = ""

	if isAndroid then
		prependString = "robux"
		if isBcMember then
			appendString = "bc"
		end
		appPrefix = "com.roblox.client."
	else
		if isBcMember then
			appendString = "RobuxBC"
		else
			appendString = "RobuxNonBC"
		end

		appPrefix = "com.roblox.robloxmobile."
	end
	
	local productString = appPrefix .. prependString .. tostring(productAmount) .. appendString

	return productAmount, productString
end

function getClosestRobuxProductToBuyItem(productAmount, playerBalanceInRobux)
	local amountNeededToBuy = productAmount - playerBalanceInRobux
	local amountToBuy, productName = getMinimumProductNeededForPurchase(amountNeededToBuy)
	if not amountToBuy then
		return
	end
	local remainderAfterPurchase = amountToBuy - productAmount

	return amountToBuy, remainderAfterPurchase, productName
end

function canUseNewRobuxToProductFlow()
	return (Game:GetService("UserInputService").TouchEnabled and doNativePurchasing)
end

-- make sure our gui displays the proper purchase data, and set the productid we will try and buy if use specifies a buy action
function updatePurchasePromptData(insufficientFunds)
	local newItemDescription = ""

	-- id to use when we request a purchase
	if not currentProductId then
		currentProductId = currentProductInfo["ProductId"]
	end

	if isFreeItem() then
		newItemDescription = string.gsub( freeItemPurchaseText,"itemName", tostring(currentProductInfo["Name"]))
		newItemDescription = string.gsub( newItemDescription,"assetType", tostring(assetTypeToString(currentProductInfo["AssetTypeId"])) )
		setHeaderText(takeHeaderText)
	elseif insufficientFunds and canUseNewRobuxToProductFlow() then
		local purchaseText = productPurchaseWithMoreRobuxText

		local playerBalance = getPlayerBalance()
		if not playerBalance then
			newItemDescription = "Could not retrieve your balance. Please try again later."
		elseif canUseNewRobuxToProductFlow() then
			local amountToBuy, remainderAfterPurchase, productName = getClosestRobuxProductToBuyItem(currentCurrencyAmount, playerBalance["robux"])
			thirdPartyProductName = productName

			if not amountToBuy then
				newItemDescription = "This item cost more ROBUX than you can purchase. To purchase more ROBUX, please visit www.roblox.com"
				isFailedNativePurchase = true
			else
				newItemDescription = string.gsub( purchaseText,"itemName", tostring(currentProductInfo["Name"]))
				newItemDescription = string.gsub( newItemDescription,"assetType", tostring(assetTypeToString(currentProductInfo["AssetTypeId"])) )
			    newItemDescription = string.gsub( newItemDescription,"robuxToBuyAmount", tostring(amountToBuy))

			    if remainderAfterPurchase and remainderAfterPurchase > 0 then
					newItemDescription = newItemDescription .. " " .. string.gsub( productPurchaseWithMoreRobuxRemainderText,"purchaseRemainder", tostring(remainderAfterPurchase))
			    end
			end
		end
		setHeaderText(buyHeaderText)
	else
		local purchaseText = productPurchaseText
		if currentProductIsTixOnly() then
			purchaseText = productPurchaseTixOnlyText 
		end

		newItemDescription = string.gsub( purchaseText,"itemName", tostring(currentProductInfo["Name"]))
		newItemDescription = string.gsub( newItemDescription,"assetType", tostring(assetTypeToString(currentProductInfo["AssetTypeId"])) )
		newItemDescription = string.gsub( newItemDescription,"currencyType", tostring(currencyTypeToString(currentCurrencyType)) )
	    newItemDescription = string.gsub( newItemDescription,"currencyAmount", tostring(currentCurrencyAmount))
	    setHeaderText(buyHeaderText)
	end

	purchaseDialog.BodyFrame.ItemDescription.Text = newItemDescription

	if purchasingConsumable then
		purchaseDialog.BodyFrame.ItemPreview.Image = baseUrl .. "thumbs/asset.ashx?assetid=" .. tostring(currentProductInfo["IconImageAssetId"]) .. '&x=100&y=100&format=png'
	else
		purchaseDialog.BodyFrame.ItemPreview.Image = baseUrl .. "thumbs/asset.ashx?assetid=" .. tostring(currentAssetId) .. '&x=100&y=100&format=png'
	end
end

function checkIfCanPurchase()
	if checkingPlayerFunds then
		local canPurchase, insufficientFunds, notRightBC = canPurchaseItem() -- check again to see if we can buy item
		if not canPurchase or (insufficientFunds or notRightBC) then -- wait a bit and try a few more times
			local retries = 20
			while retries > 0 and (insufficientFunds or notRightBC) and checkingPlayerFunds and canPurchase do 
				wait(0.5)
				canPurchase, insufficientFunds, notRightBC = canPurchaseItem()
				retries = retries - 1
			end
		end
		if canPurchase and not insufficientFunds then
			-- we can buy item! set our buttons up and we will exit this loop
			setButtonsVisible(purchaseDialog.BodyFrame.BuyButton,purchaseDialog.BodyFrame.CancelButton, purchaseDialog.BodyFrame.AfterBalanceText)
		end
	end
end

function closePurchasePrompt()
	purchaseDialog:TweenPosition(hidePosition, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, tweenTime, true, function()
		game:GetService("GuiService"):RemoveCenterDialog(purchaseDialog)
		hidePurchasing()

		purchaseDialog.Visible = false
		currentlyPrompting = false
		currentlyPurchasing = false

		Game:GetService("UserInputService").ModalEnabled = false
	end)
end

function cancelPurchase()
	game:GetService("GuiService"):AddCenterDialog(purchaseDialog, Enum.CenterDialogType.ModalDialog,
			--ShowFunction
					function()
						-- set the state for our buttons
						purchaseDialog.Visible = true

						if not currentlyPurchasing then
							setButtonsVisible(purchaseDialog.BodyFrame.OkButton)
						end

						Game:GetService("UserInputService").ModalEnabled = true
						purchaseDialog:TweenPosition(showPosition, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, tweenTime, true)
					end,
			--HideFunction
					function()
						Game:GetService("UserInputService").ModalEnabled = false
						purchaseDialog.Visible = false
					end)

	purchaseFailed("inGamePurchasesDisabled")
end

function showPurchasePrompt()
	local canPurchase, insufficientFunds, notRightBC, override, descText = canPurchaseItem()	

	if isMarketplaceDown() then
		print("tried to show purchase, but local purchasing is disabled")
		cancelPurchase()
		return
	end

	if shouldCheckMarketplaceAvailable() then
		local response = nil
		local success, errorReason = pcall(function() response = game:GetService("HttpRbxApiService"):GetAsync("my/economy-status", false, Enum.ThrottlingPriority.Extreme) end)

		if success then
			local responseTable = game:GetService("HttpService"):JSONDecode(response)
			if responseTable["isMarketplaceEnabled"] ~= nil then
				if responseTable["isMarketplaceEnabled"] == false then
					print("tried to show purchase, but my/economy-status isMarketplaceEnabled is false")
					cancelPurchase()
				end
			end
		else
			print("tried to show purchase, but my/economy-status failed because",errorReason)
			cancelPurchase()
			return
		end
	end

	if canPurchase then
		updatePurchasePromptData(insufficientFunds)

		if override and descText then 
			purchaseDialog.BodyFrame.ItemDescription.Text = descText
			purchaseDialog.BodyFrame.AfterBalanceText.Visible = false
		end 
		game:GetService("GuiService"):AddCenterDialog(purchaseDialog, Enum.CenterDialogType.ModalDialog,
					--ShowFunction
					function()
						-- set the state for our buttons
						purchaseDialog.Visible = true

						if not currentlyPurchasing then
							if canUseNewRobuxToProductFlow() and isFailedNativePurchase then
								setButtonsVisible(purchaseDialog.BodyFrame.OkButton)
							elseif isFreeItem() then
								setButtonsVisible(purchaseDialog.BodyFrame.FreeButton, purchaseDialog.BodyFrame.CancelButton)
							elseif notRightBC then
								setButtonsVisible(purchaseDialog.BodyFrame.BuyBCButton, purchaseDialog.BodyFrame.CancelButton)
							elseif insufficientFunds then
								setButtonsVisible(purchaseDialog.BodyFrame.BuyRobuxButton, purchaseDialog.BodyFrame.CancelButton)						
							elseif override then 
								if currentProductIsTixOnly() then
									purchaseDialog.BodyFrame.AfterBalanceText.Visible = true
								end
								setButtonsVisible(purchaseDialog.BodyFrame.BuyDisabledButton, purchaseDialog.BodyFrame.CancelButton)
							else
								setButtonsVisible(purchaseDialog.BodyFrame.BuyButton, purchaseDialog.BodyFrame.CancelButton)
							end
						end

						Game:GetService("UserInputService").ModalEnabled = true

						purchaseDialog:TweenPosition(showPosition, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, tweenTime, true)
					end,
					--HideFunction
					function()
						Game:GetService("UserInputService").ModalEnabled = false
						purchaseDialog.Visible = false
					end)
	else -- we failed in prompting a purchase, do a decline
		doDeclinePurchase()
	end
end

-- given an asset id, this function will grab that asset from the website, and return the first "Tool" object found inside it
function getToolAssetID(assetID)
	local newTool = game:GetService("InsertService"):LoadAsset(assetID)
	if not newTool then return nil end

	if newTool:IsA("Tool") then
		return newTool
	end

	local toolChildren = newTool:GetChildren()
	for i = 1, #toolChildren do
		if toolChildren[i]:IsA("Tool") then
			return toolChildren[i]
		end
	end
	return nil
end

-- the user tried to purchase by clicking the purchase button, but something went wrong.
-- let them know their account was not charged, and that they do not own the item yet. 
function purchaseFailed(errorType)
	local name = "Item"
	if currentProductInfo then name = currentProductInfo["Name"] end

	local newPurchasedFailedText = string.gsub( purchaseFailedText,"itemName", tostring(name))

	if errorType == "inGamePurchasesDisabled" then
		newPurchasedFailedText = string.gsub( newPurchasedFailedText,"errorReason", tostring(errorPurchasesDisabledText) )
	elseif errorType == "didNotBuyRobux" then
		newPurchasedFailedText = string.gsub( newPurchasedFailedText,"errorReason", tostring(errorPurchasesBuyRobuxText) )
	else
		newPurchasedFailedText = string.gsub( newPurchasedFailedText,"errorReason", tostring(errorPurchasesUnknownText) )
	end

	purchaseDialog.BodyFrame.ItemDescription.Text = newPurchasedFailedText
	purchaseDialog.BodyFrame.ItemPreview.Image = errorImageUrl
	purchaseDialog.BodyFrame.AfterBalanceText.Text = ""

	setButtonsVisible(purchaseDialog.BodyFrame.OkButton)

	setHeaderText(buyFailedHeaderText)

	hidePurchasing()
end

-- user has specified they want to buy an item, now try to attempt to buy it for them
function doAcceptPurchase(currencyPreferredByUser)
	if currentlyPurchasing then return end
	currentlyPurchasing = true

	showPurchasing() -- shows a purchasing ui (shows spinner)

	local startTime = tick()

	-- http call to do the purchase
	local response = "none"
	local url = nil

	-- consumables need to use a different url
	if purchasingConsumable then
		url =  getSecureApiBaseUrl() .. "marketplace/submitpurchase?productId=" .. tostring(currentProductId) ..
				"&currencyTypeId=" .. tostring(currencyEnumToInt(currentCurrencyType)) .. 
				"&expectedUnitPrice=" .. tostring(currentCurrencyAmount) ..
				"&placeId=" .. tostring(Game.PlaceId)
		local h = game:GetService("HttpService")
		url = url .. "&requestId=" .. h:UrlEncode(h:GenerateGUID(false))
	else
		url = getSecureApiBaseUrl() .. "marketplace/purchase?productId=" .. tostring(currentProductId) .. 
			"&currencyTypeId=" .. tostring(currencyEnumToInt(currentCurrencyType)) .. 
			"&purchasePrice=" .. tostring(currentCurrencyAmount or 0) ..
			"&locationType=Game" .. "&locationId=" .. Game.PlaceId
	end

	local success, reason = ypcall(function() 
		response = game:HttpPostAsync(url, "RobloxPurchaseRequest") 
	end)

	if purchasingConsumable then
		local retriesLeft = 3
		local gotGoodResponse = success and response ~= "none" and response ~= nil and response ~= ''
		while retriesLeft > 0 and (not gotGoodResponse) do
			wait(1)
			retriesLeft = retriesLeft - 1
			success, reason = ypcall(function() 
				response = game:HttpPostAsync(url, "RobloxPurchaseRequest") 
			end)
			gotGoodResponse = success and response ~= "none" and response ~= nil and response ~= ''
		end

		game:ReportInGoogleAnalytics("Developer Product", "Purchase",
			gotGoodResponse and ("success. Retries = " .. (3 - retriesLeft)) or ("failure: " .. tostring(reason)), 1)
	end

	-- debug output for us (found in the logs from local)
	print("doAcceptPurchase success from ypcall is ",success,"reason is",reason)

	if (tick() - startTime) < 1 then
		wait(1) -- allow the purchasing waiting dialog to at least be readable (otherwise it might flash, looks bad)...
	end

	-- check to make sure purchase actually happened on the web end
	if response == "none" or response == nil or response == '' then
		print("did not get a proper response from web on purchase of",currentAssetId,currentProductId)
		purchaseFailed()
		return
	end

	-- parse our response, decide how to react
	response = getRbxUtility().DecodeJSON(response)

	if response then
		if response["success"] == false then
			if response["status"] ~= "AlreadyOwned" then
				print("web return response of fail on purchase of",currentAssetId,currentProductId)
				if (response["status"] == "EconomyDisabled") then
					purchaseFailed("inGamePurchasesDisabled")
				else
					purchaseFailed()
				end
				return
			end
		end
	else
		print("web return response of non parsable JSON on purchase of",currentAssetId)
		purchaseFailed()
		return
	end

	-- check to see if this item was bought, and if we want to equip it (also need to make sure the asset type was gear)
	if currentEquipOnPurchase and success and currentAssetId and tonumber(currentProductInfo["AssetTypeId"]) == 19 then
		local tool = getToolAssetID(tonumber(currentAssetId))
		if tool then
			tool.Parent = game:GetService("Players").LocalPlayer.Backpack
		end
	end

	if purchasingConsumable then
		if not response["receipt"] then
			print("tried to buy productId, but no receipt returned. productId was",currentProductId)
			purchaseFailed()
			return
		end
		Game:GetService("MarketplaceService"):SignalClientPurchaseSuccess( tostring(response["receipt"]), game:GetService("Players").LocalPlayer.userId, currentProductId )
	else
		userPurchaseActionsEnded(success)
	end
end

-- user pressed the cancel button, just remove all purchasing prompts
function doDeclinePurchase()
	if currentlyPurchasing then return end
	userPurchaseActionsEnded(false)
end
-------------------------------- End Accept/Decline Functions --------------------------------------


---------------------------------------------- Currency Functions ---------------------------------------------
-- enums have no implicit conversion to numbers in lua, has to have a function to do this
function currencyEnumToInt(currencyEnum)
	if currencyEnum == Enum.CurrencyType.Robux or currencyEnum == Enum.CurrencyType.Default then
		return 1
	elseif currencyEnum == Enum.CurrencyType.Tix then
		return 2
	end
end

-- oi, this isn't so ugly anymore
function assetTypeToString(assetType)
	local assetTypes = {
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
		[0]  = "Product";
	}
	return assetTypes[assetType] or ""
end

function currencyTypeToString(currencyType)
	if currencyType == Enum.CurrencyType.Tix then 
		return "Tix"
	else
		return "R$"
	end
end

-- figure out what currency to use based on the currency you can actually sell the item in and what the script specified
function setCurrencyAmountAndType(priceInRobux, priceInTix)
	if currentCurrencyType == Enum.CurrencyType.Default or currentCurrencyType == Enum.CurrencyType.Robux then -- sell for default (user doesn't care) or robux
		if priceInRobux ~= nil and priceInRobux ~= 0 then -- we can sell for robux
			currentCurrencyAmount = priceInRobux
			currentCurrencyType = Enum.CurrencyType.Robux
		else -- have to use tix
			currentCurrencyAmount = priceInTix
			currentCurrencyType = Enum.CurrencyType.Tix
		end
	elseif currentCurrencyType == Enum.CurrencyType.Tix then -- we want to sell for tix
		if priceInTix ~= nil and priceInTix ~= 0 then -- we can sell for tix
			currentCurrencyAmount = priceInTix
			currentCurrencyType = Enum.CurrencyType.Tix
		else -- have to use robux
			currentCurrencyAmount = priceInRobux
			currentCurrencyType = Enum.CurrencyType.Robux
		end
	else
		return false
	end

	if currentCurrencyAmount == nil then
		return false
	end

	return true
end

-- will get the player's balance of robux and tix, return in a table
function getPlayerBalance()
	local playerBalance = nil
	local success, errorCode = ypcall(function() playerBalance = game:HttpGetAsync(getSecureApiBaseUrl() .. "currency/balance") end)
	if not success then
		print("Get player balance failed because",errorCode)
		return nil
	end

	if playerBalance == '' then
		return nil
	end

	playerBalance = getRbxUtility().DecodeJSON(playerBalance)

	return playerBalance
end

-- should open an external default browser window to this url
function openBuyCurrencyWindow()
	checkingPlayerFunds = true
	game:GetService("GuiService"):OpenBrowserWindow(baseUrl .. "Upgrades/Robux.aspx")
end

function buyEnoughCurrencyForProduct()
	showPurchasing()
	Game:GetService("MarketplaceService"):PromptNativePurchase(Game:GetService("Players").LocalPlayer, thirdPartyProductName)
end

function openBCUpSellWindow()
	checkingPlayerFunds = true
	Game:GetService('GuiService'):OpenBrowserWindow(baseUrl .. "Upgrades/BuildersClubMemberships.aspx")
end 

-- set up the gui text at the bottom of the prompt (alerts user to how much money they will have left, or if they need to buy more to buy the item)
function updateAfterBalanceText(playerBalance, notRightBc, balancePreText)
	if isFreeItem() then
		purchaseDialog.BodyFrame.AfterBalanceText.Text = freeItemBalanceText
		return true, false
	end

	local keyWord = nil
	if currentCurrencyType == Enum.CurrencyType.Robux then
		keyWord = "robux"
	elseif currentCurrencyType == Enum.CurrencyType.Tix then
		keyWord = "tickets"
	end

	if not keyWord then
		return false
	end

	local playerBalanceNumber = tonumber(playerBalance[keyWord])
	if not playerBalanceNumber then
		return false
	end

	local afterBalanceNumber = playerBalanceNumber - currentCurrencyAmount

	-- check to see if we have enough of the desired currency to allow a purchase, if not we need to prompt user to buy robux
	if not notRightBc then 
		if afterBalanceNumber < 0 and keyWord == "robux" then
			purchaseDialog.BodyFrame.AfterBalanceText.Text = ""
			return true, true
		elseif afterBalanceNumber < 0 and keyWord == "tickets" then
			purchaseDialog.BodyFrame.AfterBalanceText.Text = "You need " .. tostring(-afterBalanceNumber) .. " " .. currencyTypeToString(currentCurrencyType) .. " more to buy this item."
			return true, true -- user can't buy more tickets, so we say fail the transaction (maybe instead we can prompt them to trade currency???)
		end
	else
		purchaseDialog.BodyFrame.AfterBalanceText.Text = upgradeBCText
		return true, false
	end

	if currentProductIsTixOnly() then
		purchaseDialog.BodyFrame.AfterBalanceText.Text = tostring(balancePreText) .. tostring(afterBalanceNumber) .. " " .. currencyTypeToString(currentCurrencyType) .. "."
	else
		purchaseDialog.BodyFrame.AfterBalanceText.Text = tostring(balancePreText) .. currencyTypeToString(currentCurrencyType) .. tostring(afterBalanceNumber) .. "."
	end
	purchaseDialog.BodyFrame.AfterBalanceText.Visible = true
	return true, false
end

function isFreeItem()
	-- Apparently free items have 'IsForSale' set to false, but 'IsPublicDomain' set to true
	-- Example: https://api.roblox.com/marketplace/productinfo?assetid=163811695
	-- I've tested it, if you take it off the public domain, 'IsPublicDomain' is of course false
	return currentProductInfo and currentProductInfo["IsPublicDomain"] == true
end
---------------------------------------------- End Currency Functions ---------------------------------------------


---------------------------------------------- Data Functions -----------------------------------------------------

-- more enum to int fun!
function membershipTypeToNumber(membership)
	if membership == Enum.MembershipType.None then
		return 0
	elseif membership == Enum.MembershipType.BuildersClub then
		return 1
	elseif membership == Enum.MembershipType.TurboBuildersClub then
		return 2
	elseif membership == Enum.MembershipType.OutrageousBuildersClub then
		return 3
	end

	return -1
end

function currentProductIsTixOnly()
	local priceInRobux = currentProductInfo["PriceInRobux"]
	local priceInTix = currentProductInfo["PriceInTickets"]

	if priceInRobux == nil then return true end
	priceInRobux = tonumber(priceInRobux)
	if priceInRobux == nil then return true end

	if priceInTix == nil then return false end
	priceInTix = tonumber(priceInTix)
	if priceInTix == nil then return false end

	return (priceInRobux <= 0 and priceInTix > 0)
end

-- This functions checks to make sure the purchase is even possible, if not it returns false and we don't prompt user (some situations require user feedback when we won't prompt)
function canPurchaseItem()

	-- first we see if player already owns the asset/get the productinfo
	local playerOwnsAsset = false	
	local notRightBc = false 
	local descText = nil
	local getProductSuccess = false
	local getProductErrorReason = ""

	if purchasingConsumable then
		getProductSuccess, getProductErrorReason = pcall(function() currentProductInfo = game:GetService("MarketplaceService"):GetProductInfo(currentProductId, Enum.InfoType.Product) end)
	else
		getProductSuccess, getProductErrorReason = pcall(function() currentProductInfo = game:GetService("MarketplaceService"):GetProductInfo(currentAssetId) end)
	end

	if getProductSuccess == false or currentProductInfo == nil then
		print("could not get product info because",getProductErrorReason)
		descText = "In-game sales are temporarily disabled. Please try again later."
		return false, nil, nil, true, descText 
	end

	if not purchasingConsumable then
		if not currentAssetId then
			return false
		end
		if currentAssetId <= 0 then
			return false
		end

		local success, errorCode = ypcall(function() playerOwnsAsset = game:HttpGetAsync(getSecureApiBaseUrl() 
			.. "ownership/hasAsset?userId=" 
			.. tostring(game:GetService("Players").LocalPlayer.userId) 
			.. "&assetId=" .. tostring(currentAssetId))
		end)

		if not success then
			return false
		end

		if playerOwnsAsset == true or playerOwnsAsset == "true" then		
			descText = "You already own this item." 
			return true, nil, nil, true, descText 
		end
	end
	
	-- For public models, as there is still the freeButton, indicating it should be
	-- available, while this function (canPurchaseItem) doesn't count on free stuff
	if isFreeItem() then
		return true	
	end

	purchaseDialog.BodyFrame.AfterBalanceText.Visible = true 

	-- next we parse through product info and see if we can purchase

	if type(currentProductInfo) ~= "table" then
		currentProductInfo = getRbxUtility().DecodeJSON(currentProductInfo)
	end

	if not currentProductInfo then
		descText = "Could not get product info. Please try again later."
		return true, nil, nil, true, descText
	end

	if currentProductInfo["IsForSale"] == false and currentProductInfo["IsPublicDomain"] == false then
		descText = "This item is no longer for sale." 		
		return true, nil, nil, true, descText 
	end

	-- now we start talking money, making sure we are going to be able to purchase this
	if not setCurrencyAmountAndType(tonumber(currentProductInfo["PriceInRobux"]), tonumber(currentProductInfo["PriceInTickets"])) then
		descText = "We couldn't retrieve the price of the item correctly. Please try again later." 
		return true, nil, nil, true, descText
	end	

	local playerBalance = getPlayerBalance()
	if not playerBalance then
		descText = "Could not retrieve your balance. Please try again later."
		return true, nil, nil, true, descText
	end

	if tonumber(currentProductInfo["MinimumMembershipLevel"]) > membershipTypeToNumber(game:GetService("Players").LocalPlayer.MembershipType) then				
		notRightBc = true 		
	end

	local updatedBalance, insufficientFunds = updateAfterBalanceText(playerBalance, notRightBc, balanceFutureTenseText)

	if notRightBc then 
		purchaseDialog.BodyFrame.AfterBalanceText.Active = true
		return true, insufficientFunds, notRightBc, false 
	end 

	if currentProductInfo["ContentRatingTypeId"] == 1 then
		if game:GetService("Players").LocalPlayer:GetUnder13() then
			descText = "Your account is under 13 so purchase of this item is not allowed." 			
			return true, nil, nil, true, descText 
		end
	end

	if (currentProductInfo["IsLimited"] == true or currentProductInfo["IsLimitedUnique"] == true) and
		(currentProductInfo["Remaining"] == "" or currentProductInfo["Remaining"] == 0 or currentProductInfo["Remaining"] == nil) then
			descText = "All copies of this item have been sold out! Try buying from other users on www.roblox.com." 			
			return true, nil, nil, true, descText 
	end	

	if not updatedBalance then
		descText = 'Could not update your balance. Please check back after some time.'		
		return true, nil, nil, true, descText
	end

	if insufficientFunds then
		-- if this is a ticket only time and we don't have enough, tell the user to get more tix
		if currentProductIsTixOnly() then
			descText = "This item costs more tickets than you currently have! Try trading currency on www.roblox.com to get more tickets." 			
			return true, nil, nil, true, descText 
		end
	end

	-- we use insufficient funds to display a prompt to buy more robux
	return true, insufficientFunds
end

---------------------------------------------- End Data Functions -----------------------------------------------------


---------------------------------------------- Gui Functions ----------------------------------------------
function startSpinner()
	if purchaseDialog.PurchasingFrame.Visible then return end
	purchaseDialog.PurchasingFrame.Visible = true

	renderSteppedConnection = Game:GetService("RunService").RenderStepped:connect(function()
									purchaseDialog.PurchasingFrame.PurchasingSpinnerOuter.Rotation = purchaseDialog.PurchasingFrame.PurchasingSpinnerOuter.Rotation + 7
									purchaseDialog.PurchasingFrame.PurchasingSpinnerInner.Rotation = purchaseDialog.PurchasingFrame.PurchasingSpinnerInner.Rotation - 9
							  end)
end

function stopSpinner()
	if renderSteppedConnection then
		renderSteppedConnection:disconnect()
		renderSteppedConnection = nil
		purchaseDialog.PurchasingFrame.Visible = false
	end
end

-- next two functions control the "Purchasing..." overlay
function showPurchasing()
	startSpinner()
end

function hidePurchasing()
	stopSpinner()
end

-- convenience method to say exactly what buttons should be visible (all others are not!)
function setButtonsVisible(...)
	local args = {...}
	local argCount = select('#', ...)

	local bodyFrameChildren = purchaseDialog.BodyFrame:GetChildren()
	for i = 1, #bodyFrameChildren do
		if bodyFrameChildren[i]:IsA("GuiButton") then
			bodyFrameChildren[i].Visible = false
			for j = 1, argCount do
				if bodyFrameChildren[i] == args[j] then
					bodyFrameChildren[i].Visible = true
					break
				end
			end
		end
	end
end

-- all the gui init.  Would be nice if this didn't have to be a script
function createPurchasePromptGui()
	purchaseDialog = Instance.new("Frame")
	purchaseDialog.Name = "PurchaseFrame"
	purchaseDialog.Size = UDim2.new(0,435,0,292)
	purchaseDialog.Position = hidePosition
	purchaseDialog.Active = true
	purchaseDialog.Visible = false
	purchaseDialog.BackgroundColor3 = Color3.new(225/255,225/255,225/255)
	purchaseDialog.BorderSizePixel = 0
	purchaseDialog.ZIndex = 8
	purchaseDialog.Parent = game:GetService("CoreGui").RobloxGui

	local bodyFrame = Instance.new("Frame")
	bodyFrame.Name = "BodyFrame"
	bodyFrame.Active = true
	bodyFrame.Size = UDim2.new(1,-10,1,-55)
	bodyFrame.Position = UDim2.new(0,5,0,50)
	bodyFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	bodyFrame.BorderSizePixel = 0
	bodyFrame.ZIndex = 8
	bodyFrame.Parent = purchaseDialog

	local titleLabel = createTextObject("TitleLabel", "Buy Item", "TextLabel", Enum.FontSize.Size36)
	titleLabel.Active = true
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextColor3 = Color3.new(54/255,54/255,54/255)
	titleLabel.ZIndex = 8
	titleLabel.Size = UDim2.new(1,0,0,50)
	titleLabel.Parent = purchaseDialog

	local distanceBetweenButtons = 20

	local cancelButton = createImageButton("CancelButton")
	cancelButton.Position = UDim2.new(0.5,(distanceBetweenButtons/2),1,-100)
	cancelButton.BorderColor3 = Color3.new(86/255,86/255,86/255)
	cancelButton.Parent = bodyFrame
	cancelButton.Modal = true
	cancelButton.ZIndex = 8
	cancelButton.Image = cancelButtonImageUrl
	cancelButton.MouseButton1Up:connect(function( )
		cancelButton.Image = cancelButtonImageUrl
	end)
	cancelButton.MouseLeave:connect(function( )
		cancelButton.Image = cancelButtonImageUrl
	end)
	cancelButton.MouseButton1Click:connect(doDeclinePurchase)

	local cancelText = createTextObject("CancelText","Cancel","TextLabel",Enum.FontSize.Size24)
	cancelText.TextColor3 = Color3.new(1,1,1)
	cancelText.Size = UDim2.new(1,0,1,0)
	cancelText.ZIndex = 8
	cancelText.Parent = cancelButton

	local cancelHoverFrame = Instance.new("Frame")
	cancelHoverFrame.Name = "HoverFrame"
	cancelHoverFrame.Size = UDim2.new(1,0,1,0)
	cancelHoverFrame.BackgroundColor3 = Color3.new(1,1,1)
	cancelHoverFrame.BackgroundTransparency = 0.7
	cancelHoverFrame.BorderSizePixel = 0
	cancelHoverFrame.Visible = false
	cancelHoverFrame.ZIndex = 8
	cancelHoverFrame.Parent = cancelButton
	cancelButton.MouseEnter:connect(function()
		cancelHoverFrame.Visible = true
	end)
	cancelButton.MouseLeave:connect(function( )
		cancelHoverFrame.Visible = false
	end)
	cancelButton.MouseButton1Click:connect(function( )
		cancelHoverFrame.Visible = false
	end)

	local buyButton = createImageButton("BuyButton")
	buyButton.Position = UDim2.new(0.5,-117-(distanceBetweenButtons/2),1,-100)
	buyButton.BorderColor3 = Color3.new(0,112/255,1/255)
	buyButton.Image = buyImageUrl
	buyButton.ZIndex = 8
	buyButton.Parent = bodyFrame

	local buyText = createTextObject("BuyText","Buy Now","TextLabel",Enum.FontSize.Size24)
	buyText.ZIndex = 8
	buyText.TextColor3 = Color3.new(1,1,1)
	buyText.Size = UDim2.new(1,0,1,0)
	buyText.Parent = buyButton

	local buyHoverFrame = cancelHoverFrame:Clone()
	buyButton.MouseEnter:connect(function()
		buyHoverFrame.Visible = true
	end)
	buyButton.MouseLeave:connect(function( )
		buyHoverFrame.Visible = false
	end)
	buyButton.MouseButton1Click:connect(function( )
		buyHoverFrame.Visible = false
	end)
	buyHoverFrame.Parent = buyButton

	local buyDisabledButton = buyButton:Clone()
	buyDisabledButton.Name = "BuyDisabledButton"
	buyDisabledButton.AutoButtonColor = false
	buyDisabledButton.Visible = false
	buyDisabledButton.Active = false
	buyDisabledButton.Parent = bodyFrame

	local buyRobux = buyButton:Clone()
	buyRobux.Name = "BuyRobuxButton"
	buyRobux.AutoButtonColor = false
	buyRobux.Visible = false
	buyRobux.ZIndex = 8

	if canUseNewRobuxToProductFlow() then
		buyRobux.BuyText.Text = "Buy"
	else
		buyRobux.BuyText.Text = "Buy R$"
	end

	buyRobux.MouseEnter:connect(function()
		buyRobux.HoverFrame.Visible = true
	end)
	buyRobux.MouseLeave:connect(function( )
		buyRobux.HoverFrame.Visible = false
	end)
	buyRobux.MouseButton1Click:connect(function( )
		buyRobux.HoverFrame.Visible = false

		if canUseNewRobuxToProductFlow() then
			buyEnoughCurrencyForProduct()
		else
			openBuyCurrencyWindow()
		end
	end)
	buyRobux.Parent = bodyFrame

	local buyBC = buyRobux:Clone()
	buyBC.Name = "BuyBCButton"
	buyBC.BuyText.Text = "Buy Builders Club"
	buyBC.MouseEnter:connect(function()
		buyBC.HoverFrame.Visible = true
	end)
	buyBC.MouseLeave:connect(function( )
		buyBC.HoverFrame.Visible = false
	end)
	buyBC.MouseButton1Click:connect(function( )
		buyBC.HoverFrame.Visible = false
		openBCUpSellWindow()
	end)
	buyBC.Parent = bodyFrame

	local freeButton = buyButton:Clone()
	freeButton.BuyText.Text = "Take Free"
	freeButton.BackgroundTransparency = 1
	freeButton.Name = "FreeButton"
	freeButton.Visible = false
	freeButton.MouseEnter:connect(function()
		freeButton.HoverFrame.Visible = true
	end)
	freeButton.MouseButton1Click:connect(function( )
		freeButton.HoverFrame.Visible = false
	end)
	freeButton.MouseLeave:connect(function( )
		freeButton.HoverFrame.Visible = false
	end)
	freeButton.Parent = bodyFrame

	local okButton = buyButton:Clone()
	okButton.BuyText.Text = "Ok"
	okButton.Name = "OkButton"
	okButton.Visible = false
	okButton.Position = UDim2.new(0.5,-okButton.Size.X.Offset/2,1,-100)
	okButton.Modal = true
	okButton.MouseEnter:connect(function()
		okButton.HoverFrame.Visible = true
	end)
	okButton.MouseButton1Click:connect(function( )
		okButton.HoverFrame.Visible = false
		signalPromptEnded(false)
	end)
	okButton.MouseLeave:connect(function( )
		okButton.HoverFrame.Visible = false
	end)
	okButton.Parent = bodyFrame

	local okPurchasedButton = okButton:Clone()
	okPurchasedButton.Name = "OkPurchasedButton"
	okPurchasedButton.MouseEnter:connect(function()
		okPurchasedButton.HoverFrame.Visible = true
	end)
	okPurchasedButton.MouseLeave:connect(function( )
		okPurchasedButton.HoverFrame.Visible = false
	end)
	okPurchasedButton.MouseButton1Click:connect(function() 
		okPurchasedButton.HoverFrame.Visible = false
		if purchasingConsumable then
			userPurchaseProductActionsEnded(true)
		else
			signalPromptEnded(true) 
		end
	end)
	okPurchasedButton.Parent = bodyFrame

	buyButton.MouseButton1Click:connect(function() doAcceptPurchase(Enum.CurrencyType.Robux) end)
	freeButton.MouseButton1Click:connect(function() doAcceptPurchase(false) end)

	local itemPreview = Instance.new("ImageLabel")
	itemPreview.Name = "ItemPreview"
	itemPreview.BackgroundTransparency = 1
	itemPreview.BorderSizePixel = 0
	itemPreview.Position = UDim2.new(0,20,0,20)
	itemPreview.Size = UDim2.new(0,100,0,100)
	itemPreview.ZIndex = 9
	itemPreview.Parent = bodyFrame

	local itemDescription = createTextObject("ItemDescription","","TextLabel",Enum.FontSize.Size18)
	itemDescription.TextXAlignment = Enum.TextXAlignment.Left
	itemDescription.Position = UDim2.new(0.5, -70, 0, 10)
	itemDescription.Size = UDim2.new(0,245,0,115)
	itemDescription.TextColor3 = Color3.new(54/255,54/255,54/255)
	itemDescription.ZIndex = 8
	itemDescription.Parent = bodyFrame

	local afterBalanceText = createTextObject("AfterBalanceText","","TextLabel",Enum.FontSize.Size14)
	afterBalanceText.BackgroundTransparency = 1
	afterBalanceText.TextColor3 = Color3.new(102/255,102/255,102/255)
	afterBalanceText.Position = UDim2.new(0,5,1,-33)
	afterBalanceText.Size = UDim2.new(1,-10,0,28)
	afterBalanceText.ZIndex = 8
	afterBalanceText.Parent = bodyFrame

	local purchasingFrame = Instance.new("Frame")
	purchasingFrame.Name = "PurchasingFrame"
	purchasingFrame.Size = UDim2.new(1,0,1,0)
	purchasingFrame.BackgroundColor3 = Color3.new(0,0,0)
	purchasingFrame.BackgroundTransparency = 0.05
	purchasingFrame.BorderSizePixel = 0
	purchasingFrame.ZIndex = 9
	purchasingFrame.Visible = false
	purchasingFrame.Active = true
	purchasingFrame.Parent = purchaseDialog

	local purchasingLabel = createTextObject("PurchasingLabel","Purchasing","TextLabel",Enum.FontSize.Size48)
	purchasingLabel.Size = UDim2.new(1,0,1,0)
	purchasingLabel.Position = UDim2.new(0,0,0,-24)
	purchasingLabel.ZIndex = 10
	purchasingLabel.Parent = purchasingFrame

	local purchasingSpinner = Instance.new("ImageLabel")
	purchasingSpinner.Name = "PurchasingSpinnerOuter"
	purchasingSpinner.Image = loadingImage
	purchasingSpinner.BackgroundTransparency = 1
	purchasingSpinner.BorderSizePixel = 0
	purchasingSpinner.Size = UDim2.new(0,64,0,64)
	purchasingSpinner.Position = UDim2.new(0.5,-32,0.5,32)
	purchasingSpinner.ZIndex = 10
	purchasingSpinner.Parent = purchasingFrame

	local purchasingSpinnerInner = purchasingSpinner:Clone()
	purchasingSpinnerInner.BackgroundTransparency = 1
	purchasingSpinnerInner.Name = "PurchasingSpinnerInner"
	purchasingSpinnerInner.Size = UDim2.new(0,32,0,32)
	purchasingSpinnerInner.Position = UDim2.new(0.5,-16,0.5,48)
	purchasingSpinnerInner.Parent = purchasingFrame
end

-- next 2 functions are convenienvce creation functions for guis
function createTextObject(name, text, type, size)
	local textLabel = Instance.new(type)
	textLabel.Font = Enum.Font.SourceSans
	textLabel.TextColor3 = Color3.new(217/255, 217/255, 217/255)
	textLabel.TextWrapped = true
	textLabel.Name = name
	textLabel.Text = text
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.FontSize = size

	return textLabel
end

function createImageButton(name)
	local imageButton = Instance.new("ImageButton")
	imageButton.Size = UDim2.new(0,117,0,60)
	imageButton.Name = name
	return imageButton
end

function setHeaderText(text)
	purchaseDialog.TitleLabel.Text = text
end

function doPurchasePrompt(player, assetId, equipIfPurchased, currencyType, productId)
	if not purchaseDialog then
		createPurchasePromptGui()
	end

	if player == game:GetService("Players").LocalPlayer then
		if currentlyPrompting then return end

		currentlyPrompting = true

		currentAssetId = assetId
		currentProductId = productId
		currentCurrencyType = currencyType
		currentEquipOnPurchase = equipIfPurchased

		purchasingConsumable = (currentProductId ~= nil)

		showPurchasePrompt()
	end
end

function userPurchaseProductActionsEnded(userIsClosingDialog)
	checkingPlayerFunds = false

	if userIsClosingDialog then
		closePurchasePrompt()
		if currentServerResponseTable then
			local isPurchased = false
			if tostring(currentServerResponseTable["isValid"]):lower() == "true" then
				isPurchased = true
			end

			Game:GetService("MarketplaceService"):SignalPromptProductPurchaseFinished(tonumber(currentServerResponseTable["playerId"]), tonumber(currentServerResponseTable["productId"]), isPurchased)
		end
		removeCurrentPurchaseInfo()
	else
		if tostring(currentServerResponseTable["isValid"]):lower() == "true" then
			local newPurchasedSucceededText = string.gsub( purchaseSucceededText,"itemName", tostring(currentProductInfo["Name"]))
			purchaseDialog.BodyFrame.ItemDescription.Text = newPurchasedSucceededText

			local playerBalance = getPlayerBalance()
			local keyWord = "robux"
			if currentCurrencyType == Enum.CurrencyType.Tix then
				keyWord = "tickets"
			end

			local afterBalanceNumber = playerBalance[keyWord]
			purchaseDialog.BodyFrame.AfterBalanceText.Text = tostring(balanceCurrentTenseText) .. currencyTypeToString(currentCurrencyType) .. tostring(afterBalanceNumber) .. "."

			setButtonsVisible(purchaseDialog.BodyFrame.OkPurchasedButton)
			hidePurchasing()
		else
			purchaseFailed()
		end
	end
end

function doProcessServerPurchaseResponse(serverResponseTable)
	if not serverResponseTable then
		purchaseFailed()
		return
	end

	if serverResponseTable["playerId"] and tonumber(serverResponseTable["playerId"]) == game:GetService("Players").LocalPlayer.userId then
		currentServerResponseTable = serverResponseTable
		userPurchaseProductActionsEnded(false)
	end
end

---------------------------------------------- End Gui Functions ----------------------------------------------


---------------------------------------------- Script Event start/initialization ----------------------------------------------
preloadAssets()

game:GetService("MarketplaceService").PromptProductPurchaseRequested:connect(function(player, productId, equipIfPurchased, currencyType)
	doPurchasePrompt(player, nil, equipIfPurchased, currencyType, productId)
end)

Game:GetService("MarketplaceService").PromptPurchaseRequested:connect(function(player, assetId, equipIfPurchased, currencyType)
	doPurchasePrompt(player, assetId, equipIfPurchased, currencyType, nil)
end)

Game:GetService("MarketplaceService").ServerPurchaseVerification:connect(function(serverResponseTable)
	doProcessServerPurchaseResponse(serverResponseTable)
end)

Game:GetService("GuiService").BrowserWindowClosed:connect(checkIfCanPurchase)

if not canUseNewRobuxToProductFlow() then return end

Game:GetService("MarketplaceService").NativePurchaseFinished:connect(function(player, productId, wasPurchased)
	if wasPurchased then

		-- try for 20 seconds to see if we get the funds if we purchased something
		local retriesLeft = 40
		local canPurchase, insufficientFunds, notRightBC = canPurchaseItem()
		while canPurchase and insufficientFunds and retriesLeft > 0 do
			wait(0.5)
			canPurchase, insufficientFunds, notRightBC = canPurchaseItem()
			retriesLeft = retriesLeft - 1
		end

		if canPurchase and not insufficientFunds and not notRightBC then
			doAcceptPurchase(Enum.CurrencyType.Robux)
		else
			purchaseFailed("didNotBuyRobux")
		end
	else
		purchaseFailed("didNotBuyRobux")
	end
end)
