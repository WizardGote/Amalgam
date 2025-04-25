net.Receive("nDatabaseStatus", function()
    local connected = net.ReadBool()
    timer.Simple(1, function()
        if (connected) then
            Amalgam.HideDatabaseErrorScreen()
        else
            Amalgam.ShowDatabaseErrorScreen()
        end
    end)
end)

function GM:PlayerBindPress(ply, bind, pressed)
    if (not IsValid(ply)) then return end
    if (not pressed) then return end

    if (pressed and string.find(bind, "gm_showspare2")) then
        if (IsValid(Amalgam.Terminal)) then Amalgam.Terminal:Remove() end
        Amalgam.Terminal = vgui.Create("AmalgamTerminal")
        return true
    end

    if (pressed and string.find(bind, "gm_showhelp")) then
        Amalgam.JobsMenu = vgui.Create("AmalgamJobsMenu")
        return true
    end

    if (pressed and bind == "+menu") then
        local wep = ply:GetActiveWeapon()
        if (IsValid(wep)) then
            local class = wep:GetClass()
            if (class == "weapon_physgun" or class == "gmod_tool" or class == "amalgam_entsaver" or class == "amalgam_doorsaver") then
                return false
            end
        end

        if (IsValid(Amalgam.Inventory)) then
            Amalgam.Inventory:Remove()
        end

        Amalgam.Inventory = vgui.Create("AmalgamInventoryMenu")
        Amalgam.Inventory:OpenInventory()
        return true
    end
end

local cachedShootPos, viewEntity

function GM:DrawEntities()
    local ply = LocalPlayer()
    if (not IsValid(ply)) then return end
    if (not ply:GetNWBool("FullyLoaded", false)) then return end

    viewEntity = ply:GetViewEntity()
    cachedShootPos = (IsValid(viewEntity) and viewEntity.GetShootPos) and viewEntity:GetShootPos() or ply:EyePos()

    local function GetDistanceAlpha(pos)
        local distSqr = cachedShootPos:DistToSqr(pos)
        if (distSqr > 500 * 500) then return nil end
        return (distSqr > 150 * 150) and 255 * (1 - math.Clamp((math.sqrt(distSqr) - 150) / 350, 0, 1)) or 255
    end

    for _, target in ipairs(player.GetAll()) do
        if (not IsValid(target) or not target:Alive() or target:IsDormant() or target:GetNoDraw() or target == ply) then continue end

        local alpha = GetDistanceAlpha(target:GetShootPos())
        if (not alpha) then continue end

        local jobName = target:GetJobName() or "Unemployed"
        local pos = (target:EyePos() + Vector(0, 0, 10)):ToScreen()
        local name = target:GetCharNickname()
        local zodiac = (Amalgam.Zodiacs[target:GetZodiac() or ""] or {}).Symbol or "☼"
        local plyArgs = "(" .. zodiac .. ")" .. name

        draw.SimpleTextOutlined(jobName, "Trebuchet24", pos.x, pos.y - 55, Color(225, 168, 0, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))
        draw.SimpleTextOutlined(plyArgs, "Trebuchet24", pos.x, pos.y - 40, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))
        if (target:IsTyping()) then draw.SimpleTextOutlined("Typing...", "Trebuchet24", pos.x, pos.y - 15, Color(200, 200, 200, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha)) end
    end

    local focused = LocalPlayer():GetEyeTrace().Entity
    for _, ent in ipairs(ents.FindByClass("amalgam_item")) do
        if (not IsValid(ent) or ent == focused) then continue end

        local alpha = GetDistanceAlpha(ent:GetPos() + Vector(0, 0, 10))
        if (not alpha) then continue end

        local screen = (ent:GetPos() + Vector(0, 0, 10)):ToScreen()
        draw.SimpleTextOutlined(Amalgam.Items[ent:GetItemID()].Name or "Unknown", "Trebuchet24", screen.x, screen.y, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))
    end

    for _, ent in ipairs(ents.FindByClass("amalgam_money")) do
        if (not IsValid(ent) or ent == focused) then continue end

        local alpha = GetDistanceAlpha(ent:GetPos() + Vector(0, 0, 10))
        if (not alpha) then continue end

        local screen = (ent:GetPos() + Vector(0, 0, 10)):ToScreen()
        draw.SimpleTextOutlined(ent:GetAmount() .. "$" or 0, "Trebuchet24", screen.x, screen.y, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))
    end
end

GM.DisplayEntities = GM.DisplayEntities or {}

function GM:QueueDisplayHUD(ent)
    if (not IsValid(ent) or not ent.Display or not ent.DisplayHUDInfo) then return end

    local id = ent:EntIndex()
    local entry = self.DisplayEntities[id] or { ent = ent, alpha = 0 }

    entry.alpha = Lerp(FrameTime() * 5, entry.alpha, 255)

    local data = {}
    ent:DisplayHUDInfo(data)

    if istable(data.lines) then
        entry.lines = data.lines
        entry.offset = data.offset or vector_origin
        self.DisplayEntities[id] = entry
    end
end

function GM:DrawDisplayHUD()
    local ply, trace = LocalPlayer(), LocalPlayer():GetEyeTrace()
    local focused = trace.Entity

    if (IsValid(focused) and focused.Display and trace.HitPos:DistToSqr(ply:GetPos()) <= 10000) then
        self:QueueDisplayHUD(focused)
    end

    for id, data in pairs(self.DisplayEntities) do
        local ent = data.ent
        if (not IsValid(ent)) then self.DisplayEntities[id] = nil continue end

        data.alpha = (ent == focused) and Lerp(FrameTime() * 5, data.alpha, 255) or Lerp(FrameTime() * 5, data.alpha, 0)
        if (data.alpha <= 1) then self.DisplayEntities[id] = nil continue end

        local pos = (ent:GetPos() + data.offset):ToScreen()
        local alpha = math.Clamp(data.alpha, 0, 255)
        local y = 0

        for _, line in ipairs(data.lines or {}) do
            local c = line.color or color_white
            draw.SimpleTextOutlined(line.text or "", line.font or "DermaDefault", pos.x, pos.y - 20 + y, Color(c.r, c.g, c.b, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))
            y = y + draw.GetFontHeight(line.font or "DermaDefault") + 4
        end
    end
end

function GM:HUDPaint()
    self:DrawEntities()
    self:DrawDisplayHUD()
end