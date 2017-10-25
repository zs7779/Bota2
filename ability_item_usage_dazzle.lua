require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local abilityGuide = {};

local function GetAbilityGuide(I)
	local spells, talents = I:GetAbilities();

	abilityGuide = {
		talents[8],
		talents[5],
		spells[4],
		spells[1],
		talents[3],
		spells[1],
		spells[1],
		spells[4],
		talents[2],
		spells[2],
		spells[2],
		spells[2],
		spells[3],
		spells[4],
		spells[3],
		spells[2],
		spells[3],
		spells[1],
		spells[3]
	}
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
	return ability_item_usage_generic.ConsiderAoEBuff(I, spell, castRange, radius, 0);
end