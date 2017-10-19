----------------------------------------------------------------------------
--	Ranked Matchmaking AI v1.0a
--	Author: adamqqq		Email:adamqqq@163.com
----------------------------------------------------------------------------
require(GetScriptDirectory() ..  "/utility")
local role = require(GetScriptDirectory() ..  "/RoleUtility")

function CDOTA_Bot_Script:GetFactor()
	return self:GetHealth()/self:GetMaxHealth()+self:GetMana()/self:GetMaxMana()
end

function GetDesire()
	local npcBot=GetBot()
	
	if(npcBot:IsAlive()==false)
	then
		return 0
	end
	local TeamRoamDesire=GetTeamRoamDesire()

	return TeamRoamDesire
end

function Think()
	TeamRoamThink()
end

function GetTeamRoamDesire()
	local npcBot=GetBot()

	if(CheckTimer==nil or CheckTimer>DotaTime())
	then
		CheckTimer=DotaTime()
	end

	if(DotaTime()-CheckTimer>5 and npcBot.TeamRoam~=true and npcBot.TeamRoamTimer==nil)
	then
		ConsiderTeamRoam()
		CheckTimer=DotaTime()
	end

	if(npcBot.TeamRoam==true)
	then
		return 0.7
	end

	return 0
end

function ConsiderTeamRoam()
	local npcBot=GetBot()
	local item_smoke = utility.IsItemAvailable("item_smoke_of_deceit")
	
	if(item_smoke~=nil and GetAllyFactor(npcBot)>=0.75)
	then
		local factor,target,allys=FindTarget()
		if(factor>0.7)
		then
			local nearBuilding = utility.GetNearestBuilding(GetTeam(), npcBot:GetLocation())
			local location = GetUnitsTowardsLocation(nearBuilding,GetAncient(GetTeam()),600)
			npcBot.TeamRoamAssemblyPoint=location
			npcBot:ActionImmediate_Chat("Let's Gank "..string.gsub(target:GetUnitName(),"npc_dota_hero_","").." together! ",false)
			print(npcBot:GetPlayerID().." @TeamRoam@ Let's Gank together! Factor:"..factor.." target:"..target:GetUnitName())
			npcBot:ActionImmediate_Ping(location.x,location.y,true)
			
			for _,npcAlly in pairs(allys)
			do
				npcAlly.TeamRoam=true
				npcAlly.TeamRoamState="Assemble"
				npcAlly.TeamRoamTargetID=target:GetPlayerID()
				npcAlly.TeamRoamLeader=npcBot
				npcAlly.TeamRoamTimer=DotaTime()
				npcAlly:SetTarget(target)
				npcBot:ActionImmediate_Chat(string.gsub(npcAlly:GetUnitName(),"npc_dota_hero_","").." come to Gank!",false)
				print(npcBot:GetPlayerID().." @TeamRoam@"..npcAlly:GetUnitName().." want to Gank together!")
			end
		end
	end
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

function GetEnemyFactor(npcEnemy,allys)
	local npcBot=GetBot()
	if(GetUnitToUnitDistance(npcBot,npcEnemy)>=2000)
	then
		local TowersCount=0
		local AllysCount=#allys
		local EnemysCount=0
		local damageFactor=0
		local distance=GetUnitToUnitDistance(npcBot,npcEnemy)
		local distFactor=math.max(0,(6000-distance)/6000)

		for j=0,8,1 do
			local tower=GetTower(utility.GetOtherTeam(),j);
			if NotNilOrDead(tower) and GetUnitToUnitDistance(npcEnemy,tower)<1600 then
				TowersCount=TowersCount+1;
			end
		end

		local enemys2=npcEnemy:GetNearbyHeroes(1600,false,BOT_MODE_NONE)

		for _,enemy in pairs (enemys2)
		do
			if(enemy:GetFactor()>=1.0)
			then
				EnemysCount=EnemysCount+1
			end
		end
	
		if(TowersCount>0 or EnemysCount-AllysCount>=1)
		then
			return 0,0
		end
		
		local sumdamage=0
		local suitableallys={}
		local allys3 = npcEnemy:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
		for i,npcAlly in pairs(allys3)
		do
			local IsIn=false
			for i,npcAlly2 in pairs(allys)
			do
				if(npcAlly:GetPlayerID()==npcAlly2:GetPlayerID())
				then
					IsIn=true
				end
			end
			if(IsIn==false)
			then
				table.insert(allys,npcAlly)
			end
			--print(npcBot:GetPlayerID().." [TeamRoam] Ally damage include/ "..npcAlly:GetUnitName())
		end
		
		for i,npcAlly in pairs(allys)
		do
			if(GetUnitToUnitDistance(npcAlly,npcEnemy)>=1600)
			then
				table.insert(suitableallys,npcAlly)
			end
			sumdamage=sumdamage+npcAlly:GetEstimatedDamageToTarget(true,npcEnemy,5.0,DAMAGE_TYPE_ALL)
		end
		
		damageFactor=math.min(sumdamage/npcEnemy:GetHealth(),1.25)/1.25
		local factor=damageFactor*0.7+distFactor*0.3
		if(npcEnemy:IsBot()==false)
		then
			factor=factor*1.2
		end
		print(npcBot:GetPlayerID().." =[TeamRoam] Enemy/"..npcEnemy:GetUnitName().."/ sumdamage:"..sumdamage.."/ Factor:"..factor)
		return math.min(1.0,factor),suitableallys
	end
	return 0,0
end


function FindTarget()

	local npcBot=GetBot()
	local allys2= GetUnitList(UNIT_LIST_ALLIED_HEROES)
	local allys={}
	--print("---------------------------")
	for i,npcAlly in pairs(allys2)
	do
		local factor=GetAllyFactor(npcAlly)
		if(factor>=0.8)
		then
			--print(npcBot:GetPlayerID().." [TeamRoam] SearchAlly/ "..npcAlly:GetUnitName().." / Factor:"..factor)
			table.insert(allys,npcAlly)
		end
	end

	if(#allys==0)
	then
		return 0,0
	end

	local MaxFactor=0
	local BestTarget
	local BestAllys={}
	local enemys= GetUnitList(UNIT_LIST_ENEMY_HEROES)
	for _,npcEnemy in pairs(enemys)
	do
		local factor,suitableallys=GetEnemyFactor(npcEnemy,allys)
		if(factor>MaxFactor)
		then
			MaxFactor=factor
			BestTarget=npcEnemy
			BestAllys=suitableallys
		end
	end
	
	return MaxFactor,BestTarget,BestAllys

end

function GetLocationTowardsLocation(vMyLocation,vTargetLocation, nUnits)
	local tempvector=(vTargetLocation-vMyLocation)/utility.PointToPointDistance(vMyLocation,vTargetLocation)
	return vMyLocation+nUnits*tempvector
end

function TeamRoamThink()
	local npcBot=GetBot()

	local towers=npcBot:GetNearbyTowers(1000,true)

	if(npcBot.TeamRoam==true)
	then
		if(IsHeroAlive(npcBot.TeamRoamTargetID)==false or DotaTime()-npcBot.TeamRoamTimer>=40 or #towers>=1)
		then
			npcBot.TeamRoam=false
			return
		end
	end

	if(npcBot.TeamRoamState=="Assemble")
	then
		if(npcBot.TeamRoamLeader:GetUnitName()==npcBot:GetUnitName())
		then
			local enemys=npcBot:GetNearbyHeroes(1000,true,BOT_MODE_NONE)
			local ready=true
			
			if(#enemys>0)
			then
				ready=false
				npcBot.TeamRoamAssemblyPoint=GetLocationTowardsLocation(npcBot.TeamRoamAssemblyPoint,GetAncient(GetTeam()):GetLocation(),100)
			end
			
			for _,npcAlly in pairs (GetUnitList(UNIT_LIST_ALLIED_HEROES ))
			do
				if(IsPlayerBot(npcAlly:GetPlayerID())==true and npcAlly.TeamRoam==true)
				then
					if(GetUnitToUnitDistance(npcBot,npcAlly)>1000)
					then
						ready=false
					end
				end
			end

			if(ready==true)
			then
				local item_smoke = utility.IsItemAvailable("item_smoke_of_deceit")
				if(npcBot:HasModifier("modifier_smoke_of_deceit")==false)
				then
					npcBot:Action_UseAbility(item_smoke)
					npcBot:ActionImmediate_Chat("smoke used!",false)
				end
			else
				npcBot:Action_MoveToLocation(npcBot.TeamRoamAssemblyPoint)
			end
		else
			if(GetUnitToUnitDistance(npcBot,npcBot.TeamRoamLeader)>300)
			then
				npcBot:Action_MoveToLocation(npcBot.TeamRoamLeader:GetLocation())
			end
		end

		if(npcBot:HasModifier("modifier_smoke_of_deceit"))
		then
			npcBot.TeamRoamState="Roaming"
			npcBot.TeamRoamTimer=DotaTime()
		end

	elseif(npcBot.TeamRoamState=="Roaming")
	then
		local enemys3=GetUnitList(UNIT_LIST_ENEMY_HEROES)
		local target
		for _,enemy in pairs(enemys3)
		do
			if(enemy:GetPlayerID()==npcBot.TeamRoamTargetID)
			then
				target=enemy
			end
		end

		local seeninfo=GetHeroLastSeenInfo(npcBot.TeamRoamTargetID)
		local seenpoint=seeninfo[1].location
		seenpoint=GetLocationTowardsLocation(seenpoint,GetAncient(utility.GetOtherTeam()):GetLocation(),1000)
		local seentime=seeninfo[1].time_since_seen

		if(seentime>5 and npcBot.TeamRoamLeader:GetUnitName()==npcBot:GetUnitName())
		then
			local factor,target2,ChangedAllys=FindTarget()
			if(factor>0.6)
			then
				npcBot.TeamRoamTargetID=target2:GetPlayerID()
				for i,npcAlly in pairs(ChangedAllys)
				do
					npcAlly.TeamRoamTargetID=target2:GetPlayerID()
				end
				npcBot:ActionImmediate_Chat("Target Change to "..string.gsub(target2:GetUnitName(),"npc_dota_hero_",""),false)
				print(npcBot:GetPlayerID().." Target Change！factor:"..factor.." target:"..target2:GetUnitName())
			else
				npcBot.TeamRoam=false
				for i,npcAlly in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES))
				do
					npcAlly.TeamRoam=false
				end
				npcBot:ActionImmediate_Chat("Target disappear, Ganking stop",false)
				print(npcBot:GetPlayerID().." Target disappear！Roaming stop")
			end
		end
		
		if(GetUnitToLocationDistance(npcBot,seenpoint)<=1200)
		then
			if(target~=nil)
			then
				npcBot:SetTarget(target)
				npcBot:Action_AttackUnit(target,false)
			else
				npcBot:Action_AttackMove(seenpoint)
			end
		else
			local ready=true
			for _,npcAlly in pairs (GetUnitList(UNIT_LIST_ALLIED_HEROES ))
			do
				if(IsPlayerBot(npcAlly:GetPlayerID())==true and npcAlly.TeamRoam==true)
				then
					if(GetUnitToUnitDistance(npcBot,npcBot.TeamRoamLeader)>500)
					then
						ready=false
					end
				end
			end

			if(ready==true)
			then
				npcBot:Action_MoveToLocation(seenpoint)
			else
				npcBot:Action_MoveToLocation(npcBot.TeamRoamLeader:GetLocation())
			end
		end
	end

end

function OnEnd()
	local npcBot=GetBot()
	npcBot.TeamRoam=false
	npcBot.TeamRoamState=nil
	npcBot.TeamRoamTargetID=nil
	npcBot.TeamRoamLeader=nil
	npcBot.TeamRoamTimer=nil
end
