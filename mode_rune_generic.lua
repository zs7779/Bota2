utils = require(GetScriptDirectory().."/utils");
mode_utils = require(GetScriptDirectory().."/mode_utils");
require(GetScriptDirectory().."/CDOTA_utils");


function GetDesire()
    local this_bot = GetBot();
    local time = DotaTime();
    if not this_bot.is_initialized then
        this_bot:InitializeBot();
    end
    if not this_bot:IsAlive() then
        return 0;
    end

    -- Standing on top of rune, pick it up, dunno if appropriate to put here
    this_bot:PickupRune();
    local runes = {power={RUNE_POWERUP_1, RUNE_POWERUP_2},
                bounty={RUNE_BOUNTY_1, RUNE_BOUNTY_2, RUNE_BOUNTY_3, RUNE_BOUNTY_4}};
    local next_power_rune_time = 240;
    local next_bounty_rune_time = 0;
    local want_rune = false;
    -- Before game begin
    -- if this_bot.position >= 3 and time < 0 then
    --     return mode_utils.mode_desire.rune;
    -- end
    -- Bounty rune
    if time + 20 > next_bounty_rune_time then
        want_rune = want_rune or this_bot:DecideRoamRune(runes.bounty, time>next_bounty_rune_time);
    end
    -- Power rune
    if time + 20 > next_power_rune_time then
        want_rune = want_rune or this_bot:DecideRoamRune(runes.power, time>next_power_rune_time);
    end
    -- All runes are unavailable
    if time - 280 > next_bounty_rune_time then
        next_bounty_rune_time = next_bounty_rune_time + 300;
    end
    if time - 100 > next_power_rune_time then
        next_power_rune_time = next_power_rune_time + 120;
    end

    if want_rune then
        return mode_utils.mode_desire.rune;
    end
	return 0;
end