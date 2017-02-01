

----------------------------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_item_usage_generic", package.seeall )

----------------------------------------------------------------------------------------------------

-- function AbilityUsageThink()
-- end

----------------------------------------------------------------------------------------------------

function ItemUsageThink()
	if GetNumCouriers() == 0 then
		local npcBot = GetBot();
	    for i = 0, 5, 1 do
	        local item = npcBot:GetItemInSlot(i);
			if (item~=nil) then
				if(item and item:GetName() == "item_courier") then
					npcBot:Action_UseAbility(item);
				end
			end
	    end
	end

end

----------------------------------------------------------------------------------------------------


for k,v in pairs( ability_item_usage_generic ) do	_G._savedEnv[k] = v end
