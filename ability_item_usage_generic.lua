utils = require(GetScriptDirectory().."/utils");
enums = require(GetScriptDirectory().."/enums");
require(GetScriptDirectory().."/CDOTA_utils");


-- mods = target:GetModifierList();
-- for i = 1,#mods do
--     print(target:GetUnitName(), i, target:GetModifierName(i), target:GetModifierRemainingDuration(i));
-- end
-- one work around maybe: save stun time on enemy? use GetDuration( )
-- but can you save things on enemy handle? I think handle doesnt get destroyed since you can call can be seen when invisible, how about dead?
---------------------------------------------------------------------------------------------------------------------------------------------
-- 1.point 2.no target 3.unit due to need to cast ability
-- no target is point with 0 cast range
-- need to decide wither a rectangular shape ability use circle aoe or special function, circle radius can be get by GetSpecialValue
-- need to consider invisible enemy/enemy in shadow

function CanCastOnTarget(target, target_flags, modifier_func)
    local target_magic_immune = utils.GetFlag(target_flags, ABILITY_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES);
    local cant_target_attack_immune = utils.GetFlag(target_flags, ABILITY_TARGET_FLAG_NOT_ATTACK_IMMUNE);
    return target ~= nil and target:IsAlive() and
        ( (not target:IsMagicImmune() or target_magic_immune) and (not target:IsAttackImmune() or not cant_target_attack_immune) ) and
        ( modifier_func == nil or modifier_func(target) );
end

function ThinkCircleAbility(enemey, hero, base_location, cast_range, aoe_radius, time_in_future, damage, target_flags, modifier_func)
    local this_bot = GetBot();
    local aoe = this_bot:FindAoELocation(enemey, hero, base_location, cast_range, aoe_radius, time_in_future, damage);
    local aoe_num_units, aoe_location = aoe.count, aoe.targetloc;
    if aoe_num_units > 0 and aoe_location ~= nil and hero then
        aoe_num_units = 0;
        local targets = {};
        local range = cast_range + aoe_radius;
        if range <= 1600 then
            targets = this_bot:GetNearbyHeroes(range, enemey, BOT_MODE_NONE);
        else
            units = GetUnitList(enums.unit_list[enemy]);
            for _, unit in pairs(units) do
                if utils.GetDistance(base_location, unit:GetExtrapolatedLocation(time_in_future)) <= range then
                    targets[#targets+1] = unit;
                end
            end
        end
        for _, target in pairs(targets) do
            -- find number of heroes being hit (considering magic immunity)
            if CanCastOnTarget(target, target_flags, modifier_func) and utils.GetDistance(aoe_location, target:GetExtrapolatedLocation(time_in_future)) <= aoe_radius then
                aoe_num_units = aoe_num_units + 1;
            end
        end
    end
    return aoe_num_units, aoe_location;
end

function ThinkCircleAbilityOnTarget(target, base_location, cast_range, aoe_radius, time_in_future, damage, target_flags, modifier_func)
    if not CanCastOnTarget(target, target_flags, modifier_func) then
        return 0, nil;
    end
    local target_location = target:GetExtrapolatedLocation(time_in_future);
    if utils.GetDistance(base_location, target_location) < cast_range and (damage == 0 or target:GetHealth() < damage) then -- maybe adda aoe_radius
        return 1, target_location;
    end
    return 0, nil;
end

function UseCircleNuke(ability, enemey, hero, cast_range, aoe_radius, time_in_future, damage, target_flags, modifier_func)
    local aoe_unit_num, aoe_location = 0, nil;
    local this_bot = GetBot();
    local bot_location = this_bot:GetLocation();
    local active_mode = this_bot:GetActiveMode();
    if active_mode == BOT_MODE_ATTACK then
        local target = this_bot:GetTarget();
        aoe_unit_num, aoe_location = ThinkCircleAbilityOnTarget(target, bot_location, cast_range, aoe_radius, time_in_future, 0, target_flags, modifier_func);
    elseif active_mode == BOT_MODE_RETREAT or active_mode == BOT_MODE_DEFEND_ALLY then
        aoe_unit_num, aoe_location = ThinkCircleAbility(enemey, hero, bot_location, cast_range, aoe_radius, time_in_future, 0, target_flags, modifier_func);
    elseif active_mode == BOT_MODE_LANING then
        if this_bot:FreeAbility(ability) then
            aoe_unit_num, aoe_location = ThinkCircleAbility(enemey, hero, bot_location, cast_range, aoe_radius, time_in_future, 0, target_flags, modifier_func);
        end
    elseif active_mode == BOT_MODE_FARM then
        if this_bot:FreeAbility(ability) then
            aoe_unit_num, aoe_location = ThinkCircleAbility(enemey, false, bot_location, cast_range, aoe_radius, time_in_future, damage, target_flags, modifier_func);
        end
    end
    if aoe_unit_num > 0 then
        DebugDrawCircle(aoe_location, aoe_radius, 0, 0, 100);
        this_bot:Action_UseAbilityOnLocation(ability, aoe_location);
    end
end

local ability_item_usage_generic = {};
-- GetSpecialValueInt
-- GetSpecialValueFloat
ability_item_usage_generic.ability_usage = {
    ["jakiro_dual_breath"] = function (ability)
        UseCircleNuke(ability, true, true, ability:GetCastRange(), ability:GetSpecialValueInt("start_radius"),
            ability:GetCastPoint()+ability:GetSpecialValueFloat("fire_delay"), ability:GetDuration() * ability:GetSpecialValueInt("burn_damage"),
            ability:GetTargetFlags(), nil);
        return "special_bonus_unique_jakiro_2";
    end,
    ["jakiro_ice_path"] = function (ability)
        UseCircleNuke(ability, true, true, ability:GetCastRange(), ability:GetSpecialValueInt("path_radius"),
            ability:GetCastPoint()+ability:GetSpecialValueFloat("path_delay"), ability:GetSpecialValueInt("damage"),
            ability:GetTargetFlags(), CDOTA_Bot_Script.IsStunned);
        return "special_bonus_unique_jakiro";
    end,
    ["jakiro_liquid_fire"] = function (ability)
        return "special_bonus_unique_jakiro_4";
    end,
    ["jakiro_macropyre"] = function (ability)
        UseCircleNuke(ability, true, true, ability:GetCastRange(), ability:GetSpecialValueInt("path_radius"),
            ability:GetCastPoint(), ability:GetSpecialValueFloat(linger_duration) * ability:GetSpecialValueInt("damage"),
            ability:GetTargetFlags(), nil);
        return nil;
    end,
};

function ability_item_usage_generic.ThinkAbility()
    local this_bot = GetBot();
    local mode = this_bot:GetActiveMode();
    if this_bot.abilities_slots ~= nil then
        for i = 1, #this_bot.abilities_slots do
            local bot_location = this_bot:GetLocation();
            local ability = this_bot:GetAbilityInSlot(this_bot.abilities_slots[i]);
            if ability ~= nil and ability:IsTrained() then
                local ability_name = ability:GetName();
                local modifier = ability_item_usage_generic.ability_usage[ability_name](ability);
            end
        end
    end 
end
return ability_item_usage_generic;