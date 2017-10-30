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
		spells[2],
		talents[1],
		spells[2],
		spells[1],
		spells[3],
		spells[4],
		spells[3],
		spells[2],
		spells[3],
		spells[3],
		spells[2]
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
	
	local Gush = I:GetAbilityByName(spells[1]);
	local AnchorSmash = I:GetAbilityByName(spells[3]);
	local Ravage = I:GetAbilityByName(spells[4]);
	
	local GushDesire, GushTarget = unpack(ConsiderGush(I, Gush));
	local AnchorSmashDesire = unpack(ConsiderAnchorSmash(I, AnchorSmash));
	local RavageDesire = unpack(ConsiderRavage(I, Ravage));

	if RavageDesire > 0 then
		I:Action_UseAbility(Ravage);
	end
	if AnchorSmashDesire > 0 then
		I:Action_UseAbility(AnchorSmash);
	end
	if GushDesire > 0 then
		I:Action_UseAbilityOnEntity(Gush, GushTarget);
	end
	ability_item_usage_generic.SwapItemThink(I);
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
	local radius = spell:GetAOERadius();
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = 0;

	local considerNuke = ability_item_usage_generic.ConsiderAoENuke(I, spell, castRange, radius, damage, spellType, delay);
	if considerNuke[1] > 0 then return considerNuke; end
	return ability_item_usage_generic.ConsiderAoEDebuff(I, spell, castRange, radius, delay);
end

function ConsiderRavage(I, spell)
	local castRange = 0;
	local radius = spell:GetAOERadius();
	local damage = spell:GetAbilityDamage();
	local spellType = spell:GetDamageType();
	local delay = 0;
	
	local considerStun = ability_item_usage_generic.ConsiderAoEStun(I, spell, castRange, radius, delay);
	if considerStun[1] > 0 then	return considerStun; end
	return ability_item_usage_generic.ConsiderAoENuke(I, spell, castRange, radius, damage, spellType, delay);
end
