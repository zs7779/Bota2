function GetComboMana(abilities)
	local manaCost = 0;
	for _, ability in pairs(abilities) do
		if not ability:IsPassive() and ability:IsFullyCastable() and ability:GetAbilityDamage()>0 then
			manaCOst = manaCost + ability:GetManaCost();
		end
	end
	return manaCost;
end

function GetComboDamage(abilities)
	local totalDamage = 0;
	for _, ability in pairs(abilities) do
		if not ability:IsPassive() and ability:IsFullyCastable() and ability:GetAbilityDamage()>0 then
			totalDamage = totalDamage + ability:GetAbilityDamage();
		end
	end
	return totalDamage;
end

function CanCastAbilityOnTarget(ability, target)
	return ability:IsFullyCastable() and 
	target:CanBeSeen() and 
	not target:IsInvulnerable() and 
	(not target:IsMagicImmune() or 
	ability:GetTargetFlags() == ABILITY_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES);
end

BotsInit = require( "game/botsinit" );
local ability_item_usage_generic = BotsInit.CreateGeneric();
ability_item_usage_generic.GetComboMana = GetComboMana;
ability_item_usage_generic.GetComboDamage = GetComboDamage;
ability_item_usage_generic.CanCastAbilityOnTarget = CanCastAbilityOnTarget;
return ability_item_usage_generic;