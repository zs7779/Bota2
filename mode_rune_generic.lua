utils = require(GetScriptDirectory().."/utils");
enums = require(GetScriptDirectory().."/enums");
require(GetScriptDirectory().."/CDOTA_utils");

update_time = 0;
next_power_rune_time = 240;
next_bounty_rune_time = 0;

local function GarbageCleaning()
    local this_bot = GetBot();
    this_bot.rune = nil;
    this_bot.rune_time = nil;
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
        -- print(utils.SecondsToClock(next_bounty_rune_time), utils.SecondsToClock(next_power_rune_time))
        update_time = update_time + 60;
    end
    -- Standing on top of rune, pick it up, dunno if appropriate to put here
    if this_bot.rune ~= nil then
        if GetRuneStatus(this_bot.rune) == RUNE_STATUS_AVAILABLE and GetUnitToLocationDistance(this_bot, GetRuneSpawnLocation(this_bot.rune)) < 300 then
            return enums.mode_desire.rune;
        elseif (this_bot.rune_time == nil or time > this_bot.rune_time) then
            if GetRuneStatus(this_bot.rune) == RUNE_STATUS_MISSING then
                GarbageCleaning();
                return 0;
            elseif GetUnitToLocationDistance(this_bot, GetRuneSpawnLocation(this_bot.rune)) < 300 then
                return enums.mode_desire.rune;
            end
        end
    end

    local runes = {power={RUNE_POWERUP_1, RUNE_POWERUP_2},
                bounty={RUNE_BOUNTY_1, RUNE_BOUNTY_2, RUNE_BOUNTY_3, RUNE_BOUNTY_4},
                all={RUNE_POWERUP_1, RUNE_POWERUP_2,RUNE_BOUNTY_1, RUNE_BOUNTY_2, RUNE_BOUNTY_3, RUNE_BOUNTY_4}};
    -- todo: add if rune is about to expire and i am close
    this_bot:DecideRoamRune(runes.all, true, 600);
    -- Bounty rune
    if this_bot.rune == nil then
        if time + enums.free_time[this_bot.position] > next_bounty_rune_time then
            this_bot:DecideRoamRune(runes.bounty, time>next_bounty_rune_time, 3000);
            if this_bot.rune ~= nil then
                this_bot.rune_time = next_bounty_rune_time;
                this_bot:FriendWantRune();
            end
        end
        -- Power rune
        if time + enums.free_time[this_bot.position] > next_power_rune_time then
            this_bot:DecideRoamRune(runes.power, time>next_power_rune_time, 3000);
            if this_bot.rune ~= nil then
                this_bot.rune_time = next_power_rune_time;
                this_bot:FriendWantRune();
            end
        end
    end
    
    -- All runes are unavailable
    if time > next_bounty_rune_time and
        this_bot:AllRunesUnavailable(runes.bounty) then
        next_bounty_rune_time = next_bounty_rune_time + 300;
        -- print("bounty time is now "..next_bounty_rune_time);
    end
    if time > next_power_rune_time and
        this_bot:AllRunesUnavailable(runes.power) then
        next_power_rune_time = next_power_rune_time + 120;
        -- print("rune time is now "..next_power_rune_time);
    end

	return 0;
end

function OnEnd()
    GarbageCleaning();
end

function Think()
    local this_bot = GetBot();
    this_bot:PickUpRune();
end