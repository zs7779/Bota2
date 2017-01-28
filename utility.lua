_G._savedEnv = getfenv()
module( "utility", package.seeall )

----------------------------------------------------------------------------------------------------

----(s/a/i, core,mid,off,supt,frnt,back,ctrl,dps, init,cinit,teamf,push,def, greed,lane,jngle,vision, burst,stun,root,silnc,mnbrn,purge, 
----evas,immun,cimun, invis,truest, heal,cheal, +phy,-phy, +mgc,-mgc, ilusn,splsh,bash)
heroRating = {
	["npc_dota_hero_antimage"] 				= {2, 2,0,0,0, 1,0,0,0, 0,0,0,0,0, 2,0,0,0, 1,0,0,0,2,0, 1,0,0, 0,0, 0,0, 0,0, 0,2, 0,0,1},
	["npc_dota_hero_axe"] 					= {1, 0,0,2,1, 2,0,2,0, 2,2,2,0,1, 1,2,2,0, 1,2,0,0,0,0, 0,0,2, 0,0, 0,1, 0,1, 0,0, 0,0,0},
	["npc_dota_hero_bane"] 					= {3, 0,0,0,2, 0,1,2,0, 1,1,0,0,0, 0,2,0,0, 0,2,0,0,1,0, 0,0,1, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_bloodseeker"] 			= {2, 2,0,0,0, 1,0,1,1, 0,1,1,0,1, 1,0,2,1, 0,0,0,1,0,0, 0,0,1, 0,1, 1,0, 2,0, 2,0, 0,0,0},
	["npc_dota_hero_crystal_maiden"] 		= {3, 0,0,0,2, 0,2,1,1, 1,0,1,0,1, 0,2,1,0, 1,1,1,0,0,0, 0,0,0, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_drow_ranger"] 			= {2, 2,0,0,0, 0,2,0,1, 0,1,0,2,0, 2,0,0,0, 0,0,0,2,0,0, 0,0,0, 0,0, 0,0, 1,0, 0,0, 0,1,0},
	["npc_dota_hero_earthshaker"] 			= {1, 0,0,1,2, 0,1,2,0, 2,2,2,0,1, 0,2,0,0, 1,2,0,0,0,0, 0,0,0, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_juggernaut"] 			= {2, 2,1,0,0, 1,0,0,1, 0,0,0,1,0, 1,1,0,0, 1,0,0,0,0,0, 1,2,0, 0,0, 2,0, 0,0, 0,0, 0,0,1},
	["npc_dota_hero_mirana"] 				= {2, 1,2,1,1, 0,1,1,2, 0,0,1,0,1, 1,2,1,0, 2,0,0,0,0,0, 1,0,0, 1,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_nevermore"] 			= {2, 1,2,0,0, 1,2,0,2, 0,0,1,2,1, 2,0,0,0, 2,0,0,0,0,0, 0,0,0, 0,0, 0,0, 2,0, 0,0, 0,0,0},
	["npc_dota_hero_morphling"] 			= {2, 2,0,0,1, 1,0,1,0, 1,0,0,0,0, 2,0,0,0, 2,1,0,0,0,0, 2,1,0, 0,0, 2,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_phantom_lancer"] 		= {2, 2,1,0,0, 1,0,0,0, 0,0,0,0,0, 2,1,0,0, 0,0,0,0,1,0, 1,0,0, 0,0, 0,0, 0,0, 0,0, 2,0,0},
	["npc_dota_hero_puck"] 					= {3, 0,2,1,0, 1,0,1,1, 1,1,2,0,1, 1,2,0,0, 1,1,0,1,0,0, 2,0,1, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_pudge"] 				= {1, 0,0,0,2, 2,0,1,0, 1,1,0,0,1, 0,1,1,0, 1,1,0,0,0,0, 0,0,1, 0,0, 0,0, 0,0, 0,1, 0,0,0},
	["npc_dota_hero_razor"] 				= {2, 2,2,0,0, 1,0,0,1, 0,0,0,1,1, 2,2,0,0, 0,0,0,0,0,1, 1,0,1, 0,0, 0,0, 0,0, 0,1, 0,0,0},
	["npc_dota_hero_sand_king"] 			= {1, 0,1,2,1, 1,0,1,0, 2,1,2,0,0, 1,2,0,0, 2,1,0,0,0,0, 1,0,0, 1,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_storm_spirit"] 			= {3, 1,2,0,0, 1,0,1,1, 2,0,0,1,0, 2,1,0,0, 1,1,0,0,0,0, 1,0,0, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_sven"] 					= {1, 2,0,0,0, 2,0,1,1, 1,1,0,1,0, 2,1,0,0, 2,1,0,0,0,0, 0,0,0, 0,0, 0,0, 0,2, 0,0, 0,2,0},
	["npc_dota_hero_tiny"] 					= {1, 2,1,0,0, 1,0,1,2, 1,1,1,1,1, 1,1,0,0, 2,1,0,0,0,0, 0,0,1, 0,0, 0,0, 0,0, 0,0, 0,1,0},
	["npc_dota_hero_vengefulspirit"] 		= {2, 1,0,0,2, 1,1,1,1, 1,1,0,2,0, 0,1,0,0, 0,1,0,0,0,0, 0,0,1, 0,0, 0,0, 2,0, 0,0, 0,0,0},
	["npc_dota_hero_windrunner"] 			= {3, 1,2,1,0, 1,0,1,1, 1,0,0,1,1, 1,2,0,0, 1,1,0,0,0,0, 1,0,0, 0,0, 0,0, 0,1, 0,0, 0,0,0},
	["npc_dota_hero_zuus"] 					= {3, 0,2,0,1, 0,2,0,2, 0,0,0,0,1, 1,0,0,1, 2,0,0,0,0,0, 0,0,0, 0,2, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_kunkka"] 				= {1, 1,1,1,2, 1,1,1,1, 1,2,2,0,1, 0,1,0,0, 1,1,0,0,0,0, 0,0,0, 0,0, 0,0, 0,1, 0,1, 0,1,0},
	["npc_dota_hero_lina"] 					= {3, 1,2,0,1, 0,2,1,2, 1,0,0,1,1, 1,1,0,0, 2,1,0,0,0,0, 0,0,1, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_lich"] 					= {3, 0,0,0,2, 0,2,0,0, 0,0,1,0,1, 0,2,0,0, 1,0,0,0,0,0, 0,0,0, 0,0, 0,0, 0,2, 0,0, 0,0,0},
	["npc_dota_hero_lion"] 					= {3, 0,0,0,2, 0,1,2,0, 2,1,1,0,0, 0,1,0,0, 1,2,0,0,1,0, 0,0,0, 0,0, 0,0, 0,0, 0,0, 0,1,0},
	["npc_dota_hero_shadow_shaman"] 		= {3, 0,0,0,2, 0,1,2,0, 2,0,0,2,0, 0,1,0,0, 0,2,0,0,0,0, 0,0,0, 0,0, 0,0, 0,0, 0,0, 0,1,0},
	["npc_dota_hero_slardar"] 				= {1, 1,0,2,1, 1,0,1,0, 2,2,2,0,0, 1,1,0,0, 0,1,0,0,0,0, 1,0,0, 0,2, 0,0, 2,0, 0,0, 0,0,1},
	["npc_dota_hero_tidehunter"] 			= {1, 0,0,2,1, 2,0,1,0, 1,1,2,0,1, 1,2,1,0, 1,1,0,0,0,1, 2,0,0, 0,0, 0,0, 1,0, 0,0, 0,0,0},
	["npc_dota_hero_witch_doctor"] 			= {3, 0,0,0,2, 0,2,1,1, 0,1,1,0,0, 0,2,0,0, 1,1,0,0,0,0, 0,0,0, 0,0, 1,0, 1,0, 1,0, 0,0,0},
	["npc_dota_hero_riki"] 					= {2, 1,0,1,1, 0,1,0,0, 0,1,1,0,0, 1,2,0,1, 0,0,0,1,0,0, 1,0,0, 2,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_enigma"] 				= {3, 0,0,1,2, 0,1,1,0, 1,1,2,2,0, 1,1,2,0, 0,1,0,0,0,0, 0,0,2, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_tinker"] 				= {3, 2,2,0,0, 0,1,0,2, 0,0,0,1,2, 2,2,0,0, 2,0,0,0,0,0, 0,0,0, 0,0, 0,0, 0,1, 0,0, 0,1,0},
	["npc_dota_hero_sniper"] 				= {2, 2,2,0,0, 0,2,0,1, 0,0,1,0,1, 2,2,0,1, 0,0,0,0,0,0, 0,0,0, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_necrolyte"] 			= {3, 1,2,0,0, 1,0,0,0, 0,0,0,0,0, 2,1,0,0, 1,1,0,0,0,0, 0,0,2, 0,0, 2,0, 1,1, 1,0, 0,0,0},
	["npc_dota_hero_warlock"] 				= {3, 0,0,0,2, 0,2,0,0, 0,1,2,0,0, 0,2,0,0, 0,1,0,0,0,0, 0,0,1, 0,0, 1,0, 1,0, 2,0, 0,1,0},
	["npc_dota_hero_beastmaster"] 			= {1, 0,1,2,1, 1,1,1,0, 2,0,0,2,1, 1,1,2,2, 0,1,0,0,0,0, 0,0,2, 0,1, 0,0, 2,0, 0,0, 0,0,0},
	["npc_dota_hero_queenofpain"] 			= {3, 1,2,0,0, 2,0,0,2, 0,0,1,0,0, 2,2,0,0, 2,0,0,0,0,0, 0,0,1, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_venomancer"] 			= {2, 2,1,1,1, 1,2,0,2, 0,0,2,1,1, 1,2,2,0, 0,0,0,0,0,0, 0,0,0, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_faceless_void"] 		= {2, 2,0,2,0, 1,0,2,0, 2,0,2,0,0, 2,1,0,0, 0,0,0,0,0,0, 1,0,2, 0,1, 1,0, 0,0, 0,0, 0,0,2},
	["npc_dota_hero_skeleton_king"] 		= {1, 2,0,0,0, 2,0,1,0, 1,0,1,0,0, 2,1,1,0, 0,1,0,0,0,0, 0,0,0, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_death_prophet"] 		= {3, 1,2,0,0, 1,0,0,2, 0,1,2,2,2, 1,2,0,0, 1,0,0,2,0,0, 0,0,1, 0,0, 2,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_phantom_assassin"] 		= {2, 2,1,0,0, 1,0,0,1, 0,0,0,0,0, 2,1,0,0, 1,0,0,0,0,0, 1,0,0, 0,0, 0,0, 0,1, 0,0, 0,0,1},
	["npc_dota_hero_pugna"] 				= {3, 1,2,0,1, 0,1,0,1, 0,1,2,2,0, 1,1,0,0, 1,0,0,0,0,0, 0,0,0, 0,0, 2,0, 0,2, 2,0, 0,1,0},
	["npc_dota_hero_templar_assassin"] 		= {2, 0,2,0,0, 1,0,0,2, 0,0,0,1,0, 1,1,0,0, 1,0,0,0,0,0, 0,0,0, 1,0, 0,0, 2,0, 0,0, 0,1,0},
	["npc_dota_hero_viper"] 				= {2, 1,2,0,0, 2,0,0,1, 0,0,1,1,0, 1,2,0,0, 0,0,0,0,0,0, 0,0,1, 0,0, 0,0, 0,0, 0,1, 0,0,0},
	["npc_dota_hero_luna"] 					= {2, 2,0,0,0, 1,0,0,1, 0,0,1,1,0, 2,1,0,0, 1,0,0,0,0,0, 0,0,0, 0,0, 0,0, 1,0, 0,0, 0,2,0},
	["npc_dota_hero_dragon_knight"] 		= {1, 1,2,0,0, 2,0,1,1, 2,0,1,2,1, 1,0,0,0, 1,1,0,0,0,0, 0,0,0, 0,0, 0,0, 0,0, 0,0, 0,2,0},
	["npc_dota_hero_dazzle"] 				= {3, 0,0,0,2, 0,2,0,0, 0,1,2,1,0, 0,1,0,0, 0,0,0,0,0,0, 0,0,0, 0,0, 2,0, 2,0, 0,0, 0,0,0},
	["npc_dota_hero_rattletrap"] 			= {1, 0,0,2,1, 2,0,2,0, 2,0,1,0,0, 1,2,0,1, 1,2,0,0,0,0, 1,0,1, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_leshrac"] 				= {3, 1,2,0,1, 0,2,1,2, 1,0,1,2,1, 1,1,0,0, 2,1,0,0,0,0, 0,0,0, 0,0, 0,0, 0,0, 0,0, 0,1,0},
	["npc_dota_hero_furion"] 				= {2, 1,0,2,0, 0,2,0,0, 0,0,0,2,1, 2,1,2,0, 0,0,0,0,0,0, 0,0,1, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_life_stealer"] 			= {1, 2,0,0,0, 2,0,0,2, 0,0,0,0,0, 1,1,1,0, 2,0,0,0,0,0, 0,2,0, 0,0, 1,0, 0,0, 0,0, 0,0,1},
	["npc_dota_hero_dark_seer"] 			= {3, 0,0,2,1, 1,0,1,1, 2,1,2,1,0, 1,2,2,0, 0,1,0,0,0,0, 1,0,1, 0,0, 0,0, 0,0, 0,0, 1,0,0},
	["npc_dota_hero_clinkz"] 				= {2, 2,0,1,0, 0,1,0,2, 0,0,0,1,0, 1,1,0,1, 1,0,0,0,0,0, 0,0,0, 2,0, 1,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_omniknight"] 			= {1, 0,0,1,2, 1,1,0,0, 0,2,1,0,0, 0,1,0,0, 1,0,0,0,0,1, 1,2,0, 0,0, 2,0, 0,2, 0,2, 0,0,0},
	["npc_dota_hero_enchantress"] 			= {0, 0,0,1,2, 0,2,0,1, 0,0,0,2,0, 1,2,2,0, 0,0,0,0,0,0, 0,0,1, 0,0, 2,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_huskar"] 				= {1, 2,2,0,0, 2,0,0,2, 0,0,0,2,0, 1,2,0,0, 1,0,0,0,0,0, 0,0,1, 0,0, 2,0, 0,0, 0,2, 0,0,0},
	["npc_dota_hero_night_stalker"] 		= {1, 0,1,1,2, 1,1,0,0, 0,0,0,0,0, 1,1,0,2, 1,0,0,1,0,0, 0,0,0, 0,1, 0,0, 0,1, 0,0, 0,0,0},
	["npc_dota_hero_broodmother"] 			= {0, 0,1,2,0, 0,1,0,1, 0,0,0,2,0, 1,2,0,0, 1,0,0,0,0,0, 1,0,0, 2,0, 1,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_bounty_hunter"] 		= {2, 0,0,1,2, 0,2,0,1, 0,0,1,0,1, 0,2,0,1, 1,0,0,0,0,0, 0,0,0, 2,2, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_weaver"] 				= {2, 2,1,1,2, 1,0,0,1, 0,0,1,1,0, 1,1,0,0, 1,0,0,0,0,0, 1,0,0, 2,0, 0,0, 2,0, 0,0, 0,0,0},
	["npc_dota_hero_jakiro"] 				= {3, 0,0,0,2, 1,1,2,1, 1,2,2,2,1, 0,1,0,0, 1,2,0,0,0,0, 0,0,0, 0,0, 0,0, 0,0, 0,0, 0,1,0},
	["npc_dota_hero_batrider"] 				= {3, 0,1,2,1, 1,1,1,1, 2,0,1,0,1, 1,2,1,1, 1,1,0,0,0,0, 1,0,2, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_chen"] 					= {3, 0,0,1,2, 1,1,1,1, 0,1,2,2,1, 0,2,2,0, 1,1,1,0,1,1, 0,0,0, 0,0, 2,0, 1,0, 1,0, 0,0,0},
	["npc_dota_hero_spectre"] 				= {2, 2,0,0,0, 2,0,0,0, 0,0,1,1,0, 2,0,0,1, 0,0,0,0,0,0, 1,0,0, 0,1, 0,0, 0,0, 0,0, 1,0,0},
	["npc_dota_hero_doom_bringer"] 			= {1, 1,0,2,1, 2,0,1,1, 1,0,0,0,0, 1,1,2,0, 0,0,0,2,0,1, 0,0,2, 0,0, 2,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_ancient_apparition"] 	= {3, 0,0,0,2, 0,2,0,1, 1,1,2,0,1, 0,1,0,0, 1,1,0,0,0,0, 0,0,1, 0,0, 0,0, 1,0, 2,0, 0,0,0},
	["npc_dota_hero_ursa"] 					= {2, 2,1,0,0, 2,0,0,2, 1,0,0,0,0, 1,1,1,0, 2,0,0,0,0,0, 1,1,0, 0,0, 0,0, 2,0, 0,0, 0,0,1},
	["npc_dota_hero_spirit_breaker"] 		= {1, 0,0,1,2, 2,0,1,0, 2,1,1,0,0, 0,1,0,1, 0,2,0,0,0,0, 1,0,1, 0,0, 0,0, 0,0, 0,0, 0,0,2},
	["npc_dota_hero_gyrocopter"] 			= {1, 2,0,0,1, 0,1,0,1, 0,0,2,0,1, 2,1,0,0, 2,0,0,0,0,0, 0,0,0, 0,0, 0,0, 0,0, 0,0, 0,2,0},
	["npc_dota_hero_alchemist"] 			= {1, 2,2,0,1, 2,0,0,1, 1,1,1,0,1, 2,1,0,0, 0,1,0,0,0,0, 0,0,0, 0,0, 2,0, 1,0, 0,0, 1,0,0},
	["npc_dota_hero_invoker"] 				= {3, 1,2,0,0, 0,2,2,1, 1,1,1,1,0, 2,1,0,0, 1,1,0,0,1,1, 0,0,0, 1,0, 0,0, 1,0, 0,0, 0,1,0},
	["npc_dota_hero_silencer"] 				= {3, 1,0,0,2, 0,2,0,0, 2,2,2,0,0, 0,2,0,0, 0,0,0,2,0,0, 0,0,1, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_obsidian_destroyer"] 	= {3, 2,2,0,0, 0,1,0,2, 0,2,1,0,0, 2,2,0,0, 1,0,0,0,1,0, 0,0,0, 0,0, 0,0, 0,0, 1,0, 0,0,0},
	["npc_dota_hero_lycan"] 				= {1, 2,2,0,0, 1,0,0,1, 0,0,0,2,0, 1,0,1,1, 0,0,0,0,1,0, 1,0,0, 0,1, 1,0, 1,0, 0,0, 0,0,0},
	["npc_dota_hero_brewmaster"] 			= {1, 1,2,1,0, 2,0,2,0, 1,1,2,0,0, 1,1,0,0, 0,1,0,0,0,1, 0,0,0, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_shadow_demon"] 			= {3, 0,0,0,2, 0,2,0,0, 0,2,0,0,1, 0,1,0,0, 1,0,0,0,0,1, 0,0,2, 0,0, 0,0, 1,0, 1,0, 0,0,0},
	["npc_dota_hero_lone_druid"] 			= {2, 2,2,2,0, 1,1,1,0, 0,1,0,2,0, 2,2,2,0, 0,0,1,0,0,0, 1,0,0, 0,0, 0,0, 0,0, 0,0, 0,0,1},
	["npc_dota_hero_chaos_knight"] 			= {1, 2,0,0,1, 1,0,2,1, 1,0,0,1,0, 2,1,0,0, 1,2,0,0,0,0, 0,0,0, 0,0, 0,0, 1,0, 0,0, 2,0,0},
	["npc_dota_hero_meepo"] 				= {2, 2,2,0,0, 1,1,1,2, 1,0,1,2,0, 2,1,1,0, 2,0,2,0,0,0, 1,0,1, 0,1, 0,0, 0,0, 0,0, 1,1,0},
	["npc_dota_hero_treant"] 				= {3, 0,0,1,2, 0,1,1,0, 1,2,2,0,2, 0,2,0,1, 1,1,2,0,0,0, 0,0,2, 2,0, 1,0, 0,2, 0,0, 0,0,0},
	["npc_dota_hero_ogre_magi"] 			= {3, 0,0,0,2, 2,0,1,1, 1,0,2,1,1, 0,2,0,0, 1,1,0,0,0,0, 0,0,0, 0,0, 0,0, 1,0, 0,0, 0,0,0},
	["npc_dota_hero_undying"] 				= {1, 0,0,0,2, 2,0,0,1, 0,1,2,1,1, 0,2,0,0, 1,0,0,0,0,0, 0,0,0, 0,0, 1,1, 2,0, 2,0, 0,0,0},
	["npc_dota_hero_rubick"] 				= {3, 0,1,0,2, 0,2,1,0, 2,1,2,0,1, 0,0,0,0, 1,1,0,0,0,0, 0,0,0, 0,0, 0,0, 0,0, 0,2, 0,0,0},
	["npc_dota_hero_disruptor"] 			= {3, 0,0,0,2, 0,2,2,0, 2,1,2,0,0, 0,1,0,0, 0,1,0,2,0,0, 0,0,0, 0,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_nyx_assassin"]			= {2, 0,1,2,1, 0,0,2,1, 2,0,2,0,2, 1,1,0,1, 2,2,0,0,2,0, 1,0,0, 2,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_naga_siren"] 			= {2, 2,2,0,1, 1,0,1,0, 1,2,1,1,0, 2,1,0,0, 1,0,2,0,1,0, 1,0,2, 0,0, 0,0, 1,0, 0,0, 2,0,0},
	["npc_dota_hero_keeper_of_the_light"] 	= {3, 0,0,0,2, 0,2,1,0, 1,1,2,1,2, 0,1,0,2, 0,1,0,0,1,0, 0,0,0, 0,0, 1,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_wisp"] 					= {3, 0,0,0,2, 0,2,0,0, 0,2,0,0,0, 0,1,0,0, 1,0,0,0,0,0, 1,0,0, 0,0, 2,0, 1,0, 0,0, 0,0,0},
	["npc_dota_hero_visage"] 				= {2, 0,0,0,2, 1,1,1,1, 0,1,1,1,0, 0,2,0,0, 2,1,0,0,0,0, 0,0,0, 0,0, 0,0, 1,1, 0,1, 0,0,0},
	["npc_dota_hero_slark"] 				= {2, 2,0,0,0, 1,0,0,1, 1,0,0,0,0, 2,0,0,2, 1,0,0,0,0,1, 2,2,0, 1,0, 2,0, 0,0, 0,0, 0,0,1},
	["npc_dota_hero_medusa"] 				= {2, 2,2,0,0, 2,0,1,0, 0,1,1,0,1, 2,1,0,0, 0,0,0,0,1,0, 0,0,1, 0,0, 0,0, 0,0, 0,0, 0,2,0},
	["npc_dota_hero_troll_warlord"] 		= {2, 2,1,0,0, 1,0,0,1, 0,0,1,2,0, 2,1,0,0, 1,0,0,0,0,0, 0,0,0, 0,0, 0,0, 2,0, 0,0, 0,0,2},
	["npc_dota_hero_centaur"] 				= {1, 1,0,2,1, 2,0,1,1, 1,2,2,0,0, 1,1,0,0, 1,1,0,0,0,0, 1,0,0, 0,0, 0,0, 0,2, 0,2, 0,0,0},
	["npc_dota_hero_magnataur"] 			= {1, 1,0,2,1, 1,0,1,1, 2,2,2,0,1, 1,1,0,0, 1,1,0,0,0,0, 1,0,2, 0,0, 0,0, 1,0, 0,0, 0,2,0},
	["npc_dota_hero_shredder"] 				= {1, 1,2,1,0, 2,0,0,2, 0,0,1,0,1, 1,2,0,0, 2,0,0,0,0,0, 1,0,0, 0,0, 2,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_bristleback"] 			= {1, 2,0,2,0, 2,0,0,1, 0,0,1,0,1, 1,1,0,0, 1,0,0,0,0,0, 0,0,0, 0,0, 0,0, 1,0, 0,0, 0,0,0},
	["npc_dota_hero_tusk"] 					= {1, 1,0,2,2, 1,0,1,1, 0,2,2,0,1, 0,0,0,0, 2,1,0,0,0,0, 0,0,2, 0,0, 0,0, 0,2, 0,0, 0,0,0},
	["npc_dota_hero_skywrath_mage"] 		= {3, 0,1,0,2, 0,2,0,1, 1,0,1,0,0, 0,2,0,0, 2,0,0,1,0,0, 0,0,0, 0,0, 0,0, 0,0, 2,0, 0,0,0},
	["npc_dota_hero_abaddon"] 				= {1, 0,0,1,2, 2,0,0,0, 0,1,2,0,0, 0,1,0,0, 0,0,0,0,0,1, 0,2,0, 1,0, 1,0, 1,0, 0,0, 0,0,0},
	["npc_dota_hero_elder_titan"] 			= {1, 0,0,0,2, 0,2,1,1, 1,2,2,0,2, 0,1,0,0, 1,1,0,0,0,0, 0,0,1, 0,0, 0,0, 2,0, 2,0, 0,0,0},
	["npc_dota_hero_legion_commander"] 		= {1, 1,2,2,0, 1,0,1,0, 2,1,0,0,1, 1,1,1,0, 1,1,0,1,0,1, 0,1,2, 0,0, 1,0, 1,0, 0,0, 0,0,1},
	["npc_dota_hero_ember_spirit"] 			= {2, 2,2,0,0, 0,1,1,1, 1,0,1,0,1, 2,1,0,0, 2,0,2,0,0,0, 2,0,0, 0,0, 0,0, 0,0, 0,0, 0,1,0},
	["npc_dota_hero_earth_spirit"] 			= {1, 0,0,0,2, 1,1,2,1, 1,1,1,0,1, 0,2,0,0, 1,1,0,1,0,0, 1,0,0, 0,0, 0,0, 0,1, 0,1, 0,0,0},
	["npc_dota_hero_terrorblade"] 			= {2, 2,1,0,0, 0,1,0,2, 0,0,0,2,0, 2,1,0,0, 1,0,0,0,0,0, 0,0,1, 0,0, 0,0, 0,0, 0,0, 2,0,0},
	["npc_dota_hero_phoenix"] 				= {3, 0,0,1,2, 0,2,0,1, 0,1,2,0,1, 0,1,0,0, 1,0,0,0,0,0, 1,0,1, 0,0, 2,0, 0,2, 0,0, 0,0,0},
	["npc_dota_hero_oracle"] 				= {3, 0,0,0,2, 0,2,0,1, 0,2,1,0,0, 0,1,0,0, 1,0,0,0,0,2, 1,2,0, 0,0, 2,0, 1,2, 0,2, 0,0,0},
	["npc_dota_hero_techies"] 				= {0, 0,0,1,2, 0,2,1,1, 0,1,1,0,2, 0,0,0,1, 1,0,1,1,0,0, 0,0,0, 1,0, 0,0, 0,0, 0,0, 0,0,0},
	["npc_dota_hero_winter_wyvern"] 		= {3, 0,0,0,2, 0,1,2,1, 1,2,2,0,2, 0,2,0,1, 1,2,0,0,0,0, 1,0,2, 0,0, 1,0, 0,2, 0,0, 0,0,0},
	["npc_dota_hero_arc_warden"] 			= {2, 2,1,0,1, 0,2,0,1, 0,0,1,1,0, 1,0,0,0, 1,0,0,0,0,0, 0,0,0, 0,0, 0,0, 2,1, 0,0, 1,0,0},
	["npc_dota_hero_abyssal_underlord"] 	= {1, 0,0,2,1, 2,0,1,1, 1,2,2,2,2, 1,2,0,0, 1,0,2,0,0,0, 1,0,0, 0,1, 0,0, 0,2, 0,0, 0,0,0},
	["npc_dota_hero_monkey_king"] 			= {2, 2,1,1,1, 1,1,0,1, 1,1,1,0,0, 1,2,0,1, 2,1,0,0,0,0, 1,0,0, 0,0, 1,0, 0,0, 0,0, 0,1,0}
};
heroRatingLength = 113;

keys = {
		"s/a/i",
		"core","mid","off","support",
		"frontline","backline","control","dps",
		"initiation","countrinit","teamfight","push","defense",
		"greed","lane","jungle","vision",
		"burst","stun","root","silence","manaburn","purge","evasive",
		"magicimmune","ignoreimmune","invis","truesight","heal","counterheal",
		"+physical","-physical","+magical","-magical",
		"illusion","splash","bashlord"
		};
----------------------------------------------------------------------------------------------------

heroCombo = {
----TeamAura
	["npc_dota_hero_drow_ranger"] = {"npc_dota_hero_dragon_knight","npc_dota_hero_visage","npc_dota_hero_batrider","npc_dota_hero_windrunner","npc_dota_hero_vengefulspirit","npc_dota_hero_weaver","npc_dota_hero_mirana","npc_dota_hero_puck","npc_dota_hero_queenofpain","npc_dota_hero_dazzle","npc_dota_hero_oracle","npc_dota_hero_beastmaster","npc_dota_hero_medusa"},
	["npc_dota_hero_vengefulspirit"] = {"npc_dota_hero_elder_titan","npc_dota_hero_templar_assassin","npc_dota_hero_nevermore","npc_dota_hero_weaver","npc_dota_hero_beastmaster","npc_dota_hero_drow_ranger","npc_dota_hero_lone_druid","npc_dota_hero_lycan","npc_dota_hero_slardar"},
	["npc_dota_hero_beastmaster"] = {"npc_dota_hero_ogre_magi","npc_dota_hero_dragon_knight","npc_dota_hero_vengefulspirit","npc_dota_hero_drow_ranger","npc_dota_hero_luna","npc_dota_hero_invoker","npc_dota_hero_abyssal_underlord"},
	["npc_dota_hero_luna"] = {"npc_dota_hero_shadow_demon","npc_dota_hero_dragon_knight","npc_dota_hero_vengefulspirit","npc_dota_hero_beastmaster","npc_dota_hero_abyssal_underlord"},
	["npc_dota_hero_shadow_demon"] = {"npc_dota_hero_alchemist","npc_dota_hero_slardar","npc_dota_hero_centaur","npc_dota_hero_luna","npc_dota_hero_kunkka","npc_dota_hero_lina","npc_dota_hero_leshrac","npc_dota_hero_mirana","npc_dota_hero_pudge","npc_dota_hero_dragon_knight","npc_dota_hero_morphling","npc_dota_hero_terrorblade","npc_dota_hero_drow_ranger"},
----TeamZoo
	["npc_dota_hero_lycan"] = {"npc_dota_hero_weaver","npc_dota_hero_beastmaster","npc_dota_hero_death_prophet","npc_dota_hero_vengefulspirit"},
	["npc_dota_hero_lone_druid"] = {"npc_dota_hero_weaver","npc_dota_hero_beastmaster","npc_dota_hero_death_prophet","npc_dota_hero_leshrac"},
----TeamBomb
	["npc_dota_hero_life_stealer"] = {"npc_dota_hero_batrider","npc_dota_hero_slardar","npc_dota_hero_nyx_assassin","npc_dota_hero_sand_king","npc_dota_hero_centaur","npc_dota_hero_earth_spirit"},
	["npc_dota_hero_batrider"] = {"npc_dota_hero_life_stealer","npc_dota_hero_drow_ranger","npc_dota_hero_silencer","npc_dota_hero_pudge","npc_dota_hero_queenofpain"},
	["npc_dota_hero_slardar"] = {"npc_dota_hero_elder_titan","npc_dota_hero_templar_assassin","npc_dota_hero_life_stealer","npc_dota_hero_tiny","npc_dota_hero_silencer","npc_dota_hero_shadow_demon","npc_dota_hero_vengefulspirit"},
	["npc_dota_hero_nyx_assassin"] = {"npc_dota_hero_life_stealer","npc_dota_hero_silencer","npc_dota_hero_shadow_demon","npc_dota_hero_obsidian_destroyer","npc_dota_hero_queenofpain"},
	["npc_dota_hero_sand_king"] = {"npc_dota_hero_life_stealer","npc_dota_hero_mirana","npc_dota_hero_lina","npc_dota_hero_leshrac","npc_dota_hero_tiny","npc_dota_hero_silencer"},
	["npc_dota_hero_centaur"] = {"npc_dota_hero_life_stealer","npc_dota_hero_tiny","npc_dota_hero_silencer","npc_dota_hero_shadow_demon"},
	["npc_dota_hero_tiny"] = {"npc_dota_hero_treant","npc_dota_hero_centaur","npc_dota_hero_sand_king","npc_dota_hero_slardar","npc_dota_hero_silencer","npc_dota_hero_wisp","npc_dota_hero_earthshaker"},
	["npc_dota_hero_silencer"] = {"npc_dota_hero_batrider","npc_dota_hero_slardar","npc_dota_hero_sand_king","npc_dota_hero_centaur","npc_dota_hero_tiny","npc_dota_hero_bounty_hunter"},
----TeamImpresionment
	["npc_dota_hero_mirana"] = {"npc_dota_hero_shadow_demon","npc_dota_hero_sand_king","npc_dota_hero_obsidian_destroyer","npc_dota_hero_bane","npc_dota_hero_elder_titan"},
	["npc_dota_hero_pudge"] = {"npc_dota_hero_obsidian_destroyer","npc_dota_hero_shadow_demon","npc_dota_hero_bane","npc_dota_hero_invoker","npc_dota_hero_rattletrap"},
	["npc_dota_hero_elder_titan"] = {"npc_dota_hero_obsidian_destroyer","npc_dota_hero_shadow_demon","npc_dota_hero_bane","npc_dota_hero_mirana","npc_dota_hero_invoker"},
	["npc_dota_hero_bane"] = {"npc_dota_hero_elder_titan","npc_dota_hero_kunkka","npc_dota_hero_pudge","npc_dota_hero_mirana","npc_dota_hero_leshrac","npc_dota_hero_invoker"},
	["npc_dota_hero_ember_spirit"] = {"npc_dota_hero_mirana","npc_dota_hero_pudge","npc_dota_hero_kunkka","npc_dota_hero_dark_seer","npc_dota_hero_magnataur","npc_dota_hero_elder_titan"},
----TeamFight
	["npc_dota_hero_warlock"] = {"npc_dota_hero_mirana","npc_dota_hero_phoenix","npc_dota_hero_luna","npc_dota_hero_abyssal_underlord","npc_dota_hero_nevermore","npc_dota_hero_magnataur"},
	["npc_dota_hero_faceless_void"] = {"npc_dota_hero_elder_titan","npc_dota_hero_phoenix","npc_dota_hero_ancient_apparition","npc_dota_hero_magnataur","npc_dota_hero_queenofpain","npc_dota_hero_weaver","npc_dota_hero_dark_seer"},
	["npc_dota_hero_phoenix"] = {"npc_dota_hero_tidehunter","npc_dota_hero_faceless_void","npc_dota_hero_magnataur","npc_dota_hero_axe","npc_dota_hero_treant","npc_dota_hero_centaur","npc_dota_hero_slardar"},
	["npc_dota_hero_ancient_apparition"] = {"npc_dota_hero_ember_spirit","npc_dota_hero_magnataur","npc_dota_hero_faceless_void","npc_dota_hero_tidehunter","npc_dota_hero_treant"},
	["npc_dota_hero_treant"] = {"npc_dota_hero_ancient_apparition","npc_dota_hero_phoenix","npc_dota_hero_weaver","npc_dota_hero_queenofpain","npc_dota_hero_kunkka"},
	["npc_dota_hero_magnataur"] = {"npc_dota_hero_juggernaut","npc_dota_hero_legion_commander","npc_dota_hero_ember_spirit","npc_dota_hero_faceless_void","npc_dota_hero_alchemist","npc_dota_hero_sven","npc_dota_hero_phantom_assassin"},
----TeamCaveman
	["npc_dota_hero_kunkka"] = {"npc_dota_hero_tinker","npc_dota_hero_obsidian_destroyer","npc_dota_hero_shadow_demon","npc_dota_hero_bane","npc_dota_hero_ursa","npc_dota_hero_dark_seer","npc_dota_hero_riki","npc_dota_hero_mirana"},
	["npc_dota_hero_disruptor"] = {"npc_dota_hero_slark","npc_dota_hero_spirit_breaker","npc_dota_hero_ursa","npc_dota_hero_dark_seer","npc_dota_hero_riki","npc_dota_hero_life_stealer","npc_dota_hero_pudge"},
	["npc_dota_hero_spirit_breaker"] = {"npc_dota_hero_shredder","npc_dota_hero_ogre_magi","npc_dota_hero_ursa","npc_dota_hero_disruptor","npc_dota_hero_dark_seer","npc_dota_hero_oracle","npc_dota_hero_invoker"},
	["npc_dota_hero_dark_seer"] = {"npc_dota_hero_shredder","npc_dota_hero_ember_spirit","npc_dota_hero_slark","npc_dota_hero_mirana","npc_dota_hero_spirit_breaker","npc_dota_hero_ember_spirit","npc_dota_hero_riki","npc_dota_hero_bounty_hunter","npc_dota_hero_disruptor","npc_dota_hero_ursa","npc_dota_hero_phantom_assassin","npc_dota_hero_slardar","npc_dota_hero_axe","npc_dota_hero_centaur"},
----TeamGlobal
	["npc_dota_hero_wisp"] = {},
	["npc_dota_hero_abyssal_underlord"] = {},
----TeamLaneFitness
	["npc_dota_hero_riki"] = {},
	["npc_dota_hero_bounty_hunter"] = {},
	["npc_dota_hero_ogre_magi"] = {},
	["npc_dota_hero_winter_wyvern"] = {},
	["npc_dota_hero_earth_spirit"] = {},
	["npc_dota_hero_undying"] ={},
	["npc_dota_hero_skywrath_mage"] = {},
	["npc_dota_hero_witch_doctor"] = {},
----TeamVersatile
	["npc_dota_hero_shredder"] = {},
	["npc_dota_hero_monkey_king"] = {},
	["npc_dota_hero_rubick"] = {},
	["npc_dota_hero_juggernaut"] = {},
	["npc_dota_hero_legion_commander"] = {},
	["npc_dota_hero_razor"] = {},
----TeamNevermore
	["npc_dota_hero_rattletrap"] = {"npc_dota_hero_nevermore","npc_dota_hero_pudge","npc_dota_hero_shadow_demon","npc_dota_hero_invoker","npc_dota_hero_mirana","npc_dota_hero_elder_titan"},
----TeamNagaSiren
	["npc_dota_hero_keeper_of_the_light"] = {"npc_dota_hero_ember_spirit","npc_dota_hero_storm_spirit","npc_dota_hero_phantom_lancer","npc_dota_hero_naga_siren","npc_dota_hero_batrider","npc_dota_hero_slardar","npc_dota_hero_nyx_assassin","npc_dota_hero_tiny","npc_dota_hero_sand_king","npc_dota_hero_centaur"},
	["npc_dota_hero_naga_siren"] = {"npc_dota_hero_keeper_of_the_light","npc_dota_hero_mirana","npc_dota_hero_disruptor","npc_dota_hero_kunkka","npc_dota_hero_enigma","npc_dota_hero_undying"},
----TeamHuskar
	["npc_dota_hero_dazzle"] = {"npc_dota_hero_huskar","npc_dota_hero_meepo","npc_dota_hero_sand_king","npc_dota_hero_dark_seer","npc_dota_hero_obsidian_destroyer","npc_dota_hero_phantom_lancer"},
	["npc_dota_hero_oracle"] = {"npc_dota_hero_huskar","npc_dota_hero_alchemist","npc_dota_hero_earth_spirit","npc_dota_hero_sand_king","npc_dota_hero_obsidian_destroyer","npc_dota_hero_spirit_breaker"},
	["npc_dota_hero_omniknight"] = {"npc_dota_hero_ember_spirit","npc_dota_hero_huskar","npc_dota_hero_sand_king","npc_dota_hero_obsidian_destroyer","npc_dota_hero_legion_commander","npc_dota_hero_spirit_breaker"}
};
heroComboLength = 52;

----------------------------------------------------------------------------------------------------

heroCounter = {};
teamCounter = {};


----------------------------------------------------------------------------------------------------

for k,v in pairs( utility ) do _G._savedEnv[k] = v end
