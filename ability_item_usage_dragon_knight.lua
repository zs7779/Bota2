ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

function GetAbilities(I)
	local abilities = {};
	local talents = {};
	for i = 0,23 do
		local ability = I:GetAbilityInSlot(i);
		if ability ~= nil then
			if ability:IsTalent() then
				table.insert(talents, ability:GetName());
			else
				table.insert(abilities,ability:GetName());
			end
		end
	end
	return abilities, talents;
end

function GetAbilityGuide(I)
	abilities, talents = GetAbilities(I);

	local abilityLevelUp = {};
	abilityLevelUp[1] = abilities[1];
	abilityLevelUp[2] = abilities[3];
	abilityLevelUp[3] = abilities[3];
	abilityLevelUp[4] = abilities[1];
	abilityLevelUp[5] = abilities[2];
	abilityLevelUp[6] = abilities[4];
	abilityLevelUp[7] = abilities[1];
	abilityLevelUp[8] = abilities[1];
	abilityLevelUp[9] = abilities[3];
	abilityLevelUp[10] = talents[2];
	abilityLevelUp[11] = abilities[3];
	abilityLevelUp[12] = abilities[4];
	abilityLevelUp[13] = abilities[2];
	abilityLevelUp[14] = abilities[2];
	abilityLevelUp[15] = talents[4];
	abilityLevelUp[16] = abilities[2];
	abilityLevelUp[18] = abilities[4];
	abilityLevelUp[20] = talents[6];
	abilityLevelUp[25] = talents[8];
	return abilityLevelUp;
end

function AbilityLevelUpThink()
	local I = GetBot();
	if I:GetAbilityPoints() < 1 then return; end
	local guide = GetAbilityGuide(I);
	local myLevel = I:GetLevel();
	local ability = I:GetAbilityByName(guide[myLevel]);
	if ability ~= nil and ability:CanAbilityBeUpgraded() then
		I:ActionImmediate_LevelAbility(guide[myLevel]);
	end
end

function AbilityUsageThink()
	local I = GetBot();
	local abilities, talents = GetAbilities(I);
	BreatheFire = I:GetAbilityByName(abilities[1]);
	DragonTail = I:GetAbilityByName(abilities[2]);
	local BreatheFireDesire, BreatheFireLoc = ConsiderBreatheFire(I, BreatheFire);

	if BreatheFireDesire > 0 then
		I:Action_UseAbilityOnLocation(BreatheFire,BreatheFireLoc);
	end
end

function ConsiderBreatheFire(I, ability)
	local castRange = ability:GetCastRange();
	local damage = ability:GetAbilityDamage();
	local radius = ability:GetAOERadius();
	
	-- GetNearby sorts units from close to far
	local enemys = I:GetNearbyHeroes(castRange,true,BOT_MODE_NONE);
	local creeps = I:GetNearbyCreeps(castRange,true);
	
	-- Kill secure
	for _, enemy in pairs(enemys) do
		if ability_item_usage_generic.CanCastAbilityOnTarget(ability, enemy) and
			enemy:GetHealth() <= enemy:GetActualIncomingDamage(damage, DAMAGE_TYPE_MAGICAL) then
			return BOT_ACTION_DESIRE_HIGH, enemy:GetLocation();
		end
	end
	
	-- Laning last hit
	-- If enough mana and low health, try landing any last hit
	if I:GetActiveMode() == BOT_MODE_LANING then
		if not I:LowMana() and I:LowHealth() then
			local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, 0, damage );
			if AoELocation.count >= 1 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
		elseif not I:LowMana() then -- this logic is questionable.. what does maxHealth consider?
			local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, 0, damage );
			if AoELocation.count >= 2 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
		end
	end

	if I:GetActiveMode() == BOT_MODE_FARM then
		local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, 0, damage );
		if AoELocation.count >= 2 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
	end

	if I:GetActiveMode() == BOT_MODE_PUSH_TOWER_TOP or
		I:GetActiveMode() == BOT_MODE_PUSH_TOWER_MID or
	 	I:GetActiveMode() == BOT_MODE_PUSH_TOWER_BOT or
		I:GetActiveMode() == BOT_MODE_DEFEND_TOWER_TOP or
		I:GetActiveMode() == BOT_MODE_DEFEND_TOWER_MID or
		I:GetActiveMode() == BOT_MODE_DEFEND_TOWER_BOT then
		local AoELocation = I:FindAoELocation( true, false, I:GetLocation(), castRange, radius, 0, 0 );
		if AoELocation.count >= 2 then return BOT_ACTION_DESIRE_LOW, AoELocation.targetloc; end
	end

	if I:GetActiveMode() == BOT_MODE_ROAM or
		 I:GetActiveMode() == BOT_MODE_TEAM_ROAM or
		 I:GetActiveMode() == BOT_MODE_DEFEND_ALLY or
		 I:GetActiveMode() == BOT_MODE_ATTACK then
		 local target = I:GetTarget();
		 if target ~= nil and ability_item_usage_generic.CanCastAbilityOnTarget(ability, target) then
		 	return BOT_ACTION_DESIRE_MODERATE, target:GetLocation();
		 end
	end

	return BOT_ACTION_DESIRE_NONE, nil;
end