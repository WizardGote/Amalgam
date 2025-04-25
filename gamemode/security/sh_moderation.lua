local meta = FindMetaTable("Player")

--[[
====================================================================================
                                HIERARCHY EXPLANATION
====================================================================================

Privilege inheritance always applies from a designated rank upward in the hierarchy.
This means that any privilege assigned to a specific rank will also be inherited by all
higher ranks above it.

Example: If you grant Noclip access to all admin ranks, apply it to the 'Moderator' rank
via meta:HasRank("Moderator") — both "Administrator" and "RootUser" will inherit this
privilege automatically.

Another example: If you restrict the "Remover" tool to "Administrator", only
Administrators and RootUsers will have access, while Moderators will not inherit this
privilege.

Using meta:HasRank("Rank") provides a powerful way to manage rank-based privileges,
but it is also dangerous — improper configuration may unintentionally grant privileges
to unintended ranks.

Refer to the next comment section for guidance on preventing privilege inheritance
when exclusive access is required.

To assign a privilege to a specific rank without inheritance, use meta:Rank() and
compare directly to the desired rank.

This ensures that the privilege remains exclusive to the specified rank and is not
inherited by higher ones.

Example: Granting Event Coordinators access to the spawn menu while restricting it
to Tool Trusted users and Administrators only:
    meta:Rank() == "EventCoordinator"

====================================================================================
                           SECURITY & METATABLE USAGE WARNING
====================================================================================

For security reasons, never use meta:GetRank() for moderation or permission checks.
Always use meta:Rank() or meta:HasRank() instead, as they retrieve actual values
from the database.

meta:GetRank() is strictly for display purposes and should not be trusted in critical
logic. Using it for permission checks creates exploitable logic paths.

This warning applies to all metatables in this module:
    - DonationStatus
    - Money
    - Nickname
    - ToolTrust

Misusing these can lead to exploitable behavior and open the door to abuse
by malicious users.

====================================================================================
]]

Amalgam.RankHierarchy = {
    User = 1,
    EventCordinator = 2,
    Moderator = 3,
    Administrator = 4,
    RootUser = 5
}

-- Client-side only, UI
function meta:GetRank()
    return self:GetNWString("PlayerRank", "User")
end

-- Server-side only, used for logic
function meta:Rank()
    local playerRank = self:GetData("Rank", "User")

    if (not Amalgam.RankHierarchy[playerRank]) then
        return "User"
    end

    return playerRank
end

function meta:SetRank(rank)
    if (not Amalgam.RankHierarchy[rank]) then
        rank = "User"
    end
    self:SetData("Rank", rank, true)
end

function meta:HasRank(rank)
    local playerRank = self:GetData("Rank", "User")
    if (Amalgam.RankHierarchy[playerRank] and Amalgam.RankHierarchy[rank]) then
        return Amalgam.RankHierarchy[playerRank] >= Amalgam.RankHierarchy[rank]
    end
    return false
end

function meta:CanActOn(targ)
    if (not IsValid(targ) or not targ:IsPlayer()) then return false end

    local myRank = Amalgam.RankHierarchy[self:GetData("Rank", "User")] or 0
    local theirRank = Amalgam.RankHierarchy[targ:GetData("Rank", "User")] or 0

    return myRank > theirRank
end

--[[
===================================================================================================
    Donation privilege inheritance follows the same logic as administrative ranks.
    Any privilege granted to a specific donor rank will also be inherited by all higher donor ranks.
    Refer to 'Hierarchy Explaination' on privilege inheritance for more information.
    Use meta:GetDonorTier() for personal privileges (e.g., displaying icons).  
    Use meta:DonorTier() for inherited privileges (e.g., faction whitelists).
======================================================================================================
]]

Amalgam.DonorsHierarchy = {
    None = 1,
    VIP = 2,
    Silver = 3,
    Gold = 4
}

function meta:GetDonorTier()
    return self:GetNWString("PlayerDonation", "None")
end

function meta:DonorTier()
    local playerTier = self:GetData("DonationStatus", "None")

    if (not Amalgam.DonorsHierarchy[playerTier]) then
        return "None"
    end

    return playerTier
end

function meta:HasDonorTier(tier)
    local playerTier = self:GetData("DonationStatus", "None")
    if (Amalgam.DonorsHierarchy[playerTier] and Amalgam.DonorsHierarchy[tier]) then
        return Amalgam.DonorsHierarchy[playerTier] >= Amalgam.DonorsHierarchy[tier]
    end
    return false
end

function meta:SetDonorTier(tier)
    if (not Amalgam.DonorsHierarchy[tier]) then
        tier = "None"
    end
    self:SetData("DonationStatus", tier, true)
end

-- Determines if the character has completed initial setup (character creation)
-- Returns 1 if registered, 0 if not. Used to suppress the character creation screen
function meta:IsRegistered()
    return self:GetData("Registered", 0)
end

-- Sets the character's registration state
-- Accepts only binary values: 0 (not registered) or 1 (registered)
-- Any invalid value will default to 0 to maintain data integrity
function meta:SetRegistered(val)
    local numTable = {0, 1}

    if(not table.HasValue(numTable, val)) then
        val = 0
    end

    self:SetData("Registered", val)
end

-- Money -- 
function meta:GetMoney()
    return self:GetNWInt("PlayerMoney", 0) 
end

function meta:Money()
    return self:GetData("Money", 0) 
end

function meta:AddMoney(val)
    local newVal = math.floor(self:Money() + val)
    self:SetData("Money", newVal, true)
end

-- Character Details -- 
function meta:GetCharNickname()
    return self:GetNWString("PlayerNick", self:Nick())
end

function meta:CharNickname()
    return self:GetData("Nickname", self:Nick())
end

function meta:SetCharNickname(name)
    local newName = name or "Undefined"
    self:SetData("Nickname", newName, true)
end

function meta:GetCharBio()
    return self:GetNWString("PlayerBio", "N/A")
end

function meta:CharBio()
    return self:GetData("Bio", "N/A")
end

function meta:SetCharBio(bio)
    local newBio = bio or "N/A"
    self:SetData("Bio", newBio, true)
end

function meta:CharModel()
    return self:GetData("Model", "models/player/kleiner.mdl")
end

function meta:SetCharModel(model, save)
    if (not isstring(model) or model == "") then return end
    self:SetModel(model)
    if (save) then
        self:SetData("Model", model)
    end
end

-- ToolTrust Premissions -- 
function meta:GetToolTrust()
    return self:GetNWInt("PlayerToolTrust", 0)
end

function meta:ToolTrust()
    return self:GetData("ToolTrust", 0)
end

function meta:SetToolTrust(val)
    local numTable = {0, 1, 2}

    if(not table.HasValue(numTable, val)) then
        val = 0
    end

    self:SetData("ToolTrust", val, true)
end

-- Utility function for player resolution via multiple identifiers
-- Primarily used by the terminal system to track players for command execution
-- Supports lookup via: SteamID, Steam Nickname, Character Name
function meta:FindPlayer(str)
    if (str == "") then return end

    for _, v in ipairs(player.GetAll()) do
        if (v:SteamID() == str or
            string.find(string.lower(v:Nick()), string.lower(str)) or
            string.find(string.lower(v:CharNickname()), string.lower(str))) then
            return v
        end
    end
end

-- Sandbox Restrictions --

function GM:PlayerSpawnProp(ply, model, ent)
    if (ply:ToolTrust() >= 1 or ply:HasRank("Moderator")) then return true end
    return false
end

function GM:PlayerSpawnedProp(ply, model, ent) 
    if (IsValid(ent)) then
        ent:SetNWEntity("PropOwner", ply)
    end
end
 
function GM:CanTool(ply, tr, tool)
    local ent = tr.Entity

    -- Admins bypass all checks
    if (ply:HasRank("Administrator")) then return true end

    -- Deny if invalid or world
    if (not IsValid(ent) or ent:IsWorld()) then
        return false
    end

    -- Deny if it's a static prop (unownable world prop)
    local class = ent:GetClass()
    if class:StartWith("func_") or class:StartWith("env_") or class:StartWith("prop_static") then
        return false
    end

    -- Optional: block remover for non-admins
    if (tool == "remover" and not ply:HasRank("Administrator")) then
        return false
    end

    -- Owner check
    local owner = ent:GetNWEntity("PropOwner")
    if (owner == ply or ply:HasRank("Moderator")) then
        return true
    end

    return false
end

function GM:PhysgunPickup(ply, ent)
    if (ent:IsWorld() and not ply:HasRank("Administrator")) then return false end
    local propOwner = ent:GetNWEntity("PropOwner")
  
  	if (ent:IsPlayer()) then
        if (not ply:HasRank("Moderator")) then return false end
        if (ply:Rank() ~= "RootUser" and ent:HasRank("Administrator")) then return false end
        return true
    end
  
    if (propOwner == ply or ply:HasRank("Moderator")) then return true end
    return false
end

function GM:PlayerNoClip(ply)
    if (ply:HasRank("Moderator")) then return true end
    return false
end

function GM:PlayerSpawnSWEP(ply)
    if (ply:HasRank("RootUser")) then return true end
    return false
end

function GM:PlayerGiveSWEP(ply)
    if (ply:HasRank("RootUser")) then return true end
    return false
end

function GM:PlayerSpawnVehicle(ply)
    if (ply:HasRank("RootUser")) then return true end
    return false
end

function GM:PlayerSpawnSENT(ply)
    if(ply:HasRank("Administrator")) then return true end
    return false
end

function GM:PlayerSpawnNPC(ply)
    if (ply:HasRank("Administrator")) then return true end
    return false
end

function GM:CanProperty(ply)
    if (ply:HasRank("RootUser")) then return true end
    return false
end

function GM:CanCleanup(ply)
    if (ply:HasRank("RootUser")) then return true end
    return false
end

function GM:CanPlayerSuicide(ply)
    if (ply:HasRank("Administrator")) then return true end 
    return false
end

function GM:CanPlayerUnfreeze(ply, ent, phys)
    if (not IsValid(ent) or ent:IsWorld()) then return false end
    local propOwner = ent:GetNWEntity("PropOwner")
    if (ply:HasRank("Moderator")) then return true end
    if (propOwner ~= ply) then return false end
    return true
end

