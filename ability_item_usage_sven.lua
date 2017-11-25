require(GetScriptDirectory() ..  "/utils")
ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local abilityGuide = {};

function GetAbilityGuide(I)
	local spells, talents = I:GetAbilities(); 

	abilityGuide = {
		-- levels    =  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
		-- upgrade   =  1  3  2  2  2  4  2  3  3  T  3  4  1  1  T  1  -  4  -  T  -  -  -  -  T
		[spells[1]]  = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[2]]  = {0, 0, 1, 2, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[3]]  = {0, 1, 1, 1, 1, 1, 1, 2, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
		[spells[4]]  = {0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3},
		[talents[1]] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		[talents[4]] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		[talents[5]] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
		[talents[7]] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
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
	ability_item_usage_generic.SwapItemThink(I);	
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
