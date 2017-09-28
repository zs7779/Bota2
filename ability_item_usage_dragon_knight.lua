require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local function GetAbilityGuide(I)
	local spells, talents = table.unpack(I:GetAbilities()); --*** need test if unpack exist
	local abilityLevelUp = {};
	abilityLevelUp[1] = spells[1];
	abilityLevelUp[2] = spells[3];
	abilityLevelUp[3] = spells[3];
	abilityLevelUp[4] = spells[1];
	abilityLevelUp[5] = spells[2];
	abilityLevelUp[6] = spells[4];
	abilityLevelUp[7] = spells[1];
	abilityLevelUp[8] = spells[1];
	abilityLevelUp[9] = spells[3];
	abilityLevelUp[10] = talents[2];
	abilityLevelUp[11] = spells[3];
	abilityLevelUp[12] = spells[4];
	abilityLevelUp[13] = spells[2];
	abilityLevelUp[14] = spells[2];
	abilityLevelUp[15] = talents[4];
	abilityLevelUp[16] = spells[2];
	abilityLevelUp[18] = spells[4];
	abilityLevelUp[20] = talents[6];
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
	local spells, talents = I:GetAbilities();
	
	local BreatheFire = I:GetAbilityByName(spells[1]);
	local DragonTail = I:GetAbilityByName(spells[2]);
	local ElderDragonForm = I:GetAbilityByName(spells[4]);
	
	local BreatheFireDesire, BreatheFireLoc = table.unpack(ConsiderBreatheFire(I, BreatheFire));
	local DragonTailDesire, DragonTailTarget = table.unpack(ConsiderDragonTail(I, DragonTail));
	local ElderDragonFormDesire = table.unpack(ConsiderElderDragonForm(I, ElderDragonForm));

	if ElderDragonFormDesire > 0 then
		I:Action_UseAbility(ElderDragonForm);
	end
	if DragonTailDesire > 0 then
		I:Action_UseAbilityOnEntity(DragonTail, DragonTailTarget);
	end
	if BreatheFireDesire > 0 then
		I:Action_UseAbilityOnLocation(BreatheFire, BreatheFireLoc);
	end
	
end

function ConsiderBreatheFire(I, spell)
	local castRange = spell:GetCastRange();
	local radius = spell:GetSpecialValueInt("end_radius");
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = 0;
	return ability_item_usage_generic.ConsiderAoENuke(I, spell, castRange, radius, damage, spellType, delay);
end
function ConsiderDragonTail(I, spell)
	local castRange = spell:GetCastRange();
	local radius = 0;
	local damage = 0; -- I don't consider it as a damage spell
	local spellType = 0;
	local delay = 0;
	return ability_item_usage_generic.ConsiderUnitStun(I, spell, castRange, radius);
end

function ConsiderElderDragonForm(I, spell)
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
		 if GetUnitToUnitDistance(I, target) <= 500 and not I:IsLow() then 
		 	return BOT_ACTION_DESIRE_MODERATE; 
		 end
	 end
	
	return BOT_ACTION_DESIRE_NONE;
end
