Amalgam.Modules = Amalgam.Modules or {}
Amalgam.DisabledModules = {}

local modulesPath = "amalgam/gamemode/modules"
local moduleBlocklistPath = "amalgam/disabled_modules.txt"

function Amalgam.LoadDisabledModules()
    if not file.Exists(moduleBlocklistPath, "DATA") then
        file.Write(moduleBlocklistPath, "")
    end

    local raw = file.Read(moduleBlocklistPath, "DATA") or ""
    for line in string.gmatch(raw, "[^\r\n]+") do
        Amalgam.DisabledModules[line:Trim()] = true
    end
end

function Amalgam.LoadModule(uniqueID, path, isSingleFile, variable)
    if (Amalgam.DisabledModules[uniqueID]) then return end
    if (hook.Run("ModuleShouldLoad", uniqueID) == false) then return end

    variable = variable or "MODULE"

    local oldModule = _G[variable]
    local MODULE = {
        UniqueID = uniqueID,
        Name = "Unknown",
        Description = "No description provided.",
        Author = "Anonymous",
        Folder = path,
        Hooks = {},
        IsValid = function(self) return true end
    }

    _G[variable] = MODULE

    if (isSingleFile) then
        if not file.Exists(path, "LUA") then
            print("[Amalgam] ERROR: Module file not found: " .. path)
            _G[variable] = oldModule
            return
        end
        Amalgam.LoadFile(path)
    else
        local entryFile = path .. "/sh_module.lua"
        if not file.Exists(entryFile, "LUA") then
            print("[Amalgam] ERROR: Module entry file missing: " .. entryFile)
            _G[variable] = oldModule
            return
        end
        Amalgam.LoadFile(entryFile)
        Amalgam.LoadModuleEntities(path)
    end

    for hookName, func in pairs(MODULE) do
        if (type(func) == "function") then
            hook.Add(hookName, MODULE.UniqueID, function(...)
                return func(MODULE, ...)
            end)
        end
    end

    Amalgam.Modules[uniqueID] = MODULE

    if (MODULE.Initialize) then
        MODULE:Initialize()
    end

    hook.Run("ModuleLoaded", uniqueID, MODULE)

    _G[variable] = oldModule
end

function Amalgam.LoadModuleEntities(path)
    local function LoadGmodEnts(folder, globalName, registerFunc, default, clientOnly)
        local fullPath = path .. "/entities/" .. folder
        if (not file.Exists(fullPath, "LUA")) then return end

        local files = file.Find(fullPath .. "/*.lua", "LUA")

        for _, fileName in ipairs(files) do
            local className = string.StripExtension(fileName)
            local fullFilePath = fullPath .. "/" .. fileName

            _G[globalName] = table.Copy(default)
            _G[globalName].ClassName = className

            if (SERVER) then AddCSLuaFile(fullFilePath) end
            include(fullFilePath)

            if (not clientOnly or CLIENT) then
                registerFunc(_G[globalName], className)
            end

            _G[globalName] = nil
        end
    end

    LoadGmodEnts("entities", "ENT", scripted_ents.Register, {
        Type = "anim",
        Base = "base_gmodentity",
        Spawnable = true
    })

    LoadGmodEnts("weapons", "SWEP", weapons.Register, {
        Primary = {},
        Secondary = {},
        Base = "weapon_base"
    })

    if (effects) then
        LoadGmodEnts("effects", "EFFECT", effects.Register, {}, true)
    end
end

function Amalgam.LoadAllModules(dir)
    local files, directories = file.Find(dir .. "/*", "LUA")

    for _, fileName in ipairs(files) do
        local uniqueID = string.StripExtension(fileName)
        Amalgam.LoadModule(uniqueID, dir .. "/" .. fileName, true)
    end

    for _, folderName in ipairs(directories) do
        local uniqueID = folderName
        Amalgam.LoadModule(uniqueID, dir .. "/" .. folderName, false)
    end
end

function Amalgam.ModuleInitialize()
    for _, module in pairs(Amalgam.Modules) do
        if (module.Initialize) then
            module:Initialize()
        end
    end
end

hook.Add("Initialize", "AmalgamLoadModules", function()
    Amalgam.LoadDisabledModules()
    Amalgam.LoadAllModules(modulesPath)
    Amalgam.ModuleInitialize()
end)

hook.Add("OnReloaded", "AmalgamReloadModules", function()
       Amalgam.LoadDisabledModules()
        Amalgam.LoadAllModules(modulesPath)
        Amalgam.ModuleInitialize()
end)

Amalgam.RegisterCommand("dev_fetchmodules", "Fetch and display all the loaded modules", function(ply)
    local modules = 0
    local msgType = "info"
    local index = {}
    table.insert(index, "Loaded Modules:\n")
    for uniqueID, module in pairs(Amalgam.Modules or {}) do
        modules = modules + 1
        local id = module.UniqueID or uniqueID
        local name = module.Name or "No name provided"
        local description = module.Description or "No description provided"
        local author = module.Author or "Anonymous"
        table.insert(index, "UniqueID: " .. id .. " | Name: " .. name .. " | Description: " .. description .. " | Author: " .. author)  
    end

    table.insert(index, "\n")

    if (modules == 0 ) then
        table.insert(index, "No modules could be fetched or none exist.")
        msgType = "error"
    end

    local disabled = 0

    for id in pairs(Amalgam.DisabledModules or {}) do
        disabled = disabled + 1
        table.insert(index, "- " .. id)
    end

    if (disabled == 0) then
        table.insert(index, "There are no disabled modules.\n")
    end

    table.insert(index, "Total loaded modules: " .. modules)
    local result = table.concat(index, "\n")
    Amalgam.TerminalNetSend(result, msgType, ply)
end, "RootUser")

function Amalgam.SaveDisabledModules()
    local lines = {}
    for id in pairs(Amalgam.DisabledModules) do
        table.insert(lines, id)
    end
    file.Write(moduleBlocklistPath, table.concat(lines, "\n"))
end


Amalgam.RegisterCommand("dev_enablemodule", "Enables a module by an ID", function(ply, uniqueID)
    local id = istable(uniqueID) and uniqueID[1] or uniqueID
    if (not id or id == "") then
        Amalgam.TerminalNetSend("Useage: dev_enablemodule [UniqueID]" , "error", ply)
        return
    end

    Amalgam.DisabledModules[id] = nil
    Amalgam.SaveDisabledModules()
    Amalgam.TerminalNetSend("Module: '[" .. id .. "]' enabled, Server restart is required to apply changes.", "info", ply)

end, "RootUser", {uniqueID})


Amalgam.RegisterCommand("dev_disablemodule", "Disables a module by an ID", function(ply, uniqueID)
    local id = istable(uniqueID) and uniqueID[1] or uniqueID
    if (not id or id == "") then
        Amalgam.TerminalNetSend("Useage: dev_disablemodule [UniqueID]" , "error", ply)
        return
    end

    Amalgam.DisabledModules[id] = true
    Amalgam.SaveDisabledModules()
    Amalgam.TerminalNetSend("Module: '[" .. id .. "]' disabled, Server restart is required to apply changes", "info", ply)

end, "RootUser", {uniqueID})
