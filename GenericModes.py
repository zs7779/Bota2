import os.path


modes = ["laning","attack","roam","retreat","secret_shop","side_shop","rune",\
"push_tower_top","push_tower_mid","push_tower_bot","defend_tower_top","defend_tower_mid","defend_tower_bottom",\
"assemble","team_roam","farm","defend_ally","evasive_maneuvers","roshan","item","ward"]

for mode in modes:
	luaModule = "mode_"+mode+"_generic"
	luaFile = luaModule+".lua"

	text = \
"""_G._savedEnv = getfenv()
module( "{luaFile}", package.seeall )

-- Called every ~300ms, and needs to return a floating-point value between 0 and 1 that indicates how much this mode wants to be the active mode.
function GetDesire() 
end

-- Called when a mode takes control as the active mode.
function OnStart() 
end

-- Called when a mode relinquishes control to another active mode.
function OnEnd() 
end

-- Called every frame while this is the active mode. Responsible for issuing actions for the bot to take.
function Think()
end

for k,v in pairs({luaModule}) do _G._savedEnv[k] = v end
""".format(luaFile=luaModule,luaModule=luaModule)

	if not os.path.exists(luaFile):
		with open(luaFile, 'a') as f:
		    f.write(text)