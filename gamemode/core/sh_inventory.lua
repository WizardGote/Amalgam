local meta = FindMetaTable("Player")

Amalgam.Items = {}

function Amalgam.ItemBlueprint(data)
    data.Drop = data.Drop or function(self, ply)
        local item = ents.Create("amalgam_item")

        if (IsValid(item)) then
            item:SetModel(self.Model)
            item:SetItemData(self.UniqueID)
            item:SetPos(ply:GetPos() + ply:GetForward() * 45 + Vector(0, 0, 10))
            item:Spawn()
        end
        ply:RemoveItem(self.UniqueID, 1)
        ply:EmitSound("npc/zombie/foot_slide1.wav", 75, 100)
    end

    Amalgam.Items[data.UniqueID] = data
    return data
end

function meta:GetInventory()
    if (SERVER) then
        local invString = self:GetData("Inventory", "")
        self.inv = {}

        if (invString == "") then return self.inv end

        local exp = string.Explode("|", invString)
        for _, v in pairs(exp) do
            local data = string.Explode(":", v)
            local itemID = data[1]
            local amount = tonumber(data[2]) or 1
            self.inv[itemID] = amount
        end

        return self.inv
    else
        return self.Inventory or {}
    end
end

function meta:GetInventoryWeight()
    local weight = 0
    local inv = self:GetInventory()

    for itemID, amount in pairs(inv) do
        local itemData = Amalgam.Items[itemID]
        if (itemData and itemData.Weight) then
            weight = weight + (itemData.Weight * amount)
        end
    end

    return weight
end

if (SERVER) then

    function meta:SaveInventory(inv)
        local entries = {}

        for itemID, amount in pairs(inv) do
            table.insert(entries, itemID .. ":" .. amount)
        end

        local str = table.concat(entries, "|")
        self:SetData("Inventory", str)
    end

    function meta:SyncInventory()
        local inv = self:GetInventory()
        net.Start("nSendInventory")
            net.WriteTable(inv)
        net.Send(self)
    end

    function meta:CanPickupItem(itemID)
        local item = Amalgam.Items[itemID]
        if (not item or not item.Weight) then return true end

        local currentWeight = self:GetInventoryWeight()
        local maxWeight = Amalgam.GetConfig("MaxWeight")

        return (currentWeight + item.Weight) <= maxWeight
    end

    function meta:TakeItem(itemID)
        local item = Amalgam.Items[itemID]
        if (not item) then return end

        if (not self:CanPickupItem(itemID)) then
            return
        end

        local inv = self:GetInventory()
        inv[itemID] = (inv[itemID] or 0) + 1
        self:SaveInventory(inv)
        self:SyncInventory()
    end

    function meta:AddItem(itemID, amount)
        local item = Amalgam.Items[itemID]
        if (not item) then return end

        local inv = self:GetInventory()
        inv[itemID] = (inv[itemID] or 0) + amount
        self:SaveInventory(inv)
        self:SyncInventory()
    end

    function meta:RemoveItem(itemID, amount)
        local inv = self:GetInventory()

        if (inv[itemID]) then
            inv[itemID] = inv[itemID] - amount
            if (inv[itemID] <= 0) then
                inv[itemID] = nil
            end
            self:SaveInventory(inv)
            self:SyncInventory()
        end
    end

    function meta:ForceInvSync()
        timer.Simple(1, function()
            if (IsValid(self)) then
                self:GetInventory()
                self:SyncInventory()
            end
        end)
    end

    net.Receive("nItemFunc", function(len, ply)
        local itemID = net.ReadString()
        local actionName = net.ReadString()

        local itemData = Amalgam.Items[itemID]
        if (not itemData) then 
            return 
        end

        local itemFunc = itemData[actionName]
        if (not isfunction(itemFunc)) then 
            return 
        end

        itemFunc(itemData, ply)
    end)


    net.Receive("nDropMoney", function(len, ply)
        local amount = net.ReadUInt(32)
        local money = ents.Create("amalgam_money")

        if (ply:Money() < amount) then
            ply:Notify("You don't have enough money!")
            return
        end

        if (amount <= 0) then
            ply:Notify("Invalid amount! Please enter a valid number.")
            return
        end

        if (IsValid(money)) then
            money:SetPos(ply:GetPos() + ply:GetForward() * 45 + ply:GetUp() * 64)
            money:SetAmount(amount)
            money:Spawn()
        end

        ply:EmitSound("npc/zombie/foot_slide1.wav", 75, 100)
        ply:AddMoney(-amount)
    end)
end
