require( GetScriptDirectory().."/utils" ) 
item_purchase_generic = dofile( GetScriptDirectory().."/item_purchase_generic" )

local itemGuide = {};

function ItemPurchaseThink()
	local itemLists = {
		[1] = {
			"item_tango",
			"item_boots",
			"item_clarity",
		},
		[2] = {
			"item_tranquil_boots", --2 tranquil
			"item_magic_wand",
			"item_blink", -- 3 blink
		},
		[3] = {
			"item_tranquil_boots", --2 tranquil
			"item_blink", -- 3 blink
			"item_force_staff", --4 force
			"item_cyclone", -- 5 euls
			"item_black_king_bar", -- 6 bkb
		},
		[4] = {
			"item_travel_boots", -- *3 bot2
			"item_blink", -- 3 blink
			"item_force_staff", --4 force
			"item_cyclone", -- 5 euls
			"item_black_king_bar", -- 6 bkb
			"item_ultimate_scepter", -- *1 aghs
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