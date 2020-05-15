utils = require(GetScriptDirectory().."/utils");
enums = require(GetScriptDirectory().."/enums");
require(GetScriptDirectory().."/CDOTA_utils");

update_time = 30;

local function GarbageCleaning()
    local this_bot = GetBot();
    this_bot:SetTarget(nil);
end

function GetDesire()
    local this_bot = GetBot();
    local time = DotaTime();
    if not this_bot.is_initialized then
        this_bot:InitializeBot();
    end
    if not this_bot:IsAlive() then
        GarbageCleaning();
        return 0;
    end

    if time > update_time then
        -- print(this_bot:GetUnitName().." Power "..this_bot:EstimatePower().." Disable "..this_bot:EstimateFriendsDisableTime(0));
        this_bot:GetAbilities(); -- maybe good idea
        update_time = update_time + 20;
    end

    -- 先有切后排logic
    -- local target = this_bot:FindWeakestEnemy(1200);
    -- if current_target ~= nil and current_target:IsAlive() and current_target:CanBeSeen() then
    --     return enums.mode_desire.attack;
        -- GetPlayerID() 
        -- { {location, time_since_seen}, ...} GetHeroLastSeenInfo( nPlayerID ) 
        -- int GetUnitPotentialValue( hUnit, vLocation, fRadius ) 
    -- end
    -- Assault
    -- Kill
    local target = this_bot:GetFriendsTarget(600);
    if target == nil then
        target = this_bot:FindWeakestEnemy(this_bot:GetKillRange());
    end

    if target ~= nil and this_bot:EstimateFriendsDamageToTarget(600, target) > enums.passiveness * target:GetHealth() then
        this_bot:SetTarget(target);
        -- print("Target "..target:GetUnitName().." Damage "..this_bot:EstimateFriendsDamageToTarget(900, target).." Disable "..target:GetRemainingDisableTime());
        return enums.mode_desire.attack;
    end
    return 0;	
end

function OnEnd()
    GarbageCleaning(); 
end