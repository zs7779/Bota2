utils = require(GetScriptDirectory().."/utils");
enums = require(GetScriptDirectory().."/enums");
require(GetScriptDirectory().."/CDOTA_utils");

update_time = 0;
next_outpost_time = 600;
local function GarbageCleaning()
    local this_bot = GetBot();
    this_bot.roam = nil;
    this_bot.outpost = nil;
    this_bot.outpost_time = nil;
end

function GetDesire()
    local this_bot = GetBot();
    local time = DotaTime();
    if not this_bot.is_initialized then
        this_bot:InitializeBot();
    end
    if not this_bot:IsAlive() then
        GarbageCleaning();
        return 0;
    end

    if time > update_time and this_bot.position == 5 then
        update_time = update_time + 30;
    end
    -- main purpose of roam should be to move bot to location, not actually do the thing
    -- roam for single person roam/ward/rune, team roam for gank
    -- determine roam to help teammate
    this_bot.roam = this_bot:FindFriendNeedHelp();
    -- determine roam to outpost
    if this_bot.outposts == nil then
        this_bot.outposts = utils.GetOutposts();
    else
        for _, outpost in pairs(this_bot.outposts) do
            if outpost:GetTeam() ~= this_bot:GetTeam() and GetUnitToUnitDistance(this_bot, outpost) < 400 then -- not occupied and close by
                this_bot.outpost = outpost;
                this_bot.outpost_time = next_outpost_time;
            end
        end
    end

    -- if time > 0 then
        if not this_bot:FriendNeedHelpNearby(1600) then
            if (this_bot.rune or this_bot.roam or this_bot.outpost or this_bot.pull or this_bot.ward) then
                return enums.mode_desire.roam;
            end
        end
    -- end
	return 0;
end

function Think()
    local this_bot = GetBot();
    local this_bot_location = this_bot:GetLocation();
    local roam_location = nil;
    local function MoveToWaypoint(distance, table_length_I_assume, waypoints)
        if distance > 0 and waypoints ~= nil and #waypoints > 0 then
            this_bot:Action_MovePath(waypoints);    
        end
    end


    -- the get desires should determine if the runes or wards or rotates are no longer valid
    -- determined by mode rune
    if this_bot.rune then
        roam_location = GetRuneSpawnLocation(this_bot.rune);
    -- -- determined by roam
    -- elseif this_bot.roam then
    --     print(this_bot.roam:GetUnitName());
    -- -- determined by roam
    -- elseif this_bot.outpost then
    --     print(this_bot.outpost:GetUnitName());
    -- -- determined by lane
    -- elseif this_bot.pull then
    --     print(this_bot.pull[1]);
    -- -- determined by ward
    -- elseif this_bot.ward then
    --     print(this_bot.ward);
    end
    if roam_location ~= nil then
        GeneratePath(this_bot_location, roam_location, GetAvoidanceZones(), MoveToWaypoint);
    end
end

function OnEnd()
    GarbageCleaning();
end