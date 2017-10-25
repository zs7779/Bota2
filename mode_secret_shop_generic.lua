require(GetScriptDirectory() ..  "/utils")

function GetDesire()
	local I = GetBot();
	if not I.secretShopMode or
	   not I:CanAct() or
	   I:GetGold() < I:GetNextItemPurchaseValue() or
	   I:GetNextItemPurchaseValue() == 0 or
	   I:DistanceFromSideShop() > 3000 or
	   I:WasRecentlyDamagedByAnyHero(5.0) or
	   #(I:GetNearbyHeroes(1000,true,BOT_MODE_NONE)) > 0 then
		return 0;
	end
	if I:DistanceFromSideShop() == 0 then
		I.secretShopMode = nil;
		return 0;
	elseif I:DistanceFromSideShop() < 600 then
		return 0.6;
	elseif I:DistanceFromSideShop() < 3000 then
		return 0.3;
	end
end