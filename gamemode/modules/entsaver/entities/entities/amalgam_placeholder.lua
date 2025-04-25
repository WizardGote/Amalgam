AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Placeholder Entity"
ENT.Author = "Ceryx"
ENT.Category = "Amalgam"
ENT.Spawnable = true
ENT.CanPersist = true

function ENT:Initialize()
    if (CLIENT) then return end
	self:SetModel("models/props_junk/wood_crate001a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:Wake()
	end
end
