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

function utils.GetLaneTower(team, lane)
    local towers = {[LANE_TOP]={TOWER_TOP_1, TOWER_TOP_2, TOWER_TOP_3},
                    [LANE_MID]={TOWER_MID_1, TOWER_MID_2, TOWER_MID_3}, 
                    [LANE_BOT]={TOWER_BOT_1, TOWER_BOT_2, TOWER_BOT_3}};
    for _, i in pairs(towers[lane]) do
        local tower = GetTower(team, i);
        if tower:IsAlive() then
            return tower;
        end
    end
    return nil;
end

return utils;