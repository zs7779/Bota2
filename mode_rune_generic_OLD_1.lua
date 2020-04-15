_G._savedEnv = getfenv()
module( "mode_rune_generic", package.seeall )

Utility = require( GetScriptDirectory().."/Utility" );

-- Called every ~300ms, and needs to return a floating-point value between 0 and 1 that indicates how much this mode wants to be the active mode.
function GetDesire()
	if (GetGameState( ) ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState( ) ~= GAME_STATE_PRE_GAME) then return 0.0 end

	local time = DotaTime();
	local npcBot = GetBot();
	if time < 1 and npcBot:GetAssignedLane() ~= 4 then return 0.9
	elseif time < 100 then return 0.0 end
	

	for rune = RUNE_POWERUP_1,RUNE_BOUNTY_4 do
		if GetUnitToLocationDistance(npcBot,GetRuneSpawnLocation( rune ))<200 and GetRuneStatus(rune)~=RUNE_STATUS_MISSING then
			return 0.9;
		end
	end

	local runeTime = time%120;
	if (runeTime < 20 or runeTime > 110) then
		return 0.6;
	end
	return 0;
end

-- Called when a mode takes control as the active mode.
function OnStart()
end

-- Called when a mode relinquishes control to another active mode.
function OnEnd()
end

-- Called every frame while this is the active mode. Responsible for issuing actions for the bot to take.
function Think()
	local npcBot = GetBot();
	local team = GetTeam();
	local time = DotaTime();
	
	if time <= 3 then
		if npcBot:GetAssignedLane() == 2 then Utility.GetRune(npcBot,RUNE_BOUNTY_2)
		elseif npcBot:GetAssignedLane() == 5 then Utility.GetRune(npcBot,RUNE_BOUNTY_1)
		elseif npcBot:GetAssignedLane() == 3 then npcBot:Action_MoveToLocation( Utility.Locations[team]["TopShrine"] )
		elseif npcBot:GetAssignedLane() == 1 then npcBot:Action_MoveToLocation( Utility.Locations[team]["BotShrine"] )
		end
	else
		for rune = RUNE_POWERUP_1,RUNE_BOUNTY_4 do
			if GetRuneStatus(rune)~=RUNE_STATUS_MISSING and GetUnitToLocationDistance( npcBot, GetRuneSpawnLocation( rune ) ) < 2000 then
				Utility.GetRune(npcBot,rune);
			end
		end
	end

end

for k,v in pairs(mode_rune_generic) do _G._savedEnv[k] = v end
