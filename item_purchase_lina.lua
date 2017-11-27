require( GetScriptDirectory().."/utils" ) 
item_purchase_generic = dofile( GetScriptDirectory().."/item_purchase_generic" )

local itemGuide = {};

function ItemPurchaseThink()
	local itemLists = {
		[1] = {
			"item_tango",
			"item_null_talisman",
		},
		[2] = {
			"item_null_talisman", -- 1 null
			"item_bottle",
			"item_phase_boots", -- 3 boot	
		},
		[3] = {
			"item_phase_boots", -- 3 boot
			"item_bloodstone", -- 4 bloodstone
			"item_invis_sword", -- 5 shadowblade
			"item_black_king_bar", -- 6 bkb
			"item_shivas_guard", -- *1 shivas
		},
		[4] = {
			"item_travel_boots", -- *3 bot2
			"item_bloodstone", -- 4 bloodstone
			"item_silver_edge", -- *5 silveredge
			"item_black_king_bar", -- 6 bkb
			"item_shivas_guard", -- *1 shivas
			"item_greater_crit", -- *2 crit
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