enums = require(GetScriptDirectory().."/enums");

local abilities_dictionary = {
    jakiro_dual_breath = function (ability)
        return {
            handle = ability,
            cast_range = ability:GetCastRange(),
            aoe_radius = ability:GetSpecialValueInt("start_radius"),
            cast_delay = ability:GetCastPoint()+ability:GetSpecialValueFloat("fire_delay"),
            damage = ability:GetDuration() * ability:GetSpecialValueInt("burn_damage"),
            target_flags = ability:GetTargetFlags(),
            modifier = "modifier_jakiro_dual_breath_slow",
            timer = enums.timer.SLOW,
        };
    end,
    jakiro_ice_path = function (ability)
        return {
            handle = ability,
            cast_range = ability:GetCastRange(),
            aoe_radius = ability:GetSpecialValueInt("path_radius"),
            cast_delay = ability:GetCastPoint()+ability:GetSpecialValueFloat("path_delay"),
            damage = ability:GetSpecialValueInt("damage"),
            target_flags = ability:GetTargetFlags(),
            modifier = "modifier_jakiro_ice_path_stun", 
            timer = enums.timer.STUN,
        };
    end,
    jakiro_liquid_fire = function (ability)
        return {
            handle = ability,
            cast_range = ability:GetCastRange(),
            aoe_radius = ability:GetSpecialValueInt("radius"),
            damage = ability:GetSpecialValueInt("damage"),
            target_flags = ability:GetTargetFlags(),
            modifier = "modifier_jakiro_liquid_fire_burn",
            timer = enums.timer.NONE,
        };
    end,
    jakiro_macropyre = function (ability)
        return {
            handle = ability,
            cast_range = ability:GetCastRange(),
            aoe_radius = ability:GetSpecialValueInt("path_radius"),
            cast_delay = ability:GetCastPoint(),
            damage = ability:GetSpecialValueFloat("linger_duration") * ability:GetSpecialValueInt("damage"),
            target_flags = ability:GetTargetFlags(),
            modifier = "modifier_jakiro_macropyre_burn",
            timer = enums.timer.NONE,
        };
    end,
    sven_storm_bolt = function (ability)
        return {
            handle = ability,
            cast_range = ability:GetCastRange(),
            aoe_radius = ability:GetSpecialValueInt("bolt_aoe"),
            damage = ability:GetAbilityDamage(),
            target_flags = ability:GetTargetFlags(),
            modifier = "modifier_sven_stormbolt_hide",
            timer = enums.timer.STUN,
        };
    end,
    sven_warcry = function (ability)
        return {
            handle = ability,
            cast_range = 0,
            aoe_radius = ability:GetSpecialValueInt("radius"),
            cast_delay = ability:GetCastPoint(),
            damage = 0,
            target_flags = ability:GetTargetFlags(),
            modifier = "modifier_sven_warcry",
            timer = enums.timer.NONE,
        };
    end,
    sven_gods_strength = function (ability)
        return {
            handle = ability,
            cast_range = 0,
            aoe_radius = 0,
            cast_delay = ability:GetCastPoint(),
            damage = 0,
            target_flags = ability:GetTargetFlags(),
            modifier = "modifier_sven_gods_strength",
            timer = enums.timer.NONE,
        };
    end,
    sniper_shrapnel = function (ability)
        return {
            handle = ability,
            cast_range = ability:GetCastRange(),
            aoe_radius = ability:GetSpecialValueInt("radius"),
            cast_delay = ability:GetCastPoint() + ability:GetSpecialValueFloat("damage_delay"),
            damage = ability:GetSpecialValueFloat("slow_duration") * ability:GetSpecialValueInt("shrapnel_damage"),
            target_flags = ability:GetTargetFlags(),
            modifier = "modifier_sniper_shrapnel_slow",
            timer = enums.timer.SLOW,
        };
    end,
    sniper_take_aim = function (ability)
        return {
            handle = ability,
            cast_range = 0,
            aoe_radius = 0,
            cast_delay = ability:GetCastPoint(),
            damage = 0,
            target_flags = ability:GetTargetFlags(),
            modifier = "modifier_sniper_take_aim",
            timer = enums.timer.NONE,
        };
    end,
    sniper_assassinate = function (ability)
        return {
            handle = ability,
            cast_range = ability:GetCastRange(),
            aoe_radius = 0,
            damage = ability:GetAbilityDamage(),
            target_flags = ability:GetTargetFlags(),
            modifier = "modifier_sniper_assassinate",
            timer = enums.timer.STUN,
        };
    end,
    necrolyte_death_pulse = function (ability)
        return {
            handle = ability,
            cast_range = 0,
            aoe_radius = ability:GetSpecialValueInt("area_of_effect"),
            cast_delay = ability:GetCastPoint(),
            damage = ability:GetAbilityDamage(),
            target_flags = ability:GetTargetFlags(),
            modifier = "",
            timer = enums.timer.NONE,
        };
    end,
    necrolyte_sadist = function (ability)
        return {
            handle = ability,
            cast_range = 0,
            aoe_radius = ability:GetSpecialValueInt("slow_aoe"),
            cast_delay = ability:GetCastPoint(),
            damage = 0,
            target_flags = ability:GetTargetFlags(),
            modifier = "modifier_necrolyte_sadist_aura_effect", -- todo: maybe wrong double check
            timer = enums.timer.NONE,
        };
    end,
    necrolyte_reapers_scythe = function (ability)
        return {
            handle = ability,
            cast_range = ability:GetCastRange(),
            aoe_radius = 0,
            damage = 0,
            target_flags = ability:GetTargetFlags(),
            modifier = "modifier_necrolyte_reapers_scythe",
            timer = enums.timer.STUN,
        };
    end,
    sandking_burrowstrike = function (ability)
        return {
            handle = ability,
            cast_range = ability:GetCastRange(),
            aoe_radius = ability:GetSpecialValueInt("burrow_width"),
            cast_delay = ability:GetCastPoint(),
            damage = ability:GetAbilityDamage(),
            target_flags = ability:GetTargetFlags(),
            modifier = "modifier_sandking_burrowstrike",
            timer = enums.timer.STUN,
        };
    end,
    sandking_sand_storm = function (ability)
        return {
            handle = ability,
            cast_range = 0,
            aoe_radius = ability:GetSpecialValueInt("sand_storm_radius"),
            cast_delay = ability:GetCastPoint(),
            damage = ability:GetSpecialValueInt("sand_storm_damage"),
            target_flags = ability:GetTargetFlags(),
            modifier = "modifier_sandking_sand_storm_slow",
            timer = enums.timer.NONE,
        };
    end,
    sandking_epicenter = function (ability)
        return {
            handle = ability,
            cast_range = 0,
            aoe_radius = ability:GetSpecialValueInt("epicenter_radius"),
            cast_delay = ability:GetCastPoint() + ability:GetChannelTime(),
            damage = ability:GetSpecialValueInt("epicenter_damage"),
            target_flags = ability:GetTargetFlags(),
            modifier = "modifier_sand_king_epicenter_slow",
            timer = enums.timer.SLOW, -- todo: not gonna work right? cause of the delay
        };
    end,
};

return abilities_dictionary;