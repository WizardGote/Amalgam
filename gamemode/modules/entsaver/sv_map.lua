local dir = "amalgam/maps"
local path = string.format("%s/%s.txt", dir, game.GetMap())

function MODULE:InitPostEntity()
    if (not file.Exists(path, "DATA")) then return end

    local data = file.Read(path, "DATA")
    if (not data) then return end

    local rows = string.Explode("\n", data)
    local count = 0

    for _, row in ipairs(rows) do
        local octet = string.Explode(";", row)
        if (#octet >= 3) then
            local pos = Vector(octet[1])
            local ang = Angle(octet[2])
            local class = string.Trim(octet[3])

            local ent = ents.Create(class)
            if (IsValid(ent)) then
                ent:SetPos(pos)
                ent:SetAngles(ang)
                ent:Spawn()
                ent:SetNWBool("Persistent", true)
                ent.AmalgamPersistent = true
                count = count + 1
            else
                print("[Amalgam] Failed to create entity:", class)
            end
        end
    end

    print(string.format("[Amalgam] Loaded %d persistent entities for map '%s'.", count, game.GetMap()))
end

function Amalgam.SavePersistentEntity(pos, ang, class)
    if (not file.IsDir(dir, "DATA")) then file.CreateDir(dir) end

    local rows = {}
    if (file.Exists(path, "DATA")) then
        rows = string.Explode("\n", file.Read(path, "DATA"))

        for _, row in ipairs(rows) do
            local octet = string.Explode(";", row)
            if (#octet >= 3) then
                local savedPos = Vector(octet[1])
                local savedAng = Angle(octet[2])
                local savedClass = string.Trim(octet[3])

                if (
                    savedClass == class and
                    pos:Distance(savedPos) < 1 and
                    math.abs(ang.p - savedAng.p) < 1 and
                    math.abs(ang.y - savedAng.y) < 1 and
                    math.abs(ang.r - savedAng.r) < 1
                ) then
                    return
                end
            end
        end
    end

    table.insert(rows, string.format(
        "%s;%s;%s",
        tostring(pos),
        tostring(ang),
        class
    ))

    file.Write(path, table.concat(rows, "\n"))
end

function Amalgam.RemovePersistentEntity(pos, ang, class)
    if (not file.Exists(path, "DATA")) then return false end

    local rows = string.Explode("\n", file.Read(path, "DATA"))
    local newRows = {}
    local removedEnt = false

    for _, row in ipairs(rows) do
        local octet = string.Explode(";", row)
        if (#octet >= 3) then
            local savedPos = Vector(octet[1])
            local savedAng = Angle(octet[2])
            local savedClass = string.Trim(octet[3])

            if (
                savedClass == class and
                pos:Distance(savedPos) < 1 and
                math.abs(ang.p - savedAng.p) < 1 and
                math.abs(ang.y - savedAng.y) < 1 and
                math.abs(ang.r - savedAng.r) < 1
            ) then
                removedEnt = true
            else
                table.insert(newRows, row)
            end
        else
            table.insert(newRows, row)
        end
    end

    file.Write(path, table.concat(newRows, "\n"))
    return removedEnt
end