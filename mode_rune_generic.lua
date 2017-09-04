require(GetScriptDirectory() ..  "/utils")

local safeRunes={};
safeRunes[TEAM_RADIANT]={
    RUNE_BOUNTY_1,
    RUNE_BOUNTY_2,
    RUNE_POWERUP_1,
    RUNE_POWERUP_2
	};
safeRunes[TEAM_DIRE]={
    RUNE_BOUNTY_3,
    RUNE_BOUNTY_4,
    RUNE_POWERUP_1,
    RUNE_POWERUP_2
};

function PendingRunes(runes)
	local pending={};
	for _,rune in pairs(runes) do
		if GetRuneStatus(rune) ~= RUNE_STATUS_MISSING then
			table.insert(pending,rune);
		end
	end
	return pending;
end

function NearestRune(runes)
	local npcBot = GetBot();
	local nearest = nil;
	local dist = math.huge;
	for _, rune in pairs(runes) do
		local tmp = GetUnitToLocationDistance(npcBot,GetRuneSpawnLocation(rune));
		if tmp < dist then
			dist = tmp;
			nearest = rune;
		end
	end
	return nearest;
end

function DibsHaveBeenCalled()
	local npcBot = GetBot();
	local desire = 0;
	if npcBot:GetActiveMode() == BOT_MODE_RUNE then
		desire = npcBot:GetActiveModeDesire();
	end

	local friends = GetUnitList(UNIT_LIST_ALLIED_HEROES);
	for _, friend in pairs(friends) do
		if friend:GetActiveMode() == BOT_MODE_RUNE and friend:GetActiveModeDesire() > desire then
			local runes = PendingRunes(safeRunes[GetTeam()]);
		    if #runes == 0 then return false; end
		    local runeLoc = GetRuneSpawnLocation(NearestRune(runes));
		    if GetUnitToLocationDistance(friend,runeLoc)+100 < GetUnitToLocationDistance(npcBot,runeLoc) then
		    	return true;
		    end
		end
	end
	return false;
end

function GetDesire()
	local npcBot = GetBot();
	local position = npcBot:GetPlayerPosition();
	local hasBottle = (npcBot:FindItemSlot( "item_bottle" ) ~= -1);

	if (not npcBot:IsAlive()) or npcBot:IsUsingAbility() or npcBot:IsChanneling() then return 0; end
    if DibsHaveBeenCalled() then return 0; end

	local friends = npcBot:GetNearbyHeroes(1200,false,BOT_MODE_NONE);
	local enemys = npcBot:GetNearbyHeroes(1200,true,BOT_MODE_NONE);

	if DotaTime()>=-75 and DotaTime()<=0.5 and (position == 1 or position == 2) and #friends>=#enemys then
		return 0.8;
	end

	if #enemys > 1 then return 0.0; end
    
    local runes = PendingRunes(safeRunes[GetTeam()]);
    if #runes == 0 then return 0; end

	if NearestRune(runes) < 2500 then
		return 0.55;
	end

	if hasBottle then
		if npcBot:IsLow() then
			return 0.65;
		else
			return 0.55;
		end
	end
	return 0;
end

function Think()
	local npcBot = GetBot();
	local position = npcBot:GetPlayerPosition();

	local rune = npcBot:OnRune(safeRunes[GetTeam()]);
	if rune ~= nil then 
		npcBot:Action_PickUpRune(rune); 
		return;
	end

	-- Find first rune before time 0:00
	if DotaTime()>=-75 and DotaTime()<=0.5 and position < 3 then
		npcBot:Action_MoveToLocation(GetRuneSpawnLocation(safeRunes[GetTeam()][position]));
	end

	-- Check nearest rune
	local runes = PendingRunes(safeRunes[GetTeam()]);
	if #runes ~= 0 then
		npcBot:Action_MoveToLocation(GetRuneSpawnLocation(NearestRune(runes)));
	end

	return;
end