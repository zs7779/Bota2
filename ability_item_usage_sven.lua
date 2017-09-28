require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

function GetAbilityGuide(I)
	local spells, talents = table.unpack(I:GetAbilities());

	local abilityLevelUp = {};
	abilityLevelUp[1] = spells[1];
	abilityLevelUp[2] = spells[3];
	abilityLevelUp[3] = spells[2];
	abilityLevelUp[4] = spells[2];
	abilityLevelUp[5] = spells[2];
	abilityLevelUp[6] = spells[4];
	abilityLevelUp[7] = spells[2];
	abilityLevelUp[8] = spells[3];
	abilityLevelUp[9] = spells[3];
	abilityLevelUp[10] = talents[1];
	abilityLevelUp[11] = spells[3];
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
	local abilities, talents = I:GetAbilities();
	
	local StormBolt = I:GetAbilityByName(abilities[1]);
	local Warcry = I:GetAbilityByName(abilities[3]);
	local GodsStrength = I:GetAbilityByName(abilities[4]);
	
	local StormBoltDesire, StormBoltTarget = table.unpack(ConsiderStormBolt(I, StormBolt));
	local WarcryDesire = ConsiderWarcry(I, Warcry)[1];
	local GodsStrengthDesire = ConsiderGodsStrength(I, GodsStrength);

	if StormBoltDesire > 0 then
		I:Action_UseAbilityOnEntity(StormBolt, StormBoltTarget);
	end
	if WarcryDesire > 0 then
		I:Action_UseAbility(Warcry);
	end
	if GodsStrengthDesire > 0 then
		I:Action_UseAbility(GodsStrength);
	end
	
end

function ConsiderStormBolt(I, spell)
	local castRange = spell:GetCastRange();
	local radius = spell:GetSpecialValueInt("bolt_aoe");
	local damage = spell:GetAbilityDamage();
	local spellType = GetDamageType();
	local delay = 0;
	
	local considerStun = ability_item_usage_generic.ConsiderUnitStun(I, spell, castRange, radius);
	if considerStun[1] > 0 then	return considerStun; end
	return ability_item_usage_generic.ConsiderUnitNuke(I, spell, castRange, radius, damage, spellType);

	
end

function ConsiderWarcry(I, spell)
	local castRange = spell:GetCastRange();
	local radius = spell:GetSpecialValueInt("warcry_radius");
	local damage = 0;
	local spellType = 0;
	local delay = 0;
	return ability_item_usage_generic.ConsiderAoEBuff(I, spell, castRange, radius, delay);
end

function ConsiderGodsStrength(I, spell)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	local activeMode = I:GetActiveMode();

	-- Something something like if pushing and close to tower, of if attack and close to target
	if activeMode >= BOT_MODE_PUSH_TOWER_TOP and 
		activeMode <= BOT_MODE_PUSH_TOWER_BOT then
		local towers = GetNearbyTowers(500, true);
		if #towers > 0 then 
			return BOT_ACTION_DESIRE_MODERATE; 
		end
	end
	
	if activeMode == BOT_MODE_ROAM or
		 activeMode == BOT_MODE_TEAM_ROAM or
		 activeMode == BOT_MODE_DEFEND_ALLY or
		 activeMode == BOT_MODE_ATTACK then
		 local target = I:GetTarget();
		 if GetUnitToUnitDistance(I, target) <= 300 then 
		 	return BOT_ACTION_DESIRE_MODERATE;
		 end
	 end
	
	return BOT_ACTION_DESIRE_NONE;
end
