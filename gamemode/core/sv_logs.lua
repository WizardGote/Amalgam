Amalgam.LogCategories = Amalgam.LogCategories or {}

local baseDir = "amalgam/logs"

function Amalgam.InsertLog(category, message)
    if (not file.IsDir(baseDir, "DATA")) then
        file.CreateDir(baseDir)
    end

    local timestamp = os.time()
    local formattedTime = os.date("%d/%m/%Y - %H:%M:%S", timestamp)
    local row = string.format("[%s] %s", formattedTime, message)
    
    local categoryFile = string.format("%s/%s.txt", baseDir, string.lower(category))
    local existing = ""

    if (file.Exists(categoryFile, "DATA")) then
        existing = file.Read(categoryFile, "DATA") .. "\n"
    end

    file.Write(categoryFile, existing .. row)
end

function Amalgam.ReadLogs(category, fromTime, toTime)
    local path = string.format("amalgam/logs/%s.txt", string.lower(category))
    if not file.Exists(path, "DATA") then return {} end

    local logs = {}
    local rows = string.Explode("\n", file.Read(path, "DATA"))

    for _, row in ipairs(rows) do
        local timeStamp, msg = row:match("^%[(.-)%]%s(.+)$")
        if timeStamp and msg then
            local ts = os.time({
                day = tonumber(timeStamp:sub(1, 2)),
                month = tonumber(timeStamp:sub(4, 5)),
                year = tonumber(timeStamp:sub(7, 10)),
                hour = tonumber(timeStamp:sub(14, 15)),
                min = tonumber(timeStamp:sub(17, 18)),
                sec = tonumber(timeStamp:sub(20, 21))
            })

            if ts >= fromTime and ts <= toTime then
                table.insert(logs, {
                    Timestamp = ts,
                    Category = category,
                    Message = msg
                })
            end
        end
    end

    return logs
end

net.Receive("nSendChatLog", function(len, ply)
    local log = net.ReadString()
    Amalgam.InsertLog("Chatbox", log)
end)

Amalgam.RegisterCommand("dev_getlogs", "Instructions: [category] [date-##/##/####]", function(ply, category, date)
    if not SERVER then return end

    local d, m, y = date:match("(%d+)/(%d+)/(%d+)")
    if not d or not m or not y then
        Amalgam.TerminalNetSend("[Error] Invalid date format. Use DD/MM/YYYY.", "error", ply)
        return
    end

    local startTime = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0 })
    local endTime = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 23, min = 59, sec = 59 })

    local results = Amalgam.ReadLogs(category, startTime, endTime)

    if #results == 0 then
        Amalgam.TerminalNetSend("[Info] No logs found for '" .. category .. "' on " .. date, "info", ply)
        return
    end

    net.Start("nOpenLogViewer")
        net.WriteTable(results)
    net.Send(ply)
end, "RootUser", {"category", "date"})
