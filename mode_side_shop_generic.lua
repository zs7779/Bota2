require(GetScriptDirectory() ..  "/utils")

function GetDesire()
	local I = GetBot();
	if not I.sideShopMode or
	   not I:CanAct() or
	   I:GetGold() < I:GetNextItemPurchaseValue() or
	   I:GetNextItemPurchaseValue() == 0 or
	   I:DistanceFromSideShop() > 2000 or
	   I:WasRecentlyDamagedByAnyHero(5.0) or
	   #(I:GetNearbyHeroes(800,true,BOT_MODE_NONE)) > 0 then
		return 0;
	end
	if I:DistanceFromSideShop() == 0 then
		I.sideShopMode = nil;
		return 0;
	elseif I:DistanceFromSideShop() < 600 then
		return 0.6;
	elseif I:DistanceFromSideShop() < 2000 then
		return 0.3;
	end

end

function Think()
	local I = GetBot();
	local shop1 = GetShopLocation(GetTeam(), SHOP_SIDE);
	local shop2 = GetShopLocation(GetTeam(), SHOP_SIDE2)
	if GetUnitToLocationDistance(I, shop1) < GetUnitToLocationDistance(I, shop1) then
		I:ActionQueue_MoveToLocation(shop1);
	else
		I:ActionQueue_MoveToLocation(shop2);
	end
end