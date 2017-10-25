require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local abilityGuide = {};

local function GetAbilityGuide(I)
	local spells, talents = I:GetAbilities(); --*** need test if unpack exist

	abilityGuide = {
		talents[8],
	 	talents[6],
	 	spells[4],
	 	spells[2],
	 	talents[4],
		spells[2],
		spells[2],
		spells[4],
		spells[3],
		talents[2],
		spells[3],
		spells[1],
		spells[1],
		spells[4],
		spells[2],
		spells[1],
		spells[3],
		spells[3],
		spells[1]
	};
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
