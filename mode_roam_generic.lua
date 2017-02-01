_G._savedEnv = getfenv()
module( "mode_roam_generic", package.seeall )

-- Called every ~300ms, and needs to return a floating-point value between 0 and 1 that indicates how much this mode wants to be the active mode.
function GetDesire() 
end

-- Called when a mode takes control as the active mode.
function OnStart() 
end

-- Called when a mode relinquishes control to another active mode.
function OnEnd() 
end

-- Called every frame while this is the active mode. Responsible for issuing actions for the bot to take.
function Think()
end

for k,v in pairs(mode_roam_generic) do _G._savedEnv[k] = v end
