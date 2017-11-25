require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local abilityGuide = {};

function GetAbilityGuide(I)
	local spells, talents = I:GetAbilities(); 

	abilityGuide = {
		--   levels  =  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
		-- u  pgrade =  1  3  1  3  2  4  1  1  3  T  3  4  2  2  T  2  -  4  -  T  -  -  -  -  T
		[spells[1]]  = {1, 1, 2, 2, 2, 2, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[2]]  = {0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[3]]  = {0, 1, 1, 2, 2, 2, 2, 2, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[4]]  = {0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3},
		[talents[2]] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		[talents[4]] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
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
	
	local BreatheFire = I:GetAbilityByName(spells[1]);
	local DragonTail = I:GetAbilityByName(spells[2]);
	local ElderDragonForm = I:GetAbilityByName(spells[4]);
	
	local BreatheFireDesire, BreatheFireLoc = unpack(ConsiderBreatheFire(I, BreatheFire));
	local DragonTailDesire, DragonTailTarget = unpack(ConsiderDragonTail(I, DragonTail));
	local ElderDragonFormDesire = unpack(ConsiderElderDragonForm(I, ElderDragonForm));

	if ElderDragonFormDesire > 0 then
		I:Action_UseAbility(ElderDragonForm);
	end
	if DragonTailDesire > 0 then
		I:Action_UseAbilityOnEntity(DragonTail, DragonTailTarget);
	end
	if BreatheFireDesire > 0 then
		I:Action_UseAbilityOnLocation(BreatheFire, BreatheFireLoc);
	end
	ability_item_usage_generic.SwapItemThink(I);
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
		return {BOT_ACTION_DESIRE_NONE};
	end
	local activeMode = I:GetActiveMode();

	-- Something something like if pushing and close to tower, of if attack and close to target
	if activeMode >= BOT_MODE_PUSH_TOWER_TOP and 
		activeMode <= BOT_MODE_PUSH_TOWER_BOT then
		local towers = I:GetNearbyTowers(400, true);
		if #towers > 0 then 
			return {BOT_ACTION_DESIRE_MODERATE}; 
		end
	end
	
	if activeMode == BOT_MODE_ROAM or
		 activeMode == BOT_MODE_TEAM_ROAM or
		 activeMode == BOT_MODE_ATTACK then
		 local target = I:UseUnitSpell(spell, 300, 0, 0, 0, {I:GetTarget()});
		 if utils.GetLocationToLocationDistance(self:GetLocation(), unit:GetLocation()) <= 300 and not I:IsLow() then 
		 	return {BOT_ACTION_DESIRE_MODERATE}; 
		 end
	 end
	
	return {BOT_ACTION_DESIRE_NONE};
end
