require( GetScriptDirectory().."/utils" ) 
item_purchase_generic = dofile( GetScriptDirectory().."/item_purchase_generic" )

local itemGuide = {};

function GetItemGuide(itemLists)
	if itemLists == nil then return; end
	for listName, list in pairs(itemLists) do
		itemGuide[listName] = {};
		local totalCost = 0;
		for _, item in ipairs(list) do
			totalCost = totalCost + GetItemCost(item);
			table.insert(itemGuide[listName], {['cost']=totalCost, ['item']=item});
		end
	end
end

function ItemPurchaseThink()
	local itemLists = {
		[1] = {
			"item_tango",
			"item_clarity",
		},
		[2] = {
			"item_arcane_boots", -- 1 arcane
			"item_magic_wand", -- 2 wand
		},
		[3] = {
			"item_arcane_boots", -- 1 arcane
			"item_glimmer_cape", -- 4 glim
			"item_urn_of_shadows", --3 urn
			"item_force_staff", --4 force
			"item_lotus_orb", --*2 lotus
		},
		[4] = {
			"item_travel_boots", -- *3 bot2
			"item_glimmer_cape", -- 4 glim
			"item_force_staff", --4 force
			"item_lotus_orb", --*2 lotus
			"item_urn_of_shadows", --3 urn
			"item_solar_crest", -- 6 solar crest
		},
	};
	if GetGameState() < GAME_STATE_PRE_GAME then return; end
	if #itemGuide == 0 then
		GetItemGuide(itemLists);
	end
	item_purchase_generic.ItemPurchaseThink();
	local I = GetBot();
	if DotaTime() < 0 then
		item_purchase_generic.PurchaseItem(I, itemGuide[1]);
		return;
	end
	for list = 2,3 do
		if I:GetNetWorth() < itemGuide[list][#itemGuide[list]]['cost'] then
			item_purchase_generic.PurchaseItem(I, itemGuide[list]);
			return;
		end
	end
	item_purchase_generic.PurchaseItem(I, itemGuide[4]);
end