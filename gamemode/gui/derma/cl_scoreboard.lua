local PANEL = {}

local gradient_down = Material("vgui/gradient-d")
local gradient_right = Material("vgui/gradient-l")

local color_dark = Color(15, 15, 15, 230)
local color_orange = Color(255, 168, 0, 245)

function PANEL:Init()
    self:SetSize(ScrW() * 0.35, ScrH() * 0.6)
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    self:SetAlpha(0)
    self.FadeStart = CurTime()
    self:MakePopup()

    self.PlayerList = vgui.Create("DScrollPanel", self)
    self.PlayerList:SetSize(self:GetWide(), self:GetTall() - 50)
    self.PlayerList:SetPos(0, 50)
end

function PANEL:Paint(w, h)
    local fadeProgress = math.Clamp((CurTime() - self.FadeStart) / 0.2, 0, 1)
    local alpha = Lerp(fadeProgress, 0, 255)
    self:SetAlpha(alpha)

    Derma_DrawBackgroundBlur(self, self.FadeStart)

    local glowColor = HSVToColor((CurTime() * 50) % 360, 1, 1)
    surface.SetDrawColor(glowColor.r, glowColor.g, glowColor.b, 200)
    surface.DrawOutlinedRect(-2, -2, w + 4, h + 4, 3)

    draw.RoundedBox(8, 0, 0, w, h, color_dark)

    surface.SetDrawColor(15, 15, 15, 25)
    surface.SetMaterial(gradient_down)
    surface.DrawTexturedRect(0, 0, w, h)

    local titleColor = HSVToColor(30 + math.sin(CurTime() * 2) * 10, 1, 1)
    draw.SimpleText("Player List", "Amalgam.HudLabelSmall", w / 2, 15, titleColor, TEXT_ALIGN_CENTER)
end

local copied = 0
function PANEL:RefreshList()
    self.PlayerList:Clear()

    for i, ply in ipairs(player.GetAll()) do
        local plyPanel = self.PlayerList:Add("DButton")
        plyPanel:SetSize(self:GetWide(), 70)
        plyPanel:Dock(TOP)
        plyPanel:DockMargin(1, 0, 1, 5)
        plyPanel:SetText("")
        plyPanel.CopyAlpha = 0

        local me = (ply == LocalPlayer())
        local rank = ply.GetRank and ply:GetRank() or "User"
        function plyPanel:Paint(w, h)
            surface.SetDrawColor(30, 30, 30, 200)
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(35, 35, 35, 120)
            surface.SetMaterial(gradient_down)
            surface.DrawTexturedRect(0, 0, w, h)

            if me then
                surface.SetDrawColor(89, 89, 89, 40)
                surface.SetMaterial(gradient_right)
                surface.DrawTexturedRect(0, 0, w, h)
            end

            local pingColor = HSVToColor(30 + math.sin(CurTime() * 2) * 10, 1, 1)

            draw.SimpleText(ply:Nick(), "Amalgam.HudLabelSmall", 70, 10, color_white, TEXT_ALIGN_LEFT)
            draw.SimpleText(rank, "Amalgam.HudLabelTiny", 70, 35, color_orange, TEXT_ALIGN_LEFT)
            draw.SimpleText(ply:Ping(), "Amalgam.HudLabelTiny", w - 15, 25, pingColor, TEXT_ALIGN_RIGHT)

            if plyPanel.CopyAlpha > 0 and copied == i then
                draw.SimpleText( "SteamID copied.", "Amalgam.HudLabelTiny", w / 2, h / 2, ColorAlpha(color_white, plyPanel.CopyAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
                plyPanel.CopyAlpha = plyPanel.CopyAlpha - ( FrameTime() * 200 )
            end
        end

        plyPanel.DoClick = function()
            SetClipboardText(ply:SteamID())
            surface.PlaySound("buttons/button14.wav")
            plyPanel.CopyAlpha = 255
            copied = i
        end

        -- Avatar Image
        local Avatar = vgui.Create("AvatarImage", plyPanel)
        Avatar:SetSize(48, 48)
        Avatar:SetPos(10, 10)
        Avatar:SetPlayer(ply, 64)
    end
end

vgui.Register("AmalgamScoreboard", PANEL, "DFrame")

local scoreboard

hook.Add("ScoreboardShow", "ShowAmalgamScoreboard", function()
    if not IsValid(scoreboard) then
        scoreboard = vgui.Create("AmalgamScoreboard")
    end
    scoreboard.FadeStart = CurTime()
    scoreboard:SetVisible(true)
    scoreboard:RefreshList()
    return false
end)

hook.Add("ScoreboardHide", "HideAmalgamScoreboard", function()
    if IsValid(scoreboard) then
        scoreboard:SetVisible(false)
    end
end)
