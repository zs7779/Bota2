require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local abilityGuide = {};

function GetAbilityGuide(I)
	local spells, talents = I:GetAbilities(); 

	abilityGuide = {
		-- levels    =  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
		-- upgrade   =  2  3  2  1  3  4  2  3  2  T  3  4  1  1  T  1  -  4  -  T  -  -  -  -  T
		[spells[1]]  = {0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[2]]  = {1, 1, 2, 2, 2, 2, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[3]]  = {0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[4]]  = {0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3},
		[talents[1]] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		[talents[4]] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		[talents[5]] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
		[talents[7]] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
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
	
	local Gush = I:GetAbilityByName(spells[1]);
	local AnchorSmash = I:GetAbilityByName(spells[3]);
	local Ravage = I:GetAbilityByName(spells[4]);
	
	local GushDesire, GushTarget = unpack(ConsiderGush(I, Gush));
	local AnchorSmashDesire = unpack(ConsiderAnchorSmash(I, AnchorSmash));
	local RavageDesire = unpack(ConsiderRavage(I, Ravage));

	if RavageDesire > 0 then
		I:Action_UseAbility(Ravage);
	end
	if AnchorSmashDesire > 0 then
		I:Action_UseAbility(AnchorSmash);
	end
	if GushDesire > 0 then
		I:Action_UseAbilityOnEntity(Gush, GushTarget);
	end
	ability_item_usage_generic.SwapItemThink(I);
end

function ConsiderGush(I, spell)
	local castRange = spell:GetCastRange();
	local radius = 0;
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = 0;
	
	local considerDebuff = ability_item_usage_generic.ConsiderUnitDebuff(I, spell, castRange, radius);
	if considerDebuff[1] > 0 then return considerDebuff; end
	return ability_item_usage_generic.ConsiderUnitNuke(I, spell, castRange, radius, damage, spellType);
end

function ConsiderAnchorSmash(I, spell)
	local castRange = 0;
	local radius = spell:GetAOERadius();
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = 0;

	local considerNuke = ability_item_usage_generic.ConsiderAoENuke(I, spell, castRange, radius, damage, spellType, delay);
	if considerNuke[1] > 0 then return considerNuke; end
	return ability_item_usage_generic.ConsiderAoEDebuff(I, spell, castRange, radius, delay);
end

function ConsiderRavage(I, spell)
	local castRange = 0;
	local radius = spell:GetAOERadius();
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = 0;
	
	local considerStun = ability_item_usage_generic.ConsiderAoEStun(I, spell, castRange, radius, delay);
	if considerStun[1] > 0 then	return considerStun; end
	return ability_item_usage_generic.ConsiderAoENuke(I, spell, castRange, radius, damage, spellType, delay);
end
