utils = require(GetScriptDirectory().."/utils");
enums = require(GetScriptDirectory().."/enums");
require(GetScriptDirectory().."/CDOTA_utils");
-- eventually any decision use GetUnitlist not GetNearby need to do here

local update_time = 0;
local enemy_heroes_status = {};
local friend_heroes_status = {};
local friends_mean_health = 0;
local we_have_aegis = false;
local roshan_time = 0;
local time;
local team;
local enemy_team;
local game_started = false;

function UpdateEnemyHeroes()
    -- update any enemy you can see, OK to use sparsely. every 5 second?
    local enemy_heroes = GetUnitList( UNIT_LIST_ENEMY_HEROES );
    local current_status = {};
    for _, enemy in pairs(enemy_heroes) do
        local enemy_id = enemy:GetPlayerID();
        if IsHeroAlive(enemy_id) then
            local last_seen = GetHeroLastSeenInfo(enemy_id);
            local stat = {handle = enemy, health = enemy:GetHealth(), power = enemy:EstimatePower(true),
                          level = enemy:GetLevel(), last_seen_info = last_seen[1],
                          speed = enemy:GetCurrentMovementSpeed(), networth = enemy:GetNetWorth()};
            if current_status[enemy_id] == nil then
                current_status[enemy_id] = stat;
            else
                -- todo: use health because illusions are more squishy? but if you only damage one target the handle will keep changing
                if stat.health > current_status[enemy_id].health then
                    current_status[enemy_id] = stat;
                end
            end
            enemy:GetAbilities();
                
        end
    end
    for enemy_id, enemy_status in pairs(current_status) do
        enemy_heroes_status[enemy_id] = enemy_status;
    end
end

function UpdateFriendHeroes()
    -- update any enemy you can see, OK to use sparsely. every 5 second?
    local friend_heroes = GetUnitList( UNIT_LIST_ALLIED_HEROES );
    local total_health, total_friends = 0, 0;
    for _, friend in pairs(friend_heroes) do
        local friend_id = friend:GetPlayerID();
        if not friend:IsIllusion() and IsHeroAlive(friend_id) then
            local stat = {handle = friend, health = friend:GetHealth(), max_health = friend:GetMaxHealth(), power = friend:EstimatePower(true),
                          level = friend:GetLevel(), speed = friend:GetCurrentMovementSpeed(), networth = friend:GetNetWorth()};
            total_health = total_health + stat.max_health;
            total_friends = total_friends + 1;
            friend_heroes_status[friend_id] = stat;
            if not friend.is_initialized or not friend.position or not friend.abilities or not friend.neutral_camps then
                friend:InitializeBot();
            else
                friend:GetAbilities();
                -- friend:GetPlayerPosition();
            end
        end
    end
    friends_mean_health = total_health / total_friends;
    for _, friend_stat in pairs(friend_heroes_status) do
        friend_stat.handle.safety_factor = friend_stat.max_health / friends_mean_health;
    end
end

function TeamThink()
    if GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS then
        return;
    end
    time = DotaTime();
    team = GetTeam();
    enemy_team = GetOpposingTeam();
    UpdateEnemyHeroes();
    UpdateFriendHeroes();
    -- todo: look for enemy warding
    -- todo: calculate enemy networth
    game_started = true;
end

-- Called every frame. Returns floating point values between 0 and 1 that represent the desires for pushing the top, middle, and bottom lanes, respectively.
function UpdatePushLaneDesires()
    if not game_started then
        return {0, 0, 0};
    end
    local old_push_desire = {GetPushLaneDesire(LANE_TOP), GetPushLaneDesire(LANE_MID), GetPushLaneDesire(LANE_BOT)};
    -- 1. lane front at tower 2. friend at tower 3. enemy (potential location) at tower assume any enemy missing long enough to be at tower
    local push_desire = {0.5, 0.5, 0.5};
    local friend_heroes = GetUnitList( UNIT_LIST_ALLIED_HEROES );
    -- local lanes = {LANE_TOP, LANE_MID, LANE_BOT};
    local lane_front_locations = {GetLaneFrontLocation(team, LANE_TOP, 0), GetLaneFrontLocation(team, LANE_MID, 0), GetLaneFrontLocation(team, LANE_BOT, 0)};
    for lane = 1, 3 do
        local enemy_potential = {};
        -- DebugDrawCircle(lane_front_locations[lane], 200, 255,0,0)
        for enemy_id, enemy_stat in pairs(enemy_heroes_status) do
            local enemy = enemy_stat.handle;
            if IsHeroAlive(enemy_id) then
                if enemy_potential[enemy_id] == nil then
                    enemy_potential[enemy_id] = utils.EnemyPotentialAtLocation(enemy_stat, lane_front_locations[lane], 2000);
                else
                    enemy_potential[enemy_id] = math.max(enemy_potential[enemy_id], utils.EnemyPotentialAtLocation(enemy_stat, lane_front_locations[lane], 2000));
                end
            end
        end
        
        for eid, ep in pairs(enemy_potential) do
            DebugDrawText(0+lane*100, 0+eid*20,tostring(ep),255,0,0)
            if ep > 0.1 then
                -- if ep < 1 then
                --     print(lane, GetSelectedHeroName(eid), "pt", ep)
                -- end
                push_desire[lane] = push_desire[lane] - 0.1 * ep;
            end
        end
        local siege = time > 1200 and 1 or 0.8;
        for _, friend in pairs(friend_heroes) do
            if not siege and friend:GetActiveMode() == enums.push_modes[lane] then
                for _, creep in pairs(friend:GetNearbyCreeps(1600, false)) do
                    if creep:IsAlive() and creep:GetUnitName() == enums.siege_creep_name[team] then
                        siege = 1;
                    end
                end
            end
        end
        for fid, friend in pairs(friend_heroes) do
            if friend:IsAlive() and friend:GetActiveMode() ~= BOT_MODE_RETREAT and GetUnitToLocationDistance(friend, lane_front_locations[lane]) < 1600 then
                push_desire[lane] = push_desire[lane] + siege * 0.1;
                -- print(fid,friend:GetUnitName(),push_desire[lane])
            end
        end
        push_desire[lane] = push_desire[lane] * enums.tower_importance[team][lane];
        push_desire[lane] = old_push_desire[lane] + (push_desire[lane] - old_push_desire[lane]) * 0.05;
    end
    return push_desire;
end
-- Called every frame. Returns floating point values between 0 and 1 that represent the desires for defending the top, middle, and bottom lanes, respectively.
function UpdateDefendLaneDesires()
    if not game_started then
        return {0, 0, 0};
    end
    local old_defend_desire = {GetDefendLaneDesire(LANE_TOP), GetDefendLaneDesire(LANE_MID), GetDefendLaneDesire(LANE_BOT)};
    -- 1. lane front at tower 2. friend at tower 3. enemy (potential location) at tower assume any enemy missing long enough to be at tower
    local defend_desire = {0, 0, 0};
    local friend_heroes = GetUnitList( UNIT_LIST_ALLIED_HEROES );
    local lane_front_locations = {GetLaneFrontLocation(enemy_team, LANE_TOP, 0), GetLaneFrontLocation(enemy_team, LANE_MID, 0), GetLaneFrontLocation(enemy_team, LANE_BOT, 0)};
    for lane = 1, 3 do
        local tower, tier = utils.GetLaneTower(team, lane);
        local enemy_potential = {};
        -- DebugDrawCircle(lane_front_locations[lane], 200, 255,0,0)
        for enemy_id, enemy_stat in pairs(enemy_heroes_status) do
            local enemy = enemy_stat.handle;
            if IsHeroAlive(enemy_id) then
                if enemy_potential[enemy_id] == nil then
                    enemy_potential[enemy_id] = utils.EnemyPotentialAtLocation(enemy_stat, tower:GetLocation(), 2000);
                else
                    enemy_potential[enemy_id] = math.max(enemy_potential[enemy_id], utils.EnemyPotentialAtLocation(enemy_stat, tower:GetLocation(), 2000));
                end
            end
        end
        local siege = time > 1200 and 1 or 0.6;
        local creeps = tower:GetNearbyCreeps(1600, true);
        if not siege and not creeps then
            for _, creep in pairs() do
                if not siege and creep:IsAlive() and creep:GetUnitName() == enums.siege_creep_name[team] then
                    siege = 1;    
                end
            end
        end
        if tier < 4 and GetUnitToLocationDistance(tower, lane_front_locations[lane]) <= 2000 or
           tier >= 4 and GetUnitToLocationDistance(tower, lane_front_locations[lane]) <= 4000 then
            defend_desire[lane] = defend_desire[lane] + siege * 0.4
        end
        for eid, ep in pairs(enemy_potential) do
            DebugDrawText(0+lane*100, 150+eid*20,tostring(ep),255,0,0)
            if ep > 0 then
                defend_desire[lane] = defend_desire[lane] + siege * ep * 0.3;
            end
        end
        
        defend_desire[lane] = math.min(defend_desire[lane] * enums.tower_importance[team][lane], 1);
        defend_desire[lane] = old_defend_desire[lane] + (defend_desire[lane] - old_defend_desire[lane]) * 0.05;
    end
    return defend_desire;
end
-- Called every frame. Returns floating point values between 0 and 1 that represent the desires for farming the top, middle, and bottom lanes, respectively.
function UpdateFarmLaneDesires()
    if not game_started then
        return {0, 0, 0};
    end
    local old_farm_desire = {GetFarmLaneDesire(LANE_TOP), GetFarmLaneDesire(LANE_MID), GetFarmLaneDesire(LANE_BOT)};
    local farm_desire = {0, 0, 0};
    -- 1. lane front at tower 2. friend at tower 3. enemy (potential location) at tower assume any enemy missing long enough to be at tower
    local farm_danger = {0, 0, 0};
    -- local lanes = {LANE_TOP, LANE_MID, LANE_BOT};
    local lane_front_locations = {GetLaneFrontLocation(enemy_team, LANE_TOP, 0), GetLaneFrontLocation(enemy_team, LANE_MID, 0), GetLaneFrontLocation(enemy_team, LANE_BOT, 0)};
    for lane = 1, 3 do
        local enemy_potential = {};
        -- DebugDrawCircle(lane_front_locations[lane], 200, 255,0,0)
        for enemy_id, enemy_stat in pairs(enemy_heroes_status) do
            local enemy = enemy_stat.handle;
            if IsHeroAlive(enemy_id) then
                if enemy_potential[enemy_id] == nil then
                    enemy_potential[enemy_id] = utils.EnemyPotentialAtLocation(enemy_stat, lane_front_locations[lane], 2000);
                else
                    enemy_potential[enemy_id] = math.max(enemy_potential[enemy_id], utils.EnemyPotentialAtLocation(enemy_stat, lane_front_locations[lane], 2000));
                end
            end
        end
        
        for eid, ep in pairs(enemy_potential) do
            DebugDrawText(0+lane*100, 300+eid*20,tostring(ep),255,0,0)
            if ep > 0 then
                farm_danger[lane] = farm_danger[lane] + enemy_heroes_status[eid].power * ep;
            end
        end
        farm_desire[lane] = 1 - math.min(farm_danger[lane] / friends_mean_health * enums.tower_importance[team][lane], 1);
        farm_desire[lane] = old_farm_desire[lane] + (farm_desire[lane] - old_farm_desire[lane]) * 0.05;
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