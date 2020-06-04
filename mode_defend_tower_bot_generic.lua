utils = require(GetScriptDirectory().."/utils");
enums = require(GetScriptDirectory().."/enums");
require(GetScriptDirectory().."/CDOTA_utils");

local this_bot = GetBot();
-- todo: best way is probably some scheduler type logic in TeamThink()?
function GetDesire()
    if not this_bot.is_initialized then
        this_bot:InitializeBot();
    end
    if not this_bot:IsAlive() then
        return 0;
    end
    local team = GetTeam();
    local lane = LANE_BOT;
    local other_lanes = {LANE_TOP, LANE_MID};
    local this_mode = BOT_MODE_DEFEND_TOWER_BOT;
    -- highest desire and highest tier
    local defend_desire = GetDefendLaneDesire(lane);
    local defend_strength = 0.4;
    if defend_desire < 0.4 then
        return 0;
    end
    local tower, tier = utils.GetLaneTower(team, lane);
    -- defend desire should be highest on only 1 lane
    for _, other_lane in pairs(other_lanes) do
        if GetDefendLaneDesire(other_lane) > defend_desire then
            return 0;
        end
    end
    local closest = this_bot;
    local my_distance = GetUnitToUnitDistance(this_bot, tower);
    for _, friend in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES)) do
        if not friend:IsIllusion() and friend:IsAlive() then
            local wave_clear = friend:HaveWaveClear() and 0.2 or 0.15;
            if friend:GetActiveMode() == this_mode then
                defend_strength = defend_strength + wave_clear;
            elseif friend.position > 2 and GetUnitToUnitDistance(friend, tower) < my_distance then
                closest = friend;
            end
        end
    end
    DebugDrawText(600, 150+lane*100, tostring(defend_strength),255,255,0)
    if this_bot:GetActiveMode() == this_mode then
        return enums.mode_desire.defend;
    end
    if this_bot.position > 2 then
        if defend_strength < defend_desire and closest == this_bot then
            return enums.mode_desire.defend;
        end
    else
        if this_bot.team_mates[3]:GetActiveMode() == this_mode and
           this_bot.team_mates[4]:GetActiveMode() == this_mode and
           this_bot.team_mates[5]:GetActiveMode() == this_mode and
           defend_strength < defend_desire and this_bot:HaveWaveClear() then
            return enums.mode_desire.defend;
        end
    end
    return 0;
end