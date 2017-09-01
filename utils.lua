utils={};

function utils.nextTower(nTeam, towerList)
	-- given a team and a list of towers,
	-- return the first tower that is alive.
	for i, tower in pairs(towerList) do
		local T = GetTower(nTeam, tower);
		if T ~= nil then return T; end
	end
    return nil;
end

function utils.locationToLocationDistance(vloc1, vloc2)
	if vloc1 == nil or vloc2 == nil then return nil; end
	return math.sqrt(math.pow(vloc1.x-vloc2.x,2)+math.pow(vloc1.y-vloc2.y,2));
end

function utils.tableMax(ids, numTable)
	local max = 0;
	local imax = 0;
	for _, id in pairs(ids) do
		if numTable[id] > max then
			max = numTable[id];
			imax = id;
		end
	end
	return imax, max;
end

return utils;