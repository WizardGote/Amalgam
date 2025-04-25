local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:SetTitle("")
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    self:MakePopup()
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

function PANEL:Paint(w, h)
    surface.SetDrawColor(0, 0, 0, 200)
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(0, 0, 0, 255)
    surface.DrawRect(0, 0, w, h * 0.1)
    surface.DrawRect(0, h * 0.9, w, h * 0.1)

    draw.SimpleText("DATABASE CONNECTION FAILED", "Amalgam.DermaLabelBig", w / 2, h / 2 - 40, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("Check your database configuration and server settings, then restart and try again.", "Amalgam.DermaLabelSmall", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

vgui.Register("AmalgamDatabaseError", PANEL, "DFrame")

local fixedViewPos = Vector(0, 0, 100)
local fixedViewAng = Angle(0, -500, 0)
g_DatabaseErrorPanel = nil

function Amalgam.ShowDatabaseErrorScreen()
    if (IsValid(g_DatabaseErrorPanel)) then return end
    g_DatabaseErrorPanel = vgui.Create("AmalgamDatabaseError")
end

function Amalgam.HideDatabaseErrorScreen()
    if (IsValid(g_DatabaseErrorPanel)) then
        g_DatabaseErrorPanel:Remove()
        g_DatabaseErrorPanel = nil
    end
end

hook.Add("CalcView", "LockCameraDatabaseError", function(ply, pos, angles, fov)
    if (IsValid(g_DatabaseErrorPanel)) then
        local view = {}
        view.origin = fixedViewPos
        view.angles = fixedViewAng
        view.fov = fov
        view.drawviewer = true
        return view
    end
end)