require(GetScriptDirectory() ..  "/utils")

function AoEHarass(I, spell, baseLocation, targetlocation, range, radius, delay)
	if range > 1580 then range = 1580; end
	local enemys = I:GetNearbyHeroes(range, true, BOT_MODE_NONE);

	if utils.CheckFlag(spell:GetBehavior(), ABILITY_BEHAVIOR_AOE) then
		for _, enemy in ipairs(enemys) do
			local predLoc = enemy:PredictLocation(delay);
			if utils.GetLocationToLocationDistance(predLoc, targetlocation) < radius then
				return true;
			end
		end
	elseif utils.CheckFlag(spell:GetBehavior(), ABILITY_BEHAVIOR_POINT) then
		for _, enemy in ipairs(enemys) do
			local predLoc = enemy:PredictLocation(delay);
			local distToLine = PointToLineDistance(baseLocation, targetlocation, predLoc);
			if distToLine.within and distToLine.distance < radius then
				return true;
			end
		end
	end
	
	return false;
end

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

-- ***No target abilities don't work. I might as well...

-- ***All MODE_RETEAT need also have MODE_ASSEMBLE for shrines! right now is on TEAM_ROAM

-- AoE
function ConsiderAoENuke(I, spell, castRange, radius, maxHealth, spellType, delay)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE};
	end
	local AoELocation;
	local activeMode = I:GetActiveMode();
	local myLocation = I:GetLocation();

	-- GetNearby sorts units from close to far
	if castRange >= 1600 then castRange = 1580; end
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);
	local creeps = I:GetNearbyCreeps(castRange,true);
	local laneCreeps = I:GetNearbyLaneCreeps(castRange,true);

	-- AoE kill secure
	AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, maxHealth, spellType, enemys);
	if AoELocation.count > 0 then
		I:DebugTalk("精致x"..AoELocation.count);
		return {BOT_ACTION_DESIRE_HIGH, AoELocation.targetloc}; 
	end
	
	-- If attacking, just go
	if activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK then
		local target = I:UseUnitSpell(spell, castRange, radius, 0, spellType, {I:GetTarget()});
		if target ~= nil then
			I:DebugTalk("干人x1")
			local AoELocation, stable = target:PredictLocation(delay);
			if stable then
	 			return {BOT_ACTION_DESIRE_LOW, AoELocation};
	 		end
		end
	end

	-- Laning last hit
	-- If high mana and high health, try last hit + harass enemy hero
	if activeMode == BOT_MODE_LANING and not spell:IsUltimate() then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, maxHealth, spellType, creeps);
		if AoELocation.count >= 2 and not I:LowMana()  or
			AoELocation.count > 0 and
			(not I:LowMana() and 
				(I:WasRecentlyDamagedByAnyHero(1.0) or
					AoEHarass(I, spell, myLocation, AoELocation.targetloc, castRange, radius, delay)) or
			I:LowHealth()) then
			I:DebugTalk("补刀x"..AoELocation.count)
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc}; 
		end
	end

	-- If farming, use aoe to get multiple last hits
	if activeMode == BOT_MODE_FARM and not spell:IsUltimate() then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, maxHealth, spellType, creeps);
		if AoELocation.count >= 2 and not I:LowMana() or
			AoELocation.count > 0 and I:LowHealth() then
			I:DebugTalk("伐木x"..AoELocation.count)
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc}; 
		end
	end

	-- If pushing/defending, clear wave
	if activeMode >= BOT_MODE_PUSH_TOWER_TOP and
		activeMode <= BOT_MODE_DEFEND_TOWER_BOT and not spell:IsUltimate() then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, spellType, laneCreeps);
		if AoELocation.count >= 2 and not I:LowMana() or
			AoELocation.count > 0 and I:LowHealth() then
			I:DebugTalk("推线x"..AoELocation.count)
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc}; 
		end
	end

	-- Add if not BOT_MODE_RETREAT, go ahead if can hit multiple heroes
	if activeMode ~= BOT_MODE_LANING and activeMode ~= BOT_MODE_RETREAT and not spell:IsUltimate() then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, spellType, enemys);
		if AoELocation.count >= 3 then
			I:DebugTalk("耗血x"..AoELocation.count)
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc};
		end
	end

	return {BOT_ACTION_DESIRE_NONE};
end

function ConsiderAoEStun(I, spell, castRange, radius, delay)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE};
	end
	local AoELocation;
	local activeMode = I:GetActiveMode();
	local myLocation = I:GetLocation();

	-- GetNearby sorts units from close to far
	if castRange >= 1600 then castRange = 1580; end
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);
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
	if AoELocation.count > 0 and
		(not spell:IsUltimate() or activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK) then
		I:DebugTalk("打断x"..AoELocation.count)
		return {BOT_ACTION_DESIRE_HIGH, AoELocation.targetloc};
	end

	-- If fighting, stun lowHP/strongest carry/best disabler that is not already disabled
	if activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, {utils.strongestDisabler(movingEnemys, true), utils.strongestUnit(movingEnemys, true), utils.weakestUnit(movingEnemys, true)});
		if(spell:GetName()=="tidehunter_ravage") then
			print(AoELocation.count,#{utils.strongestDisabler(movingEnemys, true), utils.strongestUnit(movingEnemys, true), utils.weakestUnit(movingEnemys, true)})
		end
		if AoELocation.count > 0 then
			I:DebugTalk("控关键英雄x"..AoELocation.count)
			return {BOT_ACTION_DESIRE_HIGH, AoELocation.targetloc};
		end
		local target = I:UseUnitSpell(spell, castRange, radius, 0, 0, {I:GetTarget()});
		if target ~= nil then
			I:DebugTalk("晕人x1")
			local AoELocation, stable = target:PredictLocation(delay);
			if stable then
	 			return {BOT_ACTION_DESIRE_MODERATE, AoELocation};
	 		end
		end
	end

	-- If retreating, stun closest enemy within immediate cast range
	if activeMode == BOT_MODE_RETREAT then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, movingEnemys);
		if AoELocation.count > 0 and not spell:IsUltimate() then
			I:DebugTalk("随便控x"..AoELocation.count)
			return {BOT_ACTION_DESIRE_MODERATE, AoELocation.targetloc};
		end
	end

	return {BOT_ACTION_DESIRE_NONE};
end

function ConsiderAoEDebuff(I, spell, castRange, radius, delay)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE};
	end
	local AoELocation;
	local activeMode = I:GetActiveMode();
	local myLocation = I:GetLocation();

	if castRange >= 1600 then castRange = 1580; end
	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);

	-- Add if not BOT_MODE_RETREAT, go ahead if can hit multiple heroes
	if activeMode ~= BOT_MODE_RETREAT then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, enemys);
		if AoELocation.count > 0 then
			I:DebugTalk("骚扰x"..AoELocation.count)
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc};
		end
	end
	
	-- If attacking, just go
	if activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK then
		local target = I:UseUnitSpell(spell, castRange, radius, 0, 0, {I:GetTarget()});
		if target ~= nil then
			I:DebugTalk("搞人x1")
			local AoELocation, stable = target:PredictLocation(delay);
			if stable then
	 			return {BOT_ACTION_DESIRE_LOW, AoELocation};
	 		end
		end
	end

	if activeMode == BOT_MODE_RETREAT then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, enemys);
		if AoELocation.count > 0 and not spell:IsUltimate() then
			I:DebugTalk("随便搞x"..AoELocation.count)
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc};
		end
	end

	return {BOT_ACTION_DESIRE_NONE};
end

function ConsiderAoEBuff(I, spell, castRange, radius, delay)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE};
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
	friends[#friends+1] = I;
	
	for _, friend in ipairs(friends) do
		local friendMode = friend:GetActiveMode();
		if friendMode == BOT_MODE_RETREAT or 
			friendMode == BOT_MODE_EVASIVE_MANEUVERS then
			AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, friends);
			if AoELocation.count > 0 and #(I:GetNearbyHeroes(1580,true,BOT_MODE_NONE)) > 0 then
				I:DebugTalk("不舒服x"..AoELocation.count)
				return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc};
			end
		end
		if friendMode == BOT_MODE_ROAM or
		 	friendMode == BOT_MODE_TEAM_ROAM or
		 	friendMode == BOT_MODE_DEFEND_ALLY or
		 	friendMode == BOT_MODE_ATTACK then
			
			AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, friends);
			if AoELocation.count > 0 and not I:LowMana() or AoELocation.count >= 2 then
				I:DebugTalk("加加加x"..AoELocation.count)
				return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc};
			end
		end
	end

	return {BOT_ACTION_DESIRE_NONE};
end

-- Unit
-- ***some unit target spells also have radius
function ConsiderUnitNuke(I, spell, castRange, radius, maxHealth, spellType)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE};
	end
	local target;
	local activeMode = I:GetActiveMode();

	-- GetNearby sorts units from close to far
	if castRange >= 1600 then castRange = 1580; end
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);
	local creeps = I:GetNearbyCreeps(castRange,true);
	
	-- Kill secure
	target = I:UseUnitSpell(spell, castRange, radius, maxHealth, spellType, enemys);
	if target ~= nil then
		I:DebugTalk("精致")
		return {BOT_ACTION_DESIRE_HIGH, target};
	end
	
	-- If have target, go
	if activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK then
	 	target = I:UseUnitSpell(spell, castRange, radius, 0, spellType, {I:GetTarget()});
	 	if target ~= nil then
	 		I:DebugTalk("干人")
		 	return {BOT_ACTION_DESIRE_LOW, target};
		end
	end

	-- Laning last hit when being harassed or is low
	if activeMode == BOT_MODE_LANING and not spell:IsUltimate() then
		if (not I:LowMana() and I:WasRecentlyDamagedByAnyHero(1.0)) or I:LowHealth() then
			target = I:UseUnitSpell(spell, castRange, radius, maxHealth, spellType, creeps);
			if target ~= nil then
				I:DebugTalk("补刀")
				return {BOT_ACTION_DESIRE_LOW, target};
			end
		end
	end

	return {BOT_ACTION_DESIRE_NONE};
end

function ConsiderUnitStun(I, spell, castRange, radius)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE};
	end
	local target;
	local activeMode = I:GetActiveMode();
	
	-- GetNearby sorts units from close to far
	if castRange >= 1600 then castRange = 1580; end
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);
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
	if target ~= nil and
		(not spell:IsUltimate() or activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK) then
		I:DebugTalk("打断")
		return {BOT_ACTION_DESIRE_HIGH, target};
	end

	-- If fighting, stun lowHP/strongest carry/best disabler that is not already disabled
	if activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK then
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, {utils.strongestDisabler(movingEnemys, true), utils.strongestUnit(movingEnemys, true), utils.weakestUnit(movingEnemys, true)});
		if target ~= nil then
			I:DebugTalk("控关键英雄")
			return {BOT_ACTION_DESIRE_HIGH, target};
		end
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, {I:GetTarget()});
	 	if target ~= nil and not target:IsDisabled() then
	 		I:DebugTalk("晕人")
		 	return {BOT_ACTION_DESIRE_MODERATE, target};
		end
	end

	-- If retreating, stun closest enemy within immediate cast range
	if activeMode == BOT_MODE_RETREAT and not spell:IsUltimate() then
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, movingEnemys);
		if target ~= nil then
			I:DebugTalk("随便控")
			return {BOT_ACTION_DESIRE_MODERATE, target};
		end
	end

	return {BOT_ACTION_DESIRE_NONE};
end

function ConsiderUnitDebuff(I, spell, castRange, radius)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE};
	end
	local target;
	local activeMode = I:GetActiveMode();

	-- GetNearby sorts units from close to far
	if castRange >= 1600 then castRange = 1580; end
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);
	local movingEnemys = {}
	for i, enemy in ipairs(enemys) do
		if not enemy:IsImmobile() then
			table.insert(movingEnemys, enemy);
		end
	end

	-- If fighting, stun lowHP/strongest carry/best disabler that is not already disabled
	if activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_ATTACK then
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, {utils.weakestUnit(movingEnemys, true), utils.strongestDisabler(movingEnemys, true), utils.strongestUnit(movingEnemys, true)});
		if target ~= nil then
	 		I:DebugTalk("搞关键英雄")
			return {BOT_ACTION_DESIRE_MODERATE, target};
		end
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, {I:GetTarget()});
	 	if target ~= nil and not target:IsDisabled() then
	 		I:DebugTalk("搞人")
		 	return {BOT_ACTION_DESIRE_MODERATE, target};
		end
	end

	-- If retreating, stun closest enemy within immediate cast range
	if activeMode == BOT_MODE_RETREAT then
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, movingEnemys);
		if target ~= nil then
	 		I:DebugTalk("随便搞")
			return {BOT_ACTION_DESIRE_LOW, target};
		end
	end

	return {BOT_ACTION_DESIRE_NONE};
end

function ConsiderUnitSave(I, spell, castRange, radius, maxHealth)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE};
	end
	local target;
	local activeMode = I:GetActiveMode();
	if maxHealth == 0 then maxHealth = 100000; end
	-- GetNearby sorts units from close to far
	local friends = {};
	if castRange >= 1600 then 
		friends = I:GetFarHeroes(castRange,false,BOT_MODE_NONE);
	else
		friends = I:GetNearbyHeroes(castRange,false,BOT_MODE_NONE);
		friends[#friends+1] = I;
	end
	
	for _, friend in ipairs(richestSort(friends)) do
		if maxHealth < 0 then
			maxHealth = friend:GetMaxHealth() - maxHealth;
		end
		if friend:IsTrueHero() and friend:GetHealth() < maxHealth and
		    (friend:IsImmobile() or 
			friend:IsSilenced() or
			friend:WasRecentlyDamagedByAnyHero(1.0) or
			#(friend:GetIncomingTrackingProjectiles())>0) then
			target = I:UseUnitSpell(spell, castRange, radius, maxHealth, 0, {friend});
			if target ~= nil then
	 		I:DebugTalk("救人")
				return {BOT_ACTION_DESIRE_HIGH, target};
			end
		end
	end

	return {BOT_ACTION_DESIRE_NONE};
end


function ConsiderInvis(I, spell)
	if not spell:IsFullyCastable() or not I:CanCast() or I:IsInvisible() then
		return {BOT_ACTION_DESIRE_NONE, ""};
	end
	local enemys = I:GetNearbyHeroes(1200,true,BOT_MODE_NONE);

	local activeMode = I:GetActiveMode();
	if activeMode == BOT_MODE_RETREAT or 
		activeMode == BOT_MODE_EVASIVE_MANEUVERS and
		I:WasRecentlyDamagedByAnyHero(3.0) and
		#enemys > 0 then 
 		I:DebugTalk("无敌")
		return {BOT_ACTION_DESIRE_LOW}; -- invis is the last resource, not high priority 
	end
	
	if (activeMode == BOT_MODE_ATTACK or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_RUNE or
		activeMode == BOT_MODE_WARD) and
		#enemys > 0 then
 		I:DebugTalk("隐身")
		return {BOT_ACTION_DESIRE_LOW};
	end
	
	return {BOT_ACTION_DESIRE_NONE};
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
