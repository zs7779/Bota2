function GetComboMana(abilities)
	local manaCost = 0;
	for _, ability in pairs(abilities) do
		if not ability:IsPassive() and ability:IsFullyCastable() and ability:GetAbilityDamage()>0 then
			manaCOst = manaCost + ability:GetManaCost();
		end
	end
	return manaCost;
end

function GetComboDamage(abilities)
	local totalDamage = 0;
	for _, ability in pairs(abilities) do
		if not ability:IsPassive() and ability:IsFullyCastable() and ability:GetAbilityDamage()>0 then
			totalDamage = totalDamage + ability:GetAbilityDamage();
		end
	end
	return totalDamage;
end

function CanCastAbilityOnTarget(ability, target)
	return ability:IsFullyCastable() and 
	target:CanBeSeen() and 
	not target:IsInvulnerable() and 
	(not target:IsMagicImmune() or 
	ability:GetTargetFlags() == ABILITY_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES);
end

-- Generic logic:
-- Use nuke when 1. attack 2. enemy health low
-- Use stun when 1. channeling 2. key hero
-- use aoe when 1. attack 2. defend 3. push

function ConsiderAoEDamage(I, ability)
	if not ability:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end

	local castRange = ability:GetCastRange();
	local radius = ability:GetAOERadius();
	local castPoint = ability:GetCastPoint();
	local damage = ability:GetAbilityDamage();
	
	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);
	local creeps = I:GetNearbyCreeps(castRange,true);

	-- If there exist enemy you can ks, go
	-- ***If use AoELocation, how to consider if enemy use BKB?
	-- ***If lowHP enemy location -> aoe location < radius
	for _, enemy in pairs(enemys) do
		local actualDamage = enemy:GetActualIncomingDamage(damage, DAMAGE_TYPE_MAGICAL);
		if CanCastAbilityOnTarget(ability, enemy) and
			enemy:GetHealth() <= actualDamage then
			local AoELocation = I:FindAoELocation( true, true, I:GetLocation(), castRange, radius, castPoint, actualDamage );
			if AoELocation.count >= 1 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
		end
	end
	
	-- Laning last hit
	-- If enough mana and low health, try landing any last hit
	if I:GetActiveMode() == BOT_MODE_LANING then
		if not I:LowMana() and I:LowHealth() then
			local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, castPoint, damage );
			if AoELocation.count >= 1 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
		elseif not I:LowMana() then 
		
		-- If can last hit + harrase enemy hero, go
		-- ***If aoe location -> hero location < radius or in same vector.. or something like this
			local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, castPoint, damage );
			if AoELocation.count >= 2 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
		end
	end

	-- If farming, use aoe to get multiple last hits
	if I:GetActiveMode() == BOT_MODE_FARM then
		local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, castPoint, damage );
		if AoELocation.count >= 2 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
	end

	-- If pushing/defending, clear wave
	if I:GetActiveMode() >= BOT_MODE_PUSH_TOWER_TOP and
		I:GetActiveMode() <= BOT_MODE_DEFEND_TOWER_BOT then
		local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, castPoint, 0 );
		if AoELocation.count >= 2 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
	end

	-- Add if not BOT_MODE_RETREAT, go ahead if can hit multiple heroes
	if I:GetActiveMode() ~= BOT_MODE_RETREAT
		local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, castPoint, 0 );
		if AoELocation.count >= 3 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
	end
	
	-- If attacking, just go
	if I:GetActiveMode() == BOT_MODE_ROAM or
		 I:GetActiveMode() == BOT_MODE_TEAM_ROAM or
		 I:GetActiveMode() == BOT_MODE_DEFEND_ALLY or
		 I:GetActiveMode() == BOT_MODE_ATTACK then
		 local target = I:GetTarget();
		 if target ~= nil and CanCastAbilityOnTarget(ability, target) then
		 	return BOT_ACTION_DESIRE_MODERATE, target:GetExtrapolatedLocation(castPoint);
		 end
	end

	return BOT_ACTION_DESIRE_NONE, nil;
end

function ConsiderUnitStun(I, ability)
	if not ability:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end

	local castRange = ability:GetCastRange();
	local radius = ability:GetAOERadius();
	local castPoint = 0; -- cast point should not apply... right?
	local damage = ability:GetAbilityDamage();
	
	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);
	local nearbyEnemys = I:GetNearbyHeroes(I:GetCurrentMovementSpeed()+castRange,true,BOT_MODE_NONE);
	
	-- Interrupt channeling within 1s walking
	for _, enemy in pairs(nearbyEnemys) do
		if CanCastAbilityOnTarget(ability, enemy) and
			enemy:IsChanneling() then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end

	-- If fighting, stun lowHP/strongest carry/best disabler
	if I:GetActiveMode() ~= BOT_MODE_RETREAT
		local disabler = utils.strongestDisabler(enemys, false);
		if disabler ~= nil and CanCastAbilityOnTarget(ability, disabler) and 
			not disabler:IsDisabled() then
			return BOT_ACTION_DESIRE_HIGH, disabler;
		end
		local weakest = utils.weakestUnit(enemys, false);
		if weakest ~= nil and CanCastAbilityOnTarget(ability, weakest) and 
			not weakest:IsDisabled() then
			return BOT_ACTION_DESIRE_HIGH, weakest;
		end
		local strongest = utils.strongestUnit(enemys, false);
		if strongest ~= nil and CanCastAbilityOnTarget(ability, strongest) and 
			not strongest:IsDisabled() then
			return BOT_ACTION_DESIRE_HIGH, strongest;
		end
	end

	-- If retreating, stun closest enemy within immediate cast range
	if I:GetActiveMode() == BOT_MODE_RETREAT
		for _, enemy in pairs(nearbyEnemys) do
			if CanCastAbilityOnTarget(ability, enemy) and
				not enemy:IsDisabled() then
				return BOT_ACTION_DESIRE_MODERATE, target;
			end
		end
	end

	-- If have target, go
	if I:GetActiveMode() == BOT_MODE_ROAM or
		 I:GetActiveMode() == BOT_MODE_TEAM_ROAM or
		 I:GetActiveMode() == BOT_MODE_DEFEND_ALLY or
		 I:GetActiveMode() == BOT_MODE_ATTACK then
		 local target = I:GetTarget();
		 if target ~= nil and CanCastAbilityOnTarget(ability, target) and
		 	not target:IsDisabled() then
		 	return BOT_ACTION_DESIRE_MODERATE, target;
		 end
	end

	return BOT_ACTION_DESIRE_NONE, nil;
end

function ConsiderUnitDamage(I, ability)
	if not ability:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end

	local castRange = ability:GetCastRange();
	local radius = ability:GetAOERadius();
	local castPoint = 0; -- cast point should not apply... right?
	local damage = ability:GetAbilityDamage();
	
	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);
	local nearbyEnemys = I:GetNearbyHeroes(I:GetCurrentMovementSpeed()+castRange,true,BOT_MODE_NONE);
	
	-- Kill secure
	for _, enemy in pairs(enemys) do
		local actualDamage = enemy:GetActualIncomingDamage(damage, DAMAGE_TYPE_MAGICAL);
		if CanCastAbilityOnTarget(ability, enemy) and
			enemy:GetHealth() <= actualDamage then
	
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end

	-- If have target, go
	if I:GetActiveMode() == BOT_MODE_ROAM or
		 I:GetActiveMode() == BOT_MODE_TEAM_ROAM or
		 I:GetActiveMode() == BOT_MODE_DEFEND_ALLY or
		 I:GetActiveMode() == BOT_MODE_ATTACK then
		 local target = I:GetTarget();
		 if target ~= nil and CanCastAbilityOnTarget(ability, target) then
		 	return BOT_ACTION_DESIRE_MODERATE, target;
		 end
	end

	return BOT_ACTION_DESIRE_NONE, nil;
end



BotsInit = require( "game/botsinit" );
local ability_item_usage_generic = BotsInit.CreateGeneric();
ability_item_usage_generic.GetComboMana = GetComboMana;
ability_item_usage_generic.GetComboDamage = GetComboDamage;
ability_item_usage_generic.CanCastAbilityOnTarget = CanCastAbilityOnTarget;
return ability_item_usage_generic;