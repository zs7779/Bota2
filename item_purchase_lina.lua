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
	
	"item_javelin", -- *2 mkb
	"item_javelin",
	"item_demon_edge",
	"item_boots", -- *3 bot
	"item_recipe_travel_boots",
	"item_recipe_silver_edge", -- *5 silveredge
	"item_ultimate_orb",
	
	"item_recipe_shivas_guard", -- *1 shivas
	"item_mystic_staff",
	"item_platemail", -- *1 armor
	"item_recipe_black_king_bar", -- 6 bkb
	"item_mithril_hammer",
	"item_ogre_axe",
	"item_claymore", -- 5 shadowblade
	"item_shadow_amulet",
	"item_recipe_bloodstone", -- *4 bloodstone
	"item_vitality_booster",
	"item_energy_booster",
	"item_point_booster",
	"item_blades_of_attack", -- *3 phaseboot
	"item_blades_of_attack",
	"item_enchanted_mango", -- 4 soulring
	"item_ring_of_regen",
	"item_sobi_mask",
	"item_boots", -- 3 boot
	"item_clarity",
	"item_recipe_null_talisman", -- 2 null
	"item_mantle",
	"item_circlet",
	"item_flask",

	"item_recipe_null_talisman", -- 1 null
	"item_mantle",
	"item_circlet",
	"item_tango"
};
local trash = {
	"item_null_talisman",
	"item_null_talisman",
	"item_tango"
}

function ItemPurchaseThink()
	item_purchase_generic.ItemPurchaseThink();
	local I = GetBot();
	item_purchase_generic.PurchaseItem(I, itemGuide, trash);
end