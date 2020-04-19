utils = require(GetScriptDirectory().."/utils");
mode_utils = require(GetScriptDirectory().."/mode_utils");
require(GetScriptDirectory().."/CDOTA_utils");

update_time = 0;
stupidity = 1.0;
healthy = 0.6;
timeout = 90;
function GetDesire()
    local this_bot = GetBot();
    local time = DotaTime();
    if not this_bot.is_initialized then
        this_bot:InitializeBot();
    end
    if not this_bot:IsAlive() then
        return 0;
    end
    
    if time > update_time then
        -- print(this_bot:GetUnitName().." Danger "..this_bot:EstimateEnimiesPower(1200));
        update_time = update_time + 30;
    end
    local health = this_bot:GetHealth();
    if this_bot:EstimateEnimiesPower(1200) > stupidity * health then
        return mode_utils.mode_desire.retreat;
    end
    -- not enough mana to do combo
    -- want some number that is consistent, say we want to regen from 0 to 90 in 30 seconds, then 45 to 90 should be 15 seconds
    if this_bot:GetActiveMode() ~= BOT_MODE_ATTACK and this_bot:TimeToRegen() > timeout then
        return mode_utils.mode_desire.retreat;
    end
	return 0;
end