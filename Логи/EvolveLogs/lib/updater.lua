-- Модуль автообновления

local download_status = require("moonloader").download_status
local json = require("json")

local workDir = getWorkingDirectory()
local tempDir = os.getenv("TEMP") or os.getenv("TMP") or workDir

local function createParentDirs(filePath)
    local path = filePath:gsub("/", "\\")
    local segments = {}
    for s in path:gmatch("[^\\]+") do segments[#segments + 1] = s end
    if #segments < 2 then return end
    local acc = workDir .. "\\"
    for i = 1, #segments - 1 do
        acc = acc .. (i > 1 and "\\" or "") .. segments[i]
        if not doesDirectoryExist(acc) then createDirectory(acc) end
        acc = acc .. "\\"
    end
end

local function downloadModules(modules, prefix, onDone)
    if not modules or type(modules) ~= "table" or #modules == 0 then
        if onDone then onDone() end
        return
    end
    local idx = 1
    local function downloadNext()
        if idx > #modules then
            if onDone then onDone() end
            return
        end
        local entry = modules[idx]
        local path = (entry.path or entry[1]):gsub("/", "\\")
        local dest = workDir .. "\\" .. path
        local tempFile = tempDir .. "\\_evolvelogs_upd_" .. idx .. ".tmp"
        if doesFileExist(tempFile) then os.remove(tempFile) end
        local ok, err = pcall(function()
            downloadUrlToFile(entry.url, tempFile, function(_, status, loaded, total)
                local isFinal = (status == download_status.STATUS_ENDDOWNLOADDATA or status == download_status.STATUSEX_ENDDOWNLOAD)
                if isFinal then
                    if doesFileExist(tempFile) then
                        local fr = io.open(tempFile, "rb")
                        if fr then
                            local content = fr:read("*a")
                            fr:close()
                            createParentDirs(path)
                            local fw = io.open(dest, "wb")
                            if fw then
                                fw:write(content or "")
                                fw:close()
                                print(prefix .. "Модуль обновлён: " .. path)
                            else
                                print(prefix .. "Ошибка записи модуля: " .. path)
                            end
                        end
                        os.remove(tempFile)
                    else
                        print(prefix .. "Ошибка загрузки модуля: " .. path)
                    end
                end
                if isFinal then
                    idx = idx + 1
                    lua_thread.create(function()
                        wait(150)
                        downloadNext()
                    end)
                end
            end)
        end)
        if not ok then
            print(prefix .. "Ошибка загрузки: " .. path .. " (" .. tostring(err) .. ")")
            idx = idx + 1
            lua_thread.create(function()
                wait(150)
                downloadNext()
            end)
        end
    end
    downloadNext()
end

function check(json_url, prefix, base_url)
    local tmp = os.tmpname()
    local start = os.clock()
    local done = false
    if doesFileExist(tmp) then os.remove(tmp) end
    downloadUrlToFile(json_url, tmp, function(_, status, _, _)
        if status ~= download_status.STATUSEX_ENDDOWNLOAD then return end
        done = true
        if status ~= download_status.STATUSEX_ENDDOWNLOAD then return end
        if not doesFileExist(tmp) then return end
        local f = io.open(tmp, "r")
        if not f then return end
        local content = f:read("*a")
        f:close()
        os.remove(tmp)
        local ok, data = pcall(json.decode, content)
        if not ok or not data then
            print(prefix .. "Не могу проверить обновление.")
            return
        end
        local updateversion = data.latest
        local updatelink = data.updateurl

        if updateversion == thisScript().version then
            print("v" .. thisScript().version .. ": Обновление не требуется.")
            return
        end

        local function checkMainUpdate()
            if not updateversion or not updatelink then return end
            sampAddChatMessage(prefix .. "Обнаружено обновление. Пытаюсь обновиться c " .. thisScript().version .. " на " .. updateversion, -1)
            wait(250)
            downloadUrlToFile(updatelink, thisScript().path, function(_, status, loaded, total)
                if status == download_status.STATUS_DOWNLOADINGDATA then
                    print(string.format("Загружено %d из %d.", loaded, total))
                elseif status == download_status.STATUS_ENDDOWNLOADDATA then
                    print("Загрузка обновления завершена.")
                    sampAddChatMessage(prefix .. "Обновление завершено!", -1)
                    lua_thread.create(function()
                        wait(500)
                        thisScript():reload()
                    end)
                elseif status == download_status.STATUSEX_ENDDOWNLOAD then
                end
            end)
        end

        downloadModules(data.modules, prefix, checkMainUpdate)
        if not data.modules or #data.modules == 0 then
            checkMainUpdate()
        end
    end)
    while os.clock() - start < 10 and not done do wait(100) end
    if not done then
        print("v" .. thisScript().version .. ": timeout проверки обновления.")
    end
end

return { check = check }