require(GetScriptDirectory() ..  "/utils")

-- local friendTotalPower = 500;
-- local enemyTotalPower = 500;
-- local LastSeenEnemys = {};
-- local enemyPowerAtLane = {500,500,500};
-- local friendPowerAtLane = {500,500,500};
-- function initializeLastSeen()
-- 	for _, id in ipairs(GetTeamPlayers(GetOpposingTeam())) do
-- 		LastSeenEnemys[id] = {};
-- 		LastSeenEnemys[id].location = Vector(0, 0);
-- 		LastSeenEnemys[id].time = 0;
-- 		LastSeenEnemys[id].power = 100;
-- 		LastSeenEnemys[id].speed = 300;
-- 	end
-- end


-- -- so this enemy power thing works
-- -- now you want to farm if enemy power is low
-- -- you want to push if enemy power is lower than your power
-- -- you want to def if lanefront is near your tower and enemy power is present
-- -- roam into push or rosh
-- local FarmRiskFactor = 2.0;
-- local PushRiskFactor = 1.2;
-- local DefRiskFactor = 0.9;

function TeamThink()
	-- if #LastSeenEnemys == 0 then
	-- 	initializeLastSeen();
	-- 	return;
	-- end
	-- if GetGameState() <= GAME_STATE_PRE_GAME or DotaTime() < -30 then
	-- 	return {0, 0, 0};
	-- end
	-- -- last seen location and power
	-- for _, enemy in ipairs(GetUnitList(UNIT_LIST_ENEMY_HEROES)) do
	-- 	if enemy:IsTrueHero() and enemy:IsAlive() then
	-- 		LastSeenEnemys[enemy:GetPlayerID()].power = enemy:GetRawOffensivePower();
	-- 		LastSeenEnemys[enemy:GetPlayerID()].speed = enemy:GetCurrentMovementSpeed();
	-- 	end
	-- end
	-- for _, id in ipairs(GetTeamPlayers(GetOpposingTeam())) do
	-- 	if not IsHeroAlive(id) then
	-- 		LastSeenEnemys[id].power = 100;
	-- 		LastSeenEnemys[id].speed = 100;
	-- 	end
	-- 	local lastSeen = GetHeroLastSeenInfo(id)[1];
	-- 	if lastSeen ~= nil then
	-- 		LastSeenEnemys[id].location = lastSeen.location;
	-- 		LastSeenEnemys[id].time = lastSeen.time_since_seen;
	-- 	end
	-- end

	-- -- local power
	-- local team = GetTeam();
	-- local enemyTeam = GetOpposingTeam();
	-- -- local lanePosition = {};
	-- for lane = LANE_TOP, LANE_BOT do
	-- 	local laneFront = GetLaneFrontLocation(team, lane, 0);
	-- 	local enemyLaneFront = GetLaneFrontLocation(enemyTeam, lane, 0);
	-- 	local enemyPower = 0;
	-- 	for _, enemyID in ipairs(GetTeamPlayers(GetOpposingTeam())) do
	-- 		if GetLocationToLocationDistance(enemyLaneFront,LastSeenEnemys[enemyID].location)-LastSeenEnemys[enemyID].time*LastSeenEnemys[enemyID].speed<5000 then
	-- 	   	   enemyPower = enemyPower + LastSeenEnemys[enemyID].power;
	-- 	   	end
	-- 	end
	-- 	enemyPowerAtLane[lane] = enemyPower;

	-- 	local friendPower = 0;
	-- 	for N, friend in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES)) do
	-- 		if friend:IsTrueHero() then
	-- 			if GetUnitToLocationDistance(friend, laneFront) < 3000 then
	-- 	   	   		friendPower = friendPower + friend:GetOffensivePower();
	-- 	   	   	end
	-- 	   	end
	-- 	end
	-- 	friendPowerAtLane[lane] = friendPower;
	-- end

	-- -- global power
	-- friendTotalPower = 0;
	-- enemyTotalPower = 0;
	-- for _, enemyID in ipairs(GetTeamPlayers(GetOpposingTeam())) do
 --   	   enemyTotalPower = enemyTotalPower + LastSeenEnemys[enemyID].power;
 --   	end
 --   	for N, friend in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES)) do
	-- 	if friend:IsTrueHero() then
	--    	   	friendTotalPower = friendTotalPower + friend:GetOffensivePower();
	--    	end
	-- end
	-- if friendTotalPower <= 0 then friendTotalPower = 500; end
	-- if enemyTotalPower <= 0 then enemyTotalPower = 500; end
end

-- friend > enemy push and def
-- friend <= enemy trade push and def high ground

-- I don't know how to define this cuz
-- you always want to push all the lanes
-- so the fewer the enemies show the less you want to push?
-- how is that different from farm
-- then the more people you have the more you want to push
-- function UpdatePushLaneDesires()
-- 	if GetGameState() <= GAME_STATE_PRE_GAME or DotaTime() < -30 then
-- 		return {0, 0, 0};
-- 	end
-- 	local pushDesire = {0.2,0.2,0.2}
-- 	local team = GetTeam();
-- 	local enemyTeam = GetOpposingTeam();
-- 	local laneFront = {};
-- 	for lane = LANE_TOP, LANE_BOT do
-- 		laneFront[lane] = GetLaneFrontAmount(team, lane, false);
-- 		if laneFront[lane] > 0.6 then
-- 			if friendTotalPower*PushRiskFactor > enemyTotalPower then
-- 				pushDesire[lane] = (laneFront[lane]-0.6)/0.4*0.9;
-- 			else
-- 				pushDesire[lane] = Max((1.0-laneFront[lane])/0.4 * friendPowerAtLane[lane]*PushRiskFactor/enemyPowerAtLane[lane], 1.0);
-- 			end
-- 		end
-- 	end
	
-- 	return pushDesire;
-- end

-- you want to defend when enemy are close to your tower
-- but the fewer enemies show the more defensive you are (aoe from long distance)
-- For defence if you are outgunned, there is still creep wave cutting
-- probably only apply to high ground def? risky
-- function UpdateDefendLaneDesires()
-- 	if GetGameState() <= GAME_STATE_PRE_GAME or DotaTime() < -30 then
-- 		return {0, 0, 0};
-- 	end
-- 	local defDesire = {0.3, 0.3, 0.3};
-- 	local team = GetTeam();
-- 	local enemyTeam = GetOpposingTeam();
-- 	local laneFront = {};
-- 	local nextTower = utils.GetNextTowers(team);
-- 	local hgTower = {TOWER_TOP_3, TOWER_MID_3, TOWER_BOT_3};
-- 	for lane = LANE_TOP, LANE_BOT do
-- 		laneFront[lane] = GetLaneFrontAmount(enemyTeam, lane, false);
-- 		if laneFront[lane] < 0.4 then
-- 			if friendTotalPower*DefRiskFactor > enemyTotalPower or
-- 			   nextTower[lane] == hgTower[lane] then
-- 				defDesire[lane] = Max((0.4-laneFront[lane])/0.3, 1.0);
-- 			else
-- 				defDesire[lane] = Max((0.4-laneFront[lane])/0.5 * friendPowerAtLane[lane]*DefRiskFactor/enemyPowerAtLane[lane], 1.0);
-- 			end
-- 		end
-- 	end
-- 	return defDesire;
-- end


-- maybe I can use farm desire to represent how
-- save it is to stay in the lane
-- *** or maybe use this to represent the amount of farm available
-- need to count number of creeps and neutrals yadiyada
-- { { string, vector }, ... } GetNeutralSpawners()
-- Returns a table containing a list of camp-type and location pairs. 
-- Camp types are one of "basic_N", "ancient_N", "basic_enemy_N", "ancient_enemy_N", where N counts up from 0.
-- function UpdateFarmLaneDesires()
-- 	if GetGameState() <= GAME_STATE_PRE_GAME or DotaTime() < -30 then
-- 		return {0, 0, 0};
-- 	end
-- 	local friendAvgHealth = 0;
-- 	for N, friend in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES)) do
-- 		friendAvgHealth = (friendAvgHealth*(N-1) + friend:GetMaxHealth())/N;
-- 	end
-- 	friendAvgHealth = Max(friendAvgHealth, 1000);
-- 	-- print(friendAvgHealth,enemyPowerAtLane[LANE_TOP],enemyPowerAtLane[LANE_MID],enemyPowerAtLane[LANE_BOT])
-- 	return {1.0-Min(enemyPowerAtLane[LANE_TOP]/friendAvgHealth/FarmRiskFactor,1.0),
-- 			1.0-Min(enemyPowerAtLane[LANE_MID]/friendAvgHealth/FarmRiskFactor,1.0),
-- 			1.0-Min(enemyPowerAtLane[LANE_BOT]/friendAvgHealth/FarmRiskFactor,1.0)};
-- end


-- maybe use this to represent an easy target
-- but not necessarily gank target
-- function UpdateRoamDesire()
 
-- end

-- depends on how quickly you can kill rosh
-- and how many enemies are dead
-- function UpdateRoshanDesire()
 
-- end