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
    if this_bot.position == 0 and time < 600 then -- todo: pulling disabled for now
        if this_bot.pull == nil and this_bot.pull_state == nil then
            if not this_bot:WasRecentlyDamagedByAnyHero(1) and not this_bot:WasRecentlyDamagedByCreep(2) then
                local pull_camp = this_bot:FindNeutralCamp(true);
                if pull_camp ~= nil then
                    this_bot.pull = pull_camp;
                    this_bot.pull_state = {["state"] = "pull", ["time"] = time + 15};
                end
            else
                this_bot.pull = nil;
                this_bot.pull_state = nil;
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
        if this_bot.pull_state.state == "success" then
            this_bot.pull = nil;
            return;
        else
            local pull_time = enums.pull_time[this_bot.pull.team][this_bot.pull.type];
            local neutrals = this_bot:GetNearbyNeutralCreeps(1600);
            local friend_creeps = this_bot:GetNearbyLaneCreeps(900, false);
            if #neutrals > 0 then
                local neutral = neutrals[1];
                if neutral:IsAlive() and neutral:CanBeSeen() then
                    local projectiles = neutral:GetIncomingTrackingProjectiles();
                    for _, p in pairs(projectiles) do
                        if p.playerid == -1 then
                            this_bot.pull_state = {["state"] = "success", ["time"] = time + 15};
                            -- print("pull good")
                            return;
                        end
                        if this_bot.pull_state.state == "pull" and p.caster == this_bot then
                            -- print("aggro good")
                            this_bot.pull_state = {["state"] = "aggro", ["time"] = time + 10};
                        end
                    end
                    for _, c in pairs(friend_creeps) do
                        if GetUnitToUnitDistance(c, neutral) < 500 then
                            this_bot.pull_state = {["state"] = "success", ["time"] = time + 15};
                            -- print("pull good")
                            return;
                        end
                    end
                    if this_bot.pull_state.state == "pull" and this_bot:IsAtLocation(this_bot.pull.location, 1800) then
                        if this_bot:WasRecentlyDamagedByCreep(5) then -- todo: may add projectile playerid == -1
                            -- print("aggro good")
                            this_bot.pull_state = {["state"] = "aggro", ["time"] = time + 10};
                        end
                    end
                end
            
            end

            if this_bot.pull_state.state == "pull" then
                if GetUnitToLocationDistance(this_bot, this_bot.pull.location) > 350 then
                    roam_location = this_bot.pull.location;
                elseif this_bot:IsAtLocation(this_bot.pull.location, 600) and #neutrals > 0 and
                       time % 30 >= pull_time - 1 and time % 30 <= pull_time + 1 then
                    -- print("attack pull")
                    this_bot:Action_AttackUnit(neutrals[1], true);
                else
                    -- print("wait pull time")
                    this_bot:Action_ClearActions(true);
                end
            elseif this_bot.pull_state.state == "aggro" and time % 30 >= pull_time - 1 and time % 30 <= pull_time + 4 then
                this_bot:Action_MoveToLocation(this_bot.pull.location + enums.pull_vector[this_bot.pull.team][this_bot.pull.type]);
                -- print("pull to lane")
            end
        end
    -- -- determined by ward
    -- elseif this_bot.ward then
    --     print(this_bot.ward);
    end
    if roam_location ~= nil then
        this_bot:MoveToLocationOnPath(roam_location);
        -- GeneratePath(this_bot_location, roam_location, GetAvoidanceZones(), MoveToWaypoint);
    end
end

function OnEnd()
    GarbageCleaning();
end