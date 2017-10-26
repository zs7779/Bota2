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
				 SHRINE_JUNGLE_1,
				 SHRINE_JUNGLE_2};


function GetDesire()
	local I = GetBot();
	local team = GetTeam();
	if not I:IsTrueHero() then return 0; end
	local position = I:GetPlayerPosition();
	local enemys = I:GetNearbyHeroes(1200,true,BOT_MODE_NONE);
	-- need mana/greaves/shrine
	-- for shrine you probably want more people/have a core/worth tp from far
	-- for manaboot and mek probably just local folks

	if I.shrine and GetShrineCooldown(I.shrine) > 10 and not IsShrineHealing(I.shrine) then
		I.shrine = nil;
		I.shrineTime = nil;
	end
	if I.shrine then
		if not I:IsLowHealth() and not I:IsLowMana() then
			return 0.7;
		else
			return 0.8;
		end
	end
	if (I:IsLowHealth() or I:IsLowMana()) and position <= 3 and not I.shrine then -- I need shrine and I'm core or I'm underattack
		local dist = I:DistanceFromFountain();
		for _, i in ipairs(shrines) do
			local shrine = GetShrine(team, i);
			if shrine ~= nil and GetShrineCooldown(shrine) < 10 then
				local thisDist = GetUnitToUnitDistance(I, shrine);
				local thisTime = thisDist/I:GetCurrentMovementSpeed() + 5;
				print(i,thisDist)
				if thisTime >= GetShrineCooldown(shrine) and thisDist < dist then
					print("| shorter")
					dist = thisDist;
					I.shrine = shrine;
					I.shrineTime = thisTime;
				end
			end
			shrine = nil;
		end
		if I.shrine and not (#enemys > 0 and I:WasRecentlyDamagedByAnyHero(3.0)) then -- I have my shrine, who wants to come?
			for P = 1,5 do
				local friend = GetTeamMember(P);
				if P ~= position and friend ~= nil and friend:IsTrueHero() and
				   (friend:WantHeal() or friend:WantMana()) and
				   (GetUnitToUnitDistance(friend, I.shrine)/friend:GetCurrentMovementSpeed() <= math.min(I.shrineTime+5,20) or friend:HaveTp()) then
					friend.shrine = I.shrine;
				end
			end
		end
	end
	-- if enough people want mana or a core wants mana, then shrine
	-- else find mana boot or suck it
	-- you dont want mek for heal. use greaves or urn or shrine
	return 0;


end

function Think()
	local I = GetBot();
	if not I:IsTrueHero() or not I:CanAct() then
		return;
	end
	if I.shrine then
		local enemys = I:GetNearbyHeroes(1200,true,BOT_MODE_NONE);
		if  GetUnitToUnitDistance(I, I.shrine) > 300 then
			I:Action_MoveToUnit(I.shrine);
		end
		local wait = 0;
		for P = 1,5 do
			local friend = GetTeamMember(P);
			if friend ~= nil and friend:IsTrueHero() and
			   friend.shrine == I.shrine and
			   friend:GetActiveMode() == BOT_MODE_ASSEMBLE and
			   GetUnitToUnitDistance(friend, I.shrine) > 300 then
				wait = wait + 1;
			end
		end
		if wait == 0 or #enemys > 0 and I:WasRecentlyDamagedByAnyHero(3.0) then
			I:Action_UseShrine(I.shrine);
		end

	end
end
