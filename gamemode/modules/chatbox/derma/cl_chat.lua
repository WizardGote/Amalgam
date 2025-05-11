local PANEL = {}

function PANEL:Init()
    self:SetSize(500, 60)
    self:SetPos(20, ScrH() - 200)

    self.PrefixLabel = vgui.Create("DLabel", self)
    self.PrefixLabel:SetFont("Amalgam.DermaLabelVeryBig")
    self.PrefixLabel:SetText("IC:")
    self.PrefixLabel:SetTextColor(Color(255, 168, 0, 255))
    self.PrefixLabel:SizeToContents()

    self.Input = vgui.Create("DTextEntry", self)
    self.Input:SetFont("Amalgam.DermaLabelNormal")
    self.Input:SetTextColor(Color(255, 255, 255))
    self.Input:SetPlaceholderText("Say something...")

    self.Input.Paint = function(pnl, w, h)
        surface.SetDrawColor(25, 25, 25, 0)
        surface.DrawRect(0, 0, w, h)
        pnl:DrawTextEntryText(Color(255, 255, 255), Color(200, 200, 200), Color(150, 150, 150))
    end

    self.Input.OnChange = function(s)
        local val = s:GetValue() or ""
        local chatPrefix = "ic"

        if (string.sub(val, 1, 2) == "//") then
            chatPrefix = "ooc"
        elseif (string.sub(val, 1, 3) == ".//") then
            chatPrefix = "looc"
        elseif (string.sub(val, 1, 1) == "/") then
            local cmd = string.match(val, "^/([^%s]+)")
            if (cmd) then
                chatPrefix = string.lower(cmd)
            end
        end

        local chatType = Amalgam.ChatTypes[chatPrefix] or Amalgam.ChatTypes["ic"]
        local labelText = (chatType and chatType.Label or "IC") .. ":"

        self.chatPrefix = chatPrefix

        self.PrefixLabel:SetText(labelText)
        self.PrefixLabel:SetTextColor(chatType.Color)
        self.PrefixLabel:SizeToContents()
        self:InvalidateLayout()
    end

    self.Input.OnEnter = function(s)
        local text = string.Trim(s:GetValue())
        if (#text > 75) then
            Amalgam.CreateNotification("Your message is too long (75 character limit)")
            return
        end

        if (text ~= "") then
            net.Start("nChatSend")
                net.WriteString(text)
            net.SendToServer()

            local formatLog = "[".. string.upper(self.chatPrefix) .."][".. LocalPlayer():Nick() .. "] " .. LocalPlayer():GetCharNickname() .. ": " .. text

            net.Start("nSendChatLog")
                net.WriteString(formatLog)
            net.SendToServer()
        end
        self:CloseChatbox()
    end

    self:SetVisible(false)
end

function PANEL:PerformLayout(w, h)
    local padding = 12

    surface.SetFont("Amalgam.DermaLabelVeryBig")
    local prefixW = surface.GetTextSize(self.PrefixLabel:GetText())

    local prefixY = (h - self.PrefixLabel:GetTall()) / 2
    self.PrefixLabel:SetPos(10, prefixY)

    local entryX = prefixW + padding + 10
    local entryW = w - entryX - 10
    local entryH = 28
    local entryY = (h - entryH) / 2

    self.Input:SetPos(entryX, entryY)
    self.Input:SetSize(entryW, entryH)
end

local gradient = Material("vgui/gradient-d")

function PANEL:Paint(w, h)
    draw.RoundedBox(2, 0, 0, w, h, Color(35, 35, 35, 200))

    surface.SetDrawColor(15, 15, 15, 100)
    surface.SetMaterial(gradient)
    surface.DrawTexturedRect(0, 0, w, h)

    surface.SetDrawColor(255, 168, 103, 150)
    surface.DrawOutlinedRect(0, 0, w, h)
end

vgui.Register("AmalgamChatBox", PANEL, "EditablePanel")

function PANEL:OpenChatbox()
    self:SetVisible(true)
    self:MakePopup()
    self.Input:RequestFocus()
    Amalgam.ChatOpen = true
    LocalPlayer():SetTyping(true)

    net.Start("nTypingStatus")
        net.WriteBool(true)
    net.SendToServer()
end

function PANEL:CloseChatbox()
    self:Remove()
    Amalgam.ChatOpen = false
    net.Start("nTypingStatus")
    	net.WriteBool(false)
    net.SendToServer()
end
