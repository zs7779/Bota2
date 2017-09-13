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
end

function COnsiderDragonTail(I, ability)
end

function ConsiderElderDragonForm(I, ability)
end