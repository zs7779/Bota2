require( GetScriptDirectory().."/utils" ) 
item_purchase_generic = dofile( GetScriptDirectory().."/item_purchase_generic" )

local itemGuide = 
{ 
	"item_recipe_refresher",
	"item_void_stone",
	"item_void_stone",
	"item_ring_of_health",
	"item_ring_of_health",
	"item_recipe_travel_boots_2",
	
	"item_boots", -- *3 bot
	"item_recipe_travel_boots",
	"item_hyperstone",
	"item_hyperstone", 

	"item_recipe_greater_crit",
	"item_demon_edge",
	"item_recipe_lesser_crit",
    "item_blades_of_attack",
	"item_broadsword";  -- *2 crystal
	"item_chainmail", -- *1 assault
	"item_recipe_assault",
	"item_platemail",
	"item_hyperstone", -- *1
	"item_recipe_black_king_bar", -- *6 bkb
	"item_mithril_hammer",
	"item_ogre_axe", -- 6
	"item_blink", -- 5
	"item_quarterstaff", --*4 MoM
	"item_lifesteal", --4 morbid mask
	"item_belt_of_strength", -- *3 treads
	"item_gloves",
	"item_boots", -- 3 boot
	"item_slippers", -- *1 pms
	"item_slippers",
	"item_quelling_blade", -- 2

	"item_clarity",
	"item_enchanted_mango",
	"item_flask",
	"item_stout_shield", -- 1
	"item_tango"
};
local trash = {
	"item_quelling_blade",
	"item_stout_shield",
}

function ItemPurchaseThink()
	local I = GetBot();
	item_purchase_generic.PurchaseItem(I, itemGuide, trash);
end