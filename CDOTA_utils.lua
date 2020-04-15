-- Extend helper functions to CDOTA_Bot_Script class, which is the class of the Bot objects

local debug = true;

function CDOTA_Bot_Script:InitializeBot()
    if debug then
        print(self:GetUnitName());
    end

    self.is_initialized = false;

    self:GetPlayerPosition();
    self:GetAbilities();

    self.is_initialized = true;

    if debug then
        print("Initialized");
    end
end

-- Get Bot position in game as a number between 1-5, 1 being carry, 5 being hard support
function CDOTA_Bot_Script:GetPlayerPosition()
    if self.position == nil then
        for position = 1,5 do
            if self == GetTeamMember(position) then
                self.position = position;
                break;
            end
        end    
    end

    if debug then
        print("Position", self.position);
    end
	return self.position;
end

function CDOTA_Bot_Script:GetAbilities()
    -- self.abilities = {anything} crush, could be a memory problem? maybe we shouldn't be changing CDOTA
    local abilities = {};
    if self.abilities == nil then
        for i = 0,23 do
            local ability = self:GetAbilityInSlot(i);
            if ability ~= nil and not ability:IsTalent() and not ability:IsItem() and not ability:IsHidden() and not ability:IsPassive() then
                abilities[#abilities+1] = i;
            end
        end
        self.abilities = abilities;
    end

    if debug then
        print("Abilities")
        for i = 1,#abilities do
            print(self.abilities[i], self:GetAbilityInSlot(self.abilities[i]):GetName());
        end
    end
	return self.abilities;
end