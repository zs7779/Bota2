utils = require(GetScriptDirectory().."/utils");
mode_utils = require(GetScriptDirectory().."/mode_utils");
require(GetScriptDirectory().."/CDOTA_utils");

-- 1.point 2.no target 3.unit due to need to cast ability
-- no target is point with 0 cast range
-- need to decide wither a rectangular shape ability use circle aoe or special function, circle radius can be get by GetSpecialValue

function UsePointTargetAbility()
end
function UseNoTargetAbility()
end
function UseUnitTargetAbility()
end

function UseDamageAbility()
    local this_bot = GetBot();
    local mode = this_bot:GetActiveMode();
    if this_bot.abilities_slots ~= nil then
        for i = 1, #this_bot.abilities_slots do
            local ability = this_bot:GetAbilityInSlot(this_bot.abilities_slots[i]);
            local ability_behavior = ability:GetBehavior();
            local cast_range = ability:GetCastRange();
            local aoe_radius = ability:GetAOERadius();
            local true_range = cast_range + aoe_radius;
            local free_ability = this_bot:FreeAbility(ability);
            if utils.GetFlag(ability_behavior, ABILITY_BEHAVIOR_NO_TARGET) then
            end
            if utils.GetFlag(ability_behavior, ABILITY_BEHAVIOR_UNIT_TARGET) then
            end
            if utils.GetFlag(ability_behavior, ABILITY_BEHAVIOR_POINT) then
            end
            
        end
    end
    
end