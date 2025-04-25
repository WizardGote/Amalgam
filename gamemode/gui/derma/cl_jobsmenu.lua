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

    local placeholderJob = Amalgam.Jobs["Job_None"]

    self.CurrentModelIndex = 1
    self.SelectedModel = LocalPlayer():GetModel()

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

    local modelX, modelW = 120, self.ModelPanel:GetWide()
    local infoX = modelX + modelW + 40
    local infoY = self.ModelPanel:GetY()
    local infoW = 350

    self.Title = vgui.Create("DLabel", self)
    self.Title:SetFont("Amalgam.DermaLabelTitle")
    self.Title:SetText("")
    self.Title:SetSize(ScrW(), barHeight)
    self.Title:SetContentAlignment(5)
    self.Title:SetPos(0, 0)

    self.Title.Paint = function(_, w, h)
        local text1 = "Choose"
        local text2 = " Your Duty"
        local font = "Amalgam.DermaLabelTitle"

        surface.SetFont(font)

        local padding = 80
        local y = h / 2 - 10
        local text1Width = surface.GetTextSize(text1)
        surface.SetTextColor(Color(255, 165, 0))
        surface.SetTextPos(padding, y)
        surface.DrawText(text1)

        surface.SetTextColor(Color(255, 255, 255))
        surface.SetTextPos(padding + text1Width, y)
        surface.DrawText(text2)
    end

    self.JobNameLabel = vgui.Create("DLabel", self)
    self.JobNameLabel:SetFont("Amalgam.DermaLabelVeryBig")
    self.JobNameLabel:SetText(placeholderJob.Name)
    self.JobNameLabel:SetTextColor(Color(255, 168, 0))
    self.JobNameLabel:SetContentAlignment(4)

    self.JobDescriptionLabel = vgui.Create("DLabel", self)
    self.JobDescriptionLabel:SetFont("Amalgam.DermaLabelNormal")
    self.JobDescriptionLabel:SetText(placeholderJob.Description)
    self.JobDescriptionLabel:SetTextColor(Color(245, 245, 245))
    self.JobDescriptionLabel:SetWrap(true)
    self.JobDescriptionLabel:SetAutoStretchVertical(true)

    self.RightSidePanel = vgui.Create("DPanel", self)
    self.RightSidePanel.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 25, 240))
        surface.SetDrawColor(255, 168, 35, 40)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    self.JobGrid = vgui.Create("DIconLayout", self.RightSidePanel)
    self.JobGrid:SetSpaceX(10)
    self.JobGrid:SetSpaceY(10)

    local selectedJob = "Job_None"

    for _, job in pairs(Amalgam.Jobs) do
        local model = (type(job.Model) == "table") and job.Model[1] or job.Model
        if not model or model == "" then continue end

        local button = self.JobGrid:Add("DButton")
        button:SetSize(90, 130)
        button:SetText("")
        button.Paint = function(s, w, h)
            draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and Color(255, 168, 35, 15) or Color(25, 25, 25, 240))
            surface.SetDrawColor(255, 168, 35, 50)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        local modelPanel = vgui.Create("DModelPanel", button)
        modelPanel:SetSize(90, 90)
        modelPanel:SetModel(model)
        modelPanel:SetFOV(24)
        modelPanel:SetCamPos(Vector(35, 0, 62))
        modelPanel:SetLookAt(Vector(0, 0, 62))
        modelPanel:SetMouseInputEnabled(false)
        modelPanel:SetKeyboardInputEnabled(false)
        modelPanel.LayoutEntity = function() end

        local nameLabel = vgui.Create("DLabel", button)
        nameLabel:SetText(job.Name)
        nameLabel:SetFont("Amalgam.DermaLabelSmall")
        nameLabel:SetTextColor(Color(255, 255, 255))
        nameLabel:SetContentAlignment(5)
        nameLabel:SetSize(90, 30)
        nameLabel:SetPos(0, 100)

        button.DoClick = function()
            surface.PlaySound("amalgam/button.mp3")

            self.SelectedModel = model
            self.ModelPanel:SetModel(model)
            self.JobNameLabel:SetText(job.Name or "Unknown")
            self.JobDescriptionLabel:SetText(job.Description or "No description.")
            selectedJob = job.UniqueID
        end
    end

    self.ChooseButton = vgui.Create("DButton", self)
    self.ChooseButton:SetFont("Amalgam.DermaLabelHuge")
    self.ChooseButton:SetTextColor(Color(235, 235, 235))
    self.ChooseButton:SetText("Apply")
    self.ChooseButton.DoClick = function()
        net.Start("nChooseJob")
            net.WriteString(selectedJob)
        net.SendToServer()
        surface.PlaySound("amalgam/button.mp3")
        self:Close()
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
    local padding = 40
    local barHeight = h * 0.2
    local modelHeight = h * 0.86
    local modelWidth = modelHeight * 0.5
    local modelX = padding
    local modelY = barHeight + (h - barHeight * 0.7 - modelHeight) / 2

    self.ModelPanel:SetSize(modelWidth, modelHeight)
    self.ModelPanel:SetPos(modelX, modelY)

    local infoX = modelX + modelWidth + padding
    local infoW = 350

    self.JobNameLabel:SetSize(infoW, 40)
    self.JobNameLabel:SetPos(infoX, modelY)

    self.JobDescriptionLabel:SetSize(infoW, 60)
    self.JobDescriptionLabel:SetPos(infoX, modelY + 50)

    self.RightSidePanel:SetSize(800, 700)
    self.RightSidePanel:SetPos(infoX + infoW + padding, modelY - 25)

    self.JobGrid:SetSize(self.RightSidePanel:GetWide() - 20, self.RightSidePanel:GetTall() - 20)
    self.JobGrid:SetPos(10, 10)

    -- Title bar
    self.Title:SetSize(w, barHeight)

    -- Buttons placement
    local buttonWidth, buttonHeight = math.Clamp(w * 0.1, 80, 150), math.Clamp(h * 0.1, 30, 60)
    local buttonY = self.RightSidePanel:GetY() + self.RightSidePanel:GetTall() + 10

    self.ChooseButton:SetSize(buttonWidth, buttonHeight)
    self.ChooseButton:SetPos(self.RightSidePanel:GetX(), buttonY)

    self.CloseButton:SetSize(buttonWidth, buttonHeight)
    self.CloseButton:SetPos(self.RightSidePanel:GetX() + self.RightSidePanel:GetWide() - buttonWidth, buttonY)
end


function PANEL:Think()
    local animTime = 0.4
    local progress = math.Clamp((CurTime() - self.StartTime) / animTime, 0, 1)

    if self.AnimatingIn then
        self:SetAlpha(math.sin(progress * math.pi * 0.5) * 255)
        if progress >= 1 then self.AnimatingIn = false end
    elseif self.AnimatingOut then
        self:SetAlpha((1 - math.sin(progress * math.pi * 0.5)) * 255)
        if progress >= 1 then self:Remove() end
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
    surface.SetMaterial(gradient)
    surface.DrawTexturedRect(0, h - barHeight, w, barHeight)
end

vgui.Register("AmalgamJobsMenu", PANEL, "DFrame")