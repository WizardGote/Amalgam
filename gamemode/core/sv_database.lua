require("mysqloo")

local Database = {
    Connected = false,
    Queue = {},
    Config = {
        SQLHost = "176.9.113.46",
        SQLUser = "GMod1096458",
        SQLPassword = "101096458",
        SQLDB = "GMod1096458",
        SQLPort = 3306 -- MySQL port is 3306 by standard. DO NOT change it unless you know what you are doing!
    }
}

--[[
====================================================================================
                              ADDING NEW COLUMNS TO DATABASE
====================================================================================
Amalgam's MySQL module will automatically handle any custom columns added to 
'Amalgam.PlayerTable'.

Choose the appropriate data type when adding a new column (e.g., `VARCHAR(100)`, `INT`, 
`TINYINT`). 

While not every column requires a corresponding entry in `Amalgam.NetworkVars`, 
you may define one if network synchronization is necessary for your intended feature. 
Only columns that need to be accessed client-side or updated in real-time should have 
a NetworkVar entry—this depends entirely on the specific purpose known to the developer 
adding the column.

Follow the same structure as existing columns in the tables below. Incorrect formatting 
may cause data creation failure or break the entire module.

If you’re still unsure how this works, You may check the documents on my repository. 
Be aware that modifying this file incorrectly will break the entire framework and 
block access to the game
====================================================================================
]]

Amalgam.PlayerTable = {
    Rank = {default = "User", type = "VARCHAR(32)"},
    DonationStatus = {default = "none", type = "VARCHAR(32)"},
    Nickname = {default = "Undefined", type = "VARCHAR(100)"},
    Bio = {default = "Undefined", type = "VARCHAR(2000)"},
    Model = {default = "models/player/kleiner.mdl", type = "VARCHAR(100)"},
    Money = {default = 0, type = "INT"},
    Zodiac = {default = "Undefined", type = "VARCHAR(32)"},
    Inventory = {default = "", type = "VARCHAR(2048)"},
    ToolTrust = {default = 0, type = "TINYINT"},
    Registered = {default = 0, type = "TINYINT"},
    WatchedIntro = {default = 0, type = "TINYINT"}
}

Amalgam.NetworkVars = {
    Rank = {func = "SetNWString", key = "PlayerRank"},
    DonationStatus = { func = "SetNWString", key = "PlayerDonation"},
    Nickname = {func = "SetNWString", key = "PlayerNick"},
    Bio = {func = "SetNWString", key = "PlayerBio"},
    Model = {func = "SetNWString", key = "PlayerModel"},
    Money = {func = "SetNWInt", key = "PlayerMoney"},
    Zodiac = {func = "SetNWString", key = "PlayerZodiac"}
}

Amalgam.BansTable = {
    Length = {default = 0, type = "INT"},
    Reason = {default = "", type = "VARCHAR(300)"},
    Date = {default = "", type = "VARCHAR(20)"},
    BanTime = {default = 0, type = "INT"} 
}

function Database.Connect()
    local cfg = Database.Config
    Database.DB = mysqloo.connect(cfg.SQLHost, cfg.SQLUser, cfg.SQLPassword, cfg.SQLDB, cfg.SQLPort)

    function Database.DB:onConnected()
        Database.Connected = true
        Database.Initialized = true
        MsgC(Color(0, 255, 0), "[Amalgam-MySQL] Connected to database.\n")

        net.Start("nDatabaseStatus")
            net.WriteBool(true)
        net.Broadcast()

        for _, query in ipairs(Database.Queue) do
            Database.Query(query[1], query[2], query[3])
        end

        Database.Queue = {}
        Database.CreatePlayerTable()
        Database.CreateBansTable()

        Amalgam.LoadBans()

        for _, ply in ipairs(player.GetAll()) do
            ply:LoadPlayerData()
        end
    end

    function Database.DB:onConnectionFailed(err)
        Database.Connected = false
        Database.Initialized = false
        MsgC(Color(255, 0, 0), "[Amalgam-MySQL] Connection failed: " .. err .. "\n")

        net.Start("nDatabaseStatus")
            net.WriteBool(false)
        net.Broadcast()

        timer.Simple(10, Database.Connect)
    end

    Database.DB:connect()
end

function Database.CreatePlayerTable()
    local columns = {}

    for col, data in pairs(Amalgam.PlayerTable) do
        table.insert(columns, string.format("%s %s DEFAULT '%s'", col, data.type, data.default))
    end

    local query = string.format("CREATE TABLE IF NOT EXISTS amalgam_players (SteamID VARCHAR(30) NOT NULL PRIMARY KEY, %s)", table.concat(columns, ", "))
    
    Database.Query(query)
end

function Database.CreateBansTable()
    local columns = {}

    for col, data in pairs(Amalgam.BansTable) do
        table.insert(columns, string.format("%s %s DEFAULT '%s'", col, data.type, data.default))
    end

    local query = string.format("CREATE TABLE IF NOT EXISTS amalgam_bans (SteamID64 VARCHAR(32) NOT NULL PRIMARY KEY, %s)", table.concat(columns, ", "))
    Database.Query(query)
end

function Database.Query(sql, onSuccess, onError)
    if (not Database.Connected) then
        table.insert(Database.Queue, {sql, onSuccess, onError})
        return
    end

    local query = Database.DB:query(sql)

    function query:onSuccess(data)
        if (onSuccess) then onSuccess(data) end
    end

    function query:onError(err)
        if (onError) then onError(err) end
    end

    query:start()
end

function Database.Wipe(anyDB, callback)
    if (not Database.Connected) then
        if (callback) then callback(false, "Database not connected.") end
        return
    end

    Database.Query("DELETE FROM " .. anyDB, function()
        if (callback) then callback(true) end
    end, function(err)
        if (callback) then callback(false, err) end
    end)
end

--[[
==============================================================================
                BAN SYSTEM (MEMORY + DATABASE SYNC)
    - Stores all bans in MySQL and saves in memory via Amalgam.BanCache
    - Enforces bans through CheckPassword for instant connect denial
==============================================================================]]

function Amalgam.BanPlayer(ply, length, reason)
    if (not IsValid(ply) or not ply:IsPlayer()) then return end

    local steamID64 = ply:SteamID64()
    local escapedID = Database.DB:escape(steamID64)
    local banReason = Database.DB:escape(string.sub(reason or "No reason provided", 1, 300))
    local banLength = math.max(tonumber(length) or 0, 0)
    local banTime = os.time()
    local timestampStr = os.date("%Y-%m-%d %H:%M:%S", banTime)

    Amalgam.BanCache[steamID64] = {
        Length = banLength,
        Reason = reason,
        Date = timestampStr,
        BanTime = banTime
    }

    local query = string.format("REPLACE INTO amalgam_bans (SteamID64, Length, Reason, Date, BanTime) VALUES ('%s', %d, '%s', '%s', %d)",
        escapedID, banLength, banReason, timestampStr, banTime)

    Database.Query(query, function()
        ply:Kick("Banned: " .. reason)
    end)
end

function Amalgam.UnbanPlayer(steamID64)
    local escapedID = Database.DB:escape(steamID64)
    Database.Query("DELETE FROM amalgam_bans WHERE SteamID64 = '" .. escapedID .. "'", function()
        print("[Amalgam] Unbanned player: " .. escapedID)
    end)
end

Amalgam.BanCache = {}

function Amalgam.LoadBans()
    Database.Query("SELECT * FROM amalgam_bans", function(data)
        Amalgam.BanCache = {}

        for _, ban in ipairs(data or {}) do
            Amalgam.BanCache[ban.SteamID64] = {
                Length = tonumber(ban.Length),
                Reason = ban.Reason,
                Date = ban.Date,
                BanTime = tonumber(ban.BanTime)
            }
        end
    end)
end

hook.Add("CheckPassword", "AmalgamCheckBanMemory", function(steamID64, ip, svPassword, clPassword, playerName)
    local getBan = Amalgam.BanCache[steamID64]
    if (not getBan) then return end

    local now = os.time()
    local isPermanent = tonumber(getBan.Length) == 0
    local expiresAt = getBan.BanTime + (getBan.Length * 60)

    if (isPermanent or now < expiresAt) then
        local timeLeft = isPermanent and "Permanent" or string.NiceTime(expiresAt - now)
        return false, string.format("You are banned.\nReason: %s\nTime left: %s", getBan.Reason, timeLeft)
    else
        Amalgam.UnbanPlayer(steamID64)
    end
end)

--[[
==============================================================================
                PLAYER DATA MANAGEMENT (IN-MEMORY + DATABASE SYNC)
    - Handles loading, saving, and caching player data (PlayerData table)
    - Syncs with SQL and optionally broadcasts NWVars
    - Includes safe fallback for disconnects
==============================================================================]]

local meta = FindMetaTable("Player")

function meta:SaveNewPlayer(callback)
    local data = {SteamID = self:SteamID()}
    local columns, values = {"SteamID"}, {"'" .. Database.DB:escape(data.SteamID) .. "'"}

    for col, info in pairs(Amalgam.PlayerTable) do
        data[col] = info.default
        table.insert(columns, col)
        table.insert(values, "'" .. Database.DB:escape(tostring(info.default)) .. "'")
    end

    local query = string.format("INSERT INTO amalgam_players (%s) VALUES (%s)", table.concat(columns, ", "), table.concat(values, ", "))

    Database.Query(query, function()
        self.PlayerData = data
        if (callback) then callback(true) end
    end, function(err)
        if (callback) then callback(false, err) end
    end)
end

function meta:LoadPlayerData(callback)
    if (not Database.Connected) then
        if (callback) then
            timer.Simple(2, function()
                if (callback) then callback(false, "Database not connected.") end
            end)
        end
        return
    end

    local steamID = Database.DB:escape(self:SteamID())

    Database.Query("SELECT * FROM amalgam_players WHERE SteamID = '" .. steamID .. "'", function(data)
        if (data and data[1]) then
            self.PlayerData = data[1]
            self:ApplyPlayerData()
            if (callback) then callback(true) end
        else
            self:SaveNewPlayer(callback)
        end
    end, function(err)
        if (callback) then callback(false, err) end
    end)
end

function meta:ApplyPlayerData()
    if (not self.PlayerData) then
        print("[Amalgam-MySQL] No PlayerData found for", self:SteamID())
        return
    end

    for col, info in pairs(Amalgam.PlayerTable) do
        self.PlayerData[col] = self.PlayerData[col] or info.default
    end
    
    for col, netVar in pairs(Amalgam.NetworkVars) do
        local value = self.PlayerData[col] or ""

        self[netVar.func](self, netVar.key, value)

    end

    if (self:GetJob() == "Job_None") then
        self:SetModel(self.PlayerData.Model)
    end

    if (IsValid(self:GetHands())) then
        self:SetupHands()
    end
end

function meta:SaveData()
    if (not self.PlayerData) then return end

    local steamID = Database.DB:escape(self:SteamID())
    local updates = {}

    for col, _ in pairs(Amalgam.PlayerTable) do
        local value = self.PlayerData[col] or Amalgam.PlayerTable[col].default
        table.insert(updates, string.format("%s = '%s'", col, Database.DB:escape(tostring(value))))
    end

    local query = string.format("UPDATE amalgam_players SET %s WHERE SteamID='%s'", table.concat(updates, ", "), steamID)
    Database.Query(query)
end

hook.Add("PlayerDisconnected", "SaveDataFailsafe", function(ply)
    if (ply.PlayerData) then ply:SaveData() end
end)

hook.Add("SetupMove", "BlockMovement", function(ply, mv, cmd)
    if (not Database.Connected or not Database.Initialized) then
        mv:SetVelocity(Vector(0, 0, 0))
        mv:SetMaxSpeed(0)
        mv:SetSideSpeed(0)
        mv:SetForwardSpeed(0)
    end
end)

Database.Connect()
