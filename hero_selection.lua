function Think()
	if GetGameState() ~= GAME_STATE_HERO_SELECTION then	return; end
    local picks = {"npc_dota_hero_sven","npc_dota_hero_lina","npc_dota_hero_tidehunter","npc_dota_hero_sand_king","npc_dota_hero_dazzle"};
	local friendTeam = GetTeam();
	local IDs = GetTeamPlayers(friendTeam);

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