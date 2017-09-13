_G._savedEnv = getfenv()
module("utils", package.seeall)
-- 

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
				table.insert(talents, ability:GetName());
			else
				table.insert(abilities, ability:GetName());
			end
		end
	end
	return abilities, talents;
end

function CDOTA_Bot_Script:GetComboMana()
	local abilities, talents = self:GetAbilities()
	local manaCost = 0;
	for _, ability in pairs(abilities) do
		if not ability:IsPassive() and ability:IsFullyCastable() and ability:GetAbilityDamage()>0 then
			manaCOst = manaCost + ability:GetManaCost();
		end
	end
	return manaCost;
end
function CDOTA_Bot_Script:GetComboDamage()
	local abilities, talents = self:GetAbilities()
	local totalDamage = 0;
	for _, ability in pairs(abilities) do
		if not ability:IsPassive() and ability:IsFullyCastable() and ability:GetAbilityDamage()>0 then
			totalDamage = totalDamage + ability:GetAbilityDamage();
		end
	end
	return totalDamage;
end

function CDOTA_Bot_Script:LowHealth()
	return self:GetHealth()/self:GetMaxHealth() < 0.6;
end
function CDOTA_Bot_Script:LowMana()
	local mana = self:GetMana()
	return mana/self:GetMaxMana() < 0.4 or mana < self:GetComboMana();
end

function CDOTA_Bot_Script:IsLow()
	return self:LowHealth() or self:LowMana();
end

function CDOTA_Bot_Script:OnRune(runes)
	for _, rune in pairs(runes) do
		if GetRuneStatus(rune) == RUNE_STATUS_AVAILABLE and GetUnitToLocationDistance(self,GetRuneSpawnLocation(rune)) < 100 then
			return rune;
		end
	end
	return nil;
end

function CDOTA_Bot_Script:IsDisabled()
	if self:IsRooted() or self:IsStunned() or self:IsHexed() or self:IsNightmared() then
		return true;
	end
	return false;
end

function CDOTA_Bot_Script:IsImmune()
	if self:IsMagicImmune() or self:IsInvulnerable() then
		return true;
	end
	return false;
end

function weakestUnit(units, disable)
	local health = math.huge;
	local weakest = nil;
	for _, unit in pairs(units) do
		local thisHealth = unit:GetHealth();
		if unit:IsAlive() and thisHealth < health and not (disable and not unit:IsDisabled()) then
			weakest = unit;
			health = thisHealth;
		end
	end
	return weakest;
end

function strongestUnit(units, disable)
	local power = 0;
	local strongest = nil;
	for _, unit in pairs(units) do
		local thisPower = unit:GetOffensivePower();
		if unit:IsAlive() and thisPower > power then
			strongest = unit;
			power = thisPower;
		end
	end
	return strongest;
end

function strongestDisabler(units, disable)
	local stunTime = 0;
	local strongest = nil;
	for _, unit in pairs(units) do
		local thisTime = unit:GetStunDuration();
		if unit:IsAlive() and thisTime > stunTime then
			strongest = unit;
			stunTime = thisTime;
		end
	end
	return strongest;
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

function middleLocation(vloc1, vloc2)
	if vloc1 == nil or vloc2 == nil then return nil; end
	return Vector((vloc1.x+vloc2.x)/2, (vloc1.y+vloc2.y)/2);
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