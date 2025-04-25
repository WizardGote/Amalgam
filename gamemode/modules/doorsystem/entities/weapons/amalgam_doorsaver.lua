AddCSLuaFile()

SWEP.PrintName = "[Dev] Doors Saver"
SWEP.Author = "Ceryx"
SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = ""
SWEP.Instructions = [[
LMB: Open Doors Editor 
RMB: Wipe Door Data]]
SWEP.Category = "Amalgam"
SWEP.Spawnable = true
SWEP.AdminOnly = false
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
    local door = tr.Entity

    if (not IsValid(door)) then return end
    if (not door:IsDoorEntity()) then return end
    if (tr.HitPos:Distance(owner:GetPos()) > 200) then return end

    if (SERVER) then
        net.Start("nDoorEditor")
         net.WriteEntity(door)
        net.Send(owner)
    end
end

if (CLIENT) then
    net.Receive("nDoorEditor", function()
        local door = net.ReadEntity()
        if (not IsValid(door)) then return end

        local frame = vgui.Create("DFrame")
        frame:SetSize(350, 200)
        frame:Center()
        frame:SetTitle("")
        frame:SetDraggable(false)
        frame:ShowCloseButton(false)
        frame:MakePopup()

        local gradient = Material("vgui/gradient-d")
        frame.Paint = function(s, w, h)
            surface.SetDrawColor(255, 168, 35, 25)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
            draw.RoundedBox(8, 0, 0, w, h, Color(15, 15, 15, 220))
            surface.SetDrawColor(15, 15, 15, 25)
            surface.SetMaterial(gradient)
            surface.DrawTexturedRect(0, 0, w, h)
        end

        local label = vgui.Create("DLabel", frame)
        label:SetText("Edit Door Settings")
        label:SetFont("Amalgam.DermaLabelNormal")
        label:SetTextColor(Color(255, 255, 255))
        label:SetSize(300, 25)
        label:SetPos(20, 15)

        local title = vgui.Create("DTextEntry", frame)
        title:SetPos(20, 45)
        title:SetSize(310, 25)
        title:SetFont("Amalgam.DermaLabelNormal")
        title:SetText(door:GetNWString("DoorTitle", ""))

        local ownable = vgui.Create("DCheckBoxLabel", frame)
        ownable:SetPos(20, 80)
        ownable:SetText("Ownable")
        ownable:SetFont("Amalgam.DermaLabelNormal")
        ownable:SetTextColor(Color(255, 255, 255))
        ownable:SetValue(door:GetNWBool("DoorOwnable", false))
        ownable:SizeToContents()

        local price = vgui.Create("DTextEntry", frame)
        price:SetPos(20, 110)
        price:SetSize(200, 25)
        price:SetFont("Amalgam.DermaLabelNormal")
        price:SetNumeric(true)
        price:SetText(door:GetNWInt("DoorPrice", 0))

        local save = vgui.Create("DButton", frame)
        save:SetSize(100, 30)
        save:SetPos(230, 110)
        save:SetText("Save")
        save:SetTextColor(Color(255, 255, 255))
        save.DoClick = function()
            net.Start("nDoorSaver")
                net.WriteEntity(door)
                net.WriteBool(ownable:GetChecked())
                net.WriteInt(tonumber(price:GetText()) or 0, 32)
                net.WriteString(title:GetText())
            net.SendToServer()
            frame:Close()
        end

        save.Paint = function(s, w, h)
            local col = s:IsHovered() and Color(255, 168, 0, 180) or Color(150, 75, 25, 180)
            draw.RoundedBox(8, 0, 0, w, h, col)
        end

        local close = vgui.Create("DButton", frame)
        close:SetSize(40, 40)
        close:SetPos(frame:GetWide() - 45, 5)
        close:SetText("X")
        close:SetTextColor(Color(255, 255, 255))
        close.DoClick = function()
            frame:Close()
        end

        close.Paint = function(s, w, h)
            local col = s:IsHovered() and Color(255, 168, 0, 180) or Color(150, 75, 25, 180)
            draw.RoundedBox(8, 0, 0, w, h, col)
        end
    end)
end


function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.5)
    self:DoMagic()

    local owner = self:GetOwner()
    if (not IsValid(owner)) then return end

    local tr = owner:GetEyeTrace()
    local door = tr.Entity

    if (not IsValid(door)) then return end
    if (door:IsDoorEntity()) then return end

    local pos = door:GetPos()
    local ang = door:GetAngles()
    local class = door:GetClass()

    local removed = Amalgam.RemoveDoorFromPersistence(pos, ang, class)

    if (removed) then
        door:SetNWBool("DoorOwnable", nil)
        door:SetNWInt("DoorPrice", "")
        door:SetNWString("DoorTitle", "")
        owner:Notify("Door removed from persistence data.")
    else
        owner:Notify("Door not found in persistence data.")
    end
end

function SWEP:Deploy()
    if (SERVER and not self:GetOwner():HasRank("RootUser")) then
        self:GetOwner():StripWeapon(self:GetClass())
    end
end
