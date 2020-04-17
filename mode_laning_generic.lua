utils = require(GetScriptDirectory().."/utils");
mode_utils = require(GetScriptDirectory().."/mode_utils");
require(GetScriptDirectory().."/CDOTA_utils");

-- Called every ~300ms, and needs to return a floating-point value between 0 and 1 that indicates how much this mode wants to be the active mode.
function GetDesire()
    local this_bot = GetBot();
    local time = DotaTime();
    local this_bot_level = this_bot:GetLevel();
    if not this_bot.is_initialized then
        this_bot:InitializeBot();
    end
    -- Time < 5 minutes or level < 7
    if time < 600 or this_bot_level < 10 then
        return mode_utils.mode_desire.laning
    end
    -- and if laning enemy is not too strong
    return 0;	
end

-- Called when a mode takes control as the active mode.
-- function OnStart()
-- end

-- Called when a mode relinquishes control to another active mode.
-- function OnEnd() 
--     local this_bot = GetBot();
--     local this_bot_level = this_bot:GetLevel();
--     local time = DotaTime();
--     this_bot:ActionImmediate_Chat("Level " .. this_bot_level .. " Time " .. utils.SecondsToClock(time), true);
-- end
