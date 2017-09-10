function GetDesire()
	
	local I = GetBot();
	local position = I:GetPlayerPosition();
	if(DotaTime()<=8*60 and I:GetLevel()<9)
	then
		if position < 4 then return 0.4;
		else return 0.1; end
	else
		return 0.3;
	end

end
