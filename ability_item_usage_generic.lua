require(GetScriptDirectory() ..  "/utils")

function AoEHarass(I, spell, baseLocation, targetlocation, range, radius, delay)
	if range > 1580 then range = 1580; end
	local enemys = I:GetNearbyHeroes(range, true, BOT_MODE_NONE);

	if utils.CheckBit(spell:GetBehavior(), ABILITY_BEHAVIOR_AOE) then
		for _, enemy in ipairs(enemys) do
			local predLoc = enemy:PredictLocation(delay);
			if utils.GetLocationToLocationDistance(predLoc, targetlocation) < radius then
				return true;
			end
		end
	elseif utils.CheckBit(spell:GetBehavior(), ABILITY_BEHAVIOR_POINT) then
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
	if castRange > 1600 then castRange = 1600; end
	if radius > 1600 then radius = 1600; end
	local searchRadius = Min(castRange+radius, 1600);
	local enemys = I:GetNearbyHeroes(searchRadius,true,BOT_MODE_NONE);
	local creeps = I:GetNearbyCreeps(searchRadius,true);
	local laneCreeps = I:GetNearbyLaneCreeps(searchRadius,true);

	-- AoE kill secure
	AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, maxHealth, spellType, enemys, true);
	if AoELocation.count > 0 then
		I:DebugTalk("精致x"..AoELocation.count);
		return {BOT_ACTION_DESIRE_HIGH, AoELocation.targetloc}; 
	end
	
	-- If attacking, just go
	if  activeMode == BOT_MODE_ATTACK or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY then
		local target = I:UseUnitSpell(spell, castRange, radius, 0, spellType, {I:GetTarget()}, true);
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
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, maxHealth, spellType, creeps, true);
		if AoELocation.count >= 2 and not I:IsLowMana()  or
			AoELocation.count > 0 and
			(not I:IsLowMana() and 
			(I:WasRecentlyDamagedByAnyHero(1.0) or
			AoEHarass(I, spell, myLocation, AoELocation.targetloc, castRange, radius, delay)) or
			I:IsLowHealth()) then
			I:DebugTalk("补刀x"..AoELocation.count)
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc}; 
		end
	end

	-- If farming, use aoe to get multiple last hits
	if activeMode == BOT_MODE_FARM and not spell:IsUltimate() then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, maxHealth, spellType, creeps, true);
		if AoELocation.count >= 2 and not I:IsLowMana() or
			AoELocation.count > 0 and I:IsLowHealth() then
			I:DebugTalk("伐木x"..AoELocation.count)
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc}; 
		end
	end

	-- If pushing/defending, clear wave
	if activeMode >= BOT_MODE_PUSH_TOWER_TOP and
		activeMode <= BOT_MODE_DEFEND_TOWER_BOT and not spell:IsUltimate() then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, spellType, laneCreeps, true);
		if AoELocation.count >= 2 and not I:IsLowMana() or
			AoELocation.count > 0 and I:IsLowHealth() then
			I:DebugTalk("推线x"..AoELocation.count)
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc}; 
		end
	end

	-- Add if not BOT_MODE_RETREAT, go ahead if can hit multiple heroes
	if activeMode ~= BOT_MODE_LANING and activeMode ~= BOT_MODE_RETREAT and not spell:IsUltimate() then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, spellType, enemys, true);
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
	if castRange > 1600 then castRange = 1600; end
	if radius > 1600 then radius = 1600; end
	local searchRadius = Min(castRange+radius, 1600);
	local enemys = I:GetNearbyHeroes(searchRadius,true,BOT_MODE_NONE);
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
	AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, channelingEnemys, true);
	if  AoELocation.count > 0 and not spell:IsUltimate() then
		I:DebugTalk("打断x"..AoELocation.count)
		return {BOT_ACTION_DESIRE_HIGH, AoELocation.targetloc};
	end

	-- If fighting, stun lowHP/strongest carry/best disabler that is not already disabled
	if  activeMode == BOT_MODE_ATTACK or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, {utils.strongestDisabler(movingEnemys, true), utils.strongestUnit(movingEnemys, true), utils.weakestUnit(movingEnemys, true)}, true);

		if AoELocation.count > 0 then
			I:DebugTalk("控关键英雄x"..AoELocation.count)
			return {BOT_ACTION_DESIRE_HIGH, AoELocation.targetloc};
		end
		local target = I:UseUnitSpell(spell, castRange, radius, 0, 0, {I:GetTarget()}, true);
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
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, movingEnemys, true);
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

	if castRange > 1600 then castRange = 1600; end
	if radius > 1600 then radius = 1600; end
	local searchRadius = Min(castRange+radius, 1600);
	local enemys = I:GetNearbyHeroes(searchRadius,true,BOT_MODE_NONE);

	-- Add if not BOT_MODE_RETREAT, go ahead if can hit multiple heroes
	if activeMode ~= BOT_MODE_RETREAT then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, enemys, true);
		if AoELocation.count > 0 then
			I:DebugTalk("骚扰x"..AoELocation.count)
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc};
		end
	end
	
	-- If attacking, just go
	if  activeMode == BOT_MODE_ATTACK or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY then
		local target = I:UseUnitSpell(spell, castRange, radius, 0, 0, {I:GetTarget()}, true);
		if target ~= nil then
			I:DebugTalk("搞人x1")
			local AoELocation, stable = target:PredictLocation(delay);
			if stable then
	 			return {BOT_ACTION_DESIRE_LOW, AoELocation};
	 		end
		end
	end

	if activeMode == BOT_MODE_RETREAT then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, 0, enemys, true);
		if AoELocation.count > 0 and not spell:IsUltimate() then
			I:DebugTalk("随便搞x"..AoELocation.count)
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc};
		end
	end

	return {BOT_ACTION_DESIRE_NONE};
end

function ConsiderAoEBuff(I, spell, castRange, radius, maxHealth)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE};
	end
	local activeMode = I:GetActiveMode();
	local myLocation = I:GetLocation();

	-- GetNearby sorts units from close to far
	local friends = {};
	if radius >= 1600 then 
		friends = I:GetFarHeroes(radius,false,BOT_MODE_NONE);
	else
		friends = I:GetNearbyHeroes(radius,false,BOT_MODE_NONE); --<-- does GetNearby include yourself?
	end
	if #friends == 0 then
		return {BOT_ACTION_DESIRE_NONE};
	end
	local enemys = I:GetNearbyHeroes(1500,true,BOT_MODE_NONE);
	for _, friend in ipairs(friends) do
		local friendMode = friend:GetActiveMode();
		if friendMode == BOT_MODE_RETREAT or 
			friendMode == BOT_MODE_EVASIVE_MANEUVERS then
			AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, 0, maxHealth, 0, friends, false);
			if AoELocation.count > 0 and #enemys > 0 then
				I:DebugTalk("不舒服x"..AoELocation.count)
				return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc};
			end
		end
		if  friendMode == BOT_MODE_ATTACK or
		    friendMode == BOT_MODE_ROAM or
		 	friendMode == BOT_MODE_TEAM_ROAM or
		 	friendMode == BOT_MODE_DEFEND_ALLY then
			
			AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, 0, maxHealth, 0, friends, false);
			if AoELocation.count > 0 and #enemys > 0 and not I:IsLowMana() or AoELocation.count >= 2 then
				I:DebugTalk("加加加x"..AoELocation.count)
				return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc};
			end
		end
	end

	return {BOT_ACTION_DESIRE_NONE};
end

function ConsiderAoESave(I, spell, castRange, radius, maxHealth)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE};
	end
	if maxHealth == 0 then maxHealth = 100000; end
	local activeMode = I:GetActiveMode();
	local myLocation = I:GetLocation();

	-- GetNearby sorts units from close to far
	local friends = {};
	if radius >= 1600 then 
		friends = I:GetFarHeroes(radius,false,BOT_MODE_NONE);
	else
		friends = I:GetNearbyHeroes(radius,false,BOT_MODE_NONE); --<-- does GetNearby include yourself?
	end
	if #friends == 0 then
		return {BOT_ACTION_DESIRE_NONE};
	end
	local enemys = I:GetNearbyHeroes(1500,true,BOT_MODE_NONE);

	local friend = utils.weakestSort(friends)[1];
	if  friend:IsTrueHero() and friend:GetMaxHealth() - friend:GetHealth() > 220 and
	    (friend:IsImmobile() or 
		friend:IsSilenced() or
		friend:WasRecentlyDamagedByAnyHero(1.0) or
		#(friend:GetIncomingTrackingProjectiles())>0 or
		#enemys > 0 or
		friend:IsNoHealth() or
		not I:IsLowMana() and spell:IsSpammable()) then
		AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, maxHealth, 0, friends, false);
		if  AoELocation.count > 0 and (friend:IsNoHealth() or not I:IsLowMana() and spell:IsSpammable()) or
		    AoELocation.count >= 2 then
			I:DebugTalk("救人x"..AoELocation.count)
			return {BOT_ACTION_DESIRE_LOW, AoELocation.targetloc};
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
	if castRange > 1600 then castRange = 1600; end
	if radius > 1600 then radius = 1600; end
	local searchRadius = Min(castRange+radius, 1600);
	local enemys = I:GetNearbyHeroes(searchRadius,true,BOT_MODE_NONE);
	local creeps = I:GetNearbyCreeps(searchRadius,true);
	
	-- Kill secure
	target = I:UseUnitSpell(spell, castRange, radius, maxHealth, spellType, enemys, true);
	if target ~= nil then
		I:DebugTalk("精致")
		return {BOT_ACTION_DESIRE_HIGH, target};
	end
	
	-- If have target, go
	if  activeMode == BOT_MODE_ATTACK or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY then
	 	target = I:UseUnitSpell(spell, castRange, radius, 0, spellType, {I:GetTarget()}, true);
	 	if target ~= nil then
	 		I:DebugTalk("干人")
		 	return {BOT_ACTION_DESIRE_LOW, target};
		end
	end

	-- Laning last hit when being harassed or is low
	if activeMode == BOT_MODE_LANING and not spell:IsUltimate() then
		if (not I:IsLowMana() and I:WasRecentlyDamagedByAnyHero(1.0)) or I:IsLowHealth() then
			target = I:UseUnitSpell(spell, castRange, radius, maxHealth, spellType, creeps, true);
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
	if castRange > 1600 then castRange = 1600; end
	if radius > 1600 then radius = 1600; end
	local searchRadius = Min(castRange+radius, 1600);
	local enemys = I:GetNearbyHeroes(searchRadius,true,BOT_MODE_NONE);
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
	target = I:UseUnitSpell(spell, castRange, radius, 0, 0, channelingEnemys, true);
	if target ~= nil and not spell:IsUltimate() then
		I:DebugTalk("打断")
		return {BOT_ACTION_DESIRE_HIGH, target};
	end

	-- If fighting, stun lowHP/strongest carry/best disabler that is not already disabled
	if  activeMode == BOT_MODE_ATTACK or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY then
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, {utils.strongestDisabler(movingEnemys, true), utils.strongestUnit(movingEnemys, true), utils.weakestUnit(movingEnemys, true)}, true);
		if target ~= nil then
			I:DebugTalk("控关键英雄")
			return {BOT_ACTION_DESIRE_HIGH, target};
		end
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, {I:GetTarget()}, true);
	 	if target ~= nil and not target:IsDisabled() then
	 		I:DebugTalk("晕人")
		 	return {BOT_ACTION_DESIRE_MODERATE, target};
		end
	end

	-- If retreating, stun closest enemy within immediate cast range
	if activeMode == BOT_MODE_RETREAT and not spell:IsUltimate() then
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, movingEnemys, true);
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
	if castRange > 1600 then castRange = 1600; end
	if radius > 1600 then radius = 1600; end
	local searchRadius = Min(castRange+radius, 1600);
	local enemys = I:GetNearbyHeroes(searchRadius,true,BOT_MODE_NONE);
	local movingEnemys = {}
	for i, enemy in ipairs(enemys) do
		if not enemy:IsImmobile() then
			table.insert(movingEnemys, enemy);
		end
	end

	-- If fighting, stun lowHP/strongest carry/best disabler that is not already disabled
	if  activeMode == BOT_MODE_ATTACK or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY then
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, {utils.weakestUnit(movingEnemys, true), utils.strongestDisabler(movingEnemys, true), utils.strongestUnit(movingEnemys, true)}, true);
		if target ~= nil then
	 		I:DebugTalk("搞关键英雄")
			return {BOT_ACTION_DESIRE_MODERATE, target};
		end
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, {I:GetTarget()}, true);
	 	if target ~= nil and not target:IsDisabled() then
	 		I:DebugTalk("搞人")
		 	return {BOT_ACTION_DESIRE_MODERATE, target};
		end
	end

	-- If retreating, stun closest enemy within immediate cast range
	if activeMode == BOT_MODE_RETREAT then
		target = I:UseUnitSpell(spell, castRange, radius, 0, 0, movingEnemys, true);
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
	local activeMode = I:GetActiveMode();
	if maxHealth == 0 then maxHealth = 100000; end
	-- GetNearby sorts units from close to far
	local friends = {};
	if castRange >= 1600 then 
		friends = I:GetFarHeroes(castRange,false,BOT_MODE_NONE);
	else
		friends = I:GetNearbyHeroes(castRange,false,BOT_MODE_NONE);
	end
	if #friends == 0 then
		return {BOT_ACTION_DESIRE_NONE};
	end
	local enemys = I:GetNearbyHeroes(1500,true,BOT_MODE_NONE);
	local friend = utils.weakestSort(friends)[1];
	if maxHealth < 0 then
		maxHealth = friend:GetMaxHealth() - maxHealth;
	end
	if  friend:IsTrueHero() and friend:GetMaxHealth() - friend:GetHealth() > 220 and
	    (friend:IsImmobile() or 
		friend:IsSilenced() or
		friend:WasRecentlyDamagedByAnyHero(1.0) or
		#(friend:GetIncomingTrackingProjectiles())>0 or
		#enemys > 0 or
		friend:IsNoHealth() or
		not I:IsLowMana() and spell:IsSpammable()) then

		friend = I:UseUnitSpell(spell, castRange, radius, maxHealth, 0, {friend}, false);
		if friend ~= nil then
 			I:DebugTalk("救人")
			return {BOT_ACTION_DESIRE_HIGH, friend};
		end
	end
	

	return {BOT_ACTION_DESIRE_NONE};
end


function ConsiderInvis(I, spell, offensive)
	if not spell:IsFullyCastable() or not I:CanCast() or I:IsInvisible() then
		return {BOT_ACTION_DESIRE_NONE};
	end
	local enemys = I:GetNearbyHeroes(1200,true,BOT_MODE_NONE);

	local activeMode = I:GetActiveMode();
	if not offensive then
		if (activeMode == BOT_MODE_RETREAT or 
			activeMode == BOT_MODE_EVASIVE_MANEUVERS) and
		   (I:WasRecentlyDamagedByAnyHero(3.0) or #(I:GetIncomingTrackingProjectiles())>0) and
			#enemys > 0 then
	 		I:DebugTalk("无敌")
			return {BOT_ACTION_DESIRE_LOW}; -- invis is the last resource, not high priority 
		end
	end
	if offensive then
		if (activeMode == BOT_MODE_ATTACK or
			activeMode == BOT_MODE_ROAM or
			activeMode == BOT_MODE_TEAM_ROAM or
			activeMode == BOT_MODE_RUNE or
			activeMode == BOT_MODE_WARD) and
			#enemys > 0 then
	 		I:DebugTalk("隐身")
			return {BOT_ACTION_DESIRE_LOW};
		end
	end
	
	return {BOT_ACTION_DESIRE_NONE};
end

--*** I'm thinking if offensive blink can be simulated by aoe nuke
function ConsiderBlink(I, spell, distance)
	if not spell:IsFullyCastable() or not I:CanCast() or I:IsInvisible() then
		return {BOT_ACTION_DESIRE_NONE};
	end
	local activeMode = I:GetActiveMode();

	local enemys = I:GetNearbyHeroes(1200,true,BOT_MODE_NONE);
	local badPlace = utils.midPoint(enemys);
	
	if (activeMode == BOT_MODE_ATTACK or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_LANING) then
		-- save blink for the jump
		local target = I:UseUnitSpell(spell, dsitance, 0, 0, 0, {I:GetTarget()}, true);
		--*** find location that's close to target but far from other enemies <- dunno how to
		I:DebugTalk("跳跳")
		return {BOT_ACTION_DESIRE_HIGH, (target:GetLocation() - badPlace)/GetUnitToLocationDistance(target, badPlace)*200};
	end

	if (activeMode == BOT_MODE_RETREAT or
		activeMode == BOT_MODE_EVASIVE_MANEUVERS) and
	   (I:WasRecentlyDamagedByAnyHero(3.0) or #(I:GetIncomingTrackingProjectiles())>0) and
		#enemys > 0 then
		
 		I:DebugTalk("不舒服")
		return {BOT_ACTION_DESIRE_MODERATE, (I:GetLocation() - badPlace)/GetUnitToLocationDistance(I, badPlace)*distance};
	end
	
	if spell:GetCooldown() < 8 and
	   (activeMode == BOT_MODE_SECRET_SHOP or
		activeMode == BOT_MODE_SIDE_SHOP or
		activeMode == BOT_MODE_RUNE or
		activeMode == BOT_MODE_ASSEMBLE or
		activeMode == BOT_MODE_FARM or
		activeMode == BOT_MODE_WARD) and
		#enemys == 0 then
 		I:DebugTalk("赶路")
		return {BOT_ACTION_DESIRE_LOW, I:GetFacingVector()*distance}; -- ***<- it can't be distance. what can it be?
	end
end


function CourierUsageThink()
	local I = GetBot();
	local position = I:GetPlayerPosition();
	local courier;

	-- think of buying multiple couriers if human exist. only use last one
	if GetNumCouriers() > 0 then
		courier = GetCourier(0);
	end
	if courier == nil or
	   not I:IsTrueHero(true) or I:HasModifier("modifier_arc_warden_tempest_double") then
		return;
	end
	if not I.wantCourier and I:GetCourierValue() >= 400 or
	   position <= 3 and (courier:GetItem('item_tpscroll') or courier:GetItem('item_flask') or courier:GetItem('item_clarity')) or
	   DotaTime() > 480 and I:GetCourierValue() > 0 then
		I.wantCourier = true;
	else
		I.wantCourier = nil;
	end

	local state = GetCourierState(courier);
	if state == COURIER_STATE_DEAD then return; end
	if state == COURIER_STATE_IDLE or state == COURIER_STATE_AT_BASE or state == COURIER_STATE_RETURNING_TO_BASE then
		if courier.idleTime == nil then
			courier.idleTime = GameTime();
		end
	else
		courier.idleTime = nil;
	end

	if courier.idleTime and GameTime() - courier.idleTime > 3 then
		if I.secretShopMode and (I:GetActiveMode() ~= BOT_MODE_SECRET_SHOP or not I:IsAlive()) then
			I:ActionImmediate_Courier(courier, COURIER_ACTION_SECRET_SHOP);
		elseif I:IsAlive() and I.wantCourier and I:HaveSlot(true) then
			for P = 1,5 do
				if GetTeamMember(P).wantCourier and P < position then return; end
			end
			I:ActionImmediate_Courier(courier, COURIER_ACTION_TRANSFER_ITEMS);
		elseif state ~= COURIER_STATE_AT_BASE and state ~= COURIER_STATE_RETURNING_TO_BASE then
			I:ActionImmediate_Courier(courier, COURIER_ACTION_RETURN);
		elseif state == COURIER_STATE_AT_BASE and I:IsAlive() and I:GetStashValue() > 0 and courier:HaveSlot() then
			I:ActionImmediate_Courier(courier, COURIER_ACTION_TAKE_STASH_ITEMS);
		end
		return;
	end
end

function IsConsumable(item)
	local consumableGoods = {
		"item_smoke_of_deceit",
		"item_tpscroll",
		"item_enchanted_mango",
		"item_tango",
		"item_faerie_fire",
		"item_flask",
		"item_clarity"
	};
	for _, goody in ipairs(consumableGoods) do
		if item:GetName() == goody then
			return true;
		end
	end
	return false;
end
function IsBoot(item)
	if item:GetName():find("boots") ~= nil then
		return true;
	else
		return false;
	end
end
function IsRecipe(item)
	if item:GetName():find("recipe") ~= nil then
		return true;
	else
		return false;
	end
end

function SwapItemThink(I)
	if not I:IsTrueHero() then
		return;
	end
	if not I:HaveSlot() then
		for i = 6,8 do
			local item1 = I:GetItemInSlot(i);
			if item1 and IsBoot(item1) then
		   	    local minCost = 10000;
		   	    local minj = -1;
				for j = 0,5 do
					item2 = I:GetItemInSlot(j);
					if item2 then
						if IsConsumable(item2) or IsRecipe(item2) then
							I:ActionImmediate_SwapItems(i,j);
							return;
						end
						local cost = GetItemCost(item2:GetName());
						if cost < minCost then
							minCost = cost;
							minj = j;
						end
					end
				end
				if minj ~= -1 then
					I:ActionImmediate_SwapItems(i,minj);
					return;
				end
			end
		end
		for i = 6,8 do
			local item1 = I:GetItemInSlot(i);
			if item1 and not IsConsumable(item1) and not IsRecipe(item1) then
		   	    local minCost = GetItemCost(item1:GetName());
		   	    local minj = -1;
				for j = 0,5 do
					item2 = I:GetItemInSlot(j);
					if item2 then
						if IsConsumable(item2) or IsRecipe(item2) then
							I:ActionImmediate_SwapItems(i,j);
							return;
						end
						local cost = GetItemCost(item2:GetName());
						if IsBoot(item2) then cost = 10000; end
						if cost < minCost then
							minCost = cost;
							minj = j;
						end
					end
				end
				if minj ~= -1 then
					I:ActionImmediate_SwapItems(i,minj);
					return;
				end
			end
		end
	end
end



-- only check the ones bot dont use well
-- wand/stick/mana boot/armlet/soul ring/salve/mango/bottle/glimmer cape
-- maybe put manaboot and mek somewhere in assemble
function ItemUsageThinkTwice() -- <- because I can't program blink
	local I = GetBot();
	-- if not I:CanUseItem() or I:IsInvisible() then return; end
	-- for i = 0,5 do
	-- 	local item = I:GetItemInSlot(i);
	-- 	if item ~= nil and ConsiderItem[item:GetName()] ~= nil then
	-- 		ConsiderItem[item:GetName()](I, item);
	-- 	end
	-- end
end

local ConsiderItem = {};

ConsiderItem["item_tango"] = function(I,tango)
	local tangoCharge = tango:GetCurrentCharges();
	if I:GetMaxHealth() - I:GetHealth() > 100 and I:DistanceFromFountain() > 2000 then
		local trees = I:GetNearbyTrees(1200);
		if trees[1] ~= nil then
			I:Action_UseAbilityOnTree(tango, trees[1]); -- ** also consider not run toward enemy tower or something
		end
	end
end
ConsiderItem["item_tango_single"] = ConsiderItem["item_tango"];
ConsiderItem["item_faerie_fire"] = function(I, fire)
	if  I:GetHealth() < 100 or
		I:GetHealth() < 300 and
		(I:WasRecentlyDamagedByAnyHero(1.0) or
		#(I:GetIncomingTrackingProjectiles()) > 0) then
		I:Action_UseAbility(fire);
	end
end
ConsiderItem["item_enchanted_mango"] = function(I,mango)
	local activeMode = I:GetActiveMode();
	if  activeMode == BOT_MODE_ATTACK or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY then
		local target = I:GetTarget();
		if  ValidTarget(target) and
			I:EstimateDamageToTarget(target) and
			I:GetComboMana() - I:GetMana() <= 150 and
			I:GetMaxMana() - I:GetMana() <= 150 then
			I:Action_UseAbility(mango);
		end
	end
	-- ***also consider blink/speed boost/invis/tp abilities
end
ConsiderItem["item_soul_ring"] = ConsiderItem["item_enchanted_mango"];
ConsiderItem["item_magic_stick"] = function(I, stick)
	ConsiderItem["item_faerie_fire"](I, stick);
	if boots:IsFullyCastable() and I:CanUseItem() and not I:IsInvisible() then
		ConsiderItem["item_enchanted_mango"](I, stick);
	end
	if boots:IsFullyCastable() and I:CanUseItem() and not I:IsInvisible() then
		local stickRegen = stick:GetCurrentCharges() * 15;
		if (utils.LowHealth(I:GetHealth(), I:GetMaxHealth()) or utils.LowMana(I:GetMana(), I:GetMaxMana())) and
		   (not utils.LowHealth(I:GetHealth()+stickRegen, I:GetMaxHealth()) and not utils.LowMana(I:GetMana()+stickRegen, I:GetMaxMana())) then
		   I:Action_UseAbility(stick);
		end
	end
	
end
ConsiderItem["item_magic_wand"] = ConsiderItem["item_magic_stick"];
ConsiderItem["item_cheese"] = function(I, cheese)
	local activeMode = I:GetActiveMode();
	if  activeMode == BOT_MODE_ATTACK or
		activeMode == BOT_MODE_ROAM or
		activeMode == BOT_MODE_TEAM_ROAM or
		activeMode == BOT_MODE_DEFEND_ALLY then
		local target = I:GetTarget();
		if  ValidTarget(target) and
			I:GetComboDamageToTarget(target) and
			I:IsNoMana() then
			I:Action_UseAbility(cheese);
			return;
		end
	end
	if (activeMode == BOT_MODE_RETREAT or
		activeMode == BOT_MODE_EVASIVE_MANEUVERS) and
	   (I:WasRecentlyDamagedByAnyHero(3.0) or #(I:GetIncomingTrackingProjectiles())>0) and
		#enemys > 0 then
		I:Action_UseAbility(cheese);
	end
end


ConsiderItem["item_quelling_blade"] = function(I, chop)
	-- ***consider monkey and treant
	if not IsLocationPassable(I:ClosestBuilding():GetLocation()) then
		for _, tree in ipairs(GetNearbyTrees(200)) do
			if IsFacingLocation(GetTreeLocation(tree), 36) then
				I:Action_UseAbilityOnTree(chop, tree);
				return;
			end
		end
	end
end
ConsiderItem["item_bfury"] = ConsiderItem["item_quelling_blade"];
ConsiderItem["item_iron_talon"] = function(I, talon)
	if I:GetActiveMode() == BOT_MODE_FARM then
		local creeps = utils.weakestSort(I:GetNearbyCreeps(500));
		I:Action_UseAbilityOnEntity(talon, creeps[#creeps]);
		return;
	end
	ConsiderItem["item_quelling_blade"](I, talon);
end


ConsiderItem["item_arcane_boots"] = function(I, boots)
	if I:GetComboMana() - I:GetMana() <= 250 and
	   I:GetMaxMana() - I:GetMana() <= 250 then
	   I:Action_UseAbility(boots);
	end
end
ConsiderItem["item_mekansm"] = function(I, mekansm)
	if ConsiderAoESave(I, mekansm, 0, 900, -300) > 0 then
		I:Action_UseAbility(mekansm);
		return;
	end
end
ConsiderItem["item_guardian_greaves"] = function(I, boots)
	ConsiderItem["item_mekansm"](I, boots);
	if boots:IsFullyCastable() and I:CanUseItem() and not I:IsInvisible() then
		ConsiderItem["item_arcane_boots"](I, boots);
	end
end

ConsiderItem["item_crimson_guard"] = function(I, crimson)
	if ConsiderAoEBuff(I, mekansm, 0, 900, -50) > 0 then
		I:Action_UseAbility(mekansm);
		return;
	end
end
ConsiderItem["item_hood_of_defiance"] = function(I, hood)
	if ConsiderAoEBuff(I, hood, 0, 900, -50) > 0 then
		I:Action_UseAbility(hood);
		return;
	end
end
ConsiderItem["item_pipe"] = function(I, pipe)
	if ConsiderAoEBuff(I, pipe, 0, 900, -50) > 0 then
		I:Action_UseAbility(pipe);
		return;
	end
end

-- ConsiderItem["item_urn_of_shadows"]
-- ConsiderItem["item_veil_of_discord"]
-- ConsiderItem["item_dagon"]
-- ConsiderItem["item_dagon_2"]
-- ConsiderItem["item_dagon_3"]
-- ConsiderItem["item_dagon_4"]
-- ConsiderItem["item_dagon_5"]
-- ConsiderItem["item_shivas_guard"]


-- ConsiderItem["item_shadow_amulet"]
-- ConsiderItem["item_invis_sword"]
-- ConsiderItem["item_silver_edge"]


-- ConsiderItem["item_black_king_bar"]
-- ConsiderItem["item_blade_mail"]
-- ConsiderItem["item_manta"]
-- ConsiderItem["item_bloodstone"]
-- ConsiderItem["item_satanic"]
-- ConsiderItem["item_armlet"]


-- ConsiderItem["item_phase_boots"]
-- ConsiderItem["item_mask_of_madness"]
-- ConsiderItem["item_butterfly"]


-- ConsiderItem["item_force_staff"]
-- ConsiderItem["item_hurricane_pike"]


-- ConsiderItem["item_cyclone"]
-- ConsiderItem["item_diffusal_blade"]
-- ConsiderItem["item_diffusal_blade_2"]
-- ConsiderItem["item_rod_of_atos"]
-- ConsiderItem["item_orchid"]
-- ConsiderItem["item_bloodthorn"]
-- ConsiderItem["item_abyssal_blade"]
-- ConsiderItem["item_sheepstick"]


-- ConsiderItem["item_ethereal_blade"]
-- ConsiderItem["item_ghost"]
-- ConsiderItem["item_glimmer_cape"]
-- ConsiderItem["item_lotus_orb"]
-- ConsiderItem["item_medallion_of_courage"]
-- ConsiderItem["item_heavens_halberd"]
-- ConsiderItem["item_solar_crest"]
-- ConsiderItem["item_mjollnir"]


-- ConsiderItem["item_necronomicon"]
-- ConsiderItem["item_necronomicon_2"]
-- ConsiderItem["item_necronomicon_3"]

-- ConsiderItem["item_radiance"]
-- ConsiderItem["item_refresher"]


-- ConsiderItem["item_hand_of_midas"]
-- ConsiderItem["item_helm_of_the_dominator"]

-- -- Unimplemented
-- ConsiderItem["item_flask"]
-- ConsiderItem["item_clarity"]
-- ConsiderItem["item_bottle"]
-- ConsiderItem["item_blink"]
-- ConsiderItem["item_power_treads"]
-- ConsiderItem["item_smoke_of_deceit"]
-- ConsiderItem["item_tpscroll"]
-- ConsiderItem["item_travel_boots"]
-- ConsiderItem["item_travel_boots_2"]
-- ConsiderItem["item_ward_observer"]
-- ConsiderItem["item_ward_sentry"]


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
ability_item_usage_generic.SwapItemThink = SwapItemThink;
return ability_item_usage_generic;