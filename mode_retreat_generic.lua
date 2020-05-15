utils = require(GetScriptDirectory().."/utils");
enums = require(GetScriptDirectory().."/enums");
require(GetScriptDirectory().."/CDOTA_utils");

update_time = 0;
timeout = 90;

local this_bot = GetBot();

function GetDesire()
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
    if this_bot:EstimateEnimiesPower(1600) > enums.stupidity * health then
        return enums.mode_desire.retreat;
    end
    -- not enough mana to do combo
    -- want some number that is consistent, say we want to regen from 0 to 90 in 30 seconds, then 45 to 90 should be 15 seconds
    if this_bot:GetActiveMode() ~= BOT_MODE_ATTACK and this_bot:TimeToRegen() > timeout then
        return enums.mode_desire.retreat;
    end
	return 0;
end