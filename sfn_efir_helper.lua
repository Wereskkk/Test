local imgui = require('mimgui')
local encoding = require('encoding')
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local new = imgui.new
local ffi = require('ffi')

-- ============================================================
-- SHA256
-- ============================================================
local sha256 = (function()
    local band    = bit.band
    local bxor    = bit.bxor
    local bor     = bit.bor
    local bnot    = bit.bnot
    local rrotate = bit.ror
    local lshift  = bit.lshift
    local rshift  = bit.rshift
    local tobit   = bit.tobit

    local K = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    }

    local function preprocess(msg)
        local len = #msg
        local bitlen = len * 8
        msg = msg .. "\128"
        while (#msg % 64) ~= 56 do msg = msg .. "\0" end
        msg = msg .. "\0\0\0\0" .. string.char(
            band(rshift(bitlen, 24), 0xff),
            band(rshift(bitlen, 16), 0xff),
            band(rshift(bitlen,  8), 0xff),
            band(bitlen, 0xff))
        return msg
    end

    local function hash(msg)
        msg = preprocess(msg)
        local H = {
            0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
            0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
        }
        for i = 1, #msg, 64 do
            local w = {}
            for j = 0, 15 do
                local k = i + j * 4
                w[j] = bor(
                    lshift(msg:byte(k), 24),
                    lshift(msg:byte(k + 1), 16),
                    lshift(msg:byte(k + 2), 8),
                    msg:byte(k + 3))
            end
            for j = 16, 63 do
                local s0 = bxor(rrotate(w[j-15], 7), rrotate(w[j-15], 18), rshift(w[j-15], 3))
                local s1 = bxor(rrotate(w[j-2], 17), rrotate(w[j-2], 19), rshift(w[j-2], 10))
                w[j] = tobit(w[j-16] + s0 + w[j-7] + s1)
            end
            local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
            for j = 0, 63 do
                local S1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
                local ch = bxor(band(e, f), band(bnot(e), g))
                local t1 = tobit(h + S1 + ch + K[j + 1] + w[j])
                local S0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
                local maj = bxor(band(a, b), band(a, c), band(b, c))
                local t2 = tobit(S0 + maj)
                h = g; g = f; f = e
                e = tobit(d + t1)
                d = c; c = b; b = a
                a = tobit(t1 + t2)
            end
            H[1] = tobit(H[1] + a); H[2] = tobit(H[2] + b)
            H[3] = tobit(H[3] + c); H[4] = tobit(H[4] + d)
            H[5] = tobit(H[5] + e); H[6] = tobit(H[6] + f)
            H[7] = tobit(H[7] + g); H[8] = tobit(H[8] + h)
        end
        return bit.tohex(H[1], 8) .. bit.tohex(H[2], 8) ..
               bit.tohex(H[3], 8) .. bit.tohex(H[4], 8) ..
               bit.tohex(H[5], 8) .. bit.tohex(H[6], 8) ..
               bit.tohex(H[7], 8) .. bit.tohex(H[8], 8)
    end

    return { hash = hash }
end)()

local sampev_ok, sampev = pcall(require, 'samp.events')

local function logPrint(msg) print(u8:decode(tostring(msg))) end
local function logAction(msg) logPrint("[SFN] " .. os.date("%H:%M:%S") .. " " .. msg) end

CURRENT_VERSION = "7.0.1"

VERSION_URL = "https://raw.githubusercontent.com/Wereskkk/sfn-efir/refs/heads/main/sfn_version.txt"
UPDATE_URL  = "https://raw.githubusercontent.com/Wereskkk/sfn-efir/refs/heads/main/sfn_efir_helper.lua"

local function resolveScriptPath()
    local ok, sp = pcall(thisScript)
    if ok and type(sp) == "string" and #sp > 0 and sp:find("%.lua") then
        return sp
    end
    local wd = getWorkingDirectory() or ""
    local candidates = {
        wd .. "\\moonloader\\sfn_efir_helper.lua",
        wd .. "\\packs\\Default\\moonloader\\sfn_efir_helper.lua",
        wd .. "\\..\\moonloader\\sfn_efir_helper.lua",
        wd .. "\\sfn_efir_helper.lua",
    }
    for _, path in ipairs(candidates) do
        if doesFileExist(path) then return path end
    end
    return ""
end

SCRIPT_PATH = resolveScriptPath()
SCRIPT_DIR  = (SCRIPT_PATH ~= "" and SCRIPT_PATH:match("^(.*)\\[^\\]+$")) or getWorkingDirectory() or ""
UPDATE_TMP  = (SCRIPT_PATH ~= "" and (SCRIPT_PATH .. ".new")) or ""

local function applyPendingUpdate()
    if SCRIPT_PATH == "" or UPDATE_TMP == "" then return false end
    if not doesFileExist(UPDATE_TMP) then return false end
    local f = io.open(UPDATE_TMP, "rb")
    if not f then return false end
    local data = f:read("*a")
    f:close()
    if not data or #data < 1024 then
        os.remove(UPDATE_TMP)
        return false
    end
    local out = io.open(SCRIPT_PATH, "wb")
    if not out then return false end
    out:write(data)
    out:close()
    os.remove(UPDATE_TMP)
    return true
end

local function checkForUpdates()
    if VERSION_URL == "" or UPDATE_URL == "" then return end
    if SCRIPT_PATH == "" or UPDATE_TMP == "" then return end

    lua_thread.create(function()
        wait(8000)
        local verTmp = SCRIPT_DIR .. "\\sfn_version.tmp"
        local ok = downloadUrlToFile(VERSION_URL, verTmp)
        if not ok then return end
        wait(400)
        local f = io.open(verTmp, "r")
        if not f then return end
        local remoteVersion = f:read("*a"):gsub("%s+", "")
        f:close()
        os.remove(verTmp)
        if remoteVersion == "" or remoteVersion == CURRENT_VERSION then return end
        logPrint("[SFN] Доступна новая версия: " .. remoteVersion)
        local ok2 = downloadUrlToFile(UPDATE_URL, UPDATE_TMP)
        if not ok2 then return end
        wait(400)
        local nf = io.open(UPDATE_TMP, "rb")
        if not nf then return end
        local data = nf:read("*a")
        nf:close()
        if not data or #data < 1024 then
            os.remove(UPDATE_TMP)
            return
        end
        logPrint("[SFN] Обновление загружено.")
        sampAddChatMessage(
            "{FFD700}[SFN] Доступно обновление " .. remoteVersion ..
            ". Перезапустите игру.", -1)
    end)
end

local DATA_DIR = getWorkingDirectory() .. "\\sfn_data"
local CONFIG_PATH = DATA_DIR .. "\\config.json"
local SCORES_PATH = DATA_DIR .. "\\scores.json"
local GENDERS_PATH = DATA_DIR .. "\\genders.json"
local TEXTS_PATH  = DATA_DIR .. "\\texts.lua"
local ANAGRAMS_PATH = DATA_DIR .. "\\anagrams.lua"
local WORDS_PATH = DATA_DIR .. "\\words.lua"

local DEFAULT_HOTKEY = 0x7A
local SPEECH_DELAY = 5

local CHAT_MAX_LEN = 120

local PATTERN_AIR_MESSAGE        = "%[[^%]]+%]%s*(%d+)%."
local PATTERN_ANAGRAM_MESSAGE    = "%[[^%]]+%]%s*([^%[%]%.]+)%."
local PATTERN_NICK_WITH_ID       = "([%a][%w_]+)%[(%d+)%]"
local PATTERN_AIR_MESSAGE_SIGNED = "%[[^%]]+%]%s*(%-?%s*%d+)%."

local AUTH_SALT = "SFN_2026_SECURE_x7p9nq2m"

local ADMIN_NICK_HASHES = {
    "548213b64ed49aaf6e51ff5f263e266665c8b6623ea8a7c05d331605d3728e82",
}

local ALLOWED_NICK_HASHES = {
    "96c38190233366a49a2cfbec525f0d8a8205a34bd428b1ff70c50bdf26842c91",
}

local ACCESS_GRANTED = false
local ACCESS_CHECKED = false

local str_sub, str_char, str_upper = string.sub, string.char, string.upper
local tbl_concat = table.concat

local lu_rus, ul_rus = {}, {}
for i = 192, 223 do
    local A, a = str_char(i), str_char(i + 32)
    ul_rus[A] = a
    lu_rus[a] = A
end
local E_UP, E_LO = str_char(168), str_char(184)
ul_rus[E_UP] = E_LO
lu_rus[E_LO] = E_UP

local function cp1251Upper(s)
    if not s then return s end
    s = str_upper(s)
    local len, res = #s, {}
    for i = 1, len do
        local ch = str_sub(s, i, i)
        res[i] = lu_rus[ch] or ch
    end
    return tbl_concat(res)
end

local function normalizeAnswer(s)
    if not s then return "" end
    s = cp1251Upper(s)
    s = s:gsub("[%.%!%?]$", "")
    s = s:gsub("Ё", "Е")
    s = s:gsub("%s+", "")
    return s
end

local function getDefaultTexts()
    return {
        intro = { jingle = "...", lines = { "..." } },
        outro = { lines = { "..." } },
        rules = { math = { "..." }, anagram = { "..." }, vyshibaly = { "..." } },
        scores_intros = { "..." },
        advertisement = { jingle = "...", intros = { "..." }, blocks = { { "..." } } },
        system = {
            loaded_title    = "========== San Fierro News ==========",
            loaded_message  = "SFN Helper — скрипт успешно запущен!",
            loaded_greeting = "Приветствую, {NICK}!",
            loaded_help     = "Чтобы открыть меню — нажми F11 или введи /efir",
            loaded_bottom   = "=====================================",
            menu_opened = "[SFN] Меню открыто",
            menu_closed = "[SFN] Меню закрыто",
            screenshot_reminder = "[SFN] Пора сделать скриншот!",
            screenshot_done = "[SFN] Скриншот #{N} сделан",
            base_cleared = "[SFN] База баллов очищена",
            no_scores = "[SFN] Пока никто не набрал баллов",
            no_answer = "[SFN] Нет верного ответа для начисления",
            no_anagram_words = "[SFN] База слов для анаграмм пуста.",
        },
    }
end

local function loadTexts()
    local f = loadfile(TEXTS_PATH)
    if not f then logPrint("[SFN] texts.lua не найден.") return nil end
    local ok, result = pcall(f)
    if not ok or type(result) ~= "table" then return nil end
    if not result.intro or not result.intro.lines then return nil end
    return result
end

local TEXTS = loadTexts() or getDefaultTexts()

local ANAGRAMS = {}
local VYSHIBALY_WORDS = {}

local function loadWordList(path, label)
    local f = loadfile(path)
    if not f then return nil end
    local ok, result = pcall(f)
    if not ok or type(result) ~= "table" then return nil end
    local words = {}
    for _, word in ipairs(result) do
        if type(word) == "string" and #word > 0 then
            local cp = u8:decode(word)
            cp = cp1251Upper(cp)
            table.insert(words, u8:encode(cp))
        end
    end
    return words
end

local loadedWords = loadWordList(WORDS_PATH, "words.lua")
local loadedAnagrams = loadWordList(ANAGRAMS_PATH, "anagrams.lua")

if loadedWords then VYSHIBALY_WORDS = loadedWords else VYSHIBALY_WORDS = loadedAnagrams or {} end
if loadedAnagrams then ANAGRAMS = loadedAnagrams else ANAGRAMS = loadedWords or {} end

local WinState = new.bool(true)

local HOTKEY = DEFAULT_HOTKEY
local MAX_SCORE = 20
local PRIZE_FUND = 500000
local efirRunning = false
local efirStarted = false -- Флаг: тикает ли сейчас таймер
local efirStartTime = 0
local screenshots = 0

local currentMode = "math"
local currentType = "Математика"

local mathQuestion = ""
local mathAnswer = 0
local mathQuestionSuffix = " = ?"

local MATH_TYPES = {
    "classic", "addsub", "multiply", "divide",
    "brackets", "mixed", "equation",
}
local lastMathType = nil

local anagramWord = ""
local anagramShuffled = ""
local vyshibalyWord = ""
local vyshibalyMasked = ""
local currentFirstAnswer = nil
local scores = {}
local genders = {}
local pendingGenderConfirm = nil
local genderWindowOpen = new.bool(false)

local myNick = "Unknown"
local myDisplayNick = "Unknown"
local myId = -1

-- ============================================================
-- БАЗОВЫЕ ЛОГИЧЕСКИЕ ФУНКЦИИ
-- ============================================================

local function say(msg) sampAddChatMessage(u8:decode(msg), -1) end
local function sendChat(msg) sampSendChat(u8:decode(msg)) end

local function sendPacked(items, prefixFirst, prefixRest)
    if not items or #items == 0 then return end
    prefixFirst = prefixFirst or ""
    prefixRest = prefixRest or prefixFirst
    local idx = 1
    local isFirstMsg = true
    while idx <= #items do
        local prefix = isFirstMsg and prefixFirst or prefixRest
        if #prefix + #items[idx] > CHAT_MAX_LEN and #prefix > #prefixRest then
            prefix = prefixRest
        end
        local current = prefix .. items[idx]
        local j = idx + 1
        while j <= #items do
            local candidate = current .. ", " .. items[j]
            if #candidate > CHAT_MAX_LEN then break end
            current = candidate
            j = j + 1
        end
        if current:sub(-1) ~= "." then current = current .. "." end
        sendChat(current)
        wait(3000)
        idx = j
        isFirstMsg = false
    end
end

local function formatNick(nick)
    if not nick then return "" end
    return (nick:gsub("_", " "))
end

local function formatAnagramDots(word)
    if not word or #word == 0 then return "" end
    local chars = {}
    local i = 1
    while i <= #word do
        local b = word:byte(i)
        local len = 1
        if b >= 0xF0 then len = 4
        elseif b >= 0xE0 then len = 3
        elseif b >= 0xC0 then len = 2 end
        table.insert(chars, word:sub(i, i + len - 1))
        i = i + len
    end
    return table.concat(chars, ".")
end

local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function pluralScore(n)
    local mod10 = n % 10
    local mod100 = n % 100
    if mod100 >= 11 and mod100 <= 14 then return "баллов" end
    if mod10 == 1 then return "балл" end
    if mod10 >= 2 and mod10 <= 4 then return "балла" end
    return "баллов"
end

local function getGender(nick)
    if not nick then return "m" end
    return genders[nick] or "m"
end

local function genderForms(nick)
    local g = getGender(nick)
    if g == "f" then
        return { heShe = "она", hisHer = "у неё", first = "первая", gave = "дала", won = "победила" }
    end
    return { heShe = "он", hisHer = "у него", first = "первый", gave = "дал", won = "победил" }
end

local function applyPlaceholders(str, extra)
    if not str then return "" end
    extra = extra or {}
    local result = str:gsub("{NICK}", myDisplayNick or "ведущий")
    result = result:gsub("{FRACTION}", "San Fierro News")
    result = result:gsub("{RANK}", "Ведущий")
    result = result:gsub("{TYPE}", currentType or "Математика")
    result = result:gsub("{N}", tostring(screenshots or 0))
    result = result:gsub("{ANSWER}", tostring(extra.answer or "?"))
    result = result:gsub("{MAX_SCORE}", tostring(MAX_SCORE or 20))
    result = result:gsub("{PRIZE_FUND}", tostring(PRIZE_FUND or 500000))
    return result
end

local ANSWER_REVEAL_PHRASES = {
    "Верный ответ был: {ANSWER}",
    "Правильным ответом был: {ANSWER}",
    "А вот и правильный ответ: {ANSWER}",
}

local function capitalizeWord(word)
    if not word or #word == 0 then return "" end
    local cp = u8:decode(word)
    if not cp or #cp == 0 then return word end
    local first = cp:sub(1, 1)
    local rest = cp:sub(2)
    first = cp1251Upper(first)
    local lowerRest = {}
    for i = 1, #rest do
        local ch = rest:sub(i, i)
        lowerRest[i] = ul_rus[ch] or ch
    end
    rest = tbl_concat(lowerRest)
    return u8:encode(first .. rest)
end

local function sendRevealAnswer(answer)
    if not answer then return end
    local ans = tostring(answer)
    if currentMode == "anagram" or currentMode == "vyshibaly" then
        ans = capitalizeWord(ans)
    end
    local phrase = ANSWER_REVEAL_PHRASES[math.random(1, #ANSWER_REVEAL_PHRASES)]
    phrase = phrase:gsub("{ANSWER}", ans)
    sendChat(phrase)
end

local function tryDetectNick()
    if myNick ~= "Unknown" then return true end
    local ok1, id1 = pcall(sampGetPlayerId)
    if ok1 and type(id1) == "number" and id1 >= 0 then
        local nick = sampGetPlayerNickname(id1)
        if nick and type(nick) == "string" and #nick > 0 then
            myNick = nick
            myDisplayNick = nick:gsub("_", " ")
            myId = id1
            logPrint("[SFN] Ваш ник: " .. myNick .. " (ID: " .. myId .. ")")
            logPrint("[SFN] ВАШ ХЕШ: " .. sha256.hash(myNick .. AUTH_SALT))
            return true
        end
    end
    if PLAYER_PED and PLAYER_PED ~= -1 then
        local ok2, isSuccess, id2 = pcall(sampGetPlayerIdByCharHandle, PLAYER_PED)
        if ok2 and isSuccess and type(id2) == "number" and id2 >= 0 then
            local nick = sampGetPlayerNickname(id2)
            if nick and type(nick) == "string" and #nick > 0 then
                myNick = nick
                myDisplayNick = nick:gsub("_", " ")
                myId = id2
                logPrint("[SFN] Ваш ник: " .. myNick .. " (ID: " .. myId .. ")")
                return true
            end
        end
    end
    return false
end

local function ensureDataDir()
    if not doesDirectoryExist(DATA_DIR) then createDirectory(DATA_DIR) end
end

local function writeFile(path, content)
    local file = io.open(path, "w")
    if not file then return false end
    file:write(content); file:flush(); file:close()
    return true
end

local function readFile(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*a"); file:close()
    return content
end

local function saveConfig()
    writeFile(CONFIG_PATH, encodeJson({
        hotkey = HOTKEY, max_score = MAX_SCORE, prize_fund = PRIZE_FUND,
    }))
end

local function ensureConfig()
    if not doesFileExist(CONFIG_PATH) then saveConfig() return end
    local content = readFile(CONFIG_PATH)
    if content and #content > 0 then
        local ok, config = pcall(decodeJson, content)
        if ok and config then
            if type(config.hotkey) == "number" then HOTKEY = config.hotkey end
            if type(config.max_score) == "number" then MAX_SCORE = config.max_score end
            if type(config.prize_fund) == "number" then PRIZE_FUND = config.prize_fund end
        end
    end
end

local function saveScores() writeFile(SCORES_PATH, encodeJson(scores)) end

local function loadScores()
    local content = readFile(SCORES_PATH)
    if not content or #content == 0 then return {} end
    local ok, data = pcall(decodeJson, content)
    if not ok or not data then return {} end
    local result = {}
    for nick, info in pairs(data) do
        if type(info) == "table" then
            result[nick] = { id = tonumber(info.id) or 0, score = tonumber(info.score) or 0 }
        end
    end
    return result
end

local function ensureScores()
    if not doesFileExist(SCORES_PATH) then writeFile(SCORES_PATH, "{}") return end
    scores = loadScores()
end

local function resetScores() scores = {} saveScores() end

local function saveGenders() writeFile(GENDERS_PATH, encodeJson(genders)) end

local function loadGenders()
    local content = readFile(GENDERS_PATH)
    if not content or #content == 0 then return {} end
    local ok, data = pcall(decodeJson, content)
    if not ok or not data then return {} end
    local result = {}
    for nick, g in pairs(data) do
        if g == "m" or g == "f" then result[nick] = g end
    end
    return result
end

local function ensureGenders()
    if not doesFileExist(GENDERS_PATH) then writeFile(GENDERS_PATH, "{}") return end
    genders = loadGenders()
end

local function isAdmin(nick)
    if not nick or nick == "Unknown" then return false end
    local h = sha256.hash(nick .. AUTH_SALT)
    for _, adminHash in ipairs(ADMIN_NICK_HASHES) do
        if h == adminHash then return true end
    end
    return false
end

local function isAllowed(nick)
    if not nick or nick == "Unknown" then return false end
    local h = sha256.hash(nick .. AUTH_SALT)
    for _, allowed in ipairs(ALLOWED_NICK_HASHES) do
        if h == allowed then return true end
    end
    return false
end

local function grantAccess()
    ACCESS_GRANTED = true
    ACCESS_CHECKED = true
    logPrint("[SFN] Доступ разрешён.")
    say(TEXTS.system.loaded_title)
    say(TEXTS.system.loaded_message)
    say(applyPlaceholders(TEXTS.system.loaded_greeting))
    say(TEXTS.system.loaded_help)
    say(TEXTS.system.loaded_bottom)
end

local function checkAutoAccess()
    if ACCESS_GRANTED then return end
    if not myNick or myNick == "Unknown" then return end

    if isAdmin(myNick) then
        logPrint("[SFN] Доступ разрешён администратору.")
        grantAccess()
        return
    end

    if isAllowed(myNick) then
        logPrint("[SFN] Доступ разрешён (ник в списке).")
        grantAccess()
        return
    end

    ACCESS_CHECKED = true
    logPrint("[SFN] Доступ запрещён: ника нет в списке.")
    say("[SFN] У вас нет доступа к скрипту. Обратитесь к Jonny Wilde.")
end

local function makeScreenshot()
    logAction("Делаю скриншот...")
    local wasWindowOpen = WinState[0]
    WinState[0] = false
    wait(300)
    sampSendChat("/time")
    wait(1500)
    setVirtualKeyDown(0x77, true)
    wait(50)
    setVirtualKeyDown(0x77, false)
    wait(300)
    if wasWindowOpen then WinState[0] = true end
    screenshots = screenshots + 1
    say(applyPlaceholders(TEXTS.system.screenshot_done))
end

local function playIntro(efirType)
    local intro = TEXTS.intro
    
    -- Запускаем таймер только если эфир уже идет и время еще не запущено
    if efirRunning and not efirStarted then
        efirStartTime = os.clock()
        efirStarted = true
    end
    
    lua_thread.create(function()
        sendChat(applyPlaceholders(intro.jingle))
        wait(SPEECH_DELAY * 1000)
        for _, line in ipairs(intro.lines) do
            sendChat(applyPlaceholders(line))
            wait(SPEECH_DELAY * 1000)
        end
    end)
end

local function playRules()
    local rulesBlock = TEXTS.rules
    if not rulesBlock then return end
    local lines
    if currentMode == "anagram" then lines = rulesBlock.anagram
    elseif currentMode == "vyshibaly" then lines = rulesBlock.vyshibaly
    else lines = rulesBlock.math end
    if not lines or #lines == 0 then return end
    lua_thread.create(function()
        for _, line in ipairs(lines) do
            sendChat(applyPlaceholders(line))
            wait(SPEECH_DELAY * 1000)
        end
    end)
end

local function playOutro()
    lua_thread.create(function()
        for _, line in ipairs(TEXTS.outro.lines) do
            sendChat(applyPlaceholders(line))
            wait(SPEECH_DELAY * 1000)
        end
    end)
end

local function autoStartEfir(mode)
    currentMode = mode
    if mode == "anagram" then currentType = "Анаграммы"
    elseif mode == "vyshibaly" then currentType = "Вышибалы"
    else currentType = "Математика" end
    currentFirstAnswer = nil
    screenshots = 0
    efirRunning = true
    efirStarted = false
    efirStartTime = 0
end

local function autoStopEfir()
    local totalTime = efirStartTime > 0 and (os.clock() - efirStartTime) or 0
    logAction("Эфир завершён. Время: " .. formatTime(totalTime))
    efirRunning = false
    efirStarted = false
    currentFirstAnswer = nil
end

local function genClassic()
    local n1 = math.random(10, 50); local n2 = math.random(10, 50)
    local n3 = math.random(1, 10); local n4 = math.random(1, 10)
    local ops = {"+", "-"}
    local op1 = ops[math.random(1, 2)]; local op2 = ops[math.random(1, 2)]
    local q = n1 .. " " .. op1 .. " " .. n2 .. " " .. op2 .. " " .. n3 .. " * " .. n4
    local mult = n3 * n4
    local result = (op1 == "+") and (n1 + n2) or (n1 - n2)
    if op2 == "+" then result = result + mult else result = result - mult end
    return q, result
end

local function genAddSub()
    local a = math.random(20, 99); local b = math.random(10, 60)
    if math.random(1, 2) == 1 then return a .. " + " .. b, a + b
    else return a .. " - " .. b, a - b end
end

local function genMultiply()
    local a = math.random(3, 15); local b = math.random(3, 15)
    return a .. " * " .. b, a * b
end

local function genDivide()
    local b = math.random(2, 12); local result = math.random(3, 15)
    local a = b * result
    return a .. " / " .. b, result
end

local function genBrackets()
    local a = math.random(5, 30); local b = math.random(1, 15); local c = math.random(2, 9)
    if math.random(1, 2) == 1 then return "(" .. a .. " + " .. b .. ") * " .. c, (a + b) * c
    else if a < b then a, b = b, a end return "(" .. a .. " - " .. b .. ") * " .. c, (a - b) * c end
end

local function genMixed()
    local a = math.random(2, 12); local b = math.random(2, 12)
    local c = math.random(1, a * b - 1)
    return a .. " * " .. b .. " - " .. c, a * b - c
end

local function genEquation()
    local variant = math.random(1, 5)
    if variant == 1 then
        local x = math.random(2, 50); local a = math.random(2, 50)
        return "x + " .. a .. " = " .. (x + a), x, ", x = ?"
    elseif variant == 2 then
        local a = math.random(2, 30); local x = math.random(a + 1, a + 50)
        return "x - " .. a .. " = " .. (x - a), x, ", x = ?"
    elseif variant == 3 then
        local a = math.random(20, 80); local x = math.random(1, a - 1)
        return a .. " - x = " .. (a - x), x, ", x = ?"
    elseif variant == 4 then
        local a = math.random(2, 12); local x = math.random(2, 12)
        return a .. " * x = " .. (a * x), x, ", x = ?"
    else
        local a = math.random(2, 10); local b = math.random(2, 15)
        return "x / " .. a .. " = " .. b, a * b, ", x = ?"
    end
end

local function generateMath()
    local t
    repeat t = MATH_TYPES[math.random(1, #MATH_TYPES)]
    until t ~= lastMathType or #MATH_TYPES == 1
    lastMathType = t
    local q, a, suffix
    if t == "classic" then q, a = genClassic()
    elseif t == "addsub" then q, a = genAddSub()
    elseif t == "multiply" then q, a = genMultiply()
    elseif t == "divide" then q, a = genDivide()
    elseif t == "brackets" then q, a = genBrackets()
    elseif t == "mixed" then q, a = genMixed()
    elseif t == "equation" then q, a, suffix = genEquation()
    else q, a = genClassic() end
    mathQuestion = q; mathAnswer = a; mathQuestionSuffix = suffix or " = ?"
    currentFirstAnswer = nil
end

local function splitUtf8(str)
    local chars = {}
    local i = 1
    while i <= #str do
        local b = str:byte(i); local len = 1
        if b >= 0xF0 then len = 4
        elseif b >= 0xE0 then len = 3
        elseif b >= 0xC0 then len = 2 end
        table.insert(chars, str:sub(i, i + len - 1))
        i = i + len
    end
    return chars
end

local function shuffleWord(word)
    local chars = splitUtf8(word)
    for i = #chars, 2, -1 do
        local j = math.random(1, i)
        chars[i], chars[j] = chars[j], chars[i]
    end
    return table.concat(chars)
end

local function generateAnagram()
    if #ANAGRAMS == 0 then return end
    anagramWord = ANAGRAMS[math.random(1, #ANAGRAMS)]
    local shuffled = anagramWord
    local attempts = 0
    repeat shuffled = shuffleWord(anagramWord); attempts = attempts + 1
    until shuffled ~= anagramWord or attempts > 20
    anagramShuffled = shuffled
    currentFirstAnswer = nil
end

local function maskWord(word)
    local chars = splitUtf8(word)
    local total = #chars
    if total < 3 then return word end
    local ratio = 0.40 + math.random() * 0.15
    local hideCount = math.floor(total * ratio)
    hideCount = math.max(hideCount, total >= 8 and 4 or 3)
    hideCount = math.min(hideCount, total - 1)
    local candidates = {}
    for i = 2, total - 2 do table.insert(candidates, i) end
    if #candidates < hideCount then
        candidates = {}
        for i = 1, total do table.insert(candidates, i) end
    end
    for i = #candidates, 2, -1 do
        local j = math.random(1, i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end
    local maskSet = {}
    for i = 1, math.min(hideCount, #candidates) do
        maskSet[candidates[i]] = true
    end
    local placeholder = (math.random(1, 2) == 1) and "*" or "_"
    local result = {}
    for i = 1, total do
        if maskSet[i] then result[i] = placeholder
        else result[i] = chars[i] end
    end
    return table.concat(result)
end

local function generateVyshibaly()
    if #VYSHIBALY_WORDS == 0 then return end
    vyshibalyWord = VYSHIBALY_WORDS[math.random(1, #VYSHIBALY_WORDS)]
    local attempts = 0
    repeat vyshibalyMasked = maskWord(vyshibalyWord); attempts = attempts + 1
    until vyshibalyMasked ~= vyshibalyWord or attempts > 20
    currentFirstAnswer = nil
end

local function tryParseAnswer(text, source)
    if not text then return false end
    local utf8text = u8:encode(text) or text
    local bufNick, bufId = utf8text:match(PATTERN_NICK_WITH_ID)
    local cleaned = utf8text:gsub("%[%d+:%d+:%d+%]", ""):gsub("%[%d+%]", "")
    local pattern = (currentMode == "anagram" or currentMode == "vyshibaly")
        and PATTERN_ANAGRAM_MESSAGE or PATTERN_AIR_MESSAGE_SIGNED
    local answer = cleaned:match(pattern)
    if not answer or not bufNick then return false end
    if not efirRunning then return true end

    if currentMode == "math" then
        local cleanAnswer = answer:gsub("%s+", "")
        local numAnswer = tonumber(cleanAnswer)
        if numAnswer and numAnswer == mathAnswer and not currentFirstAnswer then
            currentFirstAnswer = { nick = bufNick, id = tonumber(bufId),
                answer = cleanAnswer, time = os.clock() }
        end
    elseif currentMode == "anagram" then
        if normalizeAnswer(u8:decode(answer)) == normalizeAnswer(u8:decode(anagramWord))
           and not currentFirstAnswer then
            currentFirstAnswer = { nick = bufNick, id = tonumber(bufId),
                answer = answer, time = os.clock() }
        end
    elseif currentMode == "vyshibaly" then
        if normalizeAnswer(u8:decode(answer)) == normalizeAnswer(u8:decode(vyshibalyWord))
           and not currentFirstAnswer then
            currentFirstAnswer = { nick = bufNick, id = tonumber(bufId),
                answer = answer, time = os.clock() }
        end
    end
    return true
end

local function handleChatText(text, source)
    if not text then return end
    if ACCESS_GRANTED then tryParseAnswer(text, source) end
end

if sampev_ok and sampev then
    function sampev.onServerMessage(color, text) handleChatText(text, "SE-SERVER") end
    function sampev.onChatMessage(playerId, text) handleChatText(text, "SE-CHAT") end
end

local function applyCorrectAnswer(nick, id)
    if not scores[nick] then scores[nick] = { id = id, score = 0 } end
    scores[nick].score = scores[nick].score + 1
    scores[nick].id = id
    saveScores()
    local sc = scores[nick].score
    local f = genderForms(nick)
    sendChat(string.format("%s %s %s правильный ответ и %s %d %s",
        formatNick(nick), f.first, f.gave, f.hisHer, sc, pluralScore(sc)))
    currentFirstAnswer = nil
    pendingGenderConfirm = nil
    local revealAnswer
    if currentMode == "anagram" then revealAnswer = anagramWord
    elseif currentMode == "vyshibaly" then revealAnswer = vyshibalyWord
    else revealAnswer = mathAnswer end
    lua_thread.create(function()
        wait(5000)
        if revealAnswer then sendRevealAnswer(revealAnswer) end
    end)
end

local function confirmCorrect()
    if not currentFirstAnswer then say(TEXTS.system.no_answer) return end
    local nick = currentFirstAnswer.nick
    local id = currentFirstAnswer.id
    if not genders[nick] then
        pendingGenderConfirm = { nick = nick, id = id }
        genderWindowOpen[0] = true
        return
    end
    applyCorrectAnswer(nick, id)
end

local function sendTopScores()
    local sorted = {}
    for nick, info in pairs(scores) do
        table.insert(sorted, { nick = nick, id = info.id, score = info.score })
    end
    if #sorted == 0 then say(TEXTS.system.no_scores) return end
    table.sort(sorted, function(a, b)
        if a.score == b.score then return a.nick < b.nick end
        return a.score > b.score
    end)
    local groups = {}; local currentGroup = nil
    for _, item in ipairs(sorted) do
        if not currentGroup or currentGroup.score ~= item.score then
            currentGroup = { score = item.score, players = { item }, rank = #groups + 1 }
            table.insert(groups, currentGroup)
        else
            table.insert(currentGroup.players, item)
        end
    end
    lua_thread.create(function()
        local intro = TEXTS.scores_intros[math.random(1, #TEXTS.scores_intros)]
        sendChat(applyPlaceholders(intro))
        wait(5000)
        local maxGroups = math.min(#groups, 3)
        for i = 1, maxGroups do
            local group = groups[i]
            local nicks = {}
            for _, player in ipairs(group.players) do
                table.insert(nicks, formatNick(player.nick))
            end
            local namesStr
            if #nicks == 1 then namesStr = nicks[1]
            elseif #nicks == 2 then namesStr = nicks[1] .. " и " .. nicks[2]
            else namesStr = table.concat(nicks, ", ", 1, #nicks - 1) .. " и " .. nicks[#nicks] end
            local msg
            if #group.players == 1 then
                local f = genderForms(group.players[1].nick)
                msg = string.format("На %s месте — %s, %s %d %s!",
                    tostring(group.rank), namesStr, f.hisHer, group.score, pluralScore(group.score))
            else
                msg = string.format("На %s месте — %s, у них по %d %s!",
                    tostring(group.rank), namesStr, group.score, pluralScore(group.score))
            end
            sendChat(msg)
            wait(5000)
        end
        if #groups > 3 then
            local restLines = {}
            for i = 4, #groups do
                local group = groups[i]
                local nicks = {}
                for _, player in ipairs(group.players) do
                    table.insert(nicks, formatNick(player.nick))
                end
                local namesStr
                if #nicks == 1 then namesStr = nicks[1]
                elseif #nicks == 2 then namesStr = nicks[1] .. " и " .. nicks[2]
                else namesStr = table.concat(nicks, ", ", 1, #nicks - 1) .. " и " .. nicks[#nicks] end
                table.insert(restLines, string.format("%s (%d %s)",
                    namesStr, group.score, pluralScore(group.score)))
            end
            sendPacked(restLines, "Также баллы набрали: ", "Также: ")
        end
    end)
end

local function sendAdvertisement()
    local adv = TEXTS.advertisement
    lua_thread.create(function()
        sendChat(adv.jingle); wait(5000)
        sendChat(applyPlaceholders(adv.intros[math.random(1, #adv.intros)])); wait(5000)
        for _, line in ipairs(adv.blocks[math.random(1, #adv.blocks)]) do
            sendChat(applyPlaceholders(line)); wait(5000)
        end
        sendChat(adv.jingle); wait(5000)
    end)
end

-- ============================================================
-- MODERN UI LAYER  ·  визуальный слой (редизайн)
-- Логика, ID виджетов и обработчики сохранены без изменений.
-- ============================================================

local THEME = {
    width = 356.0,
    radius = 14.0,
    padding = 14.0,
    gap = 8.0,
    colors = {
        bgTop    = {0.058, 0.066, 0.090, 0.970},
        bgBot    = {0.086, 0.098, 0.132, 0.970},
        surface  = {0.106, 0.118, 0.153, 0.920},
        surface2 = {0.150, 0.165, 0.208, 0.950},
        border   = {0.320, 0.360, 0.460, 0.420},
        inner    = {1.000, 1.000, 1.000, 0.045},
        shadow   = {0.000, 0.000, 0.000, 0.320},
        text     = {0.945, 0.958, 0.985, 1.000},
        muted    = {0.565, 0.615, 0.710, 1.000},
        faint    = {0.420, 0.465, 0.560, 1.000},
        accent   = {0.290, 0.620, 1.000, 1.000},
        accent2  = {0.560, 0.380, 0.990, 1.000},
        success  = {0.220, 0.840, 0.490, 1.000},
        warning  = {1.000, 0.720, 0.240, 1.000},
        danger   = {0.990, 0.330, 0.380, 1.000},
        purple   = {0.650, 0.400, 0.980, 1.000},
        gold     = {1.000, 0.780, 0.290, 1.000},
        silver   = {0.770, 0.820, 0.900, 1.000},
        bronze   = {0.880, 0.570, 0.340, 1.000},
    }
}

local C = THEME.colors

-- ------------------------------------------------------------
-- СОСТОЯНИЕ АНИМАЦИЙ (лёгкие: lerp + синус, без тяжёлых эффектов)
-- ------------------------------------------------------------
local anim_alpha = 0.0          -- плавное появление/исчезновение окна
local gender_anim = 0.0         -- плавное появление модального окна пола
local ui_time = 0.0             -- общее время UI (для синус-эффектов)
local frame_dt = 0.016          -- дельта последнего кадра
local last_time = os.clock()
local ctx_alpha = 1.0           -- альфа текущего рисуемого окна
local widgetAnim = {}           -- сглаженные состояния hover/press виджетов
local genderSnap = nil          -- снимок данных для fade-out модального окна
local faKey, faGlowT = nil, -10.0 -- однократная вспышка карточки ответа

local CF = imgui.DrawCornerFlags
local HAS_HOVERRECT = (imgui.IsMouseHoveringRect ~= nil)

local function V2(x, y) return imgui.ImVec2(x, y) end
local function V4(r, g, b, a) return imgui.ImVec4(r, g, b, a) end

local function clamp01(v)
    if v ~= v then return 0.0 end
    if v < 0.0 then return 0.0 end
    if v > 1.0 then return 1.0 end
    return v
end

local function Col(color, alphaMultiplier)
    local a = (alphaMultiplier or 1.0) * (color[4] or 1.0) * (ctx_alpha or 1.0)
    return imgui.ColorConvertFloat4ToU32(V4(color[1], color[2], color[3], clamp01(a)))
end

local function WithA(c, a) return { c[1], c[2], c[3], a } end

local function MixCol(c1, c2, t)
    t = clamp01(t)
    local a1, a2 = c1[4] or 1.0, c2[4] or 1.0
    return {
        c1[1] + (c2[1] - c1[1]) * t,
        c1[2] + (c2[2] - c1[2]) * t,
        c1[3] + (c2[3] - c1[3]) * t,
        a1 + (a2 - a1) * t,
    }
end

local function SmoothTo(cur, target, rate)
    local k = rate * frame_dt
    if k > 1.0 then k = 1.0 elseif k < 0.0 then k = 0.0 end
    return cur + (target - cur) * k
end

local function GetAnim(id)
    local s = widgetAnim[id]
    if not s then s = { h = 0.0, a = 0.0 } widgetAnim[id] = s end
    return s
end

-- ------------------------------------------------------------
-- ШРИФТЫ (загружаются один раз при инициализации)
-- ------------------------------------------------------------
local FONTS = {}

local function PushF(name)
    local f = FONTS[name]
    if f ~= nil and imgui.PushFont ~= nil then
        if pcall(imgui.PushFont, f) then return true end
    end
    return false
end

local function PopF(pushed)
    if pushed and imgui.PopFont ~= nil then pcall(imgui.PopFont) end
end

local function TextSize(text, fname)
    local p = PushF(fname)
    local s = imgui.CalcTextSize(text or "")
    PopF(p)
    return s
end

local function DText(dl, pos, u32col, text, fname, shadow)
    local p = PushF(fname)
    if shadow then dl:AddText(pos + V2(0, 1), Col({0.0, 0.0, 0.0, shadow}), text) end
    dl:AddText(pos, u32col, text)
    PopF(p)
end

local settingBuffers = {}

local BUTTON_KINDS = {
    primary = { bg = C.accent,   hover = {0.400, 0.700, 1.000, 1.000}, active = {0.190, 0.520, 0.900, 1.000}, border = false },
    success = { bg = C.success,  hover = {0.340, 0.920, 0.580, 1.000}, active = {0.160, 0.700, 0.380, 1.000}, border = false },
    danger  = { bg = C.danger,   hover = {1.000, 0.420, 0.470, 1.000}, active = {0.800, 0.220, 0.270, 1.000}, border = false },
    warning = { bg = C.warning,  hover = {1.000, 0.800, 0.380, 1.000}, active = {0.860, 0.600, 0.140, 1.000}, border = false },
    purple  = { bg = C.purple,   hover = {0.740, 0.500, 1.000, 1.000}, active = {0.530, 0.290, 0.860, 1.000}, border = false },
    neutral = { bg = C.surface2, hover = {0.205, 0.222, 0.275, 1.000}, active = {0.130, 0.142, 0.180, 1.000}, border = true },
    ghost   = { bg = {0.130, 0.143, 0.180, 0.600}, hover = {0.180, 0.196, 0.240, 0.900}, active = {0.110, 0.120, 0.150, 0.950}, border = true, flat = true },
}

local function ModernButton(id, label, width, height, kind, onClick)
    local dl = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local size = V2(width, height)
    local clicked = imgui.InvisibleButton(id, size)
    local hovered = imgui.IsItemHovered()
    local active = imgui.IsItemActive()

    -- плавные hover/press переходы (экспоненциальное сглаживание)
    local s = GetAnim(id)
    s.h = SmoothTo(s.h, hovered and 1.0 or 0.0, 13.0)
    s.a = SmoothTo(s.a, active and 1.0 or 0.0, 22.0)
    if s.h < 0.003 then s.h = 0.0 end
    if s.a < 0.003 then s.a = 0.0 end

    local k = BUTTON_KINDS[kind] or BUTTON_KINDS.neutral
    local base = MixCol(k.bg, k.hover, s.h)
    base = MixCol(base, k.active, s.a)

    local sink = s.a * 1.5
    local p = pos + V2(0, sink)
    local r = THEME.radius - 3

    -- мягкое свечение при наведении
    if not k.flat and s.h > 0.02 then
        local g = 2.0 + 2.0 * s.h
        dl:AddRectFilled(pos + V2(-g, -g), pos + size + V2(g, g), Col(WithA(k.bg, 0.13 * s.h)), r + 4)
    end
    -- тень
    if not k.flat then
        dl:AddRectFilled(pos + V2(1, 3), pos + size + V2(-1, 5), Col(WithA(C.shadow, 0.45 + 0.25 * s.h)), r)
    end
    -- корпус
    dl:AddRectFilled(p, p + size, Col(base), r)
    if k.border then
        -- Убрали динамическую толщину, оставили четкую линию в 1 пиксель
        dl:AddRect(p, p + size, Col(MixCol(C.border, C.accent, s.h * 0.75)), r, 0, 1.0)
    end
    -- верхний блик (объём)
    dl:AddRectFilled(p + V2(r, 1.2), p + V2(width - r, 2.2), Col(WithA({1.0, 1.0, 1.0, 1.0}, 0.06 + 0.10 * s.h)), 0.0)

    local ts = TextSize(label, "semi")
    DText(dl, p + V2((width - ts.x) * 0.5, (height - ts.y) * 0.5 - 1.0), Col(C.text), label, "semi")

    if clicked and onClick then onClick() end
end

local function SectionTitle(text)
    local dl = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local w = imgui.GetContentRegionAvail().x
    local ts = TextSize(text, "small")
    -- акцентная метка + заголовок + затухающая линия
    dl:AddRectFilled(pos + V2(0, 2), pos + V2(3, 13), Col(C.accent), 1.5)
    DText(dl, pos + V2(9, 0), Col(C.muted), text, "small")
    local lx = pos.x + 9 + ts.x + 12
    local ly = pos.y + 7.5
    if lx < pos.x + w - 8 then
        local mid = lx + (pos.x + w - lx) * 0.45
        dl:AddRectFilled(V2(lx, ly), V2(mid, ly + 1), Col(WithA(C.border, 0.90)), 0)
        dl:AddRectFilled(V2(mid, ly), V2(pos.x + w, ly + 1), Col(WithA(C.border, 0.35)), 0)
    end
    imgui.Dummy(V2(w, 22))
end

local function StatTile(label, value, color, width, height)
    local dl = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local r = THEME.radius - 3
    dl:AddRectFilled(pos, pos + V2(width, height), Col(C.surface), r)
    dl:AddRect(pos, pos + V2(width, height), Col(C.inner), r, 0, 1.0)
    dl:AddRectFilled(pos + V2(0, 12), pos + V2(3.5, height - 12), Col(color), 1.75)
    DText(dl, pos + V2(14, 9), Col(C.muted), label, "small")
    DText(dl, pos + V2(14, 28), Col(color), value, "big", 0.30)
    imgui.Dummy(V2(width, height))
end

local function DrawQuestionCard()
    local dl = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local w = imgui.GetContentRegionAvail().x
    local r = THEME.radius - 2

    local title, main, sub, color = "ВОПРОС", "", "", C.accent

    if currentMode == "math" then
        title = "ТЕКУЩИЙ ПРИМЕР"
        main = tostring(mathQuestion or "") .. tostring(mathQuestionSuffix or "")
        color = C.warning
    elseif currentMode == "anagram" then
        title = "АНАГРАММА"
        main = formatAnagramDots(tostring(anagramShuffled or ""))
        sub = "Ответ: " .. tostring(anagramWord or "")
        color = C.accent
    else
        title = "ВЫШИБАЛЫ"
        main = tostring(vyshibalyMasked or "")
        sub = "Ответ: " .. tostring(vyshibalyWord or "")
        color = C.purple
    end

    local mainColor = color
    if main == "" then main = "-"; mainColor = C.faint end

    local h = (sub ~= "") and 90.0 or 68.0
    dl:AddRectFilled(pos, pos + V2(w, h), Col(C.surface), r)
    dl:AddRect(pos, pos + V2(w, h), Col(WithA(color, 0.30)), r, 0, 1.0)

    -- акцентная полоса сверху + медленный бегущий блик
    local x0, x1 = pos.x + r, pos.x + w - r
    dl:AddRectFilled(V2(x0, pos.y), V2(x1, pos.y + 3), Col(WithA(color, 0.85)), 0)
    local span = x1 - x0
    local sweepW = 70.0
    local ph = (ui_time * 0.30) % 2.0
    if ph < 1.0 and span > sweepW then
        local cx0 = x0 + ph * (span + sweepW) - sweepW * 0.5
        local segA = { 0.10, 0.30, 0.30, 0.10 }
        for seg = 1, 4 do
            local sx0 = cx0 + (seg - 1) * (sweepW * 0.25)
            local sx1 = sx0 + sweepW * 0.25
            if sx0 < x0 then sx0 = x0 end
            if sx1 > x1 then sx1 = x1 end
            if sx1 > sx0 then
                dl:AddRectFilled(V2(sx0, pos.y), V2(sx1, pos.y + 3), Col(WithA({1.0, 1.0, 1.0, 1.0}, segA[seg])), 0)
            end
        end
    end

    -- маркер + тексты
    dl:AddCircleFilled(pos + V2(15.5, 18.5), 2.6, Col(color), 12)
    DText(dl, pos + V2(24, 12), Col(C.muted), title, "small")
    DText(dl, pos + V2(14, 31), Col(mainColor), main, "big", 0.35)
    if sub ~= "" then
        DText(dl, pos + V2(14, 61), Col(C.success), sub, "semi")
    end
    imgui.Dummy(V2(w, h + THEME.gap))
end

local function DrawFirstAnswerCard()
    local dl = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local w = imgui.GetContentRegionAvail().x
    local h = 66.0
    local r = THEME.radius - 2

    if currentFirstAnswer then
        -- однократная мягкая вспышка при появлении ответа
        local key = tostring(currentFirstAnswer.nick) .. "@" .. tostring(currentFirstAnswer.time)
        if key ~= faKey then faKey = key faGlowT = ui_time end
        local gt = ui_time - faGlowT
        local pulse = 0.0
        if gt >= 0.0 and gt < 1.5 then
            pulse = 1.0 - (gt / 1.5)
            pulse = pulse * pulse
        end

        if pulse > 0.01 then
            dl:AddRectFilled(pos + V2(-3, -3), pos + V2(w + 3, h + 3), Col(WithA(C.success, 0.22 * pulse)), r + 3)
        end
        dl:AddRectFilled(pos, pos + V2(w, h), Col(WithA(C.success, 0.10 + 0.05 * pulse)), r)
        dl:AddRect(pos, pos + V2(w, h), Col(WithA(C.success, 0.45 + 0.25 * pulse)), r, 0, 1.0)
        dl:AddRectFilled(pos + V2(r, 0), pos + V2(w - r, 2.5), Col(WithA(C.success, 0.75)), 0)

        DText(dl, pos + V2(14, 10), Col(C.muted), "ПЕРВЫЙ ОТВЕТ", "small")
        local line1 = formatNick(currentFirstAnswer.nick or "???") .. " - "
        local tw = TextSize(line1, "semi")
        DText(dl, pos + V2(14, 33), Col(C.text), line1, "semi")
        DText(dl, pos + V2(14 + tw.x, 33), Col(C.success), tostring(currentFirstAnswer.answer or ""), "semi")
    else
        dl:AddRectFilled(pos, pos + V2(w, h), Col(C.surface), r)
        dl:AddRect(pos, pos + V2(w, h), Col(C.inner), r, 0, 1.0)
        DText(dl, pos + V2(14, 10), Col(C.muted), "ПЕРВЫЙ ОТВЕТ", "small")
        -- "дыхание" текста ожидания + анимированное многоточие
        local dots = string.rep(".", 1 + math.floor(ui_time * 2.0) % 3)
        local breathe = 0.65 + 0.35 * (0.5 + 0.5 * math.sin(ui_time * 3.0))
        DText(dl, pos + V2(14, 33), Col(C.faint, breathe), "Ожидание ответа" .. dots, "body")
    end
    imgui.Dummy(V2(w, h))
end

local function DrawHeader(onClose)
    local dl = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local w = imgui.GetContentRegionAvail().x
    local h = 64.0

    -- логотип: градиентная плитка с символом эфира
    local ls = 36.0
    local lp = pos + V2(0, 3)
    dl:AddRectFilled(lp + V2(1, 3), lp + V2(ls + 1, ls + 4), Col(WithA(C.shadow, 0.40)), 11)
    dl:AddRectFilled(lp, lp + V2(ls, ls), Col(C.accent), 11)
    dl:AddRectFilled(lp + V2(0, ls * 0.55), lp + V2(ls, ls), Col(WithA(C.accent2, 0.40)), 11)
    dl:AddRectFilled(lp + V2(5, 1.3), lp + V2(ls - 5, 2.3), Col(WithA({1.0, 1.0, 1.0, 1.0}, 0.25)), 0)
    local lcx, lcy = lp.x + ls * 0.5 + 1.5, lp.y + ls * 0.5
    dl:AddTriangleFilled(V2(lcx - 5, lcy - 7), V2(lcx - 5, lcy + 7), V2(lcx + 7, lcy), Col(WithA({1.0, 1.0, 1.0, 1.0}, 0.95)))

    -- заголовок и подзаголовок
    local tx = pos.x + ls + 12
    DText(dl, V2(tx, pos.y + 1), Col(C.text), "SFN Helper", "title", 0.35)
    local sub = efirRunning and ("Эфир · " .. tostring(currentType or "")) or "Панель управления"
    sub = sub .. " · v" .. tostring(CURRENT_VERSION or "")
    DText(dl, V2(tx + 1, pos.y + 30), Col(C.muted), sub, "small")

    -- статус-пилюля LIVE/IDLE
    local statusText = efirRunning and "LIVE" or "IDLE"
    local statusColor = efirRunning and C.success or C.muted
    local sts = TextSize(statusText, "semi")
    local pillW, pillH, closeW = sts.x + 30.0, 25.0, 27.0
    local pillX = pos.x + w - pillW - closeW - 9.0
    local pillY = pos.y + 6.0
    dl:AddRectFilled(V2(pillX, pillY), V2(pillX + pillW, pillY + pillH), Col(WithA(C.surface2, 0.85)), pillH * 0.5)
    dl:AddRect(V2(pillX, pillY), V2(pillX + pillW, pillY + pillH), Col(WithA(statusColor, 0.30)), pillH * 0.5, 0, 1.0)
    local dcx, dcy = pillX + 14.0, pillY + pillH * 0.5
    if efirRunning then
        -- расходящееся кольцо пульса
        local ringT = (ui_time % 1.9) / 1.9
        dl:AddCircle(V2(dcx, dcy), 4.5 + ringT * 6.0, Col(WithA(statusColor, 0.40 * (1.0 - ringT))), 20, 1.2)
    end
    local pulse = efirRunning and (0.5 + 0.5 * math.sin(ui_time * 4.2)) or 0.0
    dl:AddCircleFilled(V2(dcx, dcy), 4.0, Col(WithA(statusColor, 0.55 + 0.45 * pulse)), 18)
    DText(dl, V2(pillX + 24.0, pillY + (pillH - sts.y) * 0.5 - 1.0), Col(statusColor), statusText, "semi")

    -- кнопка закрытия (плавный hover, крестик линиями)
    local cs = GetAnim("hdr_close")
    local cx0, cy0 = pos.x + w - closeW, pos.y + 5.0
    imgui.SetCursorScreenPos(V2(cx0, cy0))
    local closeClicked = imgui.InvisibleButton("header_close", V2(closeW, closeW))
    local closeHovered = imgui.IsItemHovered()
    local closeActive = imgui.IsItemActive()
    cs.h = SmoothTo(cs.h, closeHovered and 1.0 or 0.0, 15.0)
    cs.a = SmoothTo(cs.a, closeActive and 1.0 or 0.0, 22.0)
    local cbg = MixCol(C.surface2, C.danger, clamp01(cs.h * 0.85 + cs.a))
    dl:AddRectFilled(V2(cx0, cy0), V2(cx0 + closeW, cy0 + closeW), Col(cbg), 9)
    if cs.h > 0.02 then
        dl:AddRect(V2(cx0, cy0), V2(cx0 + closeW, cy0 + closeW), Col(WithA(C.danger, 0.45 * cs.h)), 9, 0, 1.2)
    end
    local kk = 4.4
    local ccx, ccy = cx0 + closeW * 0.5, cy0 + closeW * 0.5
    local xcol = MixCol(C.muted, {1.0, 1.0, 1.0, 1.0}, clamp01(cs.h + cs.a))
    dl:AddLine(V2(ccx - kk, ccy - kk), V2(ccx + kk, ccy + kk), Col(xcol), 1.7)
    dl:AddLine(V2(ccx - kk, ccy + kk), V2(ccx + kk, ccy - kk), Col(xcol), 1.7)
    if closeClicked and onClose then onClose() end

    -- разделитель с акцентным сегментом
    imgui.SetCursorScreenPos(pos)
    local sy = pos.y + h - 8
    dl:AddRectFilled(V2(pos.x + 2, sy), V2(pos.x + w - 2, sy + 1), Col(WithA(C.border, 0.55)), 0)
    dl:AddRectFilled(V2(pos.x + 2, sy), V2(pos.x + 78, sy + 1.6), Col(WithA(C.accent, 0.85)), 0)
    imgui.Dummy(V2(w, h))
end

local function SettingRow(id, label, value, minVal, maxVal, onSave)
    local dl = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local w = imgui.GetContentRegionAvail().x
    local h = 40.0
    local r = THEME.radius - 4

    dl:AddRectFilled(pos, pos + V2(w, h), Col(C.surface), r)
    dl:AddRect(pos, pos + V2(w, h), Col(C.inner), r, 0, 1.0)

    local lsts = TextSize(label, "body")
    DText(dl, pos + V2(12, (h - lsts.y) * 0.5 - 1), Col(C.muted), label, "body")

    local vs = tostring(value or 0)
    local vts = TextSize(vs, "semi")
    DText(dl, pos + V2(w - vts.x - 44, (h - vts.y) * 0.5 - 1), Col(C.text), vs, "semi")

    local bx, by, bs = pos.x + w - 34.0, pos.y + (h - 26.0) * 0.5, 26.0
    imgui.SetCursorScreenPos(V2(bx, by))
    local editClicked = imgui.InvisibleButton("edit_" .. id, V2(bs, bs))
    local editHovered = imgui.IsItemHovered()
    local editActive = imgui.IsItemActive()

    -- плавная подсветка кнопки редактирования + три точки
    local es = GetAnim("edit_" .. id)
    es.h = SmoothTo(es.h, editHovered and 1.0 or 0.0, 14.0)
    es.a = SmoothTo(es.a, editActive and 1.0 or 0.0, 22.0)
    local ebg = MixCol(C.surface2, C.accent, clamp01(es.h * 0.55 + es.a))
    dl:AddRectFilled(V2(bx, by), V2(bx + bs, by + bs), Col(ebg), 8)
    local dotCol = MixCol(C.muted, {1.0, 1.0, 1.0, 1.0}, clamp01(es.h + es.a))
    for i = -1, 1 do
        dl:AddCircleFilled(V2(bx + bs * 0.5 + i * 4.0, by + bs * 0.5), 1.5, Col(dotCol), 8)
    end

    if editClicked then
        settingBuffers[id] = new.int(value or 0)
        imgui.OpenPopup("popup_" .. id)
    end

    imgui.SetCursorScreenPos(pos)
    imgui.Dummy(V2(w, h + 4))

    if imgui.BeginPopupModal("popup_" .. id, nil, imgui.WindowFlags.AlwaysAutoResize) then
        imgui.Text(label)
        imgui.Dummy(V2(0, 6))
        imgui.PushItemWidth(170)
        local buf = settingBuffers[id] or new.int(value or 0)
        settingBuffers[id] = buf
        if imgui.InputInt("##" .. id, buf, 0, 0, imgui.InputTextFlags.EnterReturnsTrue) then
            local nv = buf[0]
            if nv >= minVal and nv <= maxVal then onSave(nv) end
            imgui.CloseCurrentPopup()
        end
        imgui.PopItemWidth()
        imgui.Dummy(V2(0, 8))
        if imgui.Button("Сохранить", V2(82, 28)) then
            local nv = buf[0]
            if nv >= minVal and nv <= maxVal then onSave(nv) end
            imgui.CloseCurrentPopup()
        end
        imgui.SameLine()
        if imgui.Button("Отмена", V2(82, 28)) then imgui.CloseCurrentPopup() end
        imgui.EndPopup()
    end
end

local function DrawOffline()
    local w = imgui.GetContentRegionAvail().x
    local half = (w - THEME.gap) * 0.5

    SectionTitle("НАСТРОЙКИ ЭФИРА")
    SettingRow("max_scores", "Максимум баллов", MAX_SCORE, 1, 999, function(v) MAX_SCORE = v; saveConfig() end)
    SettingRow("fund", "Призовой фонд", PRIZE_FUND, 0, 999999999, function(v) PRIZE_FUND = v; saveConfig() end)

    imgui.Dummy(V2(0, THEME.gap))
    SectionTitle("ЗАПУСК ЭФИРА")

    ModernButton("start_math", "МАТЕМАТИКА", half, 40, "success", function() autoStartEfir("math"); generateMath() end)
    imgui.SameLine(0, THEME.gap)
    ModernButton("start_anagram", "АНАГРАММА", half, 40, "primary", function() autoStartEfir("anagram"); generateAnagram() end)

    imgui.Dummy(V2(0, THEME.gap))
    ModernButton("start_vysh", "ВЫШИБАЛЫ", w, 40, "purple", function() autoStartEfir("vyshibaly"); generateVyshibaly() end)
end

local function DrawLeaderboard()
    local w = imgui.GetContentRegionAvail().x
    SectionTitle("РЕЙТИНГ ИГРОКОВ")

    local list = {}
    for nick, info in pairs(scores) do
        table.insert(list, { nick = nick, score = info.score or 0 })
    end
    table.sort(list, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return tostring(a.nick) < tostring(b.nick)
    end)

    local rowH = 30.0
    local rowCount = math.min(8, #list)
    local listHeight = (rowCount > 0) and (rowCount * rowH + 2.0) or 38.0
    imgui.BeginChild("##sfn_leaderboard", V2(w, listHeight), false)
    local cw = imgui.GetContentRegionAvail().x
    local cdl = imgui.GetWindowDrawList()

    if rowCount == 0 then
        DText(cdl, imgui.GetCursorScreenPos() + V2(2, 9), Col(C.faint), "Пока нет баллов", "small")
    else
        local medals = { C.gold, C.silver, C.bronze }
        for i = 1, rowCount do
            local item = list[i]
            local rpos = imgui.GetCursorScreenPos()
            local rh = rowH - 6.0

            local bg = WithA(C.surface, 0.55)
            if i == 1 then bg = {0.235, 0.188, 0.085, 0.920}
            elseif i == 2 then bg = {0.152, 0.163, 0.198, 0.920}
            elseif i == 3 then bg = {0.222, 0.148, 0.098, 0.920} end

            cdl:AddRectFilled(rpos, rpos + V2(cw, rh), Col(bg), 8.0)
            if i <= 3 then
                cdl:AddRect(rpos, rpos + V2(cw, rh), Col(WithA(medals[i], 0.30)), 8.0, 0, 1.0)
            end

            -- мягкая подсветка строки под курсором
            if HAS_HOVERRECT then
                local rs = GetAnim("lbrow" .. i)
                local hv = imgui.IsMouseHoveringRect(rpos, rpos + V2(cw, rh)) and 1.0 or 0.0
                rs.h = SmoothTo(rs.h, hv, 12.0)
                if rs.h > 0.02 then
                    cdl:AddRectFilled(rpos, rpos + V2(cw, rh), Col(WithA({1.0, 1.0, 1.0, 1.0}, 0.045 * rs.h)), 8.0)
                end
            end

            if i <= 3 then
                -- медаль с номером
                local mcx, mcy = rpos.x + 18.0, rpos.y + rh * 0.5
                cdl:AddCircleFilled(V2(mcx, mcy), 8.6, Col(medals[i]), 20)
                local ns = TextSize(tostring(i), "semi")
                DText(cdl, V2(mcx - ns.x * 0.5, mcy - ns.y * 0.5 - 1), Col({0.10, 0.09, 0.05, 1.0}), tostring(i), "semi")
            else
                local its = TextSize(tostring(i) .. ".", "small")
                DText(cdl, rpos + V2(10, (rh - its.y) * 0.5 - 1), Col(C.faint), tostring(i) .. ".", "small")
            end

            local nh = TextSize("Ы", "body").y
            DText(cdl, rpos + V2(34, (rh - nh) * 0.5 - 1), Col(i <= 3 and C.text or WithA(C.text, 0.90)), formatNick(item.nick or "???"), "body")

            local scoreStr = tostring(item.score) .. " " .. pluralScore(item.score)
            local ss = TextSize(scoreStr, "semi")
            DText(cdl, rpos + V2(cw - ss.x - 10, (rh - ss.y) * 0.5 - 1), Col(i == 1 and C.gold or C.success), scoreStr, "semi")

            imgui.Dummy(V2(cw, rowH))
        end
    end
    imgui.EndChild()
    imgui.Dummy(V2(0, THEME.gap))
    ModernButton("clear_scores", "ОЧИСТИТЬ БАЗУ", w, 32, "ghost", function() imgui.OpenPopup("confirm_clear_scores") end)

    if imgui.BeginPopupModal("confirm_clear_scores", nil, imgui.WindowFlags.AlwaysAutoResize) then
        imgui.Text("Очистить базу баллов?")
        imgui.Text("Это действие нельзя отменить.")
        imgui.Dummy(V2(0, 10))
        if imgui.Button("Да, очистить", V2(120, 30)) then
            resetScores(); say(TEXTS.system.base_cleared); imgui.CloseCurrentPopup()
        end
        imgui.SameLine()
        if imgui.Button("Отмена", V2(120, 30)) then imgui.CloseCurrentPopup() end
        imgui.EndPopup()
    end
end

local function DrawLive()
    local w = imgui.GetContentRegionAvail().x
    local half = (w - THEME.gap) * 0.5
    local totalTime = efirStarted and (os.clock() - efirStartTime) or 0

    SectionTitle("СТАТИСТИКА")
    StatTile("ВРЕМЯ", formatTime(totalTime), C.accent, w, 62)

    imgui.Dummy(V2(0, THEME.gap))
    SectionTitle("ТЕКУЩИЙ ВОПРОС")
    DrawQuestionCard()
    DrawFirstAnswerCard()

    imgui.Dummy(V2(0, THEME.gap))

    if currentFirstAnswer then
        ModernButton("confirm_answer", "ВЕРНЫЙ ОТВЕТ", w, 38, "success", confirmCorrect)
        imgui.Dummy(V2(0, THEME.gap))
    end

    SectionTitle("УПРАВЛЕНИЕ ЭФИРОМ")
    ModernButton("new_question", "НОВЫЙ", half, 34, "primary", function()
        if currentMode == "math" then generateMath()
        elseif currentMode == "anagram" then generateAnagram()
        else generateVyshibaly() end
    end)
    imgui.SameLine(0, THEME.gap)
    ModernButton("send_question", "В ЧАТ", half, 34, "neutral", function()
        if currentMode == "math" then sendChat("Следующий пример: " .. tostring(mathQuestion or "") .. tostring(mathQuestionSuffix or ""))
        elseif currentMode == "anagram" then sendChat("Новая Анаграмма: " .. formatAnagramDots(tostring(anagramShuffled or "")))
        else sendChat("Новое слово: " .. tostring(vyshibalyMasked or "")) end
        currentFirstAnswer = nil
    end)

    imgui.Dummy(V2(0, THEME.gap))
    ModernButton("play_intro", "СТАРТОВАЯ РЕЧЬ", half, 34, "success", function() playIntro(currentType) end)
    imgui.SameLine(0, THEME.gap)
    ModernButton("play_rules", "ПРАВИЛА", half, 34, "primary", playRules)

    imgui.Dummy(V2(0, THEME.gap))
    ModernButton("play_outro", "ЗАВЕРШАЮЩАЯ", half, 34, "purple", playOutro)
    imgui.SameLine(0, THEME.gap)
    ModernButton("send_top", "ИТОГИ", half, 34, "neutral", sendTopScores)

    imgui.Dummy(V2(0, THEME.gap))
    -- Кнопка рекламы теперь на всю ширину, скриншот убран
    ModernButton("send_adv", "РЕКЛАМА", w, 34, "warning", sendAdvertisement)

    imgui.Dummy(V2(0, THEME.gap))
    ModernButton("stop_efir", "ЗАВЕРШИТЬ ЭФИР", w, 40, "danger", autoStopEfir)

    imgui.Dummy(V2(0, THEME.gap))
    DrawLeaderboard()
end

-- ------------------------------------------------------------
-- ФОН ОКНА: градиент, свечения, сетка, бегущий блик, рамки
-- ------------------------------------------------------------
local function DrawWindowBackground(dl, wp, ws)
    local w, hh = ws.x, ws.y
    local r = THEME.radius

    -- мягкая тень окна (два слоя)
    dl:AddRectFilled(wp + V2(-1, 3), wp + ws + V2(1, 8), Col(WithA(C.shadow, 0.50)), r + 2)
    dl:AddRectFilled(wp + V2(-3, 8), wp + ws + V2(3, 14), Col(WithA(C.shadow, 0.26)), r + 6)

    -- базовый вертикальный градиент (полосы со скруглением углов)
    if CF then
        local strips = 6
        for i = 1, strips do
            local y0 = hh * (i - 1) / strips
            local y1 = hh * i / strips + 0.6
            local colr = MixCol(C.bgTop, C.bgBot, (i - 0.5) / strips)
            local pmin = wp + V2(0, y0)
            local pmax = wp + V2(w, y1)
            if i == 1 then
                dl:AddRectFilled(pmin, pmax, Col(colr), r, CF.TopLeft + CF.TopRight)
            elseif i == strips then
                dl:AddRectFilled(pmin, pmax, Col(colr), r, CF.BotLeft + CF.BotRight)
            else
                dl:AddRectFilled(pmin, pmax, Col(colr), 0.0)
            end
        end
    else
        dl:AddRectFilled(wp, wp + ws, Col(MixCol(C.bgTop, C.bgBot, 0.5)), r)
    end

    -- фоновые свечения по углам (вложенные скруглённые слои)
    for i = 1, 5 do
        local f = 1.0 - (i - 1) * 0.17
        local inset = 16.0
        local sx, sy = 210.0 * f, 150.0 * f
        dl:AddRectFilled(wp + V2(inset, inset), wp + V2(inset + sx, inset + sy), Col(WithA({0.30, 0.55, 1.0, 1.0}, 0.020)), r - 2)
        local bx, by = 230.0 * f, 165.0 * f
        dl:AddRectFilled(wp + V2(w - inset - bx, hh - inset - by), wp + V2(w - inset, hh - inset), Col(WithA({0.55, 0.35, 0.98, 1.0}, 0.018)), r - 2)
    end

    -- верхняя акцентная линия + медленный бегущий блик
    local lx0, lx1 = wp.x + r, wp.x + w - r
    dl:AddRectFilled(V2(lx0, wp.y), V2(lx1, wp.y + 2), Col(WithA(C.accent, 0.55)), 0)
    local span = lx1 - lx0
    local sweepW = 90.0
    local ph = (ui_time * 0.22) % 1.7
    if ph < 1.0 and span > sweepW then
        local cx0 = lx0 + ph * (span + sweepW) - sweepW * 0.5
        local segA = { 0.08, 0.22, 0.22, 0.08 }
        for seg = 1, 4 do
            local sx0 = cx0 + (seg - 1) * (sweepW * 0.25)
            local sx1 = sx0 + sweepW * 0.25
            if sx0 < lx0 then sx0 = lx0 end
            if sx1 > lx1 then sx1 = lx1 end
            if sx1 > sx0 then
                dl:AddRectFilled(V2(sx0, wp.y), V2(sx1, wp.y + 2), Col(WithA({0.85, 0.93, 1.0, 1.0}, segA[seg])), 0)
            end
        end
    end

    -- рамки: внутренняя светлая + внешняя
    dl:AddRect(wp + V2(1, 1), wp + ws + V2(-1, -1), Col(C.inner), r - 1, 0, 1.0)
    dl:AddRect(wp, wp + ws, Col(C.border), r, 0, 1.0)
end

local function ApplyTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    style.WindowPadding = V2(THEME.padding, THEME.padding)
    style.FramePadding = V2(9, 6)
    style.ItemSpacing = V2(THEME.gap, 6)
    style.ItemInnerSpacing = V2(6, 4)
    style.WindowRounding = THEME.radius
    style.ChildRounding = 10.0
    style.FrameRounding = THEME.radius - 4
    style.GrabRounding = THEME.radius - 4
    style.ScrollbarRounding = THEME.radius
    style.PopupRounding = THEME.radius - 2
    style.ScrollbarSize = 9.0
    style.WindowBorderSize = 0.0
    style.FrameBorderSize = 0.0
    style.ChildBorderSize = 0.0
    style.PopupBorderSize = 0.0
    style.WindowTitleAlign = V2(0.5, 0.5)
    style.AntiAliasedLines = true
    style.AntiAliasedFill = true

    local function SetCol(name, color, forcedAlpha)
        local id = imgui.Col[name]
        if id then
            local a = forcedAlpha or color[4] or 1.0
            style.Colors[id] = V4(color[1], color[2], color[3], a)
        end
    end

    local popupBg = MixCol(C.bgTop, C.bgBot, 0.5)

    SetCol("WindowBg", {0, 0, 0}, 0.0)
    SetCol("ChildBg", {0, 0, 0}, 0.0)
    SetCol("PopupBg", popupBg, 0.985)
    SetCol("Border", C.border)
    SetCol("Text", C.text)
    SetCol("TextDisabled", C.faint)
    SetCol("Button", C.surface2)
    SetCol("ButtonHovered", {0.360, 0.660, 1.000, 1.000})
    SetCol("ButtonActive", {0.190, 0.520, 0.900, 1.000})
    SetCol("FrameBg", C.surface)
    SetCol("FrameBgHovered", C.surface2)
    SetCol("FrameBgActive", {0.240, 0.540, 0.940, 1.000})
    SetCol("CheckMark", C.accent)
    SetCol("SliderGrab", C.accent)
    SetCol("SliderGrabActive", C.success)
    SetCol("ScrollbarBg", {0.070, 0.080, 0.100, 0.450})
    SetCol("ScrollbarGrab", C.surface2)
    SetCol("ScrollbarGrabHovered", C.accent)
    SetCol("ScrollbarGrabActive", C.accent)
end

imgui.OnInitialize(function()
    ApplyTheme()
    pcall(function()
        local io = imgui.GetIO()
        local ranges = io.Fonts:GetGlyphRangesCyrillic()
        local REGULAR = {
            "C:\\Windows\\Fonts\\segoeui.ttf",
            "C:\\Windows\\Fonts\\tahoma.ttf",
            "C:\\Windows\\Fonts\\arial.ttf",
        }
        local SEMIBOLD = {
            "C:\\Windows\\Fonts\\seguisb.ttf",
            "C:\\Windows\\Fonts\\segoeuib.ttf",
            "C:\\Windows\\Fonts\\tahomabd.ttf",
            "C:\\Windows\\Fonts\\arialbd.ttf",
        }
        local function AddFont(cands, size)
            for _, p in ipairs(cands) do
                if doesFileExist(p) then
                    local ok, f = pcall(io.Fonts.AddFontFromFileTTF, io.Fonts, p, size, nil, ranges)
                    if ok and f ~= nil then return f end
                end
            end
            return nil
        end
        -- body добавляется первым и становится шрифтом по умолчанию
        FONTS.body  = AddFont(REGULAR, 16.0)
        FONTS.small = AddFont(REGULAR, 13.0)
        FONTS.semi  = AddFont(SEMIBOLD, 16.0) or FONTS.body
        FONTS.big   = AddFont(SEMIBOLD, 19.0) or FONTS.semi
        FONTS.title = AddFont(SEMIBOLD, 22.0) or FONTS.semi
    end)
end)

imgui.OnFrame(
    function() return (WinState[0] or anim_alpha > 0.005) and ACCESS_GRANTED end,
    function()
        local now = os.clock()
        local dt = now - last_time
        if dt > 0.15 then dt = 0.15 elseif dt < 0.0 then dt = 0.0 end
        last_time = now
        frame_dt = dt
        ui_time = ui_time + dt

        local target = (WinState[0] and ACCESS_GRANTED) and 1.0 or 0.0
        anim_alpha = anim_alpha + (target - anim_alpha) * math.min(1.0, 14.0 * dt)

        -- анимация модального окна пола (живёт только пока видимо основное окно)
        local mainVisible = (WinState[0] or anim_alpha > 0.005)
        local gTarget = (genderWindowOpen[0] and pendingGenderConfirm ~= nil and mainVisible) and 1.0 or 0.0
        gender_anim = gender_anim + (gTarget - gender_anim) * math.min(1.0, 13.0 * dt)
        if gender_anim < 0.004 and gTarget < 0.01 then gender_anim = 0.0 end
        if genderWindowOpen[0] and pendingGenderConfirm then
            genderSnap = { nick = pendingGenderConfirm.nick, id = pendingGenderConfirm.id }
        end

        if anim_alpha < 0.005 and target < 0.01 then
            anim_alpha = 0.0
            gender_anim = 0.0
            return
        end

        local display = imgui.GetIO().DisplaySize
        local eased = clamp01(anim_alpha)
        eased = eased * eased * (3.0 - 2.0 * eased)

        ctx_alpha = anim_alpha
        imgui.SetNextWindowSize(V2(THEME.width, 0), imgui.Cond.Always)
        -- Cond.FirstUseEver позволяет двигать окно. math.floor убирает пикселизацию текста.
        imgui.SetNextWindowPos(V2(math.floor(display.x * 0.5), math.floor(display.y * 0.5 + (1.0 - eased) * 16.0)), imgui.Cond.FirstUseEver, V2(0.5, 0.5))
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, anim_alpha)

        local flags = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoBringToFrontOnFocus + imgui.WindowFlags.AlwaysAutoResize
        local open = imgui.Begin("##sfn_modern_main", WinState, flags)

        if open then
            local dl = imgui.GetWindowDrawList()
            local wp = imgui.GetWindowPos()
            local ws = imgui.GetWindowSize()
            DrawWindowBackground(dl, wp, ws)

            imgui.SetCursorPos(V2(THEME.padding, THEME.padding))
            DrawHeader(function() WinState[0] = false end)
            imgui.Dummy(V2(0, 2))

            if efirRunning then DrawLive() else DrawOffline() end
        end

        imgui.End()
        imgui.PopStyleVar()

        -- модальное окно подтверждения пола (с плавным появлением/исчезновением)
        if gender_anim > 0.008 and genderSnap then
            ctx_alpha = anim_alpha * gender_anim
            local nick = (pendingGenderConfirm and pendingGenderConfirm.nick) or genderSnap.nick
            local gW, gH = 336.0, 198.0
            imgui.SetNextWindowSize(V2(gW, gH), imgui.Cond.Always)
            imgui.SetNextWindowPos(V2(display.x * 0.5, display.y * 0.5 + (1.0 - gender_anim) * 12.0), imgui.Cond.Always, V2(0.5, 0.5))
            imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, clamp01(ctx_alpha))
            local gFlags = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoBringToFrontOnFocus
            local gOpen = imgui.Begin("##sfn_gender_modal", nil, gFlags)

            if gOpen then
                local gdl = imgui.GetWindowDrawList()
                local gp = imgui.GetWindowPos()
                local gs = imgui.GetWindowSize()
                local gr = THEME.radius

                gdl:AddRectFilled(gp + V2(0, 4), gp + gs + V2(0, 10), Col(WithA(C.shadow, 0.45)), gr + 2)
                gdl:AddRectFilled(gp, gp + gs, Col(MixCol(C.bgTop, C.bgBot, 0.5)), gr)
                for i = 1, 3 do
                    local f = 1.0 - (i - 1) * 0.25
                    gdl:AddRectFilled(gp + V2(14, 14), gp + V2(14 + 180 * f, 14 + 110 * f), Col(WithA({0.30, 0.55, 1.0, 1.0}, 0.022)), gr - 2)
                end
                gdl:AddRectFilled(V2(gp.x + gr, gp.y), V2(gp.x + gs.x - gr, gp.y + 2), Col(WithA(C.accent, 0.55)), 0)
                gdl:AddRect(gp, gp + gs, Col(C.border), gr, 0, 1.0)

                imgui.SetCursorPos(V2(THEME.padding + 2, THEME.padding + 2))
                local pos = imgui.GetCursorScreenPos()
                local w = imgui.GetContentRegionAvail().x

                DText(gdl, pos + V2(0, 2), Col(C.text), "Подтверждение пола", "semi", 0.30)
                DText(gdl, pos + V2(1, 26), Col(C.muted), "Игрок: " .. formatNick(nick or "???"), "small")
                gdl:AddRectFilled(pos + V2(0, 48), pos + V2(w * 0.4, 49), Col(WithA(C.accent, 0.60)), 0)
                gdl:AddRectFilled(pos + V2(w * 0.4, 48), pos + V2(w, 49), Col(WithA(C.border, 0.50)), 0)

                local half = (w - THEME.gap) * 0.5
                imgui.SetCursorScreenPos(pos + V2(0, 60))

                ModernButton("gender_male", "ПАРЕНЬ", half, 38, "primary", function()
                    if not pendingGenderConfirm then genderWindowOpen[0] = false return end
                    genders[pendingGenderConfirm.nick] = "m"
                    saveGenders()
                    applyCorrectAnswer(pendingGenderConfirm.nick, pendingGenderConfirm.id)
                    genderWindowOpen[0] = false
                end)
                imgui.SameLine(0, THEME.gap)
                ModernButton("gender_female", "ДЕВУШКА", half, 38, "purple", function()
                    if not pendingGenderConfirm then genderWindowOpen[0] = false return end
                    genders[pendingGenderConfirm.nick] = "f"
                    saveGenders()
                    applyCorrectAnswer(pendingGenderConfirm.nick, pendingGenderConfirm.id)
                    genderWindowOpen[0] = false
                end)

                DText(gdl, pos + V2(0, 108), Col(C.faint), "Пол сохранится в базу.", "small")
                imgui.SetCursorScreenPos(pos + V2(0, 130))

                ModernButton("gender_cancel", "ОТМЕНА", w, 30, "ghost", function()
                    pendingGenderConfirm = nil
                    genderWindowOpen[0] = false
                end)
            end
            imgui.End()
            imgui.PopStyleVar()
            ctx_alpha = anim_alpha
        end
    end
)

-- ============================================================
-- КОМАНДЫ
-- ============================================================
function cmd_efir()
    if not ACCESS_GRANTED then
        say("[SFN] У вас нет доступа к скрипту.")
        return
    end
    WinState[0] = not WinState[0]
    if WinState[0] then say(TEXTS.system.menu_opened)
    else say(TEXTS.system.menu_closed) end
end

function cmd_efirversion()
    if not isAdmin(myNick) then return end
    say("[SFN] Версия: " .. CURRENT_VERSION)
    if doesFileExist(UPDATE_TMP) then
        say("[SFN] Ожидает установки.")
    else
        say("[SFN] Обновлений не найдено.")
    end
end

function cmd_efirlist()
    if not isAdmin(myNick) then return end
    local total = #ALLOWED_NICK_HASHES
    say("[SFN] Разрешённых ников (кроме админов): " .. total)
end

function cmd_efirwhoami()
    if not isAdmin(myNick) then return end
    if not myNick or myNick == "Unknown" then return end
    local h = sha256.hash(myNick .. AUTH_SALT)
    say("[SFN] Ваш ник: " .. myNick)
    say("[SFN] SHA256: " .. h)
    say("[SFN] Роль: АДМИН")
end

function main()
    math.randomseed(os.time() + math.floor(os.clock() * 1000000))

    local wasUpdated = applyPendingUpdate()

    ensureDataDir()
    ensureConfig()
    ensureScores()
    ensureGenders()

    tryDetectNick()

    sampRegisterChatCommand("efir", cmd_efir)
    sampRegisterChatCommand("efirversion", cmd_efirversion)
    sampRegisterChatCommand("efirlist", cmd_efirlist)
    sampRegisterChatCommand("efirwhoami", cmd_efirwhoami)

    if wasUpdated then
        wait(3000)
        sampAddChatMessage("{66FF66}[SFN] Скрипт обновлён до v" .. CURRENT_VERSION .. ".", -1)
    end

    checkForUpdates()

    while true do
        wait(0)
        if myNick == "Unknown" then tryDetectNick() end
        if not ACCESS_CHECKED and myNick ~= "Unknown" then checkAutoAccess() end
        if ACCESS_GRANTED then
            if isKeyDown(HOTKEY) and not sampIsCursorActive() then
                WinState[0] = not WinState[0]
                wait(300)
            end
        end
    end
end

function scriptUnload()
    saveScores()
    saveGenders()
end