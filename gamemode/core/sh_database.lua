local meta = FindMetaTable("Player")

function meta:GetData(col, default)
    self.PlayerData = self.PlayerData or {}
    return (self.PlayerData[col] ~= nil and self.PlayerData[col] or default)
end

if (SERVER) then
    function meta:SetData(col, val, forcesave)
        if (not Amalgam.PlayerTable[col]) then return end
        self.PlayerData = self.PlayerData or {}

        self.PlayerData[col] = val

        local netVar = Amalgam.NetworkVars[col]
        if (netVar) then
            self[netVar.func](self, netVar.key, val)
            if (netVar.extra) then netVar.extra(self, val) end
        end

        if (forcesave ~= false) then
            timer.Simple(5, function()
                if (IsValid(self)) then
                    self:SaveData()
                end
            end)
        end
    end
end
