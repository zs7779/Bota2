Utility = require( GetScriptDirectory().."/Utility" );
-- local TeamAttributes = Utility.TeamAttributes;
local GetPresence = Utility.GetPresence;
local GetLaneDistance = Utility.GetLaneDistance;
local HeroNearTarget = Utility.HeroNearTarget;
local DayNight = Utility.DayNight;
local CanFindHero = Utility.CanFindHero;
----------------------------------------------------------------------------------------------------

function UpdatePushLaneDesires()
	if GetGameState( ) ~= GAME_STATE_GAME_IN_PROGRESS then return { 0.0, 0.0, 0.0 } end

	local friendTeam = GetTeam();
	local enemyTeam = TEAM_RADIANT+TEAM_DIRE-friendTeam;

	local presenceScore = GetPresence(); 
	local laneDistance = { [1] = 3000, [2] = 3000, [3] = 3000 }; -- lane - tower
	local heroFactor = { [1] = 0, [2] = 0, [3] = 0 };
	local tower;
	for i = 1,3 do
		laneDistance[i],tower = GetLaneDistance(enemyTeam,friendTeam,i);
		if tower ~= nil then
			-- heroFactor[i] = HeroNearTarget(false,tower,2000);
		end
	end

	return { 
	Clamp((0.5 - Clamp( laneDistance[1], 0, 3000 )/6000) + Clamp( heroFactor[1], 0, 3 )/6 + Clamp( DotaTime() - 200, -200, 0 )/200, 0 ,1),
	Clamp((0.5 - Clamp( laneDistance[2], 0, 3000 )/6000) + Clamp( heroFactor[2], 0, 3 )/6 + Clamp( DotaTime() - 200, -200, 0 )/200, 0 ,1),
	Clamp((0.5 - Clamp( laneDistance[3], 0, 3000 )/6000) + Clamp( heroFactor[3], 0, 3 )/6 + Clamp( DotaTime() - 200, -200, 0 )/200, 0 ,1)
	};
end

----------------------------------------------------------------------------------------------------

function UpdateDefendLaneDesires()
	if GetGameState( ) ~= GAME_STATE_GAME_IN_PROGRESS then return { 0.0, 0.0, 0.0 } end
	
	local friendTeam = GetTeam();
	local enemyTeam = TEAM_RADIANT+TEAM_DIRE-friendTeam;
	local laneDistance = { [1] = 3000, [2] = 3000, [3] = 3000 }; -- lane - tower
	local heroFactor = { [1] = 0, [2] = 0, [3] = 0 };
	local tower;
	for i = 1,3 do
		laneDistance[i],tower = GetLaneDistance(friendTeam,enemyTeam,i);
		if tower ~= nil then
			-- heroFactor[i] = HeroNearTarget(true,tower,2000);
		end
	end

	return { 
	Clamp((1 - Clamp( laneDistance[1], 0, 3000 )/3000) + Clamp( heroFactor[1], 0, 3 )/3, 0 ,1), 
	Clamp((1 - Clamp( laneDistance[2], 0, 3000 )/3000) + Clamp( heroFactor[2], 0, 3 )/3, 0 ,1), 
	Clamp((1 - Clamp( laneDistance[3], 0, 3000 )/3000) + Clamp( heroFactor[3], 0, 3 )/3, 0 ,1) 
	};
end

----------------------------------------------------------------------------------------------------

function UpdateFarmLaneDesires()
	if GetGameState( ) ~= GAME_STATE_GAME_IN_PROGRESS then return { 0.0, 0.0, 0.0 } end
	
	
	local friendTeam = GetTeam();
	local enemyTeam = TEAM_RADIANT+TEAM_DIRE-friendTeam;

	local presenceScore = GetPresence(); 
	local laneDistance = { [1] = 3000, [2] = 3000, [3] = 3000 }; -- lane - tower
	local heroFactor = { [1] = 0, [2] = 0, [3] = 0 };
	local tower;
	for i = 1,3 do
		laneDistance[i],tower = GetLaneDistance(friendTeam,enemyTeam,i);
		if tower ~= nil then
			-- heroFactor[i] = HeroNearTarget(true,tower,2000);
		end
	end

	return { 
	Clamp((0.5 - Clamp( laneDistance[1], 0, 3000 )/6000) + (0.5 - Clamp( heroFactor[1], 0, 3 )/6) + Clamp( 300 - DotaTime(), 0, 300 )/300, 0 ,1), 
	Clamp((0.5 - Clamp( laneDistance[2], 0, 3000 )/6000) + (0.5 - Clamp( heroFactor[2], 0, 3 )/6) + Clamp( 300 - DotaTime(), 0, 300 )/300, 0 ,1), 
	Clamp((0.5 - Clamp( laneDistance[3], 0, 3000 )/6000) + (0.5 - Clamp( heroFactor[3], 0, 3 )/6) + Clamp( 300 - DotaTime(), 0, 300 )/300, 0 ,1) 
	};

end

----------------------------------------------------------------------------------------------------

function UpdateRoamDesire()
	if (GetGameState( ) ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState( ) ~= GAME_STATE_PRE_GAME) then return { 0.0, nil } end

	local friendTeam = GetTeam();
	local enemyTeam = TEAM_RADIANT+TEAM_DIRE-friendTeam;

	local presenceScore = GetPresence();
	local roamTarget = nil;
	-- local heroes = GetTeamMember(4):GetNearbyHeroes( 2000, true, BOT_MODE_NONE );
	-- for k,v in ipairs(heroes) do
	-- 	if v~=nil and v:CanBeSeen() then roamTarget = v end
		-- if presenceScore < 4 or CanFindHero(roamTarget) ~= true or HeroNearTarget(true,roamTarget,2000) > 2 then
		-- 	roamTarget = nil;
		-- end
	-- end
	local night = 0;
	local nightRemain = 0;
	night,nightRemain = DayNight();
	return { ((1-night) * 0.5 + night * Clamp(nightRemain-30, 10, 20)/20) * presenceScore/5, roamTarget };
end

----------------------------------------------------------------------------------------------------

function UpdateRoshanDesire()
	if GetGameState( ) ~= GAME_STATE_GAME_IN_PROGRESS then return 0.0 end

	local friendTeam = GetTeam();
	local enemyTeam = TEAM_RADIANT+TEAM_DIRE-friendTeam;

	local presenceScore = GetPresence();
	if presenceScore < 4 then
		roamTarget = nil;
	end
	
	local night = 0;
	local nightRemain = 0;
	night,nightRemain = DayNight();
	return ((1-night) * 0.5 + night * Clamp(nightRemain-30, 10, 20)/20) * presenceScore/5;
end

----------------------------------------------------------------------------------------------------
