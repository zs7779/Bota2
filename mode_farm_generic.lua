utils = require(GetScriptDirectory().."/utils");
mode_utils = require(GetScriptDirectory().."/mode_utils");
require(GetScriptDirectory().."/CDOTA_utils");

-- I'm having a sense the original farm mode was exclusively for jungle
-- Called every ~300ms, and needs to return a floating-point value between 0 and 1 that indicates how much this mode wants to be the active mode.
function GetDesire()
    local this_bot = GetBot();
    local time = DotaTime();
    local this_bot_level = this_bot:GetLevel();
    if not this_bot.is_initialized then
        this_bot:InitializeBot();
    end
    -- Time > 10 minutes or level >= 7
    if this_bot_level >= 6 or time > 600 then
        return mode_utils.mode_desire.farm
    end
    -- If very close to a big item
    return 0;	
end
