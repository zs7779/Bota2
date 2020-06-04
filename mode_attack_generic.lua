utils = require(GetScriptDirectory().."/utils");
enums = require(GetScriptDirectory().."/enums");
require(GetScriptDirectory().."/CDOTA_utils");

update_time = 30;

function GarbageCleaning()
    local this_bot = GetBot();
    this_bot:SetTarget(nil);
end

local this_bot = GetBot();

function GetDesire()
    local time = DotaTime();
    if not this_bot.is_initialized then
        this_bot:InitializeBot();
    end
    if not this_bot:IsAlive() then
        GarbageCleaning();
        return 0;
    end
    local team = GetTeam();
    if time > update_time then
        -- print(this_bot:GetUnitName().." Power "..this_bot:EstimatePower().." Disable "..this_bot:EstimateFriendsDisableTime(0));
        this_bot:GetAbilities(); -- maybe good idea
        -- if this_bot.position == 5 then
        --     for _, enemy in pairs(GetUnitList(UNIT_LIST_ENEMY_HEROES)) do
        --         print(enemy:GetUnitName(), enemy:EstimatePower(), enemy:EstimateFriendsDisableTime(1200))
        --     end
        -- end
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
    local target = this_bot:GetFriendsTarget(1200);
    if target == nil then
        -- weakest enemy vs closest enemy? if you have blink then weakest?
        -- target = this_bot:FindClosestEnemy(this_bot:GetKillRange(false));
        target = this_bot:FindWeakestEnemy(this_bot:GetKillRange(false));
    end

    if target ~= nil then
        local projectiles = target:GetIncomingTrackingProjectiles();
        for _, pjt in pairs(projectiles) do
            -- a spell is flying
            if pjt.caster ~= nil and pjt.caster:GetTeam() == team and pjt.is_attack == false then
                this_bot:SetTarget(target);
                return enums.mode_desire.attack;
            end
        end
        -- 1 attack away from kill
        if this_bot:GetEstimatedDamageToTarget(true, target, this_bot:GetAttackPoint() * 2 + 0.1, DAMAGE_TYPE_ALL) > enums.passiveness * target:GetHealth() or
           target:IsStunned() or target:IsRooted() or target:IsHexed() or target:GetRemainingDisableTime() > 0 then
            this_bot:SetTarget(target);
            return enums.mode_desire.attack;
        end
        -- plan kill, if not being hit by tower
        if not this_bot:IsBeingTargetedBy(this_bot:GetNearbyTowers(800, true)) and not this_bot:WasRecentlyDamagedByTower(2) then

            if target:EstimateEnemiesDamageToSelf(1600) > enums.passiveness * target:GetHealth() and target:EnemyCanInitiateOnSelf(1600) then
                this_bot:SetTarget(target);
                -- print("Target "..target:GetUnitName().." Damage "..this_bot:EstimateFriendsDamageToTarget(900, target).." Disable "..target:GetRemainingDisableTime());
                return enums.mode_desire.attack;
            end
        end
    end
    return 0;	
end

function OnEnd()
    GarbageCleaning(); 
end