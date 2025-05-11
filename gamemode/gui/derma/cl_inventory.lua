local PANEL = {}

PANEL.InventoryWidth = ScrW() * 0.5
PANEL.InventoryHeight = ScrH() * 0.43
PANEL.StartY = ScrH() + 10
PANEL.OpenY = ScrH() - PANEL.InventoryHeight - 10

function PANEL:Init()
    self:SetSize(self.InventoryWidth, self.InventoryHeight)
    self:SetPos((ScrW() - self.InventoryWidth) / 2, self.StartY)
    self:MakePopup()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetDraggable(false)

    local gradient = Material("vgui/gradient-d")

    self.Paint = function(s, w, h)
        surface.SetDrawColor(255, 168, 35, 25)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        draw.RoundedBox(8, 0, 0, w, h, Color(15, 15, 15, 220))
        surface.SetDrawColor(15, 15, 15, 25)
        surface.SetMaterial(gradient)
        surface.DrawTexturedRect(0, 0, w, h)
    end

    self.Title = vgui.Create("DLabel", self)
    self.Title:SetText("Inventory")
    self.Title:SetFont("Amalgam.DermaLabelBig")
    self.Title:SetTextColor(Color(225, 168, 0, 245))
    self.Title:SetContentAlignment(4)
    self.Title:SetSize(120, 40)
    self.Title:SetPos(15, 5)

    self.CloseButton = vgui.Create("DButton", self)
    self.CloseButton:SetText("X")
    self.CloseButton:SetFont("Amalgam.DermaLabelNormal")
    self.CloseButton:SetSize(40, 40)
    self.CloseButton:SetPos(self:GetWide() - 50, 5)
    self.CloseButton:SetTextColor(Color(255, 255, 255))
    self.CloseButton.DoClick = function()
        self:CloseInventory()
    end

    self.CloseButton.Paint = function(s, w, h)
        local col = s:IsHovered() and Color(255, 168, 35, 180) or Color(150, 75, 25, 180)
        draw.RoundedBox(8, 0, 0, w, h, col)
    end

    self.FillerPanel = vgui.Create("DScrollPanel", self)
    self.FillerPanel:SetSize(self.InventoryWidth - 40, self.InventoryHeight - 110)
    self.FillerPanel:SetPos(20, 55)

    self.FillerPanel.Paint = function(s, w, h)
        surface.SetDrawColor(20, 20, 20, 230)
        surface.DrawRect(0, 0, w, h)
    end

    self.ItemGrid = vgui.Create("DIconLayout", self.FillerPanel)
    self.ItemGrid:SetSize(self.FillerPanel:GetWide() - 10, self.FillerPanel:GetTall())
    self.ItemGrid:SetSpaceY(5)
    self.ItemGrid:SetSpaceX(5)
    self.ItemGrid:SetPos(10, 10)

    local weight = LocalPlayer():GetInventoryWeight()
    local maxWeight = Amalgam.GetConfig("MaxWeight")
    self.WeightLabel = vgui.Create("DLabel", self)
    self.WeightLabel:SetFont("Amalgam.DermaLabelNormal")
    self.WeightLabel:SetTextColor(Color(225, 225, 225, 245))
    self.WeightLabel:SetSize(self.InventoryWidth, 20)
    self.WeightLabel:SetPos(15, self.InventoryHeight - 40)
    self.WeightLabel:SetText("Weight: " .. weight .. " / " .. maxWeight)

    self.DropMoneyButton = vgui.Create("DButton", self)
    self.DropMoneyButton:SetText("Drop Money")
    self.DropMoneyButton:SetSize(120, 40)
    self.DropMoneyButton:SetPos(self.InventoryWidth - 130, self.InventoryHeight - 50)
    self.DropMoneyButton:SetTextColor(Color(255, 255, 255))
    self.DropMoneyButton:SetFont("Amalgam.DermaLabelNormal")
    self.DropMoneyButton.DoClick = function()
        self:DropMoneyMenu()
    end

    self.DropMoneyButton.Paint = function(s, w, h)
        local col = s:IsHovered() and Color(255, 168, 35, 180) or Color(150, 75, 25, 180)
        draw.RoundedBox(8, 0, 0, w, h, col)
    end
end

vgui.Register("AmalgamInventoryMenu", PANEL, "DFrame")

function PANEL:ToolTip(itemData)
    if not itemData then return end

    if IsValid(self.Tooltip) then
        self.Tooltip:Remove()
    end

    local padding = 10
    local iconSize = 64
    local textOffsetX = iconSize + padding * 2

    local nameText = itemData.Name or "Unknown"
    local descText = itemData.Description or "No description."

    surface.SetFont("DermaLarge")
    local nameW = surface.GetTextSize(nameText)

    surface.SetFont("Amalgam.ToolTipLabelNormal")
    local descW = surface.GetTextSize(descText)

    local totalW = math.max(nameW, descW) + textOffsetX + padding
    local totalH = iconSize + padding * 2

    local tooltip = vgui.Create("DPanel")
    self.Tooltip = tooltip
    tooltip:SetSize(totalW, totalH)
    tooltip:SetDrawOnTop(true)
    tooltip:SetZPos(32767)
    tooltip:MakePopup()
    tooltip:SetMouseInputEnabled(false)
    tooltip:SetKeyboardInputEnabled(false)

    tooltip.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 20, 240))
    end

    -- Icon Frame Box
    local iconFrame = vgui.Create("DPanel", tooltip)
    iconFrame:SetPos(padding - 1, padding - 1)
    iconFrame:SetSize(iconSize + 2, iconSize + 2)
    iconFrame.Paint = function(s, w, h)
        surface.SetDrawColor(255, 168, 53, 220)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    local icon = vgui.Create("SpawnIcon", iconFrame)
    icon:SetModel(itemData.Model or "models/props_junk/PopCan01a.mdl")
    icon:SetSize(iconSize, iconSize)
    icon:SetPos(0, 0)
    icon:SetTooltip(false)
    icon:SetMouseInputEnabled(false)
    icon.PaintOver = function() end

    local nameLabel = vgui.Create("DLabel", tooltip)
    nameLabel:SetFont("Amalgam.ToolTipLabelBig")
    nameLabel:SetText(nameText)
    nameLabel:SetTextColor(Color(255, 168, 0))
    nameLabel:SizeToContents()
    nameLabel:SetPos(textOffsetX, padding)

    local descLabel = vgui.Create("DLabel", tooltip)
    descLabel:SetFont("Amalgam.ToolTipLabelNormal")
    descLabel:SetText(descText)
    descLabel:SetTextColor(color_white)
    descLabel:SetWrap(false)
    descLabel:SizeToContents()
    descLabel:SetPos(textOffsetX, padding + 30)

    tooltip.Think = function()
        local mx, my = input.GetCursorPos()
        tooltip:SetPos(mx + 15, my + 15)
    end
end

function PANEL:DropMoneyMenu()
    self:CloseInventory()

    local confirmPanel = vgui.Create("DFrame")
    confirmPanel:SetSize(350, 120)
    confirmPanel:SetPos(ScrW() / 2 - 150, ScrH() / 2 - 90)
    confirmPanel:SetTitle("")
    confirmPanel:SetDraggable(false)
    confirmPanel:ShowCloseButton(false)
    confirmPanel:MakePopup()

    local gradient = Material("vgui/gradient-d")
    confirmPanel.Paint = function(s, w, h)
        surface.SetDrawColor(255, 168, 35, 25)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        draw.RoundedBox(8, 0, 0, w, h, Color(15, 15, 15, 220))
        surface.SetDrawColor(15, 15, 15, 25)
        surface.SetMaterial(gradient)
        surface.DrawTexturedRect(0, 0, w, h)
    end

    local promptLabel = vgui.Create("DLabel", confirmPanel)
    promptLabel:SetText("Enter amount to drop...")
    promptLabel:SetFont("Amalgam.DermaLabelNormal")
    promptLabel:SetTextColor(Color(255, 255, 255))
    promptLabel:SetSize(280, 35)
    promptLabel:SetPos(10, 10)

    local amountInput = vgui.Create("DTextEntry", confirmPanel)
    amountInput:SetSize(200, 30)
    amountInput:SetPos(25, 60)
    amountInput:SetFont("Amalgam.DermaLabelNormal")

    local confirmButton = vgui.Create("DButton", confirmPanel)
    confirmButton:SetSize(85, 30)
    confirmButton:SetPos(230, 60)
    confirmButton:SetText("Confirm")
    confirmButton:SetTextColor(Color(255, 255, 255))
    confirmButton.DoClick = function()
        local amount = tonumber(amountInput:GetValue())
        if amount and amount > 0 then
            net.Start("nDropMoney")
                net.WriteUInt(amount, 32)
            net.SendToServer()

            confirmPanel:Close()
        end
    end

    local closeButton = vgui.Create("DButton", confirmPanel)
    closeButton:SetSize(40, 40)
    closeButton:SetPos(confirmPanel:GetWide() - 45, 5)
    closeButton:SetText("X")
    closeButton:SetTextColor(Color(255, 255, 255))
    closeButton.DoClick = function()
        confirmPanel:Close()
    end

    closeButton.Paint = function(s, w, h)
        local col = s:IsHovered() and Color(255, 168, 0, 180) or Color(150, 75, 25, 180)
        draw.RoundedBox(8, 0, 0, w, h, col)
    end

    confirmButton.Paint = function(s, w, h)
        local col = s:IsHovered() and Color(255, 168, 0, 180) or Color(150, 75, 25, 180)
        draw.RoundedBox(8, 0, 0, w, h, col)
    end
end

function PANEL:PopulateInventory()
    self.ItemGrid:Clear()

    local inv = LocalPlayer():GetInventory()
    local slotSize = 64

    for itemID, amount in pairs(inv) do
        local itemData = Amalgam.Items[itemID]
        if itemData then
            local container = vgui.Create("DPanel")
            container:SetSize(slotSize, slotSize)
            container:SetMouseInputEnabled(true)
            container.Paint = nil
            self.ItemGrid:Add(container)

            local slot = vgui.Create("DPanel", container)
            slot:SetSize(slotSize, slotSize)
            slot:SetMouseInputEnabled(false)

            slot.Paint = function(s, w, h)
                local hovered = container:IsHovered()

                local bgColor = hovered and Color(15, 15, 15, 220) or Color(50, 50, 50, 180)
                surface.SetDrawColor(bgColor)
                surface.DrawRect(0, 0, w, h)

                local outlineColor = hovered and Color(255, 165, 0, 255) or Color(80, 80, 80, 220)
                surface.SetDrawColor(outlineColor)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            end

            local icon = vgui.Create("SpawnIcon", slot)
            icon:SetSize(slotSize, slotSize)
            icon:SetModel(itemData.Model or "models/props_junk/PopCan01a.mdl")
            icon:SetTooltip(false)
            icon:SetMouseInputEnabled(false)
            icon.PaintOver = function() end

            container.OnCursorEntered = function()
                self:ToolTip(itemData)
            end

            container.OnCursorExited = function()
                local hovered = vgui.GetHoveredPanel()
                if IsValid(self.Tooltip) and (not hovered or hovered:GetName() ~= "DMenu") then
                    self.Tooltip:Remove()
                end
            end

            if amount > 1 then
                local countLabel = vgui.Create("DLabel", slot)
                countLabel:SetFont("DermaDefaultBold")
                countLabel:SetTextColor(Color(255, 255, 255))
                countLabel:SetText("x" .. amount)
                countLabel:SizeToContents()
                countLabel:SetPos(slotSize - countLabel:GetWide() - 4, 2)
                countLabel:SetZPos(10)
            end

            container.OnMousePressed = function(_, code)
                if code == MOUSE_RIGHT then
                    if IsValid(self.Tooltip) then
                        self.Tooltip.Think = nil
                    end

                    local menu = DermaMenu()
                    menu:SetDrawOnTop(true)

                    for name, func in pairs(itemData) do
                        if isfunction(func) then
                            menu:AddOption(string.upper(name), function()
                                net.Start("nItemFunc")
                                    net.WriteString(itemData.UniqueID)
                                    net.WriteString(name)
                                net.SendToServer()
                                if IsValid(self.Tooltip) then
                                    self.Tooltip:Remove()
                                end
                                timer.Simple(0.1, function()
                                    self:PopulateInventory()
                                    if (IsValid(self.WeightLabel)) then
                                        local weight = LocalPlayer():GetInventoryWeight()
                                        local maxWeight = Amalgam.GetConfig("MaxWeight")
                                        self.WeightLabel:SetText("Weight: " .. weight .. " / " .. maxWeight)
                                    end
                                end)
                            end)
                        end
                    end

                    menu.OnRemove = function()
                        if IsValid(self.Tooltip) then
                            self.Tooltip:Remove()
                        end
                    end

                    menu:Open()
                end
            end
        end
    end
end

function PANEL:OnKeyCodePressed(key)
    if input.LookupKeyBinding(key) == "+menu" then
        self:CloseInventory()
    end
end

function PANEL:OpenInventory()
    self:PopulateInventory()
    self:SetVisible(true)
    self:MoveTo((ScrW() - self.InventoryWidth) / 2, self.OpenY, 0.3, 0, 0.2)
    gui.EnableScreenClicker(true)
end

function PANEL:CloseInventory()
    self:MoveTo((ScrW() - self.InventoryWidth) / 2, self.StartY, 0.3, 0, 0.2, function()
        self:SetVisible(false)
    end)
    gui.EnableScreenClicker(false)
end

net.Receive("nSendInventory", function()
    local inv = net.ReadTable()
    LocalPlayer().Inventory = inv
    if (IsValid(LocalPlayer().InventoryMenu)) then
        LocalPlayer().InventoryMenu:PopulateInventory()
    end
end)
