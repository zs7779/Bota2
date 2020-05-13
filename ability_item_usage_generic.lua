utils = require(GetScriptDirectory().."/utils");
enums = require(GetScriptDirectory().."/enums");
require(GetScriptDirectory().."/CDOTA_utils");


-- mods = target:GetModifierList();
-- for i = 1,#mods do
--     print(target:GetUnitName(), i, target:GetModifierName(i), target:GetModifierRemainingDuration(i));
-- end
-- one work around maybe: save stun time on enemy? use GetDuration( )
-- but can you save things on enemy handle? I think handle doesnt get destroyed since you can call can be seen when invisible, how about dead? how about illusion????
---------------------------------------------------------------------------------------------------------------------------------------------
-- 1.point 2.no target 3.unit due to need to cast ability
-- no target is point with 0 cast range
-- need to decide wither a rectangular shape ability use circle aoe or special function, circle radius can be get by GetSpecialValue
-- need to consider invisible enemy/enemy in shadow

local this_bot = GetBot();

function CanCastOnTarget(target, target_flags, modifier_func)
    local target_magic_immune = utils.GetFlag(target_flags, ABILITY_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES);
    local cant_target_attack_immune = utils.GetFlag(target_flags, ABILITY_TARGET_FLAG_NOT_ATTACK_IMMUNE);
    return target ~= nil and target:IsAlive() and
        ( (not target:IsMagicImmune() or target_magic_immune) and (not target:IsAttackImmune() or not cant_target_attack_immune) ) and
        ( modifier_func == nil or not modifier_func(target) );
end

function GetTargetsInRange(range, enemy, base_location, time_in_future)
    local targets = {};
    if range <= 1600 then
        targets = this_bot:GetNearbyHeroes(range, enemy, BOT_MODE_NONE);
    else
        units = GetUnitList(enums.unit_list[enemy]);
        for _, unit in pairs(units) do
            if unit:GetMovementDirectionStability() >= time_in_future and utils.GetDistance(base_location, unit:GetExtrapolatedLocation(time_in_future)) <= range then
                targets[#targets+1] = unit;
            end
        end
    end
    return targets;
end

function CheckTargetsStillAtLocation(aoe_num_units, aoe_location, enemy, base_location, cast_range, aoe_radius, target_flags, modifier_func)
    local unit_count = 0;
    if aoe_location ~= nil then
        local targets = GetTargetsInRange(cast_range, enemy, base_location, 0);
        for _, target in pairs(targets) do
            -- find number of heroes being hit (considering magic immunity)
            if CanCastOnTarget(target, target_flags, modifier_func) and GetUnitToLocationDistance(target, aoe_location) <= aoe_radius then
                unit_count = unit_count + 1;
            end
        end
    end
    if unit_count >= aoe_num_units then
        return true;
    end
    print("old num",aoe_num_units,"new num", unit_count);
    return false;
end

function ThinkCircleAbility(enemy, hero, base_location, cast_range, aoe_radius, time_in_future, damage, target_flags, modifier_func)
    local aoe = this_bot:FindAoELocation(enemy, hero, base_location, cast_range, aoe_radius, time_in_future, damage);
    local aoe_num_units, aoe_location = aoe.count, aoe.targetloc;
    return aoe_num_units, aoe_location;
end

function ThinkCircleAbilityOnTarget(target, base_location, cast_range, aoe_radius, time_in_future, damage, target_flags, modifier_func)
    if not CanCastOnTarget(target, target_flags, modifier_func) or target:GetMovementDirectionStability() < time_in_future then
        return 0, nil;
    end
    local target_location = target:GetExtrapolatedLocation(time_in_future);
    if utils.GetDistance(base_location, target_location) < cast_range and (damage == 0 or target:GetHealth() < damage)
       and target:GetMovementDirectionStability() >= time_in_future then -- maybe adda aoe_radius
        return 1, target_location;
    end
    return 0, nil;
end

function UseCircleNuke(ability, enemy, hero, cast_range, aoe_radius, time_in_future, damage, target_flags, modifier_func)
    if ability == nil or not ability:IsFullyCastable() then
        return;
    end
    local aoe_num_units, aoe_location = 0, nil;
    local bot_location = this_bot:GetLocation();
    local active_mode = this_bot:GetActiveMode();
    if active_mode == BOT_MODE_ATTACK then
        local target = this_bot:GetTarget();
        aoe_num_units, aoe_location = ThinkCircleAbilityOnTarget(target, bot_location, cast_range, aoe_radius, time_in_future, 0, target_flags, modifier_func);
    elseif active_mode == BOT_MODE_RETREAT or active_mode == BOT_MODE_DEFEND_ALLY then
        aoe_num_units, aoe_location = ThinkCircleAbility(enemy, hero, bot_location, cast_range, aoe_radius, time_in_future, 0, target_flags, modifier_func);
    elseif active_mode == BOT_MODE_LANING then
        if this_bot:FreeAbility(ability) then
            aoe_num_units, aoe_location = ThinkCircleAbility(enemy, hero, bot_location, cast_range, aoe_radius, time_in_future, 0, target_flags, modifier_func);
        end
    elseif active_mode >= BOT_MODE_PUSH_TOWER_TOP and active_mode <= BOT_MODE_DEFEND_TOWER_BOT then
        if this_bot:FreeAbility(ability) then
            aoe_num_units, aoe_location = ThinkCircleAbility(enemy, false, bot_location, cast_range, aoe_radius, time_in_future, 0, target_flags, modifier_func);
        end
    elseif active_mode == BOT_MODE_FARM then
        if this_bot:FreeAbility(ability) then
            aoe_num_units, aoe_location = ThinkCircleAbility(enemy, false, bot_location, cast_range, aoe_radius, time_in_future, damage, target_flags, modifier_func);
        end
    end
    if aoe_num_units > 0 then
        DebugDrawCircle(aoe_location, aoe_radius, 0, 0, 100);
        if ability:IsInAbilityPhase() then
            if not CheckTargetsStillAtLocation(aoe_num_units, aoe_location, enemy, bot_location, cast_range, aoe_radius, target_flags, modifier_func) then
                this_bot:Action_ClearActions(true);
                print("cancel");
            end
        else
            this_bot:Action_UseAbilityOnLocation(ability, aoe_location);
        end
    end
end

function NoStunTime(target)
    if target:GetStunTime() == 0 then
        print(target:GetUnitName(),"Not stunned");
        return true;
    end
    print(target:GetUnitName(),"Stunned");
    return false;
end

local ability_item_usage_generic = {};
-- GetSpecialValueInt
-- GetSpecialValueFloat
ability_item_usage_generic.ability_usage = {
    ["jakiro_dual_breath"] = {
        use_func = function (ability)
            UseCircleNuke(ability, true, true, ability:GetCastRange(), ability:GetSpecialValueInt("start_radius"),
                ability:GetCastPoint()+ability:GetSpecialValueFloat("fire_delay"), ability:GetDuration() * ability:GetSpecialValueInt("burn_damage"),
                ability:GetTargetFlags(), nil);
            return {["name"]="modifier_jakiro_dual_breath_slow", ["timer"]=enums.SLOW};
        end
    },
    ["jakiro_ice_path"] = {
        use_func = function (ability)
            UseCircleNuke(ability, true, true, ability:GetCastRange(), ability:GetSpecialValueInt("path_radius"),
                ability:GetCastPoint()+ability:GetSpecialValueFloat("path_delay"), ability:GetSpecialValueInt("damage"),
                ability:GetTargetFlags(), NoStunTime);
            return {["name"]="modifier_jakiro_ice_path_stun", ["timer"]=enums.STUN};
        end
    },
    ["jakiro_liquid_fire"] = {
        use_func = function (ability)
            return nil;
        end
    },
    ["jakiro_macropyre"] = {
        use_func = function (ability)
            UseCircleNuke(ability, true, true, ability:GetCastRange(), ability:GetSpecialValueInt("path_radius"),
                ability:GetCastPoint(), ability:GetSpecialValueFloat("linger_duration") * ability:GetSpecialValueInt("damage"),
                ability:GetTargetFlags(), nil);
            return nil;
        end
    },
};

function ability_item_usage_generic.ThinkAbility()
    local mode = this_bot:GetActiveMode();
    if this_bot.abilities_slots ~= nil then
        for i = 1, #this_bot.abilities_slots do
            local bot_location = this_bot:GetLocation();
            local ability = this_bot:GetAbilityInSlot(this_bot.abilities_slots[i]);
            if ability ~= nil and ability:IsTrained() then
                local ability_name = ability:GetName();
                local modifier = ability_item_usage_generic.ability_usage[ability_name].use_func(ability);
                -- computation about stun time
                if modifier ~= nil then
                    local enemies = GetTargetsInRange(1600, true, this_bot:GetLocation(), 0);
                    for _, enemy in pairs(enemies) do
                        if enemy ~= nil and enemy:IsAlive() and enemy:HasModifier(modifier.name) then
                            local remain_time = enemy:GetModifierRemainingDuration(enemy:GetModifierByName(modifier.name));
                            if enemy[modifier.timer] == nil then
                                enemy[modifier.timer] = remain_time;
                            else
                                enemy[modifier.timer] = math.max(enemy[modifier.timer], DotaTime() + remain_time);
                            end
                        end
                    end
                end
            end
        end
    end 
end
return ability_item_usage_generic;