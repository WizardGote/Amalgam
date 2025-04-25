MODULE.Name = "Amalgam Hud"
MODULE.Description = "The default HUD of Amalgam"
MODULE.Author = "Oriensnox"

if (CLIENT) then
    local hudgradient = Material("vgui/gradient-d")
    local amalgamLogo = Material("amalgam/amalcon.PNG")

    local hudWidth, hudHeight = 360, 120
    local hudX, hudY = 10, ScrH() - hudHeight - 10
    local padding = 10
    local smoothSpeed = 10
    local barSegments = 12
    local smoothHealth, smoothArmor = 100, 0

    local function DrawSegmentedBar(x, y, width, height, value, max, color)
        local segments = barSegments
        local segmentWidth = width / segments
        local filledSegments = math.Round((value / max) * segments)

        for i = 1, segments do
            draw.RoundedBox(4, x + (i - 1) * segmentWidth, y, segmentWidth - 2, height, Color(45, 45, 45, 200))
        end

        for i = 1, filledSegments do
            local segmentX = x + (i - 1) * segmentWidth
            draw.RoundedBox(4, segmentX, y, segmentWidth - 2, height, color)
            draw.RoundedBox(4, segmentX, y, segmentWidth - 2, height, Color(color.r, color.g, color.b, 35))
        end
    end

    local function FormatMoney(amount)
        if (amount >= 1e9) then
            return math.floor(amount / 1e9) .. "b"
        elseif (amount >= 1e6) then
            return math.floor(amount / 1e6) .. "m"
        elseif (amount >= 1e5) then
            return math.floor(amount / 1e3) .. "k"
        else
            return amount
        end
    end

    function MODULE:HUDShouldDraw(element)
        if (element == "CHudHealth" or 
            element == "CHudBattery" or 
            element == "CHudAmmo" or 
            element == "CHudSecondaryAmmo")
        then return false end
    end

    function MODULE:HUDPaint()
        local ply = LocalPlayer()
        if (not IsValid(ply) or not ply:Alive()) then return end
        if (not ply:GetNWBool("FullyLoaded", false)) then return end
    	if (ply:GetNWBool("IntroActive", false)) then return end

        smoothHealth = Lerp(FrameTime() * smoothSpeed, smoothHealth, ply:Health())
        smoothArmor = Lerp(FrameTime() * smoothSpeed, smoothArmor, ply:Armor())

        local job = ply:GetJobName() or "Unemployed"
        local money = ply:GetMoney() or 0
        local formattedMoney = FormatMoney(money)
        local zodiacSymbol = (Amalgam.Zodiacs[ply:GetZodiac() or ""] or {}).Symbol or "☼"
        local zodiac = ply:GetZodiac() or "Unknown"
        local zodiacArgs = zodiacSymbol .. " " .. zodiac

        draw.RoundedBox(6, hudX, hudY, hudWidth, hudHeight, Color(30, 30, 20, 215))
        surface.SetDrawColor(15, 15, 15, 200)
        surface.SetMaterial(hudgradient)
        surface.DrawTexturedRect(hudX, hudY, hudWidth, hudHeight)

        surface.SetDrawColor(255, 255, 255, 10)
        surface.SetMaterial(amalgamLogo)
        local logoSize = 96
        local logoX = hudX + hudWidth / 2 - logoSize / 2
        local logoY = hudY + hudHeight / 2 - logoSize / 2
        surface.DrawTexturedRect(logoX, logoY, logoSize, logoSize)

        surface.SetDrawColor(225, 168, 0, 50)
        surface.DrawOutlinedRect(hudX - 2, hudY - 2, hudWidth + 4, hudHeight + 4, 3)
        surface.SetDrawColor(255, 168, 35, 100)
        surface.DrawOutlinedRect(hudX - 1, hudY - 1, hudWidth + 2, hudHeight + 2, 2)

        local barX = hudX + padding
        local barWidth = hudWidth - padding * 2
        DrawSegmentedBar(barX, hudY + padding + 5, barWidth, 12, ply:Health(), ply:GetMaxHealth(), Color(256, 168, 0, 255))
        DrawSegmentedBar(barX, hudY + padding + 25, barWidth, 12, smoothArmor, 100, Color(200, 200, 255, 255))

        draw.SimpleTextOutlined(job, "Amalgam.DermaLabelNormal", hudX + hudWidth / 2, hudY + hudHeight - 58, Color(225, 168, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 100))
        draw.SimpleTextOutlined(zodiacArgs, "Amalgam.DermaLabelSmall", hudX + padding, hudY + hudHeight - 30, Color(245, 245, 245, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 100))
        draw.SimpleTextOutlined("$" .. formattedMoney, "Amalgam.DermaLabelSmall", hudX + hudWidth - padding, hudY + hudHeight - 30, Color(245, 245, 245, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 100))
    end
end
