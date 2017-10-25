require(GetScriptDirectory() ..  "/utils")

function PurchaseItem(I, shoppingGuide, trash)
	if I == nil or not I:IsTrueHero() then return; end
	if #shoppingGuide == 0 then
		I:SetNextItemPurchaseValue(0);
		return;
	end

	local courier;
	if GetNumCouriers() > 0 then
		courier = GetCourier(0);
	end

	local item = shoppingGuide[#shoppingGuide];
	local itemCost = GetItemCost(item);
	if I:GetGold() > itemCost then
		if not I:HaveSlot() and
			I:DistanceFromSecretShop() == 0 or
			I:DistanceFromSideShop() == 0 or
			I:DistanceFromFountain() == 0 then
			SellItem(I, trash);
		end

		local purchaseResult = 0;
		-- if item is in secret shop or in nearby side shop
		if IsItemPurchasedFromSecretShop(item) then
			if I:DistanceFromSecretShop() == 0 then -- at shop
				if I:HaveSlot() then
					purchaseResult = I:ActionImmediate_PurchaseItem(item);
				else
					SellItem(I, trash);
				end
			elseif courier ~= nil and courier:DistanceFromSecretShop() == 0 and courier:HaveSlot() then
				purchaseResult = courier:ActionImmediate_PurchaseItem(item);
			else -- walk if have slot else dunkey
				I.secretShopMode = true;
			end
		elseif IsItemPurchasedFromSideShop(item) and I:DistanceFromSideShop() < 2000 then
			if I:DistanceFromSideShop() == 0 then
				if I:HaveSlot() then
					purchaseResult = I:ActionImmediate_PurchaseItem(item);
				else
					SellItem(I, trash);
				end
			elseif courier ~= nil and courier:DistanceFromSecretShop() == 0 and courier:HaveSlot() then
				purchaseResult = courier:ActionImmediate_PurchaseItem(item);
			else -- walk
				I.sideShopMode = true;
			end
		else
			if I:DistanceFromFountain() == 0 then
				if I:HaveSlot() then
					purchaseResult = I:ActionImmediate_PurchaseItem(item);
				else
					SellItem(I, trash);
				end
			elseif courier ~= nil and courier:DistanceFromSecretShop() == 0 and courier:HaveSlot() then
				purchaseResult = courier:ActionImmediate_PurchaseItem(item);
			else
				purchaseResult = I:ActionImmediate_PurchaseItem(item);
			end
		end

		if purchaseResult == PURCHASE_ITEM_SUCCESS then
			table.remove(shoppingGuide);
			purchaseResult = 0;
			I.secretShopMode = nil;
			I.sideShopMode = nil;
			return;
		end
	end
	I:SetNextItemPurchaseValue(itemCost);
end

-- function IgnoreItemOnReload(I, shoppingGuide)
-- 	for _, item in ipairs(shoppingGuide) do
-- 		if FindItemSlot(item) ~= -1 then
-- 			table.remove(shoppingGuide);
-- 		end
-- 	end
-- end

function SellItem(I, trash)
	local consumableGoods = {
		"item_tango",
		"item_faerie_fire",
		"item_flask",
		"item_clarity"
	};
	for slot = 0,16 do
		local item = I:GetItemInSlot(slot);
		for _, good in ipairs(consumableGoods) do
			if item:GetName() == good then
				ActionImmediate_SellItem(item);
				return;
			end
		end
		if item:GetName() == trash[#trash] then
			ActionImmediate_SellItem(item);
			table.remove(trash);
			return; -- sell just one, see if space available
		end
	end
end

BotsInit = require( "game/botsinit" );
local item_purchase_generic = BotsInit.CreateGeneric();
item_purchase_generic.PurchaseItem = PurchaseItem;
return item_purchase_generic;