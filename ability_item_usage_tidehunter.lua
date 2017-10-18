require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local function GetAbilityGuide(I)
	local spells, talents = unpack(I:GetAbilities());

	local abilityLevelUp = {};
	abilityLevelUp[1] = spells[2];
	abilityLevelUp[2] = spells[3];
	abilityLevelUp[3] = spells[3];
	abilityLevelUp[4] = spells[2];
	abilityLevelUp[5] = spells[3];
	abilityLevelUp[6] = spells[4];
	abilityLevelUp[7] = spells[3];
	abilityLevelUp[8] = spells[1];
	abilityLevelUp[9] = spells[2];
	abilityLevelUp[10] = talents[1];
	abilityLevelUp[11] = spells[2];
	abilityLevelUp[12] = spells[4];
	abilityLevelUp[13] = spells[1];
	abilityLevelUp[14] = spells[1];
	abilityLevelUp[15] = talents[4];
	abilityLevelUp[16] = spells[1];
	abilityLevelUp[18] = spells[4];
	abilityLevelUp[20] = talents[5];
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
	
	local Gush = I:GetAbilityByName(spells[1]);
	local AnchorSmash = I:GetAbilityByName(spells[3]);
	local Ravage = I:GetAbilityByName(spells[4]);
	
	local GushDesire, GushTarget = unpack(ConsiderGush(I, Gush));
	local AnchorSmashDesire = ConsiderAnchorSmash(I, AnchorSmash)[1];
	local RavageDesire = ConsiderRavage(I, Ravage)[1];

	if RavageDesire > 0 then
		I:Action_UseAbility(Ravage);
	end
	if AnchorSmashDesire > 0 then
		I:Action_UseAbility(AnchorSmash);
	end
	if GushDesire > 0 then
		I:Action_UseAbilityOnEntity(Gush, GushTarget);
	end
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
	local castRange = 50;
	local radius = spell:GetAOERadius();
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = 0;

	local considerNuke = ability_item_usage_generic.ConsiderAoENuke(I, spell, castRange, radius, damage, spellType, delay);
	if considerNuke[1] > 0 then return considerNuke; end
	return ability_item_usage_generic.ConsiderAoEDebuff(I, spell, castRange, radius, delay);
end

function ConsiderRavage(I, spell)
	local castRange = 50;
	local radius = spell:GetAOERadius();
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = 0;
	
	local considerStun = ability_item_usage_generic.ConsiderAoEStun(I, spell, castRange, radius, delay);
	if considerStun[1] > 0 then	return considerStun; end
	return ability_item_usage_generic.ConsiderAoENuke(I, spell, castRange, radius, damage, spellType, delay);
end
