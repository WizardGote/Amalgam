local PANEL = {}

function PANEL:Init()
    local w, h = 900, 500
    local terminalX, terminalY = 50, ScrH() / 2 - 300
    local paddingX, paddingY = 40, -20

    self:SetSize(w, h)
    self:SetPos(terminalX + self:GetWide() + paddingX, terminalY + paddingY)
    self:SetTitle("")
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    self:MakePopup()

    self.TopBar = vgui.Create("DPanel", self)
    self.TopBar:SetPos(0, 0)
    self.TopBar:SetSize(w, 30)
    self.TopBar.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(30, 30, 30))
        draw.SimpleText("A-Shell: Log Viewer", "DermaDefaultBold", 10, h / 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    self.TopBar.OnMousePressed = function(_, code)
        if code == MOUSE_LEFT then
            self:MouseCapture(true)
            self.Dragging = { gui.MouseX() - self.x, gui.MouseY() - self.y }
        end
    end

    self.TopBar.OnMouseReleased = function()
        self:MouseCapture(false)
        self.Dragging = nil
    end

    self.TopBar.OnCursorMoved = function(_, x, y)
        if self.Dragging then
            local mx, my = gui.MouseX(), gui.MouseY()
            self:SetPos(mx - self.Dragging[1], my - self.Dragging[2])
        end
    end

    self.CloseButton = vgui.Create("DButton", self.TopBar)
    self.CloseButton:SetSize(20, 20)
    self.CloseButton:SetPos(w - 30, 5)
    self.CloseButton:SetText("")
    self.CloseButton.Paint = function(_, w, h)
        draw.RoundedBox(10, 0, 0, w, h, Color(220, 50, 50))
    end
    self.CloseButton.DoClick = function()
        self:Remove()
    end

    self.LogDisplay = vgui.Create("RichText", self)
    self.LogDisplay:SetPos(5, 35)
    self.LogDisplay:SetSize(w - 10, h - 40)
    self.LogDisplay:SetVerticalScrollbarEnabled(true)
    self.LogDisplay.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(15, 15, 15))
    end
end

function PANEL:PopulateLogs(logs)
    for _, entry in ipairs(logs) do
        local msg = entry.Message or entry.msg or ""
        local type = entry.Type or entry.type or "info"
        local ts = os.date("%H:%M:%S", entry.Timestamp or os.time())

        local color = Color(200, 200, 200)
        if type == "error" then
            color = Color(255, 0, 0)
        elseif type == "info" then
            color = Color(153, 255, 51)
        elseif type == "admin" then
            color = Color(255, 255, 255)
        elseif type == "warning" then
            color = Color(255, 200, 0)
        end

        self.LogDisplay:InsertColorChange(color.r, color.g, color.b, 255)
        self.LogDisplay:AppendText("[" .. ts .. "] " .. msg .. "\n")
    end

    self.LogDisplay:GotoTextEnd()
end

vgui.Register("AmalgamLogViewer", PANEL, "DFrame")

net.Receive("nOpenLogViewer", function()
    local logs = net.ReadTable()
    if not istable(logs) or #logs == 0 then return end

    local frame = vgui.Create("AmalgamLogViewer")
    frame:PopulateLogs(logs)
end)
