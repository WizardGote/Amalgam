MODULE.Name = "Gatekeeper"
MODULE.Description = "Restrict server access to specific users and/or reserve slots for priority players"
MODULE.Author = "Oriensnox"

if (SERVER) then
	-- Enables or disables the Gatekeeper access control system (true = enabled, false = disabled).
	-- When enabled, only users listed in 'MODULE.KeyHolders' will be allowed to join the server.
	-- No server password is required when Gatekeeper is active.
	MODULE.GateKeeper = false

	-- Message shown to rejected users when Gatekeeper denies access.
	MODULE.GateKeeperMsg = "Server access is temporarily restricted. Please try again later"

	-- Reserved slot system (independent of Gatekeeper).
	-- If greater than 0, this reserves slots exclusively for users in 'MODULE.KeyHolders'.
	-- If set to 0, no reserved slots are enforced—even if 'MODULE.KeyHolders' contains entries.
	MODULE.ReservedSlots = 0

	-- Whitelisted SteamID64s that are allowed entry when Gatekeeper is active,
	-- and/or prioritized when reserved slots are in use.
	-- IMPORTANT: Use SteamID64 format only.
	MODULE.KeyHolders = {
		--"76561198000000000", -- Example SteamID
		--"76561198000000001",
		--"76561198000000002"
	}

	function MODULE:CheckPassword(steamid, networkid, svpass, pass, name)
	    if (self.GateKeeper == true) then
	        if (not table.HasValue(self.KeyHolders, steamid)) then
	            return false, self.GateKeeperMsg
	        end
	    end

	    if (#player.GetAll() >= (game.MaxPlayers() - self.ReservedSlots)) then
	        if (self.ReservedSlots == 0) then
	            return false
	        elseif (not table.HasValue(self.KeyHolders, steamid)) then
	            return false
	        end
	    end

	    return true
	end
end