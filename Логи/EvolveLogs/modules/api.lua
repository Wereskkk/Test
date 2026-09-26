-- API: проверка сервера, HTTP-запросы, таблицы контрактников, расчёт дат

local json = require("json")
local requests = require("requests")

local config
local utils
local isRequestInProgress = false
local errorLogged = false

function initApi(cfg, ut)
    config = cfg
    utils = ut
end

function checkServer()
    local server_ip = sampGetCurrentServerAddress()
    local server_name = sampGetCurrentServerName()
    local sc = config.SERVER_CHECK
    if server_ip == sc.ip or (server_name and server_name:find(sc.name_evolve) and server_name:find(sc.name_saint_louis)) then
        return config.SERVER_CHECK.server_id
    end
    return nil
end

function getPlayerFraction(fractionRef)
    if not fractionRef then return nil end
    return config.UI_TO_API_FACTION[fractionRef[0]]
end

function asyncHttpRequest(url, handler, chatMsgFn)
    if isRequestInProgress then
        if chatMsgFn then chatMsgFn("предыдущий запрос ещё выполняется.", true) end
        return
    end
    isRequestInProgress = true
    local timeout = config.HTTP_TIMEOUT or 10
    local success, response = pcall(function() return requests.get(url, { timeout = timeout }) end)
    if not success or not response then
        isRequestInProgress = false
        handler(nil, "Timeout occurred or other error during the HTTP request.")
        return
    end
    isRequestInProgress = false
    if response and response.status_code >= 200 and response.status_code < 500 and response.text then
        handler(response.text, response.status_code, response.headers or {})
    else
        handler(nil, "HTTP error: " .. tostring(response.status_code))
    end
end

function httpRequestHistory(nickname, state, chatMsgFn)
    local lastRequestTimes = state.lastRequestTimes
    local floodLimit = config.FLOOD_LIMIT
    local floodTimeWindow = config.FLOOD_TIME_WINDOW
    local currentTime = os.clock()
    for i = #lastRequestTimes, 1, -1 do
        if currentTime - lastRequestTimes[i] > floodTimeWindow then table.remove(lastRequestTimes, i) end
    end
    if #lastRequestTimes >= floodLimit then
        if chatMsgFn then chatMsgFn("не так часто!", true) end
        return
    end
    table.insert(lastRequestTimes, currentTime)
    local playerId = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
    if not playerId then
        if chatMsgFn then chatMsgFn("не удалось получить ID игрока.", true) end
        return
    end
    local playerName = sampGetPlayerNickname(playerId)
    local fraction = getPlayerFraction(state.fraction)
    local server = checkServer()
    if not playerName or playerName == "" or not fraction or not server then
        if chatMsgFn then chatMsgFn("данные игрока не определены.", true) end
        return
    end
    local baseUrl = (state.settings.api_base_url and state.settings.api_base_url ~= "") and state.settings.api_base_url or config.API_BASE_URL
    baseUrl = baseUrl:gsub("/+$", "")
    local url = baseUrl .. "/v1/journal/history?player=" .. nickname .. "&fraction=" .. tostring(fraction) .. "&server=" .. server .. "&requester=" .. playerName
    asyncHttpRequest(url, function(response, status_code)
        if response then
            local success, result = pcall(json.decode, response)
            if not success then
                if chatMsgFn then chatMsgFn("неверный формат ответа сервера. Ошибка: " .. tostring(result), true) end
                return
            end
            if result.errors then
                local errMsg = result.errors[1] and result.errors[1].message or utils.u8"Неизвестная ошибка"
                if chatMsgFn then chatMsgFn(utils.u8:decode(errMsg), true) end
                return
            end
            if result.data and type(result.data) == "table" then
                state.searchResults = {}
                for _, data in ipairs(result.data) do
                    if type(data) == "table" then
                        local row = {
                            nickname = data.player_nickname or "N/A", initiator = data.initiator_nickname or "N/A",
                            giverank_last = data.previous_rank or "N/A", lastPromotion = data.event_date or "N/A",
                            giverankto = data.new_rank or "N/A", reason = data.reason or "—", fraction = fraction,
                            contractType = utils.u8"Нет",
                        }
                        table.insert(state.searchResults, row)
                    end
                end
            else
                if chatMsgFn then chatMsgFn("неожиданный формат ответа сервера.", true) end
            end
        else
            if chatMsgFn then chatMsgFn("запроса: " .. tostring(status_code), true) end
        end
    end, chatMsgFn)
end

function getSpreadsheetData(spreadsheetUrl, callback, chatMsgFn)
    asyncHttpRequest(spreadsheetUrl, function(response, status_code)
        if not response then
            if chatMsgFn then chatMsgFn("запроса: " .. tostring(status_code), true) end
            callback(nil)
            return
        end
        local jsonData = response:match("google%.visualization%.Query.setResponse%((.+)%)")
        if not jsonData then
            if chatMsgFn then chatMsgFn("не удалось извлечь JSON из таблицы.", true) end
            callback(nil)
            return
        end
        local ok, data = pcall(json.decode, jsonData)
        callback(ok and data or nil)
    end, chatMsgFn)
end

function getContractTypeFromSpreadsheet(nickname, server, fraction, handler, chatMsgFn, cleanContractTypeFn, cleanDateStringFn)
    local url = config.SPREADSHEET_URLS[server] and config.SPREADSHEET_URLS[server][fraction]
    local columns = config.COLUMN_MAPPING[server] and config.COLUMN_MAPPING[server][fraction]
    if not url or not columns then
        if chatMsgFn then chatMsgFn("нет данных для сервера или фракции.", true) end
        handler(nil)
        return
    end
    getSpreadsheetData(url, function(data)
        if not data or not data.table or not data.table.rows then handler(nil); return end
        cleanContractTypeFn = cleanContractTypeFn or utils.cleanContractType
        cleanDateStringFn = cleanDateStringFn or utils.cleanDateString
        for _, row in ipairs(data.table.rows) do
            local columnA = row.c[columns.nick] and row.c[columns.nick].v
            local contractValue = columns.contract and row.c[columns.contract] and row.c[columns.contract].v or nil
            local lastPromotion = row.c[columns.lastPromotion] and row.c[columns.lastPromotion].v
            local nextPromotion = row.c[columns.nextPromotion] and row.c[columns.nextPromotion].v
            if columnA == nickname then
                local contractType = (not columns.contract or columns.contract == 0) and utils.u8"Да" or cleanContractTypeFn(contractValue)
                handler({
                    contractType = contractType,
                    lastPromotion = cleanDateStringFn(lastPromotion) or utils.u8"Неизвестно",
                    nextPromotion = cleanDateStringFn(nextPromotion) or utils.u8"Неизвестно",
                })
                return
            end
        end
        handler(nil)
    end, chatMsgFn)
end

function httpRequest(nickname, state, chatMsgFn)
    local lastRequestTimes = state.lastRequestTimes
    local floodLimit = config.FLOOD_LIMIT
    local floodTimeWindow = config.FLOOD_TIME_WINDOW
    local currentTime = os.clock()
    for i = #lastRequestTimes, 1, -1 do
        if currentTime - lastRequestTimes[i] > floodTimeWindow then table.remove(lastRequestTimes, i) end
    end
    if #lastRequestTimes >= floodLimit then
        if chatMsgFn then chatMsgFn("не так часто!", true) end
        return
    end
    table.insert(lastRequestTimes, currentTime)
    local playerId = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
    if not playerId then
        if chatMsgFn then chatMsgFn("не удалось получить ID игрока.", true) end
        return
    end
    local playerName = sampGetPlayerNickname(playerId)
    local fraction = getPlayerFraction(state.fraction)
    local server = checkServer()
    if not playerName or playerName == "" or not fraction or not server then
        if chatMsgFn then chatMsgFn("данные игрока не определены.", true) end
        return
    end
    local baseUrl = (state.settings.api_base_url and state.settings.api_base_url ~= "") and state.settings.api_base_url or config.API_BASE_URL
    baseUrl = baseUrl:gsub("/+$", "")
    local url = baseUrl .. "/v1/journal?player=" .. nickname .. "&fraction=" .. tostring(fraction) .. "&server=" .. server .. "&requester=" .. playerName
    asyncHttpRequest(url, function(response, status_code)
        if response then
            local success, result = pcall(json.decode, response)
            if not success then
                if chatMsgFn then chatMsgFn("неверный формат ответа сервера. Ошибка: " .. tostring(result), true) end
                return
            end
            if result.data and not result.errors then
                local data = result.data
                local row = {
                    nickname = data.player_nickname or "N/A", initiator = data.initiator_nickname or "N/A",
                    giverank_last = data.previous_rank or "N/A", lastPromotion = data.event_date or "N/A",
                    giverankto = data.new_rank or "N/A", reason = data.reason or "—", fraction = fraction,
                }
                local giverank_last = utils.rankStringToNumber(row.giverank_last)
                local giverankto = utils.rankStringToNumber(row.giverankto)
                if giverank_last and giverank_last == 1 and giverankto and (giverankto == 3 or giverankto == 4 or giverankto == 5) and server and fraction and config.SPREADSHEET_URLS[server] and config.COLUMN_MAPPING[server] then
                    getContractTypeFromSpreadsheet(nickname, server, fraction, function(spreadsheetData)
                        if spreadsheetData then
                            row.contractType = spreadsheetData.contractType or utils.u8"Нет"
                            row.lastPromotion = spreadsheetData.lastPromotion or utils.u8"Неизвестно"
                            row.nextPromotion = spreadsheetData.nextPromotion or utils.u8"Неизвестно"
                        else row.contractType = utils.u8"Нет" end
                        table.insert(state.searchResults, row)
                    end, chatMsgFn, utils.cleanContractType, utils.cleanDateString)
                else
                    row.contractType = utils.u8"Нет"
                    table.insert(state.searchResults, row)
                end
            elseif result.errors then
                local errMsg = result.errors[1] and result.errors[1].message or utils.u8"Неизвестная ошибка"
                if chatMsgFn then chatMsgFn(utils.u8:decode(errMsg), true) end
            else
                if chatMsgFn then chatMsgFn("неожиданный формат ответа сервера.", true) end
            end
        else
            if chatMsgFn then chatMsgFn("запроса: " .. tostring(status_code), true) end
        end
    end, chatMsgFn)
end

function calculateNextUpgradeDate(date, rankTo, contractType, playerId, rankInfo, fractionRef, chatMsgFn)
    local faction = getPlayerFraction(fractionRef)
    if not faction then
        if not errorLogged and chatMsgFn then chatMsgFn("фракция не определена.", true); errorLogged = true end
        return nil
    end
    local changeDate = utils.parseDate(date)
    if not changeDate then
        if not errorLogged and chatMsgFn then chatMsgFn("дата некорректна.", true); errorLogged = true end
        return nil
    end
    local currentServer = checkServer()
    if not currentServer or not rankInfo[currentServer] then
        if not errorLogged and chatMsgFn then chatMsgFn("ранг не найден для фракции.", true); errorLogged = true end
        return nil
    end
    local rankDays = 0
    if rankInfo[currentServer][faction] and rankInfo[currentServer][faction][tonumber(rankTo)] then
        rankDays = rankInfo[currentServer][faction][tonumber(rankTo)].days or 0
    else
        if not errorLogged and chatMsgFn then chatMsgFn("ранг не найден для фракции.", true); errorLogged = true end
        return nil
    end
    local contractDaysExtra = (contractType and config.CONTRACT_DAYS[contractType]) and 0 or 0
    return changeDate + (rankDays + contractDaysExtra) * 24 * 60 * 60
end

return {
    initApi = initApi, checkServer = checkServer, getPlayerFraction = getPlayerFraction,
    asyncHttpRequest = asyncHttpRequest, getSpreadsheetData = getSpreadsheetData,
    getContractTypeFromSpreadsheet = getContractTypeFromSpreadsheet, httpRequest = httpRequest,
    httpRequestHistory = httpRequestHistory,
    calculateNextUpgradeDate = calculateNextUpgradeDate,
}
