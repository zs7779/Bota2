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
        return 1;
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
    -- still need regen
    if this_bot.regen then
        if this_bot:DistanceFromFountain() < 100 and this_bot:GetHealth() / this_bot:GetMaxHealth() > 0.8 and this_bot:GetMana() / this_bot:GetMaxMana() > 0.8 then
            this_bot.regen = false;
        end
        return enums.mode_desire.retreat;
    end
    -- no mana or health to do anything
    if this_bot:TimeToRegenHealth(0.6) > timeout or this_bot:TimeToRegenMana(0.4) > timeout or
       this_bot:GetHealth() / this_bot:GetMaxHealth() < 0.2 or this_bot:GetMana() / this_bot:GetMaxMana() < 0.1 then
        this_bot.regen = true;
        return enums.mode_desire.retreat;
    end
    
	return 0;
end