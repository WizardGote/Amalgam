MODULE.Name = "Doors System"
MODULE.Description = ""
MODULE.Author = "Oriensnox"

Amalgam.Doors = Amalgam.Doors or {}

local meta = FindMetaTable("Entity")

function meta:IsDoorEntity()
    local class = self:GetClass()
    return class == "prop_door_rotating" or class == "func_door" or class == "func_door_rotating"
end

Amalgam.LoadFile("sv_doors.lua")
Amalgam.LoadFile("cl_doors.lua")

