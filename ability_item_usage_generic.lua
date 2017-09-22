require(GetScriptDirectory() ..  "/utils")

function CanCastAbilityOnTarget(ability, target)
	return ability:IsFullyCastable() and 
	target:CanBeSeen() and target:IsAlive() and
	not target:IsInvulnerable() and 
	(not target:IsMagicImmune() or 
	ability:GetTargetFlags() == ABILITY_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES);
end
-- And by AoE, I mean AoE, not your punk ass defination
function CDOTA_Bot_Script:UseAoEAbility(ability, baseLocation, range, radius, delay, damage, damageType, units)
	local AoELocation; AoELocation.count = 0;
	-- ***Sometimes you think about if it is worth it to put a loop here.
	if #units == 1 then
		local unit = units[1];
		AoELocation.count = 1;
		AoELocation.targetloc = unit:PredictLocation(delay);
		if damage > 0 and unit:GetHealth() <= unit:GetActualIncomingDamage(damage, damageType)then
			self:DebugTalk("AoE 精致");
			return AoELocation;
		elseif damage == 0
			self:DebugTalk("AoE 干他");
			return AoELocation;
		end
		return AoELocation;
	end

	for _, unit in ipairs(units) do
		local actualDamage = unit:GetActualIncomingDamage(damage, damageType);
		if CanCastAbilityOnTarget(ability, unit) and
			unit:GetHealth() <= actualDamage then
			if utils.CheckFlag(ability.GetBehavior(), ABILITY_BEHAVIOR_AOE) then
				AoELocation = self:FindAoELocation( true, unit:IsHero(), baseLocation, range, radius, delay, actualDamage);
			elseif utils.CheckFlag(ability.GetBehavior(), DOTA_ABILITY_BEHAVIOR_DIRECTIONAL) then
				AoELocation = self:FindAoEVector(true, unit:IsHero(), false, baseLocation, range, radius, delay, actualDamage);
			end

			if AoELocation.count > 0 then
				if unit:IsHero() then
					if damage > 0 then
						self:DebugTalk("AoE 精致");
					else
						self:DebugTalk("AoE 干他");
					end
				else
					if damage > 0 then
						self:DebugTalk("AoE 收线");
					else
						self:DebugTalk("AoE 推线");
					end
				end
				return AoELocation;
			end
		end
	end
	return AoELocation;
end

function CDOTA_Bot_Script:UseAoEHarass(lity, baseLocation, range, radius, delay, damage)
	local AoELocation; AoELocation.count = 0;
	if utils.CheckFlag(ability.GetBehavior(), ABILITY_BEHAVIOR_AOE) then
		local AoEHero = self:FindAoELocation( true, true, baseLocation, castRange, radius, delay, 0);
		local AoECreep = self:FindAoELocation( true, false, baseLocation, castRange, radius, delay, damage);
		if AoEHero.count > 0 and AoECreep.count > 0 and 
		    utils.locationToLocationDistance(AoEHero.targetloc,AoECreep.targetloc) < radius then 
			self:DebugTalk("收兵+压人");
			AoELocation.count =  AoEHero.count + AoECreep.count;
			AoELocation.targetloc = midPoint({AoEHero.targetloc,AoECreep.targetloc}); 
		end
	elseif utils.CheckFlag(ability.GetBehavior(), DOTA_ABILITY_BEHAVIOR_DIRECTIONAL) then
		local AoECreep = self:FindAoEVector( true, false, true, self:GetLocation(), castRange, radius, delay, damage);
		if AoECreep.count > 0 then 
		    self:DebugTalk("收兵+压人");
		    AoELocation = AoECreep;
		end
	end
	return AoELocation;
end

function CDOTA_Bot_Script:UseTargetAbility(ability, radius, damage, damageType, units)
	if damage == 0 then damage = math.huge; end
	for _, unit in ipairs(units) do
		local actualDamage = unit:GetActualIncomingDamage(damage, damageType);
		if target ~= nil and CanCastAbilityOnTarget(ability, target) and 
		 	GetUnitToUnitDistance(I, target) < castRange and
			unit:GetHealth() <= actualDamage then
			if unit:IsHero() then
				if damage > 0 then
					self:DebugTalk("精致");
				else --*** maybe we don't consider harassing right now.
					self:DebugTalk("干他");
				end
			else
				self:DebugTalk("补刀");
			end
			return unit;
		end
	end
	return nil;
end
-- ***1. aoe nuke         2. aoe stun         3. aoe debuff         4. aoe buff         5. aoe save
-- ***6. unit nuke        7. unit stun        8. unit debuff        9. unit buff        10. unit save
-- ***11. no target nuke  12. no target stun  13. no target debuff  14. no target buff  15. no target save
-- ***16. invis           17. blink

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
	local AoELocation;
	local activeMode = I:GetActiveMode();

	local castRange = ability:GetCastRange();
	local delay = ability:GetCastPoint() + fTimeInFuture;
	local damage = ability:GetAbilityDamage();
	local damageType = ability:GetDamageType();

	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange+radius,true,BOT_MODE_NONE);
	local creeps = I:GetNearbyCreeps(castRange+radius,true);

	-- AoE kill secure
	AoELocation = I:UseAoEAbility(ability, I:GetLocation(), castRange, radius, delay, damage, damageType, enemys);
	if AoELocation.count > 0 then
		return BOT_ACTION_DESIRE_HIGH, AoELocation.targetloc; 
	end
	
	-- Laning last hit
	-- If high mana and high health, try last hit + harass enemy hero
	if activeMode == BOT_MODE_LANING then
		if not I:LowHealth() and not I:LowMana() then
			AoELocation = I:UseAoEHarass(ability, baseLocation, range, radius, delay, damage);
			if AoELocation ~= nil then
				return BOT_ACTION_DESIRE_MODERATE, AoELocation.targetloc;
			end
	-- If being harassed or low HP, try landing any last hit
		elseif (not I:LowMana() and I:WasRecentlyDamagedByAnyHero(1.0)) or I:LowHealth() then
			AoELocation = I:UseAoEAbility(ability, I:GetLocation(), castRange, radius, delay, damage, damageType, creeps);
			if AoELocation.count > 0 then
				return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; 
			end
		end
	end

	-- If farming, use aoe to get multiple last hits
	if activeMode == BOT_MODE_FARM then
		AoELocation = I:UseAoEAbility(ability, I:GetLocation(), castRange, radius, delay, damage, damageType, creeps);
		if AoELocation.count >= 2 then
			return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; 
		end
	end

	-- If pushing/defending, clear wave
	if activeMode >= BOT_MODE_PUSH_TOWER_TOP and
		activeMode <= BOT_MODE_DEFEND_TOWER_BOT then
		AoELocation = I:UseAoEAbility(ability, I:GetLocation(), castRange, radius, delay, 0, damageType, creeps);
			if AoELocation.count >= 2 then
			return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; 
		end
	end

	-- Add if not BOT_MODE_RETREAT, go ahead if can hit multiple heroes
	if activeMode ~= BOT_MODE_LANING and activeMode ~= BOT_MODE_RETREAT then
		AoELocation = I:UseAoEAbility(ability, I:GetLocation(), castRange, radius, delay, 0, damageType, enemys);
		if AoELocation.count >= 3 then
			return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc;
		end
	end
	
	-- If attacking, just go
	if activeMode == BOT_MODE_LANING or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK then
		local target = I:GetTarget();
		if target ~= nil and 
			GetUnitToUnitDistance(I, target) < castRange then
			AoELocation = I:UseAoEAbility(ability, I:GetLocation(), castRange, radius, delay, 0, damageType, {target});
			if AoELocation.count > 0 then
		 		return BOT_ACTION_DESIRE_MODERATE, AoELocation.targetloc;
		 	end
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
	local target;
	local activeMode = I:GetActiveMode();
		
	local castRange = ability:GetCastRange();
	local delay = 0; -- delay should not apply... right?
	local damage = ability:GetAbilityDamage();
	local damageType = ability:GetDamageType();

	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange+radius,true,BOT_MODE_NONE);
	local creeps = I:GetNearbyCreeps(castRange+radius,true);
	
	-- Kill secure
	target = I:UseTargetAbility(ability, radius, damage, damageType, enemys);
	if target ~= nil then
		return BOT_ACTION_DESIRE_HIGH, target;
	end
	
	-- Laning last hit when being harassed or is low
	if activeMode == BOT_MODE_LANING then
		if (not I:LowMana() and I:WasRecentlyDamagedByAnyHero(1.0)) or I:LowHealth() then
			target = I:UseTargetAbility(ability, radius, damage, damageType, creeps);
			if target ~= nil then
				return BOT_ACTION_DESIRE_LOW, target;
			end
		end
	end
			
	-- If have target, go
	if activeMode == BOT_MODE_LANING or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK then
	 	target = I:UseTargetAbility(ability, radius, 0, damageType, {I:GetTarget()});
	 	if target ~= nil then
		 	return BOT_ACTION_DESIRE_MODERATE, target;
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil;
end

function ConsiderUnitStun(I, ability, radius)
	if not ability:IsFullyCastable() or not I:CanCast() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	local target;
	local activeMode = I:GetActiveMode();
	
	local castRange = ability:GetCastRange();
	local delay = 0; -- delay should not apply... right?
	local damage = 0;
	local damageType = ability:GetDamageType();
	
	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange+radius,true,BOT_MODE_NONE);
	local channelingEnemys = {};
	for i, enemy in ipairs(enemys) do
		if enemy:IsChanneling() then
			table.insert(channelingEnemys, enemy);
		end
	end
	
	-- Interrupt channeling within 1s walking
	target = I:UseTargetAbility(ability, radius, 0, damageType, channelingEnemys);
	if target ~= nil then
		return BOT_ACTION_DESIRE_HIGH, target;
	end

	-- If fighting, stun lowHP/strongest carry/best disabler that is not already disabled
	if activeMode ~= BOT_MODE_RETREAT then
		local disabler = I:UseTargetAbility(ability, radius, 0, damageType, {utils.strongestDisabler(enemys, true)});
		if disabler ~= nil then
			return BOT_ACTION_DESIRE_HIGH, disabler;
		end
		local weakest = I:UseTargetAbility(ability, radius, 0, damageType, {utils.weakestUnit(enemys, true)});
		if weakest ~= nil then
			return BOT_ACTION_DESIRE_HIGH, weakest;
		end
		local strongest = I:UseTargetAbility(ability, radius, 0, damageType, {utils.strongestUnit(enemys, true)});
		if strongest ~= nil then
			return BOT_ACTION_DESIRE_HIGH, strongest;
		end
	end

	-- If retreating, stun closest enemy within immediate cast range
	if activeMode == BOT_MODE_RETREAT then
		target = I:UseTargetAbility(ability, radius, 0, damageType, enemys);
		if target ~= nil and not target:IsDisabled() then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end

	-- If have target, go
	if activeMode == BOT_MODE_LANING or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK then
		target = I:UseTargetAbility(ability, radius, 0, damageType, {I:GetTarget()});
	 	if target ~= nil and not target:IsDisabled() then
		 	return BOT_ACTION_DESIRE_MODERATE, target;
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil;
end

function ConsiderUnitDebuff(I, ability, radius)
	if not ability:IsFullyCastable() or not I:CanCast() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	local target;
	local activeMode = I:GetActiveMode();
	
	local castRange = ability:GetCastRange();
	local delay = 0; -- delay should not apply... right?
	local damage = 0; -- do not consider damage
	local damageType = ability:GetDamageType();
	
	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange+radius,true,BOT_MODE_NONE);

	-- If fighting, stun lowHP/strongest carry/best disabler that is not already disabled
	if activeMode ~= BOT_MODE_RETREAT then
		local weakest = I:UseTargetAbility(ability, radius, 0, damageType, {utils.weakestUnit(enemys, true)});
		if weakest ~= nil then
			return BOT_ACTION_DESIRE_HIGH, weakest;
		end
		local disabler = I:UseTargetAbility(ability, radius, 0, damageType, {utils.strongestDisabler(enemys, true)});
		if disabler ~= nil then
			return BOT_ACTION_DESIRE_HIGH, disabler;
		end
		local strongest = I:UseTargetAbility(ability, radius, 0, damageType, {utils.strongestUnit(enemys, true)});
		if strongest ~= nil then
			return BOT_ACTION_DESIRE_HIGH, strongest;
		end
	end

	-- If retreating, stun closest enemy within immediate cast range
	if activeMode == BOT_MODE_RETREAT then
		target = I:UseTargetAbility(ability, radius, 0, damageType, enemys);
		if target ~= nil and not target:IsDisabled() then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end

	-- If have target, go
	if activeMode == BOT_MODE_LANING or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK then
		target = I:UseTargetAbility(ability, radius, 0, damageType, {I:GetTarget()});
	 	if target ~= nil and not target:IsDisabled() then
		 	return BOT_ACTION_DESIRE_MODERATE, target;
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil;
end

-- No target
function ConsiderNoTargetNuke(I, ability, radius, fTimeInFuture)
	if not ability:IsFullyCastable() or not I:CanCast() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	local AoELocation;
	local activeMode = I:GetActiveMode();

	local castRange = 0; -- *** need testing for what range to use. dunno if 0 works
	local delay = ability:GetCastPoint() + fTimeInFuture;
	local damage = ability:GetAbilityDamage();
	local damageType = ability:GetDamageType();

	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange+radius,true,BOT_MODE_NONE);
	local creeps = I:GetNearbyCreeps(castRange+radius,true);

	-- AoE kill secure
	AoELocation = I:UseAoEAbility(ability, I:GetLocation(), castRange, radius, delay, damage, damageType, enemys);
	if AoELocation.count > 0 then
		return BOT_ACTION_DESIRE_HIGH;
	end
	
	-- Laning last hit
	-- If high mana and high health, try last hit + harass enemy hero
	if activeMode == BOT_MODE_LANING then
		if not I:LowHealth() and not I:LowMana() then
			AoELocation = I:UseAoEHarass(ability, baseLocation, range, radius, delay, damage);
			if AoELocation ~= nil then
				return BOT_ACTION_DESIRE_MODERATE;
			end
	-- If being harassed or low HP, try landing any last hit
		elseif (not I:LowMana() and I:WasRecentlyDamagedByAnyHero(1.0)) or I:LowHealth() then
			AoELocation = I:UseAoEAbility(ability, I:GetLocation(), castRange, radius, delay, damage, damageType, creeps);
			if AoELocation.count > 0 then
				return BOT_ACTION_DESIRE_LOW;
			end
		end
	end

	-- If farming, use aoe to get multiple last hits
	if activeMode == BOT_MODE_FARM then
		AoELocation = I:UseAoEAbility(ability, I:GetLocation(), castRange, radius, delay, damage, damageType, creeps);
		if AoELocation.count >= 2 then
			return BOT_ACTION_DESIRE_LOW;
		end
	end

	-- If pushing/defending, clear wave
	if activeMode >= BOT_MODE_PUSH_TOWER_TOP and
		activeMode <= BOT_MODE_DEFEND_TOWER_BOT then
		AoELocation = I:UseAoEAbility(ability, I:GetLocation(), castRange, radius, delay, 0, damageType, creeps);
			if AoELocation.count >= 2 then
			return BOT_ACTION_DESIRE_LOW;
		end
	end

	-- Add if not BOT_MODE_RETREAT, go ahead if can hit multiple heroes
	if activeMode ~= BOT_MODE_LANING and activeMode ~= BOT_MODE_RETREAT then
		AoELocation = I:UseAoEAbility(ability, I:GetLocation(), castRange, radius, delay, 0, damageType, enemys);
		if AoELocation.count >= 3 then
			return BOT_ACTION_DESIRE_LOW; 
		end
	end
	
	-- If attacking, just go
	if activeMode == BOT_MODE_LANING or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK then
		local target = I:GetTarget();
		if target ~= nil and 
			GetUnitToUnitDistance(I, target) < radius then
			AoELocation = I:UseAoEAbility(ability, I:GetLocation(), castRange, radius, delay, 0, damageType, {target});
			if AoELocation.count > 0 then
		 		return BOT_ACTION_DESIRE_MODERATE; 
		 	end
		end
	end

	return BOT_ACTION_DESIRE_NONE;
end

function ConsiderNoTargetStun(I, ability, radius, fTimeInFuture)
	if not ability:IsFullyCastable() or not I:CanCast() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	local target;
	local activeMode = I:GetActiveMode();
	
	local castRange = 0;
	local delay = ability:GetCastPoint() + fTimeInFuture;
	local damage = 0;
	local damageType = ability:GetDamageType();
	
	-- GetNearby sorts units from close to far
	-- ***When to use enemys vs channelingEnemys?
	-- ***I guess use channelingEnemys in the enemy must die situation?
	local enemys = I:GetNearbyHeroes(castRange+radius,true,BOT_MODE_NONE);
	local channelingEnemys = {};
	for i, enemy in ipairs(enemys) do
		if enemy:IsChanneling() then
			table.insert(channelingEnemys, enemy);
		end
	end
	
	-- Interrupt channeling within 1s walking
	target = I:UseTargetAbility(ability, radius, 0, damageType, channelingEnemys);
	if target ~= nil then
		return BOT_ACTION_DESIRE_HIGH;
	end

	-- If fighting, stun lowHP/strongest carry/best disabler that is not already disabled
	if activeMode ~= BOT_MODE_RETREAT then
		local disabler = I:UseTargetAbility(ability, radius, 0, damageType, {utils.strongestDisabler(enemys, true)});
		if disabler ~= nil then
			return BOT_ACTION_DESIRE_HIGH;
		end
		local weakest = I:UseTargetAbility(ability, radius, 0, damageType, {utils.weakestUnit(enemys, true)});
		if weakest ~= nil then
			return BOT_ACTION_DESIRE_HIGH;
		end
		local strongest = I:UseTargetAbility(ability, radius, 0, damageType, {utils.strongestUnit(enemys, true)});
		if strongest ~= nil then
			return BOT_ACTION_DESIRE_HIGH;
		end
	end

	-- If retreating, stun closest enemy within immediate cast range
	if activeMode == BOT_MODE_RETREAT then
		target = I:UseTargetAbility(ability, radius, 0, damageType, enemys);
		if target ~= nil and not target:IsDisabled() then
			return BOT_ACTION_DESIRE_HIGH;
		end
	end

	-- If have target, go
	if activeMode == BOT_MODE_LANING or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK then
		target = I:UseTargetAbility(ability, radius, 0, damageType, {I:GetTarget()});
	 	if target ~= nil and not target:IsDisabled() then
		 	return BOT_ACTION_DESIRE_MODERATE;
		end
	end

	return BOT_ACTION_DESIRE_NONE;
end

function ConsiderNoTargetDebuff(I, ability, radius, fTimeInFuture)
	if not ability:IsFullyCastable() or not I:CanCast() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	local AoELocation;
	local activeMode = I:GetActiveMode();

	local castRange = 0; -- *** need testing for what range to use. dunno if 0 works
	local delay = ability:GetCastPoint() + fTimeInFuture;
	local damage = 0;
	local damageType = ability:GetDamageType();

	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange+radius,true,BOT_MODE_NONE);

	-- Add if not BOT_MODE_RETREAT, go ahead if can hit multiple heroes
	if activeMode ~= BOT_MODE_RETREAT then
		AoELocation = I:UseAoEAbility(ability, I:GetLocation(), castRange, radius, delay, 0, damageType, enemys);
		if AoELocation.count >= 3 then
			return BOT_ACTION_DESIRE_LOW; 
		end
	end
	
	if activeMode == BOT_MODE_RETREAT then
		AoELocation = I:UseAoEAbility(ability, I:GetLocation(), castRange, radius, delay, 0, damageType, enemys);
		if AoELocation.count > 0 then
			return BOT_ACTION_DESIRE_LOW; 
		end
	end


	-- If attacking, just go
	if activeMode == BOT_MODE_LANING or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK then
		local target = I:GetTarget();
		if target ~= nil and 
			GetUnitToUnitDistance(I, target) < radius then
			AoELocation = I:UseAoEAbility(ability, I:GetLocation(), castRange, radius, delay, 0, damageType, {target});
			if AoELocation.count > 0 then
		 		return BOT_ACTION_DESIRE_MODERATE; 
		 	end
		end
	end

	return BOT_ACTION_DESIRE_NONE;
end

function ConsiderNoTargetBuff(I, ability, radius, fTimeInFuture)
	if not ability:IsFullyCastable() or not I:CanCast() then
		return BOT_ACTION_DESIRE_NONE;
	end
	local activeMode = I:GetActiveMode();
	if activeMode == BOT_MODE_RETREAT or 
		activeMode == BOT_MODE_EVASIVE_MANEUVERS then 
		return BOT_ACTION_DESIRE_HIGH; 
	end

	local AoELocation;
	local activeMode = I:GetActiveMode();

	local castRange = 0; -- *** need testing for what range to use. dunno if 0 works
	local delay = ability:GetCastPoint() + fTimeInFuture;

	-- GetNearby sorts units from close to far
	local friends = {};
	if radius >= 1600 then 
		local friendlist = GetUnitList(UNIT_LIST_ALLIED_HEROES);
		for _, friend in ipairs(friendlist) do
			local friend = friendlist[i];
			if GetUnitToUnitDistance(I, friend) < radius then
				friends[#friends+1] = friend;
			end
		end
	else
		friends = I:GetNearbyHeroes(radius,false,BOT_MODE_NONE);
	end
	
	for _, friend in ipairs(friends) do
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

function ConsiderInvisibility(I, ability)
	if not ability:IsFullyCastable() or not I:CanCast() then
		return BOT_ACTION_DESIRE_NONE;
	end
	local activeMode = I:GetActiveMode();
	if activeMode == BOT_MODE_RETREAT or 
		activeMode == BOT_MODE_EVASIVE_MANEUVERS then 
		return BOT_ACTION_DESIRE_HIGH; 
	end
	local enemys = I:GetNearbyHeroes(1500,true,BOT_MODE_NONE);
	-- ***Use invis to walk up to enemy from outside of vision.. 1800
	
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
