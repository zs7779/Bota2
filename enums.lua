local enums = {};

enums.atentnion = 0.5;
enums.passiveness = 0.6;
enums.stupidity = 1.2;
enums.healthy = 0.6;

enums.slow_factor = 0.5;
enums.passiveness_factor = 0.9;
enums.excution_factor = 1.0;
enums.friend_help_factor = 1.5;

enums.mode_desire = {
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
enums.free_time = {1, 5, 10, 15, 15};

enums.towers = {[LANE_TOP]={TOWER_TOP_1, TOWER_TOP_2, TOWER_TOP_3},
                [LANE_MID]={TOWER_MID_1, TOWER_MID_2, TOWER_MID_3}, 
                [LANE_BOT]={TOWER_BOT_1, TOWER_BOT_2, TOWER_BOT_3}};
enums.runes = {["power"]={RUNE_POWERUP_1, RUNE_POWERUP_2},
               ["bounty"]={RUNE_BOUNTY_1, RUNE_BOUNTY_2, RUNE_BOUNTY_3, RUNE_BOUNTY_4}};

enums.hero_list = {[true]=UNIT_LIST_ENEMY_HEROES, [false]=UNIT_LIST_ALLIED_HEROES};
enums.creep_list = {[true]=UNIT_LIST_ENEMY_CREEPS, [false]=UNIT_LIST_ALLIED_CREEPS};

enums.modes = {BOT_MODE_LANING, BOT_MODE_ATTACK, BOT_MODE_ROAM, BOT_MODE_RETREAT, BOT_MODE_SECRET_SHOP, BOT_MODE_SIDE_SHOP,
BOT_MODE_PUSH_TOWER_TOP, BOT_MODE_PUSH_TOWER_MID, BOT_MODE_PUSH_TOWER_BOT, BOT_MODE_DEFEND_TOWER_TOP, BOT_MODE_DEFEND_TOWER_MID, BOT_MODE_DEFEND_TOWER_BOT,
BOT_MODE_ASSEMBLE, BOT_MODE_TEAM_ROAM, BOT_MODE_FARM, BOT_MODE_DEFEND_ALLY, BOT_MODE_EVASIVE_MANEUVERS, BOT_MODE_ROSHAN, BOT_MODE_ITEM, BOT_MODE_WARD};

enums.experience_range = 1500;

enums.timer = {
    STUN = "stun_timer",
    SLOW = "slow_timer",
    BUFF = "buff_timer",
    NONE = nil,
};
return enums;