AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Spawnable  = false
ENT.AdminSpawnable  = false
ENT.Display = true
ENT.FadeAlpha = 0

function ENT:PostEntityPaste(ply, ent, tab)
    ent:Remove()
end

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "Amount")
end

function ENT:Initialize()
    if (CLIENT) then return end
    self:SetModel("models/props_lab/box01a.mdl")
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if (IsValid(phys)) then
        phys:Wake()
    end

    self:SetAmount(self:GetAmount() or 0)
end

function ENT:Use(activator, caller)
    if (IsValid(activator) and activator:IsPlayer()) then
        activator:AddMoney(self:GetAmount())
        activator:EmitSound("npc/zombie/foot_slide1.wav", 75, 100)
        self:Remove()
    end
end

function ENT:DisplayHUDInfo(tbl)
    local amount = self:GetAmount() or 0
    tbl.lines = {
        {
            text = amount .. "$",
            font = "DermaLarge",
            color = Color(255, 168, 0)
        }
    }

    tbl.offset = Vector(0, 0, 0)
end