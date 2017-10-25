require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local abilityGuide = {};

local function GetAbilityGuide(I)
	local spells, talents = I:GetAbilities();

	abilityGuide = {
		talents[7],
		talents[5],
		spells[4],
		spells[1],
		talents[4],
		spells[1],
		spells[1],
		spells[4],
		spells[3],
		talents[1],
		spells[3],
		spells[3],
		spells[2],
		spells[4],
		spells[2],
		spells[2],
		spells[2],
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
	
	local StormBolt = I:GetAbilityByName(spells[1]);
	local Warcry = I:GetAbilityByName(spells[3]);
	local GodsStrength = I:GetAbilityByName(spells[4]);
	
	local StormBoltDesire, StormBoltTarget = unpack(ConsiderStormBolt(I, StormBolt));
	local WarcryDesire = unpack(ConsiderWarcry(I, Warcry));
	local GodsStrengthDesire = unpack(ConsiderGodsStrength(I, GodsStrength));

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
	local spellType = spell:GetDamageType();
	local delay = 0;
	local considerStun = ability_item_usage_generic.ConsiderUnitStun(I, spell, castRange, radius);
	if considerStun[1] > 0 then	return considerStun; end
	return ability_item_usage_generic.ConsiderUnitNuke(I, spell, castRange, radius, damage, spellType);

	
end

function ConsiderWarcry(I, spell)
	local castRange = 0;
	local radius = spell:GetSpecialValueInt("warcry_radius");
	local damage = 0;
	local spellType = 0;
	local delay = 0;
	return ability_item_usage_generic.ConsiderAoEBuff(I, spell, castRange, radius, 0);
end

function ConsiderGodsStrength(I, spell)
	if not spell:IsFullyCastable() or not I:CanCast() then
		return {BOT_ACTION_DESIRE_NONE};
	end
	local activeMode = I:GetActiveMode();

	-- Something something like if pushing and close to tower, of if attack and close to target
	if activeMode >= BOT_MODE_PUSH_TOWER_TOP and 
		activeMode <= BOT_MODE_PUSH_TOWER_BOT then
		local towers = I:GetNearbyTowers(300, true);
		if #towers > 0 then
			I:DebugTalk("牛逼推塔")
			return {BOT_ACTION_DESIRE_MODERATE}; 
		end
	end
	
	if activeMode == BOT_MODE_ROAM or
		 activeMode == BOT_MODE_TEAM_ROAM or
		 activeMode == BOT_MODE_DEFEND_ALLY or
		 activeMode == BOT_MODE_ATTACK then
		 local target = I:UseUnitSpell(spell, 300, 0, 0, 0, {I:GetTarget()});
		 if target~=nil then
		 	I:DebugTalk("牛逼干人")
		 	return {BOT_ACTION_DESIRE_MODERATE};
		 end
	 end
	
	return {BOT_ACTION_DESIRE_NONE};
end
