require( GetScriptDirectory().."/utils" ) 
item_purchase_generic = dofile( GetScriptDirectory().."/item_purchase_generic" )

local itemGuide = {};

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
		[4] = {
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
		item_purchase_generic.GetItemGuide(itemLists, itemGuide);
	end
	item_purchase_generic.ItemPurchaseThink();
	
	local I = GetBot();
	if DotaTime() < 0 then
		item_purchase_generic.PurchaseItem(I, itemGuide[1]);
		return;
	end
	for list = 2,3 do
		if I:GetNetWorth() < itemGuide[list][#itemGuide[list]]['worth'] then
			item_purchase_generic.PurchaseItem(I, itemGuide[list]);
			return;
		end
	end
	item_purchase_generic.PurchaseItem(I, itemGuide[4]);
end