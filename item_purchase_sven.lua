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
			"item_stout_shield",
			"item_clarity",
			"item_enchanted_mango",
			"item_flask",
		},
		[2] = {
			"item_stout_shield", -- 1
			"item_quelling_blade", -- 2
			"item_power_treads", -- 3 boot
			"item_mask_of_madness", --4 MoM
		},
		[3] = {
			"item_power_treads", -- 3 boot	
			"item_mask_of_madness", --4 MoM
			"item_blink", -- 5
			"item_black_king_bar", -- 6 bkb
			"item_greater_crit", -- *1 crit
		},
		[3] = {
			"item_travel_boots", -- *3 bot2
			"item_mask_of_madness", --4 MoM
			"item_blink", -- 5
			"item_black_king_bar", -- 6 bkb
			"item_greater_crit", -- *1 crit
			"item_assault", -- *2 assault
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