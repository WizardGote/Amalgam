local meta = FindMetaTable("Player")

-- Incomplete feature
-- Will get more attention in the future

Amalgam.Zodiacs = {
    ["Aries"] = {
        Symbol = "♈",
        Buff = "Increased melee damage and stamina regeneration.",
        Debuff = "More likely to provoke aggressive NPC reactions."
    },
    ["Taurus"] = {
        Symbol = "♉",
        Buff = "Increased carry weight and slower hunger/thirst drain.",
        Debuff = "Slightly slower movement speed."
    },
    ["Gemini"] = {
        Symbol = "♊",
        Buff = "Faster XP gain and improved persuasion.",
        Debuff = "Slightly less steady hands when aiming."
    },
    ["Cancer"] = {
        Symbol = "♋",
        Buff = "Health regenerates slowly below 50%.",
        Debuff = "Reduced max stamina."
    },
    ["Leo"] = {
        Symbol = "♌",
        Buff = "Increased damage when fighting in a group.",
        Debuff = "Less effective when alone."
    },
    ["Virgo"] = {
        Symbol = "♍",
        Buff = "Faster crafting speed and better repairs.",
        Debuff = "Slightly worse rare loot chances."
    },
    ["Libra"] = {
        Symbol = "♎",
        Buff = "Shop discounts and NPCs react more positively.",
        Debuff = "Less effective at intimidating people."
    },
    ["Scorpio"] = {
        Symbol = "♏",
        Buff = "Higher sneak attack damage and faster crouch speed.",
        Debuff = "NPCs are more suspicious of them."
    },
    ["Sagittarius"] = {
        Symbol = "♐",
        Buff = "Increased movement speed and reduced fall damage.",
        Debuff = "Slightly worse in close-quarters combat."
    },
    ["Capricorn"] = {
        Symbol = "♑",
        Buff = "Earns more money from jobs and gets better rare loot.",
        Debuff = "Slower weapon switching."
    },
    ["Aquarius"] = {
        Symbol = "♒",
        Buff = "Faster hacking and reduced jail time.",
        Debuff = "Reloading takes longer."
    },
    ["Pisces"] = {
        Symbol = "♓",
        Buff = "Harder to detect in darkness, slight night vision boost.",
        Debuff = "Takes more melee damage."
    }
}

function meta:GetZodiac()
    return self:GetNWString("PlayerZodiac", "")
end

function meta:Zodiac()
    return self:GetData("Zodiac", "")
end

function meta:SetZodiac(sign)
    sign = sign or "Aries"
    if (type(sign) ~= "string") then return end
    self:SetData("Zodiac", sign, true)
end
