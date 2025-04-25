MODULE.Name = "Terminal Commands"
MODULE.Description = "All the default commands for A-Shell"
MODULE.Author = "Oriensnox"

--[[-------------------------------------------------------------------
					Terminal Commands

This file contains all core A-Shell command registrations.
To maintain consistency and keep the codebase organized, all terminal
commands should be defined here. This ensures a single point of truth
for shared command logic.

Note: All commands should be structured in the shared realm.
---------------------------------------------------------------------]]

Amalgam.RegisterCommand("claimroot", "Claim Root User access with root password", function(ply, password)
    if (Amalgam.RootUserStatus()) then
        Amalgam.TerminalNetSend("[Error] Root User already exists. Root access is disabled.", "error", ply)
        return
    end

    if (not file.Exists(Amalgam.RootPasswordFile, "DATA")) then
        Amalgam.TerminalNetSend("[Error] Root password is missing! Restart the server to generate a new one.", "error", ply)
        return
    end

    local storedPassword = file.Read(Amalgam.RootPasswordFile, "DATA")

    if (password ~= storedPassword) then
        Amalgam.TerminalNetSend("[Error] Incorrect root password!", "error", ply)
        return
    end

    file.Write(Amalgam.RootUserFile, ply:SteamID())
    Amalgam.DeleteRootPassword()
    Amalgam.TerminalNetSend("You have set yourself root access!", "admin", ply)
    Amalgam.TerminalNetSend("Deleting file 'amalgam_root.txt'", "warning", ply)
    Amalgam.TerminalNetSend("'$claimroot' is permanently disabled!", "warning", ply)
    ply:SetRank("RootUser")
end, nil, {"password"}, true)

Amalgam.RegisterCommand("help", "", function(ply)
    local index = {}
    table.insert(index, "Available Commands:")
    for name, data in pairs(Amalgam.Commands) do
        local required = data.requiredRank
        if (not data.isHidden and (not required or ply:HasRank(required)) and not string.StartWith(name, "dev_")) then
            local argsList = table.concat(data.requiredArgs or {}, " ")
            local argsDisplay = argsList ~= "" and " [" .. argsList .. "]" or ""
            table.insert(index, "$" .. name .. argsDisplay .. " - " .. data.desc)
        end
    end
    table.insert(index, "\n[Info] All commands must begin with the prefix '$'")
    table.insert(index, "[Info] Use ↑ / ↓ to scroll through previous commands.")
    local result = table.concat(index, "\n")
    Amalgam.TerminalNetSend(result, "info", ply)
end, "Moderator", nil, true)

Amalgam.RegisterCommand("help_dev", "", function(ply)
    local index = {}
    table.insert(index, "Available Developer Commands:")
    for name, data in pairs(Amalgam.Commands) do
        local required = data.requiredRank
        if (not data.isHidden and (not required or ply:HasRank(required)) and string.StartWith(name, "dev_")) then
            local argsList = table.concat(data.requiredArgs or {}, " ")
            local argsDisplay = argsList ~= "" and " [" .. argsList .. "]" or ""
            table.insert(index, "$" .. name .. argsDisplay .. " - " .. data.desc)
        end
    end
    table.insert(index, "\n[Info] Refer to the repository documentation for detailed usage of this gamebase")
    table.insert(index, "for all developer tools and utilities")
    local result = table.concat(index, "\n")
    Amalgam.TerminalNetSend(result, "info", ply)
end, "RootUser", nil, true)

Amalgam.RegisterCommand("getplayers", "Print all the online players", function(ply)
    local index = {}
    table.insert(index, "Online Players:")

    for _, v in ipairs(player.GetAll()) do
        local steamName = v:Nick()
        local steamid = v:SteamID()
        local charName = "(" .. v:GetCharNickname() .. ")" or "N/A"
        local rank = v:GetRank() or "Unknown"
        local argsDisplay = " [" .. steamid .. "] [" .. rank .. "] " .. steamName .. " " .. charName
        table.insert(index, "*" .. argsDisplay)
    end
    local result = table.concat(index, "\n")
    Amalgam.TerminalNetSend(result, "info", ply)
end, "Moderator")

Amalgam.RegisterCommand("listitems", "Print all the existing items", function(ply)
    local index = {}
    local ind = 0
    table.insert(index, "Existing Items:")
    for _, v in pairs(Amalgam.Items) do
        ind = ind + 1
        local id = v.UniqueName
        local name = v.Name
        local argsDisplay = ind .. ") " .. "[" .. id .. "] " .. name 
        table.insert(index, argsDisplay)
    end
    local result = table.concat(index, "\n")
    Amalgam.TerminalNetSend(result, "info", ply)
end, "Administrator")

Amalgam.RegisterCommand("restart", "", function(ply)
    timer.Simple(5, function() 
		game.ConsoleCommand( "changelevel " .. game.GetMap() .. "\n" ) 
    end)
    Amalgam.TerminalNetSend("Server will restart in 5 seconds", "info", ply)
    Amalgam.InsertLog("admin", "[A] " .. ply:Nick() .. " restarted the server.")
    Amalgam.ChatNotifyAll(Color(225, 0, 0), "[Admin] ", Color(225, 255, 255), "Server will restart in 5 seconds")
end, "Administrator")

Amalgam.RegisterCommand("setrank", "Set a player's rank", function(ply, target, newRank)
    if (SERVER) then
        local targ = ply:FindPlayer(target)
        if (not IsValid(targ)) then
            Amalgam.TerminalNetSend("[Error] Player not found!", "error", ply)
            return
        end

        if (not Amalgam.RankHierarchy[newRank]) then
            Amalgam.TerminalNetSend("[Error] Invalid rank: " .. tostring(newRank), "error", ply)
            return
        end

        targ:SetRank(newRank)
        Amalgam.TerminalNetSend(targ:Name() .. " is now ranked: " .. newRank, "admin", ply)
      	Amalgam.InsertLog("admin", "[A] " .. ply:Nick() .. " set " .. targ:Nick() .. " rank to" .. newRank .. ".")
    end
end, "RootUser", {"player", "rank"})

Amalgam.RegisterCommand("kick", "Kick a player from the server", function(ply, target, reason)
    if (SERVER) then
        local targ = ply:FindPlayer(target)
        if (not IsValid(targ)) then
            Amalgam.TerminalNetSend("[Error] Player not found!", "error", ply)
            return
        end

        if (not ply:CanActOn(targ)) then
            Amalgam.TerminalNetSend("[Error] You cannot target a player with equal or higher rank!", "error", ply)
            return
        end

        targ:Kick(reason)
        Amalgam.TerminalNetSend("[Admin] " .. target .. " was kicked for: " .. reason, "admin", ply)
      	Amalgam.InsertLog("admin", "[A] " .. ply:Nick() .. " kicked " .. targ:Nick() .. " for " .. reason .. ".")
    end
end, "Moderator", {"player", "reason"})

Amalgam.RegisterCommand("ban", "Ban a player from the server", function(ply, target, minutes, reason)
    if (SERVER) then
        local targ = ply:FindPlayer(target)
        if (not IsValid(targ)) then
            Amalgam.TerminalNetSend("[Error] Player not found!", "error", ply)
            return
        end

        local duration = tonumber(minutes)
        if (not duration or duration < 0) then
            Amalgam.TerminalNetSend("[Error] Invalid duration.", "error", ply)
            return
        end

        Amalgam.BanPlayer(targ, duration, reason or "No reason provided")
        Amalgam.TerminalNetSend("[Admin] " .. target .. " was banned for " .. (duration == 0 and "permanently" or (duration .. " minutes")) .. ": " .. reason, "admin", ply)
      	Amalgam.InsertLog("admin", "[A] " .. ply:Nick() .. " banned " .. targ:Nick() .. " for " .. (duration == 0 and "permanently" or (duration .. " minutes")) .. ": " .. reason .. ".")
    end
end, "Moderator", {"player", "minutes", "reason"})

Amalgam.RegisterCommand("unban", "Unban a player by SteamID64 or legacy SteamID", function(ply, steamid)
    if (SERVER) then
        if (not steamid or steamid == "") then
            Amalgam.TerminalNetSend("[Error] SteamID is required.", "error", ply)
            return
        end

        -- Auto-convert legacy to 64-bit
        if steamid:StartWith("STEAM_") then
            steamid = util.SteamIDTo64(steamid)
        end

        if (not Amalgam.BanCache[steamid]) then
            Amalgam.TerminalNetSend("[Error] No ban found for SteamID: " .. steamid, "error", ply)
            return
        end

        Amalgam.UnbanPlayer(steamid)
        Amalgam.BanCache[steamid] = nil

        Amalgam.TerminalNetSend("[Admin] Player with SteamID " .. steamid .. " has been unbanned.", "admin", ply)
        Amalgam.InsertLog("admin", "[A] " .. ply:Nick() .. " unbanned " .. steamid .. ".")
    end
end, "Moderator", {"steamid"})

Amalgam.RegisterCommand("giveitem", "[itemid]", function(ply, itemid)
    if (SERVER) then
        itemid = itemid or nil
        if (itemid == nil) then
            Amalgam.TerminalNetSend("[Error] ItemID in arguement missing!", "error", ply)
            return
        end

        local item = Amalgam.Items[itemid]
        if (not item) then
            Amalgam.TerminalNetSend("[Error] This ItemID don't exist!", "error", ply)
            return
        end

        ply:AddItem(itemid, 1)
        Amalgam.TerminalNetSend("[Admin] You gave yourself " .. item.Name .. "." , "admin", ply)
      	Amalgam.InsertLog("admin", "[A] " .. ply:Nick() .. " gave themselves " .. item.Name .. ".")
    end
end, "Administrator", {"itemid"})

Amalgam.RegisterCommand("givemoney", "Add or remove money from a player. Use negative values to take", function(ply, target, amount)
    if (SERVER) then
        local targ = ply:FindPlayer(target)
        if (not IsValid(targ)) then
            Amalgam.TerminalNetSend("[Error] Player not found!", "error", ply)
            return
        end

        local money = tonumber(amount)
        if (not money) then
            Amalgam.TerminalNetSend("[Error] Invalid amount. Please enter a number.", "error", ply)
            return
        end

        targ:AddMoney(money)

        local absAmount = math.abs(money)
        local verb = (money >= 0) and "gave" or "took from"
        local symbol = (money >= 0) and "$" or "$"

        targ:Notify(string.format("%s %s %s%d", ply:Nick(), (money >= 0 and "gave you" or "took from you"), symbol, absAmount))
        Amalgam.TerminalNetSend(string.format("[Admin] You %s %s %s%d", verb, targ:Nick(), symbol, absAmount), "admin", ply)
    end
end, "Administrator", {"player, money"})

Amalgam.RegisterCommand("settooltrust", "Set tooltrust to a player[1/2]", function(ply, target, num)
    if (SERVER) then
        local targ = ply:FindPlayer(target)
        if (not IsValid(targ)) then
            Amalgam.TerminalNetSend("[Error] Player not found!", "error", ply)
            return
        end

        local ttlevel = tonumber(num)
        if (not ttlevel) then
            Amalgam.TerminalNetSend("[Error] Invalid tooltrust level, must be a number", "error", ply)
            return
        end

        targ:SetToolTrust(ttlevel)
        if (ttlevel > 0) then
            GAMEMODE:PlayerLoadout(ply)
        end
        targ:Notify("Your tooltrust level was set to '" .. ttlevel .. "'")
        Amalgam.TerminalNetSend("[Admin] You set " .. targ:Nick() .. " tooltrust level to '" .. ttlevel .. "'", "admin", ply)
      	Amalgam.InsertLog("admin", "[A] " .. ply:Nick() .. " set " .. targ:Nick() .. " tooltrust to " .. ttlevel .. ".")
    end
end, "Administrator", {"player, ttlevel"})