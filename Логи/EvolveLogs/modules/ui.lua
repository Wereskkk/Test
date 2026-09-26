-- UI: тема, шрифты, меню, окна 

local allHints

function DarkTheme(imgui)
    imgui.SwitchContext()
    imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)
    imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
    imgui.GetStyle().IndentSpacing = 0
    imgui.GetStyle().ScrollbarSize = 10
    imgui.GetStyle().GrabMinSize = 10
    imgui.GetStyle().WindowBorderSize = 1
    imgui.GetStyle().ChildBorderSize = 1
    imgui.GetStyle().PopupBorderSize = 1
    imgui.GetStyle().FrameBorderSize = 1
    imgui.GetStyle().TabBorderSize = 1
    imgui.GetStyle().WindowRounding = 5
    imgui.GetStyle().ChildRounding = 5
    imgui.GetStyle().FrameRounding = 5
    imgui.GetStyle().PopupRounding = 5
    imgui.GetStyle().ScrollbarRounding = 5
    imgui.GetStyle().GrabRounding = 5
    imgui.GetStyle().TabRounding = 5
    imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
    local c = imgui.GetStyle().Colors
    c[imgui.Col.Text] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    c[imgui.Col.TextDisabled] = imgui.ImVec4(0.36, 0.42, 0.47, 1.00)
    c[imgui.Col.WindowBg] = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    c[imgui.Col.ChildBg] = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    c[imgui.Col.PopupBg] = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    c[imgui.Col.Border] = imgui.ImVec4(0.25, 0.25, 0.26, 0.54)
    c[imgui.Col.FrameBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    c[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    c[imgui.Col.FrameBgActive] = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    c[imgui.Col.TitleBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    c[imgui.Col.TitleBgActive] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    c[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    c[imgui.Col.MenuBarBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    c[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    c[imgui.Col.ScrollbarGrab] = imgui.ImVec4(0.00, 0.00, 0.00, 1.00)
    c[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
    c[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(0.51, 0.51, 0.51, 1.00)
    c[imgui.Col.CheckMark] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    c[imgui.Col.SliderGrab] = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    c[imgui.Col.SliderGrabActive] = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    c[imgui.Col.Button] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    c[imgui.Col.ButtonHovered] = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    c[imgui.Col.ButtonActive] = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
    c[imgui.Col.Header] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    c[imgui.Col.HeaderHovered] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    c[imgui.Col.HeaderActive] = imgui.ImVec4(0.47, 0.47, 0.47, 1.00)
    c[imgui.Col.Separator] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    c[imgui.Col.ResizeGrip] = imgui.ImVec4(1.00, 1.00, 1.00, 0.25)
    c[imgui.Col.ResizeGripHovered] = imgui.ImVec4(1.00, 1.00, 1.00, 0.67)
    c[imgui.Col.ResizeGripActive] = imgui.ImVec4(1.00, 1.00, 1.00, 0.95)
    c[imgui.Col.Tab] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    c[imgui.Col.TabHovered] = imgui.ImVec4(0.28, 0.28, 0.28, 1.00)
    c[imgui.Col.TabActive] = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    c[imgui.Col.TextSelectedBg] = imgui.ImVec4(1.00, 0.00, 0.00, 0.35)
    c[imgui.Col.ModalWindowDimBg] = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
end

function DrawGradientButton(imgui, smal, icon, text, size, color1, color2)
    icon = icon or ""
    text = text or "None"
    color1 = color1 or imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.03, 0.8, 0.73, 1.00))
    color2 = color2 or imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.07, 0.07, 0.07, 0.0))
    size = size or imgui.ImVec2(190, 35)
    local drawList = imgui.GetWindowDrawList()
    local cursorPos = imgui.GetCursorScreenPos()
    local result = imgui.InvisibleButton(text, size)
    drawList:AddRectFilledMultiColor(
        imgui.ImVec2(cursorPos.x, cursorPos.y),
        imgui.ImVec2(cursorPos.x + size.x, cursorPos.y + size.y),
        color1, color2, color2, color1
    )
    imgui.PushFont(smal)
    imgui.SetCursorScreenPos(imgui.ImVec2(cursorPos.x + 10, cursorPos.y + 8))
    imgui.Text(icon .. "  " .. text)
    imgui.PopFont()
    return result
end

function resetIO(imgui, key)
    for i = 0, 511 do imgui.GetIO().KeysDown[i] = false end
    for i = 0, 4 do imgui.GetIO().MouseDown[i] = false end
    imgui.GetIO().KeyCtrl = false
    imgui.GetIO().KeyShift = false
    imgui.GetIO().KeyAlt = false
    imgui.GetIO().KeySuper = false
end

function extendImgui(imgui, u8, key)
    function imgui.CenterText(text)
        imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - imgui.CalcTextSize(u8(text)).x / 2)
        imgui.Text(u8(text))
    end
    function imgui.CenterTextColoredRGB(text)
        imgui.SetCursorPosX(imgui.GetWindowSize().x / 2 - imgui.CalcTextSize(text).x / 2)
        imgui.TextColoredRGB(text)
    end
    function imgui.CenterDisableColumnText(text)
        imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
        imgui.TextDisabled(text)
    end
    function imgui.CenterColumnText(text)
        imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
        imgui.Text(text)
    end
    function imgui.Hint(hintKey, hintText, hintDelay)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(5, 5))
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 8)
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(1, 1, 1, 1))
        local isHovered = imgui.IsItemHovered()
        local fadeTime = 0.2
        local delay = hintDelay or 0
        if not allHints then allHints = {} end
        if not allHints[hintKey] then allHints[hintKey] = { timer = 0, status = false } end
        if isHovered then
            for k, h in pairs(allHints) do
                if k ~= hintKey and fadeTime >= os.clock() - h.timer then return end
            end
        end
        if allHints[hintKey].status ~= isHovered then
            allHints[hintKey].status = isHovered
            allHints[hintKey].timer = os.clock() + delay
        end
        local elapsed = os.clock() - allHints[hintKey].timer
        if elapsed <= fadeTime then
            local alpha = isHovered and math.min(1, math.max(0, elapsed / fadeTime)) or math.min(1, math.max(0, 1 - elapsed / fadeTime))
            imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)
            imgui.SetTooltip(hintText)
            imgui.PopStyleVar(1)
        elseif isHovered then
            imgui.SetTooltip(hintText)
        end
        imgui.PopStyleVar(2)
        imgui.PopStyleColor(1)
    end
    function imgui.CustomHint(text, hintText, u8_decode)
        imgui.Text(text)
        if hintText then
            imgui.SameLine()
            local r = imgui.GetFontSize() * 0.45
            local pad = 2
            local pos = imgui.GetCursorScreenPos()
            local cx, cy = pos.x + r + pad, pos.y + r + pad * 0.5
            imgui.GetWindowDrawList():AddCircleFilled(imgui.ImVec2(cx, cy), r, imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.5, 0.5, 0.5, 1.0)), 16)
            imgui.SetCursorScreenPos(pos)
            imgui.Dummy(imgui.ImVec2(r * 2 + pad * 2, r * 2 + pad))
            imgui.SetCursorScreenPos(imgui.ImVec2(cx - imgui.CalcTextSize("?").x * 0.5, cy - imgui.GetFontSize() * 0.5))
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.15, 0.15, 0.15, 1.0))
            imgui.Text("?")
            imgui.PopStyleColor()
            if imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.PushTextWrapPos(500)
                local displayText = ""
                if type(hintText) == "string" and #hintText > 0 and u8_decode then
                    local ok, decoded = pcall(u8_decode, hintText)
                    displayText = (ok and decoded and type(decoded) == "string") and decoded or hintText
                else
                    displayText = (type(hintText) == "string") and hintText or ""
                end
                imgui.Text(displayText)
                imgui.PopTextWrapPos()
                imgui.EndTooltip()
            end
        end
    end

    function imgui.TextColoredRGB(text)
        local style = imgui.GetStyle()
        local colors = style.Colors
        local col = imgui.Col
        text = text:gsub("{(%x%x%x%x%x%x)}", "{%1FF}")
        local color = colors[col.Text]
        local start = 1
        local a, b = text:find("{........}", start)
        while a do
            local t = text:sub(start, a - 1)
            if #t > 0 then
                imgui.TextColored(color, t)
                imgui.SameLine(nil, 0)
            end
            local clr = text:sub(a + 1, b - 1)
            if clr:upper() == "STANDART" then color = colors[col.Text]
            else
                clr = tonumber(clr, 16)
                if clr then
                    color = imgui.ImVec4(
                        bit.band(bit.rshift(clr, 24), 0xFF) / 255,
                        bit.band(bit.rshift(clr, 16), 0xFF) / 255,
                        bit.band(bit.rshift(clr, 8), 0xFF) / 255,
                        bit.band(clr, 0xFF) / 255
                    )
                end
            end
            start = b + 1
            a, b = text:find("{........}", start)
        end
        imgui.NewLine()
        if #text >= start then
            imgui.SameLine(nil, 0)
            imgui.TextColored(color, text:sub(start))
        end
    end
end

function drawSideMenu(ctx)
    local imgui = ctx.imgui
    local fa = ctx.fa
    local u8 = ctx.u8
    local state = ctx.state
    local config = ctx.config
    local rankInfo = ctx.rankInfo
    local utils = ctx.utils
    local api = ctx.api
    local chatMsg = ctx.chatMsg
    local saveSettings = ctx.saveSettings
    local httpRequest = ctx.httpRequest
    local httpRequestHistory = ctx.httpRequestHistory
    local openChangelog = ctx.openChangelog
    local scriptVersion = ctx.scriptVersion or ""
    local scriptUnload = ctx.scriptUnload
    local scriptReload = ctx.scriptReload
    local runUpdater = ctx.runUpdater
    local window = state.window
    local changelog = state.changelog
    local searchInput = state.searchInput
    local searchResults = state.searchResults
    local journalMode = state.journalMode
    local fraction = state.fraction
    local selectedMenu = state.selectedMenu
    local settings = state.settings
    local menuItems = state.menuItems
    local cum = ctx.fonts.cum
    local smal = ctx.fonts.smal
    local big = ctx.fonts.big
    local evolvelogo = ctx.evolvelogo
    local ffi = ctx.ffi
    local backgroundColor = imgui.ImVec4(0.094, 0.094, 0.102, 1.0)
    local highlightColor = imgui.ImVec4(0.725, 0.180, 0.263, 1.0)
    local activeTextColor = imgui.ImVec4(1.0, 1.0, 1.0, 1.0)
    local inactiveTextColor = imgui.ImVec4(0.6, 0.6, 0.6, 1.0)
    local activeColor1 = imgui.ImVec4(0.9, 0.2, 0.3, 0.5)
    local activeColor2 = imgui.ImVec4(1.0, 0.5, 0.6, 0.0)
    local inactiveColor1 = imgui.ImVec4(0.6, 0.6, 0.6, 0.0)
    local inactiveColor2 = imgui.ImVec4(0.4, 0.4, 0.4, 0.0)

    local sidebarW = config.SIDEBAR_WIDTH or 160
    local menuBtnW = config.MENU_BUTTON_WIDTH or 140
    imgui.Columns(2, "SideMenu", false)
    imgui.SetColumnWidth(0, sidebarW)
    imgui.PushStyleColor(imgui.Col.ChildBg, backgroundColor)
    if imgui.BeginChild("MenuChild", imgui.ImVec2(1020, 0), false) then
        if evolvelogo then imgui.Image(evolvelogo, imgui.ImVec2(42, 42))
        else imgui.Dummy(imgui.ImVec2(42, 42)) end
        imgui.SameLine()
        imgui.PushFont(big)
        imgui.Text("Evolve Logs")
        imgui.PopFont()
        imgui.NewLine()
        for i = 1, #menuItems do
            local color1, color2 = inactiveColor1, inactiveColor2
            if selectedMenu == i then color1, color2 = activeColor1, activeColor2 end
            if selectedMenu == i then imgui.PushStyleColor(imgui.Col.Text, activeTextColor)
            else imgui.PushStyleColor(imgui.Col.Text, inactiveTextColor) end
            if DrawGradientButton(imgui, smal, "", menuItems[i], imgui.ImVec2(menuBtnW, 30), imgui.ColorConvertFloat4ToU32(color1), imgui.ColorConvertFloat4ToU32(color2)) then
                state.selectedMenu = i
            end
            imgui.PopStyleColor()
            if selectedMenu == i then
                local cursorPos = imgui.GetCursorScreenPos()
                local offsetX, offsetY = (menuBtnW - 5), cursorPos.y - 25 + 5
                local barWidth, barHeight = 3, 15
                local rightX = cursorPos.x + offsetX + 4
                imgui.GetWindowDrawList():AddRectFilled(
                    imgui.ImVec2(rightX - barWidth, offsetY),
                    imgui.ImVec2(rightX, offsetY + barHeight),
                    imgui.ColorConvertFloat4ToU32(highlightColor)
                )
            end
        end
    end
    imgui.EndChild()
    imgui.PopStyleColor()
    imgui.NextColumn()

    if selectedMenu == 1 then
        -- Журнал
        imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.094, 0.094, 0.102, 1.0))
        imgui.BeginChild("##Menu", imgui.ImVec2(1000, 20), false)
        local drawList = imgui.GetWindowDrawList()
        local cursorPos = imgui.GetCursorScreenPos()
        drawList:AddRectFilledMultiColor(
            imgui.ImVec2(cursorPos.x, cursorPos.y), imgui.ImVec2(cursorPos.x + 430, cursorPos.y + 20),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.9, 0.3, 0.3, 0.1)), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.4, 0.4, 0.4, 0.0)),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.4, 0.4, 0.4, 0.0)), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.9, 0.3, 0.3, 0.1))
        )
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 3)
        imgui.TextDisabled(fa.ANGLE_LEFT)
        imgui.SameLine()
        imgui.PushFont(smal)
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.9, 0.3, 0.3, 1.0))
        imgui.Text(u8"Журнал логов")
        imgui.PopStyleColor()
        imgui.PopFont()
        imgui.EndChild()
        imgui.PopStyleColor()
        local inputWidth, buttonWidth = 150, 40
        local comboWidth = 140
        local clearBtnWidth = 70
        local style = imgui.GetStyle()
        local gap = style.ItemSpacing.x
        local totalRowWidth = clearBtnWidth + gap + comboWidth + gap + inputWidth + gap + buttonWidth
        local rightMargin = 10
        local startX = imgui.GetWindowWidth() - totalRowWidth - rightMargin
        imgui.SetCursorPosX(startX)
        if imgui.Button(u8"Очистить", imgui.ImVec2(clearBtnWidth, 23)) then
            state.searchResults = {}
        end
        imgui.SameLine()
        local journalModeItems = { u8"История", u8"Последняя строка" }
        local ImJournalItems = imgui.new["const char*"][2](journalModeItems)
        imgui.SetNextItemWidth(comboWidth)
        if imgui.Combo(u8"##JournalMode", journalMode, ImJournalItems, 2) then
            state.settings.journalMode = journalMode[0]
            saveSettings(state.settings)
        end
        imgui.SameLine()
        imgui.SetNextItemWidth(inputWidth)
        resetIO(imgui, ctx.key)
        imgui.PushFont(cum)
        imgui.InputTextWithHint("##SearchInput", u8"Введите никнейм", searchInput, ffi.sizeof(searchInput))
        imgui.PopFont()
        imgui.SameLine()
        if imgui.Button(fa.MAGNIFYING_GLASS .. "", imgui.ImVec2(buttonWidth, 23)) then
            local nickname = ffi.string(searchInput)
            if nickname:match("^[%w_]+$") then
                if journalMode[0] == 0 then
                    httpRequestHistory(nickname)
                else
                    httpRequest(nickname)
                end
            else
                chatMsg("Некорректный формат никнейма.", true)
            end
        end
        imgui.Hint("hintJournalSearch", u8"Текущая запись или полная история по выбору в списке")
        imgui.BeginChild("##SearchSection", imgui.ImVec2(300, 10), false)
        imgui.EndChild()
        imgui.BeginChild("##MenuActive", imgui.ImVec2(860, 430), false)
        imgui.Columns(7, "AccountList", true)
        imgui.SetColumnWidth(0, 130)
        imgui.SetColumnWidth(1, 130)
        imgui.SetColumnWidth(2, 120)
        imgui.SetColumnWidth(3, 120)
        imgui.SetColumnWidth(4, 145)
        imgui.SetColumnWidth(5, 145)
        imgui.SetColumnWidth(6, 90)
        imgui.CenterDisableColumnText(u8"Никнейм")
        imgui.NextColumn()
        imgui.CenterDisableColumnText(u8"Инициатор")
        imgui.NextColumn()
        imgui.CenterDisableColumnText(u8"Старый ранг")
        imgui.NextColumn()
        imgui.CenterDisableColumnText(u8"Новый ранг")
        imgui.NextColumn()
        imgui.CenterDisableColumnText(u8"Последнее повышение")
        imgui.NextColumn()
        imgui.CenterDisableColumnText(u8"Следующее повышение")
        imgui.NextColumn()
        imgui.CenterDisableColumnText(u8"Контракт")
        imgui.Separator()
        local playerId = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
        for idx, result in ipairs(searchResults) do
            if result and type(result) == "table" then
                local giverankText = (result.giverank_last == "Invite" or result.giverank_last == "N/A") and "Invite" or (result.giverank_last or u8"Неизвестно")
                local giveranktoText = (result.giverankto == "Uninvite" or result.giverankto == "N/A") and "Uninvite" or (result.giverankto or u8"Неизвестно")
                local lastPromotionDate = result.lastPromotion or u8"Неизвестно"
                if lastPromotionDate ~= u8"Неизвестно" then
                    local day, month, year, hour, min = lastPromotionDate:match("(%d%d)%.(%d%d)%.(%d%d) (%d%d):(%d%d)")
                    if day and month and year and hour and min then
                        lastPromotionDate = string.format("%s.%s.20%s %s:%s", day, month, year, hour, min)
                    end
                end
                local nextPromotionDate = result.nextPromotion or u8"Неизвестно"
                if result.contractType ~= u8"Нет" then
                    lastPromotionDate = result.lastPromotion or u8"Неизвестно"
                    nextPromotionDate = result.nextPromotion or u8"Неизвестно"
                else
                    local rankToNum = utils.rankStringToNumber(result.giverankto)
                    local nextTs = rankToNum and api.calculateNextUpgradeDate(lastPromotionDate, rankToNum, nil, playerId, rankInfo, fraction, chatMsg) or nil
                    nextPromotionDate = nextTs and os.date("%d.%m.%Y", nextTs) or u8"Неизвестно"
                end
                imgui.NextColumn()
                imgui.PushFont(cum)
                imgui.CenterColumnText(result.nickname or "-")
                imgui.NextColumn()
                imgui.CenterColumnText(result.initiator or "-")
                imgui.NextColumn()
                imgui.CenterColumnText(giverankText)
                imgui.NextColumn()
                imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(giveranktoText).x / 2)
                if giveranktoText == "Uninvite" and result.reason then
                    imgui.CustomHint(giveranktoText, u8"Причина: " .. (result.reason or ""), u8.decode)
                else
                    imgui.CenterColumnText(giveranktoText)
                end
                imgui.NextColumn()
                imgui.CenterColumnText(lastPromotionDate)
                imgui.NextColumn()
                do
                    local nextTs = utils.parseDate(nextPromotionDate)
                    local now = os.time()
                    local isMostRecentRow = (idx == 1)
                    if nextTs and isMostRecentRow then
                        if now > nextTs then imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.25, 0.75, 0.35, 1.0))
                        else imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.9, 0.25, 0.25, 1.0)) end
                    end
                    imgui.CenterColumnText(nextPromotionDate)
                    if nextTs and isMostRecentRow then imgui.PopStyleColor() end
                end
                imgui.NextColumn()
                local cleanedContractType = utils.cleanContractType(result.contractType)
                if not cleanedContractType or cleanedContractType == u8"Да" then
                    imgui.CenterColumnText(u8"Да")
                else
                    imgui.CenterColumnText(config.CONTRACT_DAYS[cleanedContractType] and cleanedContractType or u8"Нет")
                end
                imgui.PopFont()
                imgui.Separator()
            end
        end
        imgui.Columns(1)
        if #searchResults == 0 then
            local text = u8"Тут пусто. Начните поиск"
            imgui.SetCursorPosY(imgui.GetCursorPosY() + 180)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(text).x) / 2 - 10)
            imgui.PushFont(cum)
            imgui.TextDisabled(text)
            imgui.PopFont()
        end
        imgui.EndChild()
    elseif selectedMenu == 2 then
        -- Настройки
        imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.094, 0.094, 0.102, 1.0))
        imgui.BeginChild("##Menu", imgui.ImVec2(1000, 20), false)
        imgui.TextDisabled(fa.ANGLE_LEFT)
        imgui.SameLine()
        imgui.PushFont(smal)
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.9, 0.3, 0.3, 1.0))
        imgui.Text(u8"Настройки")
        if imgui.IsItemClicked() then state.selectedMenu = 1 end
        imgui.PopStyleColor()
        imgui.PopFont()
        imgui.EndChild()
        imgui.PopStyleColor()
        imgui.Text(u8"Выберите фракцию:")
        local factions = config.FACTIONS
        local ImItems = imgui.new["const char*"][#factions](factions)
        imgui.PushItemWidth(130)
        if imgui.Combo(u8"##FactionCombo", fraction, ImItems, #factions) then
            state.settings.fraction = fraction[0]
            saveSettings(state.settings)
        end
    elseif selectedMenu == 3 then
        -- О скрипте
        imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.094, 0.094, 0.102, 1.0))
        imgui.BeginChild("##Menu", imgui.ImVec2(1000, 20), false)
        imgui.TextDisabled(fa.ANGLE_LEFT)
        imgui.SameLine()
        imgui.PushFont(smal)
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.9, 0.3, 0.3, 1.0))
        imgui.Text(u8"О скрипте")
        if imgui.IsItemClicked() then state.selectedMenu = 1 end
        imgui.PopStyleColor()
        imgui.PopFont()
        imgui.EndChild()
        imgui.PopStyleColor()
        imgui.NewLine()
        imgui.NewLine()
        imgui.SameLine(180)
        local cursorPos = imgui.GetCursorScreenPos()
        imgui.GetWindowDrawList():AddRectFilled(imgui.ImVec2(cursorPos.x, cursorPos.y), imgui.ImVec2(cursorPos.x + 460, cursorPos.y + 110), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.3, 0.3, 0.4, 0.1)), 10)
        imgui.SetCursorScreenPos(imgui.ImVec2(cursorPos.x + 10, cursorPos.y + 10))
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.0, 1.0, 1.0, 1.0))
        imgui.PushFont(cum)
        imgui.BeginChild("##Text", imgui.ImVec2(445, 100), false, imgui.WindowFlags.NoScrollWithMouse + imgui.WindowFlags.NoScrollbar)
        imgui.TextWrapped(u8[[Evolve Logs - скрипт внутриигровых логов для государственных организаций.
Список доступных организаций: Правительство, ФБР, Больница, Армия СФ, Армия ЛВ, Полиция ЛС, Полиция СФ, Полиция ЛВ, Новости ЛС, Новости СФ, Новости ЛВ

/elogs [ID/ник] - последняя запись
/elogs [ID/ник] history (или h) - полная история]])
        imgui.EndChild()
        imgui.PopFont()
        imgui.PopStyleColor()
        imgui.SetCursorScreenPos(imgui.ImVec2(cursorPos.x, cursorPos.y + 110 + 20))
        local childW = 530
        imgui.BeginChild("##AboutFooter", imgui.ImVec2(childW, 0), false, imgui.WindowFlags.NoScrollbar)
        local text_version = u8"Версия скрипта - {EB2E4A}" .. scriptVersion
        local text_author = u8"Автор скрипта - {EB2E4A}Mary_Norton"
        local avail = imgui.GetContentRegionAvail().x
        local offsetX_version = (avail - imgui.CalcTextSize(text_version).x) / 2
        local offsetX_author = (avail - imgui.CalcTextSize(text_author).x) / 2
        imgui.PushFont(cum)
        imgui.SetCursorPosX(offsetX_version)
        imgui.TextColoredRGB(text_version)
        imgui.SetCursorPosX(offsetX_author)
        imgui.TextColoredRGB(text_author)
        imgui.PopFont()
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 5)
        local wChangelog = imgui.CalcTextSize(u8"Список изменений").x + imgui.GetStyle().FramePadding.x * 2
        imgui.SetCursorPosX((avail - wChangelog) / 2 - 30)
        if imgui.Button(u8"Список изменений") then openChangelog() end
        local style = imgui.GetStyle()
        local btnW = imgui.GetFrameHeight()
        local buttonsWIcons = btnW * 3 + style.ItemSpacing.x * 2
        imgui.SetCursorPosX((avail - buttonsWIcons) / 2 - 30)
        if imgui.Button(fa.POWER_OFF .. "") then
            chatMsg("Скрипт отключён", false)
            if scriptUnload then scriptUnload() end
        end
        imgui.Hint("hintScriptUnload", u8"Отключить скрипт")
        imgui.SameLine()
        if imgui.Button(fa.ROTATE .. "") then
            chatMsg("Скрипт перезагружен", false)
            if scriptReload then scriptReload() end
        end
        imgui.Hint("hintScriptReload", u8"Перезагрузить скрипт")
        imgui.SameLine()
        if imgui.Button(fa.DOWNLOAD .. "") then
            chatMsg("Проверка обновлений...", false)
            if runUpdater then runUpdater() end
        end
        imgui.Hint("hintScriptUpdate", u8"Проверить обновления")
        imgui.EndChild()
    end
    imgui.Columns(1)
end

function drawChangelog(ctx)
    local imgui = ctx.imgui
    local fa = ctx.fa
    local u8 = ctx.u8
    local config = ctx.config
    local state = ctx.state
    local url = config and config.CHANGELOG_JSON_URL
    if url and not changelogLoadStarted then
        changelogLoadStarted = true
        lua_thread.create(function()
            local requests = require("requests")
            local json = require("json")
            local ok, resp = pcall(function() return requests.get(url, { timeout = 10 }) end)
            if ok and resp and resp.status_code == 200 and resp.text then
                local ok2, data = pcall(json.decode, resp.text)
                if ok2 and data and data.versions and #data.versions > 0 then
                    local enc = require("encoding")
                    enc.default = "CP1251"
                    for _, ver in ipairs(data.versions) do
                        if ver.changes and type(ver.changes) == "table" then
                            for i, line in ipairs(ver.changes) do
                                if type(line) == "string" then
                                    local ok3, decoded = pcall(function() return enc.utf8:decode(line) end)
                                    data.versions[_].changes[i] = (ok3 and decoded) or line
                                end
                            end
                        end
                    end
                    changelogCache = data
                end
            end
        end)
    end

    if not changelogCache then
        imgui.TextWrapped(u8"Загрузка списка изменений...")
        return
    end

    for _, entry in ipairs(changelogCache.versions) do
        local label = "v " .. tostring(entry.version)
        if entry.current then
            label = (fa.FIRE or "") .. u8" Актуальная версия | " .. label
        else
            label = u8(label)
        end
        if imgui.CollapsingHeader(label) then
            local lines = entry.changes or {}
            local text = table.concat(lines, "\n")
            if text ~= "" then
                imgui.TextWrapped(u8(text))
            end
        end
    end
end

return {
    DarkTheme = DarkTheme,
    DrawGradientButton = DrawGradientButton,
    resetIO = resetIO,
    extendImgui = extendImgui,
    drawSideMenu = drawSideMenu,
    drawChangelog = drawChangelog,
}