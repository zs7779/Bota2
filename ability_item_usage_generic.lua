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

function CanCastOnTarget(target, target_flags, modifier_func)
    local target_magic_immune = utils.GetFlag(target_flags, ABILITY_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES) or
                                not utils.GetFlag(target_flags, ABILITY_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES); -- todo: could be problem
    local cant_target_attack_immune = utils.GetFlag(target_flags, ABILITY_TARGET_FLAG_NOT_ATTACK_IMMUNE);
    return target ~= nil and target:IsAlive() and
        ( (not target:IsMagicImmune() or target_magic_immune) and (not target:IsAttackImmune() or not cant_target_attack_immune) ) and
        ( modifier_func == nil or modifier_func(target) );
end

function GetTargetsInRange(range, enemy, creep, base_location, time_in_future, damage)
    local this_bot = GetBot();
    local targets = {};
    if creep then
        targets = this_bot:GetNearbyCreeps(math.min(range, 1600), enemy);
        return targets;
    end
    if range <= 1600 then
        targets = this_bot:GetNearbyHeroes(range, enemy, BOT_MODE_NONE);
    else
        units = GetUnitList(enums.hero_list[enemy]);
        for _, unit in pairs(units) do
            if unit:GetMovementDirectionStability() >= time_in_future and
               utils.GetDistance(base_location, unit:GetExtrapolatedLocation(time_in_future)) <= range and
               (damage == 0 or target:GetHealth() < damage) then
                targets[#targets+1] = unit;
            end
        end
    end
    return targets;
end

function CheckTargetsStillAtLocation(aoe_num_units, aoe_location, enemy, creep, base_location, cast_range, aoe_radius, target_flags, modifier_func)
    local unit_count = 0;
    if aoe_location ~= nil then
        local targets = GetTargetsInRange(cast_range, enemy, creep, base_location, 0, 0);
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
    -- print("old num",aoe_num_units,"new num", unit_count);
    return false;
end

function ThinkCircleAbility(enemy, creep, base_location, cast_range, aoe_radius, time_in_future, damage, target_flags, modifier_func)
    local this_bot = GetBot();
    local aoe = {count = 0, targetloc = nil};
    local targets = GetTargetsInRange(cast_range + aoe_radius, enemy, creep, base_location, time_in_future, damage);
    if cast_range > 0 then
        aoe = this_bot:FindAoELocation(enemy, not creep, base_location, cast_range, aoe_radius, time_in_future, damage);
    else
        aoe.targetloc = this_bot:GetLocation();
    end
    local unit_count = 0;
    for _, target in pairs(targets) do
        if CanCastOnTarget(target, target_flags, modifier_func) and GetUnitToLocationDistance(target, aoe.targetloc) <= aoe_radius then
            unit_count = unit_count + 1;
        end
    end
    aoe.count = unit_count;
    -- print(aoe.count, enemy, creep, cast_range, aoe_radius); -- todo: aoe_num_units become nil, and no one is using ability
    return aoe.count, aoe.targetloc;
end

function ThinkCircleAbilityOnTarget(base_location, cast_range, aoe_radius, time_in_future, damage, target_flags, modifier_func)
    local this_bot = GetBot();
    local target = this_bot:GetTarget();
    if not CanCastOnTarget(target, target_flags, modifier_func) or target:GetMovementDirectionStability() < time_in_future then
        return 0, nil;
    end
    local target_location = target:GetExtrapolatedLocation(time_in_future);
    if utils.GetDistance(base_location, target_location) < cast_range and (damage == 0 or target:GetHealth() < damage)
       and target:GetMovementDirectionStability() >= time_in_future then -- todo: maybe adda aoe_radius
        return 1, target_location;
    end
    return 0, nil;
end

function UseCircleAbility(ability, enemy, creep, cast_range, aoe_radius, time_in_future, damage, target_flags, modifier_func, use_in_modes, free_ability, min_units)
    if ability == nil or not ability:IsFullyCastable() then
        return;
    end
    local use_in_modes = use_in_modes or enums.modes;
    local min_units = min_units or 1;
    local this_bot = GetBot();
    -- print(this_bot:GetUnitName(), ability:GetName())
    local aoe_num_units, aoe_location = 0, nil;
    local bot_location = this_bot:GetLocation();
    local active_mode = this_bot:GetActiveMode();
    for _, mode in pairs(use_in_modes) do
        if active_mode == mode and (not free_ability or this_bot:FreeAbility(ability)) then
            if active_mode == BOT_MODE_ATTACK then
                aoe_num_units, aoe_location = ThinkCircleAbilityOnTarget(bot_location, cast_range, aoe_radius, time_in_future, 0, target_flags, modifier_func);
            else
                aoe_num_units, aoe_location = ThinkCircleAbility(enemy, creep, bot_location, cast_range, aoe_radius, time_in_future, damage, target_flags, modifier_func);
            end
        end
    end
    if aoe_num_units >= min_units then
        DebugDrawCircle(aoe_location, aoe_radius, 0, 0, 100);
        if ability:IsInAbilityPhase() and enemy then
            -- doesnt seem to work, probably need to test with toggle like Leshrac
            if not CheckTargetsStillAtLocation(aoe_num_units, aoe_location, enemy, creep, bot_location, cast_range, aoe_radius, target_flags, modifier_func) then
                this_bot:Action_ClearActions(false);
                this_bot:MoveOppositeStep(aoe_location);
                this_bot:ActionQueue_Delay(0.5);
            end
        else
            if cast_range > 0 then
                this_bot:Action_UseAbilityOnLocation(ability, aoe_location);
            else
                this_bot:Action_UseAbility(ability);
            end
        end
    end
end

function ThinkUnitAbility(enemy, creep, cast_range, aoe_radius, damage, target_flags, modifier_func)
    local this_bot = GetBot();
    local target = this_bot:GetTarget();
    if CanCastOnTarget(target, target_flags, modifier_func) and
       GetUnitToUnitDistance(this_bot, target) < cast_range and (damage == 0 or target:GetHealth() < damage) then
        return target;
    end
    local targets = GetTargetsInRange(cast_range, enemy, creep, this_bot:GetLocation(), 0, damage);
    for _, target in pairs(targets) do
        if CanCastOnTarget(target, target_flags, modifier_func) then
            return target;
        end
    end
    return nil;
end

function UseUnitAbility(ability, enemy, creep, cast_range, aoe_radius, damage, target_flags, modifier_func, use_in_modes, free_ability)
    if ability == nil or not ability:IsFullyCastable() then
        return;
    end
    local use_in_modes = use_in_modes or enums.modes;
    local this_bot = GetBot();
    -- print(this_bot:GetUnitName(), ability:GetName())
    local active_mode = this_bot:GetActiveMode();
    local target = nil;
    for _, mode in pairs(use_in_modes) do
        if active_mode == mode and (not free_ability or this_bot:FreeAbility(ability)) then
            target = ThinkUnitAbility(enemy, creep, cast_range, aoe_radius, damage, target_flags, modifier_func);
        end
    end
    if target ~= nil then
        this_bot:Action_UseAbilityOnEntity(ability, target);
    end
end


function ThinkBuffUnitAbilityTarget(creep, cast_range, base_location, target_flags, modifier_func)
    local targets = GetTargetsInRange(cast_range, false, creep, base_location, 0, 0);
    for _, target in pairs(targets) do
        if CanCastOnTarget(target, target_flags, modifier_func) then
            return target;
        end
    end
end

function ThinkBuffCircleAbilityTarget(creep, base_location, cast_range, aoe_radius, time_in_future, target_flags, modifier_func)
    return ThinkCircleAbility(false, creep, base_location, cast_range, aoe_radius, time_in_future, 0, target_flags, modifier_func);
end

function UseCircleBuffAbility(ability, creep, cast_range, aoe_radius, time_in_future, target_flags, modifier_func, use_in_modes, free_ability, min_units)
    if ability == nil or not ability:IsFullyCastable() then
        return;
    end
    local use_in_modes = use_in_modes or enums.modes;
    local min_units = min_units or 1;
    local this_bot = GetBot();
    -- print(ability:GetName(), NoModifier("modifier_sniper_take_aim")(this_bot), this_bot:GetUnitName(), this_bot:HasModifier("modifier_sniper_take_aim"))
    -- print(this_bot:GetUnitName(), ability:GetName())
    local aoe_num_units, aoe_location = 0, nil;
    local active_mode = this_bot:GetActiveMode();
    for _, mode in pairs(use_in_modes) do
        if active_mode == mode and (not free_ability or this_bot:FreeAbility(ability)) then
            aoe_num_units, aoe_location = ThinkBuffCircleAbilityTarget(creep, this_bot:GetLocation(), cast_range, aoe_radius, time_in_future, target_flags, modifier_func);
        end
    end
    -- print(ability:GetName(), aoe_num_units, min_units);
    if aoe_num_units >= min_units then
        if cast_range > 0 then
            this_bot:Action_UseAbilityOnLocation(ability, aoe_location);
        else
            this_bot:Action_UseAbility(ability);
        end
    end
end

function NoStunTime(target)
    if target:GetStunTime() == 0 then
        -- print(target:GetUnitName(),"Not stunned");
        return true;
    end
    print(target:GetUnitName().." Stunned "..target:GetStunTime());
    return false;
end

function NoModifier(modifier)
    return function (target)
        return not target:HasModifier(modifier);
    end;
end

function AbilityNotActive(ability)
    return function(target)
        print(ability:GetName(), ability:IsActivated())
        return not ability:IsActivated();
    end;
end

function CanReapersScythe(target)
    return target:GetHealth() / target:GetMaxHealth() < 0.4;
end

local ability_item_usage_generic = {};


function ability_item_usage_generic.ThinkAbility()
    local this_bot = GetBot();
    local mode = this_bot:GetActiveMode();
    if this_bot.abilities == nil then
        return;
    end
    for _, ability in pairs(this_bot.abilities) do
        -- local ability = this_bot:GetAbilityInSlot(this_bot.abilities_slots[i]);
        if ability ~= nil and ability.handle:IsTrained() then
            ability_item_usage_generic.ability_usage[ability.handle:GetName()](ability);
            -- computation about stun time
            if ability.modifier ~= nil and ability.timer ~= nil then
                local enemies = GetTargetsInRange(1600, true, false, this_bot:GetLocation(), 0, 0);
                for _, enemy in pairs(enemies) do
                    if enemy ~= nil and enemy:IsAlive() and enemy:HasModifier(ability.modifier) then
                        local remain_time = math.max(enemy:GetModifierRemainingDuration(enemy:GetModifierByName(ability.modifier)), 0);
                        -- print(modifier.name, remain_time)
                        if enemy[ability.timer] == nil then
                            enemy[ability.timer] = remain_time;
                        else
                            enemy[ability.timer] = math.max(enemy[ability.timer], DotaTime() + remain_time);
                        end
                    end
                end
            end
        end
    end
end

ability_item_usage_generic.ability_usage = {
    jakiro_dual_breath = function (ability)
        UseCircleAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, nil,
            {BOT_MODE_ATTACK, BOT_MODE_RETREAT, BOT_MODE_DEFEND_ALLY}, false, 1);
        UseCircleAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, nil,
            {BOT_MODE_LANING}, true, 2);
        UseCircleAbility(ability.handle, true, true, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, nil,
            {BOT_MODE_FARM}, true, 3);
        UseCircleAbility(ability.handle, true, true, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, nil,
            {BOT_MODE_PUSH_TOWER_TOP, BOT_MODE_PUSH_TOWER_MID, BOT_MODE_PUSH_TOWER_BOT,
            BOT_MODE_DEFEND_TOWER_TOP, BOT_MODE_DEFEND_TOWER_MID, BOT_MODE_DEFEND_TOWER_BOT, BOT_MODE_ROSHAN}, true, 3);
    end,
    jakiro_ice_path = function (ability)
        UseCircleAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, NoStunTime,
            {BOT_MODE_ATTACK, BOT_MODE_RETREAT, BOT_MODE_DEFEND_ALLY}, false, 1);
    end,
    jakiro_liquid_fire = function (ability)
        UseUnitAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, 0, ability.target_flags, nil,
            {BOT_MODE_LANING, BOT_MODE_ATTACK, BOT_MODE_DEFEND_ALLY}, false);
        UseUnitAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, 0, ability.target_flags, nil,
            {BOT_MODE_FARM}, false);
    end,
    jakiro_macropyre = function (ability)
        UseCircleAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, nil,
            {BOT_MODE_ATTACK}, false, 1);
        UseCircleAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, nil,
            {BOT_MODE_PUSH_TOWER_TOP, BOT_MODE_PUSH_TOWER_MID, BOT_MODE_PUSH_TOWER_BOT,
            BOT_MODE_DEFEND_TOWER_TOP, BOT_MODE_DEFEND_TOWER_MID, BOT_MODE_DEFEND_TOWER_BOT}, false, 3);
    end,
    sven_storm_bolt = function (ability)
        UseUnitAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, 0, ability.target_flags, NoStunTime,
            {BOT_MODE_RETREAT, BOT_MODE_ATTACK, BOT_MODE_DEFEND_ALLY}, false);
    end,
    -- todo: it suddenly feels like this is much better format. add free_ability and use_in_mode in everything and loop through
    sven_warcry = function(ability)
        UseCircleBuffAbility(ability.handle, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, ability.target_flags, nil,
            {BOT_MODE_ATTACK, BOT_MODE_RETREAT, BOT_MODE_FARM, BOT_MODE_EVASIVE_MANEUVERS, BOT_MODE_DEFEND_ALLY, BOT_MODE_ROSHAN}, false, 1);
        UseCircleBuffAbility(ability.handle, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, ability.target_flags, nil,
            {BOT_MODE_FARM}, true, 1);
    end,
    sven_gods_strength = function(ability)
        UseCircleBuffAbility(ability.handle, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, ability.target_flags, nil,
            {BOT_MODE_ATTACK, BOT_MODE_ROSHAN}, false, 1);
    end,
    sniper_shrapnel = function (ability)
        UseCircleAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, NoModifier(ability.modifier),
            {BOT_MODE_ATTACK, BOT_MODE_RETREAT, BOT_MODE_DEFEND_ALLY}, false, 1);
        UseCircleAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, NoModifier(ability.modifier),
            {BOT_MODE_LANING}, true, 2);
        UseCircleAbility(ability.handle, true, true, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, NoModifier(ability.modifier),
            {BOT_MODE_FARM}, true, 3);
        UseCircleAbility(ability.handle, true, true, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, NoModifier(ability.modifier),
            {BOT_MODE_PUSH_TOWER_TOP, BOT_MODE_PUSH_TOWER_MID, BOT_MODE_PUSH_TOWER_BOT,
            BOT_MODE_DEFEND_TOWER_TOP, BOT_MODE_DEFEND_TOWER_MID, BOT_MODE_DEFEND_TOWER_BOT, BOT_MODE_ROSHAN}, true, 3);
    end,
    sniper_take_aim = function(ability)
        UseCircleBuffAbility(ability.handle, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, ability.target_flags, NoModifier(ability.modifier),
            {BOT_MODE_ATTACK, BOT_MODE_LANING,
            BOT_MODE_PUSH_TOWER_TOP, BOT_MODE_PUSH_TOWER_MID, BOT_MODE_PUSH_TOWER_BOT,
            BOT_MODE_DEFEND_TOWER_TOP, BOT_MODE_DEFEND_TOWER_MID, BOT_MODE_DEFEND_TOWER_BOT}, true, 1);
    end,
    sniper_assassinate = function (ability)
        UseUnitAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, 0, ability.target_flags, nil,
            {BOT_MODE_ATTACK, BOT_MODE_DEFEND_ALLY}, false);
        UseUnitAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, 0, ability.target_flags, nil,
            {BOT_MODE_LANING}, true);
    end,
    necrolyte_death_pulse = function (ability)
        UseCircleAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, nil,
            {BOT_MODE_ATTACK, BOT_MODE_RETREAT, BOT_MODE_DEFEND_ALLY}, false, 1);
        UseCircleAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, nil,
            {BOT_MODE_LANING}, true, 2);
        UseCircleAbility(ability.handle, true, true, ability.cast_range, ability.aoe_radius, ability.cast_delay, ability.damage, ability.target_flags, nil,
            {BOT_MODE_FARM, BOT_MODE_LANING}, true, 2);
        UseCircleAbility(ability.handle, true, true, ability.cast_range, ability.aoe_radius, ability.cast_delay, ability.damage, ability.target_flags, nil,
            {BOT_MODE_PUSH_TOWER_TOP, BOT_MODE_PUSH_TOWER_MID, BOT_MODE_PUSH_TOWER_BOT,
            BOT_MODE_DEFEND_TOWER_TOP, BOT_MODE_DEFEND_TOWER_MID, BOT_MODE_DEFEND_TOWER_BOT, BOT_MODE_ROSHAN}, true, 2);
    end,
    necrolyte_sadist = function(ability)
        UseCircleBuffAbility(ability.handle, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, ability.target_flags, nil,
            {BOT_MODE_ATTACK, BOT_MODE_RETREAT, BOT_MODE_EVASIVE_MANEUVERS, BOT_MODE_DEFEND_ALLY}, false, 1);
    end,
    -- todo: need special function
    necrolyte_reapers_scythe = function (ability)
        UseUnitAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, 0, ability.target_flags, CanReapersScythe,
            nil, false);
    end,
    sandking_burrowstrike = function (ability) -- todo: blink ability special function for BOT_MODE_EVASIVE_MANEUVERS
        UseCircleAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, NoStunTime,
            {BOT_MODE_ATTACK, BOT_MODE_RETREAT, BOT_MODE_DEFEND_ALLY}, false, 1);
        UseCircleAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, NoStunTime,
            {BOT_MODE_LANING}, true, 2);
        UseCircleAbility(ability.handle, true, true, ability.cast_range, ability.aoe_radius, ability.cast_delay, ability.damage, ability.target_flags, nil,
            {BOT_MODE_FARM}, true, 2);
    end,
    sandking_sand_storm = function (ability)
        UseCircleAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, nil,
            {BOT_MODE_ATTACK, BOT_MODE_RETREAT, BOT_MODE_DEFEND_ALLY, BOT_MODE_EVASIVE_MANEUVERS}, false, 1);
        UseCircleAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, nil,
            {BOT_MODE_LANING}, true, 3);
        UseCircleAbility(ability.handle, true, true, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, nil,
            {BOT_MODE_FARM}, true, 3);
    end,
    sandking_epicenter = function (ability)
        UseCircleAbility(ability.handle, true, false, ability.cast_range, ability.aoe_radius, ability.cast_delay, 0, ability.target_flags, nil,
            {BOT_MODE_ATTACK, BOT_MODE_DEFEND_ALLY}, false, 1);
    end,
};

return ability_item_usage_generic;