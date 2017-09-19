require(GetScriptDirectory() ..  "/utils")

function CanCastAbilityOnTarget(ability, target)
	return ability:IsFullyCastable() and 
	target:CanBeSeen() and target:IsAlive() and
	not target:IsInvulnerable() and 
	(not target:IsMagicImmune() or 
	ability:GetTargetFlags() == ABILITY_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES);
end

-- ***1. aoe nuke         2. aoe stun         3. aoe debuff         4. aoe buff         5. aoe save
-- ***6. point nuke       7. point stun       8. point debuff       9. point buff       10. point save
-- ***11. unit nuke       12. unit stun       13. unit debuff       14. unit buff       15. unit save
-- ***16. no target nuke  17. no target stun  18. no target debuff  19. no target buff  20. no target save

-- ***Generic logic:
-- ***Use unit nuke 1. enemy health low  2. harass  3. attack
-- ***Use unit stun 1. channeling  2. enemy health low  3. key hero  4. attack
-- ***Use aoe nuke 1. enemy health low  2. harass  3. defend/push  4. attack 
-- ***Use aoe stun 1. channeling  2. enemy health low  3. key hero  4. attack
-- ***Use debuff same as stun
-- ***Use buff 1. strongest friend  2. dealing damage friend
-- ***Use save 1. weakest friend  2. disabled friend  3. slowed/silenced friend
-- ***Consider cancel channeling if mode changes

-- ***Point is pretty much like aoe.. just usually in cones or vectors

-- AoE
function ConsiderAoENuke(I, ability, radius, fTimeInFuture)
	if not ability:IsFullyCastable() or not I:CanCast() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	local activeMode = I:GetActiveMode();
	
	local mySpeed = I:GetCurrentMovementSpeed();
	if activeMode == BOT_MODE_RETREAT then 
		mySpeed = 0; 
	end
	
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
			if AoELocation.count > 1 then
				utils.DebugTalk("群体KS",true);
				return BOT_ACTION_DESIRE_HIGH, AoELocation.targetloc; 
			end
		end
	end
	
	-- Single target kill secure
	for _, enemy in pairs(nearbyEnemys) do
		local actualDamage = enemy:GetActualIncomingDamage(I:GetOffensivePower(), DAMAGE_TYPE_MAGICAL);
		if CanCastAbilityOnTarget(ability, enemy) and
			enemy:GetHealth() <= actualDamage and not I:LowMana() then
			utils.DebugTalk("单体KS",true);
			return BOT_ACTION_DESIRE_HIGH, enemy:PredictLocation(delay);
		end
	end
	
	-- Laning last hit
	-- If high mana and high health, try last hit + harass enemy hero
	-- ***If aoe location -> hero location < radius or in same vector.. or something like this
	-- ***Need to consider the case for vector skills
	if activeMode == BOT_MODE_LANING then
		if not I:IsLow() then
			local AoEHero = I:FindAoELocation( true, true, I:GetLocation(), castRange, radius, delay, 0 );
			local AoECreep = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, delay, damage );
			if AoEHero.count >= 1 and AoECreep.cout >= 1 and 
			    utils.locationToLocationDistance(AoEHero.targetloc,AoECreep.targetloc) < radius then 
				utils.DebugTalk("收兵+压人",true);
				return BOT_ACTION_DESIRE_MODERATE, midPoint({AoEHero.targetloc,AoECreep.targetloc}); 
			end
	-- If being harassed or low HP, try landing any last hit
		elseif (not I:LowMana() and I:WasRecentlyDamagedByAnyHero(1.0)) or I:LowHealth() then
			local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, delay, damage );
			if AoELocation.count >= 1 then
				utils.DebugTalk("补刀",true); 
				return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; 
			end
		end
	end
	
	-- Casual harassment
	if activeMode == BOT_MODE_LANING and not I:LowMana() and ability:GetManaCost() < I:GetMana()/4.0 then
		for _, enemy in pairs(enemys) do
			utils.DebugTalk("压人",true);
			return BOT_ACTION_DESIRE_LOW, enemy;
		end
	end

	-- If farming, use aoe to get multiple last hits
	if activeMode == BOT_MODE_FARM then
		local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, delay, damage );
		if AoELocation.count >= 2 then
			utils.DebugTalk("收线",true);
			return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; 
		end
	end

	-- If pushing/defending, clear wave
	if activeMode >= BOT_MODE_PUSH_TOWER_TOP and
		activeMode <= BOT_MODE_DEFEND_TOWER_BOT then
		local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, delay, 0 );
		if AoELocation.count >= 2 then
			utils.DebugTalk("推线",true); 
			return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; 
		end
	end

	-- Add if not BOT_MODE_RETREAT, go ahead if can hit multiple heroes
	if activeMode ~= BOT_MODE_RETREAT then
		local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, delay, 0 );
		if AoELocation.count >= 3 then
			utils.DebugTalk("波3个",true);
			return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; 
		end
	end
	
	-- If attacking, just go
	if activeMode == BOT_MODE_ROAM or
		 activeMode == BOT_MODE_TEAM_ROAM or
		 activeMode == BOT_MODE_DEFEND_ALLY or
		 activeMode == BOT_MODE_ATTACK then
		 local target = I:GetTarget();
		 if target ~= nil and CanCastAbilityOnTarget(ability, target) and 
		 	GetUnitToUnitDistance(I, target) < castRange then
			utils.DebugTalk("干他",true);
		 	return BOT_ACTION_DESIRE_MODERATE, target:PredictLocation(delay);
		 end
	end

	return BOT_ACTION_DESIRE_NONE, nil;
end

-- Point
function ConsiderPointNuke(I, ability, radius, fTimeInFuture)
	if not ability:IsFullyCastable() or not I:CanCast() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	local activeMode = I:GetActiveMode();
	
	local mySpeed = I:GetCurrentMovementSpeed();
	if activeMode == BOT_MODE_RETREAT then 
		mySpeed = 0; 
	end
	
	local castRange = ability:GetCastRange();
	local delay = ability:GetCastPoint() + fTimeInFuture;
	local damage = ability:GetAbilityDamage();
	
	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);
	local nearbyEnemys = I:GetNearbyHeroes(mySpeed+castRange,true,BOT_MODE_NONE);
	local creeps = I:GetNearbyCreeps(castRange,true);

	-- AoE kill secure
	for i = 1, #nearbyEnemys do
		local enemy = nearbyEnemys[i];
		local actualDamage = enemy:GetActualIncomingDamage(damage, DAMAGE_TYPE_MAGICAL);
		if CanCastAbilityOnTarget(ability, enemy) and
			enemy:GetHealth() <= actualDamage then
			local AoELocation = I:FindAoEVector( true, true, false, I:GetLocation(), mySpeed+castRange, radius, delay, actualDamage );
			if AoELocation.count > 1 then 
				utils.DebugTalk("群体KS",true);
				return BOT_ACTION_DESIRE_HIGH, AoELocation.targetloc; 
			end
		end
	end
	
	-- Single target kill secure
	for i = 1, #nearbyEnemys do
		local enemy = nearbyEnemys[i];
		local actualDamage = enemy:GetActualIncomingDamage(I:GetOffensivePower(), DAMAGE_TYPE_MAGICAL);
		if CanCastAbilityOnTarget(ability, enemy) and
			enemy:GetHealth() <= actualDamage and not I:LowMana() then
			utils.DebugTalk("单体KS",true);
			return BOT_ACTION_DESIRE_HIGH, enemy:PredictLocation(delay);
		end
	end
	
	-- Laning last hit
	-- If high mana and high health, try last hit + harass enemy hero
	-- ***If aoe location -> hero location < radius or in same vector.. or something like this
	-- ***Need to consider the case for vector skills
	if activeMode == BOT_MODE_LANING then
		if not I:IsLow() then
			local AoECreep = I:FindAoEVector( true, false, true, I:GetLocation(), castRange, radius, delay, damage );
			if AoECreep.count >= 1 then 
			    utils.DebugTalk("收兵+压人",true);
				return BOT_ACTION_DESIRE_LOW, AoECreep.targetloc; 
			end
	-- If being harassed or low HP, try landing any last hit
		elseif (not I:LowMana() and I:WasRecentlyDamagedByAnyHero(1.0)) or 
			(I:LowHealth() and #I:GetNearbyHeroes(6,true,BOT_MODE_NONE) > 0) then
			local AoELocation = I:FindAoEVector( true, false, false, I:GetLocation(), castRange, radius, delay, damage );
			if AoELocation.count >= 1 then 
				utils.DebugTalk("补刀",true); 
				return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; 
			end
		end
	end
	
	-- Casual harassment
	-- ***should only happen when target is being roamed but teammate is not near
	-- ***dont want to push lane for no reason
	if radius == 0 then
		if activeMode == BOT_MODE_LANING and not I:LowMana() and ability:GetManaCost() < I:GetMana()/4.0 then
			for i = 1, #enemys do
				local enemy = enemys[i];
				utils.DebugTalk("压人",true);
				return BOT_ACTION_DESIRE_LOW, enemy:GetLocation();
			end
		end
	end

	-- If farming, use aoe to get multiple last hits
	if activeMode == BOT_MODE_FARM then
		local AoELocation = I:FindAoEVector( true, false, false, I:GetLocation(), castRange, radius, delay, damage );
		if AoELocation.count >= 2 then 
			utils.DebugTalk("收线",true);
			return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; 
		end
	end

	-- If pushing/defending, clear wave
	if activeMode >= BOT_MODE_PUSH_TOWER_TOP and
		activeMode <= BOT_MODE_DEFEND_TOWER_BOT then
		local AoELocation = I:FindAoEVector( true, false, false, I:GetLocation(), castRange, radius, delay, 0 );
		if AoELocation.count >= 2 then
			utils.DebugTalk("推线",true); 
			return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; 
		end
	end

	-- Add if not BOT_MODE_RETREAT, go ahead if can hit multiple heroes
	if activeMode ~= BOT_MODE_RETREAT and
	 activeMode == BOT_MODE_LANING then
		local AoELocation = I:FindAoEVector( true, true, false, I:GetLocation(), castRange, radius, delay, 0 );
		if AoELocation.count >= 3 then 
			utils.DebugTalk("波3个",true);
			return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; 
		end
	end
	
	-- If attacking, just go
	if activeMode == BOT_MODE_ROAM or
		 activeMode == BOT_MODE_TEAM_ROAM or
		 activeMode == BOT_MODE_DEFEND_ALLY or
		 activeMode == BOT_MODE_ATTACK then
		 local target = I:GetTarget();
		 if target ~= nil and CanCastAbilityOnTarget(ability, target) and 
		 	GetUnitToUnitDistance(I, target) < castRange then
		 	utils.DebugTalk("干他",true);
		 	return BOT_ACTION_DESIRE_MODERATE, target:PredictLocation(delay);
		 end
	end

	return BOT_ACTION_DESIRE_NONE, nil;
end

-- Unit
-- ***some unit target spells also have radius
function ConsiderUnitNuke(I, ability, radius)
	if not ability:IsFullyCastable() or not I:CanCast() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	local activeMode = I:GetActiveMode();
	
	local mySpeed = I:GetCurrentMovementSpeed();
	if activeMode == BOT_MODE_RETREAT then 
		mySpeed = 0; 
	end
	
	local castRange = ability:GetCastRange();
	local delay = 0; -- delay should not apply... right?
	local damage = ability:GetAbilityDamage();
	
	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);
	local nearbyEnemys = I:GetNearbyHeroes(mySpeed+castRange,true,BOT_MODE_NONE);
	local creeps = I:GetNearbyCreeps(castRange,true);
	
	-- Kill secure
	for i = 1, #nearbyEnemys do
		local enemy = nearbyEnemys[i];
		local actualDamage = enemy:GetActualIncomingDamage(I:GetOffensivePower(), DAMAGE_TYPE_MAGICAL);
		if CanCastAbilityOnTarget(ability, enemy) and
			enemy:GetHealth() <= actualDamage then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end
	
	-- ***Also need to consider harassment when hero is within skill radius
	-- Laning last hit when being harassed or is low
	if activeMode == BOT_MODE_LANING then
		if (not I:LowMana() and I:WasRecentlyDamagedByAnyHero(1.0)) or I:LowHealth() then
			for i = 1, #creeps do
				local creep = creeps[i];
				if creep:GetHealth() <= damage then 
					return BOT_ACTION_DESIRE_LOW, creep; 
				end
			end
		end
	end

	-- Casual harassment
	if activeMode == BOT_MODE_LANING and not I:LowMana() and ability:GetManaCost() < I:GetMana()/4.0 then
		for i = 1, #enemys do
			local enemy = nearbyEnemys[i];
			return BOT_ACTION_DESIRE_LOW, enemy;
		end
	end
			
	-- If have target, go
	if activeMode == BOT_MODE_ROAM or
		 activeMode == BOT_MODE_TEAM_ROAM or
		 activeMode == BOT_MODE_DEFEND_ALLY or
		 activeMode == BOT_MODE_ATTACK then
		 local target = I:GetTarget();
		 if target ~= nil and CanCastAbilityOnTarget(ability, target) and 
		 	GetUnitToUnitDistance(I, target) < castRange then
		 	return BOT_ACTION_DESIRE_MODERATE, target;
		 end
	end

	return BOT_ACTION_DESIRE_NONE, nil;
end

function ConsiderUnitStun(I, ability, radius)
	if not ability:IsFullyCastable() or not I:CanCast() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	local activeMode = I:GetActiveMode();
	
	local mySpeed = I:GetCurrentMovementSpeed();
	if activeMode == BOT_MODE_RETREAT then 
		mySpeed = 0; 
	end
	
	local castRange = ability:GetCastRange();
	local delay = 0; -- delay should not apply... right?
	local damage = ability:GetAbilityDamage();
	
	-- GetNearby sorts units from close to far
	-- ***When to use enemys vs nearbyEnemys?
	-- ***I guess use nearbyEnemys in the enemy must die situation?
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);
	local nearbyEnemys = I:GetNearbyHeroes(mySpeed+castRange,true,BOT_MODE_NONE);
	
	-- Interrupt channeling within 1s walking
	for i = 1, #nearbyEnemys do
		local enemy = nearbyEnemys[i];
		if CanCastAbilityOnTarget(ability, enemy) and
			enemy:IsChanneling() then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end
	
	-- Kill secure
	for i = 1, #nearbyEnemys do
		local enemy = nearbyEnemys[i];
		local actualDamage = enemy:GetActualIncomingDamage(I:GetOffensivePower(), DAMAGE_TYPE_MAGICAL);
		if CanCastAbilityOnTarget(ability, enemy) and
			enemy:GetHealth() <= actualDamage then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end

	-- If fighting, stun lowHP/strongest carry/best disabler that is not already disabled
	if activeMode ~= BOT_MODE_RETREAT then
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
	if activeMode == BOT_MODE_RETREAT then
		for i = 1, #enemys do
			local enemy = nearbyEnemys[i];
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
		 	not target:IsDisabled() and 
		 	GetUnitToUnitDistance(I, target) < castRange then
		 	return BOT_ACTION_DESIRE_MODERATE, target;
		 end
	end

	return BOT_ACTION_DESIRE_NONE, nil;
end

-- No target
function ConsiderNoTargetBuff(I, ability, radius)
	if not ability:IsFullyCastable() or not I:CanCast() then
		return BOT_ACTION_DESIRE_NONE;
	end
	local activeMode = I:GetActiveMode();
	if activeMode == BOT_MODE_RETREAT or 
		activeMode == BOT_MODE_EVASIVE_MANEUVERS then 
		return BOT_ACTION_DESIRE_HIGH; 
	end
	
	local castRange = 0;
	local delay = 0; -- delay should not apply... right?
	local damage = ability:GetAbilityDamage();
	local friends = {};
	if radius >= 1600 then 
		local friendlist = GetUnitList(UNIT_LIST_ALLIED_HEROES);
		for i = 1, #friendlist do
			local friend = friendlist[i];
			if GetUnitToUnitDistance(I, friend) < radius then
				friends[#friends+1] = friend;
			end
		end
	else
		friends = I:GetNearbyHeroes(radius,true,BOT_MODE_NONE);
	end
	
	for i = 1, #friends do
		local friend = friends[i]
		local friendMode = friend:GetActiveMode();
		if friendMode == BOT_MODE_RETREAT or 
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
-- function AbilityUsageThink()
-- 	local I = GetBot();
-- 	local abilities, talents = I:GetAbilities();
	
-- 	local BreatheFire = I:GetAbilityByName(abilities[1]);
-- 	local DragonTail = I:GetAbilityByName(abilities[2]);
-- 	local BreatheFireDesire, BreatheFireLoc = ConsiderAoEDamage(I, BreatheFire);
-- 	local DragonTailDesire, DragonTailTarget = ConsiderUnitStun(I, DragonTail);
	
-- 	local considerations = {};
-- 	local desires = {};
-- 	local targets = {};
	
-- 	for _, ability in pairs(abilities) do
-- 		if not ability:IsPassive() and ability:IsFullyCastable() then
-- 			considerations[#considerations+1] = ability;
-- 			local desire, target = 
-- 		end
-- 	end
	
-- 	if BreatheFireDesire > 0 then
-- 		I:Action_UseAbilityOnLocation(BreatheFire,BreatheFireLoc);
-- 	end
-- 	if DragonTailDesire > 0 then
-- 		I:Action_UseAbilityOnEntity(DragonTailDesire, DragonTailTarget);
-- 	end
-- end


BotsInit = require( "game/botsinit" );
local ability_item_usage_generic = BotsInit.CreateGeneric();
ability_item_usage_generic.FindAoEVector = FindAoEVector;
ability_item_usage_generic.CanCastAbilityOnTarget = CanCastAbilityOnTarget;
ability_item_usage_generic.ConsiderAoENuke = ConsiderAoENuke;
ability_item_usage_generic.ConsiderPointNuke = ConsiderPointNuke;
ability_item_usage_generic.ConsiderUnitNuke = ConsiderUnitNuke;
ability_item_usage_generic.ConsiderUnitStun = ConsiderUnitStun;
ability_item_usage_generic.ConsiderNoTargetBuff = ConsiderNoTargetBuff;
return ability_item_usage_generic;
