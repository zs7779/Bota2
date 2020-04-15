utils = require(GetScriptDirectory().."/utils");
mode_utils = require(GetScriptDirectory().."/mode_utils");
require(GetScriptDirectory().."/CDOTA_utils");

function GetDesire()
    local this_bot = GetBot();
    local time = DotaTime();
    local this_bot_level = this_bot:GetLevel();
    if not this_bot.is_initialized then
        this_bot:InitializeBot();
    end
    
    -- float GetOffensivePower() 
    -- float GetEstimatedDamageToTarget( bCurrentlyAvailable, hTarget, fDuration, nDamageTypes ) 
    -- float GetStunDuration( bCurrentlyAvailable ) 
    -- float GetSlowDuration( bCurrentlyAvailable ) 
    -- { hUnit, ... } GetNearbyHeroes( nRadius, bEnemies, nMode) 

    -- Assault
    -- Kill
    return 0;	
end