if (CLIENT) then return end

util.AddNetworkString("nChatSend")
util.AddNetworkString("nChatMessage")

function Amalgam.SendFormattedMessage(targets, str)
    if (not istable(targets)) then
        targets = {targets}
    end

    net.Start("nChatMessage")
        net.WriteUInt(#str, 8)
        for _, row in ipairs(str) do
            if (IsColor(row)) then
                net.WriteBool(true)
                net.WriteColor(row)
            else
                net.WriteBool(false)
                net.WriteString(row)
            end
        end
    net.Send(targets)
end

function Amalgam.ParseMessage(ply, text)
    if (not isstring(text) or text == "") then return end
    if (#text > 512) then return end

    ply.NextChat = ply.NextChat or 0
    if (CurTime() < ply.NextChat) then return end
    ply.NextChat = CurTime() + 1.5

    local args = string.Explode(" ", text)
    local prefix = args[1]

    if (prefix == "//") then
        prefix = "/ooc"
    elseif (prefix == ".//") then
        prefix = "/looc"
    end

    if (string.sub(prefix, 1, 1) == "/") then
        prefix = string.sub(prefix, 2)
        table.remove(args, 1)
    else
        prefix = "ic"
    end

    local msg = table.concat(args, " ")
    if (msg == "" or string.Trim(msg) == "") then return end

    local chatType = Amalgam.ChatTypes[prefix] or Amalgam.ChatTypes["ic"]

    local formatted
    if (chatType.Format) then
        local result = chatType.Format(ply, msg)

        if (result == true) then return end
        if (istable(result)) then
            formatted = result
        end
    end

    if (not formatted) then
        formatted = {
            chatType.Color, ply:CharNickname() .. ": " .. msg
        }
    end

    local recipients = {}
    for _, v in ipairs(player.GetAll()) do
        if (chatType.Global or (chatType.CanHear and chatType.CanHear(ply, v))) then
            table.insert(recipients, v)
        end
    end

    if (not table.HasValue(recipients, ply)) then
        table.insert(recipients, ply)
    end

    Amalgam.SendFormattedMessage(recipients, formatted, prefix)
end

function Amalgam.ChatNotifyAll(ccol, cat, mcol, msg)
	Amalgam.SendFormattedMessage(player.GetAll(), {
	ccol, cat,
	mcol, msg
	})  
end

function MODULE:PlayerInitialSpawn(ply)
    timer.Simple(1, function()
        if (not IsValid(ply)) then return end

        Amalgam.SendFormattedMessage(player.GetAll(), {
            Color(100, 255, 100), "[Join] ",
            Color(255, 255, 255), ply:Nick() .. " has joined the game."
        })
    end)
end

function MODULE:PlayerDisconnected(ply)
	Amalgam.SendFormattedMessage(player.GetAll(), {
		Color(255, 100, 100), "[Leave] ",
		Color(255, 255, 255), ply:Nick() .. " has disconnected from the server."
	})
end

net.Receive("nChatSend", function(_, ply)
    local text = net.ReadString()
    Amalgam.ParseMessage(ply, text)
end)

local meta = FindMetaTable("Player")

function meta:ChatNotify(msg, color)
    if (not isstring(msg)) then return end

    Amalgam.SendFormattedMessage(self, {
        color or Color(255, 200, 100),
        msg
    })
end