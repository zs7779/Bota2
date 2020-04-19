local mode_utils = {};

mode_utils.mode_desire = {
    -- super duper emergency
    evasive_maneuvers = 1.0,
    rune = 0.95,
    retreat = 0.9,
    -- emergency
    attack = 0.75,
    defend_ally = 0.7,
    ward = 0.65,
    -- team activity
    push = 0.6, -- [push_tower_top push_tower_mid push_tower_bot]
    defend = 0.55, -- [defend_tower_top defend_tower_mid defend_tower_bottom]
    team_roam = 0.5,
    roshan = 0.45,
    assemble = 0.4,
    roam = 0.35,
    -- special time
    secret_shop = 0.3,
    laning = 0.25,
    -- default
    farm = 0.2,
    -- deprecated
    side_shop = 0,
    item = 0,
}

mode_utils.slow_factor = 0.5;
mode_utils.passiveness_factor = 0.9;
mode_utils.excution_factor = 1.0;

mode_utils.towers = {[LANE_TOP]={TOWER_TOP_1, TOWER_TOP_2, TOWER_TOP_3},
                        [LANE_MID]={TOWER_MID_1, TOWER_MID_2, TOWER_MID_3}, 
                        [LANE_BOT]={TOWER_BOT_1, TOWER_BOT_2, TOWER_BOT_3}};
mode_utils.runes = {["power"]={RUNE_POWERUP_1, RUNE_POWERUP_2},
                        ["bounty"]={RUNE_BOUNTY_1, RUNE_BOUNTY_2, RUNE_BOUNTY_3, RUNE_BOUNTY_4}};

return mode_utils;