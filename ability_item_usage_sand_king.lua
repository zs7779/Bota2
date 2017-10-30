require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local abilityGuide = {};

local function GetAbilityGuide(I)
	local spells, talents = I:GetAbilities();

	abilityGuide = {
		talents[7],
		talents[6],
		spells[4],
		spells[2],
		talents[3],
		spells[2],
		spells[2],
		spells[4],
		spells[3],
		talents[2],
		spells[3],
		spells[3],
		spells[1],
		spells[4],
		spells[1],
		spells[2],
		spells[1],
		spells[3],
		spells[1]
	};
	return abilityLevelUp;
end

function AbilityLevelUpThink()
	local I = GetBot();
	-- print(#abilityGuide)
	if I:GetAbilityPoints() < 1 then return; end
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
			table.remove(abilityGuide);
		else -- bugged, ability already max level
			table.remove(abilityGuide);
		end
	end
end

function AbilityUsageThink()
	local I = GetBot();
	local spells = I:GetAbilities();
	
	local Burrowstrike = I:GetAbilityByName(spells[1]);
	local SandStorm = I:GetAbilityByName(spells[2]);
	local Epicenter = I:GetAbilityByName(spells[4]);
	-- print(spells[1],spells[2],spells[3],spells[4])
	local BurrowstrikeDesire, BurrowstrikeLoc = unpack(ConsiderBurrowstrike(I, Burrowstrike));
	local SandStormDesire = unpack(ConsiderSandStorm(I, SandStorm));
	local EpicenterDesire = unpack(ConsiderEpicenter(I, Epicenter));

	if BurrowstrikeDesire > 0 then
		I:Action_UseAbilityOnLocation(Burrowstrike, BurrowstrikeLoc);
	end
	if SandStormDesire > 0 then
		I:Action_UseAbility(SandStorm);
	end
	if EpicenterDesire > 0 then
		I:Action_UseAbility(Epicenter);
	end
	ability_item_usage_generic.SwapItemThink(I);	
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
	return ability_item_usage_generic.ConsiderInvis(I, spell, false);
end

function ConsiderEpicenter(I, spell)
	local castRange = 0;
	local radius = spell:GetAOERadius();
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = spell:GetChannelTime();

	return ability_item_usage_generic.ConsiderAoENuke(I, spell, castRange, radius, damage, spellType, delay);
end
