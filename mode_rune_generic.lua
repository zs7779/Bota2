utils = require(GetScriptDirectory().."/utils");
mode_utils = require(GetScriptDirectory().."/mode_utils");
require(GetScriptDirectory().."/CDOTA_utils");

-- function GetDesire()
--     local time = DotaTime();
--     local this_bot = GetBot();
--     if not this_bot.is_initialized then
--         this_bot:InitializeBot();
--     end
--     -- Before game begin
--     if this_bot.position >= 4 and time < 0 then
--         return mode_utils.mode_desire.rune
--     end
--     -- Power rune
--     -- Bounty rune
-- 	return 0;
-- end