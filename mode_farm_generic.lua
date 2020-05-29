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
    -- if this_bot.position == 5 then
    --     for _, av in pairs(GetAvoidanceZones()) do
    --         DebugDrawCircle(av.location, av.radius, 255, 100, 100);
    --     end
    -- end
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
    local this_bot_location = this_bot:GetLocation();
    local time = DotaTime();
    local attack_range = this_bot:GetAttackRange() + 100;
    this_bot:FindFarm();
    if this_bot.farm_lane ~= nil then
        -- print(this_bot:GetUnitName(), this_bot.farm_lane)
        local lane_front_location = GetLaneFrontLocation(enemy_team, enums.lanes[this_bot.farm_lane], -attack_range);
        if this_bot:IsAtLocation(lane_front_location, 150) and IsLocationVisible(lane_front_location) then
            local creeps = this_bot:GetNearbyCreeps(1600, true);
            this_bot:FarmCreeps(creeps, this_bot:GetAttackDamage());
        else
            this_bot:MoveToLocationOnPath(lane_front_location);
        end
    else
        local neutral_camp;
        if this_bot.pull ~= nil and this_bot.pull_state.state == "success" then
            neutral_camp = this_bot.pull;
        else
            neutral_camp = this_bot:FindNeutralCamp(false);
        end
        if neutral_camp ~= nil then
            if this_bot:IsAtLocation(neutral_camp.location, 350) and IsLocationVisible(neutral_camp.location) then
                local neutrals = this_bot:GetNearbyCreeps(1200, true);
                this_bot:FarmCreeps(neutrals, this_bot:GetAttackDamage());
            else
                this_bot:MoveToLocationOnPath(neutral_camp.location);
            end
        end
    end
end

function OnStart()
    avoidance_zone = utils.AddAvoidance(nil);
end

function OnEnd()
    utils.RemoveAvoidance(avoidance_zone);
    GarbageCleaning();
end