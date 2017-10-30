require( GetScriptDirectory().."/utils" ) 
item_purchase_generic = dofile( GetScriptDirectory().."/item_purchase_generic" )

local itemGuide = 
{ 
	"item_recipe_travel_boots_2",
	"item_boots", -- *3 bot
	"item_recipe_travel_boots",

	"item_blade_of_alacrity", -- *2 aghs
	"item_staff_of_wizardry",
	"item_ogre_axe",
	"item_point_booster", -- *2
	"item_recipe_black_king_bar", -- *6 bkb
	"item_mithril_hammer",
	"item_ogre_axe", -- 6
	"item_recipe_cyclone", -- *5 euls
	"item_wind_lace",
	"item_void_stone",
	"item_staff_of_wizardry", -- 5
	"item_recipe_force_staff", --*4 force
	"item_ring_of_health",
	"item_staff_of_wizardry", -- 4
	"item_blink", -- 3 blink
	"item_magic_stick", -- 2
	"item_wind_lace", -- *1 Tranquil
	"item_ring_of_regen",

	"item_boots", -- 1
	"item_clarity",
	"item_tango"
};
local trash = {
	"item_magic_stick",
}

function ItemPurchaseThink()
	item_purchase_generic.ItemPurchaseThink();
	local I = GetBot();
	item_purchase_generic.PurchaseItem(I, itemGuide, trash);
end