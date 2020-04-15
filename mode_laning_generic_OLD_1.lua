_G._savedEnv = getfenv()
module( "mode_laning_generic", package.seeall )

Utility = require( GetScriptDirectory().."/Utility" );

-- Called every ~300ms, and needs to return a floating-point value between 0 and 1 that indicates how much this mode wants to be the active mode.
function GetDesire()
	if (GetGameState( ) ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState( ) ~= GAME_STATE_PRE_GAME) then return 0.0 end
	local time = DotaTime();
	-- if GetBot():GetAssignedLane()==1 then print(GetBot():GetActiveMode()) end
	if time < 0 then return 0 end
	return 1 - Clamp(time-480,40,160)/200;
-- Time -- Desire --
-- 0	   0.8
-- 120	   0.8
-- 240	   0.8
-- 360	   0.4
-- 480	   0.2
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
	local time=DotaTime();
	local lane=npcBot:GetAssignedLane();

	if lane == 4 and time < 20 then
		local botLoc = npcBot:GetLocation();
		if time < 3.5 then
			npcBot:Action_MoveToLocation( Utility.Locations[team]["MidBlockStart"] );
		elseif time >= 3.5 and (botLoc[1]<Utility.Locations[team]["MidBlockEnd"][1] or botLoc[2]<Utility.Locations[team]["MidBlockEnd"][2]) then
			Utility.BlockCreep(team,npcBot,LANE_MID);
		end
		return;
	end
	
	if lane ~= 4 and lane ~= 5 then
		LanePosition(npcBot,Utility.Locations[team][lane]);
		if TotalEnemyPower(npcBot) < npcBot:GetHealth() then LastHit(npcBot) end
		if GetUnitToLocationDistance( npcBot, GetLaneFrontLocation( team, lane, 0 ) ) > 900 then
			Utility.MoveToLane(npcBot,Utility.Locations[team][lane]);
		end
	end
	
end

function TotalEnemyPower(npcBot)
	local totalPower = 0;
	for _,enemy in ipairs(Utility.enemyHeroes) do
		if GetUnitToUnitDistance( npcBot, enemy ) < enemy:GetAttackRange() + 150 then
			totalPower = totalPower + enemy:GetRawOffensivePower( );
		end
	end
	if GetBot():GetAssignedLane()==1 then print(totalPower) end
	return totalPower;
end

function LastHit(npcBot)

	-- local lowest;
	for _,creep in ipairs(npcBot:GetNearbyLaneCreeps(1300,false)) do
		-- if creep:GetHealth(); < lowest:GetHealth then
		-- 	lowest = creep;
		-- end
		if creep:GetHealth() < npcBot:GetAttackDamage() then
			npcBot:Action_AttackUnit(creep,true);
		end
	end
	for _,creep in ipairs(npcBot:GetNearbyLaneCreeps(900,true)) do
		if creep:GetHealth() < npcBot:GetAttackDamage() then
			npcBot:Action_AttackUnit(creep,true);
		end
	end
	return furthest;
end

function LanePosition(npcBot,lane)
	local awayFromEnemy = 100;
	local loc;
	for _,enemy in ipairs(Utility.enemyHeroes) do
		if GetUnitToUnitDistance( npcBot, enemy ) < enemy:GetAttackRange() + 150 then
			loc = SafeLocationAlongLane(enemy,lane);
			if loc ~= nil then npcBot:Action_MoveToLocation(loc) end
		end
	end
	-- if WasRecentlyDamagedByCreep then
	-- 	for _,creep in ipairs(npcBot:GetNearbyLaneCreeps(500,false)) do
	-- 		if GetUnitToUnitDistance( npcBot, creep ) < creep:GetAttackRange() + 150 then
	-- 			loc = SafeLocationAlongLane(creep,lane)
	-- 			if loc ~= nil then npcBot:Action_MoveToLocation(loc) end
	-- 		end
	-- 	end
	-- end
end

function SafeLocationAlongLane(enemy,lane)
	local pos = 0.0;
	local bestpos = 0.0;
	local laneLoc;
	while (pos < 1.0) do
		laneLoc = GetLocationAlongLane(lane,pos);
		if GetUnitToLocationDistance( enemy, laneLoc ) > enemy:GetAttackRange() + 0 and pos > bestpos then
			bestpos = pos;
		else break end
		pos = pos + 0.01;
	end
	return nil;
end

for k,v in pairs(mode_laning_generic) do _G._savedEnv[k] = v end
