local PANEL = {}

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

    draw.RoundedBox(8, 0, 0, w, h, Color(15, 15, 15, 230))

    local gradient = Material("vgui/gradient-d")
    surface.SetDrawColor(15, 15, 15, 25)
    surface.SetMaterial(gradient)
    surface.DrawTexturedRect(0, 0, w, h)

    local titleColor = HSVToColor(30 + math.sin(CurTime() * 2) * 10, 1, 1)
    draw.SimpleText("Player List", "Amalgam.HudLabelSmall", w / 2, 15, titleColor, TEXT_ALIGN_CENTER)
end

function PANEL:RefreshList()
    self.PlayerList:Clear()

    for _, ply in ipairs(player.GetAll()) do
        local plyPanel = self.PlayerList:Add("DButton")
        plyPanel:SetSize(self:GetWide(), 70)
        plyPanel:Dock(TOP)
        plyPanel:DockMargin(0, 0, 0, 5)
        plyPanel:SetText("")

        function plyPanel:Paint(w, h)
            surface.SetDrawColor(30, 30, 30, 200)
            surface.DrawRect(0, 0, w, h)

            local gradient = Material("vgui/gradient-d")
            surface.SetDrawColor(35, 35, 35, 120)
            surface.SetMaterial(gradient)
            surface.DrawTexturedRect(0, 0, w, h)

            local rank = ply.GetRank and ply:GetRank() or "User"
            local pingColor = HSVToColor(30 + math.sin(CurTime() * 2) * 10, 1, 1)

            draw.SimpleText(ply:Nick(), "Amalgam.HudLabelSmall", 70, 10, Color(255, 255, 255), TEXT_ALIGN_LEFT)
            draw.SimpleText(rank, "Amalgam.HudLabelTiny", 70, 35, Color(255, 168, 0, 245), TEXT_ALIGN_LEFT)
            draw.SimpleText(ply:Ping(), "Amalgam.HudLabelTiny", w - 15, 25, pingColor, TEXT_ALIGN_RIGHT)
        end

        plyPanel.DoClick = function()
            SetClipboardText(ply:SteamID())
            surface.PlaySound("buttons/button14.wav")
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
