MODULE.Name = "Chatbox"
MODULE.Description = "A replacement of the old chatbox to something more modern"
MODULE.Author = "Oriensnox"

Amalgam.LoadFile("sv_chat.lua")
Amalgam.LoadFile("derma/cl_chat.lua")

Amalgam.ChatTypes = {}

function Amalgam:RegisterChatType(id, data)
    self.ChatTypes[id] = {
        Label = data.Label or string.upper(id),
        Color = data.Color or Color(255, 255, 255),
        CanHear = data.CanHear,
        Global = data.Global or false,
        Private = data.Private or false,
        Format = data.Format
    }
end

Amalgam:RegisterChatType("ic", {
    Label = "IC",
    Color = Color(255, 128, 0),
    CanHear = function(speaker, listener)
        return (speaker:GetPos():Distance(listener:GetPos()) <= 300)
    end,
    Format = function(ply, msg)
        return {
            Color(255, 128, 0), ply:GetCharNickname(),
            Color(200, 200, 200), " says '" .. msg .. "'"
        }
    end
})

Amalgam:RegisterChatType("ooc", {
    Label = "OOC",
    Color = Color(255, 168, 103),
    Global = true,
    Format = function(ply, msg)
        return {
            Color(255, 168, 103), "[OOC] ",
            Color(200, 200, 200), ply:Nick() .. ": " .. msg
        }
    end
})

Amalgam:RegisterChatType("looc", {
    Label = "LOOC",
    Color = Color(255, 168, 103),
    Global = true,
    CanHear = function(speaker, listener)
        return (speaker:GetPos():Distance(listener:GetPos()) <= 300)
    end,
    Format = function(ply, msg)
        return {
            Color(255, 168, 103), "[LOOC] ",
            Color(200, 200, 200), ply:Nick() .. ": " .. msg
        }
    end
})

Amalgam:RegisterChatType("y", {
    Label = "YELL",
    Color = Color(255, 0, 0),
    CanHear = function(speaker, listener)
        return (speaker:GetPos():Distance(listener:GetPos()) <= 600)
    end,
    Format = function(ply, msg)
        return {
            Color(255, 0, 0), ply:GetCharNickname() .. " YELLS '" .. msg:upper() .. "'"
        }
    end
})

Amalgam:RegisterChatType("w", {
    Label = "WHISPER",
    Color = Color(0, 200, 255),
    CanHear = function(speaker, listener)
        return (speaker:GetPos():Distance(listener:GetPos()) <= 150)
    end,
    Format = function(ply, msg)
        return {
            Color(0, 200, 128), ply:GetCharNickname() .. " whispers '" .. msg:lower() .. "'"
        }
    end
})

Amalgam:RegisterChatType("pm", {
    Label = "PM",
    Color = Color(200, 150, 255),
    Private = true,
    Format = function(ply, msg)
        local name, content = msg:match("^(%S+)%s+(.+)$")
        if (not name or not content) then
            ply:Notify("Invalid Name Given!")
            return true
        end

        local target = ply:FindPlayer(name)
        if (not IsValid(target)) then
            ply:Notify("No target found by: " .. name .. ".")
            return true
        end

        Amalgam.SendFormattedMessage({ply, target}, {
            Color(200, 150, 255), "[PM] from '" .. ply:Nick() .. "': ",
            Color(255, 255, 255), content
        })

        return true
    end
})

Amalgam:RegisterChatType("r", {
    Label = "RADIO",
    Color = Color(0, 255, 0),
    CanHear = function(speaker, listener)
        return speaker:GetJob() == listener:GetJob()
    end,
    Format = function(ply, msg)
        local jobData = Amalgam.Jobs[ply:GetJob()]

        if (not jobData or not jobData.CanRadio) then
            ply:ChatNotify("You can't use a radio on this job.", Color(200, 0, 0))
            return true
        end

        local jobName = jobData.Name or "Unknown"

        ply:EmitSound("npc/combine_soldier/vo/off" .. math.random(1, 3) .. ".wav", 75, 100)

        for _, v in ipairs(player.GetAll()) do
            if (ply:GetJob() == v:GetJob()) then
                v:EmitSound("npc/combine_soldier/vo/off" .. math.random(1, 3) .. ".wav", 75, 100)
            end
        end

        return {
            Color(0, 255, 0), "[Radio - " .. jobName .. "] ",
            Color(255, 255, 255), ply:Nick() .. ": " .. msg
        }
    end
})

Amalgam:RegisterChatType("a", {
    Label = "ADMIN",
    Color = Color(200, 0, 0),
    CanHear = function(speaker, listener)
        return listener:HasRank("Moderator")
    end,
    Format = function(ply, msg)

        return {
            Color(200, 0, 0), "[Admin] " .. ply:Nick() .. ": " .. msg
        }
    end
})

Amalgam:RegisterChatType("me", {
    Label = "ACTING",
    Color = Color(128, 128, 255),
    CanHear = function(speaker, listener)
        return (speaker:GetPos():Distance(listener:GetPos()) <= 300)
    end,
    Format = function(ply, msg)
        return {
            Color(128, 128, 255), ply:GetCharNickname() .. " " .. msg
        }
    end
})

if (CLIENT) then

	net.Receive("nChatMessage", function()
        local count = net.ReadUInt(8)
        local str = {}

        for i = 1, count do
            local isColor = net.ReadBool()
            if (isColor) then
                table.insert(str, net.ReadColor())
            else
                table.insert(str, net.ReadString())
            end
        end

        local plainText = ""
        for _, v in ipairs(str) do
            if (isstring(v)) then
                plainText = plainText .. v
            end
        end

        print(plainText)

        Amalgam.ChatLines = Amalgam.ChatLines or {}
        table.insert(Amalgam.ChatLines, {
            str = str,
            time = CurTime()
        })

        if (#Amalgam.ChatLines > 10) then
            table.remove(Amalgam.ChatLines, 1)
        end
    end)

    function MODULE:OnPauseMenuShow()
        if Amalgam.ChatOpen then
            Amalgam.Chatbox:CloseChatbox()
            return false
        end
    end

    function MODULE:HUDShouldDraw(element)
        if (element == "CHudChat")then
            return false
        end
    end

	function MODULE:HUDPaint()
        if (Amalgam.HideHUDChat) then return end

        local chatLines = Amalgam.ChatLines
        if (not istable(chatLines)) then return end

        local y = ScrH() - 230
        local lineHeight = 23
        local visibleLines = 0

        for i = #chatLines, 1, -1 do
            local msg = chatLines[i]
            if (not msg or not msg.time) then continue end

            local alpha = 255
            if (not Amalgam.ChatOpen) then
                alpha = math.Clamp(255 - ((CurTime() - msg.time) * 10), 0, 255)
            end

            if (alpha > 0) then visibleLines = visibleLines + 1 end
        end

        for i = #chatLines, 1, -1 do
            local msg = chatLines[i]
            if (not msg or not msg.time) then continue end

            local alpha = 255
            if (not Amalgam.ChatOpen) then
                alpha = math.Clamp(255 - ((CurTime() - msg.time) * 10), 0, 255)
            end

            if (alpha <= 0) then continue end

            local x = 30
            local currentColor = Color(255, 255, 255)

            if (istable(msg.str)) then
                for _, row in ipairs(msg.str) do
                    if (IsColor(row)) then
                        currentColor = Color(row.r, row.g, row.b)
                    elseif (isstring(row)) then
                        surface.SetFont("Amalgam.ChatboxLabel")

                        surface.SetTextColor(0, 0, 0, alpha)
                        surface.SetTextPos(x + 1, y + 1)
                        surface.DrawText(row)

                        surface.SetTextColor(currentColor.r, currentColor.g, currentColor.b, alpha)
                        surface.SetTextPos(x, y)
                        surface.DrawText(row)

                        x = x + surface.GetTextSize(row)
                    end
                end
            elseif (msg.text and msg.color) then
                surface.SetFont("Amalgam.ChatboxLabel")

                surface.SetTextColor(0, 0, 0, alpha)
                surface.SetTextPos(31, y + 1)
                surface.DrawText(msg.text)

                surface.SetTextColor(msg.color.r, msg.color.g, msg.color.b, alpha)
                surface.SetTextPos(30, y)
                surface.DrawText(msg.text)
            end

            y = y - lineHeight
        end
    end

	function MODULE:PlayerBindPress(ply, bind, pressed)
	    if (not IsValid(ply)) then return end
	    if (not pressed) then return end

	    if (pressed and bind == "messagemode") then
	        if (IsValid(Amalgam.Chatbox)) then
	            Amalgam.Chatbox:Remove()
	        end
	        Amalgam.Chatbox = vgui.Create("AmalgamChatBox")
	        Amalgam.Chatbox:OpenChatbox()
	        return true
	    end
	end
end

local meta = FindMetaTable("Player")

function meta:SetTyping(bool)
    self:SetNWBool("PlayerTyping", bool)
end

function meta:IsTyping()
    return self:GetNWBool("PlayerTyping", false)
end