require(GetScriptDirectory() ..  "/utils")

-- I don't know how to define this cuz
-- you always want to push all the lanes
-- so the fewer the enemies show the less you want to push?
-- how is that different from farm
-- then the more people you have the more you want to push
function UpdatePushLaneDesires()
	local team = GetTeam();
	local lanePosition = {};
	for lane = LANE_TOP, LANE_BOT do
		lanePosition[#lanePosition+1] = GetLaneFrontAmount(team, lane, false);
	end
	for _, id in ipairs(GetTeamPlayers(GetOpposingTeam())) do
		local lastSeen = GetHeroLastSeenInfo(id);
		lastSeen.location, lastSeen.time_since_seen
	end
end

-- you want to defend when enemy are close to your tower
-- but the fewer enemies show the more defensive you are (aoe from long distance)
function UpdateDefendLaneDesires()
 
end


-- maybe I can use farm desire to represent how
-- save it is to stay in the lane
-- *** or maybe use this to represent the amount of farm available
-- need to count number of creeps and neutrals yadiyada
-- { { string, vector }, ... } GetNeutralSpawners()
-- Returns a table containing a list of camp-type and location pairs. 
-- Camp types are one of "basic_N", "ancient_N", "basic_enemy_N", "ancient_enemy_N", where N counts up from 0.
function UpdateFarmLaneDesires()

	
end

-- maybe use this to represent an easy target
-- but not necessarily gank target
function UpdateRoamDesire()
 
end

-- depends on how quickly you can kill rosh
-- and how many enemies are dead
function UpdateRoshanDesire()
 
end