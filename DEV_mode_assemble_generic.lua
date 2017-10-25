-- Reason of assemble
-- mek/mana
-- shrine
-- BOT_MODE_TEAM_ROAM
-- BOT_MODE_WARD
-- BOT_MODE_ATTACK
-- BOT_MODE_PUSH_TOWER_TOP
-- BOT_MODE_PUSH_TOWER_MID
-- BOT_MODE_PUSH_TOWER_BOT
-- BOT_MODE_DEFEND_TOWER_TOP
-- BOT_MODE_DEFEND_TOWER_MID
-- BOT_MODE_DEFEND_TOWER_BOT
-- BOT_MODE_ROSHAN

-- I.want_mana/mek/shrine lowhealth/lowmana, lostHealth > 250 ...
-- if I have manaboot/mek, calculate assemble location (not too far), 
-- or calculate shrine location (can be far if have tp), give location to friends
-- assemble at location
-- assess feasibility of gank/push/rosh
-- assemble if not assembled


require(GetScriptDirectory() ..  "/utils")
local role = require(GetScriptDirectory() ..  "/RoleUtility")

local shrines = {SHRINE_BASE_1,
				 SHRINE_BASE_2,
				 SHRINE_BASE_3,
				 SHRINE_BASE_4,
				 SHRINE_BASE_5,
				 SHRINE_JUNGLE_1,
				 SHRINE_JUNGLE_2};

function CDOTA_Bot_Script:GetFactor()
	return self:GetHealth()/self:GetMaxHealth()+self:GetMana()/self:GetMaxMana()
end

function GetDesire()
	local I = GetBot();
	local team = GetTeam();
	if not I:IsTrueHero() then return 0; end
	local position = I:GetPlayerPosition();
	local enemys = I:GetNearbyHeroes(1200,true,BOT_MODE_NONE);
	-- need mana/greaves/shrine
	-- for shrine you probably want more people/have a core/worth tp from far
	-- for manaboot and mek probably just local folks

	if GetShrineCooldown(I.shrine) > 30 then
		I.shrine = nil;
	end
	if I.shrine then
		return 0.7;
	end
	if (I:IsLowHealth() or I:IsLowMana()) and
	   (position <= 3 or #enemys > 0 and I:WasRecentlyDamagedByAnyHero(3.0)) then -- I need shrine and I'm core or I'm underattack
		local dist = I:DistanceFromFountain();
		for _, i in ipairs(shrines) do
			local shrine = GetShrine(team, i);
			local thisDist = GetUnitToUnitDistance(I, shrine);
			local thisTime = thisDist/I:GetCurrentMovementSpeed() + 5;
			if thisTime >= GetShrineCooldown(shrine) and thisDist < dist then
				dist = thisDist;
				I.shrine = shrine;
				I.shrineTime = thisTime;
			end
		end
		if I.shrine and not (#enemys > 0 and I:WasRecentlyDamagedByAnyHero(3.0)) then -- I have my shrine, who wants to come?
			for P = 1,5 do
				local friend = GetTeamMember(P);
				if P ~= position and friend:IsTrueHero() and
				   (friend:WantHeal() or friend:WantMana()) and
				   (GetUnitToUnitDistance(friend, shrine)/friend:GetCurrentMovementSpeed() <= I.shrineTime + 5 or friend:HaveTp()) then
					friend.shrine = I.shrine;
					friend.shrineTime = I.shrineTime;
				end
			end
		end
		return 0.8;
	end
	-- if enough people want mana or a core wants mana, then shrine
	-- else find mana boot or suck it
	-- you dont want mek for heal. use greaves or urn or shrine
	


end

function Think()
	
end
