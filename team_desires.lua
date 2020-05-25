utils = require(GetScriptDirectory().."/utils");
enums = require(GetScriptDirectory().."/enums");
require(GetScriptDirectory().."/CDOTA_utils");
-- eventually any decision use GetUnitlist not GetNearby need to do here

local update_time = 0;
local enemy_heroes_status = {};
local friend_heroes_status = {};
local we_have_aegis = false;

function UpdateEnemyHeroes()
    -- update any enemy you can see
    local enemy_heroes = GetUnitList( UNIT_LIST_ENEMY_HEROES );
    local current_status = {};
    for _, enemy in pairs(enemy_heroes) do
        local enemy_id = enemy:GetPlayerID();
        if IsHeroAlive(enemy_id) then
            local last_seen = GetHeroLastSeenInfo(enemy_id);
            local stat = {handle = enemy, health = enemy:GetHealth(), power = enemy:EstimatePower(true),
                          last_seen_info = last_seen[1],
                          speed = enemy:GetCurrentMovementSpeed(), networth = enemy:GetNetWorth()};
            if current_status[enemy_id] == nil then
                current_status[enemy_id] = stat;
            else
                -- todo: use health because illusions are more squishy? but if you only damage one target the handle will keep changing
                if stat.health > current_status[enemy_id].health then
                    current_status[enemy_id] = stat;
                end
            end
        end
    end
    for enemy_id, enemy_status in pairs(current_status) do
        enemy_heroes_status[enemy_id] = enemy_status;
    end
end

-- Called every frame. Returns floating point values between 0 and 1 that represent the desires for pushing the top, middle, and bottom lanes, respectively.
function UpdatePushLaneDesires()
    if GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS then
        return {0, 0, 0};
    end
    UpdateEnemyHeroes();
    local time = DotaTime();
    local team = GetTeam();
    local enemy_team = GetOpposingTeam();
    -- 1. lane front at tower 2. friend at tower 3. enemy (potential location) at tower assume any enemy missing long enough to be at tower
    local push_desire = {0.5, 0.5, 0.5};
    local friend_heroes = GetUnitList( UNIT_LIST_ALLIED_HEROES );
    -- local lanes = {LANE_TOP, LANE_MID, LANE_BOT};
    local lane_front_locations = {GetLaneFrontLocation(team, LANE_TOP, 600), GetLaneFrontLocation(team, LANE_MID, 600), GetLaneFrontLocation(team, LANE_BOT, 600)};
    local enemy_potential = {{}, {}, {}};
    local cc = {{255,0,0},{0,255,0},{0,0,255}}
    for lane = 1, 3 do
        DebugDrawCircle(lane_front_locations[lane], 200, 255,0,0)
        for enemy_id, enemy_stat in pairs(enemy_heroes_status) do
            local enemy = enemy_stat.handle;
            if IsHeroAlive(enemy_id) then
                local enemy_distance = GetUnitToLocationDistance(enemy, lane_front_locations[lane]);
                if enemy_distance > 0 and enemy_distance < 2000 then
                    enemy_potential[lane][enemy_id] = 256;
                elseif enemy_potential[lane][enemy_id] == nil then
                    enemy_potential[lane][enemy_id] = GetUnitPotentialValue(enemy, lane_front_locations[lane], 2000);
                else
                    enemy_potential[lane][enemy_id] = math.max(enemy_potential[lane][enemy_id], GetUnitPotentialValue(enemy, lane_front_locations[lane], 2000));
                end
            end
        end
        for eid, ep in pairs(enemy_potential[lane]) do
            DebugDrawText(0+lane*100, 0+eid*20,tostring(ep),cc[lane][1],cc[lane][2],cc[lane][3])
            if ep > 0 then
                if ep < 256 then
                    print(lane, eid, GetSelectedHeroName(eid), "potential", ep)
                end
                push_desire[lane] = push_desire[lane] - 0.1;
            end
        end
        local siege = time > 1200 and 0.1 or 0.08;
        for _, friend in pairs(friend_heroes) do
            if not siege and friend:GetActiveMode() == enums.push_modes[lane] then
                for _, creep in pairs(friend:GetNearbyCreeps(900, false)) do
                    if creep:IsAlive() and creep:GetUnitName() == enums.siege_creep_name[team] then
                        siege = 1;
                    end
                end
            end
        end
        for fid, friend in pairs(friend_heroes) do
            if friend:IsAlive() and friend:GetActiveMode() ~= BOT_MODE_RETREAT and GetUnitToLocationDistance(friend, lane_front_locations[lane]) < 1600 then
                push_desire[lane] = push_desire[lane] + siege;
                -- print(fid,friend:GetUnitName(),push_desire[lane])
            end
        end
        push_desire[lane] = push_desire[lane] * enums.tower_importance[team][lane];
        if push_desire[lane] < 0 or push_desire[lane] > 1 then
            print(push_desire[lane])
        end
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