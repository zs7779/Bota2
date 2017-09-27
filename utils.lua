_G._savedEnv = getfenv()
module("utils", package.seeall)
-- 

-- gxc's code
-- created by date: 2017/03/16
-- nBehavior = hAbility:GetTargetTeam, GetTargetType, GetTargetFlags or GetBehavior function returns
-- nFlag = Ability Target Teams, Ability Target Types, Ability Target Flags or Ability Behavior Bitfields constant
-- ***behaviors and flags can be combined.. thats why they are all 2^x.. you know.. binary code 000111011
function CheckFlag( nBehavior, nFlag )
	if ( nFlag == 0 ) then
		if ( nBehavior == 0 ) then return true; else return false; end
	end
	return ( (nBehavior / nFlag) % 2 ) >= 1;
end


-- Ranked Matchmaking AI
local debug_mode = true;
function CDOTA_Bot_Script:DebugTalk(message)
	-- local npcBot=GetBot();
	if(I.LastSpeaktime==nil)
	then
		I.LastSpeaktime=0;
	end
	if(GameTime()-I.LastSpeaktime>0.1)
	then
		I:ActionImmediate_Chat(message,true);
		I.LastSpeaktime=GameTime();
	end
end

---------------------------------------------------------------------

function CDOTA_Bot_Script:GetFarHeroes(nRadius, bEnemy, nMode)
	if nRadius == 0 then nRadius = math.huge; end
	local team = (self:IsMyFriend() ~= bEnemy) and UNIT_LIST_ALLIED_HEROES or UNIT_LIST_ENEMY_HEROES;
	local heroes = {};
	for _, hero in ipairs(GetUnitList(team)) do
		if GetUnitToUnitDistance(self, hero) <= nRadius and not (bEnemy and hero:GetActiveMode() ~= nMode) then
			table.insert(heroes, hero);
		end
	end
	return heroes;
end

function  CDOTA_Bot_Script:IsMyFriend()
	return GetTeam() == self:GetTeam();
end

function CDOTA_Bot_Script:GetPlayerPosition()
	for position = 1,5 do
		if GetTeamMember(position) == self then return position; end
	end
	return nil;
end

function CDOTA_Bot_Script:GetAbilities()
	local abilities = {};
	local talents = {};
	for i = 0,23 do
		local ability = self:GetAbilityInSlot(i);
		if ability ~= nil then
			if ability:IsTalent() then
				talents[#talents+1] = ability:GetName()
			else
				abilities[#abilities+1] = ability:GetName()
			end
		end
	end
	return abilities, talents;
end

function CDOTA_Bot_Script:GetComboMana()
	local abilities, talents = self:GetAbilities()
	local manaCost = 0;
	for i = 1, #abilities do
		local ability = self:GetAbilityByName(abilities[i]);
		if not ability:IsPassive() and ability:IsFullyCastable() and ability:GetAbilityDamage()>0 then
			manaCost = manaCost + ability:GetManaCost();
		end
	end
	return manaCost;
end
function CDOTA_Bot_Script:GetComboDamageToTarget(target)
	-- ***How do you consider duration? and toggle?
	local abilities, talents = self:GetAbilities()
	local totalDamage = 0;
	for i = 1, #abilities do
		local ability = self:GetAbilityByName(abilities[i]);
		if not ability:IsPassive() and ability:IsFullyCastable() and ability:GetAbilityDamage()>0 then
			totalDamage = totalDamage + target:GetActualIncomingDamage(ability:GetAbilityDamage(),ability:GetDamageType());
		end
	end
	return totalDamage;
end

function CDOTA_Bot_Script:EstimateDamageToTarget(target)
	local estimatedDamage = 0;
	if self:CanCast() then
		estimatedDamage = estimatedDamage + self:GetComboDamageToTarget(target);
	end
	if self:CanHit() then
		estimatedDamage = estimatedDamage + 
		target:GetActualIncomingDamage(self:GetAttackDamage(),DAMAGE_TYPE_PHYSICAL) *
		(1.0 - target:GetEvasion()) *
		(self:GetStunDuration(true) + 0.5*self:GetSlowDuration(true) + 2 + target:TimeBeforeRescue());
	end
end

function CDOTA_Bot_Script:TimeBeforeRescue()
	local myID = self:GetPlayerID();
	local minTime = math.huge;

	for _, friend in ipairs(self:GetFarHeroes(0, false, BOT_MODE_NONE)) do
		local friendID = friend:GetPlayerID();
		if friendID ~= myID and IsHeroAlive(friendID) then
			local thisTime = math.huge;
			if friend:CanBeSeen() and not friend:IsLow() then
				thisTime = GetUnitToUnitDistance(self, friend)/friend:GetCurrentMovementSpeed();
			else
				local lastSeen = GetHeroLastSeenInfo(friendID);
				thisTime = GetUnitToLocationDistance(self, lastSeen.location)/400 - lastSeen.time;
			end
			if thisTime < minTime then
				minTime = thisTime;
			end
		end
	end
	return minTime;
end


function CDOTA_Bot_Script:LowHealth()
	return self:GetHealth()/self:GetMaxHealth() < 0.4;
end
function CDOTA_Bot_Script:noMana()
	return self:GetMana()/self:GetMaxMana() < 0.2 or self:GetComboMana() == 0;
end
function CDOTA_Bot_Script:LowMana()
	return self:noMana() or self:GetMana() < self:GetComboMana();
end
function CDOTA_Bot_Script:IsLow()
	return self:LowHealth() and self:NoMana();
end

function CDOTA_Bot_Script:OnRune(runes)
	for i = 1, #runes do
		local rune = runes[i];
		if GetRuneStatus(rune) == RUNE_STATUS_AVAILABLE and GetUnitToLocationDistance(self,GetRuneSpawnLocation(rune)) < 100 then
			return rune;
		end
	end
	return nil;
end

function CDOTA_Bot_Script:IsDisabled()
	return self:IsStunned() or self:IsHexed() or self:IsNightmared();
end

function CDOTA_Bot_Script:IsImmobile()
	return self:IsDisabled or self:IsRooted();
end

function CDOTA_Bot_Script:IsImmune()
	return self:IsMagicImmune() or self:IsInvulnerable();
end

function CDOTA_Bot_Script:IsTrueHero()
	return self:IsAlive() and not self:IsIllusion();
end

function CDOTA_Bot_Script:CanAct()
	return self:IsTrueHero() and not self:IsUsingAbility() and not self:IsChanneling() and not self:IsDisabled();
end

function CDOTA_Bot_Script:CatCast()
	return self:CanAct() and not self:IsSilenced() and not self:IsHexed();
end
function CDOTA_Bot_Script:CanHit()
	return self:CanAct and not self:IsDisarmed();
end

function CDOTA_Bot_Script:PredictLocation(fTime)
	local stability = self:GetMovementDirectionStability();
	-- local lastSeen = GetHeroLastSeenInfo(friendID);
	return stability*self:GetExtrapolatedLocation(fTime) + (1.0-stability)*self:GetLocation();
end


function CDOTA_Bot_Script:FindAoEVector(bEnemies, bHeroes, bHarass, vBaseLocation, nMaxDistanceFromBase, nWidth, fTimeInFuture, nMaxHealth )
	local AoEVector = {};
	AoEVector.count = 0;
	AoEVector.baseloc = vBaseLocation;
	AoEVector.targetloc = nil;
	local maxHealth = (nMaxHealth == 0) and math.huge or nMaxHealth;

	nMaxDistanceFromBase = math.min(1550, nMaxDistanceFromBase);
	local heroes = self:GetNearbyHeroes(nMaxDistanceFromBase, bEnemies, BOT_MODE_NONE);
	local units = bHeroes and heroes or self:GetNearbyCreeps(nMaxDistanceFromBase, bEnemies);
	local targetUnits = bHarass and heroes or units;

	local maxCount = 0;
	local targets = {};
	for _, targetUnit in ipairs(targetUnits) do
	    local vtargetLoc = targetUnit:PredictLocation(fTimeInFuture);
		local vector = vtargetLoc - vBaseLocation;
		local vEnd = vBaseLocation + vector/utils.locationToLocationDistance(vBaseLocation, vtargetLoc)*nMaxDistanceFromBase;
		
		local thisCount = 0;
		local thisTargets = {};
		for _, unit in ipairs(units) do
			local unitLoc = unit:PredictLocation(fTimeInFuture);
			local distToLine = PointToLineDistance(vBaseLocation, vEnd, unitLoc);
			if distToLine.within and distToLine.distance < nWidth and unit:GetHealth() <= maxHealth then
				thisCount = thisCount + 1;
				thisTargets[#thisTargets+1] = unitLoc;
			end
		end
		if thisCount > maxCount then
			maxCount = thisCount;
			targets = thisTargets;
		end
	end
	
	AoEVector.count = maxCount;
	AoEVector.baseloc = vBaseLocation;
	AoEVector.targetloc = utils.midPoint(targets);
	-- There is no guarantee this midPoint actually covers all targets...
	-- Drawing tells me it is guaranteed, but I have trouble proving it mathematically..
	return AoEVector;
end

function weakestSort(units)
	table.sort(units, function(a,b) return a:GetHealth()<b:GetHealth());
	return units;
end
function weakestUnit(units, needDisable)
	for _, unit in ipairs(weakestSort(units) do
		if unit:IsTrueHero() and (not needDisable or not unit:IsDisabled() and not unit:IsSilenced()) then
			return unit;
		end
	end
	return nil;
end

function strongestSort(units)
	table.sort(units, function(a,b) return a:GetOffensivePower()>b:GetOffensivePower());
	return units;
end
function strongestUnit(units, needDisable)
	for _, unit in ipairs(strongestSort(units)) do
		if unit:IsTrueHero() and (not needDisable or not unit:IsDisabled()) then
			return unit;
		end
	end
	return nil;
end

function disablerSort(units)
	table.sort(units, function(a,b) return a:GetStunDuration(false)>b:GetStunDuration(false));
	return units;
end
function strongestDisabler(units, needDisable)
	for _, unit in ipairs(disablerSort(units)) do
		local thisTime = unit:GetStunDuration(false);
		if unit:IsTrueHero() and (not needDisable or not unit:IsSilenced() and not unit:IsDisabled()) then
			return unit;
		end
	end
	return nil;
end

function richestSort(units)
	table.sort(units, function(a,b) return a:GetNetWorth()>b:GetNetWorth());
	return units;
end

function nextTower(nTeam, towerList)
	-- given a team and a list of towers,
	-- return the first tower that is alive.
	for i = 1, #towerList do
		local T = GetTower(nTeam, towerList[i]);
		if T ~= nil then return T; end
	end
    return nil;
end

function locationToLocationDistance(vloc1, vloc2)
	if vloc1 == nil or vloc2 == nil then return nil; end
	return math.sqrt(math.pow(vloc1.x-vloc2.x,2)+math.pow(vloc1.y-vloc2.y,2));
end

function midPoint(vlocs)
	-- vlocs need to be a strict array of Vectors, with no gap in between
	if vlocs == nil or #vlocs == 0 then return nil; end
	local mid = Vector(0,0);
	for _, v in pairs(vlocs) do
		mid.x = mid.x + v.x;
		mid.y = mid.y + v.y;
	end
	return mid;
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
