require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local abilityGuide = {};

local function GetAbilityGuide(I)
	local spells, talents = I:GetAbilities(); --*** need test if unpack exist

	abilityGuide = {
		talents[8],
		talents[6],
		spells[4],
		spells[3],
		talents[3],
		spells[3],
		spells[3],
		spells[4],
		spells[2],
		talents[2],
		spells[2],
		spells[2],
		spells[1],
		spells[4],
		spells[1],
		spells[2],
		spells[1],
		spells[3],
		spells[1]
	};
end

function AbilityLevelUpThink()
	local I = GetBot();
	-- print(#abilityGuide)
	if I:GetAbilityPoints() == 0 then return; end
	if #abilityGuide == 0 then
		GetAbilityGuide(I);
	end
	local myLevel = I:GetLevel();
	local ability = I:GetAbilityByName(abilityGuide[#abilityGuide]);
	
	if  ability ~= nil and
		ability:CanAbilityBeUpgraded() and
		ability:GetHeroLevelRequiredToUpgrade() <= myLevel then
		local abilityLevel = ability:GetLevel();
		if ability:GetMaxLevel() > abilityLevel then
			I:ActionImmediate_LevelAbility(ability:GetName());
			I:DebugTalk("升级"..ability:GetName())
			table.remove(abilityGuide);
		else -- bugged, ability already max level
			table.remove(abilityGuide);
		end
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
