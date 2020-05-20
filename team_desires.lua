utils = require(GetScriptDirectory().."/utils");

local team = GetTeam();
local enemy_team = GetOpposingTeam();
local push_modes = {BOT_MODE_PUSH_TOWER_TOP, BOT_MODE_PUSH_TOWER_MID, BOT_MODE_PUSH_TOWER_BOT};
local siege_creep_name = {TEAM_RADIANT = "npc_dota_goodguys_siege", TEAM_DIRE = "npc_dota_badguys_siege"};
local towers = {LANE_TOP = {TOWER_TOP_1, TOWER_TOP_2, TOWER_TOP_3}, LANE_MID = {TOWER_MID_1, TOWER_MID_2, TOWER_MID_3}, LANE_BOT = {TOWER_BOT_1, TOWER_BOT_2, TOWER_BOT_3}};
local tower_importance = {TEAM_RADIANT = {0.8, 1.0, 0.6}, TEAM_DIRE = [0.6, 1.0, 0.8]};
local farm_safty = {TEAM_RADIANT = {1.0, 0.6, 0.8}, TEAM_DIRE = [0.8, 0.6, 1.0]};

-- Called every frame. Returns floating point values between 0 and 1 that represent the desires for pushing the top, middle, and bottom lanes, respectively.
function UpdatePushLaneDesires()
    -- 1. lane front at tower 2. friend at tower 3. enemy (potential location) at tower assume any enemy missing long enough to be at tower
    local push_desire = {0.5, 0.5, 0.5};
    local enemy_heroes = GetUnitList( UNIT_LIST_ENEMY_HEROES );
    local friend_heroes = GetUnitList( UNIT_LIST_ALLIED_HEROES );
    -- local lanes = {LANE_TOP, LANE_MID, LANE_BOT};
    local lane_front_locations = {GetLaneFrontLocation(team, LANE_TOP, 0), GetLaneFrontLocation(team, LANE_MID, 0), GetLaneFrontLocation(team, LANE_BOT, 0)};
    local enemy_distances = {};
    for lane = 1, 3 do
        for _, enemy in pairs(enemy_heroes) do
            if enemy:IsAlive() and enemy:CanBeSeen() then
                local enemy_id = enemy:GetPlayerID();
                if enemy_distances[enemy_id] == nil then
                    enemy_distances[enemy_id] = GetUnitToLocationDistance(enemy, lane_front_locations[lane]);
                else
                    enemy_distances[enemy_id] = math.min(enemy_distances[enemy_id], GetUnitToLocationDistance(enemy, lane_front_locations[lane]));
                end
            end
        end
        for _, enemy_distance in pairs(enemy_distances) do
            if enemy_distance < 2000 then
                push_desire[lane] = push_desire[lane] - 0.1;
            end
        end
        local siege = DotaTime() > 1200;
        for _, friend in pairs(friend_heroes) do
            if friend:IsAlive() and GetUnitToLocationDistance(friend, lane_front_locations[lane]) < 1600 then
                push_desire[lane] = push_desire[lane] + 0.08;
            end
            if not siege and friend:GetActiveMode() == push_modes[lane] then
                for _, creep in pairs(friend:GetNearbyCreeps(900, false)) do
                    if creep:IsAlive() and creep:GetUnitName() == siege_creep_name[team] then
                        siege = true;
                    end
                end
            end
        end
        if push_desire[lane] > 0 and siege then
            push_desire[lane] = push_desire[lane] + 0.1;
        end
        push_desire[lane] = push_desire[lane] * tower_importance[team][lane];
    end
    return push_desire;
end
-- Called every frame. Returns floating point values between 0 and 1 that represent the desires for defending the top, middle, and bottom lanes, respectively.
function UpdateDefendLaneDesires()
    local defend_desire = {0, 0, 0};
    local enemy_heroes = GetUnitList( UNIT_LIST_ENEMY_HEROES );
    local friend_heroes = GetUnitList( UNIT_LIST_ALLIED_HEROES );
    local enemy_distances = {};
    for lane = 1, 3 do
        local tower = utils.GetLaneTower(team, lane);
        for _, enemy in pairs(enemy_heroes) do
            if enemy:IsAlive() and enemy:CanBeSeen() then
                local enemy_id = enemy:GetPlayerID();
                if enemy_distances[enemy_id] == nil then
                    enemy_distances[enemy_id] = GetUnitToUnitDistance(enemy, tower);
                else
                    enemy_distances[enemy_id] = math.min(enemy_distances[enemy_id], GetUnitToUnitDistance(enemy, tower));
                end
            end
        end
        for _, enemy_distance in pairs(enemy_distances) do
            if enemy_distance < 2000 then
                defend_desire[lane] = defend_desire[lane] + 0.2;
            end
        end
        if defend_desire[lane] > 0.6 then
            defend_desire[lane] = 0.6;
        end
        local enemy_creeps = tower:GetNearbyCreeps(900, true);
        if #enemy_creeps > 2 then
            defend_desire[lane] = defend_desire[lane] + 0.2;
        end
        local siege = DotaTime() > 1200;
        if not siege then
            for _, creep in pairs(enemy_creeps) do
                if creep:IsAlive() and creep:GetUnitName() == siege_creep_name[team] then
                    siege = true;
                end
            end
        end
        if defend_desire[lane] > 0 and siege then
            defend_desire[lane] = defend_desire[lane] + 0.2;
        end
        defend_desire[lane] = defend_desire[lane] * tower_importance[team][lane];
    end
    return defend_desire;
end
-- Called every frame. Returns floating point values between 0 and 1 that represent the desires for farming the top, middle, and bottom lanes, respectively.
function UpdateFarmLaneDesires()
    -- GetHeroLastSeenInfo
    -- GetUnitPotentialValue
    local farm_desire = {1.0, 1.0, 1.0};
    local enemy_heroes = GetUnitList( UNIT_LIST_ENEMY_HEROES );
    local friend_heroes = GetUnitList( UNIT_LIST_ALLIED_HEROES );
    local lane_front_locations = {GetLaneFrontLocation(enemy_team, LANE_TOP, 0), GetLaneFrontLocation(enemy_team, LANE_MID, 0), GetLaneFrontLocation(enemy_team, LANE_BOT, 0)};
    local enemy_distances = {};
    for lane = 1, 3 do
        for _, enemy in pairs(enemy_heroes) do
            if enemy:IsAlive() and enemy:CanBeSeen() then
                local enemy_id = enemy:GetPlayerID();
                if enemy_distances[enemy_id] == nil then
                    enemy_distances[enemy_id] = GetUnitToLocationDistance(enemy, lane_front_locations[lane]);
                else
                    enemy_distances[enemy_id] = math.min(enemy_distances[enemy_id], GetUnitToLocationDistance(enemy, lane_front_locations[lane]));
                end
            end
        end
        for _, enemy_distance in pairs(enemy_distances) do
            if enemy_distance < 2000 then
                farm_desire[lane] = farm_desire[lane] - 0.18;
            end
        end
        local enemy_tower = utils.GetLaneTower(enemy_team, lane);
        if enemy_tower:IsAlive() and GetUnitToLocationDistance(enemy_tower, lane_front_locations[lane]) < 1600 then
            push_desire[lane] = push_desire[lane] - 0.18;
        end
        for _, friend in pairs(friend_heroes) do
            if friend:IsAlive() and GetUnitToLocationDistance(friend, lane_front_locations[lane]) < 1600 then
                push_desire[lane] = push_desire[lane] + 0.18;
            end
        end
        local tower = utils.GetLaneTower(team, lane);
        if tower:IsAlive() and GetUnitToLocationDistance(tower, lane_front_locations[lane]) < 1600 then
            push_desire[lane] = push_desire[lane] + 0.18;
        end
    end
    farm_desire[lane] = farm_desire[lane] * farm_safty[team][lane];
    return farm_desire;
end
-- Called every frame. Returns a floating point value between 0 and 1 and a unit handle that represents the desire for someone to roam and gank a specified target.
-- function UpdateRoamDesire()
--     return {0, nil};
-- end
-- Called every frame. Returns a floating point value between 0 and 1 that represents the desire for the team to kill Roshan.
-- function UpdateRoshanDesire()
--     return 0;
-- end