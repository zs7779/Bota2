utils={};

function utils.nextTower(nTeam, towerList)
	-- given a team and a list of towers,
	-- return the first tower that is alive.
	for i, tower in pairs(towerList) do
		local T = GetTower(nTeam, tower);
		if T:IsAlive() then return T; end
	end
    return nil;
end

return utils;