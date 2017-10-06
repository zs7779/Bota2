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
	local abilities, talents = unpack(I:GetAbilities());
	
	local Gush = I:GetAbilityByName(abilities[1]);
	local AnchorSmash = I:GetAbilityByName(abilities[3]);
	local Ravage = I:GetAbilityByName(abilities[4]);
	
	local GushDesire, GushTarget = unpack(ConsiderGush(I, Gush));
	local AnchorSmashDesire = ConsiderAnchorSmash(I, AnchorSmash)[1];
	local RavageDesire = ConsiderRavage(I, Ravage);

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
	local castRange = 0;
	local radius = spell:GetSpecialValueInt("radius");
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = 0;

	local considerNuke = ability_item_usage_generic.ConsiderAoENuke(I, spell, castRange, radius, damage, spellType, delay);
	if considerNuke[1] > 0 then return considerNuke; end
	return ability_item_usage_generic.ConsiderAoEDebuff(I, spell, castRange, radius, delay);
end

function ConsiderRavage(I, spell)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	local castRange = 0;
	local radius = spell:GetSpecialValueInt("radius");
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = 0;

	local activeMode = I:GetActiveMode();
	local myLocation = I:GetLocation();

	local enemys = I:GetNearbyHeroes(castRange+radius,true,BOT_MODE_NONE);
	local targetEnemys = {}
	for i, enemy in ipairs(enemys) do
		if not enemy:IsImmobile() then
			table.insert(targetEnemys, enemy);
		end
	end

	-- KS
	AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, damage, spellType, enemys);
	if AoELocation.count >= 2 then
		return BOT_ACTION_DESIRE_HIGH;
	end

	AoELocation = I:UseAoESpell(spell, myLocation, castRange, radius, delay, 0, spellType, {utils.strongestDisabler(targetEnemys, true), utils.strongestUnit(targetEnemys, true), utils.weakestUnit(targetEnemys, true)});
	if (activeMode == BOT_MODE_ATTACK or
		activeMode == BOT_MODE_TEAM_ROAM) and
		AoELocation.count >= 2 then
		return math.max(BOT_ACTION_DESIRE_MODERATE+AoELocation.count/10, BOT_ACTION_DESIRE_ABSOLUTE);
	elseif (activeMode == BOT_MODE_DEFEND_ALLY or
		activeMode == BOT_MODE_RETREAT) and AoELocation.count >= 4 then
		return BOT_ACTION_DESIRE_MODERATE;
	end
	
	return BOT_ACTION_DESIRE_NONE;
end
