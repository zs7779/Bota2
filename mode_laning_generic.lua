Utility = require( GetScriptDirectory().."/Utility" );
local BlockCreep=Utility.BlockCreep;

_G._savedEnv = getfenv()
module( "mode_laning_generic", package.seeall )

-- Called every ~300ms, and needs to return a floating-point value between 0 and 1 that indicates how much this mode wants to be the active mode.
function GetDesire()
	if (GetGameState( ) ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState( ) ~= GAME_STATE_PRE_GAME) then return 0.0 end
	local time = DotaTime();
	return 1 - Clamp(time-240,40,180)/200;
end

-- Called when a mode takes control as the active mode.
function OnStart()
	
end

-- Called when a mode relinquishes control to another active mode.
function OnEnd() 
end

-- Called every frame while this is the active mode. Responsible for issuing actions for the bot to take.
function Think()
	local npcBot=GetBot();
	local team=GetTeam();
	local time = DotaTime();
	if npcBot:GetAssignedLane() == 4 and time >= 2 and time < 15 then
		BlockCreep(team,npcBot,LANE_MID);
	end
	if npcBot:GetAssignedLane() == 4 then
	Utility.FurthestCreepLocation(npcBot);
	end
end

for k,v in pairs(mode_laning_generic) do _G._savedEnv[k] = v end
