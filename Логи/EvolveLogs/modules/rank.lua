-- «агрузка и нормализаци€ данных рангов из rank_info.json

local json = require("json")
local rankInfoFilePath

function initRank(getPathFn)
    rankInfoFilePath = getPathFn and getPathFn() or nil
end

function loadRankInfo(getPathFn)
    local path = (getPathFn and getPathFn()) or rankInfoFilePath
    local result = {}
    if not path or not doesFileExist(path) then return result end
    local file = io.open(path, "r")
    if not file then return result end
    local content = file:read("*a")
    file:close()
    if not content or content == "" then return result end
    local ok, decoded = pcall(json.decode, content)
    if not ok or type(decoded) ~= "table" then return result end
    for server, factions in pairs(decoded) do
        if type(factions) == "table" then
            local normServer = {}
            for fid, ranks in pairs(factions) do
                if type(ranks) == "table" then
                    local normFaction = {}
                    for rid, data in pairs(ranks) do
                        if type(data) == "table" then
                            normFaction[tonumber(rid) or rid] = { name = data.name or "", days = data.days or 0 }
                        end
                    end
                    normServer[tonumber(fid) or fid] = normFaction
                end
            end
            result[server] = normServer
        end
    end
    return result
end

return { initRank = initRank, loadRankInfo = loadRankInfo }
