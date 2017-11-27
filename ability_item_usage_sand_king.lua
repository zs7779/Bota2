require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local abilityGuide = {};

function GetAbilityGuide(I)
	local spells, talents = I:GetAbilities(); 

	abilityGuide = {
		--   levels  =  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
		--   upgrade =  1  3  1  2  1  2  1  2  2  T  4  4  3  3  T  3  -  4  -  T  -  -  -  -  T
		[spells[1]]  = {1, 1, 2, 2, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[2]]  = {0, 0, 0, 1, 1, 2, 2, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[3]]  = {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[4]]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3},
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
