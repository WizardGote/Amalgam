if (SERVER) then
  util.AddNetworkString("nDoorEditor")
  util.AddNetworkString("nDoorSaver")

  local dir = "amalgam/maps"
  local path = string.format("%s/%s_doors.txt", dir, game.GetMap())

  function MODULE:InitPostEntity()
      if (not file.Exists(path, "DATA")) then return end
      local data = file.Read(path, "DATA")
      if (not data) then return end

      local rows = string.Explode("\n", data)
      for _, row in ipairs(rows) do
          local octet = string.Explode(";", row)
          if (#octet < 7) then continue end

          local pos = Vector(octet[1])
          local ang = Angle(octet[2])
          local class = octet[3]
          local ownable = tobool(tonumber(octet[4]))
          local price = tonumber(octet[5]) or 0
          local title = octet[6]
          local parentPos = Vector(octet[7])

          for _, door in ipairs(ents.FindByClass(class)) do
              if (door:GetPos():Distance(pos) < 2 and door:GetAngles():Forward():Dot(ang:Forward()) > 0.99) then
                  door:SetNWBool("DoorOwnable", ownable)
                  door:SetNWInt("DoorPrice", price)
                  door:SetNWString("DoorTitle", title)
                  door:SetNWVector("DoorParent", parentPos)
                  break
              end
          end
      end
  end

function MODULE:PlayerButtonDown(ply, key)
    if (key ~= KEY_F2) then return end

    local tr = ply:GetEyeTrace()
    local door = tr.Entity

    if (not IsValid(door)) then return end
    if (not door:IsDoorEntity()) then return end
    if (tr.HitPos:Distance(ply:GetPos()) > 150) then return end

    local ownable = door:GetNWBool("DoorOwnable", false)
    local owner = door:GetNWEntity("DoorOwner")
    local title = door:GetNWString("DoorTitle")
    local price = door:GetNWInt("DoorPrice")

    if (not ownable) then
        ply:Notify("You can't buy this door")
        return
    elseif (ply:Money() < price) then
        ply:Notify("You don't have enough to purchase this door")
        return
    elseif (IsValid(owner) and owner ~= ply) then
      	ply:Notify("This door is already owned by someone")
        return
    elseif (not IsValid(owner)) then
        ply:AddMoney(-price)
        ply:Notify("You now owe: " .. title)
        door:SetNWEntity("DoorOwner", ply)
        Amalgam.AssignChildrenOwnership(door, ply)
    elseif (owner == ply) then
        local newPrice = math.Round(price / 2)
        ply:AddMoney(newPrice)
        ply:Notify("You no longer own: " .. title .. " (Received: " .. newPrice .. "$)")
        door:SetNWEntity("DoorOwner", "")
        door:Fire("Unlock", "", 0)
        Amalgam.ReleaseChildrenOwnership(door)
    end
end

  net.Receive("nDoorSaver", function(len, ply)
      local door = net.ReadEntity()

      local ownable = net.ReadBool()
      local price = net.ReadInt(32)
      local title = net.ReadString()
      local parent = door:GetNWVector("DoorParent", Vector(0, 0, 0))

      door:SetNWBool("DoorOwnable", ownable)
      door:SetNWInt("DoorPrice", price)
      door:SetNWString("DoorTitle", title)

      if (not file.IsDir(dir, "DATA")) then file.CreateDir(dir) end

      local rows = file.Exists(path, "DATA") and string.Explode("\n", file.Read(path, "DATA")) or {}
      local newRows = {}
      local updated = false
      local pos = door:GetPos()
      local ang = door:GetAngles()
      local class = door:GetClass()

      for _, row in ipairs(rows) do
          local octet = string.Explode(";", row)
          if (#octet >= 7) then
              local savedPos = Vector(octet[1])
              local savedAng = Angle(octet[2])
              local savedClass = octet[3]

              if (savedClass == class and pos:Distance(savedPos) < 1 and ang:Forward():Dot(savedAng:Forward()) > 0.99) then
                  table.insert(newRows, string.format(
                      "%s;%s;%s;%d;%d;%s;%s",
                      tostring(pos), tostring(ang), class,
                      ownable and 1 or 0,
                      price, title, tostring(parent)
                  ))
                  updated = true
              else
                  table.insert(newRows, row)
              end
          end
      end

      if (not updated) then
          table.insert(newRows, string.format(
              "%s;%s;%s;%d;%d;%s;%s",
              tostring(pos), tostring(ang), class,
              ownable and 1 or 0,
              price, title, tostring(parent)
          ))
      end

      file.Write(path, table.concat(newRows, "\n"))
  end)

  function Amalgam.RemoveDoorFromPersistence(pos, ang, class)
      if (not file.Exists(path, "DATA")) then return false end

      local rows = string.Explode("\n", file.Read(path, "DATA"))
      local newRows = {}
      local removed = false

      for _, row in ipairs(rows) do
          local octet = string.Explode(";", row)
          if (#octet >= 7) then
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
                  removed = true
              else
                  table.insert(newRows, row)
              end
          else
              table.insert(newRows, row)
          end
      end

      file.Write(path, table.concat(newRows, "\n"))
      return removed
  end
end
