require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local function GetAbilityGuide(I)
	local spells, talents = unpack(I:GetAbilities());

	local abilityLevelUp = {};
	abilityLevelUp[1] = spells[1];
	abilityLevelUp[2] = spells[3];
	abilityLevelUp[3] = spells[1];
	abilityLevelUp[4] = spells[2];
	abilityLevelUp[5] = spells[1];
	abilityLevelUp[6] = spells[4];
	abilityLevelUp[7] = spells[1];
	abilityLevelUp[8] = spells[3];
	abilityLevelUp[9] = spells[3];
	abilityLevelUp[10] = talents[2];
	abilityLevelUp[11] = spells[3];
	abilityLevelUp[12] = spells[4];
	abilityLevelUp[13] = spells[2];
	abilityLevelUp[14] = spells[2];
	abilityLevelUp[15] = talents[3];
	abilityLevelUp[16] = spells[2];
	abilityLevelUp[18] = spells[4];
	abilityLevelUp[20] = talents[6];
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
	local spells = I:GetAbilities()[1];
	
	local Burrowstrike = I:GetAbilityByName(spells[1]);
	local SandStorm = I:GetAbilityByName(spells[2]);
	local Epicenter = I:GetAbilityByName(spells[4]);
	-- print(spells[1],spells[2],spells[3],spells[4])
	local BurrowstrikeDesire, BurrowstrikeLoc = unpack(ConsiderBurrowstrike(I, Burrowstrike));
	local SandStormDesire = ConsiderSandStorm(I, SandStorm)[1];
	local EpicenterDesire = ConsiderEpicenter(I, Epicenter)[1];

	if BurrowstrikeDesire > 0 then
		I:Action_UseAbilityOnLocation(Burrowstrike, BurrowstrikeLoc);
	end
	if SandStormDesire > 0 then
		I:Action_UseAbility(SandStorm);
	end
	if EpicenterDesire > 0 then
		I:Action_UseAbility(Epicenter);
	end
	
end

function ConsiderBurrowstrike(I, spell)
	local castRange = spell:GetCastRange();
	local radius = spell:GetSpecialValueInt("burrow_width");
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = 0;
	
	local considerStun = ability_item_usage_generic.ConsiderAoEStun(I, spell, castRange, radius, delay);
	if considerStun[1] > 0 then	return considerStun; end
	return ability_item_usage_generic.ConsiderAoENuke(I, spell, castRange, radius, damage, spellType, delay);
	
end

function ConsiderSandStorm(I, spell)
	local castRange = 0;
	local radius = 0;
	local damage = 0;
	local spellType = 0;
	local delay = 0;
	return ability_item_usage_generic.ConsiderInvis(I, spell);
end

function ConsiderEpicenter(I, spell)
	local castRange = 0;
	local radius = spell:GetAOERadius();
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = spell:GetChannelTime();

	return ability_item_usage_generic.ConsiderAoENuke(I, spell, castRange, radius, damage, spellType, delay);
end
