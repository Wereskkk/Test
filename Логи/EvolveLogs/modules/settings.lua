-- Настройки: пути, загрузка/сохранение, организация из Government Tools

local json = require("json")

local gameDirectory
local settingsFilePath
local personalInfoPath
local rankInfoFilePath
local config

function createSettingsDirectory()
    local baseDir = getWorkingDirectory() .. "\\EvolveLogs"
    if not doesDirectoryExist(baseDir) then
        if createDirectory(baseDir) then print(string.format("Создана директория: %s", baseDir))
        else print(string.format("Не удалось создать директорию: %s", baseDir)) end
    end
    local dir = baseDir .. "\\Configs"
    if not doesDirectoryExist(dir) then
        if createDirectory(dir) then print(string.format("Создана директория: %s", dir))
        else print(string.format("Не удалось создать директорию: %s", dir)) end
    end
end

function getDefaultSettings()
    return { fraction = 0, journalMode = 0 }
end

function initSettings(gameDir, cfg)
    config = cfg
    gameDirectory = gameDir
    settingsFilePath = gameDirectory .. "\\moonloader\\EvolveLogs\\Configs\\settings.json"
    personalInfoPath = gameDirectory .. "\\moonloader\\Government Tools\\Configs\\personal_info.json"
    rankInfoFilePath = gameDirectory .. "\\moonloader\\EvolveLogs\\Configs\\rank_info.json"
end

function loadSettings()
    createSettingsDirectory()
    local file = io.open(settingsFilePath, "r")
    if file then
        local content = file:read("*a")
        file:close()
        if content and content ~= "" then return json.decode(content) or getDefaultSettings() end
    end
    return getDefaultSettings()
end

function saveSettings(settings, chatMsgFn)
    createSettingsDirectory()
    local file = io.open(settingsFilePath, "w")
    if not file then
        if chatMsgFn then chatMsgFn("не удалось открыть файл настроек для записи.", true) end
        return false
    end
    local encoded = json.encode(settings, { indent = true })
    local ok, err = file:write(encoded)
    if not ok then
        file:close()
        if chatMsgFn then chatMsgFn("не удалось записать настройки.", true) end
        return false
    end
    file:close()
    return true
end

function getOrganizationFromPersonalInfo()
    if not personalInfoPath or not doesFileExist(personalInfoPath) then return nil end
    local file = io.open(personalInfoPath, "r")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    if not content or content == "" then return nil end
    local ok, data = pcall(json.decode, content)
    if not ok or not data or type(data) ~= "table" then return nil end
    local first = type(data[1]) == "table" and data[1] or data
    local org = first.organization or first.fraction or first.org
    return type(org) == "string" and org or nil
end

function getRankInfoFilePath()
    return rankInfoFilePath
end

return {
    initSettings = initSettings,
    loadSettings = loadSettings,
    saveSettings = saveSettings,
    getOrganizationFromPersonalInfo = getOrganizationFromPersonalInfo,
    getRankInfoFilePath = getRankInfoFilePath,
}
