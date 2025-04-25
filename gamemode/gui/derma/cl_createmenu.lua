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
    self.ModelAnim = "pose_standing_02"

    self.CurrentModelIndex = 1
    self.SelectedModel = Amalgam.DefaultModels[self.CurrentModelIndex]

    local barHeight = ScrH() * 0.20
    local modelHeight = ScrH() * 0.86
    local modelWidth = modelHeight * 0.5

    self.ModelPanel = vgui.Create("DModelPanel", self)
    self.ModelPanel:SetSize(modelWidth, modelHeight)
    self.ModelPanel:SetPos(120, barHeight + (ScrH() - barHeight * 0.7 - modelHeight) / 2)
    self.ModelPanel:SetModel(self.SelectedModel)

    function self.ModelPanel:LayoutEntity(ent)
        local parent = self:GetParent()
        local anim = (parent and parent.ModelAnim) or "idle"
        local seq = ent:LookupSequence(anim)
        if (seq > 0) then ent:SetSequence(seq) end
        ent:SetAngles(Angle(0, 0, 0))
    end

    local ent = self.ModelPanel.Entity
    if (IsValid(ent)) then
        local min, max = ent:GetRenderBounds()
        self.ModelPanel:SetCamPos(Vector(100, 0, 60))
        self.ModelPanel:SetLookAt(Vector(0, 0, 40))
        self.ModelPanel:SetFOV(20)
    end

    self.Title = vgui.Create("DLabel", self)
    self.Title:SetFont("Amalgam.DermaLabelTitle")
    self.Title:SetText("")
    self.Title:SetSize(ScrW(), barHeight)
    self.Title:SetContentAlignment(5)
    self.Title:SetPos(0, 0)

    self.Title.Paint = function(_, w, h)
        local text1 = "Create"
        local text2 = " Your Identity"
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

    self.NameLabel = vgui.Create("DLabel", self)
    self.NameLabel:SetFont("Amalgam.DermaLabelVeryBig")
    self.NameLabel:SetText("")
    self.NameLabel:SetSize(ScrW(), barHeight)
    self.NameLabel:SetTextColor(Color(255, 168, 0))
    self.NameLabel:SetContentAlignment(5)

    self.NameLabel.Paint = function(_, w, h)
        local text1 = "What"
        local text2 = " do they call you?"
        local font = "Amalgam.DermaLabelVeryBig"

        surface.SetFont(font)

        local text1Width, text1Height = surface.GetTextSize(text1)
        local text2Width, text2Height = surface.GetTextSize(text2)

        local totalWidth = text1Width + text2Width
        local startX = (w - totalWidth) / 2
        local y = h / 2 - text1Height / 2

        surface.SetTextColor(Color(255, 165, 0))
        surface.SetTextPos(startX, y)
        surface.DrawText(text1)

        surface.SetTextColor(Color(255, 255, 255))
        surface.SetTextPos(startX + text1Width, y)
        surface.DrawText(text2)
    end

    self.NameInput = vgui.Create("DTextEntry", self)
    self.NameInput:SetFont("Amalgam.DermaLabelBig")
    self.NameInput:SetText("")
    self.NameInput:SetUpdateOnType(true)
    self.NameInput:SetAllowNonAsciiCharacters(false)

    self.BioLabel = vgui.Create("DLabel", self)
    self.BioLabel:SetFont("Amalgam.DermaLabelVeryBig")
    self.BioLabel:SetText("")
    self.BioLabel:SetTextColor(Color(255, 168, 0))
    self.BioLabel:SetContentAlignment(5)

    self.BioLabel.Paint = function(_, w, h)
        local text1 = "Who"
        local text2 = " are you beyond a name?"
        local font = "Amalgam.DermaLabelVeryBig"

        surface.SetFont(font)

        local text1Width, text1Height = surface.GetTextSize(text1)
        local text2Width, text2Height = surface.GetTextSize(text2)

        local totalWidth = text1Width + text2Width
        local startX = (w - totalWidth) / 2
        local y = h / 2 - text1Height / 2

        surface.SetTextColor(Color(255, 165, 0))
        surface.SetTextPos(startX, y)
        surface.DrawText(text1)

        surface.SetTextColor(Color(255, 255, 255))
        surface.SetTextPos(startX + text1Width, y)
        surface.DrawText(text2)
    end

    self.BioInput = vgui.Create("DTextEntry", self)
    self.BioInput:SetFont("Amalgam.DermaLabelBig")
    self.BioInput:SetText("")
    self.BioInput:SetUpdateOnType(true)
    self.BioInput:SetAllowNonAsciiCharacters(true)
    self.BioInput:SetMultiline(true)

    self.ZodiacDropdown = vgui.Create("DComboBox", self)
    self.ZodiacDropdown:SetFont("Amalgam.DermaLabelNormal")
    self.ZodiacDropdown:SetValue("Select Your Zodiac")
    self.ZodiacDropdown:SetTextColor(Color(35, 35, 35))
    self.ZodiacDropdown:SetSize(200, 30)

    for name, data in pairs(Amalgam.Zodiacs) do
        local getZodiac = "(" .. data.Symbol .. ") " .. name
        self.ZodiacDropdown:AddChoice(getZodiac, name)
    end

    self.ZodiacDropdown.Paint = function(panel, w, h)
        local bgColor = Color(225, 225, 225, 100)
        local gradientColor = Color(215, 215, 215, 150)
        
        draw.RoundedBox(6, 0, 0, w, h, bgColor)

        local gradient = surface.GetTextureID("vgui/gradient-u")
        surface.SetDrawColor(gradientColor)
        surface.SetTexture(gradient)
        surface.DrawTexturedRect(0, 0, w, h)
    end

    self.ZodiacDropdown.DropButton.Paint = function(panel, w, h)
        draw.SimpleText("▼", "Amalgam.DermaLabelNormal", w / 2, h / 2, Color(35, 35, 35, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    self.ErrorLabel = vgui.Create("DLabel", self)
    self.ErrorLabel:SetFont("Amalgam.DermaLabelBig")
    self.ErrorLabel:SetText("")
    self.ErrorLabel:SetTextColor(Color(255, 100, 100))
    self.ErrorLabel:SetContentAlignment(5)

    local buttonSize = 50

    self.LeftButton = vgui.Create("DButton", self)
    self.LeftButton:SetFont("Amalgam.DermaLabelTitle")
    self.LeftButton:SetTextColor(Color(235, 235, 235))
    self.LeftButton:SetText("<")
    self.LeftButton:SetSize(buttonSize, buttonSize)
    self.LeftButton.DoClick = function()
        if #Amalgam.DefaultModels <= 1 then return end
        self.CurrentModelIndex = (self.CurrentModelIndex - 2) % #Amalgam.DefaultModels + 1
        self.SelectedModel = Amalgam.DefaultModels[self.CurrentModelIndex]
        self.ModelPanel:SetModel(self.SelectedModel)
        surface.PlaySound("amalgam/button.mp3")
    end

    self.RightButton = vgui.Create("DButton", self)
    self.RightButton:SetFont("Amalgam.DermaLabelTitle")
    self.RightButton:SetTextColor(Color(235, 235, 235))
    self.RightButton:SetText(">")
    self.RightButton:SetSize(buttonSize, buttonSize)
    self.RightButton.DoClick = function()
        if #Amalgam.DefaultModels <= 1 then return end
        self.CurrentModelIndex = self.CurrentModelIndex % #Amalgam.DefaultModels + 1
        self.SelectedModel = Amalgam.DefaultModels[self.CurrentModelIndex]
        self.ModelPanel:SetModel(self.SelectedModel)
        surface.PlaySound("amalgam/button.mp3")
    end

    self.CloseButton = vgui.Create("DButton", self)
    self.CloseButton:SetFont("Amalgam.DermaLabelHuge")
    self.CloseButton:SetTextColor(Color(235, 235, 235))
    self.CloseButton:SetText("Finish")
    self.CloseButton.DoClick = function()
        local name = self.NameInput:GetValue():Trim()
        local bio = self.BioInput:GetValue()
        local model = self.SelectedModel
        local zodiacID = self.ZodiacDropdown:GetSelectedID()
        local zodiac = self.ZodiacDropdown:GetOptionData(zodiacID)

        if (#name == 0 or #bio == 0) then
            self.ErrorLabel:SetText("Define your character!")
            return
        elseif (#name < 3 or #name > 20) then
            self.ErrorLabel:SetText("Name must be 3–20 characters long!")
            return
        elseif (not string.match(name, "^[%a%s%-']+$")) then
            self.ErrorLabel:SetText("Invalid characters in name!")
            return
        elseif (not zodiacID) then
            self.ErrorLabel:SetText("You must choose your zodiac!")
            return
        end

        net.Start("nPlayerRegistered")
            net.WriteString(name)
            net.WriteString(bio)
            net.WriteString(model)
            net.WriteString(zodiac)
        net.SendToServer()
        surface.PlaySound("amalgam/button.mp3")
        self:Close()
    end
end

function PANEL:PerformLayout(w, h)
    local inputWidth = math.Clamp(w * 0.4, 300, 600) * 1.2
    local inputHeight = h * 0.04
    local bioHeight = h * 0.15
    local labelHeight = h * 0.05
    local padding = 20

    local startX = (w / 2) - (inputWidth / 2) + 150
    local currentY = h * 0.30

    self.NameLabel:SetSize(inputWidth, labelHeight)
    self.NameLabel:SetPos(startX, currentY)

    currentY = currentY + labelHeight + padding
    self.NameInput:SetSize(inputWidth, inputHeight)
    self.NameInput:SetPos(startX, currentY)

    currentY = currentY + inputHeight + padding
    self.BioLabel:SetSize(inputWidth, labelHeight)
    self.BioLabel:SetPos(startX, currentY)

    currentY = currentY + labelHeight + padding
    self.BioInput:SetSize(inputWidth, bioHeight)
    self.BioInput:SetPos(startX, currentY)

    currentY = currentY + bioHeight + padding
    self.ZodiacDropdown:SetSize(inputWidth, inputHeight)
    self.ZodiacDropdown:SetPos(startX, currentY)

    currentY = currentY + inputHeight + (padding / 2)
    self.ErrorLabel:SetSize(inputWidth, labelHeight)
    self.ErrorLabel:SetPos(startX, currentY)

    local buttonWidth, buttonHeight =  math.Clamp(w * 0.1, 80, 150), math.Clamp(h * 0.1, 30, 60)
    self.CloseButton:SetSize(buttonWidth, buttonHeight)
    self.CloseButton:SetPos(w - buttonWidth - 25 * 4, h - buttonHeight - 25 * 4)

    local arrowY = self.ModelPanel:GetY() + (self.ModelPanel:GetTall() * 0.5) - 25
    self.LeftButton:SetPos(self.ModelPanel:GetX() - 10, arrowY)
    self.RightButton:SetPos(self.ModelPanel:GetX() + self.ModelPanel:GetWide() - 60, arrowY)
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

vgui.Register("AmalgamInfoMenu", PANEL, "DFrame")

net.Receive("nCharacterCreation", function()
    vgui.Create("AmalgamInfoMenu")
end)
