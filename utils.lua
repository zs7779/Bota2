local utils = {};

function utils.SecondsToClock(seconds)
    -- https://gist.github.com/jesseadams/791673
    local seconds = tonumber(math.abs(seconds));
    local min_str = string.format("%02.f", math.floor(seconds/60));
    local sec_str = string.format("%02.f", math.floor(seconds - min_str *60));
    return min_str..":"..sec_str
end

return utils;