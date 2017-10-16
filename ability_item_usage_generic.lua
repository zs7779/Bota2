require(GetScriptDirectory() ..  "/utils")

-- ***circle aoe and point aoe are the same. circle aoe and no target are pretty much the same, need to pass in range as 0
-- ***1. aoe nuke         2. aoe stun         3. aoe debuff         4. aoe buff         5. aoe save
-- ***6. unit nuke        7. unit stun        8. unit debuff        9. unit buff        10. unit save
-- ***11. invis           12. blink

-- ***Generic logic:
-- ***Use unit nuke 1. enemy health low  2. harass  3. attack
-- ***Use unit stun 1. channeling  2. enemy health low  3. key hero  4. attack
-- ***Use aoe nuke 1. enemy health low  2. harass  3. defend/push  4. attack 
-- ***Use aoe stun 1. channeling  2. enemy health low  3. key hero  4. attack
-- ***Use debuff same as stun
-- ***Use buff 1. strongest friend  2. dealing maxHealth friend
-- ***Use save 1. weakest friend  2. disabled friend  3. slowed/silenced friend
-- ***Consider cancel channeling if mode changes

-- ***Point is pretty much like aoe.. just usually in cones or vectors
-- ***In the end probably all I:Get*() need to be moved to top level function, like in hero skill consider
-- ***For NoTarget AoE, probably 1. search in blink/walk distance 2. if current location is also okay, cancel walk kinda deal
-- AoE
function ConsiderAoENuke(I, spell, castRange, radius, maxHealth, spellType, delay)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE, nil};
	end
	local AoELocation;
	local activeMode = I:GetActiveMode();
	local myLocation = I:GetLocation();

	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange+radius,true,BOT_MODE_NONE);
	local creeps = I:GetNearbyCreeps(castRange+radius,true);

	-- AoE kill secure
	AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, maxHealth, spellType, enemys);
	if AoELocation.count > 0 then
		return {BOT_ACTION_DESIRE_HIGH, AoELocation.targetloc}; 
	end
	
	-- Laning last hit
	-- If high mana and high health, try last hit + harass enemy hero
	if activeMode == BOT_MODE_LANING then
		if not I:LowHealth() and not I:LowMana() then
			AoELocation = I:UseAoEHarass(spell, myLocation, castRange, radius, delay, maxHealth);
			if AoELocation.count > 0 then
				return {BOT_ACTION_DESIRE_MODERATE, AoELocation.targetloc};
			end
	-- If being harassed or low HP, try landing any last hit
		elseif (not I:LowMana() and I:WasRecentlyDamagedByAnyHero(1.0)) or I:LowHealth() then
			AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, maxHealth, spellType, creeps);
			print(AoELocation.count)
			if AoELocation.count > 0 then
				return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc}; 
			end
		end
	end

	-- If farming, use aoe to get multiple last hits
	if activeMode == BOT_MODE_FARM then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, maxHealth, spellType, creeps);
		if AoELocation.count >= 2 then
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc}; 
		end
	end

	-- If pushing/defending, clear wave
	if activeMode >= BOT_MODE_PUSH_TOWER_TOP and
		activeMode <= BOT_MODE_DEFEND_TOWER_BOT then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, spellType, creeps);
			if AoELocation.count >= 2 then
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc}; 
		end
	end

	-- Add if not BOT_MODE_RETREAT, go ahead if can hit multiple heroes
	if activeMode ~= BOT_MODE_LANING and activeMode ~= BOT_MODE_RETREAT then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, spellType, enemys);
		if AoELocation.count >= 3 then
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc};
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
			AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, spellType, {target});
			if AoELocation.count > 0 then
		 		return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc};
		 	end
		end
	end

	return {BOT_ACTION_DESIRE_NONE, nil};
end

function ConsiderAoEStun(I, spell, castRange, radius, delay)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE, nil};
	end
	local AoELocation;
	local activeMode = I:GetActiveMode();
	local myLocation = I:GetLocation();

	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange+radius,true,BOT_MODE_NONE);
	local movingEnemys = {}
	local channelingEnemys = {};
	for i, enemy in ipairs(enemys) do
		if enemy:IsChanneling() then
			table.insert(channelingEnemys, enemy);
		end
		if not enemy:IsImmobile() then
			table.insert(movingEnemys, enemy);
		end
	end
	
	-- Interrupt channeling
	AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, channelingEnemys);
	if AoELocation.count > 0 then
		return {BOT_ACTION_DESIRE_HIGH, AoELocation.targetloc};
	end

	-- If fighting, stun lowHP/strongest carry/best disabler that is not already disabled
	if activeMode ~= BOT_MODE_RETREAT then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, {utils.strongestDisabler(movingEnemys, true), utils.strongestUnit(movingEnemys, true), utils.weakestUnit(movingEnemys, true)});
		if AoELocation.count > 0 then
			return {BOT_ACTION_DESIRE_HIGH, AoELocation.targetloc};
		end
	end

	-- If retreating, stun closest enemy within immediate cast range
	if activeMode == BOT_MODE_RETREAT then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, movingEnemys);
		if AoELocation.count > 0 then
			return {BOT_ACTION_DESIRE_MODERATE, AoELocation.targetloc};
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
			GetUnitToUnitDistance(I, target) < castRange and
			not target:IsDisabled() then
			AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, {target});
			if AoELocation.count > 0 then
		 		return {BOT_ACTION_DESIRE_MODERATE, AoELocation.targetloc};
		 	end
		end
	end

	return {BOT_ACTION_DESIRE_NONE, nil};
end

function ConsiderAoEDebuff(I, spell, castRange, radius, delay)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE, nil};
	end
	local AoELocation;
	local activeMode = I:GetActiveMode();
	local myLocation = I:GetLocation();

	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange+radius,true,BOT_MODE_NONE);

	-- Add if not BOT_MODE_RETREAT, go ahead if can hit multiple heroes
	if activeMode ~= BOT_MODE_RETREAT then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, enemys);
		if AoELocation.count >= 3 then
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc};
		end
	end
	
	if activeMode == BOT_MODE_RETREAT then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, enemys);
		if AoELocation.count > 0 then
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc};
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
			AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, {target});
			if AoELocation.count > 0 then
		 		return {BOT_ACTION_DESIRE_MODERATE, AoELocation.targetloc};
		 	end
		end
	end

	return {BOT_ACTION_DESIRE_NONE, nil};
end

function ConsiderAoEBuff(I, spell, castRange, radius, delay)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE, nil};
	end
	local activeMode = I:GetActiveMode();
	local myLocation = I:GetLocation();

	-- GetNearby sorts units from close to far
	local friends;
	if radius >= 1600 then 
		friends = I:GetFarHeroes(radius,false,BOT_MODE_NONE);
	else
		friends = I:GetNearbyHeroes(radius,false,BOT_MODE_NONE); --<-- does GetNearby include yourself?
	end
	
	for _, friend in ipairs(friends) do
		local friendMode = friend:GetActiveMode();
		if friendMode == BOT_MODE_RETREAT or 
			friendMode == BOT_MODE_EVASIVE_MANEUVERS then
			AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, friends);
			if AoELocation.count > 0 then
				return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc};
			end
		end
		if friendMode == BOT_MODE_ROAM or
		 	friendMode == BOT_MODE_TEAM_ROAM or
		 	friendMode == BOT_MODE_DEFEND_ALLY or
		 	friendMode == BOT_MODE_ATTACK then
			local target = friend:GetTarget();
			AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, friends);
			if AoELocation.count > 0 and not I:LowMana() or AoELocation.count >= 2 then
				return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc};
			end
		end
	end

	return {BOT_ACTION_DESIRE_NONE, nil};
end

-- Unit
-- ***some unit target spells also have radius
function ConsiderUnitNuke(I, spell, castRange, radius, maxHealth, spellType)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE, nil};
	end
	local target;
	local activeMode = I:GetActiveMode();

	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange+radius,true,BOT_MODE_NONE);
	local creeps = I:GetNearbyCreeps(castRange+radius,true);
	
	-- Kill secure
	target = I:UseUnitSpell(spell, castRange, radius, maxHealth, spellType, enemys);
	if target ~= nil then
		return {BOT_ACTION_DESIRE_HIGH, target};
	end
	
	-- Laning last hit when being harassed or is low
	if activeMode == BOT_MODE_LANING then
		if (not I:LowMana() and I:WasRecentlyDamagedByAnyHero(1.0)) or I:LowHealth() then
			target = I:UseUnitSpell(spell, castRange, radius, maxHealth, spellType, creeps);
			if target ~= nil then
				return {BOT_ACTION_DESIRE_LOW, target};
			end
		end
	end
			
	-- If have target, go
	if activeMode == BOT_MODE_LANING or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK then
	 	target = I:UseUnitSpell(spell, castRange, radius, 0, spellType, {I:GetTarget()});
	 	if target ~= nil then
		 	return {BOT_ACTION_DESIRE_LOW, target};
		end
	end

	return {BOT_ACTION_DESIRE_NONE, nil};
end

function ConsiderUnitStun(I, spell, castRange, radius)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE, nil};
	end
	local target;
	local activeMode = I:GetActiveMode();
	
	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange+radius,true,BOT_MODE_NONE);
	local movingEnemys = {}
	local channelingEnemys = {};
	for i, enemy in ipairs(enemys) do
		if enemy:IsChanneling() then
			table.insert(channelingEnemys, enemy);
		end
		if not enemy:IsImmobile() then
			table.insert(movingEnemys, enemy);
		end
	end
	
	-- Interrupt channeling within 1s walking
	target = I:UseUnitSpell(spell, castRange, radius, 0, 0, channelingEnemys);
	if target ~= nil then
		return {BOT_ACTION_DESIRE_HIGH, target};
	end

	-- If fighting, stun lowHP/strongest carry/best disabler that is not already disabled
	if activeMode ~= BOT_MODE_RETREAT then
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, {utils.strongestDisabler(movingEnemys, true), utils.strongestUnit(movingEnemys, true), utils.weakestUnit(movingEnemys, true)});
		if target ~= nil then
			return {BOT_ACTION_DESIRE_HIGH, target};
		end
	end

	-- If retreating, stun closest enemy within immediate cast range
	if activeMode == BOT_MODE_RETREAT then
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, movingEnemys);
		if target ~= nil then
			return {BOT_ACTION_DESIRE_MODERATE, target};
		end
	end

	-- If have target, go
	if activeMode == BOT_MODE_LANING or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK then
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, {I:GetTarget()});
	 	if target ~= nil and not target:IsDisabled() then
		 	return {BOT_ACTION_DESIRE_MODERATE, target};
		end
	end

	return {BOT_ACTION_DESIRE_NONE, nil};
end

function ConsiderUnitDebuff(I, spell, castRange, radius)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE, nil};
	end
	local target;
	local activeMode = I:GetActiveMode();

	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange+radius,true,BOT_MODE_NONE);
	local movingEnemys = {}
	for i, enemy in ipairs(enemys) do
		if not enemy:IsImmobile() then
			table.insert(movingEnemys, enemy);
		end
	end

	-- If fighting, stun lowHP/strongest carry/best disabler that is not already disabled
	if activeMode ~= BOT_MODE_RETREAT then
		local target = I:UseUnitSpell(spell, castRange, radius, 0, 0, {utils.weakestUnit(movingEnemys, true), utils.strongestDisabler(movingEnemys, true), utils.strongestUnit(movingEnemys, true)});
		if target ~= nil then
			return {BOT_ACTION_DESIRE_MODERATE, target};
		end
	end

	-- If retreating, stun closest enemy within immediate cast range
	if activeMode == BOT_MODE_RETREAT then
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, movingEnemys);
		if target ~= nil then
			return {BOT_ACTION_DESIRE_LOW, target};
		end
	end

	-- If have target, go
	if activeMode == BOT_MODE_LANING or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK then
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, {I:GetTarget()});
	 	if target ~= nil and not target:IsDisabled() then
		 	return {BOT_ACTION_DESIRE_MODERATE, target};
		end
	end

	return {BOT_ACTION_DESIRE_NONE, nil};
end

function ConsiderUnitSave(I, spell, castRange, radius, maxHealth)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE, nil};
	end
	local target;
	local activeMode = I:GetActiveMode();
	if maxHealth == 0 then maxHealth = math.huge; end
	-- GetNearby sorts units from close to far
	local friends = {};
	if castRange >= 1600 then 
		friends = I:GetFarHeroes(castRange,false,BOT_MODE_NONE);
	else
		friends = I:GetNearbyHeroes(castRange,false,BOT_MODE_NONE);
	end
	
	for _, friend in ipairs(richestSort(friends)) do
		if friend:IsTrueHero() and friend:GetHealth() < maxHealth and
		    (friend:IsImmobile() or 
			friend:IsSilenced() or
			friend:WasRecentlyDamagedByAnyHero(1.0) or
			#(friend:GetIncomingTrackingProjectiles())>0) then
			target = I:UseUnitSpell(spell, castRange, radius, maxHealth, 0, {friend});
			if target ~= nil then
				return {BOT_ACTION_DESIRE_HIGH, target};
			end
		end
	end

	return {BOT_ACTION_DESIRE_NONE, nil};
end


function ConsiderInvis(I, spell)
	if not spell:IsFullyCastable() or not I:CanCast() or I:IsInvisible() then
		return BOT_ACTION_DESIRE_NONE;
	end
	local activeMode = I:GetActiveMode();
	if activeMode == BOT_MODE_RETREAT or 
		activeMode == BOT_MODE_EVASIVE_MANEUVERS then 
		return BOT_ACTION_DESIRE_LOW; -- invis is the last resource, not high priority 
	end
	local enemys = I:GetNearbyHeroes(1550,true,BOT_MODE_NONE);
	if (activeMode == BOT_MODE_ATTACK or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_RUNE or
		activeMode == BOT_MODE_WARD) and
		(not I:LowMana() or #enemys > 0) then
		return BOT_ACTION_DESIRE_LOW;
	end
	
	return BOT_ACTION_DESIRE_NONE;
end


function AbilityUsageThink()
	local I = GetBot();
	
end


BotsInit = require( "game/botsinit" );
local ability_item_usage_generic = BotsInit.CreateGeneric();
ability_item_usage_generic.ConsiderAoENuke = ConsiderAoENuke;
ability_item_usage_generic.ConsiderAoEStun = ConsiderAoEStun;
ability_item_usage_generic.ConsiderAoEDebuff = ConsiderAoEDebuff;
ability_item_usage_generic.ConsiderAoEBuff = ConsiderAoEBuff;
ability_item_usage_generic.ConsiderUnitNuke = ConsiderUnitNuke;
ability_item_usage_generic.ConsiderUnitStun = ConsiderUnitStun;
ability_item_usage_generic.ConsiderUnitDebuff = ConsiderUnitDebuff;
ability_item_usage_generic.ConsiderUnitSave = ConsiderUnitSave;
ability_item_usage_generic.ConsiderInvis = ConsiderInvis;
return ability_item_usage_generic;
