local PANEL = {}


function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:SetTitle("")
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    self:SetAlpha(0)
    self:MakePopup()
    self:SetKeyboardInputEnabled(true)
    gui.EnableScreenClicker(true)
    self:SetMouseInputEnabled(true)

    self.AnimatingIn = true
    self.AnimatingOut = false
    self.StartTime = CurTime()

    local barHeight = ScrH() * 0.20

    self.Title = vgui.Create("DLabel", self)
    self.Title:SetFont("Amalgam.DermaLabelTitle")
    self.Title:SetText("")
    self.Title:SetSize(ScrW(), barHeight)
    self.Title:SetContentAlignment(5)
    self.Title:SetPos(0, 0)

    self.Title.Paint = function(_, w, h)
        local text1 = "My "
        local text2 = " codex"
        local font = "Amalgam.DermaLabelTitle"

        surface.SetFont(font)

        local padding = 80
        local y = h / 2 - 10
        local text1Width, text1Height = surface.GetTextSize(text1)
        local text2Width = surface.GetTextSize(text2)

        surface.SetTextColor(Color(255, 165, 0))
        surface.SetTextPos(padding, y)
        surface.DrawText(text1)

        surface.SetTextColor(Color(255, 255, 255))
        surface.SetTextPos(padding + text1Width, y)
        surface.DrawText(text2)
    end

    self.CloseButton = vgui.Create("DButton", self)
    self.CloseButton:SetFont("Amalgam.DermaLabelHuge")
    self.CloseButton:SetTextColor(Color(235, 235, 235))
    self.CloseButton:SetText("Close")
    self.CloseButton.DoClick = function()
        surface.PlaySound("amalgam/button.mp3")
        self:Close()
    end
end

function PANEL:PerformLayout(w, h)
    local buttonWidth, buttonHeight =  math.Clamp(w * 0.1, 80, 150), math.Clamp(h * 0.1, 30, 60)
    self.CloseButton:SetSize(buttonWidth, buttonHeight)
    self.CloseButton:SetPos(w - buttonWidth - 25 * 4, h - buttonHeight - 25 * 4)
end

function PANEL:Think()
    local animTime = 0.4
    local progress = math.Clamp((CurTime() - self.StartTime) / animTime, 0, 1)

    if (self.AnimatingIn) then
        self:SetAlpha(math.sin(progress * math.pi * 0.5) * 255)
        if (progress >= 1) then self.AnimatingIn = false end
    elseif (self.AnimatingOut) then
        self:SetAlpha((1 - math.sin(progress * math.pi * 0.5)) * 255)
        if (progress >= 1) then self:Remove() end
    end
end

function PANEL:Close()
    self.AnimatingOut = true
    self.AnimatingIn = false
    self.StartTime = CurTime()

    gui.EnableScreenClicker(false)
end


function PANEL:Paint(w, h)
    Derma_DrawBackgroundBlur(self, self.StartTime)
    surface.SetDrawColor(0, 0, 0, 200)
    surface.DrawRect(0, 0, w, h)

    local barHeight = h * 0.07
    local gradient = Material("vgui/gradient-d")

    surface.SetDrawColor(225, 225, 225, 100)
    surface.DrawRect(0, 0, w, barHeight)
    surface.SetDrawColor(215, 215, 215, 150)
    surface.SetMaterial(gradient)
    surface.DrawTexturedRect(0, 0, w, barHeight)

    surface.SetDrawColor(225, 225, 225, 100)
    surface.DrawRect(0, h - barHeight, w, barHeight)
    surface.SetDrawColor(215, 215, 215, 150)
    surface.DrawTexturedRect(0, h - barHeight, w, barHeight)
end

vgui.Register("AmalgamPlayerMenu", PANEL, "DFrame")
