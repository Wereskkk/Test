-- Конфигурация: константы, маппинги, настройки сервера и API

local encoding = require("encoding")
encoding.default = "CP1251"
local u8 = encoding.utf8

return {
    API_BASE_URL = "https://api.evolvelogs.ru",
    FLOOD_LIMIT = 4,
    UPDATE_JSON_URL = "https://raw.githubusercontent.com/Pugovka/evolvelogs/main/update.json",
    UPDATE_BASE_URL = "https://raw.githubusercontent.com/Pugovka/evolvelogs/",
    CHANGELOG_JSON_URL = "https://raw.githubusercontent.com/Pugovka/evolvelogs/main/changelog.json",
    SENTRY_DSN = "https://9bd774fa6e9d41511c7fe4d668cc25d4@o4506888930852864.ingest.us.sentry.io/4508517143674880",
    WINDOW_WIDTH = 1030,
    WINDOW_HEIGHT = 520,
    SIDEBAR_WIDTH = 160,
    MENU_BUTTON_WIDTH = 140,
    FLOOD_TIME_WINDOW = 1,
    HTTP_TIMEOUT = 10,
    SERVER_CHECK = {
        ip = "s1.evolve-rp.net",
        name_evolve = "Evolve",
        name_saint_louis = "Saint%-Louis",
        server_id = "saint-louis",
    },
    UI_TO_API_FACTION = {
        [0] = 7, [1] = 2, [2] = 22, [3] = 3, [4] = 19, [5] = 1, [6] = 10, [7] = 21, [8] = 16, [9] = 9, [10] = 20,
    },
    FACTIONS = {
        u8"Правительство", u8"ФБР", u8"Больница", u8"Армия СФ", u8"Армия ЛВ",
        u8"Полиция ЛС", u8"Полиция СФ", u8"Полиция ЛВ", u8"Новости ЛС", u8"Новости СФ", u8"Новости ЛВ",
    },
    ORG_TO_FRACTION_INDEX = {
        ["GOV"] = 0, ["Government"] = 0, [u8"Правительство"] = 0,
        ["FBI"] = 1, [u8"ФБР"] = 1,
        ["Hospital"] = 2, ["EMS"] = 2, ["Medics"] = 2, [u8"Больница"] = 2,
        ["SF Army"] = 3, ["SFArmy"] = 3, [u8"Армия СФ"] = 3,
        ["LV Army"] = 4, ["LVArmy"] = 4, [u8"Армия ЛВ"] = 4,
        ["LSPD"] = 5, ["LS PD"] = 5, [u8"Полиция ЛС"] = 5,
        ["SFPD"] = 6, ["SF PD"] = 6, [u8"Полиция СФ"] = 6,
        ["LVPD"] = 7, ["LV PD"] = 7, [u8"Полиция ЛВ"] = 7,
        ["LS News"] = 8, ["LSNews"] = 8, [u8"Новости ЛС"] = 8,
        ["SF News"] = 9, ["SFNews"] = 9, [u8"Новости СФ"] = 9,
        ["LV News"] = 10, ["LVNews"] = 10, [u8"Новости ЛВ"] = 10,
    },
    CONTRACT_DAYS = {
        [u8"ВК"] = true, [u8"Военная кафедра%s*%(%s*15%s*lvl,%s*40%+%s*%)"] = true,
        [u8"Admiral"] = true, [u8"Адмиральский контракт%s*%(%s*8%s*lvl,%s*25%+%s*%)"] = true,
        [u8"Standart"] = true, [u8"Стандартный контракт%s*%(%s*4%s*lvl,%s*5%+%s*%)"] = true,
        [u8"Professional"] = true, [u8"Профессиональный контракт%s*%(%s*6%s*lvl,%s*10%+%s*%)"] = true,
        ["Advanced%Base"] = true, ["Base"] = true,
    },
    SPREADSHEET_URLS = {
        ["saint-louis"] = {
            [3] = "https://docs.google.com/spreadsheets/d/1AZIqoKfQPx6qD_NdyCbA6gLfYFYQ9t9IJ9et5a7urYM/gviz/tq?tqx=out:json&gid=506230950",
            [19] = "https://docs.google.com/spreadsheets/d/1Pz2UpstHZyqWnmlhJEMoEMO0yGEefAQjkGnl0ZuO5oc/gviz/tq?tqx=out:json&gid=2113865029",
        },
    },
    COLUMN_MAPPING = {
        ["saint-louis"] = {
            [3] = { nick = 2, contract = 6, lastPromotion = 8, nextPromotion = 9 },
            [19] = { nick = 1, contract = 0, lastPromotion = 3, nextPromotion = 4 },
        },
    },
    LIBS_TO_DOWNLOAD = {
        { url = "https://raw.githubusercontent.com/Pugovka/evolvelogs/refs/heads/main/libs/mimgui/cdefs.lua", filename = "mimgui/cdefs.lua" },
        { url = "https://raw.githubusercontent.com/Pugovka/evolvelogs/refs/heads/main/libs/mimgui/cimguidx9.dll", filename = "mimgui/cimguidx9.lua" },
        { url = "https://raw.githubusercontent.com/Pugovka/evolvelogs/refs/heads/main/libs/mimgui/dx9.lua", filename = "mimgui/dx9.lua" },
        { url = "https://raw.githubusercontent.com/Pugovka/evolvelogs/refs/heads/main/libs/mimgui/imgui.lua", filename = "mimgui/imgui.lua" },
        { url = "https://raw.githubusercontent.com/Pugovka/evolvelogs/refs/heads/main/libs/mimgui/init.lua", filename = "mimgui/init.lua" },
        { url = "https://raw.githubusercontent.com/Pugovka/mohtools/main/lib/imgui.lua", filename = "imgui.lua" },
        { url = "https://github.com/Pugovka/mohtools/blob/main/lib/MoonImGui.dll?raw=true", filename = "MoonImGui.dll" },
        { url = "https://raw.githubusercontent.com/Pugovka/mohtools/main/lib/json.lua", filename = "json.lua" },
        { url = "https://raw.githubusercontent.com/Pugovka/evolvelogs/refs/heads/main/libs/tabler_icons.lua", filename = "tabler_icons.lua" },
        { url = "https://raw.githubusercontent.com/Pugovka/evolvelogs/refs/heads/main/libs/fAwesome6_solid.lua", filename = "fAwesome6_solid.lua" },
    },
}
