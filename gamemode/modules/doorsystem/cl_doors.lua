if (CLIENT) then

    surface.CreateFont("Amalgam.DoorTitleLabel", {
        font = "Roboto",
        size = 40,
        weight = 400
    })

    surface.CreateFont("Amalgam.DoorRestLabel", {
        font = "Roboto",
        size = 20,
        weight = 400
    })

    function MODULE:HUDPaint()
        for _, door in ipairs(ents.GetAll()) do
            if (not IsValid(door) or not door:IsDoorEntity() or not (door:GetNWString("DoorTitle", "") ~= "")) then continue end

            door.HUDAlpha = door.HUDAlpha or 0

            local mins, maxs = door:OBBMins(), door:OBBMaxs()
            local a, b = door:GetRotatedAABB(mins, maxs)
            local wpos = door:GetPos() + (a + b) / 2
            local screenPos = wpos:ToScreen()

            local ply = LocalPlayer()
            local dist = door:GetPos():Distance(ply:GetPos())
            local maxDist = 256

            if (screenPos.visible and dist <= maxDist) then
                local tr = util.TraceLine({
                    start = ply:EyePos(),
                    endpos = ply:EyePos() + ply:GetAimVector() * maxDist,
                    filter = ply,
                    mask = MASK_SOLID
                })

                if (tr.Entity == door) then
                    door.HUDAlpha = math.Clamp(door.HUDAlpha + FrameTime() * 2, 0, 1)
                else
                    door.HUDAlpha = math.Clamp(door.HUDAlpha - FrameTime() * 2, 0, 1)
                end
            else
                door.HUDAlpha = math.Clamp(door.HUDAlpha - FrameTime() * 2, 0, 1)
            end

            if (door.HUDAlpha > 0) then
                local alpha = door.HUDAlpha * 255
                local y = screenPos.y

                local title = door:GetNWString("DoorTitle", "Door")
                local owner = door:GetNWEntity("DoorOwner")
                local price = door:GetNWInt("DoorPrice")
                local ownable = door:GetNWBool("DoorOwnable", false)

                draw.SimpleTextOutlined(title, "Amalgam.DoorTitleLabel", screenPos.x, y, Color(255, 168, 0, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))
                y = y + 22

                if (ownable) then
                    if (not IsValid(owner)) then
                        draw.SimpleTextOutlined("Unowned — Press F2 to buy(" .. price .. "$)", "Amalgam.DoorRestLabel", screenPos.x, y, Color(150, 255, 150, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))
                    elseif (owner == ply) then
                        draw.SimpleTextOutlined("Owned by You — Press F2 to release", "Amalgam.DoorRestLabel", screenPos.x, y, Color(255, 255, 150, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))
                    else
                        draw.SimpleTextOutlined("Owned", "Amalgam.DoorRestLabel", screenPos.x, y, Color(255, 150, 150, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))
                    end
                else
                    draw.SimpleTextOutlined("Unownable", "Amalgam.DoorRestLabel", screenPos.x, y, Color(200, 200, 200, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))
                end
            end
        end
    end
end