Utility = require( GetScriptDirectory().."/Utility" );
local heroRating = Utility.heroRating;
local keys = Utility.keys;

----------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------

local function checkTeamBalance(hero, friendRating, enemyRating, requirement)
	if (heroRating[hero][7] < 1 and (requirement > friendRating[keys[7]] or 4 < enemyRating[keys[8]])) then
	print("need frontline",hero);
		return nil;
	elseif (heroRating[hero][7] > 1 and 7 < friendRating[keys[7]])then
	print("need backline",hero);
		return nil;
	end
	if (heroRating[hero][9] < 1 and requirement > friendRating[keys[9]]) then
	print("need control",hero);
		return nil;
	elseif (heroRating[hero][10] < 1 and requirement > friendRating[keys[10]]) then
	print("need dps",hero);
		return nil;
	end
	
	return hero;
end

local function checkTeamStrength(hero, friendRating, enemyRating, requirement)
	local teamPushFactor = friendRating[keys[14]] + friendRating[keys[13]] + friendRating[keys[11]] + friendRating[keys[12]];
	local teamDefenseFactor = friendRating[keys[15]] + friendRating[keys[13]] + friendRating[keys[11]] + friendRating[keys[12]];
	local heroPushFactor = heroRating[hero][14] + heroRating[hero][13] + heroRating[hero][11] + heroRating[hero][12];
	local heroDefenseFactor = heroRating[hero][15] + heroRating[hero][13] + heroRating[hero][11] + heroRating[hero][12];

	if (heroRating[hero][11] + friendRating[keys[11]] < requirement and requirement > friendRating[keys[11]])then
	print("need initiation",hero);
		return nil;
	elseif (enemyRating[keys[12]] > 4 and friendRating[keys[12]] < requirement and heroRating[hero][12] < requirement) then
	print("need counter initiation",hero);
		return nil;
	elseif (requirement * 4 > teamPushFactor or requirement * 4 > teamDefenseFactor) then
		if (heroPushFactor < requirement and heroDefenseFactor < requirement) then
			print("need push or def",hero);
			return nil;
		elseif (teamPushFactor >= requirement * 4 and heroDefenseFactor < requirement) then
			print("need def",hero);
			return nil;
		elseif (teamDefenseFactor >= requirement * 4 and heroPushFactor < requirement) then
			print("need push",hero);
			return nil;
		end
	end

	return hero;
end

local function checkTeamLane(hero, friendRating, enemyRating, greedlimit, requirement)
	if (heroRating[hero][16] > 1 and greedlimit < friendRating[keys[16]]) then
	print("too greedy",hero);
		return nil;
	elseif (heroRating[hero][17] < requirement-1 and 5 > friendRating[keys[17]])then
	print("weak lane",hero);
		return nil;
	end

	if ((6 < enemyRating[keys[16]] or 6 < enemyRating[keys[18]]) and 5 > enemyRating[keys[17]] and heroRating[hero][17] < requirement) then
		print("need strong lane",hero);
		return nil;
	end
	if (enemyRating[keys[19]] > friendRating[keys[19]] + 2 and heroRating[hero][19] < requirement - 1) then
	print("need vision",hero);
		return nil;
	end
	
	return hero;
end

local function checkTeamSkill(hero, friendRating, enemyRating, requirement)
	local heroHardSkill = heroRating[hero][20] + heroRating[hero][21];
	local heroSoftSkill = heroRating[hero][22] + heroRating[hero][23] + heroRating[hero][24] + heroRating[hero][25];
	local friendHardSkill = friendRating[keys[20]] + friendRating[keys[21]];
	local friendSoftSkill = friendRating[keys[22]] + friendRating[keys[23]] + friendRating[keys[24]] + friendRating[keys[25]];
	local enemyHardSkill = enemyRating[keys[20]] + enemyRating[keys[21]];
	local enemySoftSkill = enemyRating[keys[22]] + enemyRating[keys[23]] + enemyRating[keys[24]] + enemyRating[keys[25]];


	if (friendHardSkill < 4 and heroHardSkill < requirement - 1) then
	print("need hard skill",hero);
		return nil;
	elseif (friendSoftSkill + friendRating[keys[21]] < 6 and enemyRating[keys[26]] > 4 and heroSoftSkill + heroRating[hero][21] < requirement) then
	print("need more disable",hero);
		return nil;
	elseif (enemyHardSkill + enemySoftSkill < 6 and friendRating[keys[26]] < requirement and heroRating[hero][26] < requirement) then
	print("need slipery hero",hero);
		return nil;
	elseif (enemyHardSkill + enemySoftSkill > 10 and friendRating[keys[27]] < requirement and friendRating[keys[12]] < requirement and heroRating[hero][27] < requirement and heroRating[hero][12] < requirement) then
	print("need magic immune",hero);
		return nil;
	elseif (enemyRating[keys[27]] > 2 and friendRating[keys[28]] < requirement and heroRating[hero][28] < requirement) then
	print("need pierece magic immune",hero);
		return nil;
	elseif (enemyRating[keys[30]] >= 2 and friendRating[keys[29]] >= 2 and heroRating[hero][29] > 1) then
	print("need less invis",hero);
		return nil;
	elseif (enemyRating[keys[32]] >= 2 and friendRating[keys[31]] >= 2 and heroRating[hero][31] > 1) then
	print("too many healer",hero);
		return nil;
	elseif (enemyRating[keys[33]] > 3 and friendRating[keys[34]] < requirement and heroRating[hero][34] < requirement) then
	print("need +armor",hero);
		return nil;
	elseif (enemyRating[keys[35]] > 3 and friendRating[keys[36]] < requirement and heroRating[hero][36] < requirement) then
	print("need -magic",hero);
		return nil;
	elseif (enemyRating[keys[38]] > 2 and heroRating[hero][37] > 1) then
	print("too many illusions",hero);
		return nil;
	end
	return hero;
end

local function BanPickLogic(i, id)
----Return a hero name string. cannot be nil----

	local heroTable;
	local randomHero;
	local idx = 0;
	local hero;

	local friendRating = Utility.TeamAttributes(GetTeam());
	local enemyRating = Utility.TeamAttributes(TEAM_RADIANT+TEAM_DIRE-GetTeam());
	
	local rdx = RandomInt(1,i-1);
	if (i > 1 and Utility.heroCombo[GetSelectedHeroName(id-rdx)] ~= nil and RollPercentage(80)) then
		heroTable = Utility.heroCombo[GetSelectedHeroName(id-rdx)];
		randomHero = RandomInt(1,#heroTable);
		for key,value in ipairs(heroTable) do
			if key == randomHero then
				hero = value;
			end
		end
	else
		if i<=2 and RollPercentage(50) then
			heroTable = Utility.heroStarter;
			randomHero = RandomInt(1,#Utility.heroStarter);
			for key,value in ipairs(heroTable) do
				idx = idx + 1;
				if idx == randomHero then
					hero = value;
				end
			end
		else
			if i <= 3 then
				heroTable = Utility.heroCombo;
				randomHero = RandomInt(1,Utility.heroComboLength);
			else
				heroTable = heroRating;
				randomHero = RandomInt(1,Utility.heroRatingLength);
			end
			for key,value in pairs(heroTable) do
				idx = idx + 1;
				if idx == randomHero then
					hero = key;
				end
			end
		end
	end
	

---- pick or not to pick
	-- if GameTime() < (15 + i*7+RandomInt(0,10)) then
	-- 	return nil;
	-- end
	-- if (friendRating["picked"] > enemyRating["picked"] and GameTime() < 70) then
	-- 	return nil;
	-- end

	local timeFactor = Max(0,(GameTime() - 70) / 10);
	local positionRequirement = Max(1,2 - timeFactor);
	local balanceRequirement = Max(1,2 - timeFactor);
	local winRequirement = Max(1,2 - timeFactor);
	local greedlimit = Min(8,5 + timeFactor);
	local laneRequirement = Max(1,2 - timeFactor);
	local skillRequirement = Max(1,2 - timeFactor*2);
----heroes not implemented
	if heroRating[hero] == nil or  heroRating[hero][1] == 0 then return nil	end
----heroes picked
	for i,id in pairs(GetTeamPlayers(TEAM_DIRE)) do
		if hero == GetSelectedHeroName(id) then	return nil end
	end
	for i,id in pairs(GetTeamPlayers(TEAM_RADIANT)) do
		if hero == GetSelectedHeroName(id) then	return nil end
	end	
----heroes unfit to position
	local fitposition = false;
	for k,v in ipairs(Utility.heroes[i]) do
		if v == hero and heroRating[hero][i+1] >= positionRequirement then
			fitposition = true;
			break;
		end
	end
	if fitposition == false then return nil	end
----first 2 picks are not subjected to requirement check
	if (i <= 2 or hero == nil) then return hero end
----
	if checkTeamBalance(hero, friendRating, enemyRating, balanceRequirement) == nil then
		return nil;
	elseif checkTeamStrength(hero, friendRating, enemyRating, winRequirement) == nil then
		return nil;
	elseif checkTeamLane(hero, friendRating, enemyRating, greedlimit, laneRequirement) == nil then
		return nil;
	elseif checkTeamSkill(hero, friendRating, enemyRating, skillRequirement) == nil then
		return nil;
	end

	return hero;
end


function Think()
	if GetGameState() ~= GAME_STATE_HERO_SELECTION then	return end

	local friendTeam = GetTeam();
	local IDs=GetTeamPlayers(friendTeam);

	local lineUpLength = RandomInt(1,#Utility.FullLineUps); --
	for i,id in pairs(IDs) do
		if (IsPlayerBot(id) and IsPlayerInHeroSelectionControl(id) and GetSelectedHeroName(id) == "") then
			-- local hero = BanPickLogic(i, id);
			hero = Utility.FullLineUps[lineUpLength][i];
			if hero ~= nil then
				SelectHero(id,hero);

			end
		end
	end
	local friendRating = Utility.TeamAttributes(friendTeam);
	local enemyRating = Utility.TeamAttributes(TEAM_RADIANT+TEAM_DIRE-friendTeam);
	if friendRating["picked"] == 5 and enemyRating["picked"] == 5 then
		print("Carry: ",friendRating["core"],"Mid: ",friendRating["mid"]);
		print("Offlane: ",friendRating["off"],"greedsupp: ",friendRating["greedsupp"],"Supp: ",friendRating["support"]);
		print("Front:", friendRating["frontline"],"Back: ",friendRating["backline"]);
		print("Stun: ",friendRating["control"],"Damage: ",friendRating["dps"]);
		print("Init: ",friendRating["initiation"],"Ctrinit: ",friendRating["countrinit"]);
		print("Push: ",friendRating["push"],"Defense: ",friendRating["defense"]);
		print("Greed: ",friendRating["greed"],"Lane: ",friendRating["lane"]);
	
		local p = {
			[1] = "carry",
			[2] = "mid",
			[3] = "offlane",
			[4] = "greedysupport",
			[5] = "support"
		};
		for i,id in pairs(IDs) do
	    	print(GetSelectedHeroName(id),p[i]);
	    end
    end
end

----------------------------------------------------------------------------------------------------

function UpdateLaneAssignments()
    local IDs=GetTeamPlayers(GetTeam());
    local friendRating = Utility.TeamAttributes(GetTeam());

    if ( friendRating["picked"] ~= 5 )
    then
        return {
        [1] = LANE_MID,
        [2] = LANE_MID,
        [3] = LANE_MID,
        [4] = LANE_MID,
        [5] = LANE_MID,
        };
    end

    if ( GetTeam() == TEAM_RADIANT and friendRating["picked"] == 5 )
    then
        return {
        [1] = 1,
        [2] = 2,
        [3] = 3,
        [4] = 4,
        [5] = 5,
        };
    elseif ( GetTeam() == TEAM_DIRE and friendRating["picked"] == 5 )
    then
        return {
        [1] = 1,
        [2] = 2,
        [3] = 3,
        [4] = 4,
        [5] = 5,
        };
    end
end