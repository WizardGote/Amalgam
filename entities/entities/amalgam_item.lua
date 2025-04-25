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
    self:NetworkVar("String", 0, "ItemID")
end

function ENT:Initialize()
    if (CLIENT) then return end
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if (IsValid(phys)) then
        phys:Wake()
    end

    self.NextUse = 0
end

function ENT:SetItemData(itemID)
    self:SetItemID(itemID)
    local item = Amalgam.Items[itemID]

    if (item) then
        self:SetModel(item.Model)
        self:SetNWString("ItemID", itemID)
    end
end

function ENT:Use(ply, caller)
    if (CurTime() < self.NextUse) then return end
    self.NextUse = CurTime() + 0.2

    if (IsValid(ply) and ply:IsPlayer()) then
        local itemID = self:GetItemID()

        if (not ply:CanPickupItem(itemID)) then
            ply:Notify("You can't carry that. You're overburdened.")
            return
        end

        ply:TakeItem(itemID, 1)
        ply:EmitSound("npc/zombie/foot_slide1.wav", 75, 100)

        self:Remove()
    end
end

function ENT:DisplayHUDInfo(tbl)
    local itemID = self:GetItemID()
    local item = Amalgam.Items[itemID]
    if not item then return end

    tbl.lines = {
        {
            text = item.Name or "Unknown Item",
            font = "DermaLarge",
            color = Color(255, 200, 100)
        },
        {
            text = item.Description or "No description.",
            font = "DermaDefaultBold",
            color = Color(200, 200, 200)
        }
    }

    tbl.offset = Vector(0, 0, 0)
end