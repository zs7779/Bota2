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
    -- enemy can kill me and no friend has stun or save
    if this_bot:EstimateEnemiesDamageToSelf(1600) > enums.stupidity * health and this_bot:EnemyCanInitiateOnSelf(1600) and not this_bot:FriendCanSaveMe(600) then
        return enums.mode_desire.retreat;
    end
    -- no friend can take lane
    if this_bot:GetActiveMode() == BOT_MODE_LANING and #(this_bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)) == 0 then
        return 0;
    end
    -- no mana or health to do anything
    if this_bot:TimeToRegen(0.6) > timeout then
        return enums.mode_desire.retreat;
    end
    
	return 0;
end