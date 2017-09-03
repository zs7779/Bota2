require(GetScriptDirectory() ..  "/utils")

function UpdatePushLaneDesires()
-- Consider: 1. Lane tower HP 2. # of enemy heroes defending/off map
	local enemy = GetOpposingTeam();
	local IDs = GetTeamPlayers(enemy);

	local topList = {TOWER_TOP_1,TOWER_TOP_2,TOWER_TOP_3};
	local midList = {TOWER_MID_1,TOWER_MID_2,TOWER_MID_3};
	local botList = {TOWER_BOT_1,TOWER_BOT_2,TOWER_BOT_3};
	
	local topTower = utils.nextTower(enemy, topList);
	local midTower = utils.nextTower(enemy, midList);
	local botTower = utils.nextTower(enemy, botList);
    
	local topPush = 0;
	local midPush = 0;
	local botPush = 0;

	for _, id in pairs(IDs) do
		local lastSeen = GetHeroLastSeenInfo(id)[1];
		if lastSeen ~= nil and lastSeen.time_since_seen < 30 then
			-- Need to redo to consider clones and illusions
			if GetUnitToLocationDistance(topTower,lastSeen.location) > 4000 then topPush = topPush + 0.2; end
			if GetUnitToLocationDistance(midTower,lastSeen.location) > 4000 then midPush = midPush + 0.2; end
			if GetUnitToLocationDistance(botTower,lastSeen.location) > 4000 then botPush = botPush + 0.2; end
		end
	end

	return { 
	topPush,midPush,botPush
	};
end

----------------------------------------------------------------------------------------------------

function UpdateDefendLaneDesires()
-- Consider: 1. Lane front position 2. # of enemy heroes pushing/off map
	local friend = GetTeam();
	local enemy = GetOpposingTeam();
	local IDs = GetTeamPlayers(enemy);
	
	local topList = {TOWER_TOP_1,TOWER_TOP_2,TOWER_TOP_3};
	local midList = {TOWER_MID_1,TOWER_MID_2,TOWER_MID_3};
	local botList = {TOWER_BOT_1,TOWER_BOT_2,TOWER_BOT_3};
	
	local topTower = utils.nextTower(friend, topList);
	local midTower = utils.nextTower(friend, midList);
	local botTower = utils.nextTower(friend, botList);
    
	local topDef = 0;
	local midDef = 0;
	local botDef = 0;
	for _, id in pairs(IDs) do
		local lastSeen = GetHeroLastSeenInfo(id)[1];
		if lastSeen ~= nil and lastSeen.time_since_seen < 15 then
			-- Need to redo to consider clones and illusions
			if GetUnitToLocationDistance(topTower,lastSeen.location) < 4000 then topDef = topDef + 0.2; end
			if GetUnitToLocationDistance(midTower,lastSeen.location) < 4000 then midDef = midDef + 0.2; end
			if GetUnitToLocationDistance(botTower,lastSeen.location) < 4000 then botDef = botDef + 0.2; end
		end
	end

	return { 
	topDef,midDef,botDef
	};
end

----------------------------------------------------------------------------------------------------

function UpdateFarmLaneDesires()
-- Consider: 1. Lane front location 2. # of enemy heroes near lane front/off map
	local friend = GetTeam();
	local enemy = GetOpposingTeam();
	local IDs = GetTeamPlayers(enemy);
	
	local topLane = GetLaneFrontLocation(friend,LANE_TOP,0);
	local midLane = GetLaneFrontLocation(friend,LANE_MID,0);
	local botLane = GetLaneFrontLocation(friend,LANE_BOT,0);
    DebugDrawCircle( botLane, 100, 244, 0, 0 )
	local topFarm = 0.1;
	local midFarm = 0.1;
	local botFarm = 0.1;
	for _, id in pairs(IDs) do
		local lastSeen = GetHeroLastSeenInfo(id)[1];
		if lastSeen ~= nil and lastSeen.time_since_seen < 30 then
			-- Need to redo to consider clones and illusions
			if topFarm ~= 0 and utils.locationToLocationDistance(topLane,lastSeen.location) > 5000 then topFarm = topFarm + 0.2; end
			if topFarm ~= 0 and utils.locationToLocationDistance(topLane,lastSeen.location) < 3000 then topFarm = 0; end
			if midFarm ~= 0 and utils.locationToLocationDistance(midLane,lastSeen.location) > 5000 then midFarm = midFarm + 0.2; end
			if midFarm ~= 0 and utils.locationToLocationDistance(midLane,lastSeen.location) < 3000 then midFarm = 0; end
			if botFarm ~= 0 and utils.locationToLocationDistance(botLane,lastSeen.location) > 5000 then botFarm = botFarm + 0.2; end
			if botFarm ~= 0 and utils.locationToLocationDistance(botLane,lastSeen.location) < 3000 then botFarm = 0; end
		end
	end

	return { 
	topFarm,midFarm,botFarm
	};
end

----------------------------------------------------------------------------------------------------

function UpdateRoamDesire()
-- Consider: 1. Enemy hero farthest from team 2. Target health
	local enemy = GetOpposingTeam();
	local IDs = GetTeamPlayers(enemy);
	local enemyHeroes = GetUnitList( UNIT_LIST_ENEMY_HEROES );
	local enemyTowers = GetUnitList( UNIT_LIST_ENEMY_BUILDINGS );
	
	local roam={};
	for _, targetId in pairs(IDs) do
		roam[targetId] = 0;
		local targetLastSeen = GetHeroLastSeenInfo(targetId)[1];
		if targetLastSeen ~= nil and targetLastSeen.time_since_seen < 20 then
			for _, id in pairs(IDs) do
				local lastSeen = GetHeroLastSeenInfo(id)[1];
				if targetId ~= id and lastSeen ~= nil and lastSeen.time_since_seen < 20 then
					if utils.locationToLocationDistance(targetLastSeen.location,lastSeen.location) > 4000 then roam[targetId] = roam[targetId] + 0.2; end
				end
			end
			for _, tower in pairs(enemyTowers) do
				if GetUnitToLocationDistance(tower,targetLastSeen.location) < 2000 then roam[targetId] = roam[targetId] - 0.1; end
			end
		end
	end

	local roamTarget = nil;
	local id, desire = utils.tableMax(IDs, roam);
	for _, target in pairs(enemyHeroes) do
		if target:GetPlayerID() == id then roamTarget = target; end
	end
	return { desire, roamTarget };
end

----------------------------------------------------------------------------------------------------

function UpdateRoshanDesire()
-- Consider: 1. number of enemy dead 2. team physical power 3. team distance to Roshan
	if GetRoshanKillTime() > 0 and GetRoshanKillTime() < 6*60 then return 0; end

	local enemy = GetOpposingTeam();
	local IDs = GetTeamPlayers(enemy);

	local roshan = 0;
	for _, id in pairs(IDs) do
		if not IsHeroAlive(id) then roshan = roshan + 0.15; end
	end

	local heroes = GetUnitList( UNIT_LIST_ALLIED_HEROES );
	local power = 0.0;
	for _, hero in pairs(heroes) do
		power = power + hero:GetAttackDamage();
	end
	if power*30*0.5*0.85 < 5500 then roshan = 0; end

	return roshan;
end

----------------------------------------------------------------------------------------------------
