function GetDesire()
	
	local npcBot = GetBot();
	local position = npcBot:GetPlayerPosition();
	if(DotaTime()<=8*60 and npcBot:GetLevel()<7)
	then
		if position < 4 then return 0.6;
		else return 0.3; end
	else
		return 0.1;
	end

end
