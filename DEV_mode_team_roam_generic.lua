require(GetScriptDirectory() ..  "/utils")

-- when roam?
-- 1. supports 2. initiators with key level/item 3. core with key level/item
---- if only 1 roam, then use mode_roam_generic

-- where roam?
-- 1. close to objective 
-- 2. close to lone enemy
-- 3. where friend outnumber enemy (have tp == is there)
-- 4. where creeps are hitting enemy tower
-- 5. where enemy are taking objectivesi
-- 6. steal roshan

-- Do?
-- mode_assemble_generic
-- 1. core/initiator call for team roam
-- 2. calculate team power for required personels
-- 3. supports/available cores join
-- 4. pusher friend near location keep pushing

-- mode_team_roam_generic
-- 5. determine (a) assemble point (b) initiation point (c) attack point (d) optional wrap around point
-- 6. closer to (a) -> assemble
--    closer to (d) -> wrap around
--    initiator/blinker -> (b)
--    other -> (c)

-- determine who is ready to fight
function CDOTA_Bot_Script:IsCoolDownReady()
	-- if tolerance == nil or tolerance < 0 then tolerance = 0; end
	local spells = self:GetAbilities();
	for _, spell in ipairs(spells) do
		if not spell:IsPassive() and not spell:IsCooldownReady()then
			return false;
		end
	end
	return true;
end

function CDOTA_Bot_Script:RegenNeeded()
	return self:GetMaxHealth() * 0.9 - self:GetHealth(), self:GetComboMana() - self:GetMana();
end



function ConsiderTeamRoam()
	for position = 1,5 do
		local friend = GetTeamMember(position);
		if friend:IsCoolDownReady() then
			local healthRegen, manaRegen = friend:RegenNeeded();
			if friend.shrine and healthRegen <= 450 and manaRegen <= 200 then
				--
			end
		end
	end
end

