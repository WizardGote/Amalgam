MODULE.Name = "NetGuard"
MODULE.Description = "Monitors, detects, and logs net message spamming in the server, kicking offending players."
MODULE.Author = "Oriensnox"

--[[----------------------------------------------------------------------------
                        Net Spam Handler

This module tracks net message traffic from players. It detects when a player
sends too many messages within a short time window and kicks them. The event is 
logged and admins are notified.

----------------------------------------------------------------------------]]

local SPAM_LIMIT = 15
local SPAM_WINDOW = 2
local SPAM_COOLDOWN = {}

function MODULE:InitPostEntity()
    SPAM_COOLDOWN = SPAM_COOLDOWN or {}

    if (SERVER) then
        local netReceiver = net.Receive

        function net.Receive(name, func)
            netReceiver(name, function(len, ply)
                if (not ply) then return end

                local time = CurTime()

                if (SPAM_COOLDOWN[ply] and SPAM_COOLDOWN[ply][name]) then
                    local lastTime = SPAM_COOLDOWN[ply][name].lastTime
                    local count = SPAM_COOLDOWN[ply][name].count

                    if (time - lastTime <= SPAM_WINDOW) then
                        SPAM_COOLDOWN[ply][name].count = count + 1

                        if (SPAM_COOLDOWN[ply][name].count >= SPAM_LIMIT) then
                            local offName = ply:Nick()
                            local offSteam = ply:SteamID()
                            local offArgs = "[S] [" .. offSteam .. "] " .. offName .. " was kicked for spamming net messages"
                            
                            ply:Kick("Excessive net message spamming")
                            Amalgam.InsertLog("system", offArgs)
                            return
                        end
                    else
                        SPAM_COOLDOWN[ply][name] = { count = 1, lastTime = time }
                    end
                else
                    SPAM_COOLDOWN[ply] = SPAM_COOLDOWN[ply] or {}
                    SPAM_COOLDOWN[ply][name] = { count = 1, lastTime = time }
                end
                func(len, ply)
            end)
        end
    end
end

