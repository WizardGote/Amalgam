function GM:PlayerInitialSpawn(ply)
    local dbloadAttempts = 0
    timer.Create("SendDBStatus_" .. ply:SteamID(), 0.5, 20, function()
        if (not IsValid(ply)) then return end
        dbloadAttempts = dbloadAttempts + 1

        if (Database and Database.Connected ~= nil) then
            net.Start("nDatabaseStatus")
            net.WriteBool(Database.Connected == true)
            net.Send(ply)

            timer.Remove("SendDBStatus_" .. ply:SteamID())
        end
    end)
  
    ply:SetCustomCollisionCheck(true)
    ply:SetCanZoom(false)
    ply.Afk = CurTime()
end

function GM:PlayerSpawn(ply)
    self.BaseClass:PlayerSpawn(ply)
    ply.dbloadAttempts = 0

    if (ply.PlayerData) then
        ply:ApplyPlayerData()
        self:PlayerLoadout(ply)
        ply:SetJob("Job_None")
        return
    end

    ply:LoadPlayerData(function(success, err)
        if (not IsValid(ply)) then return end

        if (not success) then
            ply.dbloadAttempts = ply.dbloadAttempts + 1

            if (ply.dbloadAttempts >= 3) then
                ply:Kick("[Amalgam] Database Error: Failed to load data. Rejoin and try again.")
            else
                timer.Simple(2, function()
                    if (IsValid(ply)) then
                        ply:LoadPlayerData()
                    end
                end)
            end
            return
        end

        ply:ApplyPlayerData()
        ply:ForceInvSync()

        if (ply:GetData("Registered", 0) ~= 1) then
            ply:SetMoveType(MOVETYPE_NONE)
            ply:SetNoDraw(true)
            ply:Lock()

            if (Amalgam.GetConfig("AllowIntro") == true) then
                if (ply:GetData("Intro", 0) ~= 1) then
                    net.Start("nStartIntro")
                    net.Send(ply)
                    return
                end
            end

            net.Start("nCharacterCreation")
            net.Send(ply)
        else
            ply:SetNWBool("FullyLoaded", true)
            self:PlayerLoadout(ply)
            ply:SetJob("Job_None")
        end
    end)
end

function GM:PlayerLoadout(ply)
    ply:Give("amalgam_hands")
    ply:Give("amalgam_keys")

    timer.Simple(2, function()
        if (ply:ToolTrust() == 1) then
            ply:Give("weapon_physgun")
        elseif (ply:ToolTrust() == 2 or ply:HasRank("Administrator")) then
            ply:Give("weapon_physgun")
            ply:Give("gmod_tool")
        end
    end)
end

function GM:PlayerSwitchWeapon(ply, oldWep, newWep)
    if (not IsValid(ply) or not IsValid(newWep)) then return end

    local class = newWep:GetClass()
    if (class == "weapon_physgun" or class == "gmod_tool") then
        ply:SetWalkSpeed(75)
        ply:SetRunSpeed(75)
    else
        ply:SetWalkSpeed(Amalgam.GetConfig("WalkSpeed"))
        ply:SetRunSpeed(Amalgam.GetConfig("RunSpeed"))
    end
end

local meta = FindMetaTable("Player")

function meta:IsAFK(threshold)
    threshold = threshold or 60
    return (CurTime() - (self.Afk or 0)) >= threshold
end

net.Receive("nPlayerRegistered", function(len, ply)
    local name = net.ReadString()
    local bio = net.ReadString()
    local model = net.ReadString()
    local zodiac = net.ReadString()

    ply:SetNWBool("FullyLoaded", true)
    ply:SetCharNickname(name)
    ply:SetCharBio(bio)
    ply:SetZodiac(zodiac)
    ply:SetCharModel(model, true)
    ply:SetData("Registered", 1, true)
    ply:SetNoDraw(false)
    ply:UnLock()
    ply:SetMoveType(MOVETYPE_WALK)
    ply:Spawn()
end)

net.Receive("nIntroWatched", function(len, ply)
    if (not IsValid(ply) or not ply:IsPlayer()) then return end
    if (ply.IntroMarked) then return end

    ply.IntroMarked = true
    ply:SetNWBool("IntroWatched", true)
    ply:SetData("WatchedIntro", 1, true)
end)

net.Receive("nTypingStatus", function(_, ply)
    local typing = net.ReadBool()
    ply:SetNWBool("PlayerTyping", typing)
end)
