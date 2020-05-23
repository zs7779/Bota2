utils = require(GetScriptDirectory().."/utils");
enums = require(GetScriptDirectory().."/enums");
-- eventually any decision use GetUnitlist not GetNearby need to do here

local update_time = 0;
-- Called every frame. Returns floating point values between 0 and 1 that represent the desires for pushing the top, middle, and bottom lanes, respectively.
function UpdatePushLaneDesires()
    if GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS then
        return {0, 0, 0};
    end
    local team = GetTeam();
    local enemy_team = GetOpposingTeam();
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
            if not siege and friend:GetActiveMode() == enums.push_modes[lane] then
                for _, creep in pairs(friend:GetNearbyCreeps(900, false)) do
                    if creep:IsAlive() and creep:GetUnitName() == enums.siege_creep_name[team] then
                        siege = true;
                    end
                end
            end
        end
        if push_desire[lane] > 0 and siege then
            push_desire[lane] = push_desire[lane] + 0.1;
        end
        push_desire[lane] = push_desire[lane] * enums.tower_importance[team][lane];
    end
    return push_desire;
end
-- Called every frame. Returns floating point values between 0 and 1 that represent the desires for defending the top, middle, and bottom lanes, respectively.
function UpdateDefendLaneDesires()
    if GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS then
        return {0, 0, 0};
    end
    local team = GetTeam();
    local enemy_team = GetOpposingTeam();
    local defend_desire = {0, 0, 0};
    local enemy_heroes = GetUnitList( UNIT_LIST_ENEMY_HEROES );
    local friend_heroes = GetUnitList( UNIT_LIST_ALLIED_HEROES );
    local enemy_distances = {};
    for lane = 1, 3 do
        local tower = utils.GetLaneTower(team, lane);
        if tower ~= nil then
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
            if enemy_creeps ~= nil then
                if #enemy_creeps > 2 then
                    defend_desire[lane] = defend_desire[lane] + 0.2;
                end
                local siege = DotaTime() > 1200;
                if not siege then
                    for _, creep in pairs(enemy_creeps) do
                        if creep:IsAlive() and creep:GetUnitName() == enums.siege_creep_name[team] then
                            siege = true;
                        end
                    end
                end
                if defend_desire[lane] > 0 and siege then
                    defend_desire[lane] = defend_desire[lane] + 0.2;
                end
            end
            defend_desire[lane] = defend_desire[lane] * enums.tower_importance[team][lane];
        end
    end
    return defend_desire;
end
-- Called every frame. Returns floating point values between 0 and 1 that represent the desires for farming the top, middle, and bottom lanes, respectively.
function UpdateFarmLaneDesires()
    if GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS then
        return {0, 0, 0};
    end
    local team = GetTeam();
    local enemy_team = GetOpposingTeam();
    -- GetHeroLastSeenInfo
    -- GetUnitPotentialValue
    local farm_desire = {0.5, 0.5, 0.5};
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
                farm_desire[lane] = farm_desire[lane] - 0.09;
            end
        end
        local enemy_tower = utils.GetLaneTower(enemy_team, lane);
        if enemy_tower ~= nil and enemy_tower:IsAlive() and GetUnitToLocationDistance(enemy_tower, lane_front_locations[lane]) < 1600 then
            farm_desire[lane] = farm_desire[lane] - 0.05;
        end
        for _, friend in pairs(friend_heroes) do
            if friend:IsAlive() and GetUnitToLocationDistance(friend, lane_front_locations[lane]) < 1600 then
                farm_desire[lane] = farm_desire[lane] + 0.09;
            end
        end
        local tower = utils.GetLaneTower(team, lane);
        if tower ~= nil and tower:IsAlive() and GetUnitToLocationDistance(tower, lane_front_locations[lane]) < 1600 then
            farm_desire[lane] = farm_desire[lane] + 0.05;
        end
        farm_desire[lane] = farm_desire[lane] * enums.farm_safty[team][lane];
    end
    if DotaTime() > update_time then
        update_time = update_time + 30;
    end
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