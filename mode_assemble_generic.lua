-- Reason of assemble
-- mek/mana
-- shrine
-- BOT_MODE_TEAM_ROAM
-- BOT_MODE_WARD
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


function GetDesire() --*** add something so you don't all run to shrine mid fight
	local I = GetBot();
	if not I:IsTrueHero() then return 0; end
	
	local position = I:GetPlayerPosition();
	-- need mana/greaves/shrine
	-- for shrine you probably want more people/have a core/worth tp from far
	-- for manaboot and mek probably just local folks
	-- if enough people want mana or a core wants mana, then shrine
	-- else find mana boot or suck it
	-- you dont want mek for heal. use greaves or urn or shrine
	local ManaBootsDesire = ConsiderManaBoots(I, position);
	if ManaBootsDesire > 0 then return ManaBootsDesire; end
	local ShrineDesire = ConsiderShrine(I, position);
	if ShrineDesire > 0 then return ShrineDesire; end

	return 0;
end

function ConsiderManaBoots(I, position)
	local friends = I:GetNearbyHeroes(1600,true,BOT_MODE_NONE);
	
	if I.manaGuy and not I.manaGuy.manaBoot:IsFullyCastable() then
		I.manaGuy = nil;
	end
	if I.manaGuy then
		return 0.6;
	end
	local manaBoot = I:GetItem("item_arcane_boots");
	if manaBoot == nil then
		manaBoot = I:GetItem("item_guardian_greaves");
	end
	if manaBoot ~= nil and manaBoot:IsFullyCastable() then
		local wantMana = 0;
		for _, friend in ipairs(friends) do
			if friend:IsTrueHero() and friend:WantMana() then
				friend.manaGuy = I;
				wantMana = wantMana + 1;
			end
		end
		if wantMana > 0 then
			I.manaGuy = I;
			I.manaBoot = manaBoot;
		end
	else
		I.manaBoot = nil;
	end
	return 0;
end

function ConsiderShrine(I, position)
	if not I:IsTrueHero() or 
		I.shrine and GetShrineCooldown(I.shrine) > 10 and not IsShrineHealing(I.shrine) or
		not I:IsLowHealth() and not I:IsNoMana() and not I:WantHeal() and not I:WantMana() then
		I.shrine = nil;
		I.shrineTime = nil;
		return 0;
	end
	if I.shrine then
		if I:IsLowHealth() or I:IsNoMana() then
			return 0.8;
		else
			return 0.7;
		end
	end
	local team = GetTeam();
	local enemys = I:GetNearbyHeroes(1200,true,BOT_MODE_NONE);
	if (I:IsLowHealth() or I:IsNoMana()) and position <= 3 and not I.shrine then -- I need shrine and I'm core or I'm underattack
		local dist = I:DistanceFromFountain();
		for i = SHRINE_BASE_1, SHRINE_JUNGLE_2 do
			local shrine = GetShrine(team, i);
			if shrine ~= nil and GetShrineCooldown(shrine) < 10 then
				local thisDist = GetUnitToUnitDistance(I, shrine);
				local thisTime = thisDist/I:GetCurrentMovementSpeed() + 5;
				if thisTime >= GetShrineCooldown(shrine) and thisDist < dist then
					dist = thisDist;
					I.shrine = shrine;
					I.shrineTime = thisTime;
				end
			end
			shrine = nil; --< is this really necessary why is lua so weird
		end
	end
	if I.shrine and I.shrineTime then -- I have my shrine, who wants to come? pingpingping I do
		for P = 1,5 do
			local friend = GetTeamMember(P);
			if P ~= position and friend ~= nil and friend:IsTrueHero() and not friend.shrine and
			   ((friend:WantHeal() or friend:WantMana()) and
			    (GetUnitToUnitDistance(friend, I.shrine)/friend:GetCurrentMovementSpeed() <= Min(I.shrineTime,20) or
			     friend:HaveTp() <= I.shrineTime) or
			    (friend:IsLowHealth() or friend:IsLowMana()) and
			    (GetUnitToUnitDistance(friend, I.shrine)/friend:GetCurrentMovementSpeed() <= I.shrineTime or
			     friend:HaveTp() <= I.shrineTime)) then
				friend.shrine = I.shrine;
			end
		end
	end
	return 0;
end

-- function ConsiderTeamRoam(I, position)

-- end

function Think()
	local I = GetBot();
	if not I:IsTrueHero() or not I:CanAct() then
		return;
	end
	if I.manaGuy then
		ManaBootsThink(I);
	end
	if I.shrine then
		ShrineThink(I);
	end
end

function ManaBootsThink(I)
	if GetUnitToUnitDistance(I, I.manaGuy) > 900 then
		I:Action_MoveToUnit(I.manaGuy); --< maybe add return here?
		return;
	end
	if I.manaBoot ~= nil then
		local wait = 0;
		for P = 1,5 do
			local friend = GetTeamMember(P);
			if friend ~= nil and friend:IsTrueHero() and
			   friend.manaGuy == I and
			   friend:GetActiveMode() == BOT_MODE_ASSEMBLE and
			   GetUnitToUnitDistance(friend, I) > 900 then
				wait = wait + 1;
			end
		end
		if wait == 0 then
			I:Action_UseAbility(I.manaBoot);
		end
	end
end

function ShrineThink(I)
	if not I:IsTrueHero() or I.shrine and GetShrineCooldown(I.shrine) > 10 and not IsShrineHealing(I.shrine) then
		I.shrine = nil;
		I.shrineTime = nil;
		return;
	end
	local enemys = I:GetNearbyHeroes(1200,true,BOT_MODE_NONE);
	if GetUnitToUnitDistance(I, I.shrine) > 500 then
		I:Action_MoveToUnit(I.shrine); --< maybe add return here?
	end
	if GetShrineCooldown(I.shrine) == 0 then
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