AddCSLuaFile()

SWEP.PrintName = "Hands"
SWEP.Author = "Ceryx"
SWEP.Instructions = "LMB: Pick Item / Drop Item | RMB: Knock on Doors"
SWEP.Category = "Amalgam"
SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel = Model("models/weapons/c_arms.mdl")
SWEP.WorldModel = ""
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DrawCrosshair = false

function SWEP:Initialize()
    self:SetHoldType("normal")
end

local function IsPickupAllowed(ent)
    if (not IsValid(ent)) then return false end

    local item = ent:GetClass()
    if (item == "amalgam_item" or item == "amalgam_money") then return true end

    if (ent:IsPlayer() or ent:IsNPC()) then return false end
    if (ent:GetMoveType() ~= MOVETYPE_VPHYSICS) then return false end

    local phys = ent:GetPhysicsObject()
    if (not IsValid(phys) or not phys:IsMoveable()) then return false end
    if (phys:GetMass() > 75) then return false end

    local size = ent:OBBMaxs() - ent:OBBMins()
    if (size:Length() > 100) then return false end

    return true
end

function SWEP:PrimaryAttack()
    if (CLIENT) then return end

    local owner = self:GetOwner()
    local tr = owner:GetEyeTrace()
    local ent = tr.Entity

    if (IsValid(ent) and ent:IsDoorEntity() and tr.HitPos:DistToSqr(owner:GetShootPos()) < 10000) then
        ent:EmitSound("physics/wood/wood_crate_impact_hard2.wav")
        owner:EmitSound("physics/wood/wood_crate_impact_hard3.wav")
    end
end

function SWEP:SecondaryAttack()
    if (CLIENT) then return end

    local owner = self:GetOwner()

    if (self.HeldEnt and IsValid(self.HeldEnt)) then
        local ent = self.HeldEnt
        self.HeldEnt = nil

        ent:SetOwner(nil)
        ent:SetCollisionGroup(COLLISION_GROUP_NONE)
        ent:SetMoveType(MOVETYPE_VPHYSICS)

        local phys = ent:GetPhysicsObject()
        if (IsValid(phys)) then
            phys:EnableMotion(true)
            phys:Wake()
            phys:ApplyForceOffset(Vector(0, 0, 0), phys:GetMassCenter())
        end

        ent:SetPos(ent:GetPos())
        ent:SetAngles(ent:GetAngles())

        return
    end

    local tr = owner:GetEyeTrace()
    local ent = tr.Entity

    if (not IsPickupAllowed(ent)) then return end

    local phys = ent:GetPhysicsObject()
    if (not IsValid(phys)) then return end

    self.HeldEnt = ent
    ent:SetOwner(owner)
    ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    ent:SetMoveType(MOVETYPE_NONE)
    phys:EnableMotion(false)

    owner:EmitSound("physics/wood/wood_crate_pickup2.wav")
end

function SWEP:Holster()
    if (SERVER and self.HeldEnt and IsValid(self.HeldEnt)) then
        local ent = self.HeldEnt
        self.HeldEnt = nil

        local dropPos = ent:GetPos()
        local dropAng = ent:GetAngles()

        ent:SetOwner(nil)
        ent:SetCollisionGroup(COLLISION_GROUP_NONE)
        ent:SetMoveType(MOVETYPE_VPHYSICS)
        ent:SetPos(dropPos)
        ent:SetAngles(dropAng)

        local phys = ent:GetPhysicsObject()
        if (IsValid(phys)) then
            phys:EnableMotion(true)
            phys:Wake()
        end
    end

    return true
end

function SWEP:Think()
    if (CLIENT) then return end

    local ent = self.HeldEnt
    if (not IsValid(ent)) then return end

    local owner = self:GetOwner()
    local pos = owner:GetShootPos() + owner:GetAimVector() * 50

    ent:SetPos(pos)
    ent:SetAngles(Angle(0, owner:EyeAngles().y, 0))
end

function SWEP:Deploy()
    self:SetHoldType((self.Raised and "fist") or "normal")

    local owner = self:GetOwner()
    local vm = owner:GetViewModel()

    owner:DrawViewModel(self.Raised)

    if (IsValid(vm)) then
        vm:SendViewModelMatchingSequence(vm:LookupSequence("fists_idle"))
    end

    return true
end