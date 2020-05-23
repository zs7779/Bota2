utils = require(GetScriptDirectory().."/utils");
enums = require(GetScriptDirectory().."/enums");
require(GetScriptDirectory().."/CDOTA_utils");

update_time = 0;
next_outpost_time = 600;
function GarbageCleaning()
    local this_bot = GetBot();
    this_bot.roam = nil;
    this_bot.pull = nil;
    this_bot.outpost = nil;
    this_bot.outpost_time = nil;
end

local this_bot = GetBot();

function GetDesire()
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
    if this_bot.position == 5 and time < 600 and not this_bot:WasRecentlyDamagedByAnyHero(1) then
        if this_bot.pull_camp == nil then
            this_bot.pull = nil;
            local pull_camp = this_bot:FindNeutralCamp(true);
            if pull_camp ~= nil then
                this_bot.pull_camp = pull_camp;
                this_bot.pull = pull_camp.location;
                this_bot.pull_state = "pull";
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

-- function MoveToWaypoint(distance, table_length_I_assume, waypoints)
--     if distance > 0 and waypoints ~= nil and #waypoints > 0 then
--         this_bot:Action_MovePath(waypoints);    
--     end
-- end

function Think()
    local time = DotaTime();
    local this_bot_location = this_bot:GetLocation();
    local roam_location = nil;

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
    elseif this_bot.pull then
        if this_bot.pull_state == "pull" then
            if GetUnitToLocationDistance(this_bot, this_bot.pull) > 350 then
                print("pulling")
                roam_location = this_bot.pull;
            else
                this_bot:Action_ClearActions(true);
            end
        end
        if this_bot.pull_state == "success" then
            this_bot.pull = nil;
        end
    -- -- determined by ward
    -- elseif this_bot.ward then
    --     print(this_bot.ward);
    end
    if roam_location ~= nil then
        this_bot:MoveToLocationOnPath(roam_location);
        -- GeneratePath(this_bot_location, roam_location, GetAvoidanceZones(), MoveToWaypoint);
    end
    if this_bot.pull_camp ~= nil and this_bot.pull_state ~= "success" then       
        local neutrals = this_bot:GetNearbyNeutralCreeps(900);
        local pull_time = enums.pull_time[this_bot.pull_camp.team][this_bot.pull_camp.type];
        if neutrals ~= nil then
            for _, neutral in pairs(neutrals) do
                if neutral:IsAlive() and neutral:CanBeSeen() then
                    if neutral:WasRecentlyDamagedByCreep(2) then
                        this_bot.pull_state = "success";
                        print("pull good")
                        break;
                    elseif this_bot.pull_state ~= "aggro" and this_bot:IsAtLocation(this_bot.pull_camp.location, 1800) and
                        (neutral:WasRecentlyDamagedByHero(this_bot, 5) or this_bot:WasRecentlyDamagedByCreep(5)) then
                        print("aggro good")
                        this_bot.pull_state = "aggro";
                    end
                end
            end
        end
        if this_bot.pull_state == "aggro" and time % 30 >= pull_time - 1 and time % 30 <= pull_time + 1 then
            this_bot:Action_MoveToLocation(this_bot.pull_camp.location + enums.pull_vector[this_bot.pull_camp.team][this_bot.pull_camp.type]);
            print("pull to lane")
        elseif this_bot:IsAtLocation(this_bot.pull_camp.location, 600) and #neutrals > 0 and
                time % 30 >= pull_time - 1 and time % 30 <= pull_time + 1 then
            print("attack pull")
            this_bot:Action_AttackUnit(neutrals[1], true);
        end
    end
end

function OnEnd()
    GarbageCleaning();
end