local utils = {};

function utils.SecondsToClock(seconds)
    -- https://gist.github.com/jesseadams/791673
    local seconds = tonumber(math.abs(seconds));
    local min_str = string.format("%02.f", math.floor(seconds/60));
    local sec_str = string.format("%02.f", math.floor(seconds - min_str *60));
    return min_str..":"..sec_str
end

function utils.IsNight()
    local time_of_day = GetTimeOfDay();
    return time_of_day < 0.25 or time_of_day > 0.75;
end

function utils.VectorAdd(v1, v2)
    v1[1] = v1[1] + v2[1];
    v1[2] = v1[2] + v2[2];
    return v1;
end

function utils.GetLaneTower(team, lane)
    for i, t in pairs(enums.towers[lane]) do
        local tower = GetTower(team, t);
        if tower ~= nil and tower:IsAlive() then
            return tower;
        end
    end
    for i, b in pairs(enums.barracks[lane]) do
        local barrack = GetBarracks(team, b);
        if barrack ~= nil and barrack:IsAlive() then
            return barrack;
        end
    end
    for i, t in pairs(enums.base_towers) do
        local tower = GetTower(team, t);
        if tower ~= nil and tower:IsAlive() then
            return tower;
        end
    end
    return GetAncient(team);
end

function utils.GetOutposts()
    local ally_outpost, enemy_outpost = nil, nil;
    for _, u in pairs(GetUnitList(UNIT_LIST_ALLIED_BUILDINGS)) do
        if string.find(u:GetUnitName(), "Outpost") then
            ally_outpost = u;
        end
    end
    for _, u in pairs(GetUnitList(UNIT_LIST_ENEMY_BUILDINGS)) do
        if string.find(u:GetUnitName(), "Outpost") then
            enemy_outpost = u;
        end
    end
    return {ally_outpost, enemy_outpost};
end

function utils.GuessCreepPosition()
    
end

function utils.GetFlag(behavior, flag)
    if flag == 0 then
        return 0;
    end
    return math.floor(behavior / flag) % 2 == 1; -- because if 0 is true
end

function utils.GetDistance(a, b) -- maybe its easier to just worke with squared distance all the time..
	return math.sqrt((a[1] - b[1]) * (a[1] - b[1]) + (a[2] - b[2]) * (a[2] - b[2]));
end

function utils.GetTimeToTravel(from_loc, to_loc, speed, range)
    local range = range or 100;
    local dist = math.max(utils.GetDistance(from_loc, to_loc) - range, 0);
    return dist / speed;
end

function utils.EnemyPotentialAtLocation(enemy_stat, location, range)
    if enemy_stat == nil and enemy_stat.last_seen_info == nil and enemy_stat.speed == nil then
        print(enemy_stat,enemy_stat.last_seen_info, enemy_stat.speed)
    end
    if enemy_stat ~= nil and enemy_stat.last_seen_info ~= nil and enemy_stat.speed ~= nil then
        local time_to_travel = utils.GetTimeToTravel(enemy_stat.last_seen_info.location, location, enemy_stat.speed, range);
        -- print(time_to_travel, enemy_stat.last_seen_info.time_since_seen)
        if time_to_travel > enemy_stat.last_seen_info.time_since_seen then
            return 0;
        else
            -- if enemy can get to location in time, and missing less than 30s threat=1x, 40s threat=0.75x, 50s threat=0.6x
            return math.min(5 / math.max(enemy_stat.last_seen_info.time_since_seen, 1), 1);
        end
    end
    return 0;
end

function utils.AddAvoidance(vision)
    -- todo: vision can be nil or list of wards
    local added_handles = {};
    local team = GetTeam();
    for _, towers in pairs(enums.towers) do
        for _, t in pairs(towers) do
            local tower = GetTower(team, t);
            if tower ~= nil and tower:IsAlive() then
                if vision then
                    added_handles[#added_handles+1] = AddAvoidanceZone(tower:GetLocation(), tower:GetCurrentVisionRange());
                else
                    added_handles[#added_handles+1] = AddAvoidanceZone(tower:GetLocation(), 700);
                    -- print("avoid", added_handles[#added_handles])
                end
            end
        end
    end
    if vision then
        for _, ward in pairs(vision) do
            added_handles[#added_handles+1] = AddAvoidanceZone(ward, 1400);
        end
    end
    return added_handles;
end

function utils.RemoveAvoidance(av_zones)
    for _, zone in pairs(av_zones) do
        RemoveAvoidanceZone(zone);
    end
end

return utils;