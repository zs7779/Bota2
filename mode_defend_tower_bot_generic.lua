utils = require(GetScriptDirectory().."/utils");
enums = require(GetScriptDirectory().."/enums");
require(GetScriptDirectory().."/CDOTA_utils");
mode_defend_tower_generic = require(GetScriptDirectory().."/mode_defend_tower_generic");

local this_bot = GetBot();
-- todo: best way is probably some scheduler type logic in TeamThink()?
function GetDesire()
    if not this_bot.is_initialized then
        this_bot:InitializeBot();
    end
    if not this_bot:IsAlive() then
        return 0;
    end
    local lane = LANE_BOT;
    local other_lanes = {LANE_TOP, LANE_MID};
    return mode_defend_tower_generic.GetDesire(this_bot, lane, other_lanes);
end