local PANEL = {}

function PANEL:Init()
    self:SetSize(900, 500)
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    self:MakePopup()

    surface.PlaySound("amalgam/open_terminal.ogg")

    self.TopBar = vgui.Create("DPanel", self)
    self.TopBar:SetPos(0, 0)
    self.TopBar:SetSize(900, 30)
    self.TopBar.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(30, 30, 30))
        draw.SimpleText("A-Shell", "DermaDefaultBold", 10, h / 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    self.CloseButton = vgui.Create("DButton", self.TopBar)
    self.CloseButton:SetSize(20, 20)
    self.CloseButton:SetPos(870, 5)
    self.CloseButton:SetText("")
    self.CloseButton.Paint = function(_, w, h)
        draw.RoundedBox(10, 0, 0, w, h, Color(220, 50, 50))
    end
    self.CloseButton.DoClick = function()
        self:Remove()
    end

    self.History = vgui.Create("RichText", self)
    self.History:SetPos(5, 35)
    self.History:SetSize(890, 410)
    self.History:SetVerticalScrollbarEnabled(true)

    self.History.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(15, 15, 15))
    end

    timer.Simple(0, function()
        if (IsValid(self.History)) then
            self.History:InsertColorChange(255, 165, 0, 255)
            self.History:AppendText("Amalgam@ Type $help, $help_dev for a list of commands")
        end
    end)

    if (not LocalPlayer().InputHistory) then
        LocalPlayer().InputHistory = {}
    end
    self.InputHistory = LocalPlayer().InputHistory
    self.HistoryIndex = 0

    self.Input = vgui.Create("DTextEntry", self)
    self.Input:SetPos(5, 450)
    self.Input:SetSize(890, 35)
    self.Input:SetFont("DermaDefaultBold")
    self.Input:SetTextColor(Color(255, 165, 0))
    self.Input:SetPaintBorderEnabled(true)
    self.Input:SetCursorColor(Color(255, 165, 0))

    self.Input.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(55, 55, 55))
        s:DrawTextEntryText(Color(255, 165, 0), Color(255, 255, 255), Color(255, 165, 0))
    end

    self.Input.OnEnter = function(inputField)
        local text = inputField:GetValue()
        inputField:SetText("")
        surface.PlaySound("amalgam/enter_command.ogg")
        if (text ~= "") then
            self.LastCommand = text
            Amalgam.AddToHistory("> " .. text)
            net.Start("nTerminalCommand")
            net.WriteString(text)
            net.SendToServer()

            if (text ~= self.InputHistory[1]) then
                table.insert(self.InputHistory, 1, text)

                if (#self.InputHistory > 25) then
                    table.remove(self.InputHistory)
                end
            end

            self.HistoryIndex = 0
        end
        inputField:RequestFocus()
    end

    self.Input.OnKeyCodeTyped = function(s, code)
        if (code == KEY_ENTER or code == KEY_PAD_ENTER) then
            s:OnEnter()
            return
        end
        
        if (code == KEY_UP) then
            if (#self.InputHistory == 0) then return end
            self.HistoryIndex = math.min(self.HistoryIndex + 1, #self.InputHistory)
            s:SetText(self.InputHistory[self.HistoryIndex])
            s:SetCaretPos(#s:GetText())
        elseif (code == KEY_DOWN) then
            self.HistoryIndex = math.max(self.HistoryIndex - 1, 0)
            if (self.HistoryIndex == 0) then
                s:SetText("")
            else
                s:SetText(self.InputHistory[self.HistoryIndex])
                s:SetCaretPos(#s:GetText())
            end
        end
    end

    self.Input:RequestFocus()
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, Color(15, 15, 15))
end

function Amalgam.AddToHistory(text, msgType)
    if (not IsValid(Amalgam.Terminal)) then return end
    local history = Amalgam.Terminal.History

    history:InsertColorChange(255, 165, 0, 255)
    history:AppendText("\nAmalgam$ ")

    if (msgType == "admin") then
        history:InsertColorChange(255, 255, 255, 255)
    elseif (msgType == "warning") then
        history:InsertColorChange(255, 200, 0, 255)
    elseif (msgType == "error") then
        history:InsertColorChange(200, 0, 0, 255)
    elseif (msgType == "info") then
        history:InsertColorChange(153, 255, 51, 255)
    else
        history:InsertColorChange(200, 200, 200, 255)
    end

    history:AppendText(text)
    history:GotoTextEnd()
end

vgui.Register("AmalgamTerminal", PANEL, "DFrame")

net.Receive("nTerminalAddHistory", function()
    local text = net.ReadString()
    local msgType = net.ReadString()

    if (Amalgam.AddToHistory) then
        Amalgam.AddToHistory(text, msgType)
    end
end)