require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local function GetAbilityGuide(I)
	local spells, talents = I:GetAbilities(); --*** need test if unpack exist

	local abilityLevelUp = {};
	abilityLevelUp[1] = spells[1];
	abilityLevelUp[2] = spells[3];
	abilityLevelUp[3] = spells[1];
	abilityLevelUp[4] = spells[2];
	abilityLevelUp[5] = spells[1];
	abilityLevelUp[6] = spells[4];
	abilityLevelUp[7] = spells[1];
	abilityLevelUp[8] = spells[2];
	abilityLevelUp[9] = spells[2];
	abilityLevelUp[10] = talents[2];
	abilityLevelUp[11] = spells[2];
	abilityLevelUp[12] = spells[4];
	abilityLevelUp[13] = spells[3];
	abilityLevelUp[14] = spells[3];
	abilityLevelUp[15] = talents[3];
	abilityLevelUp[16] = spells[3];
	abilityLevelUp[18] = spells[4];
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
	-- print(convars)
	local I = GetBot();
	local spells = I:GetAbilities();
	
	local DragonSlave = I:GetAbilityByName(spells[1]);
	local LightStrikeArray = I:GetAbilityByName(spells[2]);
	local LagunaBlade = I:GetAbilityByName(spells[4]);
	
	local DragonSlaveDesire, DragonSlaveLoc = unpack(ConsiderDragonSlave(I, DragonSlave));
	local LightStrikeArrayDesire, LightStrikeArrayLoc = unpack(ConsiderLightStrikeArray(I, LightStrikeArray));
	local LagunaBladeDesire, LagunaBladeTarget = unpack(ConsiderLagunaBlade(I, LagunaBlade));

	if LightStrikeArrayDesire > BOT_ACTION_DESIRE_NONE then
		I:Action_UseAbilityOnLocation(LightStrikeArray, LightStrikeArrayLoc);
	end
	if LagunaBladeDesire > BOT_ACTION_DESIRE_NONE then
		I:Action_UseAbilityOnEntity(LagunaBlade, LagunaBladeTarget);
	end
	if DragonSlaveDesire > BOT_ACTION_DESIRE_NONE then
		I:Action_UseAbilityOnLocation(DragonSlave, DragonSlaveLoc);
	end
	
end

function ConsiderDragonSlave(I, spell)
	local castRange = spell:GetCastRange();
	local radius = spell:GetSpecialValueInt("dragon_slave_width_initial");
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = spell:GetCastPoint();
	return ability_item_usage_generic.ConsiderAoENuke(I, spell, castRange, radius, damage, spellType, delay);
end
function ConsiderLightStrikeArray(I, spell)
	local castRange = spell:GetCastRange();
	local radius = spell:GetSpecialValueInt("light_strike_array_aoe");
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = spell:GetSpecialValueInt("light_strike_array_delay_time")+spell:GetCastPoint();
	local considerStun = ability_item_usage_generic.ConsiderAoEStun(I, spell, castRange, radius, delay);
	if considerStun[1] > 0 then	return considerStun; end
	return ability_item_usage_generic.ConsiderAoENuke(I, spell, castRange, radius, damage, spellType, delay);
end

function ConsiderLagunaBlade(I, spell)
	local castRange = spell:GetCastRange();
	local radius = 0;
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = 0;
	return ability_item_usage_generic.ConsiderUnitNuke(I, spell, castRange, radius, damage, spellType);
end
