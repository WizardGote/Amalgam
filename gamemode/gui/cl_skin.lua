local SKIN = {}
derma.DefineSkin("AmalgamSkin", "Custom Amalgam Derma Skin", SKIN)

local defaultGradient = Material("vgui/gradient-u")

SKIN.DefaultFont = "Amalgam.DermaLabelNormal"
SKIN.PanelBackgroundColor = Color(235, 235, 235, 200)
SKIN.GradientColor = Color(200, 200, 200, 80)

SKIN.LabelTextColor = Color(15, 15, 15, 255)

SKIN.MenuBackgroundColor = Color(235, 235, 235, 255)
SKIN.MenuBorderColor = Color(180, 180, 180, 255)
SKIN.MenuHoverColor = Color(255, 168, 0, 255)

SKIN.MenuOptionColors = {
    Color(220, 220, 220, 255),
    Color(200, 200, 200, 255)
}

SKIN.ScrollbarBG = Color(235, 235, 235, 255)
SKIN.ScrollbarGrip = Color(255, 168, 0, 255)
SKIN.ScrollbarHover = Color(255, 168, 53, 255)

SKIN.SliderBarColor = Color(180, 180, 180, 255)
SKIN.SliderKnobColor = Color(255, 128, 0, 255)

SKIN.TextEntryBG = Color(245, 245, 245, 80)
SKIN.TextEntryBorder = Color(180, 180, 180, 200)
SKIN.TextEntryFocused = Color(255, 168, 0, 255)

SKIN.ButtonColorNormal     = Color(0, 0, 0, 0)
SKIN.ButtonColorHovered    = Color(255, 168, 0, 255)
SKIN.TextColor             = Color(235, 235, 235, 255)

function SKIN:PaintLabel(panel, w, h)
    panel:SetTextColor(self.LabelTextColor)
end

function SKIN:PaintButton(panel, w, h)
    panel:SetContentAlignment(5)
    panel:SetTextColor(Color(0, 0, 0, 0))

    surface.SetDrawColor(0, 0, 0, 0)
    surface.DrawRect(0, 0, w, h)

    local textColor = panel:IsHovered() and self.ButtonColorHovered or self.TextColor

    draw.SimpleText(panel:GetText(), panel:GetFont() or self.DefaultFont, w / 2, h / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function SKIN:PaintMenu(panel, w, h)
    draw.RoundedBox(6, 0, 0, w, h, self.TextEntryBG)

    local gradient = surface.GetTextureID("vgui/gradient-u")
    surface.SetDrawColor(Color(215, 215, 215, 150))
    surface.SetTexture(gradient)
    surface.DrawTexturedRect(0, 0, w, h)
end

function SKIN:PaintScrollBarGrip(panel, w, h)
    local color = panel:IsHovered() and self.ScrollbarHover or self.ScrollbarGrip
    surface.SetDrawColor(color)
    surface.DrawRect(0, 0, w, h)
end

function SKIN:PaintScrollBar(panel, w, h)
    surface.SetDrawColor(self.ScrollbarBG)
    surface.DrawRect(0, 0, w, h)
end

function SKIN:PaintNumSlider(panel, w, h)
    surface.SetDrawColor(self.SliderBarColor)
    surface.DrawRect(0, h / 2 - 2, w, 4)
end

function SKIN:PaintSliderKnob(panel, w, h)
    surface.SetDrawColor(self.SliderKnobColor)
    surface.DrawRect(0, 0, w, h)
end

function SKIN:PaintMenuOption(panel, w, h)

    panel:SetFont(self.DefaultFont)

    draw.RoundedBox(6, 0, 0, w, h, self.TextEntryBG)

    surface.SetDrawColor(Color(215, 215, 215, 150))
    surface.SetMaterial(defaultGradient)
    surface.DrawTexturedRect(0, 0, w, h)

end

function SKIN:PaintTextEntry(panel, w, h)
    local borderColor = panel:IsEditing() and self.TextEntryFocused or self.TextEntryBorder

    surface.SetDrawColor(self.TextEntryBG)
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(215, 215, 215, 150)
    surface.SetMaterial(defaultGradient)
    surface.DrawTexturedRect(0, 0, w, h)

    surface.SetDrawColor(borderColor)
    surface.DrawOutlinedRect(0, 0, w, h, 1)

    panel:DrawTextEntryText(Color(35, 35, 35, 255), Color(255, 128, 0, 255), Color(35, 35, 35, 255))
end
