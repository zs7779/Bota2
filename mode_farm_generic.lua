utils = require(GetScriptDirectory().."/utils");
enums = require(GetScriptDirectory().."/enums");
require(GetScriptDirectory().."/CDOTA_utils");

local this_bot = GetBot();
local position = this_bot:GetPlayerPosition();
local team = GetTeam();
local enemy_team = GetOpposingTeam();
-- I'm having a sense the original farm mode was exclusively for jungle
-- maybe it should be just default mode, since farming is most passive?
-- Called every ~300ms, and needs to return a floating-point value between 0 and 1 that indicates how much this mode wants to be the active mode.
function GetDesire()
    local time = DotaTime();
    if not this_bot.is_initialized then
        this_bot:InitializeBot();
    end
    if this_bot:GetActiveMode() == BOT_MODE_FARM then
        this_bot:FindFarm();
    end
    return enums.mode_desire.farm;
end

local safety = {0.8, 0.8, 0.6, 0.4, 0.4};

function Think()
    -- { { string, vector }, ... } GetNeutralSpawners() 
    
end