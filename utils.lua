_G._savedEnv = getfenv()
module("utils", package.seeall)
-- 

function CDOTA_Bot_Script:GetPlayerPosition()
	for position = 1,5 do
		if GetTeamMember(position) == self then return position; end
	end
	return nil;
end

function CDOTA_Bot_Script:IsLow()
	if self:GetHealth()/self:GetMaxHealth() < 0.6 or self:GetMana()/self:GetMaxMana() < 0.4 then
		return true;
	else
		return false;
	end
end

function CDOTA_Bot_Script:OnRune(runes)
	for _, rune in pairs(runes) do
		if GetRuneStatus(rune) == RUNE_STATUS_AVAILABLE and GetUnitToLocationDistance(self,GetRuneSpawnLocation(rune)) < 100 then
			return rune;
		end
	end
	return nil;
end

function nextTower(nTeam, towerList)
	-- given a team and a list of towers,
	-- return the first tower that is alive.
	for _, tower in pairs(towerList) do
		local T = GetTower(nTeam, tower);
		if T ~= nil then return T; end
	end
    return nil;
end

function locationToLocationDistance(vloc1, vloc2)
	if vloc1 == nil or vloc2 == nil then return nil; end
	return math.sqrt(math.pow(vloc1.x-vloc2.x,2)+math.pow(vloc1.y-vloc2.y,2));
end

function tableMax(ids, numTable)
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

-- 
for k,v in pairs( utils ) do _G._savedEnv[k] = v end