Amalgam.ItemBlueprint({
    UniqueID = "weapon_pistol",
    Name = "Pistol",
    Description = "A standard 9mm pistol.",
    Model = "models/weapons/w_pistol.mdl",
    Weight = 5
})

Amalgam.ItemBlueprint({
    UniqueID = "medkit",
    Name = "Medkit",
    Description = "A medical kit that restores health",
    Model = "models/items/healthkit.mdl",
    Weight = 2,
    Use = function(self, ply)
        ply:SetHealth(math.min(ply:Health() + 25, ply:GetMaxHealth()))
        ply:RemoveItem(self.UniqueID, 1) 
    end
})

Amalgam.ItemBlueprint({
    UniqueID = "soup",
    Name = "Can of Soup",
    Description = "An old rusty can of soup, maybe its stil delicious",
    Model = "models/props_junk/garbage_metalcan002a.mdl",
    Weight = 0.4,
    Use = function(self, ply)
        ply:SetHealth(math.min(ply:Health() + 15, ply:GetMaxHealth()))
        ply:RemoveItem(self.UniqueID, 1) 
    end
})

Amalgam.ItemBlueprint({
    UniqueID = "ammo_9mm",
    Name = "9MM Ammo Box",
    Description = "A box of 9mm rounds",
    Model = "models/Items/BoxSRounds.mdl",
    Weight = 3
})