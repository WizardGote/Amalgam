if (CLIENT) then

    Amalgam.Notifications = {}
    local fadeTime, stayTime = 1, 5
    local notifySound = "amalgam/notif.ogg"
    local maxNotifications = 3
    local slideSpeed = 5
    local dropSpeed = 5
    local textPadding = 10
    local maxWidth = ScrW() * 0.3
    local minWidth = 150
    local startOffset = 0

    local gradient = Material("vgui/gradient-r")
    local shadowColor = Color(0, 0, 0, 100)
    local borderColor = Color(255, 168, 35, 25)
    local backgroundColor = Color(15, 15, 15, 230)
    local gradientColor = Color(15, 15, 15, 25)
    local textColor = Color(255, 168, 0, 245)

    function Amalgam.CreateNotification(text)
        if (#Amalgam.Notifications >= maxNotifications) then
            table.remove(Amalgam.Notifications, 1)
        end

        surface.SetFont("Amalgam.HudLabelSmall")
        local textWidth, textHeight = surface.GetTextSize(text or " ")

        if (not textWidth or not textHeight) then
            print("[ERROR] Amalgam: Failed to get text size.")
            return
        end

        local notifWidth = math.Clamp(textWidth + (textPadding * 2), minWidth, maxWidth)
        local notifHeight = textHeight + (textPadding * 2)

        local notif = {
            text = text,
            alpha = 0,
            created = CurTime(),
            xPos = ScrW(),
            targetX = ScrW() - notifWidth - startOffset,
            yPos = startOffset,
            width = notifWidth,
            height = notifHeight,
            dropping = false
        }

        table.insert(Amalgam.Notifications, notif)
        surface.PlaySound(notifySound)

        timer.Simple(stayTime, function()
            if (notif) then
                notif.dropping = true
            end
        end)
    end

    hook.Add("HUDPaint", "DrawNotifications", function()
        local yOffset = 100

        for i = #Amalgam.Notifications, 1, -1 do
            local notif = Amalgam.Notifications[i]
            if (notif) then
                if (notif.dropping) then
                    notif.xPos = Lerp(FrameTime() * dropSpeed, notif.xPos, ScrW() + notif.width)
                else
                    notif.xPos = Lerp(FrameTime() * slideSpeed, notif.xPos, notif.targetX)
                end

                if (notif.dropping and notif.xPos >= ScrW()) then
                    table.remove(Amalgam.Notifications, i)
                else
                    local hue = 30 + math.sin(CurTime() * 2) * 10
                    local ocycle = HSVToColor(hue, 1, 1)
                    surface.SetDrawColor(ocycle)
                    surface.DrawOutlinedRect(notif.xPos - 1, notif.yPos + yOffset - 1, notif.width + 2, notif.height + 2, 2)

                    draw.RoundedBox(0, notif.xPos, notif.yPos + yOffset, notif.width, notif.height, backgroundColor)

                    surface.SetDrawColor(gradientColor)
                    surface.SetMaterial(gradient)
                    surface.DrawTexturedRect(notif.xPos, notif.yPos + yOffset, notif.width, notif.height)
                    draw.SimpleText(notif.text, "Amalgam.HudLabelSmall", notif.xPos + (notif.width / 2), notif.yPos + (notif.height / 2) + yOffset, ocycle, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                    yOffset = yOffset + notif.height + 12
                end
            end
        end
    end)

    net.Receive("SendNotification", function()
        local text = net.ReadString()
        Amalgam.CreateNotification(text)
    end)

else
    util.AddNetworkString("SendNotification")
    local meta = FindMetaTable("Player")

    function meta:Notify(text)
        if (not IsValid(self)) then return end
        if (SERVER) then
            net.Start("SendNotification")
                net.WriteString(text)
            net.Send(self)
        elseif (CLIENT and self == LocalPlayer()) then
            Amalgam.CreateNotification(text)
        end
    end
end
