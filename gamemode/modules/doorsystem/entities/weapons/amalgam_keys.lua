AddCSLuaFile()

SWEP.PrintName = "Keys"
SWEP.Author = "Ceryx"
SWEP.Instructions = "LMB: Lock Door | RMB: Unlock Door"
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
    self.Raised = false
end

function SWEP:GetTargetDoor()
    local owner = self:GetOwner()
    if (not IsValid(owner)) then return end

    local tr = owner:GetEyeTrace()
    local ent = tr.Entity

    if (not ent:IsDoorEntity()) then return end
    if (tr.HitPos:Distance(owner:GetPos()) > 75) then return end
    return ent
end

function SWEP:PrimaryAttack()
    if (CLIENT) then return end
    self:SetNextPrimaryFire(CurTime() + 1.5)

    local door = self:GetTargetDoor()
    if (not IsValid(door)) then return end
    if (door.Locked) then return end

    local owner = door:GetNWEntity("DoorOwner")
    if (owner ~= self:GetOwner()) then return end

    door:Fire("Lock", "", 0)
    door.Locked = true
    self:GetOwner():EmitSound("doors/door_latch1.wav")
end

function SWEP:SecondaryAttack()
    if (CLIENT) then return end
    self:SetNextSecondaryFire(CurTime() + 1.5)

    local door = self:GetTargetDoor()
    if (not IsValid(door)) then return end
    if (not door.Locked) then return end

    local owner = door:GetNWEntity("DoorOwner")
    if (owner ~= self:GetOwner()) then return end

    door:Fire("Unlock", "", 0)
    door.Locked = false
    self:GetOwner():EmitSound("doors/door_latch3.wav")
end