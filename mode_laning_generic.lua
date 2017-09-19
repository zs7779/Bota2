function GetDesire()
	
	local I = GetBot();
	local position = I:GetPlayerPosition();
	if(DotaTime()<=8*60 and I:GetLevel()<9)
	then
		if position < 4 then return 0.35;
		else return 0.2; end
	else
		return 0.27;
	end

end
