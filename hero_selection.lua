require( GetScriptDirectory().."/utility" );
local heroRating = utility.heroRating;
local heroRatingLength = utility.heroRatingLength;
local keys = utility.keys;
local heroCombo = utility.heroCombo;
local heroComboLength = utility.heroComboLength;
local heroCounter = utility.heroCounter;
local teamCounter = utility.teamCounter;

----------------------------------------------------------------------------------------------------

function TeamAttriutes(team)
	local teamRating = {
		["picked"] = 0, 		["s/a/i"] = -5,
		["core"] = 0, 		["mid"] = 0,
		["off"] = 0,		["support"] = 0,
		["frontline"] = 0,	["backline"] = 0,	["control"] = 0,	["dps"] = 0,
		["initiation"] = 0,	["countrinit"] = 0,	["teamfight"] = 0,	["push"] = 0,		["defense"] = 0,	
		["greed"] = 0,		["lane"] = 0,		["jungle"] = 0,		["vision"] = 0,
		["burst"] = 0,		["stun"] = 0, 		["root"] = 0, 		["silence"] = 0,	["manaburn"] = 0,	["purge"] = 0,		["evasive"] = 0,
		["magicimmune"] = 0,["ignoreimmune"] = 0,
		["invis"] = 0,		["truesight"] = 0,
		["heal"] = 0,		["counterheal"] = 0,
		["+physical"] = 0,	["-physical"] = 0,
		["+magical"] = 0,	["-magical"] = 0,
		["illusion"] = 0,	["splash"] = 0,		["bashlord"] = 0
	};

	local IDs = GetTeamPlayers(team);
	for i,id in pairs(IDs) do
		local hero = GetSelectedHeroName(id);
		if hero ~= "" then
			teamRating["picked"] = teamRating["picked"] + 1;

			teamRating["s/a/i"] = teamRating["s/a/i"]+heroRating[hero][1];

			teamRating["core"] = teamRating["core"]+heroRating[hero][2]; 			teamRating["mid"] = teamRating["mid"]+heroRating[hero][3];			
			teamRating["off"] = teamRating["off"]+heroRating[hero][4];				teamRating["support"] = teamRating["support"]+heroRating[hero][5];

			teamRating["frontline"] = teamRating["frontline"]+heroRating[hero][6];	teamRating["backline"] = teamRating["backline"]+heroRating[hero][7];
			teamRating["control"] = teamRating["control"]+heroRating[hero][8];		teamRating["dps"] = teamRating["dps"]+heroRating[hero][9];

			teamRating["initiation"] = teamRating["initiation"]+heroRating[hero][10];teamRating["countrinit"] = teamRating["countrinit"]+heroRating[hero][11];	
			teamRating["teamfight"] = teamRating["teamfight"]+heroRating[hero][12];	
			teamRating["push"] = teamRating["push"]+heroRating[hero][13];			teamRating["defense"] = teamRating["defense"]+heroRating[hero][14];	

			teamRating["greed"] = teamRating["greed"]+heroRating[hero][15];			teamRating["lane"] = teamRating["lane"]+heroRating[hero][16];				
			teamRating["jungle"] = teamRating["jungle"]+heroRating[hero][17];		teamRating["vision"] = teamRating["vision"]+heroRating[hero][18];

			teamRating["burst"] = teamRating["burst"]+heroRating[hero][19];			teamRating["stun"] = teamRating["stun"]+heroRating[hero][20]; 		
			teamRating["root"] = teamRating["root"]+heroRating[hero][21]; 			teamRating["silence"] = teamRating["silence"]+heroRating[hero][22];	
			teamRating["manaburn"] = teamRating["manaburn"]+heroRating[hero][23];	teamRating["purge"] = teamRating["purge"]+heroRating[hero][24];				
			teamRating["evasive"] = teamRating["evasive"]+heroRating[hero][25];

			teamRating["magicimmune"] = teamRating["magicimmune"]+heroRating[hero][26]; teamRating["ignoreimmune"] = teamRating["ignoreimmune"]+heroRating[hero][27];
			teamRating["invis"] = teamRating["invis"]+heroRating[hero][28];			teamRating["truesight"] = teamRating["truesight"]+heroRating[hero][29];
			teamRating["heal"] = teamRating["heal"]+heroRating[hero][30];			teamRating["counterheal"] = teamRating["counterheal"]+heroRating[hero][31];

			teamRating["+physical"] = teamRating["+physical"]+heroRating[hero][32];	teamRating["-physical"] = teamRating["-physical"]+heroRating[hero][33];
			teamRating["+magical"] = teamRating["+magical"]+heroRating[hero][34];	teamRating["-magical"] = teamRating["-magical"]+heroRating[hero][35];

			teamRating["illusion"] = teamRating["illusion"]+heroRating[hero][36];	teamRating["splash"] = teamRating["splash"]+heroRating[hero][37];			teamRating["bashlord"] = teamRating["bashlord"]+heroRating[hero][38];
		end
	end

	return teamRating;
end

----------------------------------------------------------------------------------------------------

function checkTeamBalance(hero, friendRating, requirement)
	if (heroRating[hero][6] < 1 and requirement > friendRating[keys[6]]) then
	print("need frontline",hero);
		return nil;
	elseif (heroRating[hero][7] < 1 and requirement > friendRating[keys[7]])then
	print("need backline",hero);
		return nil;
	end
	if (heroRating[hero][8] < 1 and requirement > friendRating[keys[8]]) then
	print("need control",hero);
		return nil;
	elseif (heroRating[hero][9] < 1 and requirement > friendRating[keys[9]]) then
	print("need dps",hero);
		return nil;
	end
	
	return hero;
end

function checkTeamStrength(hero, friendRating, enemyRating, requirement)
	local teamPushFactor = friendRating[keys[13]] + friendRating[keys[12]] + friendRating[keys[10]] + friendRating[keys[11]];
	local teamDefenseFactor = friendRating[keys[14]] + friendRating[keys[12]] + friendRating[keys[10]] + friendRating[keys[11]];
	local heroPushFactor = heroRating[hero][13] + heroRating[hero][12] + heroRating[hero][10] + heroRating[hero][11];
	local heroDefenseFactor = heroRating[hero][14] + heroRating[hero][12] + heroRating[hero][10] + heroRating[hero][11];

	if (heroRating[hero][10] + friendRating[keys[10]] < requirement and requirement > friendRating[keys[10]])then
	print("need initiation",hero);
		return nil;
	elseif (enemyRating[keys[11]] >= requirement * 2 and friendRating[keys[11]] < requirement and heroRating[hero][11] < requirement) then
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

function checkTeamLane(hero, friendRating, enemyRating, greedlimit, requirement)
	if (heroRating[hero][15] > 1 and greedlimit < friendRating[keys[15]]) then
	print("too greedy",hero);
		return nil;
	elseif (heroRating[hero][16] < 1 and requirement > friendRating[keys[16]])then
	print("weak lane",hero);
		return nil;
	end

	if ((greedlimit < enemyRating[keys[15]] or greedlimit < enemyRating[keys[17]]) and requirement > enemyRating[keys[16]] and heroRating[hero][16] < 1) then
		print("need strong lane",hero);
		return nil;
	end
	if (enemyRating[keys[18]] > friendRating[keys[18]] + 2 and heroRating[hero][18] < 1) then
	print("need vision",hero);
		return nil;
	end
	
	return hero;
end

function checkTeamSkill(hero, friendRating, enemyRating, requirement)
	local heroHardSkill = heroRating[hero][19] + heroRating[hero][20];
	local heroSoftSkill = heroRating[hero][21] + heroRating[hero][22] + heroRating[hero][23] + heroRating[hero][24];
	local friendHardSkill = friendRating[keys[19]] + friendRating[keys[20]];
	local friendSoftSkill = friendRating[keys[21]] + friendRating[keys[22]] + friendRating[keys[23]] + friendRating[keys[24]];
	local enemyHardSkill = enemyRating[keys[19]] + enemyRating[keys[20]];
	local enemySoftSkill = enemyRating[keys[21]] + enemyRating[keys[22]] + enemyRating[keys[23]] + enemyRating[keys[24]];

	if (friendHardSkill < requirement * 2 and heroHardSkill < requirement) then
	print("need hard skill",hero);
		return nil;
	elseif (friendSoftSkill + friendRating[keys[20]] < requirement * 4 and enemyRating[keys[25]] > requirement and heroSoftSkill + heroRating[hero][20] < requirement) then
	print("need more disable",hero);
		return nil;
	elseif (enemyHardSkill + enemySoftSkill < requirement * 3 and friendRating[keys[25]] < requirement and heroRating[hero][25] < requirement - 1) then
	print("need slipery hero",hero);
		return nil;
	elseif (enemyHardSkill + enemySoftSkill > requirement * 4 and friendRating[keys[26]] < requirement and heroRating[hero][26] < requirement - 1) then
	print("need magic immune",hero);
		return nil;
	elseif (enemyRating[keys[26]] > requirement and friendRating[keys[27]] < requirement and heroRating[hero][27] < requirement - 1) then
	print("need pierece magic immune",hero);
		return nil;
	elseif (enemyRating[keys[29]] >= 2 and friendRating[keys[28]] >= 2 and heroRating[hero][28] > 1) then
	print("need less invis",hero);
		return nil;
	elseif (enemyRating[keys[31]] >= 2 and friendRating[keys[30]] >= 2 and heroRating[hero][30] > 1) then
	print("too many healer",hero);
		return nil;
	elseif (enemyRating[keys[32]] > requirement and friendRating[keys[33]] < requirement and heroRating[hero][33] < requirement - 1) then
	print("need +armor",hero);
		return nil;
	elseif (enemyRating[keys[34]] > requirement and friendRating[keys[35]] < requirement and heroRating[hero][35] < requirement - 1) then
	print("need -magic",hero);
		return nil;
	elseif (enemyRating[keys[37]] > 2 and heroRating[hero][36] > 1) then
	print("too many illusions",hero);
		return nil;
	end
	return hero;
end

function BanPickLogic(i, id)
----Return a hero name string. cannot be nil----

	local heroTable;
	local randomHero;
	local idx = 0;
	local hero;

	local friendRating = TeamAttriutes(GetTeam());
	local enemyRating = TeamAttriutes(TEAM_RADIANT+TEAM_DIRE-GetTeam());

	local rand = RandomInt(1,10);
	if (i > 1 and i < 4 and heroCombo[GetSelectedHeroName(id-1)] ~= nil and rand <= 7) then
		heroTable = heroCombo[GetSelectedHeroName(id-1)];
		randomHero = RandomInt(1,#heroTable);
		for key,value in ipairs(heroTable) do
			if key == randomHero then
				hero = value;
			end
		end
	else
		if i < 4 then
			heroTable = heroCombo;
			randomHero = RandomInt(1,heroComboLength);
		else
			heroTable = heroRating;
			randomHero = RandomInt(1,heroRatingLength);
		end
		for key,value in pairs(heroTable) do
			idx = idx + 1;
			if idx == randomHero then
				hero = key;
			end
		end
	end

---- pick or not to pick
	if GameTime() < (20 + i*10+RandomInt(0,10)) then
		return nil;
	end
	if (friendRating["picked"] > enemyRating["picked"] and GameTime() < 70) then
		return nil;
	end
	for i,id in pairs(GetTeamPlayers(TEAM_DIRE)) do
		if hero == GetSelectedHeroName(id) then
			return nil;
		end
	end
	for i,id in pairs(GetTeamPlayers(TEAM_RADIANT)) do
		if hero == GetSelectedHeroName(id) then
			return nil;
		end
	end	
	if (i < 4 or hero == nil) then
		return hero;
	end
	if heroRating[hero][1] == 0 then
		return nil;
	end
----

	local timeFactor = Max(0,(GameTime() - 70) / 10);
	local heroposition = Max(1,2 - timeFactor);
	local positionRequirement = Max(1,4 - timeFactor);
	local balanceRequirement = Max(1,2 - timeFactor);
	local winRequirement = Max(1,2 - timeFactor);
	local greedlimit = Max(8,5 + timeFactor);
	local laneRequirement = Max(1,4 - timeFactor);
	local skillRequirement = Max(1,2 - timeFactor);

----After 1st pick
----First fulfill support and offlane requirements
------Support and offlane must balance the team
----Next fulfill mid or carry requirements
------Also must balance the team
--------Focus on counter picks
	if (positionRequirement > friendRating[keys[4]] or positionRequirement > friendRating[keys[5]]) then
		if (heroRating[hero][4] < heroposition and heroRating[hero][5] < heroposition) then
			print("not offlane not support",hero);
			return nil;
		elseif (heroRating[hero][4] < heroposition and positionRequirement > friendRating[keys[4]]) then
		print("not off",hero);
			return nil;
		elseif (heroRating[hero][5] < heroposition and positionRequirement > friendRating[keys[5]]) then
		print("not support",hero);
			return nil;
		end
		
	elseif (positionRequirement > friendRating[keys[2]] or positionRequirement > friendRating[keys[3]]) then
		if (heroRating[hero][2] < heroposition and heroRating[hero][3] < heroposition) then
			print("not carry not mid",hero);
			return nil;
		elseif (heroRating[hero][2] < heroposition and positionRequirement > friendRating[keys[2]]) then
		print("not carry",hero);
			return nil;
		elseif (heroRating[hero][3] < heroposition and positionRequirement > friendRating[keys[3]]) then
		print("not mid",hero);
			return nil;
		end

	end

	if checkTeamBalance(hero, friendRating, balanceRequirement) == nil then
	print("checkTeamBalance",hero);
		return nil;
	elseif checkTeamStrength(hero, friendRating, enemyRating, winRequirement) == nil then
	print("checkTeamStrength",hero);
		return nil;
	elseif checkTeamLane(hero, friendRating, enemyRating, greedlimit, laneRequirement) == nil then
	print("checkTeamLane",hero);
		return nil;
	elseif checkTeamSkill(hero, friendRating, enemyRating, skillRequirement) == nil then
	print("checkTeamSkill",hero);
		return nil;
	end

	return hero;
end

function Think()
	local IDs=GetTeamPlayers(GetTeam());
	for i,id in pairs(IDs) do
		--print(GetSelectedHeroName(id));
		if (IsPlayerBot(id) and IsPlayerInHeroSelectionControl(id) and GetSelectedHeroName(id) == "") then
			local hero = BanPickLogic(i, id);
			--print(GetTeam(),i,id,hero);
			if hero ~= nil then
				SelectHero(id,hero);
			end
		end
	end
	local friendRating = TeamAttriutes(GetTeam());
	local enemyRating = TeamAttriutes(TEAM_RADIANT+TEAM_DIRE-GetTeam());
	if friendRating["picked"] == 5 and enemyRating["picked"] == 5 then
		print("Core: ",friendRating["core"],"Mid: ",friendRating["mid"]);
		print("Offlane: ",friendRating["off"],"Support: ",friendRating["support"]);
		print("Frontline:", friendRating["frontline"],"Backline: ",friendRating["backline"]);
		print("Stun: ",friendRating["control"],"Damage: ",friendRating["dps"]);
		print("Initiation: ",friendRating["initiation"],"Countrinit: ",friendRating["countrinit"]);
		print("Push: ",friendRating["push"],"Defense: ",friendRating["defense"]);
		print("Greedy: ",friendRating["greed"],"Lane: ",friendRating["lane"]);
	

		local Lane = {};
		for i,id in pairs(IDs) do
	    	Lane[i] = id;
	    end
		
		Lane = assignLane(Lane);

	    print(GetSelectedHeroName(Lane[1]),": Mid");
	    print(GetSelectedHeroName(Lane[2]),": Carry");
	    print(GetSelectedHeroName(Lane[3]),": Offlane");
	    print(GetSelectedHeroName(Lane[5]),": GreedySup");
	    print(GetSelectedHeroName(Lane[4]),": Support");
    end
end

----------------------------------------------------------------------------------------------------

function assignLane(Lane)
	local assignments = {};
	for i = 1,5 do
		for j = 1,5 do
			for k = 1,5 do
				for l = 1,5 do
					for m = 1,5 do
						if (i~=j and i~=k and i~=l and i~=m and j~=k and j~=l and j~=m and k~=l and k~=m and l~=m) then
							table.insert(assignments,{[1]=Lane[i],[2]=Lane[j],[3]=Lane[k],[4]=Lane[l],[5]=Lane[m]});
						end
					end
				end
			end
		end
	end
	local maxPower = 0;
	local maxLane = 0;
	for i = 1,#assignments do
		local power = (heroRating[GetSelectedHeroName(assignments[i][1])][3]+
					   heroRating[GetSelectedHeroName(assignments[i][2])][2]+
					   heroRating[GetSelectedHeroName(assignments[i][3])][4]+
					   heroRating[GetSelectedHeroName(assignments[i][4])][5]+
					   heroRating[GetSelectedHeroName(assignments[i][5])][5]);
		if power > maxPower then
			maxPower = power;
			maxLane = i;
		end
	end

	return assignments[maxLane];
end

function UpdateLaneAssignments()    
    local IDs=GetTeamPlayers(GetTeam());
    local friendRating = TeamAttriutes(GetTeam());

    if ( friendRating["picked"] ~= 5 )
    then
        return {
        [1] = LANE_MID,
        [2] = LANE_BOT,
        [3] = LANE_TOP,
        [4] = LANE_BOT,
        [5] = LANE_BOT,
        };
    end
    local Lane = {};
	for i,id in pairs(IDs) do
    	Lane[i] = id;
    end
		
	Lane = assignLane(Lane);
    if ( GetTeam() == TEAM_RADIANT and friendRating["picked"] == 5 )
    then
        return {
        [Lane[1]] = LANE_MID,
        [Lane[2]] = LANE_BOT,
        [Lane[3]] = LANE_TOP,
        [Lane[5]] = LANE_BOT,
        [Lane[4]] = LANE_BOT,
        };
    elseif ( GetTeam() == TEAM_DIRE and friendRating["picked"] == 5 )
    then
        return {
        [Lane[1]] = LANE_MID,
        [Lane[2]] = LANE_TOP,
        [Lane[3]] = LANE_BOT,
        [Lane[5]] = LANE_TOP,
        [Lane[4]] = LANE_TOP,
        };
    end
end