utils = require(GetScriptDirectory().."/utils");
mode_utils = require(GetScriptDirectory().."/mode_utils");
require(GetScriptDirectory().."/CDOTA_utils");

-- I'm having a sense the original farm mode was exclusively for jungle
-- maybe it should be just default mode, since farming is most passive?
-- Called every ~300ms, and needs to return a floating-point value between 0 and 1 that indicates how much this mode wants to be the active mode.
function GetDesire()
    local this_bot = GetBot();
    local time = DotaTime();
    if not this_bot.is_initialized then
        this_bot:InitializeBot();
    end
    -- if not this_bot:IsAlive() then
    --     return 0;
    -- end

    -- local this_bot_level = this_bot:GetLevel();
    -- Time > 10 minutes or level >= 7
    -- If very close to a big item
    -- if time > 60 then
        return mode_utils.mode_desire.farm;
    -- end
    -- { { string, vector }, ... } GetNeutralSpawners() 
    return 0;
end
