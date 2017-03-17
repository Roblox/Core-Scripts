local BusinessLogic = {}





local showVisibleAgeV2Success, showVisibleAgeV2Value = pcall(function() return settings():GetFFlag("CoreScriptShowVisibleAgeV2") end)
local showVisibleAgeV2Enabled = showVisibleAgeV2Success and showVisibleAgeV2Value

function BusinessLogic.GetVisibleAgeForPlayer(player)
	local accountTypeText = showVisibleAgeV2Enabled and "Account: <13" or "Account: Under 13 yrs"
	if player and not player:GetUnder13() then
		accountTypeText = showVisibleAgeV2Enabled and "Account: 13+" or "Account: Over 13 yrs"
	end
	return accountTypeText
end





return BusinessLogic