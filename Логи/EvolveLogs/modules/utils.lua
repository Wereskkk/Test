-- Утилиты: сообщения в чат, парсинг дат, ранги, контракты

local encoding = require("encoding")
encoding.default = "CP1251"
local u8 = encoding.utf8

local CHAT_PREFIX = "{EB2E4A}[ Evolve Logs ] {FFFFFF}"

function chatMsg(text, isError)
    local msg = (isError and (CHAT_PREFIX .. "Ошибка: " .. text) or (CHAT_PREFIX .. text))
    sampAddChatMessage(msg, -1)
end

function rankStringToNumber(s)
    if not s or s == "" then return nil end
    local n = tonumber(s)
    if n then return n end
    local bracket = s:match("%[(%d+)%]")
    return bracket and tonumber(bracket) or nil
end

function cleanContractType(contractType)
    if not contractType or contractType == "" then return "Неизвестно" end
    local newType = contractType:gsub(u8"Военная кафедра%s*%(%s*15%s*lvl,%s*40%+%s*%)", u8"ВК")
    newType = newType:gsub(u8"Адмиральский контракт%s*%(%s*8%s*lvl,%s*25%+%s*%)", u8"Admiral")
    newType = newType:gsub(u8"Стандартный контракт%s*%(%s*4%s*lvl,%s*5%+%s*%)", u8"Standart")
    newType = newType:gsub(u8"Профессиональный контракт%s*%(%s*6%s*lvl,%s*10%+%s*%)", u8"Professional")
    newType = newType:gsub("%s*[Cc]ontract%s*", ""):gsub("%s*%(OLD%)%s*$", "")
    return newType
end

function parseDate(dateStr)
    if not dateStr or dateStr == "" then return nil end
    local day, month, year = dateStr:match("(%d+)%.(%d+)%.(%d+)")
    if not (day and month and year) then return nil end
    year = tonumber(year)
    if year < 100 then year = year + 2000 end
    return os.time({ year = year, month = tonumber(month), day = tonumber(day), hour = 0, min = 0, sec = 0 })
end

function cleanDateString(dateString, u8_unknown)
    u8_unknown = u8_unknown or u8"Неизвестно"
    local cleanedDate = dateString and dateString:match("Date%((%d+,%d+,%d+)%)")
    if cleanedDate then
        local year, month, day = cleanedDate:match("(%d+),(%d+),(%d+)")
        month = tonumber(month) + 1
        return string.format("%02d.%02d.%04d", tonumber(day), month, tonumber(year))
    end
    return u8_unknown
end

return {
    chatMsg = chatMsg,
    rankStringToNumber = rankStringToNumber,
    cleanContractType = cleanContractType,
    parseDate = parseDate,
    cleanDateString = cleanDateString,
    u8 = u8,
}
