require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local abilityGuide = {};

function GetAbilityGuide(I)
	local spells, talents = I:GetAbilities(); 

	abilityGuide = {
		--   levels  =  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
		--   upgrade =  1  3  1  2  1  4  1  2  2  T  2  4  3  3  T  3  -  4  -  T  -  -  -  -  T
		[spells[1]]  = {1, 1, 2, 2, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[2]]  = {0, 0, 0, 1, 1, 1, 1, 2, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[3]]  = {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[4]]  = {0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3},
		[talents[2]] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		[talents[3]] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		[talents[6]] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
		[talents[8]] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
	};
end

function GetNextUpgrade(I, level)
	for abilityName, abilityLevel in pairs(abilityGuide) do
		if abilityName ~= nil then
			local ability = I:GetAbilityByName(abilityName);
			if ability:CanAbilityBeUpgraded() and
		   	   ability:GetHeroLevelRequiredToUpgrade() <= level and
		   	   ability:GetLevel() < abilityLevel[level] then
		   	   return abilityName;
		   	end
		end
	end
	return nil;
end

function AbilityLevelUpThink()
	local I = GetBot();
	-- print(#abilityGuide)
	if I:GetAbilityPoints() < 1 then return; end
	if #abilityGuide == 0 then
		GetAbilityGuide(I);
	end
	local upgradeAbility = GetNextUpgrade(I, I:GetLevel());
	
	if upgradeAbility ~= nil then
		I:ActionImmediate_LevelAbility(upgradeAbility);
	end
end

function AbilityUsageThink()
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
	ability_item_usage_generic.SwapItemThink(I);	
end

function ConsiderDragonSlave(I, spell)
	local castRange = spell:GetCastRange();
	local radius = spell:GetSpecialValueInt("dragon_slave_width_end");
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = spell:GetCastPoint();
	
	return ability_item_usage_generic.ConsiderAoENuke(I, spell, castRange, radius, damage, spellType, delay);
end
function ConsiderLightStrikeArray(I, spell)
	local castRange = spell:GetCastRange();
	local radius = spell:GetSpecialValueInt("light_strike_array_aoe");
	local damage = spell:GetSpecialValueInt("light_strike_array_damage");
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
