local enums = {};

enums.atentnion = 0.5;
enums.passiveness = 1.0;
enums.stupidity = 0.8;
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
    roshan = 0.5,
    team_roam = 0.45,
    assemble = 0.4,
    roam = 0.35,
    -- special time
    secret_shop = 0.3,
    laning = 0.25,
    -- default
    -- todo: lane and farm probably same level? each active under condition? you choose to lane if want to shut down enemy laner
    farm = 0.2,
    -- deprecated
    side_shop = 0,
    item = 0,
}
enums.free_time = {1, 5, 10, 15, 15};
enums.safety = {0.7, 0.7, 0.5, 0.4, 0.3};
enums.siege_creep_name = {[TEAM_RADIANT] = "npc_dota_goodguys_siege", [TEAM_DIRE] = "npc_dota_badguys_siege"};
enums.tower_importance = {[TEAM_RADIANT] = {1.0, 0.8, 0.6}, [TEAM_DIRE] = {0.6, 0.8, 1.0}};
enums.farm_safty = {[TEAM_RADIANT] = {1.0, 0.6, 0.4}, [TEAM_DIRE] = {0.4, 0.6, 1.0}};
enums.pull_camps = {[TEAM_RADIANT] = {small = 2, large = 3}, [TEAM_DIRE] = {small = 12, large = 13}};
enums.pull_time = {[TEAM_RADIANT] = {small = 15, large = 23}, [TEAM_DIRE] = {small = 15, large = 20}};
enums.pull_vector = {[TEAM_RADIANT] = {small = Vector(300, -1500, 0), large = Vector(1500, -300, 0)},
                     [TEAM_DIRE] = {small = Vector(-300, 1500, 0), large = Vector(-1500, 0, 0)}};
enums.pull_lane_front = {small = 0.55, big = 0.65, enemy = 0.65};

enums.lanes = {LANE_TOP, LANE_MID, LANE_BOT};
enums.towers = {[LANE_TOP]={TOWER_TOP_1, TOWER_TOP_2, TOWER_TOP_3},
                [LANE_MID]={TOWER_MID_1, TOWER_MID_2, TOWER_MID_3}, 
                [LANE_BOT]={TOWER_BOT_1, TOWER_BOT_2, TOWER_BOT_3}};
enums.barracks = {[LANE_TOP]={BARRACKS_TOP_MELEE, BARRACKS_TOP_RANGED},
                 [LANE_MID]={BARRACKS_MID_MELEE, BARRACKS_MID_RANGED}, 
                 [LANE_BOT]={BARRACKS_BOT_MELEE, BARRACKS_BOT_RANGED}};
enums.base_towers = {TOWER_BASE_1, TOWER_BASE_2};
enums.tower_vision = {{1900, 800}, {1900, 1100}, {1900, 1100}};
enums.runes = {["power"]={RUNE_POWERUP_1, RUNE_POWERUP_2},
               ["bounty"]={RUNE_BOUNTY_1, RUNE_BOUNTY_2, RUNE_BOUNTY_3, RUNE_BOUNTY_4}};

enums.hero_list = {[true]=UNIT_LIST_ENEMY_HEROES, [false]=UNIT_LIST_ALLIED_HEROES};
enums.creep_list = {[true]=UNIT_LIST_ENEMY_CREEPS, [false]=UNIT_LIST_ALLIED_CREEPS};

enums.push_modes = {BOT_MODE_PUSH_TOWER_TOP, BOT_MODE_PUSH_TOWER_MID, BOT_MODE_PUSH_TOWER_BOT};
enums.modes = {BOT_MODE_LANING, BOT_MODE_ATTACK, BOT_MODE_ROAM, BOT_MODE_RETREAT, BOT_MODE_SECRET_SHOP, BOT_MODE_SIDE_SHOP,
BOT_MODE_PUSH_TOWER_TOP, BOT_MODE_PUSH_TOWER_MID, BOT_MODE_PUSH_TOWER_BOT, BOT_MODE_DEFEND_TOWER_TOP, BOT_MODE_DEFEND_TOWER_MID, BOT_MODE_DEFEND_TOWER_BOT,
BOT_MODE_ASSEMBLE, BOT_MODE_TEAM_ROAM, BOT_MODE_FARM, BOT_MODE_DEFEND_ALLY, BOT_MODE_EVASIVE_MANEUVERS, BOT_MODE_ROSHAN, BOT_MODE_ITEM, BOT_MODE_WARD};

enums.experience_range = 1500;

enums.timer = {
    STUN = "stun_timer",
    SLOW = "slow_timer",
    BUFF = "buff_timer",
    SAVE = "save_timer",
    NONE = nil,
    FAKE = "fake_timer",
};
return enums;