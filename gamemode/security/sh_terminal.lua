Amalgam.Commands = {}

function Amalgam.RegisterCommand(name, desc, func, requiredRank, requiredArgs, isHidden)
    Amalgam.Commands[name] = {
        func = func,
        desc = desc,
        requiredRank = requiredRank or nil,
        requiredArgs = requiredArgs or {},
        isHidden = isHidden == true
    }
end

if (SERVER) then
    file.CreateDir("amalgam")
    Amalgam.RootUserFile = "amalgam/amalgam_rootuser.txt"
    Amalgam.RootPasswordFile = "amalgam/amalgam_root.txt"

    function Amalgam.ParseArgs(input)
        local args = {}
        local pattern = "%b\"\""
        local temp = {}

        for quoted in string.gmatch(input, pattern) do
            table.insert(temp, string.sub(quoted, 2, -2))
            input = string.Replace(input, quoted, "[[Q" .. #temp .. "]]")
        end

        for word in string.gmatch(input, "%S+") do
            local newArgs = string.match(word, "%[%[Q(%d+)%]%]")
            if (newArgs) then
                table.insert(args, temp[tonumber(newArgs)])
            else
                table.insert(args, word)
            end
        end

        return args
    end

    function Amalgam.ExecuteCommand(input, ply)
        local args = Amalgam.ParseArgs(input)
        local cmd = args[1]:sub(2)
        table.remove(args, 1)

        if (not Amalgam.Commands[cmd]) then
            Amalgam.TerminalNetSend("[Error] Unknown command: " .. cmd, "error")
            return
        end

        local command = Amalgam.Commands[cmd]

        if (command.requiredRank and not ply:HasRank(command.requiredRank)) then
            Amalgam.TerminalNetSend("[Error] Insufficient permissions! Required Rank: " .. command.requiredRank, "error")
            return
        end

        if (#args < #command.requiredArgs) then
            local missingArg = command.requiredArgs[#args + 1]
            Amalgam.TerminalNetSend("[Error] Missing argument: " .. missingArg, "error")
            return
        end

        command.func(ply, unpack(args))
    end

    net.Receive("nTerminalCommand", function(len, ply)
        local cmd = net.ReadString()
        Amalgam.ExecuteCommand(cmd, ply)
    end)

    function Amalgam.TerminalNetSend(text, msgType, target)
        if (not text or text == "") then return end
        if (not msgType) then msgType = "info" end

        net.Start("nTerminalAddHistory")
        net.WriteString(text)
        net.WriteString(msgType)

        if (IsValid(target)) then
            net.Send(target)
        else
            net.Broadcast()
        end
    end

    function Amalgam.RootUserStatus()
        return file.Exists(Amalgam.RootUserFile, "DATA")
    end

    function Amalgam.GenerateRootPassword()
        if (Amalgam.RootUserStatus()) then return end

        local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+"
        local password = ""
        for i = 1, 20 do
            password = password .. chars[math.random(#chars)]
        end

        file.Write(Amalgam.RootPasswordFile, password)
        print("[Amalgam] No Root User detected! Root access password generated. Check data/amalgam_root.txt")
    end

    function Amalgam.DeleteRootPassword()
        if (file.Exists(Amalgam.RootPasswordFile, "DATA")) then
            file.Delete(Amalgam.RootPasswordFile)
        end
    end

    Amalgam.GenerateRootPassword()
end