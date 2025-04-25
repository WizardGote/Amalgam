Amalgam.JobBlueprint({
    UniqueID = "Job_Scum",
    Name = "Urban Scavenger",
    Description = "A bottom-feeder who survives by picking scraps, stealing parts, and living off society’s waste.",
    Model = "models/player/guerilla.mdl"
})

Amalgam.JobBlueprint({
    UniqueID = "Job_Medic",
    Name = "Paramedic",
    Description = "A field medic trained to stabilize the dying, treat wounds, and ignore the screams.",
    Model = "models/player/kleiner.mdl",
    CanRadio = true,
    Income = 25,
    MaxSlots = 2
})

Amalgam.JobBlueprint({
    UniqueID = "Job_Cop",
    Name = "Police Officer",
    Description = "An enforcer of law and order—tasked with protecting the city, even if the system is rotten.",
    Model = "models/player/police.mdl",
    Income = 50,
    MaxSlots = 4,
    CanRadio = true,
    JobFunc = function(ply)
        ply:Give("weapon_pistol")
        ply:GiveAmmo(30, "Pistol", true)
        ply:Give("weapon_stunstick")
    end
})

Amalgam.JobBlueprint({
    UniqueID = "Job_Mayor",
    Name = "Mayor",
    Description = "The city's political figurehead. Controls public policy, manipulates budgets, and pretends to lead.",
    Model = "models/player/breen.mdl",
    Income = 100,
    MaxSlots = 1
})
