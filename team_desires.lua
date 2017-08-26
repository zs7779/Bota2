utils = require( GetScriptDirectory().."/utils" );

function UpdatePushLaneDesires()
	local friend = GetTeam();
	local enemy = GetOpposingTeam();
	local enemyHeroes = GetUnitList( UNIT_LIST_ENEMY_HEROES );
	
	local topList = {TOWER_TOP_1,TOWER_TOP_2,TOWER_TOP_3};
	local midList = {TOWER_MID_1,TOWER_MID_2,TOWER_MID_3};
	local botList = {TOWER_BOT_1,TOWER_BOT_2,TOWER_BOT_3};
	
	local topTower = utils.nextTower(enemy, topList);
	local midTower = utils.nextTower(enemy, midList);
	local botTower = utils.nextTower(enemy, botList);
    
	local topPush = 0;
	local midPush = 0;
	local botPush = 0;
	for i, hero in pairs(enemyHeroes) do
		if GetUnitToUnitDistance(topTower,hero) > 4000 then topPush = topPush + 1; end
		if GetUnitToUnitDistance(midTower,hero) > 4000 then midPush = midPush + 1; end
		if GetUnitToUnitDistance(botTower,hero) > 4000 then botPush = botPush + 1; end
	end

	return { 
	topPush/5.0,midPush/5.0,botPush/5.0
	};
end

----------------------------------------------------------------------------------------------------

function UpdateDefendLaneDesires()
	return { 
	0,0,0
	};
end

----------------------------------------------------------------------------------------------------

function UpdateFarmLaneDesires()
	return { 
	0,0,0
	};

end

----------------------------------------------------------------------------------------------------

function UpdateRoamDesire()
	roamTarget = nil;
	return { 0, roamTarget };
end

----------------------------------------------------------------------------------------------------

function UpdateRoshanDesire()
	return 0;
end

----------------------------------------------------------------------------------------------------
