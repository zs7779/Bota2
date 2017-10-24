-- Assemble should be before a lot of things
-- 1. mek/mana
-- 2. shrine
-- 3. gank/smoke gank
-- 4. push
-- 5. rosh

-- I.want_mana/mek/shrine lowhealth/lowmana, lostHealth > 250 ...
-- if I have manaboot/mek, calculate assemble location (not too far), 
-- or calculate shrine location (can be far if have tp), give location to friends
-- assemble at location
-- assess feasibility of gank/push/rosh
-- assemble if not assembled


require(GetScriptDirectory() ..  "/utility")
local role = require(GetScriptDirectory() ..  "/RoleUtility")

function CDOTA_Bot_Script:GetFactor()
	return self:GetHealth()/self:GetMaxHealth()+self:GetMana()/self:GetMaxMana()
end

function GetAllyFactor(npcAlly)
	local npcBot=GetBot()
	local front = npcBot:GetLocation()
	local distance = GetUnitToLocationDistance( npcAlly, front )
	local nearBuilding = utility.GetNearestBuilding(GetTeam(), front)
	local distBuilding = GetUnitToLocationDistance( nearBuilding, front )
	local distFactor = 0
	local StateFactor=npcAlly:GetFactor()/2
	local powerFactor=math.min(npcAlly:GetOffensivePower()/npcAlly:GetMaxHealth(),1)
	
	local enemys=npcAlly:GetNearbyHeroes(1200,true,BOT_MODE_NONE)
	if((npcAlly:GetAssignedLane()==LANE_MID or role.IsCarry(npcAlly:GetUnitName()) or role.IsSupport(npcAlly:GetUnitName())==false) and npcAlly:GetLevel()<=6 )
	then
		return 0
	end
	
	if(#enemys>0)
	then
		return 0
	end
	
	local tp=utility.IsItemAvailable("item_tpscroll")
	if tp then
		tp = tp:IsFullyCastable()
	end
	tp=nil
	local travel = utility.IsItemAvailable("item_travel_boots")
	if travel then
		travel = travel:IsFullyCastable()
	end

	if distance <= 1000 or travel then
		distFactor = 1
	elseif distance - distBuilding >= 3000 and tp then
		if distBuilding <= 1000 then
			distFactor = 0.7
		elseif distBuilding >= 6000 then
			distFactor = 0
		else
			distFactor = -(distBuilding - 6000) * 0.7 / 5000
		end
	elseif distance >= 6000 then
		distFactor = 0
	else
		distFactor = (6000-distance) / 6000
	end

	local factor=StateFactor*0.7+distFactor*0.3--+powerFactor*0.4
	return factor
end

function GetDesire()
	local npcBot=GetBot()
	
	if(npcBot:IsAlive()==false)
	then
		return 0
	end
	local ShrineDesire=GetShrineDesire()
	return ShrineDesire

end

function Think()
	ShrineThink()
end

function GetShrineDesire()
	local npcBot=GetBot()

	if ( npcBot:IsUsingAbility() or npcBot:IsChanneling())
	then
		return 0
	end

	local enemys = npcBot:GetNearbyHeroes(1600,true,BOT_MODE_NONE)

	if(npcBot.ShrineTime==nil)
	then
		npcBot.ShrineTime=0
	end

	if(	npcBot:IsAlive()==false or
		(npcBot:DistanceFromFountain()<=6000 and (npcBot:GetStashValue()>400 or npcBot:GetMaxMana()-npcBot:GetMana()>=400) and #enemys==0) or
		(npcBot.GoingToShrine==true and GetShrineCooldown(npcBot.Shrine)>10 and IsShrineHealing(npcBot.Shrine)==false) or
		npcBot:GetFactor()>1.8 or
		(GetUnitToUnitDistance(npcBot,npcBot.Shrine)>7500) or
		(npcBot.Shrine==nil or npcBot.GoingToShrine==false)
	)
	then
		npcBot.GoingToShrine=false
		npcBot.Shrine=nil
	end

	if(npcBot.GoingToShrine==false)
	then
		ConsiderShrine()
	end

	if(npcBot.GoingToShrine==true and (GetUnitToUnitDistance(npcBot,npcBot.Shrine)>=300 or IsShrineHealing(npcBot.Shrine)==false)
		and DotaTime()+GetUnitToUnitDistance(npcBot,npcBot.Shrine)/npcBot:GetCurrentMovementSpeed() >= npcBot.ShrineTime)
	then
		local HealthFactor=npcBot:GetHealth()/npcBot:GetMaxHealth()
		return 0.7+(1-HealthFactor)*0.3
	end
	return 0.0;
end

function ConsiderShrine()
	local Shrines={	SHRINE_BASE_1,
					SHRINE_BASE_2,
					SHRINE_BASE_3,
					SHRINE_BASE_4,
					SHRINE_BASE_5,
					SHRINE_JUNGLE_1,
					SHRINE_JUNGLE_2	}

	local npcBot=GetBot()
	local enemys = npcBot:GetNearbyHeroes(1600,true,BOT_MODE_NONE)

	if(npcBot:GetActiveMode() == BOT_MODE_RETREAT and npcBot.GoingToShrine~=true and
		(npcBot:GetFactor()<1.2 or npcBot:GetMaxHealth()-npcBot:GetHealth()>=400) and
		(npcBot:GetMaxMana()-npcBot:GetMana()<=400 and npcBot:GetMaxHealth()-npcBot:GetHealth()<=1000 or #enemys>0  ))
	then
		local TargetShrine
		local min_distance=10000
		for _,s in pairs(Shrines)
		do
			local shrine=GetShrine(GetTeam(),s)
			if(shrine~=nil)
			then
				if(GetShrineCooldown(shrine)<10 or IsShrineHealing(shrine)==true)
				then
					d=GetUnitToUnitDistance(npcBot,shrine)
					if(d<min_distance)
					then
						min_distance=d
						TargetShrine=shrine
					end
				end
			end
		end
		if(2*min_distance<npcBot:DistanceFromFountain())
		then
			local shrineLocation=TargetShrine:GetLocation()
			local max_distance=GetUnitToUnitDistance(npcBot,TargetShrine)/npcBot:GetCurrentMovementSpeed()
			local allys=GetUnitList(UNIT_LIST_ALLIED_HEROES)

			for _,ally in pairs (allys)
			do
				allyfactor=ally:GetFactor()
				if((allyfactor<1.6 or ally:GetMaxHealth()-ally:GetHealth()>=300) and GetUnitToUnitDistance(ally,TargetShrine)<=7500-allyfactor*1500) and ally:IsAlive()
				then
					ally.Shrine=TargetShrine
					ally.GoingToShrine=true

					local distance = GetUnitToUnitDistance(ally,TargetShrine)/ally:GetCurrentMovementSpeed()
					if distance>max_distance
					then
						max_distance=distance
					end
				end
			end


			for _,ally in pairs (allys)
			do
				if(TargetShrine==ally.Shrine)
				then
					ally.ShrineTime=DotaTime()+max_distance
					--npcBot:ActionImmediate_Chat("Enjoy together"..ally:GetUnitName()..ally.ShrineTime,false)
				end
			end

			npcBot.Shrine=TargetShrine
			npcBot.GoingToShrine=true

			npcBot.ShrineTime=DotaTime()+max_distance
			npcBot:ActionImmediate_Chat("I want to use Shrine,let's enjoy together! 我想要使用神泉，快来一起享用",false)
			--npcBot:ActionImmediate_Ping(shrineLocation.x,shrineLocation.y,true)

		end
	end

end

function ShrineThink()
	local npcBot=GetBot()

	if ( npcBot:IsUsingAbility() or npcBot:IsChanneling())
	then
		return
	end

	if(npcBot.GoingToShrine==true and npcBot.Shrine~=nil)
	then
		if(GetUnitToUnitDistance(npcBot,npcBot.Shrine)<300 and GetShrineCooldown(npcBot.Shrine)<5)
		then
			local allys = npcBot:GetNearbyHeroes( 1600, false, BOT_MODE_NONE );
			local enemys = npcBot:GetNearbyHeroes(1600,true,BOT_MODE_NONE)
			local ready=true

			if(#enemys>0)
			then
				ready=true
			else
				for _,ally in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES))
				do
					local allyfactor=ally:GetHealth()/ally:GetMaxHealth()+ally:GetMana()/ally:GetMaxMana()
					local distance=GetUnitToUnitDistance(ally,npcBot.Shrine)
					if(IsPlayerBot(ally:GetPlayerID())==false and distance>500 and allyfactor<1.6 and distance<6000)
					then
						if(ally.ShrineHuman==nil)
						then
							ally.ShrineHuman={}
							ally.ShrineHuman.timer=DotaTime()
							ally.ShrineHuman.distance=distance
							ready=false
						else
							if(DotaTime()-ally.ShrineHuman.timer>5)
							then
								if(distance<ally.ShrineHuman.distance)
								then
									ready=false
								else
									ready=true
									ally.ShrineHuman=nil
								end
							else
								ready=false
							end
						end
					end
				end
				for _,ally in pairs (GetUnitList(UNIT_LIST_ALLIED_HEROES))
				do
					if(IsPlayerBot(ally:GetPlayerID())==true)
					then
						if(ally.GoingToShrine==true and GetUnitToUnitDistance(ally,npcBot.Shrine)>500 and ally.Shrine==npcBot.Shrine)
						then
							ready=false
						end
					end
				end
			end

			if(ready==true)
			then
				npcBot:Action_UseShrine(npcBot.Shrine)
			else
				npcBot:Action_MoveToUnit(npcBot.Shrine)
			end
		else
			npcBot:Action_MoveToUnit(npcBot.Shrine)
		end
	end
end