local MODULE = MODULE or {}
MODULE.Name = "Weapon Selection Menu"
MODULE.Description = "Replacer of the default HUD of the weapon selection menu"
MODULE.Author = "Oriensnox"

if (CLIENT) then
    MODULE.index = 1
    MODULE.alpha = 0
    MODULE.fadeTime = 0

    surface.CreateFont("Amalgam.WeaponLabel", {
        font = "Trebuchet24",
        size = 35,
        weight = 600
    })

    surface.CreateFont("Amalgam.WeaponIntLabel", {
        font = "Trebuchet24",
        size = 25,
        weight = 600
    })

	function MODULE:HUDPaint()
		if (self.alpha <= 0 or self.fadeTime < CurTime()) then
            self.alpha = 0
        else
    		local weapons = LocalPlayer():GetWeapons()
    		local total = #weapons
    		if (total == 0) then return end

    		local maxVisible = 4
    		local spacing = 30
    		local centerY = ScrH() * 0.5

    		for drawIndex = -1, 2 do
    			local weaponIndex = self.index + drawIndex

    			if (weaponIndex >= 1 and weaponIndex <= total) then
    				local weapon = weapons[weaponIndex]
    				local name = IsValid(weapon) and weapon:GetPrintName():upper() or "UNKNOWN"
    				local y = centerY + (drawIndex * spacing)

    				local alpha = 255
    				if (drawIndex == -1 or drawIndex == 2) then
    					alpha = 100
    				end

    				if (weapon:GetClass() == "gmod_tool") then
    					name = "Tool Gun"
    				end

    				local isSelected = (weaponIndex == self.index)
    				local color = isSelected and Color(255, 168, 0, alpha) or Color(200, 200, 200, alpha)

    				draw.SimpleText(name, "Amalgam.WeaponLabel", ScrW() * 0.5, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    			end
    		end

            local selected = weapons[self.index]
            if (IsValid(selected)) then
                local wepInt = selected.Instructions or ""
                if (wepInt ~= "") then
                    surface.SetFont("Amalgam.WeaponLabel")
                    local textWidth, textHeight = surface.GetTextSize(wepInt)

                    local alpha = math.Clamp(255 - ((CurTime() - self.fadeTime + 5) * 50), 0, 255)
                    local color = Color(200, 200, 200, alpha)

                    draw.SimpleText(wepInt, "Amalgam.WeaponIntLabel", ScrW() * 0.5 + 200, ScrH() * 0.5, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end
        end

        local ply = LocalPlayer()
        if (not IsValid(ply) or not ply:Alive()) then return end
        if (not ply:GetNWBool("FullyLoaded", false)) then return end


        local wep = ply:GetActiveWeapon()
        if (not IsValid(wep)) then return end

        local buildmodeTitle = "Build Mode"
        local buildmodeDesc = "Switch to your 'Hands' when you finish"

        if (wep:GetClass() == "amalgam_entsaver") then
            buildmodeTitle = "[Developer Mode]"
            buildmodeDesc = "Press LMB: To presist an entity on data | Press RMB: To unpresist entity from data"
        elseif (wep:GetClass() == "amalgam_doorsaver") then
            buildmodeTitle = "[Developer Mode]"
            buildmodeDesc = "Press LMB: Doors Editor | Press RMB: Unpresist Door"
        end

        if (wep:GetClass() == "weapon_physgun" or wep:GetClass() == "gmod_tool" or wep:GetClass() == "amalgam_entsaver" or wep:GetClass() == "amalgam_doorsaver") then
            surface.SetFont("Amalgam.HudLabelLarge")
            local titleW, titleH = surface.GetTextSize(buildmodeTitle)

            surface.SetFont("Amalgam.HudLabelSmall")
            local descW, descH = surface.GetTextSize(buildmodeDesc)

            local boxW = math.max(titleW, descW) + 40
            local boxH = titleH + descH + 30

            local scrW, scrH = ScrW(), ScrH()
            local boxX = (scrW / 2) - (boxW / 2)
            local boxY = scrH - boxH - 30

            draw.RoundedBox(8, boxX, boxY, boxW, boxH, Color(0, 0, 0, 180))

            draw.SimpleText(buildmodeTitle, "Amalgam.HudLabelLarge", scrW / 2, boxY + 10, Color(255, 255, 0), TEXT_ALIGN_CENTER)
            draw.SimpleText(buildmodeDesc, "Amalgam.HudLabelSmall", scrW / 2, boxY + 15 + titleH, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        end
	end

    function MODULE:PlayerBindPress(ply, bind, pressed)
        if (not pressed) then return end

        bind = bind:lower()
        local weapons = ply:GetWeapons()
        local changed = false

        if (bind:find("invprev")) then
            self.index = math.Clamp(self.index + 1, 1, #weapons)
            surface.PlaySound("amalgam/scroll.ogg")
            changed = true
        elseif (bind:find("invnext")) then
            self.index = math.Clamp(self.index - 1, 1, #weapons)
            surface.PlaySound("amalgam/scroll.ogg")
            changed = true
        elseif (bind:find("slot")) then
            local slot = tonumber(bind:match("slot(%d)")) or 1
            self.index = math.Clamp(slot, 1, #weapons)
            surface.PlaySound("amalgam/scroll.ogg")
            changed = true
        elseif (bind:find("attack") and self.alpha > 0) then
            local weapon = weapons[self.index]
            if (IsValid(weapon)) then
                input.SelectWeapon(weapon)
            end
            self.alpha = 0
            surface.PlaySound("amalgam/select.ogg")
            return true
        end

        if (changed) then
            self.alpha = 1
            self.fadeTime = CurTime() + 5
            return true
        end
    end

    function MODULE:Think()
        local ply = LocalPlayer()
        if (not IsValid(ply) or not ply:Alive()) then
            self.alpha = 0
        end
    end
end