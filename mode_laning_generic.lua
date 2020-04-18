utils = require(GetScriptDirectory().."/utils");
mode_utils = require(GetScriptDirectory().."/mode_utils");
require(GetScriptDirectory().."/CDOTA_utils");

update_time = 15;
stupidity = 1.0;
-- Called every ~300ms, and needs to return a floating-point value between 0 and 1 that indicates how much this mode wants to be the active mode.
function GetDesire()
    local this_bot = GetBot();
    local time = DotaTime();
    if not this_bot.is_initialized then
        this_bot:InitializeBot();
    end
    if not this_bot:IsAlive() then
        return 0;
    end

    local this_bot_level = this_bot:GetLevel();
    local lane_front = GetLaneFrontLocation(this_bot:GetTeam(), this_bot:GetAssignedLane(), 0);
    local this_bot_tower = utils.GetLaneTower(this_bot:GetTeam(), this_bot:GetAssignedLane());
    -- Time < 5 minutes or level < 7
    -- and if laning enemy is not too strong
    -- if lane is not too far from tower

    if time > update_time then
        -- print(this_bot:GetUnitName().." Tower "..GetUnitToLocationDistance(this_bot_tower, lane_front));
        update_time = update_time + 30;
    end

    if this_bot.position <= 3 and 
        (this_bot.lane_is_hard or this_bot:EstimateEnimiesPower(1200) > stupidity * this_bot:GetMaxHealth()) then
        this_bot.lane_is_hard = true;
        return 0;
    end

    if time < 0 or time < 600 and this_bot_level <= 6 and this_bot_tower ~= nil and GetUnitToLocationDistance(this_bot_tower, lane_front) < 4000 then
        local lane_danger = 0;
        lane_danger = this_bot_tower:EstimateEnimiesPower(1600);
        lane_danger = math.max(this_bot:EstimateEnimiesPower(1200), lane_danger);
        if lane_danger < stupidity * this_bot:GetHealth() then
            return mode_utils.mode_desire.laning;
        end
    end
    -- GetAssignedLane() 
    -- vector GetLaneFrontLocation( nTeam, nLane, fDeltaFromFront ) 
    -- GetUnitToLocationDistance( hUnit, vLocation ) 
    return 0;	
end
