-- Sentry: перехват ошибок скрипта и отправка в Sentry

function init(opts)
    if not opts or not opts.dsn or opts.dsn == "" then return end
    local key, host, project_id = string.match(opts.dsn, "https://(.+)@(.+)/(%d+)")
    if not key or not host or not project_id then return end
    local sentry_url = string.format(
        "https://%s/api/%s/store/?sentry_key=%s&sentry_version=7&sentry_data=",
        host, project_id, key
    )
    local target_id = opts.script_id or 0
    local target_name = (opts.script_name or "unknown"):gsub('"', '\\"'):gsub("%%", "%%%%")
    local target_path = (opts.script_path or ""):gsub("\\", "\\\\"):gsub("%%", "%%%%")
    local sentry_url_safe = sentry_url:gsub("%%", "%%%%")

    local reporter_src = string.format([[
local target_id = %d
local target_name = "%s"
local target_path = "%s"
local sentry_url = "%s"

require("lib.moonloader")
script_name("sentry-error-reporter-for: " .. target_name .. " (ID: " .. target_id .. ")")
script_description("Перехватывает вылеты скрипта и отправляет в Sentry.")

local enc = require("encoding")
enc.default = "CP1251"
local utf8 = enc.UTF8
local json = require("json")
local logger_name = "moonloader"

function getVolumeSerial()
    local ffi = require("ffi")
    ffi.cdef("int __stdcall GetVolumeInformationA(const char* lpRootPathName, char* lpVolumeNameBuffer, uint32_t nVolumeNameSize, uint32_t* lpVolumeSerialNumber, uint32_t* lpMaximumComponentLength, uint32_t* lpFileSystemFlags, char* lpFileSystemNameBuffer, uint32_t nFileSystemNameSize);")
    local out = ffi.new("unsigned long[1]", 0)
    ffi.C.GetVolumeInformationA(nil, nil, 0, out, nil, nil, nil, 0)
    return out[0]
end

function getNick()
    local ok, nick = pcall(function()
        local _, pid = sampGetPlayerIdByCharHandle(PLAYER_PED)
        return sampGetPlayerNickname(pid)
    end)
    return ok and nick or "unknown"
end

function getRealPath(path)
    if doesFileExist(path) then return path end
    local j = -1
    local wd = getWorkingDirectory()
    while j * -1 ~= string.len(path) + 1 do
        local part = string.sub(path, 0, j)
        local from, to = string.find(string.sub(wd, -string.len(part), -1), part)
        if from and to then return wd:sub(0, -1 * (from + string.len(part))) .. path end
        j = j - 1
    end
    return path
end

function url_encode(s)
    if not s then return "" end
    s = s:gsub("\n", "\r\n")
    s = s:gsub("([^%%w %%-%%_%%.%~])", function(c) return string.format("%%%02X", string.byte(c)) end)
    s = s:gsub(" ", "+")
    return s
end

function parseType(msg)
    local first = msg:match("([^\n]*)\n?")
    local exc = first and first:match("^.+:%d+: (.+)")
    return exc or "Exception"
end

function fileLine(path, lineNo)
    lineNo = tonumber(lineNo)
    if doesFileExist(path) then
        local n = 0
        for line in io.lines(path) do
            n = n + 1
            if n == lineNo then return line end
        end
        return nil
    end
    return path .. tostring(lineNo)
end

function parseStacktrace(msg)
    local frames = { frames = {} }
    local list = {}
    for line in msg:gmatch("([^\n]*)\n?") do
        local path, lineNo = line:match("^ *(.-):(%d+):")
        if not path then path, lineNo = line:match("^ *%.%.%.(.-):(%d+)") if path then path = getRealPath(path) end end
        if path and lineNo then
            lineNo = tonumber(lineNo)
            local frame = {
                in_app = (target_path == path),
                abs_path = path,
                filename = path:match("^.+\\(.+)$") or path,
                lineno = lineNo
            }
            if lineNo ~= 0 then
                frame["pre_context"] = { fileLine(path, lineNo-3), fileLine(path, lineNo-2), fileLine(path, lineNo-1) }
                frame["context_line"] = fileLine(path, lineNo)
                frame["post_context"] = { fileLine(path, lineNo+1), fileLine(path, lineNo+2), fileLine(path, lineNo+3) }
            end
            local fn = line:match("in function '(.-)'")
            if fn then frame["function"] = fn
            else
                local a, b = line:match("in function <.* *(.-):(%d+)>")
                if a and b then frame["function"] = fileLine(getRealPath(a), b)
                elseif #list == 0 then frame["function"] = msg:match("%[C%]: in function '(.-)'\n") end
            end
            table.insert(list, frame)
        end
    end
    for j = #list, 1, -1 do table.insert(frames.frames, list[j]) end
    if #frames.frames == 0 then return nil end
    return frames
end

function onSystemMessage(msg, msgType, scriptInfo)
    if not scriptInfo or msgType ~= 3 or scriptInfo.id ~= target_id or scriptInfo.name ~= target_name or scriptInfo.path ~= target_path then return end
    if msg:find("Script died due to an error.") then return end

    sampShowDialog(252, "Что-то пошло не так",
        "{FFFFFF}Произошла непредусмотренная ошибка в скрипте {00BFFF}Evolve Logs{FFFFFF}.\n"
        .. "Используйте Ctrl + R для автоматической загрузки всех библиотек.\n"
        .. "Если данная ошибка повторяется отправьте скриншот разработчику {00BFFF}vk.com/yanoka.belyaeva{FFFFFF}\n\n" .. msg,
        "Закрыть", nil, 0)

    local payload = {
        tags = { moonloader_version = getMoonloaderVersion(), sborka = string.match(getGameDirectory(), ".+\\(.-)$") },
        level = "error",
        exception = {
            values = { {
                type = parseType(msg),
                value = msg,
                mechanism = { type = "generic", handled = false },
                stacktrace = parseStacktrace(msg)
            } }
        },
        environment = "production",
        logger = logger_name .. " (no sampfuncs)",
        release = scriptInfo.name .. "@" .. scriptInfo.version,
        extra = { uptime = os.clock() },
        user = { id = tostring(getVolumeSerial()) },
        sdk = { name = "qrlk.lua.moonloader", version = "0.0.0" }
    }
    if isSampAvailable() and isSampfuncsLoaded() then
        payload.logger = logger_name
        payload.user.username = getNick() .. "@" .. sampGetCurrentServerAddress()
        payload.tags.game_state = sampGetGamestate()
        payload.tags.server = sampGetCurrentServerAddress()
        payload.tags.server_name = sampGetCurrentServerName()
    end

    local encoded = (encodeJson or json.encode)(payload)
    if utf8 and utf8.encode then
        encoded = utf8:encode(encoded)
    end
    downloadUrlToFile(sentry_url .. url_encode(encoded))
end

function onScriptTerminate(scriptInfo, quitReason)
    if not quitReason and scriptInfo and scriptInfo.id == target_id then
        lua_thread.create(function()
            print("скрипт " .. target_name .. " (ID: " .. target_id .. ") завершил свою работу, выгружаемся через 60 секунд")
            wait(60000)
            thisScript():unload()
        end)
    end
end
]], target_id, target_name, target_path, sentry_url_safe)

    local tmp = os.tmpname()
    local f = io.open(tmp, "w+")
    if f then
        f:write(reporter_src)
        f:close()
        script.load(tmp)
        pcall(os.remove, tmp)
    end
end

return { init = init }
