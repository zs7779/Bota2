ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

function GetAbilityGuide(I)
	local abilities, talents = I:GetAbilities();

	local abilityLevelUp = {};
	abilityLevelUp[1] = abilities[1];
	abilityLevelUp[2] = abilities[3];
	abilityLevelUp[3] = abilities[2];
	abilityLevelUp[4] = abilities[2];
	abilityLevelUp[5] = abilities[2];
	abilityLevelUp[6] = abilities[4];
	abilityLevelUp[7] = abilities[2];
	abilityLevelUp[8] = abilities[3];
	abilityLevelUp[9] = abilities[3];
	abilityLevelUp[10] = talents[1];
	abilityLevelUp[11] = abilities[3];
	abilityLevelUp[12] = abilities[4];
	abilityLevelUp[13] = abilities[1];
	abilityLevelUp[14] = abilities[1];
	abilityLevelUp[15] = talents[4];
	abilityLevelUp[16] = abilities[1];
	abilityLevelUp[18] = abilities[4];
	abilityLevelUp[20] = talents[5];
	abilityLevelUp[25] = talents[7];
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
	local abilities, talents = I:GetAbilities();
	
	local StormBolt = I:GetAbilityByName(abilities[1]);
	local Warcry = I:GetAbilityByName(abilities[3]);
	local GodsStrength = I:GetAbilityByName(abilities[4]);
	
	local StormBoltDesire, StormBoltTarget = ConsiderStormBoltDesire(I, StormBolt);
	local WarcryDesire = ConsiderWarcryDesire(I, Warcry);
	local GodsStrengthDesire = ConsiderGodsStrengthDesire(I, GodsStrength);

	if StormBoltDesire > 0 then
		I:Action_UseAbilityOnEntity(StormBolt, StormBoltTarget);
	end
	if WarcryDesire > 0 then
		I:Action_UseAbility(Warcry);
	end
	if GodsStrengthDesire > 0 then
		I:Action_UseAbility(GodsStrength);
	end
	
end

function ConsiderStormBolt(I, ability)
	return ConsiderUnitNuke(I, ability, ability:GetSpecialValueInt("bolt_aoe"));
end

function ConsiderWarcry(I, ability)
	return ConsiderNoTargetBuff(I, ability, ability:GetSpecialValueInt("warcry_radius"));
end

function ConsiderGodsStrength(I, ability)
	if not ability:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE;
	end
	local activeMode = I:GetActiveMode();

	-- Something something like if pushing and close to tower, of if attack and close to target
	if activeMode >= BOT_MODE_PUSH_TOWER_TOP and 
		activeMode <= BOT_MODE_PUSH_TOWER_BOT then
		local towers = GetNearbyTowers(500, true);
		if #towers > 0 then return BOT_ACTION_DESIRE_MODERATE; end
	end
	
	if activeMode == BOT_MODE_ROAM or
		 activeMode == BOT_MODE_TEAM_ROAM or
		 activeMode == BOT_MODE_DEFEND_ALLY or
		 activeMode == BOT_MODE_ATTACK then
		 local target = I:GetTarget();
		 if GetUnitToUnitDistance(I, target) <= 500 and not I:IsLow() then return BOT_ACTION_DESIRE_MODERATE; end
	 end
	
	return BOT_ACTION_DESIRE_NONE;
end
