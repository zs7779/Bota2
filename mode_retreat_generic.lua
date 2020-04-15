utils = require(GetScriptDirectory().."/utils");
mode_utils = require(GetScriptDirectory().."/mode_utils");

-- function GetDesire()
--     local time = DotaTime();
--     local this_bot = GetBot();
--     if this_bot.position == nil then
--         utils.GetBotPosition(this_bot);
--     end
--     if this_bot.position ~= 2 and time < 0 then
--         return mode_utils.mode_desire.retreat;
--     end
-- 	return 0;
-- end