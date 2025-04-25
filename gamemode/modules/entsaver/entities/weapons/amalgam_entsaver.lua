AddCSLuaFile()

SWEP.PrintName = "[Dev] Persistence Tool"
SWEP.Author = "Ceryx"
SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = ""
SWEP.Instructions = "LMB: Persist Entity | RMB: Unpersist Entity"
SWEP.Category = "Amalgam"
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.UseHands = true
SWEP.DrawAmmo = false
SWEP.HoldType = "magic"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
    if (SERVER) then return end
    self:SetHoldType(self.HoldType)
    LocalPlayer().TempEntities = LocalPlayer().TempEntities or {}
end

function SWEP:DoMagic()
    if (not IsFirstTimePredicted()) then return end

    local owner = self:GetOwner()
    if (not IsValid(owner)) then return end

    local startPos

    if (CLIENT and owner == LocalPlayer()) then
        local vm = owner:GetViewModel()
        if (IsValid(vm)) then
            local attachment = vm:LookupAttachment("anim_attachment_RH")
            if (attachment > 0) then
                local data = vm:GetAttachment(attachment)
                if (data) then
                    startPos = data.Pos
                end
            end
        end
    else
        local attachment = owner:LookupAttachment("anim_attachment_RH")
        if (attachment > 0) then
            local data = owner:GetAttachment(attachment)
            if (data) then
                startPos = data.Pos
            end
        end
    end

    if (not startPos) then
        startPos = owner:GetShootPos()
    end

    local endPos = startPos + owner:GetAimVector() * 4096

    local effect = EffectData()
    effect:SetStart(startPos)
    effect:SetOrigin(endPos)
    effect:SetAttachment(1)
    effect:SetEntity(owner)
    util.Effect("ToolTracer", effect)

    owner:EmitSound("weapons/airboat/airboat_gun_lastshot" .. math.random(1, 2) .. ".wav", 75, math.random(70, 80))
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.5)

    self:DoMagic()

    local owner = self:GetOwner()
    if (not IsValid(owner)) then return end

    local tr = owner:GetEyeTrace()
    local ent = tr.Entity

    if (not IsValid(ent) or ent:IsWorld()) then
        self.Owner:Notify("Target is not a valid entity.")
        return
    end

    if (not ent.CanPersist) then
        self.Owner:Notify("Entities are required: 'ENT.CanPersist = true'")
        return
    end

    local pos = ent:GetPos()
    local ang = ent:GetAngles()
    local class = ent:GetClass()

    Amalgam.SavePersistentEntity(pos, ang, class)

    self.Owner:Notify("Entity successfully persisted to data.")
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.5)
    self:DoMagic()

    local owner = self:GetOwner()
    if (not IsValid(owner)) then return end

    local tr = owner:GetEyeTrace()
    local ent = tr.Entity

    if (not IsValid(ent) or ent:IsWorld()) then return end
    if (not ent.CanPersist) then return end

    local pos = ent:GetPos()
    local ang = ent:GetAngles()
    local class = ent:GetClass()

    local removed = Amalgam.RemovePersistentEntity(pos, ang, class)

    if (removed) then
        owner:Notify("Entity removed from persistence data.")
    end
end

function SWEP:Deploy()
    if (SERVER and not self:GetOwner():HasRank("RootUser")) then
        self:GetOwner():StripWeapon(self:GetClass())
    end
end
