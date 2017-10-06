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
	if(self.LastSpeaktime==nil)
	then
		self.LastSpeaktime=0;
	end
	if(GameTime()-self.LastSpeaktime>0.1)
	then
		self:ActionImmediate_Chat(message,true);
		self.LastSpeaktime=GameTime();
	end
end

---------------------------------------------------------------------

function CanCastSpellOnTarget(spell, target)
	return spell:IsFullyCastable() and 
	target:CanBeSeen() and target:IsAlive() and
	not target:IsInvulnerable() and 
	(not target:IsMagicImmune() or 
	utils.CheckFlag(spell:GetTargetFlags(), ABILITY_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES) or
	utils.CheckFlag(spell:GetTargetFlags(), ABILITY_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES));
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

-- And by AoE, I mean AoE, not your half ass defination
function CDOTA_Bot_Script:UseAoESpell(spell, baseLocation, range, radius, delay, maxHealth, spellType, units)
	assert(spell~=nil and baseLocation.x~=nil and baseLocation.y~=nil and range>=0 and radius>=0 and delay>=0 and maxHealth>=0 and spellType >=0 and #units>=0)
	local AoELocation = {};
	AoELocation.count = 0;
	AoELocation.targetloc = nil;
	-- **If FindAoELocation cannot be trusted, use this V, but may need to reconsider search range = castRange+radius or castRange
	-- if #units == 1 then
	-- 	local unit = units[1];
	-- 	AoELocation.count = 1;
	-- 	AoELocation.targetloc = unit:PredictLocation(delay);
	-- 	if maxHealth > 0 and unit:GetHealth() <= unit:GetActualIncomingDamage(maxHealth, spellType)then
	-- 		self:DebugTalk("AoE 精致");
	-- 		return AoELocation;
	-- 	elseif maxHealth == 0
	-- 		self:DebugTalk("AoE 干他");
	-- 		return AoELocation;
	-- 	end
	-- 	return AoELocation;
	-- end

	-- ***Sometimes you think about if it is worth it to put a loop here.
	for _, unit in ipairs(units) do
		if not unit:IsMyFriend() and spellType > 0 then
			maxHealth = unit:GetActualIncomingDamage(maxHealth, spellType);
		end
		if CanCastSpellOnTarget(spell, unit) and
			unit:GetHealth() <= maxHealth then
			if utils.CheckFlag(spell:GetBehavior(), ABILITY_BEHAVIOR_AOE) then
				AoELocation = self:FindAoELocation( true, unit:IsHero(), baseLocation, range, radius, delay, maxHealth);
			elseif utils.CheckFlag(spell:GetBehavior(), ABILITY_BEHAVIOR_DIRECTIONAL) then
				AoELocation = self:FindAoEVector(true, unit:IsHero(), false, baseLocation, range, radius, delay, maxHealth);
			end

			if AoELocation.count > 0 then
				if unit:IsHero() then
					if maxHealth > 0 then
						self:DebugTalk(spell:GetName() .. "AoE 精致");
					else
						self:DebugTalk(spell:GetName() .. "AoE 干他");
					end
				else
					if maxHealth > 0 then
						self:DebugTalk(spell:GetName() .. "AoE 收线");
					else
						self:DebugTalk(spell:GetName() .. "AoE 推线");
					end
				end
				return AoELocation;
			end
		end
	end
	return AoELocation;
end

function CDOTA_Bot_Script:UseAoEHarass(spell, baseLocation, range, radius, delay, maxHealth)
	assert(spell~=nil and baseLocation.x~=nil and baseLocation.y~=nil and range>=0 and radius>=0 and delay>=0 and maxHealth>=0)
	local AoELocation = {};
	AoELocation.count = 0;
	AoELocation.targetloc = nil;

	if utils.CheckFlag(spell:GetBehavior(), ABILITY_BEHAVIOR_AOE) then
		local AoEHero = self:FindAoELocation( true, true, baseLocation, range, radius, delay, 0);
		local AoECreep = self:FindAoELocation( true, false, baseLocation, range, radius, delay, maxHealth);
		if AoEHero.count > 0 and AoECreep.count > 0 and 
		    utils.locationToLocationDistance(AoEHero.targetloc,AoECreep.targetloc) < radius then 
			self:DebugTalk(spell:GetName() .. "收兵+压人");
			AoELocation.count =  AoEHero.count + AoECreep.count;
			AoELocation.targetloc = midPoint({AoEHero.targetloc,AoECreep.targetloc}); 
		end
	elseif utils.CheckFlag(spell:GetBehavior(), ABILITY_BEHAVIOR_DIRECTIONAL) then
		local AoECreep = self:FindAoEVector( true, false, true, self:GetLocation(), range, radius, delay, maxHealth);
		if AoECreep.count > 0 then 
		    self:DebugTalk(spell:GetName() .. "收兵+压人");
		    AoELocation = AoECreep;
		end
	end
	return AoELocation;
end

function CDOTA_Bot_Script:UseUnitSpell(spell, range, radius, maxHealth, spellType, units)
	assert(spell~=nil and radius>=0 and maxHealth>=0 and spellType >=0 and #units>=0)
	if maxHealth == 0 then maxHealth = math.huge; end
	for _, unit in ipairs(units) do
		if not unit:IsMyFriend() then
			maxHealth = unit:GetActualIncomingDamage(maxHealth, spellType);
		end
		if target ~= nil and CanCastSpellOnTarget(spell, target) and 
		 	GetUnitToUnitDistance(I, target) < range and
			unit:GetHealth() <= maxHealth then
			if unit:IsHero() then
				if maxHealth > 0 then
					self:DebugTalk(spell:GetName() .. "精致");
				else --*** maybe we don't consider harassing right now.
					self:DebugTalk(spell:GetName() .. "干他");
				end
			else
				self:DebugTalk(spell:GetName() .. "补刀");
			end
			return unit;
		end
	end
	return nil;
end

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
	local spells = {};
	local talents = {};
	for i = 0,23 do
		local ability = self:GetAbilityInSlot(i);
		if ability ~= nil then
			if ability:IsTalent() then
				talents[#talents+1] = ability:GetName();
			else
				spells[#spells+1] = ability:GetName();
			end
		end
	end
	return {spells, talents};
end

function CDOTA_Bot_Script:GetComboMana()
	local spells = self:GetAbilities()[1];
	local manaCost = 0;
	for i = 1, #spells do
		local spell = self:GetAbilityByName(spells[i]);
		if not spell:IsPassive() and spell:IsFullyCastable() and spell:GetAbilityDamage()>0 then
			manaCost = manaCost + spell:GetManaCost();
		end
	end
	return manaCost;
end
function CDOTA_Bot_Script:GetComboDamageToTarget(target)
	-- ***How do you consider duration? and toggle?
	local spells = self:GetAbilities()[1];
	local totalDamage = 0;
	for i = 1, #spells do
		local spell = self:GetAbilityByName(spells[i]);
		if not spell:IsPassive() and spell:IsFullyCastable() and spell:GetAbilityDamage()>0 then
			totalDamage = totalDamage + target:GetActualIncomingDamage(spell:GetAbilityDamage(),spell:GetDamageType());
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
	return self:IsDisabled() or self:IsRooted();
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

function CDOTA_Bot_Script:CanCast()
	return self:CanAct() and not self:IsSilenced() and not self:IsHexed();
end
function CDOTA_Bot_Script:CanHit()
	return self:CanAct() and not self:IsDisarmed();
end

function CDOTA_Bot_Script:PredictLocation(fTime)
	local stability = self:GetMovementDirectionStability();
	-- local lastSeen = GetHeroLastSeenInfo(friendID);
	return stability*self:GetExtrapolatedLocation(fTime) + (1.0-stability)*self:GetLocation();
end


function weakestSort(units)
	table.sort(units, function(a,b) return a:GetHealth()<b:GetHealth() end);
	return units;
end
function weakestUnit(units, needDisable)
	for _, unit in ipairs(weakestSort(units)) do
		if unit:IsTrueHero() and (not needDisable or not unit:IsDisabled() and not unit:IsSilenced()) then
			return unit;
		end
	end
	return nil;
end

function strongestSort(units)
	table.sort(units, function(a,b) return a:GetOffensivePower()>b:GetOffensivePower() end);
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
	table.sort(units, function(a,b) return a:GetStunDuration(false)>b:GetStunDuration(false) end);
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
	table.sort(units, function(a,b) return a:GetNetWorth()>b:GetNetWorth() end);
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
	if vlocs == nil or #vlocs == 0 then return Vector(0,0); end
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
