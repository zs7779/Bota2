function CanCastAbilityOnTarget(ability, target)
	return ability:IsFullyCastable() and 
	target:CanBeSeen() and 
	not target:IsInvulnerable() and 
	(not target:IsMagicImmune() or 
	ability:GetTargetFlags() == ABILITY_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES);
end

function FindAoEVector( bool bEnemies, bool bHeroes, vector vBaseLocation, int nMaxDistanceFromBase, int nWidth, float fTimeInFuture, int nMaxHealth )
	local AoEVector = {};
	
	nMaxDistanceFromBase = math.min(1550, nMaxDistanceFromBase);
	local units = (bHeroes and GetNearbyHeroes(nMaxDistanceFromBase, bEnemies, BOT_MODE_NONE) or 
				GetNearbyCreeps(nMaxDistanceFromBase, bEnemies));
	
	local maxCount = 0;
	local targets = {};
	for _, targetUnit in pairs(units) do
	    local vtargetLoc = targetUnit:GetLocation();
		local vector = vtargetLoc - vBaseLocation;
		local vEnd = vBaseLocation + vector/utils.locationToLocationDistance(vBaseLocation, vtargetLoc)*nMaxDistanceFromBase;
		
		local thisCount = 0;
		local thisTargets = {};
		for _, unit in pairs(units) do
			local dist, closest_point, within = PointToLineDistance(vBaseLocation, vEnd, unit:GetLocation());
			if within and dist < nWidth then
				thisCount = thisCount + 1;
				thisTargets[#thisTargets+1] = unit;
			end
		end
		if thisCount > maxCount then
			maxCount = thisCount;
			targest = thisTargets;
		end
	end
	
	AoEVector.count = maxCount;
	AoEVector.baseloc = vBaseLocation;
	AoEVector.targetloc = utils.midPoint(targets);
	-- There is no guarantee this midPoint actually covers all targets...
	-- It seems there is guarantee, but I have trouble proving it.
	return AoEVector;
end

-- ***1. aoe nuke         2. aoe stun         3. aoe debuff         4. aoe buff         5. aoe save
-- ***6. point nuke       7. point stun       8. point debuff       9. point buff       10. point save
-- ***11. unit nuke       12. unit stun       13. unit debuff       14. unit buff       15. unit save
-- ***16. no target nuke  17. no target stun  18. no target debuff  19. no target buff  20. no target save

-- ***Generic logic:
-- ***Use unit nuke 1. enemy health low  2. harrass  3. attack
-- ***Use unit stun 1. channeling  2. enemy health low  3. key hero  4. attack
-- ***Use aoe nuke 1. enemy health low  2. harrass  3. defend/push  4. attack 
-- ***Use aoe stun 1. channeling  2. enemy health low  3. key hero  4. attack
-- ***Use debuff same as stun
-- ***Use buff 1. strongest friend  2. dealing damage friend
-- ***Use save 1. weakest friend  2. disabled friend  3. slowed/silenced friend

-- ***Point is pretty much like aoe.. just usually in cones or vectors

-- AoE
function ConsiderAoENuke(I, ability, radius, fTimeInFuture)
	if not ability:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	local activeMode = I:GetActiveMode();
	
	local mySpeed = I:GetCurrentMovementSpeed();
	if activeMode == BOT_MODE_RETREAT then mySpeed = 0; end
	
	local castRange = ability:GetCastRange();
	local delay = ability:GetCastPoint() + fTimeInFuture;
	local damage = ability:GetAbilityDamage();
	
	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);
	local nearbyEnemys = I:GetNearbyHeroes(mySpeed+castRange,true,BOT_MODE_NONE);
	local creeps = I:GetNearbyCreeps(castRange,true);

	-- AoE kill secure
	for _, enemy in pairs(nearbyEnemys) do
		local actualDamage = enemy:GetActualIncomingDamage(damage, DAMAGE_TYPE_MAGICAL);
		if CanCastAbilityOnTarget(ability, enemy) and
			enemy:GetHealth() <= actualDamage then
			local AoELocation = I:FindAoELocation( true, true, I:GetLocation(), mySpeed+castRange, radius, delay, actualDamage );
			if AoELocation.count >= 1 then return BOT_ACTION_DESIRE_HIGH, AoELocation.targetloc; end
		end
	end
	
	-- Single target kill secure
	for _, enemy in pairs(nearbyEnemys) do
		local actualDamage = enemy:GetActualIncomingDamage(I:GetOffensivePower(), DAMAGE_TYPE_MAGICAL);
		if CanCastAbilityOnTarget(ability, enemy) and
			enemy:GetHealth() <= actualDamage and not I:LowMana() then
			return BOT_ACTION_DESIRE_HIGH, enemy:PredictLocation(delay);
		end
	end
	
	-- Laning last hit
	-- If high mana and high health, try last hit + harrass enemy hero
	-- ***If aoe location -> hero location < radius or in same vector.. or something like this
	-- ***Need to consider the case for vector skills
	if activeMode == BOT_MODE_LANING then
		if not I:IsLow() then
			local AoEHero = I:FindAoELocation( true, true, I:GetLocation(), castRange, radius, delay, 0 );
			local AoECreep = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, delay, damage );
			if AoEHero.count >= 1 and AoECreep.cout >= 1 and 
			    utils.locationToLocationDistance(AoEHero.targetloc,AoECreep.targetloc) < radius then 
				return BOT_ACTION_DESIRE_MODERATE, midPoint({AoEHero.targetloc,AoECreep.targetloc}); 
			end
	-- If being harassed or low HP, try landing any last hit
		elseif (not I:LowMana() and I:WasRecentlyDamagedByAnyHero(1.0)) or I:LowHealth() then
			local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, delay, damage );
			if AoELocation.count >= 1 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
		end
	end
	
	-- Casual harrassment
	if activeMode ~= BOT_MODE_RETREAT and not I:LowMana() and ability:GetManaCost() < I:GetMana()/5.0 then
		for _, enemy in pairs(enemys) do
			return BOT_ACTION_DESIRE_LOW, enemy; end
		end
	end

	-- If farming, use aoe to get multiple last hits
	if activeMode == BOT_MODE_FARM then
		local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, delay, damage );
		if AoELocation.count >= 2 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
	end

	-- If pushing/defending, clear wave
	if activeMode >= BOT_MODE_PUSH_TOWER_TOP and
		activeMode <= BOT_MODE_DEFEND_TOWER_BOT then
		local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, delay, 0 );
		if AoELocation.count >= 2 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
	end

	-- Add if not BOT_MODE_RETREAT, go ahead if can hit multiple heroes
	if activeMode ~= BOT_MODE_RETREAT
		local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, delay, 0 );
		if AoELocation.count >= 3 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
	end
	
	-- If attacking, just go
	if activeMode == BOT_MODE_ROAM or
		 activeMode == BOT_MODE_TEAM_ROAM or
		 activeMode == BOT_MODE_DEFEND_ALLY or
		 activeMode == BOT_MODE_ATTACK then
		 local target = I:GetTarget();
		 if target ~= nil and CanCastAbilityOnTarget(ability, target) then
		 	return BOT_ACTION_DESIRE_MODERATE, target:PredictLocation(delay);
		 end
	end

	return BOT_ACTION_DESIRE_NONE, nil;
end

-- Point
function ConsiderPointNuke(I, ability, radius, fTimeInFuture)
	if not ability:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	local activeMode = I:GetActiveMode();
	
	local mySpeed = I:GetCurrentMovementSpeed();
	if activeMode == BOT_MODE_RETREAT then mySpeed = 0; end
	
	local castRange = ability:GetCastRange();
	local delay = ability:GetCastPoint() + fTimeInFuture;
	local damage = ability:GetAbilityDamage();
	
	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);
	local nearbyEnemys = I:GetNearbyHeroes(mySpeed+castRange,true,BOT_MODE_NONE);
	local creeps = I:GetNearbyCreeps(castRange,true);

	-- AoE kill secure
	for _, enemy in pairs(nearbyEnemys) do
		local actualDamage = enemy:GetActualIncomingDamage(damage, DAMAGE_TYPE_MAGICAL);
		if CanCastAbilityOnTarget(ability, enemy) and
			enemy:GetHealth() <= actualDamage then
			local AoELocation = I:FindAoEVector( true, true, I:GetLocation(), mySpeed+castRange, radius, delay, actualDamage );
			if AoELocation.count >= 1 then return BOT_ACTION_DESIRE_HIGH, AoELocation.targetloc; end
		end
	end
	
	-- Single target kill secure
	for _, enemy in pairs(nearbyEnemys) do
		local actualDamage = enemy:GetActualIncomingDamage(I:GetOffensivePower(), DAMAGE_TYPE_MAGICAL);
		if CanCastAbilityOnTarget(ability, enemy) and
			enemy:GetHealth() <= actualDamage and not I:LowMana() then
			return BOT_ACTION_DESIRE_HIGH, enemy:PredictLocation(delay);
		end
	end
	
	-- Laning last hit
	-- If high mana and high health, try last hit + harrass enemy hero
	-- ***If aoe location -> hero location < radius or in same vector.. or something like this
	-- ***Need to consider the case for vector skills
	if activeMode == BOT_MODE_LANING then
		if not I:IsLow() then
			local AoEHero = I:FindAoEVector( true, true, I:GetLocation(), castRange, radius, delay, 0 );
			local AoECreep = I:FindAoEVector( true, false, I:GetLocation(), castRange, radius, delay, damage );
			if AoEHero.count >= 1 and AoECreep.cout >= 1 and 
			    utils.locationToLocationDistance(AoEHero.targetloc,AoECreep.targetloc) < radius then 
				return BOT_ACTION_DESIRE_MODERATE, midPoint({AoEHero.targetloc,AoECreep.targetloc}); 
			end
	-- If being harassed or low HP, try landing any last hit
		elseif (not I:LowMana() and I:WasRecentlyDamagedByAnyHero(1.0)) or I:LowHealth() then
			local AoELocation = I:FindAoEVector( true, false, I:GetLocation(), castRange, radius, delay, damage );
			if AoELocation.count >= 1 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
		end
	end
	
	-- Casual harrassment
	if activeMode ~= BOT_MODE_RETREAT and not I:LowMana() and ability:GetManaCost() < I:GetMana()/5.0 then
		for _, enemy in pairs(enemys) do
			return BOT_ACTION_DESIRE_LOW, enemy; end
		end
	end

	-- If farming, use aoe to get multiple last hits
	if activeMode == BOT_MODE_FARM then
		local AoELocation = I:FindAoEVector( true, false, I:GetLocation(), castRange, radius, delay, damage );
		if AoELocation.count >= 2 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
	end

	-- If pushing/defending, clear wave
	if activeMode >= BOT_MODE_PUSH_TOWER_TOP and
		activeMode <= BOT_MODE_DEFEND_TOWER_BOT then
		local AoELocation = I:FindAoEVector( true, false, I:GetLocation(), castRange, radius, delay, 0 );
		if AoELocation.count >= 2 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
	end

	-- Add if not BOT_MODE_RETREAT, go ahead if can hit multiple heroes
	if activeMode ~= BOT_MODE_RETREAT
		local AoELocation = I:FindAoEVector( true, false, I:GetLocation(), castRange, radius, delay, 0 );
		if AoELocation.count >= 3 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
	end
	
	-- If attacking, just go
	if activeMode == BOT_MODE_ROAM or
		 activeMode == BOT_MODE_TEAM_ROAM or
		 activeMode == BOT_MODE_DEFEND_ALLY or
		 activeMode == BOT_MODE_ATTACK then
		 local target = I:GetTarget();
		 if target ~= nil and CanCastAbilityOnTarget(ability, target) then
		 	return BOT_ACTION_DESIRE_MODERATE, target:PredictLocation(delay);
		 end
	end

	return BOT_ACTION_DESIRE_NONE, nil;
end

-- Unit
-- ***some unit target spells also have radius
function ConsiderUnitNuke(I, ability, radius)
	if not ability:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	local activeMode = I:GetActiveMode();
	
	local mySpeed = I:GetCurrentMovementSpeed();
	if activeMode == BOT_MODE_RETREAT then mySpeed = 0; end
	
	local castRange = ability:GetCastRange();
	local delay = 0; -- delay should not apply... right?
	local damage = ability:GetAbilityDamage();
	
	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);
	local nearbyEnemys = I:GetNearbyHeroes(mySpeed+castRange,true,BOT_MODE_NONE);
	local creeps = I:GetNearbyCreeps(castRange,true);
	
	-- Kill secure
	for _, enemy in pairs(nearbyEnemys) do
		local actualDamage = enemy:GetActualIncomingDamage(I:GetOffensivePower(), DAMAGE_TYPE_MAGICAL);
		if CanCastAbilityOnTarget(ability, enemy) and
			enemy:GetHealth() <= actualDamage then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end
	
	-- Laning last hit when being harrassed or is low
	if activeMode == BOT_MODE_LANING then
		if (not I:LowMana() and I:WasRecentlyDamagedByAnyHero(1.0)) or I:LowHealth() then
			for _, creep in pairs(creeps) do
				if creep:GetHealth() <= damage then return BOT_ACTION_DESIRE_LOW, creep; end
			end
		end
	end

	-- Casual harrassment
	if activeMode ~= BOT_MODE_RETREAT and not I:LowMana() then
		for _, enemy in pairs(enemys) do
			return BOT_ACTION_DESIRE_LOW, enemy; end
		end
	end
			
	-- If have target, go
	if activeMode == BOT_MODE_ROAM or
		 activeMode == BOT_MODE_TEAM_ROAM or
		 activeMode == BOT_MODE_DEFEND_ALLY or
		 activeMode == BOT_MODE_ATTACK then
		 local target = I:GetTarget();
		 if target ~= nil and CanCastAbilityOnTarget(ability, target) then
		 	return BOT_ACTION_DESIRE_MODERATE, target;
		 end
	end

	return BOT_ACTION_DESIRE_NONE, nil;
end

function ConsiderUnitStun(I, ability, radius)
	if not ability:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	local activeMode = I:GetActiveMode();
	
	local mySpeed = I:GetCurrentMovementSpeed();
	if activeMode == BOT_MODE_RETREAT then mySpeed = 0; end
	
	local castRange = ability:GetCastRange();
	local delay = 0; -- delay should not apply... right?
	local damage = ability:GetAbilityDamage();
	
	-- GetNearby sorts units from close to far
	-- ***When to use enemys vs nearbyEnemys?
	-- ***I guess use nearbyEnemys in the enemy must die situation?
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);
	local nearbyEnemys = I:GetNearbyHeroes(mySpeed+castRange,true,BOT_MODE_NONE);
	
	-- Interrupt channeling within 1s walking
	for _, enemy in pairs(nearbyEnemys) do
		if CanCastAbilityOnTarget(ability, enemy) and
			enemy:IsChanneling() then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end
	
	-- Kill secure
	for _, enemy in pairs(nearbyEnemys) do
		local actualDamage = enemy:GetActualIncomingDamage(I:GetOffensivePower(), DAMAGE_TYPE_MAGICAL);
		if CanCastAbilityOnTarget(ability, enemy) and
			enemy:GetHealth() <= actualDamage then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end

	-- If fighting, stun lowHP/strongest carry/best disabler that is not already disabled
	if activeMode ~= BOT_MODE_RETREAT
		local disabler = utils.strongestDisabler(nearbyEnemys, true);
		if disabler ~= nil and CanCastAbilityOnTarget(ability, disabler) and 
			not disabler:IsDisabled() then
			return BOT_ACTION_DESIRE_HIGH, disabler;
		end
		local weakest = utils.weakestUnit(nearbyEnemys, true);
		if weakest ~= nil and CanCastAbilityOnTarget(ability, weakest) and 
			not weakest:IsDisabled() then
			return BOT_ACTION_DESIRE_HIGH, weakest;
		end
		local strongest = utils.strongestUnit(nearbyEnemys, true);
		if strongest ~= nil and CanCastAbilityOnTarget(ability, strongest) and 
			not strongest:IsDisabled() then
			return BOT_ACTION_DESIRE_HIGH, strongest;
		end
	end

	-- If retreating, stun closest enemy within immediate cast range
	if activeMode == BOT_MODE_RETREAT
		for _, enemy in pairs(enemys) do
			if CanCastAbilityOnTarget(ability, enemy) and
				not enemy:IsDisabled() then
				return BOT_ACTION_DESIRE_LOW, target;
			end
		end
	end

	-- If have target, go
	if activeMode == BOT_MODE_ROAM or
		 activeMode == BOT_MODE_TEAM_ROAM or
		 activeMode == BOT_MODE_DEFEND_ALLY or
		 activeMode == BOT_MODE_ATTACK then
		 local target = I:GetTarget();
		 if target ~= nil and CanCastAbilityOnTarget(ability, target) and
		 	not target:IsDisabled() then
		 	return BOT_ACTION_DESIRE_MODERATE, target;
		 end
	end

	return BOT_ACTION_DESIRE_NONE, nil;
end

-- No target
function ConsiderNoTargetBuff(I, ability, radius)
	if not ability:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE;
	end
	local activeMode = I:GetActiveMode();
	if activeMode == BOT_MODE_RETREAT or 
		activeMode == BOT_MODE_EVASIVE_MANEUVERS then 
		return BOT_ACTION_DESIRE_HIGH; 
	end
	
	local castRange = ability:GetCastRange();
	local delay = 0; -- delay should not apply... right?
	local damage = ability:GetAbilityDamage();
	local friends = {};
	if radius >= 1600 then 
		local friendlist = GetUnitList(UNIT_LIST_ALLIED_HEROES);
		for _, friend in pairs(friendlist) do
			if GetUnitToUnitDistance(I, friend) < radius then
				friends[#friends+1] = friend;
			end
		end
	else
		friends = I:GetNearbyHeroes(radius,true,BOT_MODE_NONE);
	end
	
	for _, friend in pairs(friends) do
		local friendMode = friend:GetActiveMode();
		if friendMode = BOT_MODE_RETREAT or 
			friendMode == BOT_MODE_EVASIVE_MANEUVERS then
			return BOT_ACTION_DESIRE_HIGH;
		end
		if friendMode == BOT_MODE_ROAM or
		 friendMode == BOT_MODE_TEAM_ROAM or
		 friendMode == BOT_MODE_DEFEND_ALLY or
		 friendMode == BOT_MODE_ATTACK then
			local target = I:GetTarget();
			-- if friend have target within initiation distance <- change it from constant please
			if target ~= nil and GetUnitToUnitDistance(friend,target) < 1100 then
				return BOT_ACTION_DESIRE_MODERATE;
			end
		end
	end
	
	return BOT_ACTION_DESIRE_NONE;
end

--
function AbilityUsageThink()
	local I = GetBot();
	local abilities, talents = I:GetAbilities();
	
	local BreatheFire = I:GetAbilityByName(abilities[1]);
	local DragonTail = I:GetAbilityByName(abilities[2]);
	local BreatheFireDesire, BreatheFireLoc = ConsiderAoEDamage(I, BreatheFire);
	local DragonTailDesire, DragonTailTarget = ConsiderUnitStun(I, DragonTail);
	
	local considerations = {};
	local desires = {};
	local targets = {};
	
	for _, ability in pairs(abilities) do
		if not ability:IsPassive() and ability:IsFullyCastable() then
			considerations[#considerations+1] = ability;
			local desire, target = 
		end
	end
	
	if BreatheFireDesire > 0 then
		I:Action_UseAbilityOnLocation(BreatheFire,BreatheFireLoc);
	end
	if DragonTailDesire > 0 then
		I:Action_UseAbilityOnEntity(DragonTailDesire, DragonTailTarget);
	end
end


BotsInit = require( "game/botsinit" );
local ability_item_usage_generic = BotsInit.CreateGeneric();
ability_item_usage_generic.GetComboMana = GetComboMana;
ability_item_usage_generic.GetComboDamage = GetComboDamage;
ability_item_usage_generic.CanCastAbilityOnTarget = CanCastAbilityOnTarget;
return ability_item_usage_generic;
