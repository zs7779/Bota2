require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local abilityGuide = {};

function GetAbilityGuide(I)
	local spells, talents = I:GetAbilities(); 

	abilityGuide = {
		--   levels  =  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
		--   upgrade =  3  1  3  2  3  4  3  2  2  T  2  4  1  1  T  1  -  4  -  T  -  -  -  -  T
		[spells[1]]  = {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[2]]  = {0, 0, 0, 1, 1, 1, 1, 2, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[3]]  = {1, 1, 2, 2, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
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
	
	local PoisonTouch = I:GetAbilityByName(spells[1]);
	local ShallowGrave = I:GetAbilityByName(spells[2]);
	local ShadowWave = I:GetAbilityByName(spells[3]);
	local Weave = I:GetAbilityByName(spells[4]);
	
	local PoisonTouchDesire, PoisonTouchTarget = unpack(ConsiderPoisonTouch(I, PoisonTouch));
	local ShallowGraveDesire, ShallowGraveTarget = unpack(ConsiderShallowGrave(I, ShallowGrave));
	local ShadowWaveDesire, ShadowWaveTarget = unpack(ConsiderShadowWave(I, ShadowWave));
	local WeaveDesire, WeaveLoc = unpack(ConsiderWeave(I, Weave));

	if PoisonTouchDesire > 0 then
		I:Action_UseAbilityOnEntity(PoisonTouch, PoisonTouchTarget);
	end
	if ShallowGraveDesire > 0 then
		I:Action_UseAbilityOnEntity(ShallowGrave, ShallowGraveTarget);
	end
	if ShadowWaveDesire > 0 then
		I:Action_UseAbilityOnEntity(ShadowWave, ShadowWaveTarget);
	end
	if WeaveDesire > 0 then
		I:Action_UseAbilityOnLocation(Weave, WeaveLoc);
	end
	ability_item_usage_generic.SwapItemThink(I);
end

function ConsiderPoisonTouch(I, spell)
	local castRange = spell:GetCastRange();
	local radius = 0;
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = 0;
	
	return ability_item_usage_generic.ConsiderUnitDebuff(I, spell, castRange, radius);
end

function ConsiderShallowGrave(I, spell)
	local castRange = spell:GetCastRange();
	local radius = 0;
	local damage = 0;
	local spellType = 0;
	local delay = 0;
	-- *** consider closeby enemys
	return ability_item_usage_generic.ConsiderUnitSave(I, spell, castRange, radius, 300);
end

function ConsiderShadowWave(I, spell)
	local castRange = spell:GetCastRange();
	local radius = spell:GetSpecialValueInt("damage_radius");
	local damage = spell:GetSpecialValueInt("damage");
	local spellType = spell:GetDamageType();
	local delay = 0;
	
	local considerHeal = ability_item_usage_generic.ConsiderUnitSave(I, spell, castRange, radius, -damage*2);
	if considerHeal[1] > 0 then	return considerHeal; end
	-- *** consider heal bomb. told you dazzle is hard
	return ability_item_usage_generic.ConsiderUnitSave(I, spell, castRange, radius, 300);
end

function ConsiderWeave(I, spell)
	local castRange = spell:GetCastRange();
	local radius = spell:GetAOERadius();
	local damage = 0;
	local spellType = 0;
	local delay = 0;
	considerDebuff = ability_item_usage_generic.ConsiderAoEDebuff(I, spell, castRange, radius, delay);
	if considerDebuff[1] > 0 then return considerDebuff; end
	return ability_item_usage_generic.ConsiderAoEBuff(I, spell, castRange, radius, 0);
end