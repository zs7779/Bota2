require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

function GetAbilityGuide(I)
	local abilities, talents = I:GetAbilities();

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
	local abilities, talents = I:GetAbilities();
	
	local BreatheFire = I:GetAbilityByName(abilities[1]);
	local DragonTail = I:GetAbilityByName(abilities[2]);
	local ElderDragonForm = I:GetAbilityByName(abilities[4]);
	
	local BreatheFireDesire, BreatheFireLoc = ConsiderBreatheFire(I, BreatheFire);
	local DragonTailDesire, DragonTailTarget = ConsiderDragonTail(I, DragonTail);
	local ElderDragonFormDesire = ConsiderElderDragonForm(I, ElderDragonForm);

	if ElderDragonFormDesire > 0 then
		I:Action_UseAbility(ElderDragonForm);
	end
	if DragonTailDesire > 0 then
		I:Action_UseAbilityOnEntity(DragonTail, DragonTailTarget);
	end
	if BreatheFireDesire > 0 then
		I:Action_UseAbilityOnLocation(BreatheFire, BreatheFireLoc);
	end
	
end

function ConsiderBreatheFire(I, ability)
	return ability_item_usage_generic.ConsiderPointNuke(I, ability, ability:GetSpecialValueInt("end_radius"),0);
end
function ConsiderDragonTail(I, ability)
	return ability_item_usage_generic.ConsiderUnitStun(I, ability, 0);
end

function ConsiderElderDragonForm(I, ability)
	if not ability:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE;
	end
	local activeMode = I:GetActiveMode();

	-- Something something like if pushing and close to tower, of if attack and close to target
	if activeMode >= BOT_MODE_PUSH_TOWER_TOP and 
		activeMode <= BOT_MODE_PUSH_TOWER_BOT then
		local towers = GetNearbyTowers(500, true);
		if #towers > 0 then 
			return BOT_ACTION_DESIRE_MODERATE; 
		end
	end
	
	if activeMode == BOT_MODE_ROAM or
		 activeMode == BOT_MODE_TEAM_ROAM or
		 activeMode == BOT_MODE_DEFEND_ALLY or
		 activeMode == BOT_MODE_ATTACK then
		 local target = I:GetTarget();
		 if GetUnitToUnitDistance(I, target) <= 500 and not I:IsLow() then 
		 	return BOT_ACTION_DESIRE_MODERATE; 
		 end
	 end
	
	return BOT_ACTION_DESIRE_NONE;
end
