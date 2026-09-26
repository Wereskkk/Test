-- Загрузка недостающих библиотек MoonLoader (mimgui, json, иконки и т.д.)

local config = require("modules.config")

function getLibFolder()
    return getWorkingDirectory() .. "\\lib"
end

function ensure()
    local list = config.LIBS_TO_DOWNLOAD or {}
    local libFolder = getLibFolder()
    local anyDownloaded = false
    for _, lib in ipairs(list) do
        if lib.url and lib.filename then
            local path = libFolder .. "\\" .. lib.filename
            if not doesFileExist(path) then
                downloadUrlToFile(lib.url, path)
                print("[Evolve Logs] Загружена библиотека: " .. lib.filename)
                anyDownloaded = true
            end
        end
    end
    return not anyDownloaded
end

return {
    ensure = ensure,
    getLibFolder = getLibFolder,
}
