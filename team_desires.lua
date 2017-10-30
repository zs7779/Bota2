require(GetScriptDirectory() ..  "/utils")

local LastSeenEnemys = {};
local enemyPowerAtLane = {500,500,500};
local friendPowerAtLane = {500,500,500};
function initializeLastSeen()
	for _, id in ipairs(GetTeamPlayers(GetOpposingTeam())) do
		LastSeenEnemys[id] = {};
		LastSeenEnemys[id].location = Vector(0, 0);
		LastSeenEnemys[id].time = 0;
		LastSeenEnemys[id].power = 100;
		LastSeenEnemys[id].speed = 300;
	end
end


-- so this enemy power thing works
-- now you want to farm if enemy power is low
-- you want to push if enemy power is lower than your power
-- you want to def if lanefront is near your tower and enemy power is present
-- roam into push or rosh
local FarmRiskFactor = 2.0;
local PushRiskFactor = 1.2;

function TeamThink()
	if #LastSeenEnemys == 0 then
		initializeLastSeen();
		return;
	end
	for _, enemy in ipairs(GetUnitList(UNIT_LIST_ENEMY_HEROES)) do
		if enemy:IsTrueHero() and enemy:IsAlive() then
			LastSeenEnemys[enemy:GetPlayerID()].power = enemy:GetRawOffensivePower();
			LastSeenEnemys[enemy:GetPlayerID()].speed = enemy:GetCurrentMovementSpeed();
		end
	end
	for _, id in ipairs(GetTeamPlayers(GetOpposingTeam())) do
		if not IsHeroAlive(id) then
			LastSeenEnemys[id].power = 0;
			LastSeenEnemys[id].speed = 100;
		end
		local lastSeen = GetHeroLastSeenInfo(id)[1];
		if lastSeen ~= nil then
			LastSeenEnemys[id].location = lastSeen.location;
			LastSeenEnemys[id].time = lastSeen.time_since_seen;
		end
	end
	local team = GetTeam();
	-- local lanePosition = {};
	for lane = LANE_TOP, LANE_BOT do
		local laneFront = GetLaneFrontLocation(team, lane, 0);
		local enemyPower = 0;
		for _, enemyID in ipairs(GetTeamPlayers(GetOpposingTeam())) do
			if GetLocationToLocationDistance(laneFront,LastSeenEnemys[enemyID].location)-LastSeenEnemys[enemyID].time*LastSeenEnemys[enemyID].speed<5000 then
		   	   enemyPower = enemyPower + LastSeenEnemys[enemyID].power;
		   	end
		end
		enemyPowerAtLane[lane] = enemyPower;

		local friendPower = 0;
		for N, friend in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES)) do
			if friend:IsTrueHero() then
				if GetUnitToLocationDistance(friend, laneFront) < 3000 then
		   	   		friendPower = friendPower + friend:GetOffensivePower();
		   	   	end
		   	end
		end
		friendPowerAtLane[lane] = friendPower;
	end
end

-- I don't know how to define this cuz
-- you always want to push all the lanes
-- so the fewer the enemies show the less you want to push?
-- how is that different from farm
-- then the more people you have the more you want to push
-- function UpdatePushLaneDesires()

-- end

-- you want to defend when enemy are close to your tower
-- but the fewer enemies show the more defensive you are (aoe from long distance)
-- function UpdateDefendLaneDesires()

-- end


-- maybe I can use farm desire to represent how
-- save it is to stay in the lane
-- *** or maybe use this to represent the amount of farm available
-- need to count number of creeps and neutrals yadiyada
-- { { string, vector }, ... } GetNeutralSpawners()
-- Returns a table containing a list of camp-type and location pairs. 
-- Camp types are one of "basic_N", "ancient_N", "basic_enemy_N", "ancient_enemy_N", where N counts up from 0.
function UpdateFarmLaneDesires()
	local friendAvgHealth = 0;
	for N, friend in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES)) do
		friendAvgHealth = (friendAvgHealth*(N-1) + friend:GetMaxHealth())/N;
	end
	friendAvgHealth = math.max(friendAvgHealth, 1000);
	-- print(friendAvgHealth,enemyPowerAtLane[LANE_TOP],enemyPowerAtLane[LANE_MID],enemyPowerAtLane[LANE_BOT])
	return {1.0-math.min(enemyPowerAtLane[LANE_TOP]/friendAvgHealth/FarmRiskFactor,1.0),
			1.0-math.min(enemyPowerAtLane[LANE_MID]/friendAvgHealth/FarmRiskFactor,1.0),
			1.0-math.min(enemyPowerAtLane[LANE_BOT]/friendAvgHealth/FarmRiskFactor,1.0)};
end


-- maybe use this to represent an easy target
-- but not necessarily gank target
-- function UpdateRoamDesire()
 
-- end

-- depends on how quickly you can kill rosh
-- and how many enemies are dead
-- function UpdateRoshanDesire()
 
-- end