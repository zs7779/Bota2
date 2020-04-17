local mode_utils = {};

mode_utils.mode_desire = {
    evasive_maneuvers = 1.0,
    retreat = 0.95,
    defend_ally = 0.9,
    attack = 0.85,
    ward = 0.8,
    push = 0.75, -- [push_tower_top push_tower_mid push_tower_bot]
    defend = 0.7, -- [defend_tower_top defend_tower_mid defend_tower_bottom]
    team_roam = 0.65,
    roshan = 0.6,
    assemble = 0.55,
    roam = 0.5,
    rune = 0.45,
    farm = 0.4,
    secret_shop = 0.35,
    laning = 0.3,
    side_shop = 0,
    item = 0,
}

mode_utils.slow_factor = 0.5;
mode_utils.passiveness_factor = 0.9;
mode_utils.excution_factor = 1.0;

return mode_utils;