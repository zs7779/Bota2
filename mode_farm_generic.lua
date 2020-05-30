utils = require(GetScriptDirectory().."/utils");
enums = require(GetScriptDirectory().."/enums");
require(GetScriptDirectory().."/CDOTA_utils");

local this_bot = GetBot();
local team = GetTeam();
local enemy_team = GetOpposingTeam();
local avoidance_zone = {};

function GarbageCleaning()
    this_bot.pull_camp = nil;
    this_bot.pull = nil;
    this_bot.neutral_camp = nil;
    this_bot.farm_lane = nil;
end

-- I'm having a sense the original farm mode was exclusively for jungle
-- maybe it should be just default mode, since farming is most passive?
-- Called every ~300ms, and needs to return a floating-point value between 0 and 1 that indicates how much this mode wants to be the active mode.
update_time = 0;
function GetDesire()
    if this_bot.position == 5 then
        for _, av in pairs(GetAvoidanceZones()) do
            DebugDrawCircle(av.location, av.radius, 255, 100, 100);
        end
    end
    local time = DotaTime();
    if not this_bot.is_initialized then
        this_bot:InitializeBot();
    end
    this_bot:RefreshNeutralCamp();
    if not this_bot:IsAlive() then
        return 0;
    end
    if time > update_time then
        if this_bot.farm_lane ~= nil then
            print(this_bot:GetUnitName().." farm is "..this_bot.farm_lane)
        end
        update_time = update_time + 10;
        -- print("enemy "..GetLaneFrontAmount(enemy_team, LANE_BOT, true))
        -- print("friend "..GetLaneFrontAmount(team, LANE_BOT, true))
    end
    if this_bot:WasRecentlyDamagedByAnyHero(3) then
        this_bot.pull_camp = nil;
    end
    return enums.mode_desire.farm;
end

-- function MoveToWaypoint(distance, table_length_I_assume, waypoints)
--     if distance > 0 and waypoints ~= nil and #waypoints > 0 then
--         this_bot:Action_MovePath(waypoints);    
--     end
-- end

function Think()
    if not this_bot:IsAlive() then
        return;
    end
    avoidance_zone = utils.AddAvoidance(nil);
    this_bot:FarmLane();
    this_bot:FarmNeutral();
    utils.RemoveAvoidance(avoidance_zone);
end

-- function OnStart()
-- end

function OnEnd()
    GarbageCleaning();
end