require( GetScriptDirectory().."/utils" ) 
item_purchase_generic = dofile( GetScriptDirectory().."/item_purchase_generic" )

local itemGuide = 
{ 
	"item_recipe_travel_boots_2",
	"item_boots", -- *3 bot
	"item_recipe_travel_boots",

	"item_recipe_sphere", --*3 linken
	"item_ring_of_health",
	"item_void_stone",
	"item_ultimate_orb", --*3
	"item_recipe_lotus_orb", --*2 lotus
	"item_ring_of_health",
	"item_void_stone",
	"item_platemail", --*2 
	"item_talisman_of_evasion", -- *6 solar crest
	"item_sobi_mask", -- *6 Medallion
	"item_blight_stone",
	"item_chainmail", -- 6
	"item_recipe_force_staff", --*5 force
	"item_ring_of_health",
	"item_staff_of_wizardry", -- 5
	"item_shadow_amulet", -- *4invincible
	"item_cloak", -- 4
	"item_recipe_urn_of_shadows", --*3 urn
	"item_circlet",
	"item_ring_of_protection",
	"item_infused_raindrop", -- 3
	"item_branches", -- *2 wand
	"item_branches",
	"item_circlet",
	"item_energy_booster", -- * 1 arcane
	"item_magic_stick", -- 2
	"item_boots", -- 1

	"item_clarity",
	"item_tango",
	"item_tango",
};
local trash = {
	"item_magic_stick",
}

function ItemPurchaseThink()
	item_purchase_generic.ItemPurchaseThink();
	local I = GetBot();
	item_purchase_generic.PurchaseItem(I, itemGuide, trash);
end