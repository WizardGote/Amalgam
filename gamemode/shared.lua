AddCSLuaFile()

Amalgam = Amalgam or {
    Util = {}, 
    Meta = {}
}

DeriveGamemode("sandbox")
DEFINE_BASECLASS("sandbox")

GM.Name = "Amalgam: Base"
GM.Author = "Ceryx"
GM.Website = "steamcommunity.com/id/atceryx"

function GM:Initialize()
    game.ConsoleCommand("sv_allowupload 0\n")
    game.ConsoleCommand("sv_allowdownload 0\n")
    game.ConsoleCommand("net_maxfilesize 64\n")
    game.ConsoleCommand("sv_kickerrornum 0\n")
    game.ConsoleCommand("sv_maxrate 30000\n")
    game.ConsoleCommand("sv_minrate 5000\n")
    game.ConsoleCommand("sv_maxcmdrate 66\n")
    game.ConsoleCommand("sv_maxupdaterate 66\n")
    game.ConsoleCommand("sv_mincmdrate 30\n")
    
    if(game.IsDedicated()) then
        game.ConsoleCommand("sv_allowcslua 0\n")
    else
        game.ConsoleCommand("sv_allowcslua 1\n")
    end
end

function Amalgam.LoadFile(path)
   	path = string.Replace(path, "\\", "/")
  
    local basePath = path

    if (MODULE and MODULE.Folder and not string.find(path, "^amalgam/")) then
        basePath = MODULE.Folder .. "/" .. path
    end
    
    local fileName = string.GetFileFromFilename(basePath)

    if (string.StartWith(fileName, "sh_")) then
        AddCSLuaFile(basePath)
        include(basePath)
    elseif (string.StartWith(fileName, "sv_")) then
        if SERVER then
            include(basePath)
        end
    elseif (string.StartWith(fileName, "cl_")) then
        AddCSLuaFile(basePath)
        if CLIENT then
            include(basePath)
        end
    else
        AddCSLuaFile(basePath)
        include(basePath)
    end
end

function Amalgam.LoadDirectory(directory)
    if (not file.Exists(directory, "LUA")) then return end

    local files, directories = file.Find(directory .. "/*", "LUA")

    for _, fileName in ipairs(files) do
        Amalgam.LoadFile(directory .. "/" .. fileName)
    end

    for _, folderName in ipairs(directories) do
        Amalgam.LoadDirectory(directory .. "/" .. folderName)
    end
end

function Amalgam.LoadList(path, callback)
    local assignedPath = GM.FolderName .. path
    local files = file.Find(assignedPath .. "/*.lua", "LUA", "namedesc")
    if (#files > 0) then
        for _, v in ipairs(files) do
            if (callback) then
                callback(assignedPath, v)
            end
        end
    else
        if (SERVER) then
            MsgC(Color(255, 0, 0), "[Amalgam] No files found for path: " .. path .. ".\n")
        end
    end
end


Amalgam.LoadFile("core/sv_database.lua")
Amalgam.LoadFile("core/sh_database.lua")
Amalgam.LoadFile("security/sh_moderation.lua")
Amalgam.LoadFile("security/sh_terminal.lua")
Amalgam.LoadFile("core/sh_confighandler.lua")
Amalgam.LoadFile("sh_config.lua")
Amalgam.LoadFile("core/sh_zodiacs.lua")
Amalgam.LoadFile("core/sh_notification.lua")
Amalgam.LoadFile("core/sh_inventory.lua")
Amalgam.LoadFile("core/sh_modules.lua")
Amalgam.LoadFile("core/sh_jobs.lua")
Amalgam.LoadFile("sh_items.lua")
Amalgam.LoadFile("sh_jobs.lua")
Amalgam.LoadFile("core/sv_logs.lua")
Amalgam.LoadFile("sv_net.lua")
Amalgam.LoadFile("player/sv_player.lua")
Amalgam.LoadFile("player/sh_player.lua")
Amalgam.LoadFile("gui/cl_skin.lua")
Amalgam.LoadFile("gui/cl_fonts.lua")
Amalgam.LoadFile("gui/cl_intro.lua")
Amalgam.LoadFile("player/cl_player.lua")
Amalgam.LoadFile("gui/derma/cl_createmenu.lua")
Amalgam.LoadFile("gui/derma/cl_jobsmenu.lua")
Amalgam.LoadFile("gui/derma/cl_scoreboard.lua")
Amalgam.LoadFile("gui/derma/cl_inventory.lua")
Amalgam.LoadFile("gui/derma/cl_database.lua")
Amalgam.LoadFile("gui/derma/cl_terminal.lua")
Amalgam.LoadFile("gui/derma/cl_logsmenu.lua")


function GM:DoAnimationEvent(ply, event, data)
    return self.BaseClass:DoAnimationEvent(ply, event, data)
end
