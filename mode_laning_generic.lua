require(GetScriptDirectory() ..  "/utils")

function GetDesire()
	
	local I = GetBot();
	local position = I:GetPlayerPosition();
	if DotaTime()<=8*60 and I:GetLevel()<7 and position < 4 then
		return 0.35;
	else
		return 0.27;
	end

end

function GetDesire()
	
	local npcBot = GetBot();
	
	if(DotaTime()>=8*60 and npcBot:GetLevel()<7)
	then
		return 0.35
	else
		return 0.27
	end

end