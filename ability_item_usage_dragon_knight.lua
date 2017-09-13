ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

function GetAbilityGuide(I)
	abilities, talents = I:GetAbilities();

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
	local BreatheFireDesire, BreatheFireLoc = ConsiderAoENuke(I, BreatheFire);
	local DragonTailDesire, DragonTailTarget = ConsiderUnitStun(I, DragonTail);

	if BreatheFireDesire > 0 then
		I:Action_UseAbilityOnLocation(BreatheFire,BreatheFireLoc);
	end
	if DragonTailDesire > 0 then
		I:Action_UseAbilityOnEntity(DragonTailDesire, DragonTailTarget);
	end
end


function ConsiderElderDragonForm(I, ability)
end