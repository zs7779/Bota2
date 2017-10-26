require( GetScriptDirectory().."/utils" ) 
item_purchase_generic = dofile( GetScriptDirectory().."/item_purchase_generic" )

local itemGuide = 
{ 
	"item_recipe_travel_boots_2",
	"item_boots", -- *3 bot
	"item_recipe_travel_boots",

	"item_recipe_shivas_guard", -- *4 shivas
	"item_mystic_staff",
	"item_platemail", -- *4
	"item_recipe_refresher", -- *3 refresher
	"item_void_stone",
	"item_void_stone",
	"item_ring_of_health",
	"item_ring_of_health", -- *3
	"item_recipe_force_staff", --*6 force
	"item_ring_of_health",
	"item_staff_of_wizardry", -- 6
	"item_recipe_guardian_greaves", --*2+6 greaves
	"item_blink", -- *1
	"item_recipe_mekansm", --* 6 mek
	"item_recipe_headdress",
	"item_branches",
	"item_ring_of_regen",
    "item_recipe_buckler", --*6 buckler
	"item_branches";
	"item_chainmail", -- 6
	"item_recipe_pipe", --*5 pipe
	"item_recipe_headdress",
	"item_branches",
	"item_ring_of_regen",
	"item_ring_of_regen", -- *5 hood
	"item_ring_of_health",
	"item_cloak", -- 5
	"item_energy_booster", --*2 Manaboot
	"item_recipe_soul_ring", --*4 soulring
	"item_sobi_mask",
	"item_ring_of_regen", -- 4
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
	local I = GetBot();
	item_purchase_generic.PurchaseItem(I, itemGuide, trash);
end