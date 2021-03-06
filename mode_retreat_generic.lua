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
    local active_mode = this_bot:GetActiveMode();
    if time > update_time then
        -- print(this_bot:GetUnitName().." Danger "..this_bot:EstimateEnimiesPower(1200));
        update_time = update_time + 30;
    end
    local health = this_bot:GetHealth();
    -- enemy can kill me and no friend has stun or save
    if this_bot:EstimateEnemiesDamageToSelf(1600) > enums.stupidity * health and this_bot:EnemyCanInitiateOnSelf(1600) and not this_bot:FriendCanSaveMe(600) then
        return enums.mode_desire.retreat;
    end
    if active_mode == BOT_MODE_FARM and this_bot:EstimateEnemiesDamageToSelf(1600) > enums.stupidity * health then
        return enums.mode_desire.retreat;
    end
    -- still need regen
    if this_bot.regen then
        if health / this_bot:GetMaxHealth() > 0.8 and this_bot:GetMana() / this_bot:GetMaxMana() > 0.8 then
            this_bot.regen = false;
        end
        return enums.mode_desire.retreat;
    end
    -- modes
    if (active_mode == BOT_MODE_RETREAT or active_mode == BOT_MODE_ROAM or active_mode == BOT_MODE_SECRET_SHOP or active_mode == BOT_MODE_FARM) and
       (this_bot:WasRecentlyDamagedByAnyHero(5) or this_bot:WasRecentlyDamagedByTower(1) or
       this_bot:IsBeingTargetedBy(this_bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)) or this_bot:IsBeingTargetedBy(this_bot:GetNearbyTowers(800, true)) or
       this_bot:EstimateEnemiesDamageToSelf(1600) > enums.stupidity * health) then
        return enums.mode_desire.retreat;
    end
    -- no mana or health to do anything
    if (this_bot:TimeToRegenHealth(0.6) > timeout or this_bot:GetHealth() / this_bot:GetMaxHealth() < 0.1) or
       ((this_bot:GetMana() / this_bot:GetMaxMana() < 0.1 or this_bot:TimeToRegenMana(0.4) > timeout) and
       active_mode ~= BOT_MODE_ATTACK and active_mode ~= BOT_MODE_LANING and active_mode ~= BOT_MODE_FARM and
       active_mode ~= BOT_MODE_SECRET_SHOP and active_mode ~= BOT_MODE_WARD)then
        this_bot.regen = true;
        return enums.mode_desire.retreat;
    end
    
	return 0;
end