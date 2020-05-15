abilities_dictionary = require(GetScriptDirectory().."/abilities_dictionary");
-- Extend helper functions to CDOTA_Bot_Script class, which is the class of the Bot objects
local debug = false;

local stun_factor, slow_factor = 1.0, 0.5;
local physical_factor, magic_factor, free_attacks = 0.65, 0.75, 3;

function CDOTA_Bot_Script:InitializeBot()
    if debug then
        print(self:GetUnitName());
    end

    self.is_initialized = false;
    self:GetPlayerPosition();
    self:GetAbilities();
    self.is_initialized = true;

    if debug then
        print("Initialized");
    end
end

-- Get Bot position in game as a number between 1-5, 1 being carry, 5 being hard support
function CDOTA_Bot_Script:GetPlayerPosition()
    if self.position == nil then
        for position = 1, 5 do
            if self == GetTeamMember(position) then
                self.position = position;
                break;
            end
        end    
    end

    if debug then
        print("Position", self.position);
    end
	return self.position;
end

function CDOTA_Bot_Script:GetAbilities()
    -- save a list of abilities to self
    local abilities = {};
    for i = 0, 23 do
        local ability = self:GetAbilityInSlot(i);
        if ability ~= nil and not ability:IsTalent() and not ability:IsItem() and not ability:IsHidden() and not ability:IsPassive() then
            abilities[#abilities+1] = abilities_dictionary[ability:GetName()](ability);
        end
    end
    self.abilities = abilities;
    -- for _, ab in pairs(self.abilities) do
    --     print(self:GetUnitName(), ab.handle:GetName());
    -- end
	return self.abilities;
end

function CDOTA_Bot_Script:GetKillRange()
    if self.abilities == nil then
        return 0;
    end
    local ability_range = 0;
    for _, ability in pairs(self.abilities) do
        if ability.handle:IsTrained() then
            ability_range = math.max(ability_range, ability.handle:GetCastRange());
        end
    end
    return math.min(ability_range, 1600);
end

function CDOTA_Bot_Script:GetComboMana()
    local mana_cost = 0;
    if self.abilities ~= nil then
        for _, ability in pairs(self.abilities) do
            mana_cost = mana_cost + ability.handle:GetManaCost();
        end
    end
    return mana_cost;
end

function CDOTA_Bot_Script:HealthyMana()
    return math.max(math.min(self:GetComboMana(), self:GetMaxMana()), self:GetMaxMana() * 0.5);
end

function CDOTA_Bot_Script:FreeMana()
    return math.max(self:GetMana() - self:HealthyMana(), 0);
end

function CDOTA_Bot_Script:FreeAbility(ability)
    return ability ~= nil and ability:IsFullyCastable() and ability:GetCooldown() < 20 and ability:GetManaCost() < self:FreeMana();
end

function CDOTA_Bot_Script:TimeToRegen()
    local healthy = 0.7;
    local healthy_hp = healthy * self:GetMaxHealth();
    local healthy_mp = self:HealthyMana();
    return math.max((healthy_hp - self:GetHealth()) / self:GetHealthRegen(), (healthy_mp - self:GetMana()) / self:GetManaRegen());
end

function CDOTA_Bot_Script:MoveOppositeStep(location)
    local self_location = self:GetLocation();
    local vector = {self_location[1] - location[1], self_location[2], location[2]};
    local vector_len = math.sqrt(vector[1] * vector[2]);
    vector[1] = vector[1] / vector_len * 300;
    vector[2] = vector[2] / vector_len * 300;
    self_location[1] = self_location[1] + vector[1];
    self_location[2] = self_location[2] + vector[2];
    self:ActionQueue_MoveToLocation(self_location);
end

function CDOTA_Bot_Script:EstimateFriendsDisableTime(distance)
    -- estimate total disable time among friends within distance, I'm guessing 0 means just myself
    local distance = distance or 0;
    local nearby_friends = self:GetNearbyHeroes(distance, false, BOT_MODE_NONE);
    local stun_time, slow_time = 0, 0;
    for i = 1, #nearby_friends do
        if nearby_friends[i]:IsAlive() then
            stun_time = stun_time + nearby_friends[i]:GetStunDuration(true);
            slow_time = slow_time + nearby_friends[i]:GetSlowDuration(true);
        end
    end
    return stun_factor * (stun_time + slow_factor * slow_time);
end

function CDOTA_Bot_Script:EstimatePower(disable_time)
    -- mean to be a rough estimate, better than GetOffensivePower, probably worse than GetEstimatedDamageToTarget
    -- still considering if the factors should be args. it would complicate the
    -- power immediately drops after cast stun, problem!
    local physical_damage = 0;
    local magic_damage = 0;
    local pure_damage = 0;
    local mana_cost = 1;
    if self.abilities ~= nil then
        for _, ability in pairs(self.abilities) do
            if ability.handle:IsFullyCastable() then
                mana_cost = mana_cost + ability.handle:GetManaCost();

                local ability_damage_type = ability.handle:GetDamageType();
                local ability_damage = ability.damage;
                
                if ability_damage_type == DAMAGE_TYPE_PHYSICAL then
                    physical_damage = physical_damage + ability_damage;
                elseif ability_damage_type == DAMAGE_TYPE_MAGICAL then
                    magic_damage = magic_damage + ability_damage;
                else
                    pure_damage = pure_damage + ability_damage;
                end
            end
        end
    end
    local total_power = (physical_factor * physical_damage + magic_factor * magic_damage + pure_damage) * (math.min(self:GetMana(), mana_cost) / mana_cost);
    local disable_time = disable_time or self:EstimateFriendsDisableTime();
    local num_attacks = math.max((disable_time + free_attacks) / (self:GetSecondsPerAttack()+0.01), free_attacks);
    total_power = total_power + self:GetAttackDamage() * num_attacks;
    return total_power;    
end

function CDOTA_Bot_Script:EstimateFriendsPower(distance)
    local distance = distance or 0;
    local nearby_friends = self:GetNearbyHeroes(distance, false, BOT_MODE_NONE);
    local disable_time = self:EstimateFriendsDisableTime(distance);
    local power = 0;
    for i = 1, #nearby_friends do
        if nearby_friends[i]:IsAlive() and not nearby_friends[i]:IsIllusion() then
            -- power = power + nearby_friends[i]:EstimatePower(disable_time);
            power = power + nearby_friends[i]:GetOffensivePower();
        end
    end
    return power;
end

function CDOTA_Bot_Script:GetStunTime()
    if self.stun_timer == nil or self.stun_timer < DotaTime() or not self:IsStunned() and not self:IsRooted() and not self:IsHexed() then
        self.stun_timer = nil;
        return 0;
    end
    return math.max(self.stun_timer - DotaTime(), 0);
end

function CDOTA_Bot_Script:GetSlowTime()
    if self.slow_timer == nil or self.slow_timer < DotaTime() then
        self.slow_timer = nil;
        return 0;
    end
    return math.max(self.slow_timer - DotaTime(), 0);
end

function CDOTA_Bot_Script:GetRemainingDisableTime()
    return self:GetStunTime() + self:GetSlowTime() * slow_factor;
end

function CDOTA_Bot_Script:EstimateFriendsDamageToTarget(distance, target)
    local distance = distance or 0;
    local nearby_friends = self:GetNearbyHeroes(distance, false, BOT_MODE_NONE);
    local disable_time = self:EstimateFriendsDisableTime(distance) + target:GetRemainingDisableTime();
    local attack_range = self:GetAttackRange();
    local target_distance = GetUnitToUnitDistance(self, target);
    
    local damage = 0;
    for i = 1, #nearby_friends do
        if nearby_friends[i]:IsAlive() and not nearby_friends[i]:IsIllusion() then
            -- power = power + nearby_friends[i]:EstimatePower(disable_time);
            if nearby_friends[i]:GetAttackRange() > GetUnitToUnitDistance(nearby_friends[i], target) then
                damage = damage + nearby_friends[i]:GetEstimatedDamageToTarget(true, target, disable_time+1, DAMAGE_TYPE_ALL);
            else
                damage = damage + nearby_friends[i]:GetEstimatedDamageToTarget(true, target, disable_time, DAMAGE_TYPE_ALL);
            end
        end
    end
    return damage;
end

function CDOTA_Bot_Script:EstimateEnimiesPower(distance)
    -- Need to add something so it doesnt count illusion twice
    local distance = distance or 0;
    local nearby_enemies = self:GetNearbyHeroes(distance, true, BOT_MODE_NONE);
    local nearby_creeps = self:GetNearbyLaneCreeps(300, true);
    local nearby_towers = self:GetNearbyTowers(700, true);
    -- local disable_time = self:EstimateFriendsDisableTime(distance);
    local power = 0;
    local enemy_account = {};
    if nearby_enemies == nil and nearby_creeps == nil and nearby_towers == nil then
        return power;
    end
    for i = 1, #nearby_enemies do
        local enemy_id = nearby_enemies[i]:GetPlayerID();
        if nearby_enemies[i]:IsAlive() and enemy_account[enemy_id] == nil then
            -- power = power + nearby_friends[i]:EstimatePower(disable_time);
            power = power + nearby_enemies[i]:GetRawOffensivePower();
            -- power = power + nearby_enemies[i]:GetEstimatedDamageToTarget(true, self, duration???);
            -- apparently this is very wrong for some heroes: phoneix/monkeyking maybe elder titan
            enemy_account[enemy_id] = true;
        end
    end
    for i = 1, #nearby_creeps do
       if nearby_creeps[i]:IsAlive() then
            power = power + nearby_creeps[i]:GetRawOffensivePower();
        end
    end
    for i = 1, #nearby_towers do
        if nearby_towers[i]:IsAlive() then
             power = power + nearby_towers[i]:GetRawOffensivePower();
         end
     end
    return power;
end

function CDOTA_Bot_Script:FindWeakestEnemy(distance)
    local distance = distance or 150;
    local nearby_enemies = self:GetNearbyHeroes(distance, true, BOT_MODE_NONE);
    local smallest_health = 1000000;
    local weakest_enemy = nil;
    for i = 1, #nearby_enemies do
        if nearby_enemies[i]:IsAlive() and nearby_enemies[i]:CanBeSeen() then
            local enemy_health = nearby_enemies[i]:GetHealth();
            if enemy_health < smallest_health then
                smallest_health = enemy_health;
                weakest_enemy = nearby_enemies[i];
            end
        end
    end
    return weakest_enemy;
end

-- richest enemy
-- strongest enemy
-- 1. 先手到大哥可以打
-- 2. 随便打 power之类的

function CDOTA_Bot_Script:GetFriendsTarget(distance)
    local distance = distance or 0;
    local nearby_friends = self:GetNearbyHeroes(distance, false, BOT_MODE_NONE);
    for i = 1, #nearby_friends do
        if nearby_friends[i]:IsAlive() and nearby_friends[i]:GetActiveMode() == BOT_MODE_ATTACK then
            local friend_target = nearby_friends[i]:GetTarget();
            if friend_target ~= nil and friend_target:IsAlive() and friend_target:CanBeSeen() then
                return friend_target;
            end
        end
    end
    return nil;
end

function CDOTA_Bot_Script:DecideRoamRune(runes, rune_spawned, min_distance)
    local min_distance = min_distance or 3000;
    local nearest_rune = nil;
    for _, rune in pairs(runes) do
        if not rune_spawned or GetRuneStatus(rune) ~= RUNE_STATUS_MISSING then
            local rune_location = GetRuneSpawnLocation(rune);
            local rune_distance = GetUnitToLocationDistance(self, rune_location);
            if rune_distance < min_distance then
                min_distance = rune_distance;
                nearest_rune = rune;
            end
        end
    end
    self.rune = nearest_rune;
end

function CDOTA_Bot_Script:PickUpRune()
    if self.rune ~= nil then
        self:Action_PickUpRune(self.rune);
    end
end

function CDOTA_Bot_Script:FriendWantRune()
    local friends = GetUnitList(UNIT_LIST_ALLIED_HEROES);
    for i = 1, #friends do
        local friend = friends[i];
        if friend ~= self and friend:IsAlive() and friend.rune == self.rune then
            if self.rune <= RUNE_POWERUP_2 and self.position > friend.position or
                self.rune > RUNE_POWERUP_2 and self.position < friend.position then
                self.rune = nil;
                self.rune_time = nil;
                return;
            end
        end
    end
end

function CDOTA_Bot_Script:AllRunesUnavailable(runes)
    local friends = GetUnitList(UNIT_LIST_ALLIED_HEROES);
    for i = 1, #friends do
        local friend = friends[i];
        if friend.rune ~= nil then
            return false;
        end
    end
    return true;
end

function CDOTA_Bot_Script:NeedHelp()
    return self:IsAlive() and self.help;
end

function CDOTA_Bot_Script:FindFriendNeedHelp()
    local friends = GetUnitList(UNIT_LIST_ALLIED_HEROES);
    local nearest_friend, min_distance = nil, 1000000;
    for i = 1, #friends do
        if friends[i] ~= self and friends[i]:NeedHelp() then
            local distance = GetUnitToUnitDistance(self, friends[i]);
            if distance < min_distance then
                nearest_friend = friend;
                min_distance = distance;
            end
        end
    end
    return nearest_friend, min_distance;
end

function CDOTA_Bot_Script:FriendNeedHelpNearby(distance)
    local distance = distance or 1200;
    local friend, friend_distance = self:FindFriendNeedHelp();
    if friend_distance <= distance then
        return friend;
    end
    return nil;
end

-- function CDOTA_Bot_Script:MoveToWaypoint(distance, waypoints)
--     if distance == 0 or waypoints == nil or #waypoints == 0 then
--         return 0;
--     end
--     self:Action_MoveToLocation(waypoints[1]);
-- end
