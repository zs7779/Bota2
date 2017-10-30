require( GetScriptDirectory().."/utils" ) 
item_purchase_generic = dofile( GetScriptDirectory().."/item_purchase_generic" )

local itemGuide = 
{ 
	"item_recipe_travel_boots_2",
	"item_boots", -- *3 bot
	"item_recipe_travel_boots",

	"item_recipe_shivas_guard", -- *3 shivas
	"item_mystic_staff",
	"item_platemail", -- *3
	"item_recipe_refresher", -- *1 refresher
	"item_void_stone",
	"item_void_stone",
	"item_ring_of_health",
	"item_ring_of_health", -- *1
	"item_recipe_force_staff", --*5 force
	"item_ring_of_health",
	"item_staff_of_wizardry", -- 5
	"item_recipe_guardian_greaves", --*2+5 greaves
	"item_blink", -- 6
	"item_recipe_mekansm", --* 5 mek
	"item_recipe_headdress",
	"item_branches",
	"item_ring_of_regen",
    "item_recipe_buckler", --*5 buckler
	"item_branches";
	"item_chainmail", -- 5
	"item_recipe_pipe", --*4 pipe
	"item_recipe_headdress",
	"item_branches",
	"item_ring_of_regen",
	"item_ring_of_regen", -- *4 hood
	"item_ring_of_health",
	"item_cloak", -- 4
	"item_energy_booster", --*2 Manaboot
	"item_magic_stick", -- 3
	"item_boots", -- 2 boot
	"item_recipe_iron_talon", -- *1 talon
	"item_quelling_blade",
	
	"item_enchanted_mango",
	"item_flask",
	"item_ring_of_protection", -- 1
	"item_tango"
};
local trash = {
	"item_soul_ring",
	"item_magic_stick",
	"item_iron_talon"
}

function ItemPurchaseThink()
	item_purchase_generic.ItemPurchaseThink();
	local I = GetBot();
	item_purchase_generic.PurchaseItem(I, itemGuide, trash);
end