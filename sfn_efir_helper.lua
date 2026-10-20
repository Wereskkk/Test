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
-- MODERN UI LAYER
-- ============================================================

local THEME = {
    width = 340.0,
    radius = 12.0,
    padding = 12.0,
    gap = 8.0,
    colors = {
        bg       = {0.070, 0.078, 0.098, 0.970},
        surface  = {0.110, 0.120, 0.150, 0.920},
        surface2 = {0.145, 0.155, 0.190, 0.950},
        border   = {0.220, 0.240, 0.300, 0.750},
        shadow   = {0.000, 0.000, 0.000, 0.350},
        text     = {0.950, 0.960, 0.980, 1.000},
        muted    = {0.580, 0.620, 0.700, 1.000},
        accent   = {0.270, 0.620, 1.000, 1.000},
        success  = {0.250, 0.850, 0.450, 1.000},
        warning  = {1.000, 0.700, 0.200, 1.000},
        danger   = {1.000, 0.300, 0.350, 1.000},
        purple   = {0.620, 0.350, 0.950, 1.000},
    }
}

local C = THEME.colors
local anim_alpha = 0.0
local last_time = os.clock()

local function V2(x, y) return imgui.ImVec2(x, y) end
local function V4(r, g, b, a) return imgui.ImVec4(r, g, b, a) end

local function Col(color, alphaMultiplier)
    local a = (alphaMultiplier or 1.0) * (color[4] or 1.0) * (anim_alpha or 1.0)
    if a > 1.0 then a = 1.0 end
    if a < 0.0 then a = 0.0 end
    return imgui.ColorConvertFloat4ToU32(V4(color[1], color[2], color[3], a))
end

local settingBuffers = {}

local BUTTON_KINDS = {
    primary = { bg = C.accent, hover = {0.360, 0.700, 1.000, 1.000}, active = {0.180, 0.520, 0.900, 1.000}, border = false },
    success = { bg = C.success, hover = {0.350, 0.930, 0.550, 1.000}, active = {0.180, 0.720, 0.360, 1.000}, border = false },
    danger  = { bg = C.danger, hover = {1.000, 0.400, 0.450, 1.000}, active = {0.800, 0.200, 0.250, 1.000}, border = false },
    warning = { bg = C.warning, hover = {1.000, 0.800, 0.350, 1.000}, active = {0.850, 0.600, 0.120, 1.000}, border = false },
    purple  = { bg = C.purple, hover = {0.720, 0.450, 1.000, 1.000}, active = {0.520, 0.270, 0.850, 1.000}, border = false },
    neutral = { bg = C.surface2, hover = {0.200, 0.215, 0.260, 1.000}, active = {0.130, 0.140, 0.175, 1.000}, border = true },
    ghost   = { bg = {0.120, 0.130, 0.160, 0.750}, hover = {0.170, 0.185, 0.225, 0.950}, active = {0.100, 0.110, 0.140, 1.000}, border = true },
}

local function ModernButton(id, label, width, height, kind, onClick)
    local dl = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local size = V2(width, height)
    local clicked = imgui.InvisibleButton(id, size)
    local hovered = imgui.IsItemHovered()
    local active = imgui.IsItemActive()

    local k = BUTTON_KINDS[kind] or BUTTON_KINDS.neutral
    local base = k.bg
    if active then base = k.active elseif hovered then base = k.hover end

    if kind ~= "ghost" then
        local shadowOffset = hovered and 3.0 or 2.0
        dl:AddRectFilled(pos + V2(0, shadowOffset), pos + size + V2(0, shadowOffset), Col(C.shadow, 0.75), THEME.radius)
    end

    dl:AddRectFilled(pos, pos + size, Col(base), THEME.radius)

    if k.border then
        dl:AddRect(pos, pos + size, Col(hovered and C.accent or C.border), THEME.radius, 0, 1.2)
    end

    dl:AddLine(pos + V2(10, 1.5), pos + V2(width - 10, 1.5), Col({1, 1, 1, hovered and 0.12 or 0.05}), 1.0)

    local ts = imgui.CalcTextSize(label)
    dl:AddText(pos + V2((width - ts.x) * 0.5, (height - ts.y) * 0.5 - 1), Col(C.text), label)

    if clicked and onClick then onClick() end
end

local function SectionTitle(text)
    local dl = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local w = imgui.GetContentRegionAvail().x
    dl:AddText(pos, Col(C.muted), text)
    dl:AddLine(pos + V2(0, 16), pos + V2(w, 16), Col(C.border), 1.0)
    imgui.Dummy(V2(w, 24))
end

local function StatTile(label, value, color, width, height)
    local dl = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    dl:AddRectFilled(pos, pos + V2(width, height), Col(C.surface), THEME.radius - 2)
    dl:AddRectFilled(pos, pos + V2(3, height), Col(color), 2.0)
    dl:AddText(pos + V2(12, 8), Col(C.muted), label)
    dl:AddText(pos + V2(12, 28), Col(color), value)
    imgui.Dummy(V2(width, height))
end

local function DrawQuestionCard()
    local dl = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local w = imgui.GetContentRegionAvail().x
    
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

    local h = (sub ~= "") and 84.0 or 64.0
    dl:AddRectFilled(pos, pos + V2(w, h), Col(C.surface), THEME.radius)
    dl:AddRectFilled(pos, pos + V2(w, 3), Col(color), THEME.radius)
    dl:AddText(pos + V2(12, 12), Col(C.muted), title)
    dl:AddText(pos + V2(12, 34), Col(color), main)
    if sub ~= "" then dl:AddText(pos + V2(12, 58), Col(C.success), sub) end
    imgui.Dummy(V2(w, h + THEME.gap))
end

local function DrawFirstAnswerCard()
    local dl = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local w = imgui.GetContentRegionAvail().x
    local h = 64.0

    if currentFirstAnswer then
        local bg = {C.success[1], C.success[2], C.success[3], 0.12}
        dl:AddRectFilled(pos, pos + V2(w, h), Col(bg), THEME.radius)
        dl:AddRect(pos, pos + V2(w, h), Col(C.success), THEME.radius, 0, 1.0)
        dl:AddText(pos + V2(12, 10), Col(C.muted), "ПЕРВЫЙ ОТВЕТ")
        local line = formatNick(currentFirstAnswer.nick or "???") .. " — " .. tostring(currentFirstAnswer.answer or "")
        dl:AddText(pos + V2(12, 34), Col(C.text), line)
    else
        dl:AddRectFilled(pos, pos + V2(w, h), Col(C.surface), THEME.radius)
        dl:AddText(pos + V2(12, 10), Col(C.muted), "ПЕРВЫЙ ОТВЕТ")
        dl:AddText(pos + V2(12, 34), Col(C.muted), "Ожидание ответа...")
    end
    imgui.Dummy(V2(w, h))
end

local function DrawHeader(onClose)
    local dl = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local w = imgui.GetContentRegionAvail().x
    local h = 68.0
    local title = "SFN Helper"
    local subtitle = efirRunning and ("Эфир: " .. tostring(currentType or "")) or "Панель управления"

    dl:AddText(pos, Col(C.text), title)
    dl:AddText(pos + V2(0, 20), Col(C.muted), subtitle)

    local statusText = efirRunning and "LIVE" or "IDLE"
    local statusColor = efirRunning and C.success or C.muted
    local pulse = efirRunning and ((math.sin(os.clock() * 4.0) + 1.0) * 0.5) or 0.0
    local dotAlpha = 0.45 + 0.55 * pulse
    local dotColor = {statusColor[1], statusColor[2], statusColor[3], dotAlpha}

    local st = imgui.CalcTextSize(statusText)
    local pillW, pillH, closeW = st.x + 28.0, 24.0, 26.0
    local pillX, pillY = pos.x + w - pillW - closeW - 10.0, pos.y + 8.0

    dl:AddRectFilled(V2(pillX, pillY), V2(pillX + pillW, pillY + pillH), Col(C.surface2, 0.95), pillH * 0.5)
    dl:AddCircleFilled(V2(pillX + 13, pillY + pillH * 0.5), 4.0, Col(dotColor), 18)
    dl:AddText(V2(pillX + 22, pillY + 5), Col(statusColor), statusText)

    local cx, cy = pos.x + w - closeW, pos.y + 7.0
    imgui.SetCursorScreenPos(V2(cx, cy))
    local closeClicked = imgui.InvisibleButton("header_close", V2(closeW, closeW))
    local closeHovered = imgui.IsItemHovered()
    local closeActive = imgui.IsItemActive()

    local closeBg = C.surface2
    if closeActive then closeBg = C.danger 
    elseif closeHovered then closeBg = {C.danger[1], C.danger[2], C.danger[3], 0.55} end

    dl:AddRectFilled(V2(cx, cy), V2(cx + closeW, cy + closeW), Col(closeBg), 8.0)
    local xs = imgui.CalcTextSize("X")
    dl:AddText(V2(cx + (closeW - xs.x) * 0.5, cy + (closeW - xs.y) * 0.5 - 1), Col(C.text), "X")

    if closeClicked and onClose then onClose() end

    imgui.SetCursorScreenPos(pos)
    dl:AddLine(pos + V2(0, h - 10), pos + V2(w, h - 10), Col(C.border), 1.0)
    imgui.Dummy(V2(w, h))
end

local function SettingRow(id, label, value, minVal, maxVal, onSave)
    local dl = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local w = imgui.GetContentRegionAvail().x
    local h = 38.0

    dl:AddRectFilled(pos, pos + V2(w, h), Col(C.surface), THEME.radius - 2)
    dl:AddText(pos + V2(12, 11), Col(C.muted), label)

    local vs = tostring(value or 0)
    local vts = imgui.CalcTextSize(vs)
    dl:AddText(pos + V2(w - vts.x - 40, 11), Col(C.text), vs)

    local bx, by, bs = pos.x + w - 32.0, pos.y + 7.0, 24.0
    imgui.SetCursorScreenPos(V2(bx, by))
    local editClicked = imgui.InvisibleButton("edit_" .. id, V2(bs, bs))
    local editHovered = imgui.IsItemHovered()
    local editActive = imgui.IsItemActive()

    local ebg = C.surface2
    if editActive then ebg = C.accent elseif editHovered then ebg = {C.accent[1], C.accent[2], C.accent[3], 0.55} end
    dl:AddRectFilled(V2(bx, by), V2(bx + bs, by + bs), Col(ebg), 7.0)

    local dots = "..."
    local dts = imgui.CalcTextSize(dots)
    dl:AddText(V2(bx + (bs - dts.x) * 0.5, by + (bs - dts.y) * 0.5 - 1), Col(C.text), dots)

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

    ModernButton("start_math", "МАТЕМАТИКА", half, 38, "success", function() autoStartEfir("math"); generateMath() end)
    imgui.SameLine(0, THEME.gap)
    ModernButton("start_anagram", "АНАГРАММА", half, 38, "primary", function() autoStartEfir("anagram"); generateAnagram() end)
    
    imgui.Dummy(V2(0, THEME.gap))
    ModernButton("start_vysh", "ВЫШИБАЛЫ", w, 38, "purple", function() autoStartEfir("vyshibaly"); generateVyshibaly() end)
end

local function DrawLeaderboard()
    local w = imgui.GetContentRegionAvail().x
    SectionTitle("РЕЙТИНГ ИГРОКОВ")
    
    local listHeight = 140.0
    imgui.BeginChild("##sfn_leaderboard", V2(w, listHeight), false)
    local cw = imgui.GetContentRegionAvail().x
    local cdl = imgui.GetWindowDrawList()

    local list = {}
    for nick, info in pairs(scores) do
        table.insert(list, { nick = nick, score = info.score or 0 })
    end
    table.sort(list, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return tostring(a.nick) < tostring(b.nick)
    end)

    local rowH = 28.0
    if #list == 0 then
        cdl:AddText(imgui.GetCursorScreenPos(), Col(C.muted), "Пока нет баллов")
    else
        for i = 1, math.min(8, #list) do
            local item = list[i]
            local rpos = imgui.GetCursorScreenPos()
            
            local bg = C.surface
            if i == 1 then bg = {0.240, 0.200, 0.080, 0.950}
            elseif i == 2 then bg = {0.170, 0.180, 0.220, 0.950}
            elseif i == 3 then bg = {0.220, 0.140, 0.100, 0.950} end

            cdl:AddRectFilled(rpos, rpos + V2(cw, rowH - 6), Col(bg), 7.0)
            cdl:AddText(rpos + V2(8, 5), Col((i <= 3) and C.warning or C.muted), tostring(i) .. ".")
            cdl:AddText(rpos + V2(30, 5), Col(C.text), formatNick(item.nick or "???"))

            local scoreStr = tostring(item.score) .. " " .. pluralScore(item.score)
            local ss = imgui.CalcTextSize(scoreStr)
            cdl:AddText(rpos + V2(cw - ss.x - 8, 5), Col(C.success), scoreStr)
            imgui.Dummy(V2(cw, rowH))
        end
    end
    imgui.EndChild()
    imgui.Dummy(V2(0, THEME.gap))
    ModernButton("clear_scores", "ОЧИСТИТЬ БАЗУ", w, 30, "ghost", function() imgui.OpenPopup("confirm_clear_scores") end)

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
    StatTile("ВРЕМЯ", formatTime(totalTime), C.text, w, 60)
    
    imgui.Dummy(V2(0, THEME.gap))
    SectionTitle("ТЕКУЩИЙ ВОПРОС")
    DrawQuestionCard()
    DrawFirstAnswerCard()

    imgui.Dummy(V2(0, THEME.gap))

    if currentFirstAnswer then
        ModernButton("confirm_answer", "ВЕРНЫЙ ОТВЕТ", w, 36, "success", confirmCorrect)
        imgui.Dummy(V2(0, THEME.gap))
    end

    SectionTitle("УПРАВЛЕНИЕ ЭФИРОМ")
    ModernButton("new_question", "НОВЫЙ", half, 32, "primary", function()
        if currentMode == "math" then generateMath()
        elseif currentMode == "anagram" then generateAnagram()
        else generateVyshibaly() end
    end)
    imgui.SameLine(0, THEME.gap)
    ModernButton("send_question", "В ЧАТ", half, 32, "neutral", function()
        if currentMode == "math" then sendChat("Следующий пример: " .. tostring(mathQuestion or "") .. tostring(mathQuestionSuffix or ""))
        elseif currentMode == "anagram" then sendChat("Новая Анаграмма: " .. formatAnagramDots(tostring(anagramShuffled or "")))
        else sendChat("Новое слово: " .. tostring(vyshibalyMasked or "")) end
        currentFirstAnswer = nil
    end)

    imgui.Dummy(V2(0, THEME.gap))
    ModernButton("play_intro", "СТАРТОВАЯ РЕЧЬ", half, 32, "success", function() playIntro(currentType) end)
    imgui.SameLine(0, THEME.gap)
    ModernButton("play_rules", "ПРАВИЛА", half, 32, "primary", playRules)

    imgui.Dummy(V2(0, THEME.gap))
    ModernButton("play_outro", "ЗАВЕРШАЮЩАЯ", half, 32, "purple", playOutro)
    imgui.SameLine(0, THEME.gap)
    ModernButton("send_top", "ИТОГИ", half, 32, "neutral", sendTopScores)

    imgui.Dummy(V2(0, THEME.gap))
    ModernButton("send_adv", "РЕКЛАМА", half, 32, "warning", sendAdvertisement)
    imgui.SameLine(0, THEME.gap)
    ModernButton("make_shot", "СКРИНШОТ", half, 32, "neutral", function() lua_thread.create(makeScreenshot) end)

    imgui.Dummy(V2(0, THEME.gap))
    ModernButton("stop_efir", "ЗАВЕРШИТЬ ЭФИР", w, 38, "danger", autoStopEfir)

    imgui.Dummy(V2(0, THEME.gap))
    DrawLeaderboard()
end

local function ApplyTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    style.WindowPadding = V2(THEME.padding, THEME.padding)
    style.FramePadding = V2(8, 5)
    style.ItemSpacing = V2(THEME.gap, 6)
    style.ItemInnerSpacing = V2(6, 4)
    style.WindowRounding = THEME.radius
    style.FrameRounding = THEME.radius - 2
    style.GrabRounding = THEME.radius
    style.ScrollbarRounding = THEME.radius
    style.PopupRounding = THEME.radius - 2
    style.WindowBorderSize = 0.0
    style.FrameBorderSize = 0.0
    style.ChildBorderSize = 0.0
    style.PopupBorderSize = 0.0
    style.WindowTitleAlign = V2(0.5, 0.5)

    local function SetCol(name, color, forcedAlpha)
        local id = imgui.Col[name]
        if id then
            local a = forcedAlpha or color[4] or 1.0
            style.Colors[id] = V4(color[1], color[2], color[3], a)
        end
    end

    SetCol("WindowBg", {0, 0, 0}, 0.0)
    SetCol("ChildBg", {0, 0, 0}, 0.0)
    SetCol("PopupBg", C.bg, 0.98)
    SetCol("Border", C.border)
    SetCol("Text", C.text)
    SetCol("TextDisabled", C.muted)
    SetCol("Button", C.surface2)
    SetCol("ButtonHovered", C.accent)
    SetCol("ButtonActive", {0.180, 0.520, 0.900, 1.000})
    SetCol("FrameBg", C.surface)
    SetCol("FrameBgHovered", C.surface2)
    SetCol("FrameBgActive", C.accent)
    SetCol("CheckMark", C.accent)
    SetCol("SliderGrab", C.accent)
    SetCol("SliderGrabActive", C.success)
    SetCol("ScrollbarBg", {0.080, 0.090, 0.110, 0.550})
    SetCol("ScrollbarGrab", C.surface2)
    SetCol("ScrollbarGrabHovered", C.accent)
    SetCol("ScrollbarGrabActive", C.accent)
end

imgui.OnInitialize(function()
    ApplyTheme()
    pcall(function()
        local io = imgui.GetIO()
        local ranges = io.Fonts:GetGlyphRangesCyrillic()
        for _, p in ipairs({
            "C:\\Windows\\Fonts\\segoeui.ttf",
            "C:\\Windows\\Fonts\\tahoma.ttf",
            "C:\\Windows\\Fonts\\arial.ttf",
        }) do
            if doesFileExist(p) then
                io.Fonts:AddFontFromFileTTF(p, 15.0, nil, ranges)
                break
            end
        end
    end)
end)

imgui.OnFrame(
    function() return (WinState[0] or anim_alpha > 0.005) and ACCESS_GRANTED end,
    function()
        local now = os.clock()
        local dt = now - last_time
        if dt > 0.15 then dt = 0.15 end
        last_time = now

        local target = (WinState[0] and ACCESS_GRANTED) and 1.0 or 0.0
        anim_alpha = anim_alpha + (target - anim_alpha) * math.min(1.0, 14.0 * dt)

        if anim_alpha < 0.005 and target < 0.01 then anim_alpha = 0.0; return end

        local display = imgui.GetIO().DisplaySize
        imgui.SetNextWindowSize(V2(THEME.width, 0), imgui.Cond.Always)
        imgui.SetNextWindowPos(V2(display.x * 0.5, display.y * 0.5), imgui.Cond.FirstUseEver, V2(0.5, 0.5))
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, anim_alpha)

        local flags = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoBringToFrontOnFocus + imgui.WindowFlags.AlwaysAutoResize
        local open = imgui.Begin("##sfn_modern_main", WinState, flags)

        if open then
            local dl = imgui.GetWindowDrawList()
            local wp = imgui.GetWindowPos()
            local ws = imgui.GetWindowSize()
            dl:AddRectFilled(wp, wp + ws, Col(C.bg), THEME.radius)
            dl:AddRect(wp, wp + ws, Col(C.border), THEME.radius, 0, 1.0)
            dl:AddRectFilled(wp + V2(THEME.radius, 0), wp + V2(ws.x - THEME.radius, 2), Col(C.accent), 0.0)

            imgui.SetCursorPos(V2(THEME.padding, THEME.padding))
            DrawHeader(function() WinState[0] = false end)
            imgui.Dummy(V2(0, 2))

            if efirRunning then DrawLive() else DrawOffline() end
        end

        imgui.End()
        imgui.PopStyleVar()

        if genderWindowOpen[0] and pendingGenderConfirm then
            local gW, gH = 330.0, 190.0
            imgui.SetNextWindowSize(V2(gW, gH), imgui.Cond.Always)
            imgui.SetNextWindowPos(V2(display.x * 0.5, display.y * 0.5), imgui.Cond.Always, V2(0.5, 0.5))
            imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, 1.0)
            local gFlags = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoBringToFrontOnFocus
            local gOpen = imgui.Begin("##sfn_gender_modal", nil, gFlags)

            if gOpen then
                local gdl = imgui.GetWindowDrawList()
                local gp = imgui.GetWindowPos()
                local gs = imgui.GetWindowSize()
                gdl:AddRectFilled(gp, gp + gs, Col(C.bg), THEME.radius)
                gdl:AddRect(gp, gp + gs, Col(C.border), THEME.radius, 0, 1.0)

                imgui.SetCursorPos(V2(THEME.padding, THEME.padding))
                local pos = imgui.GetCursorScreenPos()
                local w = imgui.GetContentRegionAvail().x

                gdl:AddText(pos, Col(C.text), "Подтверждение пола")
                gdl:AddText(pos + V2(0, 20), Col(C.muted), "Игрок: " .. formatNick(pendingGenderConfirm.nick or "???"))
                gdl:AddLine(pos + V2(0, 46), pos + V2(w, 46), Col(C.border), 1.0)

                local half = (w - THEME.gap) * 0.5
                imgui.SetCursorScreenPos(pos + V2(0, 58))

                ModernButton("gender_male", "ПАРЕНЬ", half, 38, "primary", function()
                    genders[pendingGenderConfirm.nick] = "m"
                    saveGenders()
                    applyCorrectAnswer(pendingGenderConfirm.nick, pendingGenderConfirm.id)
                    genderWindowOpen[0] = false
                end)
                imgui.SameLine(0, THEME.gap)
                ModernButton("gender_female", "ДЕВУШКА", half, 38, "purple", function()
                    genders[pendingGenderConfirm.nick] = "f"
                    saveGenders()
                    applyCorrectAnswer(pendingGenderConfirm.nick, pendingGenderConfirm.id)
                    genderWindowOpen[0] = false
                end)

                imgui.SetCursorScreenPos(pos + V2(0, 112))
                gdl:AddText(pos + V2(0, 112), Col(C.muted), "Пол сохранится в базу.")
                imgui.SetCursorScreenPos(pos + V2(0, 138))

                ModernButton("gender_cancel", "ОТМЕНА", w, 30, "ghost", function()
                    pendingGenderConfirm = nil
                    genderWindowOpen[0] = false
                end)
            end
            imgui.End()
            imgui.PopStyleVar()
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