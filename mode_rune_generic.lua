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

function NearestRune(I,runes)
	local nearest = nil;
	local dist = 100000;
	for _, rune in pairs(runes) do
		local tmp = GetUnitToLocationDistance(I,GetRuneSpawnLocation(rune));
		if tmp < dist then
			dist = tmp;
			nearest = rune;
		end
	end
	return nearest;
end

function DibsHaveBeenCalled()
	local I = GetBot();
	local desire = 0;
	if I:GetActiveMode() == BOT_MODE_RUNE then
		desire = I:GetActiveModeDesire();
	end

	local friends = GetUnitList(UNIT_LIST_ALLIED_HEROES);
	for _, friend in pairs(friends) do
		if friend:GetActiveMode() == BOT_MODE_RUNE and friend:GetActiveModeDesire() > desire then
			local runes = PendingRunes(safeRunes[GetTeam()]);
		    if #runes == 0 then return false; end
		    local runeLoc = GetRuneSpawnLocation(NearestRune(I,runes));
		    if GetUnitToLocationDistance(friend,runeLoc)+100 < GetUnitToLocationDistance(I,runeLoc) then
		    	return true;
		    end
		end
	end
	return false;
end

function GetDesire()
	local I = GetBot();
	local position = I:GetPlayerPosition();
	local hasBottle = (I:FindItemSlot( "item_bottle" ) ~= -1);

	if not I:IsTrueHero() or I:IsUsingAbility() or I:IsChanneling() then return 0; end
    if DibsHaveBeenCalled() then return 0; end

    local rune = I:OnRune(safeRunes[GetTeam()]);
	if rune ~= nil then 
		return 1.00;
	end

	local friends = I:GetNearbyHeroes(1200,false,BOT_MODE_NONE);
	local enemys = I:GetNearbyHeroes(1200,true,BOT_MODE_NONE);

	if DotaTime()<=0.5 and (position == 1 or position == 2) and #friends>=#enemys then
		return 0.4;
	end

	if #enemys > #friends then return 0.0; end
    
    local runes = PendingRunes(safeRunes[GetTeam()]);
    if #runes == 0 then return 0; end

	if NearestRune(I,runes) < 2500 and position ~= 1 and position ~= 2 or NearestRune(I,runes) < 1200 then
		return 0.25;
	end

	if hasBottle then
		if I:IsLow() then
			return 0.35;
		else
			return 0.25;
		end
	end
	return 0;
end

function Think()
	local I = GetBot();
	local position = I:GetPlayerPosition();

	local rune = I:OnRune(safeRunes[GetTeam()]);
	if rune ~= nil then 
		I:Action_PickUpRune(rune); 
		return;
	end

	-- Find first rune before time 0:00
	if DotaTime()<=0.5 and position < 3 then
		I:Action_MoveToLocation(GetRuneSpawnLocation(safeRunes[GetTeam()][position]));
		return;
	end

	-- Check nearest rune
	local runes = PendingRunes(safeRunes[GetTeam()]);
	if #runes ~= 0 then
		I:Action_MoveToLocation(GetRuneSpawnLocation(NearestRune(I,runes)));
		return;
	end
end