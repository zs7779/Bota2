function Think()
	if GetGameState() ~= GAME_STATE_HERO_SELECTION then	return; end
    local picks = {"npc_dota_hero_phantom_assassin","npc_dota_hero_sniper","npc_dota_hero_necrolyte","npc_dota_hero_sand_king","npc_dota_hero_jakiro"};
	local friendTeam = GetTeam();
	local IDs = GetTeamPlayers(friendTeam);
	-- GetTeamPlayers() returns only human players in bot mode, but works fine in lobby
	-- probably need to do some guess work here, infer IDs based on GetTeam and number of human players
	for i,id in pairs(IDs) do
		if (IsPlayerBot(id) and IsPlayerInHeroSelectionControl(id) and GetSelectedHeroName(id) == "") then
				SelectHero(id,picks[i]);
		end
	end
end

----------------------------------------------------------------------------------------------------

function UpdateLaneAssignments()
	local friendTeam = GetTeam();

	if friendTeam == TEAM_RADIANT then
	    return {
	    [1] = LANE_BOT,
	    [2] = LANE_MID,
	    [3] = LANE_TOP,
	    [4] = LANE_TOP,
	    [5] = LANE_BOT,
	    };
    end
    if friendTeam == TEAM_DIRE then
	    return {
	    [1] = LANE_TOP,
	    [2] = LANE_MID,
	    [3] = LANE_BOT,
	    [4] = LANE_BOT,
	    [5] = LANE_TOP,
	    };
    end
end