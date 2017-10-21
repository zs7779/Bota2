require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local function GetAbilityGuide(I)
	local spells, talents = I:GetAbilities();

	local abilityLevelUp = {};
	abilityLevelUp[1] = spells[3];
	abilityLevelUp[2] = spells[1];
	abilityLevelUp[3] = spells[3];
	abilityLevelUp[4] = spells[2];
	abilityLevelUp[5] = spells[3];
	abilityLevelUp[6] = spells[4];
	abilityLevelUp[7] = spells[3];
	abilityLevelUp[8] = spells[2];
	abilityLevelUp[9] = spells[2];
	abilityLevelUp[10] = spells[2];
	abilityLevelUp[11] = talents[2];
	abilityLevelUp[12] = spells[4];
	abilityLevelUp[13] = spells[1];
	abilityLevelUp[14] = spells[1];
	abilityLevelUp[15] = talents[3];
	abilityLevelUp[16] = spells[1];
	abilityLevelUp[18] = spells[4];
	abilityLevelUp[20] = talents[5];
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
	
end

function ConsiderPoisonTouch(I, spell)
	local castRange = spell:GetCastRange();
	local radius = 0;
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = 0;
	
	local considerStun = ability_item_usage_generic.ConsiderUnitStun(I, spell, castRange, radius);
	if considerStun[1] > 0 then	return considerStun; end
	return ability_item_usage_generic.ConsiderUnitNuke(I, spell, castRange, radius, damage, spellType);
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
	return ability_item_usage_generic.ConsiderAoEBuff(I, spell, castRange, radius, delay);
end